#import "@preview/zero:0.5.0": zi, ztable
#import "../template.typ": chapter, todo

#chapter(
  description: [This chapter describes the theory and the design of Safe Dip in detail. We explain the system's two-axis Cartesian gantry architecture and define its operating limitations. We present the testable system requirements and their verification criteria, describe each functional module through a system block diagram, provide engineering specifications for each subsystem, and outline the project budget.]
)[Background Research]

// Describe exactly what you will do to obtain a solution. Suitable content for this section should include, but is not limited to:
// 1. Explain your project in detail. Clearly mention if your project has operating limitations.
// 2. Clearly explain the system requirements of your project.
// 3. Establish a matrix or a table to show how testing of your project will be performed and what the criteria for success will be, i.e., different conditions under which you will test your project to establish the success for each of the project requirements.
// 4. Include a detailed block diagram of your proposed design. Explain each block clearly.
// 5. Include engineering specifications for each block. An example is shown in the table below.
// 6. Discuss different hardware and software components that you are considering to satisfy your engineering specifications.
// 7. Show a table with group members’ responsibilities towards the implementation of the project.
// 8. Establish a power budget for your project.
// 9. Include Preliminary Work completed for your project (very important)

// == Overview of Safe Dip

// Safe Dip is a two-axis Cartesian gantry system designed to automate the pick, dip, and place cycle of a hot-melt coating operation. The horizontal axis is driven by a timing belt coupled to a stepper motor along a pair of linear rails, providing smooth and repeatable travel between the input conveyor, the dipping pot, and the output conveyor. The vertical axis is driven by a leadscrew, which is mechanically self-locking, based on its pitch and the workpiece's weight, meaning that the carriage holds its position without active braking in the event of a power loss or fault. The lead nut is mounted directly to the horizontal slider, so the entire vertical assembly raises and lowers as a unit, keeping the gantry clear of the dipping pot during horizontal travel. Together, these two axes execute a coordinated motion sequence that lifts parts from an input position, lowers them into the heated coating bath for a controlled dwell period, withdraws them, and deposits them at an output position, removing the operator from direct contact with the hazardous thermal environment.

// The prototype operates at a reduced payload and process temperature relative to the full industrial specification in order to meet laboratory safety requirements. The control architecture, communications stack, and safety system topology are nonetheless implemented at full fidelity, and design calculations provided in this report demonstrate how the system scales to the industrial target.

// Equation numbers as (2.1), (2.2), ... (chapter number, then a counter).
// Put these two lines at the top of this section's file.
#set math.equation(numbering: (..n) => numbering("(1.1)", counter(heading).get().first(), ..n))
#counter(math.equation).update(0)

== Concepts, Algorithms, and Equations

This section presents the theory behind the design: how the axes convert motor rotation into motion, how the firmware generates and shapes the step pulses, and how the electrical loads were sized.

=== Axis Motion and Resolution

Both axes run open loop, so the firmware commands each position as a number of STEP pulses, and every distance in millimeters must be converted to pulses. Each pulse moves the motor by one microstep. With $N_"full"$ full steps per motor revolution and the driver DIP switches set to $M$ microsteps per full step, the number of pulses per revolution is

$ N_"rev" = N_"full" M $ <eq:pulses-per-rev>

The 23HS22-2804S motor has a step angle of 1.8°, so $N_"full" = 200$, and both DM542TE drivers are set to $M = 8$, which gives $N_"rev" = 1600$ pulses per revolution.

One motor revolution moves an axis by a distance $L$ that depends on its transmission. On the horizontal axis, a pulley with $Z$ teeth advances a belt of pitch $p_"belt"$ by

$ L_x = Z p_"belt" $ <eq:belt-travel>

The GT2 belt has a pitch of 2 mm and the pulley has 20 teeth, so $L_x = 40$ mm. On the vertical axis, a leadscrew with $n_"starts"$ thread starts of pitch $p_"screw"$ advances the nut by its lead,

$ L_y = n_"starts" p_"screw" $ <eq:screw-lead>

The Tr8x2 leadscrew has a pitch of 2 mm and a single start, so $L_y = 2$ mm. The scale factor of an axis, in steps per millimeter, is then

$ K = N_"rev" / L $ <eq:steps-per-mm>

A position $x$ in millimeters, measured from the origin set by homing, corresponds to the step count

$ N = "round"(K x) $ <eq:mm-to-steps>

and a step count $N$ corresponds to the position

$ x = N / K = (N L) / N_"rev" $ <eq:steps-to-mm>

The firmware rounds to the nearest step. Positions are programmed in whole millimeters and $K$ is an integer on both axes, so the conversion is currently exact. One step moves the axis by

$ Delta x = L / N_"rev" = 1 / K $ <eq:resolution>

and at a linear speed $v$ in mm/s the step rate is

$ f_"step" = K v = v / (Delta x) $ <eq:step-rate>

The same factor converts an acceleration in mm/s² to steps/s². @table:axis-scale lists the resulting values for each axis. For example, a 100 mm move takes 4000 pulses on the horizontal axis and 80,000 pulses on the vertical axis.

#figure(
  table(
    columns: (auto, auto, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon, center + horizon),
    inset: (x: 0.6em, y: 0.55em),
    stroke: 0.5pt,

    table.header(
      [*Quantity*],
      [*Symbol*],
      [*Horizontal axis (X)*],
      [*Vertical axis (Y)*],
    ),

    [Full steps per revolution], [$N_"full"$], [200], [200],
    [Microsteps per full step], [$M$], [8], [8],
    [Pulses per revolution], [$N_"rev"$], [1600], [1600],
    [Travel per revolution], [$L$], [40 mm], [2 mm],
    [Scale factor], [$K$], [40 steps/mm], [800 steps/mm],
    [Distance per step], [$Delta x$], [0.025 mm], [0.00125 mm],
  ),
  caption: [Conversion between stepper driver pulses and axis travel],
)<table:axis-scale>

#v(.5em)

=== Leadscrew Payload <sec:payload>

The load that the vertical axis can lift follows from the kinematics of the leadscrew and the torque--speed curve of the motor. For a leadscrew with lead $L$, defined as the axial distance traveled by the nut during one revolution @moons-thrust-generation, the rotational speed $n$ that gives a linear speed $v$ is

$ v = n L $ <eq:linear-speed>

The vertical axis cruises at $v = 20$ mm/s, and with $L = L_y = 2$ mm this is $n = 10$ rev/s, or 600 rpm. At this speed the motor delivers the torque $T(omega)$ read from its torque--speed curve, where $omega = 2 pi n$ is the angular speed. The leadscrew converts this torque into an axial force, which carries a mass $m_"max"$ against gravity, and a safety factor $S$ gives the maximum safe payload:

$ F_"axial" = (2 pi T(omega) eta) / L $ <eq:axial-force>

$ m_"max" = F_"axial" / g = (2 pi T(omega) eta) / (L g) $ <eq:max-mass>

$ m_"safe" = m_"max" / S = (2 pi T(omega) eta) / (S L g) $ <eq:payload>

Here $eta$ is the mechanical efficiency of the leadscrew, which accounts for frictional losses, and $g$ is the gravitational acceleration. A safety factor of $S = 2$ is applied to account for uncertainties in the loading, the acceleration, drivetrain losses that the nominal efficiency does not capture, and differences between the theoretical and the available motor torque.

The torque must be read from the torque--speed curve at the operating speed. The static holding torque must not be used for a moving axis, because the available torque of a stepper motor decreases as its speed increases. The 150 rpm point quoted for the motor in the movement module is well below the 600 rpm of the vertical axis.

=== Step Pulse Generation

Each axis uses a hardware timer channel in output-compare toggle mode, so the pin changes level every half period. With a timer clock $f_"timer"$, the compare register is advanced by

$ N_"half" = f_"timer" / (2 f_"step") $ <eq:half-period>

timer ticks on every event.

=== Motion Profile

The motion planner accelerates at a constant rate $a$, cruises at the maximum speed, and brakes down to a low landing speed $v_"land"$ so that the axis stops exactly on the target step. Braking starts when the remaining distance equals

$ d_"brake" = (v^2 - v_"land"^2) / (2 a) $ <eq:braking>

For a move of $D$ steps too short to reach the maximum speed, the peak speed is

$ v_"peak" = sqrt(a D) $ <eq:peak-speed>

=== Electrical Loads

The power drawn by each load is $P = V I$, and the total is compared with the rated power of each supply. The magnet current follows from its measured resistance $R$,

$ I = V / R $ <eq:magnet-current>


== Hardware Components and Mechanical Design (CAD)

The components selected for Safe Dip were chosen to satisfy the engineering specifications defined in @sec:specs while remaining within the project's budget constraint and accessible through standard commercial channels. The hardware is divided into two categories: the electronics responsible for control, motion, sensing, and communications, and the structural components that form the physical frame of the gantry.

=== Mechanical structure

The structural frame and motion transmission of Safe Dip are built from standard commercial extrusion and linear-motion components, selected so the dimensions listed in @cad-dimensions can be met without custom machining.

The frame is assembled from 4040 T-slot aluminum extrusion, which forms the horizontal beam, the vertical column, and the supporting legs shown in @cad-model. The T-slot profile allows components to be mounted at arbitrary positions along each beam and secured with T-nuts and M5 hardware, which simplifies alignment during assembly and permits adjustment of the input, dipping, and output station positions.

The horizontal axis is guided by an MGN12H linear rail and carriage and driven by a GT2 timing belt, converting the rotation of the horizontal NEMA 23 into the linear travel between stations described in @cad-dimensions. The vertical axis uses a Tr8x2 leadscrew (2 mm lead) supported by pillow-block bearings and coupled to the vertical NEMA 23 through a flexible shaft coupler; the leadscrew converts motor rotation into the controlled lifting and immersion motion, and its selection is supported by the leadscrew speed and payload calculations in @sec:payload. A brass nut on the leadscrew carries the magnet holder, so that the holder rises and lowers as the screw turns.

#import "@preview/subpar:0.2.2"

#v(-1em)
#figure(
  image("../images/CAD-model.png", width: 90%),
  caption: [CAD model of the Safe Dip mechanical arrangement -\ Perspective view]
)<cad-model>
#figure(
  image("../images/CAD-model-front.png", width: 90%),
  caption: [CAD model of the Safe Dip mechanical arrangement -\ Front view]
)

#v(1em)

The CAD model in @cad-model shows the mechanical arrangement of the Safe Dip prototype. The model shows the relative placement of the horizontal axis, vertical assembly, input station, dipping station, output station, and end effector. The dimensions were checked against the selected mechanical components and the required axis travel and clearances.

#include "02-c-cad-datum.typ"

=== E-Stop and Protection module

The emergency-stop and protection hardware satisfies the requirements in @table:module:e-stop. Its purpose is to remove power from the motor drivers independently of the STM32 while treating the electromagnet as a load-holding device. This arrangement stops the hazardous motion without causing the suspended workpiece to fall into the coating bath.

A normally closed, mechanically latching mushroom emergency-stop button controls relay K1, which switches the 24 V supply of the stepper drivers. When the button is actuated, its contact opens and K1 releases, immediately removing power from the DM542TE drivers, causing the axes to coast to a standstill and implementing a Category 0 stop. Because the stop path is hardwired and normally closed, pressing the button, breaking its wire, or losing the relay's 5 V supply all remove driver power without requiring any action from the microcontroller. A second relay, K2, driven by the same contact, signals the emergency stop to the microcontroller, so that the firmware also stops the step pulses. The button remains latched until it is manually reset, satisfying the “requires manual reset” requirement in @table:module:e-stop.

This stop path is intentionally independent of firmware and programmable logic, as IEC 60204-1 requires for a Category 0 emergency stop @iec-60204-1. A welded K1 contact is the remaining single point of failure; a production version would use a safety relay with monitored, forcibly guided contacts.

A separate effector driver switches the electromagnet coil supply and is not included in the Category 0 cutoff. The electromagnet is treated as a load-holding device rather than as a hazardous actuator that must be immediately de-energized. Removing power from it during an emergency stop could create a secondary hazard by releasing the suspended ferromagnetic part into the coating bath. IEC 60204-1 requires the emergency-stop function to avoid creating such additional hazards @iec-60204-1. The electromagnet therefore remains energized during the stop, and the part is released in a controlled manner only after motion has ceased.

An inline fuse holder provides overcurrent protection for the switched supply rail, and the resistor kit provides the resistors used in the circuit.


#figure(
  image("../images/hardware/e-stop.png", width: 25%),
  caption: [E-stop mushroom button]
)

=== Sensing Module

The sensing hardware provides the axis-homing feedback required by the pick-dip-place sequence and satisfies the requirements in @table:module:sensing. Because the stepper motors run open loop, the controller knows each axis position only by counting the steps it has commanded, and that count is lost whenever the controller restarts or the drivers lose power during an emergency stop. Each axis therefore has a limit switch at the home end of its travel, which gives it a fixed physical reference: the axis is driven slowly toward its switch, and the point where the switch trips becomes position zero.

The HiLetgo KW12-3 micro limit switch shown in @figure:limit-switch was selected for this purpose. It is a compact snap-action switch, 20 × 10.5 × 6.5 mm, with a roller lever that lets the moving carriage actuate it without a precise contact point. Its single-pole double-throw contacts provide common, normally-open, and normally-closed terminals, so the normally-closed contact can be used: a broken wire then reads the same as a tripped switch and stops the axis instead of letting it drive past home. The contacts are rated for 5 A at 125 VAC, far above the low-voltage, low-current logic signal they switch in Safe Dip. The switches are sold in packs of ten, which leaves spares beyond the two that the axes require.

#figure(
  image("../images/hardware/limit_switches.jpg", width: 65%),
  caption: [HiLetgo KW12-3 micro limit switch with roller lever]
)<figure:limit-switch>

=== Power Distribution Module

This system requires three main voltage lines, one at #zi.V[24] for the stepper motor controllers, another at #zi.V[12] for the effector, and finally one of #zi.V[5] for the processing module. To that end, two different power supplies provide the #zi.V[24] and #zi.V[12] lines, while a DC-DC buck converter generates the #zi.V[5] line.

The Mean Well LRS-350-24 is an AC-DC power supply that converts 110 or 220 Vrms into #zi.V[24]. It has four parallel terminals for the output, and it can supply a maximum current of #zi.A[14.6].

#figure(
  image("../images/hardware/meanwell.webp", width: 40%),
  caption: [Mean Well LRS-350-24 AC-DC power supply]
)

The less stringent requirements of the #zi.V[12] line means that it can be provided by an off-brand transformer, as long as it complies with the specifications. In this case, an ALITOVE DC 12V 5A Power Supply was chosen.

#figure(
  image("/images/hardware/12v-transformer.jpg", width: 50%),
  caption: [ALITOVE DC 12V 5A Power Supply]
)

Finally, for the #zi.V[5] line, as shown in @block-diagram:hardware, a HiLetgo buck converter based on the XL4016 chip was chosen.

#figure(
  image("../images/hardware/buck-converter.png", width: 30%),
  caption: [HiLetgo buck converter]
)

=== Processing Module

The STM32 NUCLEO-F446RE serves as the microcontroller responsible for coordinating the efforts for the sense-pick-dip-place sequence. It features an ARM Cortex-M4, 32-bit, #zi.V[3.3] microcontroller operating at a maximum frequency of 180 MHz. The STM32 family is widely adopted in embedded industrial designs due to its peripheral density, which allows for tight deterministic loops.

This board provides the necessary computing bandwidth to manage the real-time state machine while simultaneously running communication tasks. Crucially, its advanced hardware timers can be utilized in Output Compare mode to generate precise, jitter-free frequency pulses for step generation without taxing the CPU. Furthermore, its configurable interrupts can be used to immediately respond to external signals or to timer completion. The ability to delegate tasks to specialized hardware enables the Nucleo board to perform communication tasks with other peripherals.

#figure(
  image("/images/hardware/nucleo-board.png", width: 50%),
  caption: [STM32 Nucleo-F446RE microcontroller board]
)

The STEP and DIR signals of the Nucleo board are connected directly to the optocoupler inputs of the stepper controllers, so no level-shifting buffer is used. The pins are configured as open-drain outputs that sink the optocoupler current, as described in @sec:step-pulse.

=== Movement Module

For both the horizontal and vertical movement, a NEMA 23 stepper motor drives each axis. For this project, StepperOnline's 23HS22-2804S NEMA 23 stepper motor was chosen due to its static torque of 1.24 Nm and dynamic torque of almost 0.9 Nm at 150 RPM.

#figure(
  image("../images/hardware/nema23.png", width: 30%),
  caption: [NEMA 23 23HS22-2804S stepper motor]
)

To drive the NEMAs using a microcontroller, a stepper motor controller is required to set their speed and direction. The DM542TE accepts a supply of up to 50 V, and in this project it is powered at 24 V and accepting 5 V signals.


#figure(
  image("../images/hardware/stepper-controller.png", width: 45%),
  caption: [DM542TE stepper controller]
)

=== End Effector Module

The end-effector hardware holds the ferromagnetic workpiece throughout the pick-dip-place cycle and switches it under microcontroller control, satisfying the requirements in @table:end-effector.

A Baomain BM-P 80-38 electromagnet is used as the gripping element. It holds the ferromagnetic workpiece by magnetic attraction rather than a mechanical grip, which avoids moving jaws near the coating bath and lets the part be released simply by removing coil current. Its holding force is sized to retain the rated payload for the full duration of the dip, as required in @table:end-effector, and it is driven from a single microcontroller output.

A 5 V single-channel relay module, built around the Songle SRD-05VDC-SL-C relay @songle-srd-05vdc-sl-c, switches the electromagnet supply. The module has an active-low input that it pulls up to its own 5 V supply through an opto-coupler LED and resistor, so the microcontroller drives it from a single open-drain output on a 5 V-tolerant pin, sinking about 4 mA, as measured on the bench. The 12 V supply is wired through the relay's normally-closed contact, so the electromagnet is energized whenever the relay coil is off and is released only while the microcontroller actively pulls the input low. The module was chosen because it isolates the microcontroller from the 12 V electromagnet circuit, because the electromagnet stays engaged if the microcontroller resets or loses power or the input wire breaks, and because its contact ratings exceed the 12 V electromagnet supply and coil current, matching the effector-driver requirements in @table:end-effector.

A 1N4007 flyback diode is placed across the electromagnet coil to protect the relay contacts and the rest of the circuit from the inductive back-EMF generated when the coil is de-energized, addressing the "no damaging voltage transient" condition in the @table:end-effector verification.

#figure(
  image("../images/hardware/electromagnet.png", width: 30%),
  caption: [Baomain BM-P 80-38 electromagnet]
)
=== Communications Module

Safe Dip communicates with the user over Modbus TCP, which reports the state of the machine and its faults and lets the operator change the parameters of the cycle. The NUCLEO-F446RE's UART peripheral, along with the ST-LINK connector on the board, is used for debug messages.

For Modbus TCP, a W5500 was chosen. The W5500 is a standalone Ethernet module with a full TCP/IP stack implemented in the hardware/firmware on the chip itself. This means that the microcontroller doesn't have to run a TCP/IP stack, but instead it only has to communicate with the module via SPI.

#figure(
  image("../images/hardware/w5500.png", width: 40%),
  caption: [W5500 Ethernet module]
)

== Software and Programming Languages

The firmware and the electrical and mechanical design of the project were made with a small set of programming languages and software tools. They were chosen so that timing and memory use stay predictable on a small microcontroller, so that, wherever possible, the tools come from the component manufacturer or are free, and so that both team members can work on the same files.

The Modbus TCP library is written in C99. C is ubiquitous in embedded systems because it is simple and close to assembly code, which makes its behavior predictable and its memory use efficient. The library has no dependency on the STM32, so the same code can be built and tested on a computer, and it uses no dynamic memory. The application firmware is written in C++20 and built with the compiler set to the C++23 standard. C++ makes abstraction easier: classes and a common interface let the sequencer run any operation without knowing how it works, and features such as `constexpr` and static assertions make it easier to express constraints in the code, so that mistakes are found when the program is compiled and not while the machine is running. Strongly typed enumerations and variants also make invalid states difficult to write. The code is compiled without exceptions, run-time type information, or dynamic memory, so the language adds no unpredictable timing or memory use.

The microcontroller is configured with STM32CubeMX and the STM32Cube HAL, and the firmware is built with the STM32CubeCLT toolchain (ST Arm Clang, CMake, and Ninja), which gives the team one reproducible command-line build. clangd and clang-format keep the editor feedback and the code style consistent, the on-board ST-LINK of the Nucleo board programs and debugs the microcontroller and provides serial output, and Git and GitHub keep the history of the firmware.

Testing uses a Modbus TCP client, `madbus-cli`, to read and write coils and registers through the whole path from the computer to the STM32, an oscilloscope to check the step pulses, which come from a hardware timer and can only be confirmed by measuring the signal, and a multimeter to check the supply voltages and signal levels.

The electrical schematic is drawn in KiCad, which is free and open source and checks the wiring rules before anything is built. The mechanical parts are modeled in Onshape, which runs in a web browser so that both team members can work on the same model, and the 3D-printed parts are prepared in Bambu Studio, which previews the supports and the print time before a part is printed.

Together, these tools keep the code generated by the vendor separate from the hand-written code, rely on hardware timers and static memory for what is critical for timing, and can be shared through a file, a repository, or an online editor, so that both team members can reproduce each other's work.

== Power Budget

#include "02-b-power-budget.typ"

// == Preliminary work

// === Modbus TCP Communications Prototype

// Preliminary work has been completed on the communications subsystem through the development of a portable Modbus server library in C. The library separates the Modbus protocol from the target hardware by receiving raw protocol data units and accessing application data through user-provided callback functions. This allows the same protocol implementation to be tested on a desktop computer and later integrated into the STM32 firmware without introducing hardware-specific dependencies into the library. The implementation avoids dynamic memory allocation and organizes the supported Modbus function codes into separate modules. :contentReference[oaicite:0]{index=0}

// The library currently includes dispatch support for coils, discrete inputs, input registers, and holding registers. Incoming requests are validated before application data is accessed, and protocol exception responses are generated for unsupported functions, invalid addresses, invalid values, and internal failures. The public interface exposes a central PDU dispatcher, while a context structure containing read and write callbacks connects Modbus addresses to the Safe Dip application state. :contentReference[oaicite:1]{index=1} :contentReference[oaicite:2]{index=2} :contentReference[oaicite:3]{index=3}

// A Modbus TCP layer has also been implemented to process the Modbus Application Protocol header and forward the enclosed PDU to the protocol dispatcher. This layer uses a small state machine that first receives and parses the seven-byte MBAP header and then requests the remaining PDU bytes. This structure supports nonblocking communication because the STM32 does not need to wait for an entire request in one operation. :contentReference[oaicite:4]{index=4} :contentReference[oaicite:5]{index=5}

// The TCP implementation was integrated with the STM32 and W5500 Ethernet library through SPI. In this arrangement, the W5500 hardware manages the Ethernet and TCP socket operations, while the STM32 periodically checks the socket state, receives available request bytes, dispatches completed Modbus messages, and transmits the resulting responses without blocking the main control loop.

// Initial hardware testing was performed using `madbus-cli` as a Modbus TCP client. The test successfully read coil values, wrote individual coils, wrote several coils in one request, and read the values back from the STM32. The results shown in @figure:modbus-test confirm preliminary operation of the read-coils, write-single-coil, and write-multiple-coils functions through the complete computer-to-W5500-to-STM32 communication path.

// #figure(
//   image(
//     "/images/madbus-test.png",
//     width: 70%,
//   ),
//   caption: [Preliminary Modbus TCP coil read and write testing using `madbus-cli`],
//   placement: auto,
// )<figure:modbus-test>

// This preliminary implementation reduces the remaining communications work to defining the final Modbus address map and connecting its callbacks to the Safe Dip operating state, gantry position, sensor information, configuration values, and fault data.

// === Stepper-Motor Signal Prototype

// Preliminary work was also performed on the generation of the stepper-motor STEP signal using the STM32 hardware timers. TIM2 was configured in Output Compare toggle mode so that the timer peripheral, rather than the main application loop, controls the output transitions. After each compare event, the interrupt callback schedules the next transition by advancing the compare register by a configurable number of timer ticks. Changing this interval changes the STEP frequency without requiring software delays or a blocking pulse-generation loop.

// This experiment establishes the basic mechanism that will later be incorporated into the movement module. The module will extend the prototype with pulse counting, acceleration and deceleration, target-position tracking, and independent control of both axes. Testing performed at this stage was limited to timer configuration and STEP waveform generation; operation with the selected stepper drivers and motors remains part of the final implementation and verification.

// #import "@preview/codly:1.3.0": *
// #show: codly-init.with()
// #import "@preview/codly-languages:0.1.9": *
// #codly(languages: codly-languages)

// #figure(
//   ```c
//   // Dynamically controls the half period
//   static volatile uint32_t half_period_ticks = 500U;
  
//   // Stepper start function
//   void stepper_start(void) {
//     // Get counter
//     uint32_t now = __HAL_TIM_GET_COUNTER(&htim2);
  
//     // Set Capture/Compare Register as `now + half_period_ticks`
//     __HAL_TIM_SET_COMPARE(&htim2, TIM_CHANNEL_1, now + half_period_ticks);
  
//     // Start timer + interrupt
//     HAL_TIM_OC_Start_IT(&htim2, TIM_CHANNEL_1);
//   }
  
//   // Timer compare interrupt
//   void HAL_TIM_OC_DelayElapsedCallback(TIM_HandleTypeDef *htim) {
//     // Check it comes from correct timer and channel
//     if ((htim->Instance == TIM2) && (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1)) {
  
//       // Get Capture/Compare Register
//       uint32_t previous_compare = __HAL_TIM_GET_COMPARE(htim, TIM_CHANNEL_1);
  
//       // Set updated Capture/Compare Register
//       __HAL_TIM_SET_COMPARE(htim, TIM_CHANNEL_1,
//                             previous_compare + half_period_ticks);
//     }
//   }
//   ```,
//   caption: [Snippet for STEP square wave generator],
//   kind: image,
// )