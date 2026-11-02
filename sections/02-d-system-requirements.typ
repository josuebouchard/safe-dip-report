#import "@preview/zero:0.6.1": zi
#import "../requirements.typ": sr

#pagebreak(weak: true)

#[
  #show figure: set block(breakable: true)
  #show table.cell: set block(breakable: false)
  #show table.cell: set par(justify: true)

  #figure(
    table(
      columns: (auto, 1fr, 1fr, 1.3fr),
      align: (center + horizon, left + horizon, left + horizon, left + horizon),
      inset: (x: 1em, y: .75em),

      table.header(
        table.cell(align: center)[*ID*],
        table.cell(align: center)[*Requirement*],
        table.cell(align: center)[*Success criterion*],
        table.cell(align: center)[*Test method*]
      ),

      sr(),
      [The system shall not initiate a pick-dip-place cycle unless its part-ready trigger input is asserted.],
      [A cycle starts with the trigger asserted; no motion starts with it released or disconnected.],
      [Command a cycle with the trigger asserted by a push button. Release it, then disconnect it, and command a cycle each time.],

      sr(),
      [The system shall position the end effector at the programmed pickup position within $plus.minus #zi.cm[1]$ along both axes before acquiring the workpiece.],
      [Measured error within $plus.minus #zi.cm[1]$ along both axes.],
      [Command the system to the programmed pickup position and measure the position of the end effector relative to the target.],

      sr(),
      [The system shall retain the workpiece throughout the complete pick-dip-place cycle without slipping or dropping it.],
      [Workpiece does not visibly slip or detach at any point.],
      [Execute one complete pick-dip-place cycle using the approved prototype payload.],

      sr(),
      [The system shall lower the workpiece to the programmed immersion depth within $plus.minus #zi.cm[1]$.],
      [Measured depth within $plus.minus #zi.cm[1]$ of programmed depth.],
      [Execute one dip sequence and measure the actual immersion depth relative to the programmed value.],

      sr(),
      [The system shall hold the workpiece at the programmed immersion depth for the programmed dwell time within $plus.minus #zi.second[1]$.],
      [Measured dwell within $plus.minus #zi.s[1]$ of programmed value.],
      [Execute one dip sequence and measure the dwell period with a stopwatch or equivalent timing instrument.],

      sr(),
      [The system shall complete one full unattended pick-dip-place cycle, beginning with the part-ready trigger at the input station and ending with workpiece release at the output station and return to the home position.],
      [Every stage completes in order without operator intervention.],
      [Place a workpiece at the input station and command one operating cycle. Confirm that the system detects and acquires the workpiece, transfers it to the dipping position, lowers it to the programmed immersion depth, holds it for the programmed dwell time, raises it, transfers it to the output station, releases it, and returns to the home position.],

      sr(),
      [The system shall remove power from both stepper-motor drivers when the emergency stop is actuated.],
      [Driver power removed and all axis motion stops.],
      [Actuate the emergency stop while an axis is moving and measure the power supplied to both stepper-motor drivers.],

      sr(),
      [The system shall remain inhibited following an emergency-stop event until the emergency-stop button has been reset and the operator performs a deliberate restart action.],
      [No motion occurs until the deliberate restart action is performed.],
      [Actuate the emergency stop during operation, reset the emergency-stop button, and attempt to command motion without performing the restart action. Perform the deliberate restart action and confirm that normal operation can be re-established.],

      sr(),
      [The system shall transmit its current operating state and any active faults through the selected communications interface during operation.],
      [Each state transition and the active fault are transmitted with correct labels.],
      [Monitor the communications interface during one complete operating cycle and introduce at least one detectable fault condition.],

      sr(),
      [The system shall complete ten consecutive unattended full pick-dip-place cycles using the approved prototype payload without dropping a workpiece, missing the intended placement position, or requiring operator intervention between cycles.],
      [All ten complete; no drops, no missed placements; depth and dwell within tolerance.],
      [Command the system to perform ten consecutive full pick-dip-place cycles using the approved prototype payload. Record the cycle time, commanded immersion depth, measured immersion depth, and measured dwell time for each cycle.],

      sr(),
      [The system shall complete the full pick-dip-place cycle while carrying a workpiece with a mass of 1 lb.],
      [Lifts, transports, lowers, retains, and releases without stalling, losing position, slipping, or dropping.],
      [Attach a 1 lb workpiece and command one complete pick-dip-place cycle.]
    ),
    caption: [System requirements and verification criteria]
  )
]