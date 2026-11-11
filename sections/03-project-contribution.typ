#import "@preview/zero:0.5.0": zi, ztable
#import "../template.typ": chapter, todo

// Images live in one folder per subtitle of this chapter.
#let flow = "/images/chapter-3/design-integration-and-flow-charts/"
#let impl = "/images/chapter-3/implementation/"
#let trouble = "/images/chapter-3/troubleshooting/"
#let final = "/images/chapter-3/final-design/"

#let site = "https://safe-dip.vercel.app/progress/"

// A numbered video with a link, as the course asks: "Video 3.1: Title, https://..."
#let video(file, caption) = figure(
  [],
  kind: "video",
  supplement: [Video],
  gap: 0pt,
  caption: [#caption, #link(site + file)],
)

// One problem from the build, in the order the course asks for.
#let issue(symptom: none, cause: none, solution: none, result: none) = [
  *Symptom.* #symptom

  *Cause.* #cause

  *Solution.* #solution

  *Result.* #result
]

#chapter(
  description: [This chapter presents the work carried out to turn the Safe Dip design into a working prototype. It explains how the hardware and firmware modules connect and operate together, describes how each module was built, wired, and programmed, and records the significant problems found along the way with their causes and solutions. It then tests each system requirement against its success criterion, summarizes the results, and shows the prototype as built.]
)[Project Contribution]

== Design Integration and Flow Charts

Safe Dip is organized around the NUCLEO-F446RE controller, which connects every module shown in @block-diagram:hardware and wired as shown in @figure:schematic. The controller sends STEP and DIR signals to the two DM542TE drivers, which power the NEMA 23 motors from the 24 V supply through relay K1. It reads the emergency-stop signal, the Start button, and the limit switches, drives the relay that switches the electromagnet from the 12 V supply, and communicates with the W5500 Ethernet module over SPI to publish the machine state through Modbus TCP. The emergency-stop button acts on the motor supply through the relays independently of the controller, so the firmware adds to that protection but is not part of it.

The control software uses a cooperative, nonblocking architecture. Rather than executing the complete pick-dip-place cycle as one blocking function, the software is divided into modules that are processed repeatedly from a single main loop: the cycle sequencer, one motion controller per axis, and the communications interface. Each call into a module performs a bounded amount of work and returns immediately. This keeps the controller responsive to the emergency stop, the limit switches, the Start button, and communication requests while a movement, effector operation, or dwell is still in progress.

The firmware is divided into layers, and the build system rejects any dependency that points the wrong way. The driver layer handles timers and pins; the control layer turns a position request into a speed over time; the sequencer runs an ordered list of steps; the operations layer defines the kinds of step that exist; and the application layer is the only one that knows the whole machine, including its axes, cycle, and Modbus registers.

#figure(
  image(flow + "Main Loop.svg", height: 80%),
  caption: [One pass of the firmware's main loop],
  placement: auto,
)<flowchart:main-structure>

As shown in @flowchart:main-structure, the software first initializes the Ethernet controller, the Modbus TCP task, and the motion controllers, disengages the electromagnet, and then enters a continuous main loop. Each pass reads all inputs and the time once, so that everything in that pass acts on the same values. Two safety checks then run before the sequencer: any axis moving into its limit switch is stopped, and a pressed emergency stop raises a fault. A press of the Start button with the emergency stop released either clears the latched faults or, if there are none and the cycle is stopped, restarts the cycle.

If no fault is latched, the sequencer is stepped, and the current operation may itself raise a fault. A second check follows immediately, so a fault acts on the same pass in which it is raised: the machine enters its safe state instead of running the motion controllers. The duration of the pass is then recorded with the processor's cycle counter, which shows how quickly the firmware can respond. The communications interface is serviced last on every pass, including during a fault, so that the system state remains observable.

#place.flush()
=== Normal Cycle Sequence

The normal operating cycle is represented as an ordered list of thirteen nonblocking operations, shown in @flowchart:normal-cycle and grouped into five process stages: home, pick, dip, deposit, and release. After the last operation completes, the sequence wraps around to the first, so the gantry repeats the cycle, homing both axes again at the start of each one.

#figure(
  image(flow + "Cycles Normal Sequence.svg", width: 100%),
  caption: [Normal pick-dip-place operation sequence],
  placement: auto,
)<flowchart:normal-cycle>

Each operation represents an absolute objective rather than a blocking procedure. For example, `MOVE_Y_UP` requests that the vertical axis move to its configured upper position. The operation hands the target to the motion controller and returns immediately; the sequencer then keeps checking the operation until the axis reports that the target has been reached. Positions and the dwell time are held in a recipe, in millimeters and milliseconds, that can be changed over Modbus.

The home stage runs the vertical axis first, so that the end effector is raised before the gantry travels horizontally. Homing leaves the horizontal axis at its origin, which is where the pick stage takes place.

#todo[Update this section once the part-ready trigger is added. The firmware has no trigger input yet: the cycle currently starts from the Start button.]

#place.flush()
=== Operation Interface <sec:operation-interface>

Every entry in the sequence is an object implementing the same two-function interface:

- `start()` begins the operation, for example by giving a target position to a motion controller, and returns immediately.
- `poll()` performs any work the operation needs and reports whether the operation is still `running`, has `finished`, or was `aborted`.

The sequencer only ever calls these two functions. The correct implementation is selected at runtime through C++ virtual functions, so the sequencer needs no knowledge of which module is responsible for an operation or how that module works.

Each operation copies every configurable value it depends on when it starts. A value changed while an operation is running, for example through Modbus, therefore takes effect the next time that operation starts and never alters a run already in progress. An operation that cannot complete raises the fault that explains why before it reports `aborted`. @table:operations lists the operations.

#figure(
  table(
    columns: 4,
    align: left + horizon,
    inset: (x: .5em, y: .75em),
    table.header([*Operation*], [*`start()`*], [*Finished when…*], [*Aborted when…*]),
    [Move axis], [Converts the position to steps and sets the target], [The axis is on the target step], [Its limit switch is pressed, or something else stopped the move],
    [Home axis], [Moves toward the limit switch at homing speed], [The axis has backed off the switch and the switch has released], [The switch stays pressed after backing off, or the time limit passes],
    [Effector], [Engages or releases the electromagnet], [Immediately], [Never],
    [Dwell], [Records the start time and the dwell duration], [The dwell duration has elapsed], [Never],
  ),
  caption: [Operations available to the sequencer]
)<table:operations>

This produces a clear abstraction boundary. The sequencer does not need to know which hardware timer is assigned to an axis, which GPIO pins control the stepper drivers, how many steps remain, or how the acceleration profile is calculated. Conversely, the modules do not need to know the structure of the pick-dip-place sequence, so each one can be developed and tested independently.

#place.flush()
=== Cycle Sequencer

The cycle sequencer keeps an index to the current operation, a flag indicating whether that operation has been started, and a flag indicating whether the system is running. @flowchart:sequencer shows one sequencer step.

#figure(
  image(flow + "Sequencer.svg", width: 90%),
  caption: [One step of the cooperative cycle sequencer],
  placement: auto,
)<flowchart:sequencer>

If the system is not running, the step returns without doing anything. If the current operation has not been started, the sequencer starts it and returns; polling begins on the next iteration of the main loop. Otherwise, the operation is polled. While it reports `running`, the sequencer performs no further work. When it reports `finished`, the sequencer clears the started flag and advances to the next operation, wrapping to the first after the last. When it reports `aborted`, the sequencer stops and keeps its index on that operation, so the failed step can be read over Modbus.

The sequencer can be stopped, which halts it in place, or restarted, which resets the index to the first operation and sets it running. The Start button always uses the restart path, so the cycle never resumes from the middle of an operation whose physical state may no longer be known.

#place.flush()
=== Move and Homing Operations

@flowchart:move shows how a move is checked on each poll. A move never expects its limit switch to be pressed, whichever way it is traveling: heading into the switch is a collision risk, and heading away from it means a stuck or miswired switch, lost steps, or an axis that was never homed.

#figure(
  image(flow + "Move Operation.svg", width: 75%),
  caption: [One poll of a move operation],
  placement: auto,
)<flowchart:move>

Homing, shown in @flowchart:homing, drives the axis toward its switch at homing speed. When the switch trips, the origin is set a fixed back-off away from the switch, 40 mm on the horizontal axis and 20 mm on the vertical axis, and the axis moves to that origin. If the switch is still pressed after backing off, it cannot be trusted and the operation fails. A time limit, derived from the axis travel, the back-off, and the homing speed, catches an axis that never reaches its switch.

#figure(
  image(flow + "Homing.svg", width: 100%),
  caption: [One poll of the homing operation],
  placement: auto,
)<flowchart:homing>

#place.flush()
=== Motion Controller <sec:motion-planner>

Each axis has its own motion controller, which converts a goal into a continuously updated step rate. The controller supports two control modes. In _position mode_, used for every move in the cycle, it drives the axis to a target step count. In _velocity mode_, it holds a commanded speed; the homing operations use this mode to drive each axis toward its limit switch.

@flowchart:motion-planner shows one call of the controller's `process()` function, which is made for each axis on every iteration of the main loop in which no fault is latched.

#figure(
  image(flow + "Motion Planner.svg", width: 100%),
  caption: [One call of the motion controller's `process()` function],
  placement: auto,
)<flowchart:motion-planner>

In position mode, the controller first checks whether the axis is exactly on its target step. This check runs on every call, not only once per millisecond, so that a fast-moving axis cannot step past the target unnoticed; when it succeeds, the axis is stopped immediately. Because the system tick advances once per millisecond and the main loop runs much faster, most of the remaining calls find no elapsed time and return early.

Otherwise, the controller decides whether it is time to brake. The distance needed to slow from the current speed $v$ to the landing speed $v_"land"$ at acceleration $a$ is given by @eq:braking. Once the remaining distance falls within that value, a landing flag is set and the desired speed becomes $v_"land"$ instead of $v_"max"$. If the axis is moving away from its target, the desired speed is zero, so the axis first brakes and then reverses. In velocity mode, the desired speed is simply the commanded speed. In both modes, the current speed is then ramped toward the desired speed by at most $a dot Delta t$ and sent to the stepper driver.

The resulting motion is a trapezoidal speed profile, accelerating, cruising at $v_"max"$, and braking, followed by a short approach at the landing speed, which lets the axis stop exactly on the target step instead of overshooting or stalling short of it. With the current tuning, the horizontal axis uses $v_"max" = 200$ mm/s, $a = 100$ mm/s², and $v_"land" = 2.5$ mm/s, which the scale factor in @eq:steps-per-mm converts to 8000 steps/s, 4000 steps/s², and 100 steps/s. The vertical axis uses $v_"max" = 50$ mm/s, $a = 40$ mm/s², and $v_"land" = 0.5$ mm/s, or 10,000 steps/s, 8000 steps/s², and 100 steps/s.

=== Step Pulse Generation <sec:step-pulse>

The motion controller only decides _how fast_ each axis should turn; the individual STEP pulses are produced by hardware. TIM2 runs at 1 MHz, and each axis uses one of its channels in output-compare toggle mode. On every compare event, the timer toggles the STEP pin and an interrupt schedules the next toggle half a period later, where the half period in timer ticks is given by @eq:half-period.

The interrupt also counts one step on each active edge, which gives the controller the axis position, and loads any new speed requested by the controller on each inactive edge, so that speed changes never shorten a pulse. When the requested speed is zero, the interrupt stops rescheduling itself and the channel is released.

The STEP and DIR pins are configured as open-drain outputs that sink current from the stepper drivers' optocoupler inputs, whose anodes are tied to 5 V. The microcontroller therefore never drives these lines to 3.3 V, and the 5 V-tolerant pins interface with the drivers directly, without a level-shifting buffer.

=== Fault Handling and Emergency Stop <sec:estop-handling>

Every abnormal condition is represented by one of seven latched faults: emergency stop, interrupted operation, timed-out operation, homing failure on either axis, and limit-switch hit on either axis. Whichever part of the firmware detects the condition raises the fault, but only the main loop reacts to faults and clears them. While any fault is latched, the machine stays in its safe state: the sequencer and both axes are stopped, and the electromagnet is kept engaged so that a suspended workpiece is not dropped into the bath.

The emergency stop is enforced first by hardware: the normally closed mushroom button releases relay K1, which removes the 24 V supply from the stepper drivers independently of the firmware. A second relay signals the stop to the controller. The input is read at the start of every main-loop pass and is wired so that a broken wire reads the same as a pressed button. Because every module returns within a bounded time, the loop period is short enough that polling detects a press without the need for an external interrupt.

Releasing the emergency stop does not resume the interrupted operation. A first press of the Start button clears the latched faults, and a separate second press restarts the cycle from its first operation, so one press can never do both. Because the drivers lose power during the stop, the axes may coast and the step count may no longer reflect the true gantry position. Because homing is the first stage of the cycle, each restart re-establishes a known position from the limit switches before any other motion.

=== Communications

The Modbus TCP server runs on the W5500 at port 502 and advances one step per main-loop pass without ever blocking. Read-only registers report the emergency-stop and Start inputs, whether the sequencer is running, whether each axis is on target, the commanded effector state, the current operation index, both axis positions in steps, every latched fault, the fault that came first, and the last and longest main-loop times. Writable registers hold the recipe; a value outside its allowed range is rejected, and a multi-register write is checked in full before anything is applied.

Overall, this architecture combines cooperative scheduling with asynchronous peripheral operation. Hardware timers and their interrupts perform the timing-critical work, while the main loop coordinates higher-level behavior through the sequencer. This keeps the production sequence easy to understand while isolating the detailed control of the motors, end effector, dwell timing, and communications inside dedicated software modules.


== Implementation

This section describes how each module was built, wired, and programmed, and how it was first tested. Problems found during this work are covered in @sec:troubleshooting.

=== X Axis and Frame

The horizontal axis was designed around an aluminum extrusion frame with two linear rails and four bearing blocks, driven by a stepper motor through a GT2 timing belt. The frame extrusions were cut to the required dimensions, and the rails were measured and installed on the base frame. The mechanism was then modeled at full scale in Onshape from the real dimensions of the frame and rails, as shown in @fig:frame-model, including the plate that connects the bearing blocks to the rest of the moving assembly.

#figure(
  image(impl + "x-axis-and-frame/frame-model.png", width: 55%),
  caption: [Full-scale CAD model of the frame with the linear rails and bearing blocks],
)<fig:frame-model>

The parts that carry the belt drive were designed in CAD and 3D printed, as shown in @fig:x-axis-parts. The base plate combines the motor mount with a pocket for the transmission. At the far end of the belt path, a ball bearing and gear were joined through a printed adapter and secured with adhesive; this assembly sits in a holder fixed to the frame, and a printed cap fitted into the holder's groove keeps it from coming out when the belt pulls. @video:bearing-fit shows this fit. The team compared an oblong belt path with an elongated rounded triangle while working out the belt geometry.

#figure(
  grid(
    columns: 3,
    gutter: 8pt,
    image(impl + "x-axis-and-frame/base-plate-motor-mount.png", height: 4.2cm),
    image(impl + "x-axis-and-frame/x-axis-holder-motor-mount.png", height: 4.2cm),
    image(impl + "x-axis-and-frame/motor-belt-adapter.png", height: 4.2cm),
    image(impl + "x-axis-and-frame/bearing-gear-adapter.png", height: 3cm),
    image(impl + "x-axis-and-frame/retaining-cap.png", height: 3cm),
  ),
  caption: [X-axis parts in CAD. Top, left to right: base plate with motor mount, X-axis holder with motor mount, motor and belt adapter. Bottom: bearing and gear adapter, retaining cap],
)<fig:x-axis-parts>

The X-axis holder went through five versions, the last printed 90% solid for strength. Braces were added so that the frame no longer wobbled. In the final adjustments, the rear motor mount and the belt were moved toward the end of the frame so that the mechanism reaches both ends of the axis, as homing requires, and grease was applied to the moving parts. On the first full group test, shown in @video:first-test, both axes moved successfully with the live axis positions displayed on a laptop.

#video("week-8-first-full-test.mp4", [First full test of both axes with the monitor interface])<video:first-test>

#video("week-7-bearing-gear-fit.mp4", [Fitting the ball bearing, adapter, and gear])<video:bearing-fit>

=== Y Axis

The vertical axis was designed with two bearing holders supporting the leadscrew and connecting it to the main base. A brass threaded nut on the leadscrew carries the central section of the magnet holder, so that the holder rises and lowers as the screw turns, while side sliders guide it and keep the magnet aligned. The plate shown in @fig:y-axis-cad joins this assembly to the X-axis carriage.

#figure(
  grid(
    columns: 2,
    gutter: 12pt,
    image(impl + "y-axis/vertical-assembly-isometric.png", height: 5cm),
    image(impl + "y-axis/vertical-assembly-side-view.png", height: 5cm),
  ),
  caption: [Vertical assembly plate in CAD: isometric view (left) and side view (right)],
)<fig:y-axis-cad>

The X-axis base holder and the Y-axis holder were then integrated into a single assembly, and the rails were aligned and secured. The vertical movement was first tested without the magnet by holding the nut so that it could not rotate, and the assembly was later checked by hand and with a drill driving the leadscrew.

=== End Effector

The electromagnet was characterized before it was installed. Its resistance was measured and gave an estimated current of 1.2 A, and a later test connected directly to the 12 V supply with its flyback diode drew about 1.5 A, which is the value used in the power budget. A qualitative test with a hammer showed strong holding force even with little contact area.

The holder in @fig:magnet-holder-cad is a cylindrical cage that seats the magnet at its lower end. Its third version was printed and fitted the magnet smoothly, with a 5/16-inch screw added as a secondary retention. The planned IRLZ44N MOSFET driver was replaced with a 5 V relay module for its better safety behavior: the 12 V supply runs through the normally closed contact, so the magnet stays powered whenever the relay coil is off, including if the controller resets or loses power. The controller drives the relay input through an open-drain output.

#figure(
  image(impl + "end-effector/y-axis-magnet-holder.png", height: 6.5cm),
  caption: [Y-axis magnet holder in CAD],
)<fig:magnet-holder-cad>

=== Power Distribution and Enclosure

The 24 V supply was assembled and its output adjusted to 24.1 V. The electronics were then placed in a plastic container, as shown in @fig:enclosure, with the stepper drivers and the 24 V supply given fixed positions. The installation was tested with a multimeter, confirming that the stepper drivers could be driven, that the relay worked, and that both supplies behaved correctly. During the first full installation of the electronics and mechanics, the team redid much of the wiring and replaced the wire nuts with Wago connectors for cleaner and more reliable connections.

#figure(
  grid(
    columns: 2,
    gutter: 12pt,
    image(impl + "power-distribution-and-enclosure/electronics-box-1.jpg", height: 5.5cm),
    image(impl + "power-distribution-and-enclosure/electronics-box-2.jpg", height: 5.5cm),
  ),
  caption: [Electronics in the container during installation, seen from both sides],
)<fig:enclosure>

#todo[Confirm the final 12 V adapter. The Progress Log says the one used for the first tests met the specifications but was not the final one.]

=== Emergency Stop and Relays

After researching machinery safety and consulting the advisor on interrupting a DC load, the team revised the schematic so that relay modules cut the motor supply on an emergency stop and signal the controller. In firmware, the emergency-stop input uses a pull-down with the normally closed contact connected to 3.3 V, so a broken wire reads as a pressed button. The installed enclosure is shown in @sec:final-design. An informal test confirmed that the emergency stop cut power to the stepper drivers and that the system restarted only after a deliberate press of the Start button. The relay later failed, as described in @sec:relay-failure.

=== Sensing

Each axis has a normally closed limit switch at the home end of its travel, so a broken wire reads the same as a tripped switch. The switches could not be reliably soldered, so a way of mounting them without soldering was developed, along with a printed holder. In the first test, the X switch was wired and held by hand facing the carriage, and the firmware stopped the motors fast enough that the carriage did not crash into it. The firmware was then extended to read both switches and to home both axes.

Part detection changed during the project. An ultrasonic sensor was first selected on the professor's recommendation, but reviewers questioned the need for a sensor when the conveyor is outside the project scope, since the sensor's type and position depend on the conveyor used. With the advisor's approval, the sensor was replaced with a part-ready trigger input, leaving part detection to the external system.

#todo[Add a photo of the mounted limit switches, and describe how they were mounted and the first homing test of both axes. Describe the part-ready trigger once it is added: the firmware has no trigger input yet.]

=== Motion Control Firmware

The firmware began with two-axis motion control, and the first hardware work was validating the STEP pulse generation, which was confirmed to produce the correct frequency and timing. A common-anode, open-drain connection was devised so that the 3.3 V controller could drive the 5 V driver inputs through its 5 V-tolerant pins. The first complete controller-to-motor test turned the motor ten times and returned it to the same place. @fig:bench shows the bench setup used for the open-loop test in @video:open-loop, and @video:bench-sim shows a later simulation of both axes with an LED standing in for the electromagnet.

#figure(
  image(impl + "motion-control-firmware/stepper-bench-setup.png", width: 75%),
  caption: [Bench setup for the open-loop test: 24 V supply, DM542TE driver, NEMA 23 motor with a paper flag to show its position, and the Nucleo board with the W5500 module],
)<fig:bench>

#video("week-5-stepper-test.mp4", [Open-loop positioning test of one stepper motor])<video:open-loop>

#video("week-6-stepper-simulation.mp4", [Bench simulation of both axes and the effector signal])<video:bench-sim>

Positions, speeds, and homing distances were later converted to millimeters using the scale factors in @table:axis-scale, and the conversion was tested.

#todo[The Y-axis calibration is still pending. Measure the travel of one revolution to confirm the 8 mm lead used in @table:axis-scale. The Weekly Task Plan still says 2 mm lead and 800 steps/mm.]

=== Cycle and Fault Firmware

All thirteen operations of the production cycle were implemented in order, with a Start button that restarts the cycle and an emergency stop that halts both axes while keeping the electromagnet engaged. The homing operations were then written, followed by fault handling: homing gained a time limit, a stuck switch became detectable, and a limit-switch press during a move stops the machine. Faults were made to stay latched until a Start press clears them. A full unattended cycle was run, started with the Start button.

A bug found while connecting the X limit switch prompted a review of the firmware's structure, which was reorganized into the layers described in the previous section, around a machine layer that owns the state and lets operations raise their own faults. Static analysis was configured for the firmware at the same stage. Homing was then enabled in the sequence for both axes, with a separate back-off for each. A lost-step check that compared each switch hit with the previous origin was removed at this stage. Finally, the main-loop time was instrumented so that the responsiveness of the cooperative design could be measured.

=== Communications and Monitoring

The W5500 module was connected to the controller over SPI, and the project's memory was mapped to Modbus registers. The registers were first tested with the `madbus-cli` client, confirming that the code worked correctly. A browser-based monitor was then built, with the assistance of Claude Code, to display the Modbus output, and it served as a live view of the commanded axis positions during testing. The electromagnet state, the active faults, and the main-loop time were later added to both the Modbus map and the monitor, which graphs the loop time over the last 60 s.


== Troubleshooting <sec:troubleshooting>

This section records each significant problem found during the build, its cause, the solution applied, and the result.

=== Limit Switch Triggering a Constant Fault

#issue(
  symptom: [When the X limit switch was connected for the first time, it triggered a fault constantly and the machine could not run.],
  cause: [A firmware bug in the handling of the switch.],
  solution: [A fix was written, and the problem led to a review and reorganization of the firmware's structure. Homing was later enabled on both axes.],
  result: [To be completed.],
)

#todo[State the exact cause of the bug and the retest result. The firmware later removed the lost-step check and raised the homing back-off from 2 mm to 40 mm (X) and 20 mm (Y); say whether those changes were part of this fix.]

=== Broken Ball-Bearing Housing

#issue(
  symptom: [The ball-bearing housing broke on both sides.],
  cause: [To be completed.],
  solution: [Bearings were reworked for the upper part of the X axis to stop its pieces from oscillating.],
  result: [The new prototype was being printed and tested at the time of writing.],
)

#todo[Adriano: complete the cause, the solution, and the result, and add a photo. The sources only name this problem.]

=== Belt Tension and Skipped Steps

#issue(
  symptom: [During the first group test, the X axis skipped a few steps.],
  cause: [The skipped steps were largely attributed to the way the belt had been temporarily tensioned.],
  solution: [The motor and belt supports were completed, and the rear motor mount and the belt were moved toward the end of the frame.],
  result: [The later ruler measurement of the X axis showed drift under 0.5 cm (@sec:test-r02).],
)

#todo[Describe how the belt is tensioned in the final design.]

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
  solution: [The relay is to be replaced.],
  result: [Pending. Requirements R-07 and R-08 must be tested after the replacement.],
)

#todo[Record the replacement and the retest. Section 2.2 already names a welded K1 contact as the remaining single point of failure, so this failure can be discussed against that analysis.]

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

#figure(
  grid(
    columns: 3,
    gutter: 8pt,
    image(trouble + "3d-printing-and-part-fit/print-early-attempt.jpg", height: 5cm),
    image(trouble + "3d-printing-and-part-fit/print-corrected-tabs-side.jpg", height: 5cm),
    image(trouble + "3d-printing-and-part-fit/slicer-preview.png", height: 3.2cm),
  ),
  caption: [Early print (left), print after the corrections (center), and slicer preview with tree supports in green (right)],
)<fig:printing>

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

#todo[Most tests below have no recorded trial counts or formal measurements yet. Fill in each one as it is run. Nothing here should be read as a result unless it is stated under Results.]

=== R-01: Part-Ready Trigger

*Requirement.* The system shall not initiate a pick-dip-place cycle unless its part-ready trigger input is asserted. Success criterion: a cycle starts with the trigger asserted; no motion starts with it released or disconnected.

*Test setup.* A push button connected to the trigger input.

*Procedure.* Command a cycle with the trigger asserted, then release it, then disconnect it, and command a cycle each time.

*Results.* Not yet tested.

*Discussion.* The trigger input has not been added to the firmware; the cycle currently starts from the Start button. Status: not yet tested.

*Evidence.* None yet.

=== R-02: Pickup Position Accuracy <sec:test-r02>

*Requirement.* The system shall position the end effector at the programmed pickup position within ±1 cm along both axes before acquiring the workpiece. Success criterion: measured error within ±1 cm along both axes.

*Test setup.* A ruler placed along each axis.

*Procedure.* The system was commanded to the programmed pickup position, and the position of the end effector was measured relative to the target.

*Results.* The X axis showed drift under 0.5 cm. The Y axis was harder to measure because the platform moves, and it was judged to be within 1 cm without a precise measurement.

*Discussion.* The X result meets the criterion. The Y result is only an estimate and should be repeated after the Y-axis calibration. Status: provisional pass.

*Evidence.* @video:viability.

#todo[Record the number of trials and the measured Y error.]

=== R-03: Workpiece Retention

*Requirement.* The system shall retain the workpiece throughout the complete pick-dip-place cycle without slipping or dropping it. Success criterion: the workpiece does not visibly slip or detach at any point.

*Test setup.* The electromagnet end effector with the approved payload.

*Procedure.* One complete pick-dip-place cycle was executed while observing the workpiece.

*Results.* The workpiece did not slip or fall in the test shown in the video. A weight of 2.5 lb or more with a minimal contact area was also held through a full cycle in an informal test.

*Discussion.* Retention exceeded the requirement in the informal test. Status: pass.

*Evidence.* @video:viability ("Screw not slipping test").

#todo[Record the number of trials.]

=== R-04: Immersion Depth

*Requirement.* The system shall lower the workpiece to the programmed immersion depth within ±1 cm. Success criterion: measured depth within ±1 cm of programmed depth.

*Test setup.* A ruler at the dipping station.

*Procedure.* Execute one dip sequence and measure the actual immersion depth relative to the programmed value.

*Results.* Not yet tested.

*Discussion.* The test depends on the Y-axis calibration, which is still pending. Status: not yet tested.

*Evidence.* None yet.

=== R-05: Dwell Time

*Requirement.* The system shall hold the workpiece at the programmed immersion depth for the programmed dwell time within ±1 s. Success criterion: measured dwell within ±1 s of the programmed value.

*Test setup.* A stopwatch or equivalent timing instrument.

*Procedure.* Execute one dip sequence and measure the dwell period.

*Results.* Not yet documented.

*Discussion.* Cycles with a part were run to check the dwell time, but the result was not documented formally. Status: not yet tested formally.

*Evidence.* None yet.

=== R-06: Full Unattended Cycle

*Requirement.* The system shall complete one full unattended pick-dip-place cycle, beginning with the part-ready trigger and ending with workpiece release at the output station and return to the home position. Success criterion: every stage completes in order without operator intervention.

*Test setup.* The complete prototype with a workpiece at the input station.

*Procedure.* A cycle was started, and each stage was observed in order.

*Results.* Every stage completed in order without operator intervention, except the start from the part-ready trigger, because the cycle was started with the Start button.

*Discussion.* The requirement as written begins with the trigger, so it is not fully met until R-01 is implemented. Status: partial.

*Evidence.* @video:viability.

#todo[Record the number of trials, and repeat the test with the trigger.]

=== R-07: Emergency-Stop Power Removal

*Requirement.* The system shall remove power from both stepper-motor drivers when the emergency stop is actuated. Success criterion: driver power removed and all axis motion stops.

*Test setup.* A multimeter at the supply terminals of both drivers.

*Procedure.* Actuate the emergency stop while an axis is moving and measure the power supplied to both drivers.

*Results.* Not yet tested formally.

*Discussion.* An informal test confirmed that the emergency stop cut driver power. The motor-supply relay then failed with its contact closed (@sec:relay-failure), so the emergency stop does not currently remove driver power. The test must be run after the relay is replaced. Status: not yet tested formally.

*Evidence.* None yet.

=== R-08: Restart Inhibit

*Requirement.* The system shall remain inhibited following an emergency-stop event until the emergency-stop button has been reset and the operator performs a deliberate restart action. Success criterion: no motion occurs until the deliberate restart action is performed.

*Test setup.* The complete prototype with the emergency stop installed.

*Procedure.* Actuate the emergency stop during operation, reset the button, attempt to command motion without the restart action, then perform the restart action and confirm that normal operation resumes.

*Results.* Not yet tested formally.

*Discussion.* An informal test confirmed that the system restarted only after a deliberate press of the Start button. The test should be documented after the relay is replaced. Status: not yet tested formally.

*Evidence.* None yet.

=== R-09: State and Fault Reporting

*Requirement.* The system shall transmit its current operating state and any active faults through the selected communications interface during operation. Success criterion: each state transition and the active fault are transmitted with correct labels.

*Test setup.* A laptop running the Modbus monitor, connected to the controller over Ethernet.

*Procedure.* Monitor the interface during one complete cycle and introduce at least one detectable fault.

*Results.* State reporting was shown working in the video. State and faults were then checked informally over Modbus during a cycle.

*Discussion.* Fault reporting was implemented after the video was recorded, so the fault half of the requirement has no recorded evidence. Status: partial.

*Evidence.* @video:viability for state reporting.

#todo[Record a video of a fault appearing on the monitor. Update the monitor's stage list first: it still labels the first two operations as moves, but they are now the two homing operations, and the criterion requires correct labels.]

=== R-10: Ten Consecutive Cycles

*Requirement.* The system shall complete ten consecutive unattended full pick-dip-place cycles using the approved prototype payload without dropping a workpiece, missing the intended placement position, or requiring operator intervention between cycles. Success criterion: all ten complete with no drops and no missed placements, and depth and dwell within tolerance.

*Test setup.* The complete prototype, a ruler, and a stopwatch.

*Procedure.* Command ten consecutive full cycles, recording the cycle time, commanded and measured immersion depth, and measured dwell time for each.

*Results.* Not yet tested.

*Discussion.* The test needs the Y-axis calibration. Status: not yet tested.

*Evidence.* None yet.

=== R-11: Rated Payload

*Requirement.* The system shall complete the full pick-dip-place cycle while carrying a workpiece with a mass of 1 lb. Success criterion: the system lifts, transports, lowers, retains, and releases without stalling, losing position, slipping, or dropping.

*Test setup.* The complete prototype with a test weight.

*Procedure.* A weight was attached and one complete cycle was commanded.

*Results.* A weight of 2.5 lb or more, above the required 1 lb, was held through a full cycle in an informal test.

*Discussion.* The informal test exceeded the rated payload. Status: pass.

*Evidence.* To be added.

#todo[Record the exact weight, the number of trials, and the evidence.]


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
        [*Req.*], [*Requirement*], [*Success criterion*], [*Test method*], [*Measured result*], [*Trials passed*], [*Pass/Fail*], [*Evidence*],
      ),
      [R-01], [No cycle without the part-ready trigger], [Starts only when asserted], [Push button: asserted, released, disconnected], [Trigger input not added yet], [--], [Not tested], [--],
      [R-02], [Pickup position], [Within ±1 cm on both axes], [Ruler], [X: drift under 0.5 cm. Y: judged within 1 cm], [--], [Provisional pass], [@video:viability],
      [R-03], [Workpiece retention], [No visible slip or detachment], [One observed cycle], [No slip or drop], [--], [Pass], [@video:viability],
      [R-04], [Immersion depth], [Within ±1 cm], [Ruler], [Awaiting Y calibration], [--], [Not tested], [--],
      [R-05], [Dwell time], [Within ±1 s], [Stopwatch], [Observed, not documented], [--], [Not tested], [--],
      [R-06], [Full unattended cycle], [All stages in order], [One observed cycle], [All stages, started with the Start button], [--], [Partial], [@video:viability],
      [R-07], [E-stop removes driver power], [Power removed, motion stops], [Multimeter at drivers], [Observed earlier; relay has since failed], [--], [Not tested], [--],
      [R-08], [Restart inhibit], [No motion before restart], [Reset, attempt motion, restart], [Observed, not documented], [--], [Not tested], [--],
      [R-09], [State and fault reporting], [Correct labels transmitted], [Modbus monitor, induced fault], [State shown; faults checked informally], [--], [Partial], [@video:viability],
      [R-10], [Ten consecutive cycles], [All complete, within tolerance], [Ten recorded cycles], [Awaiting Y calibration], [--], [Not tested], [--],
      [R-11], [1 lb payload], [Full cycle without failure], [One cycle with weight], [2.5 lb or more held through a cycle], [--], [Pass], [--],
    ),
    caption: [Verification summary of the system requirements],
  )<table:verification>
]


== Final Design <sec:final-design>

@fig:final-gantry shows the current build of the gantry, and @fig:final-details shows the moving assembly, the end effector, and the electronics.

#figure(
  image(final + "frame-assembled.jpg", height: 11cm),
  caption: [Safe Dip gantry: aluminum frame, two horizontal rails, and the Y-axis assembly with its stepper motor],
)<fig:final-gantry>

#figure(
  grid(
    columns: 3,
    gutter: 8pt,
    image(final + "y-axis-on-rails.jpg", height: 6.5cm),
    image(final + "magnet-holder.jpg", height: 6.5cm),
    image(final + "estop-electronics.jpg", height: 6.5cm),
  ),
  caption: [Left: Y-axis assembly on the X-axis rails. Center: magnet holder with the electromagnet and the screw used as secondary retention. Right: emergency-stop button with the enclosure holding the relay modules, stepper drivers, 24 V supply, and Nucleo board],
)<fig:final-details>

#todo[Replace these with clear photos of the finished product, with each part labeled, for the final report (Nov 20).]
