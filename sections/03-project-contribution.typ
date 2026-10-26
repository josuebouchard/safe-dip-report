#import "@preview/zero:0.5.0": zi, ztable
#import "../template.typ": chapter, todo

#chapter(
  description: [#lorem(60)]
)[Project Contribution]

== Design Integration and Flow Charts

The Safe Dip control software uses a cooperative, nonblocking architecture. Rather than executing the complete pick-dip-place cycle as one blocking function, the software is divided into modules that are processed repeatedly from a single main loop: the cycle sequencer, one motion planner per axis, and the communications interface.

Each call into a module performs a bounded amount of work and returns immediately. This keeps the controller responsive to the emergency stop, the start button, and communication requests while a movement, effector operation, or dwell is still in progress.

#figure(
  image(
    "/images/software/Main Structure.svg",
    height: 75%,
  ),
  caption: [Main software execution structure],
  placement: auto
)<flowchart:main-structure>

As shown in @flowchart:main-structure, the software first initializes the GPIO, the W5500 controller, the Modbus TCP task, and the motion planners, and then enters a continuous main loop. At the start of every iteration, the emergency-stop and start buttons are read. If the emergency stop is pressed, the sequencer and both axes are stopped and the end effector is kept engaged (see @sec:estop-handling). Otherwise, a press of the start button while the sequencer is not running restarts the cycle from its first operation; the sequencer is then stepped, and the motion planner of each axis is processed. The communications interface is serviced on every iteration, including while the emergency stop is pressed, so that the system state remains observable.

This structure implements cooperative multitasking. No module is allowed to block execution while waiting for an operation to finish. The motion planners continue their work over many iterations of the main loop, while the sequencer monitors the progress of the current operation.

#place.flush()
==== Normal Cycle Sequence

The normal operating cycle is represented as an ordered list of nonblocking operations, shown in @flowchart:normal-cycle and grouped into five process stages: home, pick, dip, deposit, and release. After the last operation completes, the sequence wraps around to the first, so the gantry repeats the cycle.

#figure(
  image(
    "/images/software/Cycles Normal Sequence.svg",
    width: 100%,
  ),
  caption: [Normal pick-dip-place operation sequence],
  placement: auto,
)<flowchart:normal-cycle>

Each operation represents an absolute objective rather than a blocking procedure. For example, `MOVE_Y_UP` requests that the vertical axis move to its configured upper position. The operation hands the target to the motion planner and returns immediately; the sequencer then keeps checking the operation until the axis reports that the target has been reached.

Two kinds of operations are planned but not yet part of the sequence. `HOME_Y` and `HOME_X` will drive each axis slowly toward its limit switch and set that point as position zero; they will run only after a start press, with the vertical axis homed first so that the end effector is raised before the gantry travels horizontally. `WAIT_FOR_PART` will hold the cycle before the pick stage until the ultrasonic sensor detects a workpiece at the input station, satisfying the requirement that no motion begins without a part present.

#place.flush()
==== Operation Interface <sec:operation-interface>

Every entry in the sequence is an object implementing the same two-function interface:

- `start()` begins the operation, for example by giving a target position to a motion planner, and returns immediately.
- `poll()` performs any work the operation needs and reports whether the operation is still `running` or has `finished`.

The sequencer only ever calls these two functions. The correct implementation is selected at runtime through C++ virtual functions, so the sequencer needs no knowledge of which module is responsible for an operation or how that module works.

Each operation copies every configurable value it depends on when it starts. A value changed while an operation is running, for example through Modbus, therefore takes effect the next time that operation starts and never alters a run already in progress. @table:operations lists the operations.

#figure(
  table(
    columns: 3,
    align: left + horizon,
    inset: (x: .5em, y: .75em),
    table.header([*Operation*], [*`start()`*], [*`poll()` reports finished when…*]),
    [Move axis], [Sets the axis target position], [The axis has reached the target step],
    [Effector], [Engages or releases the electromagnet], [Immediately],
    [Dwell], [Records the start time and the dwell duration], [The dwell duration has elapsed],
  ),
  caption: [Operations available to the sequencer]
)<table:operations>

This produces a clear abstraction boundary. The sequencer does not need to know which hardware timer is assigned to an axis, which GPIO pins control the stepper drivers, how many steps remain, or how the acceleration profile is calculated. Conversely, the modules do not need to know the structure of the pick-dip-place sequence, so each one can be developed and tested independently.

#place.flush()
==== Cycle Sequencer

The cycle sequencer keeps an index to the current operation, a flag indicating whether that operation has been started, and a flag indicating whether the system is running. @flowchart:sequencer shows one sequencer step.

#figure(
  image(
    "/images/software/Sequencer.svg",
    width: 100%,
  ),
  caption: [Cooperative cycle sequencer],
  placement: auto,
)<flowchart:sequencer>

If the system is not running, the step returns without doing anything. If the current operation has not been started, the sequencer starts it and returns; polling begins on the next iteration of the main loop. Otherwise, the operation is polled. While it reports `running`, the sequencer performs no further work and control returns to the main loop. When it reports `finished`, the sequencer clears the started flag and advances to the next operation, wrapping to the first after the last.

The sequencer can be stopped, which halts it in place, or restarted, which resets the index to the first operation and sets it running. The start button always uses the restart path, so the cycle never resumes from the middle of an operation whose physical state may no longer be known.

#place.flush()
==== Motion Planner <sec:motion-planner>

Each axis has its own motion planner, which converts a goal into a continuously updated step rate. The planner supports two control modes. In _position mode_, used for every move in the cycle, the planner drives the axis to a target step count. In _velocity mode_, the planner holds a commanded speed; it will be used by the homing operations to jog each axis toward its limit switch.

@flowchart:motion-planner shows one call of the planner's `process()` function, which is made for each axis on every iteration of the main loop.

#figure(
  image(
    "/images/software/Motion Planner.svg",
    width: 100%,
  ),
  caption: [One call of the motion planner's `process()` function. $v_"max"$ and $v_"land"$ are applied in the direction of the target.],
  placement: auto,
)<flowchart:motion-planner>

In position mode, the planner first checks whether the axis is exactly on its target step. This check runs on every call, not only once per millisecond, so that a fast-moving axis cannot step past the target unnoticed; when it succeeds, the axis is stopped immediately. Because the system tick advances once per millisecond and the main loop runs much faster, most of the remaining calls find no elapsed time and return early.

Otherwise, the planner decides whether it is time to brake. The distance needed to slow from the current speed $v$ to the landing speed $v_"land"$ at acceleration $a$ is

$ d_"brake" = (v^2 - v_"land"^2) / (2a) $

Once the remaining distance falls within $d_"brake"$, a landing flag is set and the desired speed becomes $v_"land"$ instead of $v_"max"$. If the axis is moving away from its target, the desired speed is zero, so the axis first brakes and then reverses. In velocity mode, the desired speed is simply the commanded speed. In both modes, the current speed is then ramped toward the desired speed by at most $a dot Delta t$ and sent to the stepper driver.

The resulting motion is a trapezoidal speed profile, accelerating, cruising at $v_"max"$, and braking, followed by a short approach at the landing speed, which lets the axis stop exactly on the target step instead of overshooting or stalling short of it. With the current tuning, $v_"max" = 4000$ steps/s, $a = 4000$ steps/s², and $v_"land" = 100$ steps/s.

==== Step Pulse Generation <sec:step-pulse>

The motion planner only decides _how fast_ each axis should turn; the individual STEP pulses are produced by hardware. TIM2 runs at 1 MHz, and each axis uses one of its channels in output-compare toggle mode. On every compare event, the timer toggles the STEP pin and an interrupt schedules the next toggle half a period later, where the half period in timer ticks is $f_"timer" \/ (2 dot |v|)$.

The interrupt also counts one step on each active edge, which gives the planner the axis position, and loads any new speed requested by the planner on each inactive edge, so that speed changes never shorten a pulse. When the requested speed is zero, the interrupt stops rescheduling itself and the channel is released.

The STEP and DIR pins are configured as open-drain outputs that sink current from the stepper drivers' optocoupler inputs, whose anodes are tied to 5 V. The microcontroller therefore never drives these lines to 3.3 V, and the 5 V-tolerant pins interface with the drivers directly, without a level-shifting buffer.

#place.flush()
==== Emergency-Stop Handling <sec:estop-handling>

The emergency stop is enforced first by hardware: the normally closed mushroom button opens the stepper drivers' 24 V supply directly, independently of the firmware. The firmware response supplements this path; it does not replace it.

The emergency-stop input is read at the start of every main-loop iteration. Because every module returns within a bounded time, the loop period is short enough that polling detects a press without the need for an external interrupt. While the button is pressed, the firmware stops the sequencer, stops both axes immediately by disabling their STEP timers, and keeps the electromagnet engaged so that the suspended workpiece is not dropped into the bath. The communications interface continues to be serviced.

Releasing the emergency stop does not resume the interrupted operation. A deliberate press of the start button is required, which restarts the cycle from its first operation. Because the drivers lose power during the stop, the axes may coast, and the step count no longer reflects the true gantry position. The planned homing operations will therefore run at every restart, so that each restart re-establishes a known position from the limit switches before any other motion.

Overall, this architecture combines cooperative scheduling with asynchronous peripheral operation. Hardware timers and their interrupts perform the timing-critical work, while the main loop coordinates higher-level behavior through the sequencer. This keeps the production sequence easy to understand while isolating the detailed control of the motors, end effector, dwell timing, and communications inside dedicated software modules.


== Implementation

== Troubleshooting

== Requirement Testing and Results

== Verification Summary

== Final Design