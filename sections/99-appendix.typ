#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *

// Code listings: codly draws the line numbers and the frame. A smaller font keeps
// each listing on one page.
#show: codly-init.with()
#codly(languages: codly-languages)
#show raw: set text(size: 8pt)

= Programming Code <appendix:code>

This appendix shows the pieces of the firmware that carry the main ideas of Chapter 3. They are excerpts, not the whole program, and some comments were shortened. The firmware is written in C++ for the STM32 controller. Each listing is introduced by a short explanation and points to the section of Chapter 3 that describes the same idea in words.

== Step pulse generation

The STEP signal is produced by a hardware timer, not by the main loop. @listing:pulse shows the interrupt that runs on every compare event of the timer (@sec:step-pulse). Each event toggles the STEP pin. On the active edge the interrupt counts one step, in the direction of travel, which gives the controller the axis position. On the inactive edge it loads any new speed requested by the motion controller, so that a speed change never shortens a pulse. A requested speed of zero stops the rescheduling. Finally, the next toggle is scheduled half a period later, where the half period in timer ticks is the value of @eq:half-period.

#figure(
  ```cpp
  void StepperDriver::on_compare_elapsed() noexcept
  {
      is_step_output_active_ = !is_step_output_active_;

      if (is_step_output_active_)
      {
          // Count one step, in the direction of travel
          pulse_count_.fetch_add(static_cast<int8_t>(direction_current_),
                                 std::memory_order_relaxed);
      }
      else
      {
          // Load the speed the motion controller asked for
          const auto speed_requested =
              speed_requested_.load(std::memory_order_relaxed);

          if (speed_requested == 0)
          {
              return; // Stop: the main loop cancels the interrupt
          }

          apply_speed(speed_requested);
      }

      // Schedule the next toggle half a period later
      const std::uint32_t previous_compare = config_.timer_channel.compare();
      config_.timer_channel.set_compare(previous_compare + half_period_ticks_);
  }
  ```,

  caption: [The timer interrupt that generates the STEP pulses],
) <listing:pulse>

== Braking and speed ramp

The motion controller shapes the speed of each axis into a trapezoid (@sec:motion-planner). @listing:ramp shows its two core calculations. The first function computes the distance needed to slow from the current speed to the landing speed, which is @eq:braking, and reports whether the remaining distance has fallen within it. The second function moves the current speed toward the desired speed by at most the acceleration times the elapsed time, and snaps to the desired speed when it is closer than one step of that size, so that the speed does not oscillate around it.

#figure(
  ```cpp
  bool StepperController::should_decelerate(
      const PositionMode &position) const noexcept
  {
      const std::int64_t distance = distance_to_target(position);

      const float speed_magnitude = std::abs(speed_current_signed_);
      const float landing_speed = speed_profile_.landing_speed;

      // Distance to slow down to the landing speed, not to a standstill
      const float braking_distance =
          std::max(0.0F, (speed_magnitude * speed_magnitude) -
                             (landing_speed * landing_speed)) /
          (2.0F * speed_profile_.acceleration);

      return std::abs(static_cast<float>(distance)) <= braking_distance;
  }

  float StepperController::ramp_speed_toward(float speed_desired,
                                             float delta_time_s) const noexcept
  {
      const float speed_error = speed_desired - speed_current_signed_;
      const float speed_step = speed_profile_.acceleration * delta_time_s;

      // Snap to the setpoint instead of oscillating around it
      if (std::abs(speed_error) <= speed_step)
      {
          return speed_desired;
      }

      return speed_current_signed_ + std::copysign(speed_step, speed_error);
  }
  ```,

  caption: [Braking distance and speed ramp of the motion controller],
) <listing:ramp>

== Millimeters to steps

All positions, speeds, and accelerations are set in millimeters and converted to steps by the scale factor of the axis (@table:axis-scale). @listing:scale shows the conversion. The position is multiplied by the pulses per revolution and divided by the travel per revolution, as in @eq:mm-to-steps, and the result is rounded to the nearest step. The multiplication is done in 64 bits so that a long travel at a high microstep setting cannot overflow. The second function returns the number of steps per millimeter, @eq:steps-per-mm, which converts speeds and accelerations.

#figure(
  ```cpp
  // Rounded to the nearest step
  constexpr std::int32_t steps_from_mm(std::int32_t mm) const noexcept
  {
      // 64-bit, so a long travel at a high microstep setting can't overflow
      return static_cast<std::int32_t>(
          divide_rounded(std::int64_t{mm} * pulses_per_rev_, mm_per_rev_));
  }

  // For speeds and accelerations: multiply mm/s or mm/s^2 by this
  constexpr float steps_per_mm() const noexcept
  {
      return static_cast<float>(pulses_per_rev_) / static_cast<float>(mm_per_rev_);
  }

  // Half away from zero. `denominator` is positive
  static constexpr std::int64_t divide_rounded(std::int64_t numerator,
                                               std::int64_t denominator) noexcept
  {
      const std::int64_t half = denominator / 2;
      return numerator >= 0 ? (numerator + half) / denominator
                            : -((-numerator + half) / denominator);
  }
  ```,

  caption: [Conversion between millimeters and steps],
) <listing:scale>

== Limit-switch debounce

The limit switches were very noisy when first connected (@sec:limit-noise). @listing:debounce shows the filter that was added. A press counts only after the input has read pressed for the full debounce time without a break, so a short spike from the stepper drivers cannot fault a move. A release counts at once, so that the axis is not kept stopped longer than necessary. The price of the delay is that the axis runs on past the switch by the debounce time multiplied by its speed.

#figure(
  ```cpp
  class LimitFilter
  {
    public:
      explicit constexpr LimitFilter(std::uint32_t press_ms) noexcept
          : press_ms_(press_ms) {}

      bool update(bool pressed, std::uint32_t now_ms) noexcept
      {
          if (pressed != last_pressed_)
          {
              last_pressed_ = pressed;
              changed_at_ms_ = now_ms; // Restart the timer on every change
          }

          // A press counts only after press_ms without a break
          return pressed && now_ms - changed_at_ms_ >= press_ms_;
      }

    private:
      std::uint32_t press_ms_;
      bool last_pressed_ = false;
      std::uint32_t changed_at_ms_ = 0;
  };
  ```,

  caption: [Debounce filter for the limit switches],
) <listing:debounce>

== Fault latch and safe state

Every abnormal condition is recorded as a latched fault (@sec:estop-handling). @listing:faults shows the latch and the way the main loop reacts to it. Each fault is one bit of a 16-bit word, so any number of faults can be active at once, and the first fault to be raised is remembered separately, because it is the cause. Faults are only cleared on a Start press. In the main loop, if any fault is latched, the machine enters its safe state: the sequencer and both axes stop and the electromagnet is kept engaged. Otherwise, the motion controllers run.

#figure(
  ```cpp
  void Faults::raise(Fault fault) noexcept
  {
      const auto bit =
          static_cast<std::uint16_t>(1U << static_cast<std::size_t>(fault));

      if (active_ == 0)
      {
          first_ = bit; // The first fault is the cause
      }

      active_ |= bit;
  }

  static void enter_safe_state() noexcept
  {
      machine.sequencer.stop();
      machine.controller_x.stop_immediately();
      machine.controller_y.stop_immediately();
      hardware::effector.engage(); // Hold the part
  }

  // In loop(), after the sequencer step:
  if (machine.faults.any())
  {
      enter_safe_state();
  }
  else
  {
      machine.controller_x.process(now);
      machine.controller_y.process(now);
  }
  ```,

  caption: [The fault latch and the safe state],
) <listing:faults>

== Operation interface

Every step of the cycle is an operation, and all operations implement the same interface (@sec:operation-interface). @listing:operation shows it. An operation has two functions: `start()` begins it and returns at once, and `poll()` is called on every later pass of the main loop and reports whether the operation is still running, has finished, or was aborted. The comments summarize the rules that every operation follows: it never blocks, it takes the time from the context passed to it and never reads a clock, it reads recipe values only when it starts, and it raises the fault that explains a failure before it reports `aborted`. Because the sequencer only knows this interface, a new kind of step can be added without changing it.

#figure(
  ```cpp
  enum class PollResult
  {
      running,
      finished,
      aborted, // The sequence must not continue past it
  };

  // One step of the cycle. `Context` is what the sequencer passes on every pass.
  // An implementation must:
  // - read recipe values only in start(), keeping a copy if poll() needs them
  // - reset all per-run state in start(): the same object runs again and again
  // - never block in start() or poll()
  // - take the time from the context, and never read a clock
  // - raise the fault that explains a failure before returning aborted
  template <class Context>
  class Operation
  {
    public:
      virtual void start(Context &ctx) noexcept = 0;
      virtual PollResult poll(Context &ctx) noexcept = 0;

      virtual ~Operation() = default;
  };
  ```,

  caption: [The interface that every operation of the cycle implements],
) <listing:operation>

== Sequencer step

The cycle is a list of nonblocking operations, and the sequencer runs one step of it on every pass of the main loop (@flowchart:sequencer). @listing:sequencer shows that step. An operation that has not started is started, and one that has started is polled. A finished operation advances the sequence to the next one. An aborted operation stops the sequencer but leaves its index on that operation, so the failed step can be read over Modbus.

#figure(
  ```cpp
  void Sequencer<Context>::step(Context &ctx) noexcept
  {
      if (!is_sequencer_running_)
      {
          return;
      }

      if (!is_current_operation_started_)
      {
          is_current_operation_started_ = true;
          current_operation().start(ctx);
          return;
      }

      switch (current_operation().poll(ctx))
      {
      case PollResult::running:
          break; // Nothing to do: the axes move on their own

      case PollResult::finished:
          is_current_operation_started_ = false;
          advance_operation();
          break;

      case PollResult::aborted:
          stop(); // The index stays on this operation
          break;
      }
  }
  ```,

  caption: [One step of the cycle sequencer],
) <listing:sequencer>

== Homing

Homing drives an axis toward its limit switch, sets the origin just past the switch, and backs off to it (@flowchart:homing). @listing:homing shows the `poll()` function of the homing operation. While searching, a pressed switch sets the origin a fixed back-off behind the switch and starts the move to it. After the back-off, a switch that still reads pressed cannot be trusted, so the operation raises a homing-failed fault. A time limit catches an axis that never reaches its switch.

#figure(
  ```cpp
  PollResult HomeStepperOperation::poll(Tick &ctx) noexcept
  {
      StepperController &controller = axis_.controller;
      const bool is_switch_pressed = ctx.inputs.*axis_.limit_pressed;

      if (!is_backing_off_)
      {
          if (is_switch_pressed)
          {
              // The switch is back_off_steps_ behind the new origin
              controller.reset_position(-back_off_steps_);
              controller.move_to_steps(0);
              is_backing_off_ = true;
          }
      }
      else if (controller.is_at_target())
      {
          if (is_switch_pressed)
          {
              // Still pressed after backing off: the origin can't be trusted
              ctx.faults.raise(axis_.homing_failed);
              return PollResult::aborted;
          }

          return PollResult::finished;
      }

      if (ctx.now_ms - start_time_ >= timeout_ms_)
      {
          controller.stop_immediately();
          ctx.faults.raise(Fault::operation_timed_out);
          return PollResult::aborted;
      }

      return PollResult::running;
  }
  ```,

  caption: [One poll of the homing operation],
) <listing:homing>

== Modbus monitor <sec:monitor-code>

The Modbus monitor is a small support tool that shows the state of the machine on a laptop during tests (@sec:monitor). It is not part of the machine's control. Its code was generated with the assistance of Claude Code, an AI coding assistant, and its Modbus decoding is covered by unit tests. A web browser cannot open a raw TCP connection, so the tool is a small program in Go that serves the monitor's web page and passes the page's requests on to the board over Modbus TCP. The page shows the axis positions, the stage of the cycle, the latched faults, and a graph of the main-loop time. The three listings below are excerpts from the Go program.

@listing:mbap shows how one request is made and checked. The request is the Modbus function with an MBAP header in front of it, which holds a transaction number, the protocol identifier, the length, and the unit identifier. The reply must carry the same transaction number, and a reply with the error bit set in its function code is turned into an error. The board serves a single socket, so every request goes through one connection, under a lock.

#figure(
  ```go
  func (c *Client) roundTrip(target string, pdu []byte) ([]byte, error) {
  	// MBAP header: transaction id, protocol id (0), length, unit id
  	c.tid++
  	frame := make([]byte, 7, 7+len(pdu))
  	binary.BigEndian.PutUint16(frame[0:], c.tid)
  	binary.BigEndian.PutUint16(frame[4:], uint16(len(pdu)+1))
  	frame[6] = 1
  	if _, err := c.conn.Write(append(frame, pdu...)); err != nil {
  		return nil, err
  	}
  	header := make([]byte, 7)
  	if _, err := io.ReadFull(c.conn, header); err != nil {
  		return nil, err
  	}
  	tid := binary.BigEndian.Uint16(header[0:])
  	length := binary.BigEndian.Uint16(header[4:])
  	if tid != c.tid || length < 2 {
  		return nil, fmt.Errorf("bad MBAP header (tid %d, expected %d)", tid, c.tid)
  	}
  	body := make([]byte, length-1)
  	if _, err := io.ReadFull(c.conn, body); err != nil {
  		return nil, err
  	}
  	return checkResponse(pdu[0], body)
  }

  // An exception reply has the function code with its top bit set
  func checkResponse(fc byte, body []byte) ([]byte, error) {
  	switch {
  	case body[0] == fc|0x80 && len(body) >= 2:
  		return nil, &ExceptionError{Function: fc, Code: body[1]}
  	case body[0] != fc:
  		return nil, fmt.Errorf("function code mismatch: got %d, sent %d", body[0], fc)
  	}
  	return body[1:], nil
  }
  ```,

  caption: [Sending a Modbus TCP request and checking the reply in the monitor],
) <listing:mbap>

@listing:decode shows how the data in a reply is read. A register is two bytes, high byte first, and the first byte of the reply holds the number of data bytes, which is checked against the number requested. The bits of the discrete inputs are packed eight to a byte, with the first bit in the lowest position. A position does not fit in one 16-bit register, so the firmware sends it as two registers, high word first, and the last function joins them into a signed 32-bit number. These functions are the ones covered by the unit tests.

#figure(
  ```go
  func decodeBits(resp []byte, count uint16) ([]bool, error) {
  	if len(resp) < 1 || int(resp[0]) != (int(count)+7)/8 || len(resp) != 1+int(resp[0]) {
  		return nil, errors.New("malformed bit response")
  	}
  	bits := make([]bool, count)
  	for i := range bits {
  		bits[i] = resp[1+i/8]>>(i%8)&1 == 1
  	}
  	return bits, nil
  }

  func decodeRegisters(resp []byte, count uint16) ([]uint16, error) {
  	if len(resp) < 1 || int(resp[0]) != 2*int(count) || len(resp) != 1+int(resp[0]) {
  		return nil, errors.New("malformed register response")
  	}
  	regs := make([]uint16, count)
  	for i := range regs {
  		regs[i] = binary.BigEndian.Uint16(resp[1+2*i:])
  	}
  	return regs, nil
  }

  // Joins a high-word-first register pair into a signed 32-bit value
  func signed32(high, low uint16) int32 {
  	return int32(uint32(high)<<16 | uint32(low))
  }
  ```,

  caption: [Decoding the bits and registers of a Modbus reply in the monitor],
) <listing:decode>

Finally, @listing:state shows how one poll of the board is turned into the machine state. Three requests read the discrete inputs, the input registers, and the holding registers. The input registers are read in one request, so that both words of a position, and the fault registers, all come from the same moment. The raw tables are then given their meaning, following the Modbus map of the firmware.

#figure(
  ```go
  func poll(c *Client, target string) (*State, error) {
  	di, err := c.ReadBits(target, fcReadDiscreteInputs, diCount)
  	if err != nil {
  		return nil, err
  	}
  	// One request, so both position words and the fault registers each come
  	// from the same moment
  	ir, err := c.ReadRegisters(target, fcReadInputRegisters, irCount)
  	if err != nil {
  		return nil, err
  	}
  	hr, err := c.ReadRegisters(target, fcReadHoldingRegisters, hrCount)
  	if err != nil {
  		return nil, err
  	}
  	return newState(di, ir, hr), nil
  }

  // Maps the raw tables to their meaning (some fields are left out here)
  func newState(di []bool, ir, hr []uint16) *State {
  	return &State{
  		EStop:   di[0],
  		Running: di[2],
  		Fault:   di[6],
  		OpIndex: ir[0],
  		X:       signed32(ir[1], ir[2]),
  		Y:       signed32(ir[3], ir[4]),
  		Params:  hr,

  		FaultsActive: ir[irFaultsActive],
  		FaultFirst:   ir[irFaultFirst],
  		LoopTimeUs:   ir[irLoopTime],
  	}
  }
  ```,

  caption: [Reading the state of the machine in the monitor],
) <listing:state>

= Engineering Codes and Standards

The codes and standards in @applicable-standards were identified as relevant references for the design and development of Safe Dip. Their inclusion does not represent a claim of certification or complete compliance. Formal compliance would require evaluation of the finished system against the complete requirements of each applicable document.

#v(1em)

#[
  #show figure: set block(breakable: true)
  #show table.cell: set block(breakable: false)
  #show table.cell: set par(justify: true)

  #figure(
    table(
      columns: (
        auto,
        auto,
        1fr,
        1fr,
      ),
      align: (
        left + horizon,
        left + horizon,
        left + horizon,
        left + horizon,
      ),
      inset: (x: 0.55em, y: 0.5em),
      stroke: 0.5pt,

      table.header([*Code\ or Standard*], [*Organization*], [*Explanation*], [*Relevance to Safe Dip*]),

      [IEEE\ Code of Ethics],
      [Institute of\ Electrical\ and\ Electronics\ Engineers],
      [Defines ethical duties related to safety, honesty, competence, and public welfare.],
      [Supports safe design, truthful reporting, and clear disclosure of prototype limitations.],

      [NSPE\ Code of Ethics\ for Engineers],
      [National\ Society of\ Professional\ Engineers],
      [Requires engineers to prioritize public safety and communicate technical information honestly.],
      [Applies to safety decisions, testing, risk disclosure, and performance claims.],

      [ISO\ 13850:2015],
      [International\ Organization\ for\ Standardization],
      [Defines requirements and design principles for machinery emergency-stop functions.],
      [Guides the latching E-stop, immediate motion cutoff, manual reset, and restart inhibition.],

      [ISO\ 14118:2017],
      [International\ Organization\ for\ Standardization],
      [Addresses prevention of unexpected machine start-up.],
      [Requires a deliberate restart action after the E-stop is reset.],

      [NFPA 79],
      [National\ Fire\ Protection\ Association],
      [Covers electrical equipment, wiring, protection, and controls for industrial machinery.],
      [Guides internal wiring, branch protection, grounding, control circuits, and E-stop wiring.],

      [NFPA 70\ National\ Electrical\ Code],
      [National\ Fire\ Protection\ Association],
      [Defines requirements for safe electrical installations and supply connections.],
      [Guides power connections, wiring, fuses, grounding, and electrical fault protection.],

      [IEC\ 60204-1],
      [International\ Electrotechnical\ Commission],
      [Covers the safety of electrical equipment of machines and defines the emergency-stop categories.],
      [Defines the Category 0 stop architecture of the movement subsystem.],
    ),
    caption: [Engineering codes and standards applicable to the Safe Dip project.],
  )<applicable-standards>
]

= Datasheets

#bibliography(
  "../datasheet-citations.yaml",
  title: none,
  style: "ieee",
  full: true,
)

// The schematic gets a landscape page of its own. The orientation is switched with
// set rules, not a page block, so the heading itself starts the landscape page.
#set page(flipped: true, margin: (x: .45in, top: .45in, bottom: .45in))

= Electrical Schematic <appendix:schematic>

#v(-1.5em)

#figure(
  image("../images/hardware/schematic.svg", height: 88%),
  caption: [Complete electrical schematic of the Safe Dip prototype],
) <figure:schematic>

// Back to the report's portrait page, with the same margins as the template.
#set page(flipped: false, margin: (left: 1.25in, right: 1in, top: 1in, bottom: 1in))
#set par(first-line-indent: .5in)

= Team Biographies

#grid(
  columns: (150pt, 1fr),
  column-gutter: 1em,
  row-gutter: 3em,

  image("../images/meet-the-team/josue-picture.JPEG"),
  [
    Josué Bouchard is originally from Argentina and is completing his Bachelor’s degree in Electrical and Computer Engineering Technology at Valencia College. His interest in engineering began with an Arduino board and grew from a fascination with using software to interact with the physical world. After beginning his studies in Computer Engineering at the Universidad de Buenos Aires, he transferred to Valencia College, where he combined his theoretical background with hands-on experience in electronics, microcontrollers, and embedded systems. Josué also enjoys helping others understand technical concepts through his work as a laboratory aide. After graduation, he hopes to pursue a career in embedded systems and eventually work in aerospace or robotics.
  ],

  image("../images/meet-the-team/adriano-foto.jpg"),
  [
    Adriano Mena Duque de Estrada was born in Colón, Matanzas, Cuba, and immigrated to the United States with his family in 2016, crossing the border with very little and no knowledge of English. With faith and perseverance, he is now completing his Bachelor’s degree in Electrical and Computer Engineering Technology at Valencia College, having switched from Aerospace Engineering after realizing it wasn’t the right fit — though designing spacecraft remains a personal dream. Outside of coursework, Adriano enjoys strategy video games, spends time with his dog and bearded dragon, and loves building electrical projects, which is what ultimately drew him into this career path.
  ],
)
