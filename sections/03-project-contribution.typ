#import "@preview/zero:0.5.0": zi, ztable
#import "../template.typ": chapter, todo
#import "@preview/subpar:0.2.2"

// Figures with several images: one number for the figure, and (a), (b), ... for the
// images. The numbering follows the rest of the report: chapter number, then count.
#let subfigs(..args) = subpar.grid(
  ..args,
  numbering: n => numbering("1.1", counter(heading).get().first(), n),
  numbering-sub-ref: (n, m) => numbering("1.1a", counter(heading).get().first(), n, m),
  supplement: "Fig.",
)

// Images live in one folder per subtitle of this chapter.
#let flow = "/images/chapter-3/design-integration-and-flow-charts/"
#let impl = "/images/chapter-3/implementation/"
#let trouble = "/images/chapter-3/troubleshooting/"
#let final = "/images/chapter-3/final-design/"

#let site = "https://safe-dip.vercel.app/progress/"

// A numbered video with a link, as the course asks: "Video 3.1: Title, https://..."
// It is a figure so that @labels and the numbering work, but it is drawn as a
// left-aligned box: the title on one line, the link below it.
#let video(file, title) = figure(
  link(site + file),
  kind: "video",
  supplement: [Video],
  caption: title,
)

// Room between a figure's caption and the text around it.
#show figure.where(kind: image): set block(above: 1.4em, below: 1.4em)
#show figure.where(kind: table): set block(above: 1.4em, below: 1.4em)

#show figure.where(kind: "video"): it => block(
  width: 100%,
  above: 1.4em,
  below: 1.4em,
  inset: (x: 10pt, y: 8pt),
  fill: luma(247),
  stroke: (left: 2pt + luma(150)),
  breakable: false,
)[
  #set align(left)
  #set par(first-line-indent: 0pt, justify: false)
  *#it.supplement #context it.counter.display(it.numbering):* #it.caption.body \
  #text(size: 9pt, it.body)
]

// One problem from the build, in the order the course asks for.
#let issue(symptom: none, cause: none, solution: none, result: none) = [
  *Symptom.* #symptom

  *Cause.* #cause

  *Solution.* #solution

  *Result.* #result
]

#chapter(
  description: [This chapter presents the work carried out to turn the Safe Dip design into a working prototype. It explains how the hardware and firmware modules connect and operate together, describes how each module was built, wired, and programmed, and records the significant problems found along the way with their causes and solutions. It then tests each system requirement against its success criterion, summarizes the results, and shows the prototype as built.],
)[Project Contribution]

== Design Integration and Flow Charts

Safe Dip is organized around the NUCLEO-F446RE controller, which connects every module shown in @block-diagram:hardware and wired as shown in the schematic in @appendix:schematic. The controller sends STEP and DIR signals to the two DM542TE drivers, which power the NEMA 23 motors from the 24 V supply through relay K1. It reads the emergency-stop signal, the Start button, and the limit switches, drives the relay that switches the electromagnet from the 12 V supply, and communicates with the W5500 Ethernet module over SPI to publish the machine state through Modbus TCP. The emergency-stop button acts on the motor supply through the relays independently of the controller, so the firmware adds to that protection but is not part of it.

The control software uses a cooperative, nonblocking architecture. Rather than executing the complete pick-dip-place cycle as one blocking function, the software is divided into modules that are processed repeatedly from a single main loop: the cycle sequencer, one motion controller per axis, and the communications interface. Each call into a module performs a bounded amount of work and returns immediately. This keeps the controller responsive to the emergency stop, the limit switches, the Start button, and communication requests while a movement, effector operation, or dwell is still in progress.

The firmware is divided into layers, and the build system rejects any dependency that points the wrong way. The driver layer handles timers and pins; the control layer turns a position request into a speed over time; the sequencer runs an ordered list of steps; the operations layer defines the kinds of step that exist; a debounce layer filters the raw switch and button inputs; and the application layer is the only one that knows the whole machine, including its axes, cycle, and Modbus registers.

#figure(
  image(flow + "main-loop.pdf", height: 540pt),
  caption: [The firmware's main loop],
  placement: auto,
)<flowchart:main-structure>

@flowchart:main-structure shows the main loop in outline. The software first initializes the Ethernet controller, the Modbus TCP task, and the motion controllers, disengages the electromagnet, and then enters a continuous main loop. Each pass reads all inputs and the time once, so that everything in that pass acts on the same values. The limit-switch inputs pass through a 3 ms debounce first, described in @sec:limit-noise. Two safety checks then run before the sequencer: any axis moving into its limit switch is stopped, and a pressed emergency stop raises a fault. A press of the Start button with the emergency stop released either clears the latched faults or, if there are none and the cycle is stopped, restarts the cycle.

If no fault is latched, the sequencer is stepped, and the current operation may itself raise a fault. A second check follows immediately, so a fault acts on the same pass in which it is raised: the machine enters its safe state instead of running the motion controllers. The communications interface is then serviced on every pass, including during a fault, so that the system state remains observable. Last, the duration of the whole pass, Modbus included, is recorded with the processor's cycle counter, which shows how quickly the firmware can respond.

#place.flush()
=== Normal Cycle Sequence <sec:normal-cycle>

The normal operating cycle is represented as an ordered list of thirteen nonblocking operations, shown in @flowchart:normal-cycle and grouped into five process stages: home, pick, dip, deposit, and release. After the last operation completes, the sequence wraps around to the first, so the gantry repeats the cycle, homing both axes again at the start of each one.

#figure(
  image(flow + "normal-cycle.pdf", width: 100%),
  caption: [Normal pick-dip-place operation sequence],
  placement: auto,
)<flowchart:normal-cycle>

Each operation represents an absolute objective rather than a blocking procedure. For example, _Raise Y_ requests that the vertical axis move to its configured upper position. The operation hands the target to the motion controller and returns immediately; the sequencer then keeps checking the operation until the axis reports that the target has been reached. Positions, the dwell time, and the effector settle time are held in a recipe, in millimeters and milliseconds, that can be changed over Modbus.

The home stage runs the vertical axis first, so that the end effector is raised before the gantry travels horizontally. Homing leaves the horizontal axis at its origin, which is where the pick stage takes place.

The part-ready trigger is not in the firmware yet, and the rest of this section describes its design. The trigger is a pair of Dupont pins on the controller. One pin is connected to ground, and the other to a free input, pin PA10 (D2), which tolerates 5 V and has its internal pull-up enabled. Closing the pair, with a jumper or with the dry contact of the external system, pulls the input low, which means that a part is ready. An open pair, and an unplugged or broken wire, leave the input high, which means that no part is ready, so a disconnected trigger can never start a cycle. The input is read once per pass of the main loop with the other inputs, and it goes through the same filter as the limit switches, so that a spike of noise cannot start a cycle: the trigger counts as asserted only after the input has read low for 3 ms, and it counts as released at once.

The trigger is used by a new operation, _Wait for trigger_, which is the first operation of the cycle, before the homing operations. While the trigger is not asserted, the operation keeps running and nothing moves, so no motion starts without it. When the trigger is asserted, the operation finishes, and the cycle homes both axes and runs as before. The Start button still restarts the sequence, which brings the machine back to the wait, so the trigger is needed at the start of every cycle. It is not checked while a cycle is running, so opening it during a cycle does not stop the machine; the emergency stop and the faults do that. The state of the trigger is also reported over Modbus as a discrete input, and the operation appears in the stage list of the monitor, so that the wait can be seen. Adding the operation shifts the operation index by one, so the Modbus map and the monitor change with it.

#place.flush()
=== Operation Interface <sec:operation-interface>

Every entry in the sequence is an object implementing the same two-function interface:

- `start()` begins the operation, for example by giving a target position to a motion controller, and returns immediately.
- `poll()` performs any work the operation needs and reports whether the operation is still `running`, has `finished`, or was `aborted`.

The sequencer only ever calls these two functions. The interface is listed in @listing:operation. The correct implementation is selected at runtime through C++ virtual functions, so the sequencer needs no knowledge of which module is responsible for an operation or how that module works.

Each operation copies every configurable value it depends on when it starts. A value changed while an operation is running, for example through Modbus, therefore takes effect the next time that operation starts and never alters a run already in progress. An operation that cannot complete raises the fault that explains why before it reports `aborted`. @table:operations lists the operations.

#figure(
  table(
    columns: 4,
    align: left + horizon,
    inset: (x: .5em, y: .75em),
    table.header([*Operation*], [*`start()`*], [*Finished when…*], [*Aborted when…*]),
    [Move axis],
    [Converts the position to steps and sets the target],
    [The axis is on the target step],
    [Its limit switch is pressed, or something else stopped the move],

    [Home axis],
    [Moves toward the limit switch at homing speed],
    [The axis has backed off the switch and the switch has released],
    [The switch stays pressed after backing off, or the time limit passes],

    [Effector], [Engages or releases the electromagnet], [The settle time has elapsed], [Never],
    [Dwell], [Records the start time and the dwell duration], [The dwell duration has elapsed], [Never],
  ),
  caption: [Operations available to the sequencer],
)<table:operations>

This produces a clear abstraction boundary. The sequencer does not need to know which hardware timer is assigned to an axis, which GPIO pins control the stepper drivers, how many steps remain, or how the acceleration profile is calculated. Conversely, the modules do not need to know the structure of the pick-dip-place sequence, so each one can be developed and tested independently.

#place.flush()
=== Cycle Sequencer

The cycle sequencer keeps an index to the current operation, a flag indicating whether that operation has been started, and a flag indicating whether the system is running. @flowchart:sequencer shows one sequencer step.

#figure(
  image(flow + "sequencer.pdf", width: 450pt),
  caption: [One step of the cooperative cycle sequencer],
  placement: auto,
)<flowchart:sequencer>

The step is listed in @listing:sequencer. If the system is not running, the step returns without doing anything. If the current operation has not been started, the sequencer starts it and returns; polling begins on the next iteration of the main loop. Otherwise, the operation is polled. While it reports `running`, the sequencer performs no further work. When it reports `finished`, the sequencer clears the started flag and advances to the next operation, wrapping to the first after the last. When it reports `aborted`, the sequencer stops and keeps its index on that operation, so the failed step can be read over Modbus.

The sequencer can be stopped, which halts it in place, or restarted, which resets the index to the first operation and sets it running. The Start button always uses the restart path, so the cycle never resumes from the middle of an operation whose physical state may no longer be known.

#place.flush()
=== Move and Homing Operations

@flowchart:move shows a move from start to finish. Its checks repeat on every main-loop pass until the move finishes or aborts. A move never expects its limit switch to be pressed, whichever way it is traveling: heading into the switch is a collision risk, and heading away from it means a stuck or miswired switch, lost steps, or an axis that was never homed.

#figure(
  image(flow + "move-operation.pdf", height: 560pt),
  caption: [A move operation],
  placement: auto,
)<flowchart:move>

Homing, shown in @flowchart:homing, drives the axis toward its switch at homing speed. When the switch trips, the origin is set a fixed back-off away from the switch, 40 mm on the horizontal axis and 20 mm on the vertical axis, and the axis moves to that origin. If the switch is still pressed after backing off, it cannot be trusted and the operation fails. A time limit, derived from the axis travel, the back-off, and the homing speed, catches an axis that never reaches its switch. The poll function of the homing operation is listed in @listing:homing.

#figure(
  image(flow + "homing.pdf", height: 520pt),
  caption: [Homing one axis],
  placement: auto,
)<flowchart:homing>

#place.flush()
=== Motion Controller <sec:motion-planner>

Each axis has its own motion controller, which converts a goal into a continuously updated step rate. The controller supports two control modes. In _position mode_, used for every move in the cycle, it drives the axis to a target step count. In _velocity mode_, it holds a commanded speed; the homing operations use this mode to drive each axis toward its limit switch.

@flowchart:motion-planner shows how the controller updates an axis's speed. The update runs for each axis on every iteration of the main loop in which no fault is latched.

#figure(
  image(flow + "motion-controller.pdf", height: 560pt),
  caption: [One speed update of the motion controller],
  placement: auto,
)<flowchart:motion-planner>

In position mode, the controller first checks whether the axis is exactly on its target step. This check runs on every call, not only once per millisecond, so that a fast-moving axis cannot step past the target unnoticed; when it succeeds, the axis is stopped immediately. Because the system tick advances once per millisecond and the main loop runs much faster, most of the remaining calls find no elapsed time and return early.

Otherwise, the controller decides whether it is time to brake. The distance needed to slow from the current speed $v$ to the landing speed $v_"land"$ at acceleration $a$ is given by @eq:braking. Once the remaining distance falls within that value, a landing flag is set and the desired speed becomes $v_"land"$ instead of $v_"max"$. If the axis is moving away from its target, the desired speed is zero, so the axis first brakes and then reverses. In velocity mode, the desired speed is simply the commanded speed. In both modes, the current speed is then ramped toward the desired speed by at most $a dot Delta t$ and sent to the stepper driver.

The braking test and the speed ramp are listed in @listing:ramp. The resulting motion is a trapezoidal speed profile, accelerating, cruising at $v_"max"$, and braking, followed by a short approach at the landing speed, which lets the axis stop exactly on the target step instead of overshooting or stalling short of it. With the current tuning, the horizontal axis uses $v_"max" = 200$ mm/s, $a = 100$ mm/s², and $v_"land" = 2.5$ mm/s, which the scale factor in @eq:steps-per-mm converts to 8000 steps/s, 4000 steps/s², and 100 steps/s. The vertical axis uses $v_"max" = 20$ mm/s, $a = 10$ mm/s², and $v_"land" = 0.5$ mm/s, or 16,000 steps/s, 8000 steps/s², and 400 steps/s. The usable travel is 550 mm on the horizontal axis and 200 mm on the vertical axis. Each travel is measured from the origin that homing sets, and to the surface of the carriage that is closest to the limit switch, as explained for @cad-dimensions.

=== Step Pulse Generation <sec:step-pulse>

The motion controller only decides _how fast_ each axis should turn; the individual STEP pulses are produced by hardware. TIM2 runs at 1 MHz, and each axis uses one of its channels in output-compare toggle mode. On every compare event, the timer toggles the STEP pin and an interrupt schedules the next toggle half a period later, where the half period in timer ticks is given by @eq:half-period.

The interrupt code is shown in @listing:pulse. The interrupt also counts one step on each active edge, which gives the controller the axis position, and loads any new speed requested by the controller on each inactive edge, so that speed changes never shorten a pulse. When the requested speed is zero, the interrupt stops rescheduling itself and the channel is released.

The STEP and DIR pins are configured as open-drain outputs that sink current from the stepper drivers' optocoupler inputs, whose anodes are tied to 5 V. The microcontroller therefore never drives these lines to 3.3 V, and the 5 V-tolerant pins interface with the drivers directly, without a level-shifting buffer.

=== Fault Handling and Emergency Stop <sec:estop-handling>

Every abnormal condition is represented by one of seven latched faults: emergency stop, interrupted operation, timed-out operation, homing failure on either axis, and limit-switch hit on either axis. Whichever part of the firmware detects the condition raises the fault, but only the main loop reacts to faults and clears them; the latch and the safe state are listed in @listing:faults. While any fault is latched, the machine stays in its safe state: the sequencer and both axes are stopped, and the electromagnet is kept engaged so that a suspended workpiece is not dropped into the bath.

The emergency stop is enforced first by hardware: the normally closed mushroom button releases relay K1, which removes the 24 V supply from the stepper drivers independently of the firmware. A second relay signals the stop to the controller. The input is read at the start of every main-loop pass and is wired so that a broken wire reads the same as a pressed button. Because every module returns within a bounded time, the loop period is short enough that polling detects a press without the need for an external interrupt. The loop timer of the monitor (@fig:dashboard) showed that one whole pass, Modbus included, took about 0.29 ms on average, and between 0.27 ms and 0.31 ms over a 60 s window. The longest pass since the controller was reset was 3.2 ms.

Releasing the emergency stop does not resume the interrupted operation. A first press of the Start button clears the latched faults, and a separate second press restarts the cycle from its first operation, so one press can never do both. Because the drivers lose power during the stop, the axes may coast and the step count may no longer reflect the true gantry position. Because homing is the first stage of the cycle, each restart re-establishes a known position from the limit switches before any other motion.

=== Communications

The Modbus TCP server runs on the W5500 at port 502 and advances one step per main-loop pass without ever blocking. It serves a single connection, so only one Modbus client can be connected to the controller at a time. Read-only registers report the emergency-stop and Start inputs, whether the sequencer is running, whether each axis is on target, the commanded effector state, the current operation index, both axis positions in steps, every latched fault, the fault that came first, and the last and longest main-loop times. Writable registers hold the recipe; a value outside its allowed range is rejected, and a multi-register write is checked in full before anything is applied. A request whose header is malformed, or whose length exceeds the largest the protocol allows, closes the connection, because the start of the next request can no longer be found.

Overall, this architecture combines cooperative scheduling with asynchronous peripheral operation. Hardware timers and their interrupts perform the timing-critical work, while the main loop coordinates higher-level behavior through the sequencer. This keeps the production sequence easy to understand while isolating the detailed control of the motors, end effector, dwell timing, and communications inside dedicated software modules.


== Implementation

This section describes how each module was built, wired, and programmed, and how it was first tested. The complete electrical schematic is shown in @appendix:schematic, and the wiring of each module is described below with the controller pins it used. Problems found during this work are covered in @sec:troubleshooting.

=== X Axis and Frame

The horizontal axis was designed around an aluminum extrusion frame with two linear rails and four bearing blocks, driven by a stepper motor through a GT2 timing belt. The frame extrusions were cut to the required dimensions, and the rails were measured and installed on the base frame. The mechanism was then modeled at full scale in Onshape from the real dimensions of the frame and rails, as shown in @fig:frame-model, including the plate that connects the bearing blocks to the rest of the moving assembly.

#figure(
  image(impl + "x-axis-and-frame/frame-model.png", width: 55%),
  caption: [Full-scale CAD model of the frame with the linear rails and bearing blocks],
)<fig:frame-model>

The parts that carry the belt drive were designed in CAD and 3D printed, as shown in @fig:x-axis-parts. The base plate combines the motor mount with a pocket for the transmission. At the far end of the belt path, a ball bearing and gear were joined through a printed adapter and secured with adhesive; this assembly sits in a holder fixed to the frame, and a printed cap fitted into the holder's groove keeps it from coming out when the belt pulls. @video:bearing-fit shows this fit. The team compared an oblong belt path with an elongated rounded triangle while working out the belt geometry.

#subfigs(
  figure(image(impl + "x-axis-and-frame/base-plate-motor-mount.png", height: 4.2cm), caption: [Base plate with motor mount]),
  figure(image(impl + "x-axis-and-frame/x-axis-holder-motor-mount.png", height: 4.2cm), caption: [X-axis holder with motor mount]),
  figure(image(impl + "x-axis-and-frame/motor-belt-adapter.png", height: 4.2cm), caption: [Motor and belt adapter]),
  figure(image(impl + "x-axis-and-frame/bearing-gear-adapter.png", height: 3cm), caption: [Bearing and gear adapter]),
  figure(image(impl + "x-axis-and-frame/retaining-cap.png", height: 3cm), caption: [Retaining cap]),
  columns: (1fr, 1fr, 1fr),
  column-gutter: 8pt,
  row-gutter: 8pt,
  caption: [X-axis parts in CAD],
  label: <fig:x-axis-parts>,
)

The X-axis holder went through five versions, the last printed 90% solid for strength. Braces were added so that the frame no longer wobbled. In the final adjustments, the rear motor mount and the belt were moved toward the end of the frame so that the mechanism reaches both ends of the axis, as homing requires, and grease was applied to the moving parts. The horizontal NEMA 23 motor was wired to a DM542TE driver powered from the 24 V supply, and its movement was adjusted until it looked right. The driver's STEP and DIR inputs were connected to controller pins PA0 and PB0, and its DIP switches were set to eight microsteps per full step, which gives the 1600 pulses per revolution used in @table:axis-scale. On the first full group test, shown in @video:first-test, both axes moved successfully with the live axis positions displayed on a laptop.

#video("week-8-first-full-test.mp4", [First full test of both axes with the monitor interface])<video:first-test>

#video("week-7-bearing-gear-fit.mp4", [Fitting the ball bearing, adapter, and gear])<video:bearing-fit>

=== Y Axis

The vertical axis was designed with two bearing holders supporting the leadscrew and connecting it to the main base. A brass threaded nut on the leadscrew carries the central section of the magnet holder, so that the holder rises and lowers as the screw turns, while side sliders guide it and keep the magnet aligned. The plate shown in @fig:y-axis-cad joins this assembly to the X-axis carriage.

#subfigs(
  figure(image(impl + "y-axis/vertical-assembly-isometric.png", height: 5cm), caption: [Isometric view]),
  figure(image(impl + "y-axis/vertical-assembly-side-view.png", height: 5cm), caption: [Side view]),
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  caption: [Vertical assembly plate in CAD],
  label: <fig:y-axis-cad>,
)

The vertical motor was wired in the same way to a second DM542TE driver, with its STEP and DIR inputs on controller pins PA1 and PC1 and the same microstep setting. The X-axis base holder and the Y-axis holder were then integrated into a single assembly, and the rails were aligned and secured. The vertical movement was first tested without the magnet by holding the nut so that it could not rotate, and the assembly was later checked by hand and with a drill driving the leadscrew.

=== End Effector

The electromagnet was characterized before it was installed. Its resistance was measured and gave an estimated current of 1.2 A, and a later test connected directly to the 12 V supply with its flyback diode drew about 1.5 A, which is the value used in the power budget. A qualitative test with a hammer showed strong holding force even with little contact area.

The holder in @fig:magnet-holder-cad is a cylindrical cage that seats the magnet at its lower end. Its third version was printed and fitted the magnet smoothly, with a 5/16-inch screw added as a secondary retention. The planned IRLZ44N MOSFET driver was replaced with a 5 V relay module for its better safety behavior: the 12 V supply was wired through the normally closed contact, so the magnet stays powered whenever the relay coil is off, including if the controller resets or loses power. The relay module was powered from the 5 V rail, its input was connected to controller pin PB10, which drives it through an open-drain output, and a flyback diode was placed across the electromagnet to absorb the energy of the coil when the contact opens. Because there is no feedback from the magnet, the cycle waits a settle time after each switch, 300 ms by default and adjustable over Modbus, so that the magnet has time to grip or release the part.

#figure(
  image(impl + "end-effector/y-axis-magnet-holder.png", height: 6.5cm),
  caption: [Y-axis magnet holder in CAD],
)<fig:magnet-holder-cad>

=== Power Distribution and Enclosure

The 24 V supply was assembled and its output adjusted to 24.1 V. The electronics were then placed in a plastic container, as shown in @fig:enclosure, with the stepper drivers and the 24 V supply given fixed positions. The installation was tested with a multimeter, confirming that the stepper drivers could be driven, that the relay worked, and that both supplies behaved correctly. The 24 V supply fed the two stepper drivers through the emergency-stop relay, the 12 V supply fed the electromagnet circuit and the buck converter, and the buck converter provided the 5 V rail for the Nucleo board and the relay modules. During the first full installation of the electronics and mechanics, the team redid much of the wiring and replaced the wire nuts with Wago connectors for cleaner and more reliable connections.

#subfigs(
  figure(image(impl + "power-distribution-and-enclosure/electronics-box-1.jpg", height: 5.5cm), caption: [One side]),
  figure(image(impl + "power-distribution-and-enclosure/electronics-box-2.jpg", height: 5.5cm), caption: [The other side]),
  columns: (1fr, 1fr),
  column-gutter: 12pt,
  caption: [Electronics in the container during installation],
  label: <fig:enclosure>,
)

=== Emergency Stop and Relays

After researching machinery safety and consulting the advisor on interrupting a DC load, the team revised the schematic so that relay modules cut the motor supply on an emergency stop and signal the controller. The normally closed contact of the mushroom button was wired to the coil of relay K1, which switches the 24 V supply of the drivers, and a second relay, K2, signaled the stop to controller pin PB5. In firmware, that input uses an internal pull-down, so a broken wire reads the same as a pressed button. The installed enclosure is shown in @sec:final-design. An informal test confirmed that the emergency stop cut power to the stepper drivers and that the system restarted only after a deliberate press of the Start button. The relay later failed, as described in @sec:relay-failure.

=== Sensing

Each axis was given a normally closed limit switch at the home end of its travel. Each switch was wired between its controller pin, PA8 for X and PA9 for Y, and ground, with the internal pull-up enabled, so an untouched switch reads low, while a pressed switch or a broken wire reads high and stops the axis. The Start button was wired the same way on pin PB4, but with its other contact to ground, so that it reads low when pressed. The switches could not be reliably soldered, so a way of mounting them without soldering was developed, along with a printed holder. In the first test, the X switch was wired and held by hand facing the carriage, and the firmware stopped the motors fast enough that the carriage did not crash into it. The firmware was then extended to read both switches, through a software debounce, and to home both axes.

@fig:limit-switches shows the two switches as mounted, in a frame from a video of the prototype running. The X switch is at the end of the upper rail, on the left in the picture, and the Y switch is on the carriage plate beside the leadscrew. Each switch was glued in place, and the X switch was also wrapped in tape, for extra strength and to hide its wires. With both fitted, the cycle begins with the two homing operations, and @fig:dashboard shows the machine in its homing stage with no fault latched.

#figure(
  image(impl + "sensing/limit-switches-in-video.png", width: 90%),
  caption: [The limit switches as mounted, in a frame from the video of the prototype running. The X switch is at the end of the upper rail, and the Y switch is on the carriage plate],
)<fig:limit-switches>

Part detection changed during the project. An ultrasonic sensor was first selected on the professor's recommendation, but reviewers questioned the need for a sensor when the conveyor is outside the project scope, since the sensor's type and position depend on the conveyor used. With the advisor's approval, the sensor was replaced with a part-ready trigger input, leaving part detection to the external system. The design of the trigger is described in @sec:normal-cycle.

When both switches were first connected they proved very noisy; the fix, a software debounce and braided wires, is described in @sec:limit-noise.

=== Motion Control Firmware

The firmware began with two-axis motion control, and the first hardware work was validating the STEP pulse generation, which was confirmed to produce the correct frequency and timing. A common-anode, open-drain connection was devised so that the 3.3 V controller could drive the 5 V driver inputs through its 5 V-tolerant pins. The first complete controller-to-motor test turned the motor ten times and returned it to the same place. @fig:bench shows the bench setup used for the open-loop test in @video:open-loop, and @video:bench-sim shows a later simulation of both axes with an LED standing in for the electromagnet.

#figure(
  image(impl + "motion-control-firmware/stepper-bench-setup.png", width: 75%),
  caption: [Bench setup for the open-loop test: 24 V supply, DM542TE driver, NEMA 23 motor with a paper flag to show its position, and the Nucleo board with the W5500 module],
)<fig:bench>

#video("week-5-stepper-test.mp4", [Open-loop positioning test of one stepper motor])<video:open-loop>

#video("week-6-stepper-simulation.mp4", [Bench simulation of both axes and the effector signal])<video:bench-sim>

Positions, speeds, and homing distances were later converted to millimeters using the scale factors in @table:axis-scale, and the conversion was tested. The conversion is listed in @listing:scale.

The scale, the travel of both axes, and the positions of the cycle were then tuned to the machine. First, rough values were found by measuring the axes with a long ruler. They were then fine tuned through the Modbus interface, by writing a position to the controller and measuring where the axis actually stopped. The first measurements were made from the center of the carriage, which gave wrong values. The point that matters is the surface of the carriage closest to the limit switch, because that is the part that meets the switch, so every distance was measured from there: from the left side of the horizontal carriage and from the top of the vertical carriage. Correcting this was the fine tuning.

=== Cycle and Fault Firmware

All thirteen operations of the production cycle were implemented in order, with a Start button that restarts the cycle and an emergency stop that halts both axes while keeping the electromagnet engaged. The homing operations were then written, followed by fault handling: homing gained a time limit, a stuck switch became detectable, and a limit-switch press during a move stops the machine. Faults were made to stay latched until a Start press clears them. A full unattended cycle was run, started with the Start button.

A bug found while connecting the X limit switch prompted a review of the firmware's structure, which was reorganized into the layers described in the previous section, around a machine layer that owns the state and lets operations raise their own faults. Static analysis was configured for the firmware at the same stage. Homing was then enabled in the sequence for both axes, with a separate back-off for each. A lost-step check that compared each switch hit with the previous origin was removed at this stage. The main-loop time was then instrumented so that the responsiveness of the cooperative design could be measured. Finally, a code review of the whole firmware found and fixed several defects, described in @sec:review.

=== Communications and Monitoring <sec:monitor>

The W5500 module was connected to the controller over SPI, with the clock, data-in and data-out lines on pins PA5, PA7 and PA6, its chip select on PB6, and its reset on PC7. The project's memory was then mapped to Modbus registers. The registers were first tested with the `madbus-cli` client, confirming that the code worked correctly. A browser-based monitor was then built, with the assistance of Claude Code, to display the Modbus output, and it served as a live view of the commanded axis positions during testing. The monitor runs on a computer connected to the controller's Ethernet port, and because the controller serves one connection, only one copy of it, or of any other Modbus client, can run at a time. The electromagnet state, the active faults, and the main-loop time were later added to both the Modbus map and the monitor, which graphs the loop time over the last 60 s. The monitor was generated with Claude Code, and parts of its code are shown in @sec:monitor-code. @fig:dashboard shows it during a test. It lists the discrete inputs, the latched faults with the first one marked, the axis positions and their history, the loop time, the stage of the cycle that is running, and the parameters that can be written.

#subfigs(
  figure(image(impl + "communications-and-monitoring/dashboard-top.png", width: 100%), caption: [The connection settings, the discrete inputs, the faults table with no fault latched, and the position of the gantry]),
  figure(image(impl + "communications-and-monitoring/dashboard-bottom.png", width: 68%), caption: [The axis positions and their history over the last 60 s, and the loop time]),
  columns: (1fr,),
  row-gutter: 8pt,
  caption: [The Modbus monitor while the cycle ran],
  label: <fig:dashboard>,
)

@fig:dashboard-estop shows the same monitor after an emergency stop. The emergency-stop fault is latched and marked as the first fault, the Fault input is on, and the monitor shows that a Start press clears the fault and that a second press restarts the cycle.

#figure(
  image(impl + "communications-and-monitoring/dashboard-estop-latched.png", width: 100%),
  caption: [The Modbus monitor after an emergency stop: the emergency-stop fault is latched and marked as the first fault],
)<fig:dashboard-estop>


=== Firmware Size Over Time

@fig:loc shows how the amount of firmware grew during the project. It counts the non-blank lines of source that the team wrote, in two groups: the application and the Modbus library. The vendor code (the HAL, CMSIS, and the WIZnet library) and the files that STM32CubeMX generates are not counted. The count was made for every commit of the firmware repository, following the main line of its history. It includes the code written during the summer break, before the build semester, such as the Modbus library.

#figure(
  image(impl + "firmware-size-over-time/loc-over-time.svg", width: 100%),
  caption: [Lines of firmware source over time, counted at every commit],
)<fig:loc>

The Modbus library came first. It was started on June 21 and had about 1,100 lines by early August, when the work on the application began. On August 24, the start of the build semester, the firmware had 2,047 lines in 40 files, 967 of them in the application. The application then grew in steps, to about 1,200 lines by the time the full production cycle ran at the end of September, and to 1,517 lines by November 3. Most of the growth in November came from the fault handling, the homing of both axes, the machine layer, the limit-switch debounce, and the loop timer. At the time of writing, the firmware has 3,168 lines in 57 files: 2,067 in the application and 1,101 in the Modbus library.

== Troubleshooting <sec:troubleshooting>

This section records each significant problem found during the build, its cause, the solution applied, and the result.

=== Limit Switch Triggering a Constant Fault

#issue(
  symptom: [When the X limit switch was connected for the first time, it triggered a fault constantly and the machine could not run.],
  cause: [A firmware bug in the handling of the switch. It was most likely the lost-step ("drift") check, which compared each switch hit with the position that the step count expected. The check was badly set up, in a codebase where the axes had not been calibrated yet, so the expected position was wrong and the check faulted constantly. It was hard to find at first because the firmware showed little of its own state.],
  solution: [The problem led to a re-architecture of the firmware. The code was reorganized into layers around a machine layer that owns the state and lets operations raise their own faults, and the faults and the state were made visible over Modbus and in the monitor. The lost-step ("drift") check, which compared each switch hit with the previous origin, was removed. Homing was then enabled on both axes.],
  result: [The limit switches no longer trigger the constant fault. Both are read correctly, the two axes home at the start of each cycle, and the monitor shows no limit-switch fault (@fig:dashboard).],
)

=== Noisy Limit Switches <sec:limit-noise>

#issue(
  symptom: [When both limit switches were connected for the first time and the system was run, an axis moved only a little during homing and then stopped, as if it had already reached its limit switch. The switch had not been touched. Soon afterward the limit-switch faults appeared, and the machine stopped. The switch inputs were reading as pressed at random moments.],
  cause: [Electrical noise picked up on the switch wires, which carry a pulled-up signal that is easily disturbed. The wires run close to the stepper motors and drivers.],
  solution: [A software debounce, listed in @listing:debounce, was added to the switch inputs: a press counts only once the input has read pressed for 3 ms without a break, while a release counts at once. This improved the readings a great deal, at the price of letting the horizontal axis run about 0.6 mm further past the switch at its maximum speed. Some false triggers still appeared from time to time, so the ground wire and the pulled-up signal wire of each switch cable were braided together, and the cables were routed away from the stepper wiring. Twisting the pair makes both wires pick up the same noise, so it cancels out at the input.],
  result: [With the debounce and the braided wires together, the false triggers stopped.],
)

=== Broken Ball-Bearing Housing

#issue(
  symptom: [Parts of the belt transmission of the X axis broke, on both sides of the axis. The stepper motor adapter was the main failure. The housing of the other ball bearing was damaged, but it was only twisted, not broken.],
  cause: [The belt needs side tension to work properly, and both parts were cantilevered: they were held only from the bottom, on a small surface. The side load of the belt broke them easily.],
  solution: [The stepper motor adapter was given a second hold, at the top as well as at the bottom, and the belt is no longer overtightened. The ridges of the belt transfer the motion, so it does not need much tension. The bearings for the upper part of the X axis were also reworked to stop its pieces from oscillating.],
  result: [Because both axes are homed from their limit switches at the start of each cycle, the occasional lost step does not matter.],
)

=== Belt Tension and Skipped Steps

#issue(
  symptom: [During the first group test, the X axis skipped a few steps.],
  cause: [The skipped steps were largely attributed to the way the belt had been temporarily tensioned.],
  solution: [The motor and belt supports were completed, and the rear motor mount and the belt were moved toward the end of the frame. The belt is no longer overtightened, because its ridges transfer the motion without much tension.],
  result: [The later ruler measurement of the X axis showed drift under 0.5 cm (@sec:test-r02).],
)

=== Electromagnet Overheating

#issue(
  symptom: [The electromagnet overheated while the machine was idle.],
  cause: [The firmware engaged the magnet at startup as its safe default, keeping it energized with no workpiece to hold. The output pin also came up in the state that energizes the magnet until the startup code ran.],
  solution: [The firmware was changed to start with the magnet disengaged, and the pin's initial state was changed to match.],
  result: [The magnet is now energized only when the cycle or a fault requires it.],
)

=== Failed Motor-Supply Relay <sec:relay-failure>

#issue(
  symptom: [The stepper drivers remained powered even when the emergency stop removed power from the relay's coil.],
  cause: [The normally open contact of the relay connecting the 24 V supply to the drivers stayed closed. The team attributed this to a defective component, since the rest of the circuit is within its specifications.],
  solution: [The relay is to be replaced next week, probably by switching the AC side of the power supply instead. Until then, the emergency stop still stops the machine, because the second relay signals the controller, which stops the step pulses.],
  result: [Pending. Requirements R-07 and R-08 must be tested after the replacement.],
)

=== Modbus Connections Dropping

#issue(
  symptom: [The Modbus connection dropped during operation.],
  cause: [A TCP keep-alive had been enabled on the socket so that a client that vanished without closing would not hold the only socket open. With it enabled, Modbus communication broke.],
  solution: [The keep-alive was removed.],
  result: [Modbus communication worked again. The original limitation returns: a client that disappears without closing can hold the socket until the controller is reset.],
)

=== Modbus Stalling the Main Loop

#issue(
  symptom: [Network activity could stall the main loop and delay the step pulses, and after moving to nonblocking sockets, every Modbus connection was aborted.],
  cause: [The socket calls blocked, and interrupts were disabled during each access to the W5500. The vendor library also reported a busy socket before checking whether data had arrived, so a nonblocking socket never read anything.],
  solution: [The socket was made nonblocking, the unnecessary interrupt disabling was removed, and the library was patched to return received data first.],
  result: [The registers were read and written correctly with `madbus-cli`.],
)

=== Defects Found in Code Review <sec:review>

#issue(
  symptom: [No failure had been observed. Before the final tests, the firmware was reviewed for defects that testing might not reveal.],
  cause: [The review found that the Modbus library was told its response buffer was larger than it was, accepted request lengths beyond the largest the protocol allows, and unpacked multi-coil writes into the wrong place. The network gateway address was outside the board's subnet, and a speed profile with zero acceleration would have caused a division by zero.],
  solution: [The buffer size and the request length are now checked, a malformed request header closes the connection, the coil unpacking was corrected, the gateway was moved into the subnet, and the speed limits are kept above zero.],
  result: [The fixes are on a development branch that had not been merged at the time of writing.],
)

=== No Step Pulses From the Timer

#issue(
  symptom: [The timer channel produced no STEP signal.],
  cause: [Repeated speed requests before the first interrupt re-armed the channel from scratch each time, so its counter never reached a compare match. The compare value could also sit far behind the free-running timer.],
  solution: [The driver was changed to arm the channel only once per transition from stopped to moving, and to schedule the first pulse relative to the live counter.],
  result: [The pulses were confirmed on the hardware at the correct frequency and timing.],
)

=== Stepper Overshoot

#issue(
  symptom: [The motor slightly overshot its target position.],
  cause: [The axis arrived at the target while still moving too fast to stop exactly on it.],
  solution: [A landing speed was added, so that the axis approaches its last steps slowly, similar to the creep speed used in elevators.],
  result: [The motor arrived smoothly and returned to the same place after ten turns.],
)

=== Inverted Button Inputs

#issue(
  symptom: [The emergency-stop and Start buttons behaved opposite to their actual state.],
  cause: [Both inputs were read with an inverted comparison.],
  solution: [The polarity was corrected and the duplicated button read was removed.],
  result: [Both buttons were read correctly in the production cycle.],
)

=== 3D Printing and Part Fit

The mechanical parts required learning both Onshape and the slicer software, and several problems came from that learning process.

#issue(
  symptom: [Early prints had rough surfaces and uneven layers, as shown in @fig:printing. In assembly, holes and supports repeatedly missed their positions by a few millimeters, and some parts did not fit or meet their requirements.],
  cause: [The printer configuration, the material, and a lack of print supports caused the surface problems. The fit problems came from offsets that were not considered during design.],
  solution: [The printer settings were corrected and tree supports were added. Holes were enlarged, with 1 mm of added clearance giving a good fit on the frame supports. Several parts were redesigned: an anti-rotation section was added to the holder between the transmission and the belt, with its locking hole enlarged from 2 mm to 6 mm, and the top holder for the stepper was remodeled when the separate leadscrew holder was removed. Sections under stress, such as the connection between the two parts of the X-axis holder, were printed at higher density.],
  result: [The corrected prints came out smooth, as shown in @fig:printing, and the parts assembled. Denser parts are much stronger but take significantly longer to print.],
)

#subfigs(
  figure(image(trouble + "3d-printing-and-part-fit/print-early-attempt.jpg", height: 5cm), caption: [Early print]),
  figure(image(trouble + "3d-printing-and-part-fit/print-corrected-tabs-side.jpg", height: 5cm), caption: [Print after the corrections]),
  figure(image(trouble + "3d-printing-and-part-fit/slicer-preview.png", height: 3.2cm), caption: [Slicer preview, with the tree supports in green]),
  columns: (1fr, 1fr, 1fr),
  column-gutter: 8pt,
  caption: [3D printing of the vertical assembly part],
  label: <fig:printing>,
)

=== Damaged Leadscrew Holder

#issue(
  symptom: [The lower section of the leadscrew holder was damaged.],
  cause: [An accidental impact.],
  solution: [Two aluminum L-brackets were installed to repair and reinforce it, as shown in @fig:holder-repair.],
  result: [The assembly passed the hand and drill tests that followed.],
)

#figure(
  image(trouble + "damaged-leadscrew-holder/holder-repair-l-brackets.png", width: 45%),
  caption: [Lower section of the holder reinforced with two L-brackets],
)<fig:holder-repair>

=== Frame Wobble

#issue(
  symptom: [When the team first saw the full frame together, it wobbled slightly.],
  cause: [The frame had not yet been braced.],
  solution: [Braces were added, using metal L-supports like the one in @fig:frame-bracket.],
  result: [The frame no longer wobbled.],
)

#figure(
  image(trouble + "frame-wobble/frame-l-bracket.jpg", height: 6cm),
  caption: [Metal L-support used to brace the frame],
)<fig:frame-bracket>


== Requirement Testing and Results <sec:testing>

Each requirement in @table:requirements was tested against its success criterion. All testing used an unheated, laboratory-safe medium at room temperature and the approved 1 lb prototype payload; the prototype does not validate operation at the intended industrial temperature or with a production coating medium. The first results were recorded in @video:viability.

#video("viability-video.mp4", [Checkpoint 2 viability demonstration of the integrated prototype])<video:viability>

=== R-01: Part-Ready Trigger

*Requirement.* The system shall not initiate a pick-dip-place cycle unless its part-ready trigger input is asserted. Success criterion: a cycle starts with the trigger asserted; no motion starts with it released or disconnected.

*Test setup.* A push button connected to the trigger input.

*Procedure.* Command a cycle with the trigger asserted, then release it, then disconnect it, and command a cycle each time.

*Results.* Not yet tested.

*Discussion.* The trigger input has not been added to the firmware yet, and the cycle currently starts from the Start button. Its design is described in @sec:normal-cycle: a pair of pins that reads as "part ready" only while it is closed, so the released and disconnected cases are the same state. The test setup is a jumper on the pair. Status: not yet tested.

*Evidence.* None yet.

=== R-02: Pickup Position Accuracy <sec:test-r02>

*Requirement.* The system shall position the end effector at the programmed pickup position within ±1 cm along both axes before acquiring the workpiece. Success criterion: measured error within ±1 cm along both axes.

*Test setup.* A ruler placed along each axis.

*Procedure.* The system was commanded to the programmed pickup position, and the position of the end effector was measured relative to the target.

*Results.* The X axis showed drift under 0.5 cm. The Y axis was harder to measure because the platform moves, and it was judged to be within 1 cm without a precise measurement.

*Discussion.* The X result is a measurement and meets the criterion. The Y result is an estimate, and both axes will be measured again with a recording. A later check of the X axis, with the whole system running, also found it correct, but it was not recorded. Status: met.

*Evidence.* @video:viability.

=== R-03: Workpiece Retention

*Requirement.* The system shall retain the workpiece throughout the complete pick-dip-place cycle without slipping or dropping it. Success criterion: the workpiece does not visibly slip or detach at any point.

*Test setup.* The electromagnet end effector with the approved payload.

*Procedure.* One complete pick-dip-place cycle was executed while observing the workpiece.

*Results.* The workpiece did not slip or fall in the test shown in the video. A weight of 2.5 lb or more with a minimal contact area was also held through a full cycle in an informal test.

*Discussion.* Retention exceeded the requirement in the informal test. Status: met.

*Evidence.* @video:viability ("Screw not slipping test").

=== R-04: Immersion Depth

*Requirement.* The system shall lower the workpiece to the programmed immersion depth within ±1 cm. Success criterion: measured depth within ±1 cm of programmed depth.

*Test setup.* A ruler at the dipping station.

*Procedure.* Execute one dip sequence and measure the actual immersion depth relative to the programmed value.

*Results.* Not yet tested.

*Discussion.* Both axes have since been calibrated, but the immersion depth has not been measured yet. Status: not yet tested.

*Evidence.* None yet.

=== R-05: Dwell Time

*Requirement.* The system shall hold the workpiece at the programmed immersion depth for the programmed dwell time within ±1 s. Success criterion: measured dwell within ±1 s of the programmed value.

*Test setup.* A stopwatch or equivalent timing instrument.

*Procedure.* Execute one dip sequence and measure the dwell period.

*Results.* Not yet documented.

*Discussion.* Cycles with a part were run to check the dwell time, and the dwell looked correct, but there is no recording of it. Status: not yet tested.

*Evidence.* None yet.

=== R-06: Full Unattended Cycle

*Requirement.* The system shall complete one full unattended pick-dip-place cycle, beginning with the part-ready trigger and ending with workpiece release at the output station and return to the home position. Success criterion: every stage completes in order without operator intervention.

*Test setup.* The complete prototype with a workpiece at the input station.

*Procedure.* A cycle was started, and each stage was observed in order.

*Results.* Every stage completed in order without operator intervention, except the start from the part-ready trigger, because the cycle was started with the Start button.

*Discussion.* The start from the part-ready trigger is tested under R-01, which is not implemented yet. Status: met.

*Evidence.* @video:viability.

=== R-07: Emergency-Stop Power Removal

*Requirement.* The system shall remove power from both stepper-motor drivers when the emergency stop is actuated. Success criterion: driver power removed and all axis motion stops.

*Test setup.* A multimeter at the supply terminals of both drivers.

*Procedure.* Actuate the emergency stop while an axis is moving and measure the power supplied to both drivers.

*Results.* Not yet tested.

*Discussion.* An informal test confirmed that the emergency stop cut driver power. The motor-supply relay then failed with its contact closed (@sec:relay-failure), so the emergency stop does not currently remove driver power. It still stops the machine, because the second relay signals the controller, which stops the step pulses. The relay will be replaced next week, probably by switching the AC side of the power supply. The test must be run after the relay is replaced. Status: not yet tested.

*Evidence.* None yet.

=== R-08: Restart Inhibit

*Requirement.* The system shall remain inhibited following an emergency-stop event until the emergency-stop button has been reset and the operator performs a deliberate restart action. Success criterion: no motion occurs until the deliberate restart action is performed.

*Test setup.* The complete prototype with the emergency stop installed.

*Procedure.* Actuate the emergency stop during operation, reset the button, attempt to command motion without the restart action, then perform the restart action and confirm that normal operation resumes.

*Results.* Not yet tested.

*Discussion.* An informal test confirmed that the system restarted only after a deliberate press of the Start button. The test should be documented after the relay is replaced. Status: not yet tested.

*Evidence.* None yet.

=== R-09: State and Fault Reporting

*Requirement.* The system shall transmit its current operating state and any active faults through the selected communications interface during operation. Success criterion: each state transition and the active fault are transmitted with correct labels.

*Test setup.* A laptop running the Modbus monitor, connected to the controller over Ethernet.

*Procedure.* Monitor the interface during one complete cycle and introduce at least one detectable fault.

*Results.* State reporting was shown working in the video. State and faults were then checked informally over Modbus during a cycle. A screen recording of the monitor (@fig:dashboard) shows the operation index, the axis positions, the inputs that show whether each axis is on target, and the highlighted stage of the cycle changing while the cycle ran. It also shows the emergency-stop fault latched and marked as the first fault, with the instruction to press Start to clear it (@fig:dashboard-estop).

*Discussion.* Fault reporting was implemented after the viability video was recorded. The screen recording of the monitor covers the emergency-stop fault, but the other faults have not been shown on it. Status: partially met.

*Evidence.* @video:viability for state reporting, and @fig:dashboard-estop for the fault.

=== R-10: Ten Consecutive Cycles

*Requirement.* The system shall complete ten consecutive unattended full pick-dip-place cycles using the approved prototype payload without dropping a workpiece, missing the intended placement position, or requiring operator intervention between cycles. Success criterion: all ten complete with no drops and no missed placements, and depth and dwell within tolerance.

*Test setup.* The complete prototype, a ruler, and a stopwatch.

*Procedure.* Command ten consecutive full cycles, recording the cycle time, commanded and measured immersion depth, and measured dwell time for each.

*Results.* Not yet tested.

*Discussion.* The test needs the depth to be measured in each cycle. Status: not yet tested.

*Evidence.* None yet.

=== R-11: Rated Payload

*Requirement.* The system shall complete the full pick-dip-place cycle while carrying a workpiece with a mass of 1 lb. Success criterion: the system lifts, transports, lowers, retains, and releases without stalling, losing position, slipping, or dropping.

*Test setup.* The complete prototype with a test weight.

*Procedure.* A weight was attached and one complete cycle was commanded.

*Results.* A weight of 2.5 lb or more, above the required 1 lb, was held through a full cycle in an informal test.

*Discussion.* The informal test exceeded the rated payload. Status: met.

*Evidence.* The informal test recorded on the Final Testing and Results page of the website.

== Verification Summary

@table:verification summarizes the results of @sec:testing, in the order of @table:requirements. Trial counts are marked "--" where they have not been recorded.

#page(flipped: true, margin: 0.45in)[
  #set text(size: 9pt)
  #figure(
    table(
      columns: (auto, 1.5fr, 1.5fr, 1.2fr, 1.8fr, auto, auto, auto),
      align: left + horizon,
      inset: (x: 0.4em, y: 0.4em),
      stroke: 0.5pt,
      table.header(
        [*Req.*],
        [*Requirement*],
        [*Success criterion*],
        [*Test method*],
        [*Measured result*],
        [*Trials passed*],
        [*Pass/Fail*],
        [*Evidence*],
      ),
      [R-01],
      [No cycle without the part-ready trigger],
      [Starts only when asserted],
      [Push button: asserted, released, disconnected],
      [Trigger input not added yet],
      [--],
      [Not yet tested],
      [--],

      [R-02],
      [Pickup position],
      [Within ±1 cm on both axes],
      [Ruler],
      [X: drift under 0.5 cm. Y: judged within 1 cm],
      [--],
      [Met],
      [@video:viability],

      [R-03],
      [Workpiece retention],
      [No visible slip or detachment],
      [One observed cycle],
      [No slip or drop],
      [--],
      [Met],
      [@video:viability],

      [R-04], [Immersion depth], [Within ±1 cm], [Ruler], [Depth not yet measured], [--], [Not yet tested], [--],
      [R-05], [Dwell time], [Within ±1 s], [Stopwatch], [Observed, not documented], [--], [Not yet tested], [--],
      [R-06],
      [Full unattended cycle],
      [All stages in order],
      [One observed cycle],
      [All stages, started with the Start button],
      [--],
      [Met],
      [@video:viability],

      [R-07],
      [E-stop removes driver power],
      [Power removed, motion stops],
      [Multimeter at drivers],
      [Observed earlier; relay has since failed],
      [--],
      [Not yet tested],
      [--],

      [R-08],
      [Restart inhibit],
      [No motion before restart],
      [Reset, attempt motion, restart],
      [Observed, not documented],
      [--],
      [Not yet tested],
      [--],

      [R-09],
      [State and fault reporting],
      [Correct labels transmitted],
      [Modbus monitor, induced fault],
      [State shown; faults checked informally],
      [--],
      [Partially met],
      [@video:viability],

      [R-10],
      [Ten consecutive cycles],
      [All complete, within tolerance],
      [Ten recorded cycles],
      [Depth not yet measured],
      [--],
      [Not yet tested],
      [--],

      [R-11],
      [1 lb payload],
      [Full cycle without failure],
      [One cycle with weight],
      [2.5 lb or more held through a cycle],
      [--],
      [Met],
      [--],
    ),
    caption: [Verification summary of the system requirements],
  )<table:verification>
]


== Final Design <sec:final-design>

@fig:final-gantry shows the current build of the gantry, and @fig:final-details shows the moving assembly, the end effector, and the electronics. @fig:video-frame is a frame from a video of the assembled prototype running, with the limit switches fitted.

#figure(
  image(final + "frame-assembled.jpg", height: 11cm),
  caption: [Safe Dip gantry: aluminum frame, two horizontal rails, and the Y-axis assembly with its stepper motor],
)<fig:final-gantry>

#subfigs(
  figure(image(final + "y-axis-on-rails.jpg", height: 6.5cm), caption: [Y-axis assembly on the X-axis rails]),
  figure(image(final + "magnet-holder.jpg", height: 6.5cm), caption: [Magnet holder with the electromagnet and the screw used as secondary retention]),
  figure(image(final + "estop-electronics.jpg", height: 6.5cm), caption: [Emergency-stop button with the enclosure holding the relay modules, stepper drivers, 24 V supply, and Nucleo board]),
  columns: (1fr, 1fr, 1fr),
  column-gutter: 8pt,
  caption: [Details of the assembled prototype],
  label: <fig:final-details>,
)

#figure(
  image(final + "prototype-running-frame.png", width: 85%),
  caption: [Frame from a video of the assembled prototype running, with the limit switches fitted],
)<fig:video-frame>

