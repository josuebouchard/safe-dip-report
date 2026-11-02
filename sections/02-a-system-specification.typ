#import "@preview/zero:0.6.1": zi

=== Power Distribution

#[
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: .5em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [AC-DC\ power supply\ (motors)],
      [
        - Input: 110 VAC, 60 Hz
        - Output: 24 VDC
        - Must supply sufficient current for two stepper motors at peak load
      ],
      [Verified by measuring output voltage under full load with a multimeter.],

      [AC-DC\ power supply\ (#zi.V[12])],
      [
        - Input: 110 VAC, 60 Hz
        - Output: 12 VDC
        - Ripple and noise within acceptable limits for logic, sensors, and effector
      ],
      [Verified by measuring output voltage and ripple with an oscilloscope under full load.],

      [DC-DC\ Buck Converter\ (#zi.V[12] #sym.arrow #zi.V[5])],
      [
        - Input: 12 VDC
        - Output: 5 VDC
        - Ripple and noise within acceptable limits for logic and sensors
      ],
      [Verified by measuring output voltage and ripple with an oscilloscope under full load.],
    ),
    caption: [Power distribution specifications]
  )<table:module:power>
]

=== E-Stop

#[
  // #show figure: set block(breakable: true)
  // #show table.cell: set block(breakable: false)
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: .5em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [Emergency stop\ button],
      [
        - Must offer a Normally Closed channel for cutting the power to the motors
        - Must be able to handle peak power coming from the AC-DC power supply (motors)
        - Requires manual reset before power is restored
      ],
      [Verified by actuating the E-stop during operation and confirming output power is cut.],

    ),
    caption: [E-stop specifications]
  )<table:module:e-stop>
]

=== Processing

#[
  // #show figure: set block(breakable: true)
  // #show table.cell: set block(breakable: false)
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: .5em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [Microcontroller],
      [
        - Operates at 3.3 VDC
        - Sufficient GPIO for stepper control, sensor inputs, and effector output
        - Supports USB UART for baseline serial communications
        - Capable of driving a Pulse Train Output (PTO) at the frequency set by the stepper and stepper controller
      ],
      [Verified using an oscilloscope to check GPIO voltage and PTO frequency.],
    ),
    caption: [Processing specifications]
  )<table:module:processing>
]

=== Sensing

#[
  // #show figure: set block(breakable: true)
  // #show table.cell: set block(breakable: false)
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: .5em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [Limit switches],
      [
        - Normally-closed configuration
        - One per axis end, used for homing
        - Rated for the operating environment
      ],
      [Verified by commanding each axis to its respective home and confirming motion stops upon switch actuation.],
    ),
    caption: [Sensing specifications]
  )<table:module:sensing>
]

=== Movement

#[
  // #show figure: set block(breakable: true)
  // #show table.cell: set block(breakable: false)
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: .5em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [Stepper motors\ (x2)],
      [
        - NEMA 23 frame
        - Holding torque sufficient to lift rated payload on vertical axis and drive belt under load on horizontal axis
        - Positional accuracy: ±1 cm
      ],
      [Verified by commanding each axis to a known target and measuring offset with a ruler.],

      [Stepper motor\ drivers\ (x2)],
      [
        - Compatible with a 24 VDC supply
        - Microstepping support
        - Current output set to motor rating
      ],
      [Verified by confirming smooth motion on both axes across the full travel range.],
    ),
    caption: [Movement specifications]
  )<table:module:movement>
]

=== End Effector

#[
  // #show figure: set block(breakable: true)
  // #show table.cell: set block(breakable: false)
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: 1em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [Electromagnet],
      [
        - Holding force sufficient to retain rated payload throughout the dip cycle
        - Controlled by a single digital output from the microcontroller
      ],
      [Verified by attaching a part at rated payload and confirming no drop occurs throughout one full pick-dip-place cycle.],

      [Effector driver],
      [
        - Active-low control input that the microcontroller can drive from a single open-drain output
        - Isolates the microcontroller from the #zi.volt[12] electromagnet circuit
        - Normally-closed contact that keeps the electromagnet energized whenever the relay coil is off
        - Contact voltage rating greater than the #zi.volt[12] electromagnet supply
        - Contact current rating greater than the maximum electromagnet current
      ],
      [
        Command the electromagnet on and off from the firmware while monitoring the control input and the electromagnet voltage. The test passes if the driver switches the full electromagnet current reliably, the electromagnet stays engaged when the control input is released or the module loses its #zi.volt[5] supply, it remains within an acceptable temperature range, and no damaging voltage transient is observed when the electromagnet is de-energized.
      ],
    ),
    caption: [End effector specifications]
  )<table:end-effector>
]

=== Communications

#[
  // #show figure: set block(breakable: true)
  // #show table.cell: set block(breakable: false)
  #figure(
    table(
      columns: 3,
      align: left + horizon,
      inset: (x: 1em, y: .75em),
      table.header(
        [*Specific Component*], [*Engineering Specifications*], [*Justification & Verification*]
      ),

      [Ethernet module],
      [
        - Operating voltage compatible with the processing module
        - SPI interface compatible with microcontroller
        - Reports system state, axis positions, and fault events
        - Supports Ethernet and TCP socket communication
      ],
      [Verify communication between the STM32 and Ethernet module through SPI. Establish a TCP connection from an external computer and confirm that data can be transmitted and received.],
    ),
    caption: [Communications specifications]
  )
]