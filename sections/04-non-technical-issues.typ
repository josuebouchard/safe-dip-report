#import "../template.typ": chapter

#chapter(
  [Non-Technical Considerations],
  
  description: [
    This chapter presents the project planning and non-technical considerations associated with Safe Dip. It provides a monetary budget, a fifteen-week implementation timeline, and the distribution of responsibilities between the team members. The chapter then evaluates the environmental, health and safety, ethical, social, and sustainability aspects of the system. Particular attention is given to the hazards created by moving machinery, electrical power, and the handling of an approximately 10 kg suspended load for the fully-featured system, along with the prototype controls used to reduce those risks. Finally, the chapter discusses the project’s potential to reduce worker exposure to hazardous and repetitive dipping operations while emphasizing honest reporting, maintainability, and responsible automation.
  ],
)

#place.flush()
== Project Timeline

The proposed implementation schedule spans sixteen weeks. Mechanical construction and firmware development proceed in parallel so that each subsystem can be tested soon after installation. The schedule intentionally reserves the final weeks for integrated testing, debugging, refinement, and presentation preparation.

#include "04-b-timeline.typ"

== Project Expenses

The monetary budget in this section represents a preliminary estimate for the laboratory prototype. Prices were obtained from currently available commercial listings and may change as component availability, shipping costs, taxes, and final mechanical dimensions are resolved.

#include "04-a-budget.typ"

== Distribution of Tasks

The task assignments shown in @figure:gantt identify a primary owner for each activity, but they do not prevent either team member from assisting with work outside that assignment. Mechanical and software tasks are deliberately paired during integration so that installation, programming, and validation decisions are made jointly. @table:task-distribution gives the preliminary distribution, and @table:current-task-distribution gives the current distribution, after the changes described below.

#figure(
  table(
    columns: (1fr, 2.8fr),
    align: (left + horizon, left + horizon),
    inset: (x: 7pt, y: 7pt),
    stroke: .5pt,
    table.header(
      [*Team member*],
      [*Primary responsibilities*],
    ),
    [Josué Bouchard],
    [Embedded firmware; ultrasonic-sensor and limit-switch interfacing; horizontal- and vertical-axis motion control; supervisory state machine; Modbus TCP integration; system debugging; and software-oriented verification.],
    [Adriano Duque Mena],
    [Mechanical frame assembly; installation of rails, transmissions, motors, sensors, and external conveyor interfaces; mechanical troubleshooting; fabrication support; and preparation of rated-load testing.],
    [Both],
    [Component procurement; electrical and mechanical integration; emergency-stop validation; complete-system testing; final refinement; report preparation; and presentation.],
  ),
  caption: [Preliminary distribution of project responsibilities.],
) <table:task-distribution>

As the build has progressed, responsibilities have shifted in several areas. @table:current-task-distribution shows the distribution as it stands now.

#figure(
  table(
    columns: (1fr, 2.8fr),
    align: (left + horizon, left + horizon),
    inset: (x: 7pt, y: 7pt),
    stroke: .5pt,
    table.header(
      [*Team member*],
      [*Primary responsibilities*],
    ),
    [Josué Bouchard],
    [Embedded firmware; selection and interfacing of the workpiece-detection sensor and interfacing of the limit switches; horizontal- and vertical-axis motion control; supervisory state machine; Modbus TCP integration; electrical design, including the power distribution and wiring; system debugging; software-oriented verification; project documentation; and preparation of most of the report.],
    [Adriano Duque Mena],
    [Mechanical design in CAD, including the vertical assembly; mechanical frame assembly; installation of rails, transmissions, motors, and sensors; fabrication of custom parts; procurement of the mechanical components; mechanical troubleshooting; preparation of rated-load testing; and preparation of the mechanical parts of the report.],
    [Both],
    [Procurement of the remaining components; electrical and mechanical integration; emergency-stop validation; complete-system testing; final refinement; and presentation.],
  ),
  caption: [Current distribution of project responsibilities.],
) <table:current-task-distribution>

The main changes are:

- The external conveyor interfaces were removed from the project scope, so the conveyor activities in @figure:gantt no longer apply.
- An HC-SR04 ultrasonic sensor was chosen for workpiece detection because of its affordability and availability, and it is assumed to be sufficient for the prototype.
- Electrical design and project documentation became part of Josué's responsibilities.
- Mechanical design in CAD and the procurement of the mechanical components became part of Adriano's responsibilities.
- Report preparation, previously shared, is now split: Josué writes most of the report, and Adriano contributes the mechanical parts.

Two factors drove these changes. The first is the dependencies between tasks: the electrical design depends on the firmware, which defines the controller's pin assignments and the driver interfaces, and procurement depends on the mechanical design, which determines which parts are needed. The second is availability and timing: when a task became ready, it was taken by the team member who could start it first, rather than waiting for the originally assigned owner.

== Health and Safety

Safety is the central motivation for Safe Dip. The system is intended to remove the operator from direct interaction with a repetitive dipping task and, in the full application, from proximity to hot and viscous coating material. The prototype will be evaluated under laboratory conditions without process heat, handling a workpiece of approximately 1 lb. However, the system was designed in preparation for handling 10 kg workpieces, which will present meaningful mechanical, electrical, and suspended-load hazards.

The movement emergency stop is implemented as a Category 0 stop of the movement subsystem. Actuating the normally-closed mushroom button removes power from both stepper-motor drivers immediately. The button requires a twist action to reset, and motion must remain inhibited until the button has been reset and the operator deliberately restarts the system. The electromagnet is powered from a separate supply that is not interrupted by the motion emergency stop so that an attached workpiece is not intentionally released when axis power is removed.

#[
  #show figure: set block(breakable: true)
  #set table.cell(breakable: false)
  #figure(
    table(
      columns: (1.25fr, 2.2fr, 2.2fr),
      align: (left + horizon, left + horizon, left + horizon),
      inset: (x: 6pt, y: 6pt),
      stroke: .5pt,
      table.header(
        [*Hazard*],
        [*Prototype control*],
        [*Residual limitation*],
      ),
      [Unexpected axis motion],
      [Normally-closed, twist-reset mushroom emergency stop removes power from both motor drivers. Firmware prevents automatic restart after a stop event.],
      [The emergency stop does not replace safe setup procedures or physical separation from the moving gantry.],
  
      [Pinch and crush points],
      [Motion is limited to controlled laboratory tests, and personnel must remain clear of the rails, leadscrew, belt transmission, and carriage while the system is enabled.],
      [The current prototype does not claim the protection provided by a fully guarded industrial cell.],
  
      [Suspended workpiece],
      [The magnet remains powered during a motion emergency stop. Retention is tested before complete-cycle operation, and no person may stand beneath the workpiece.],
      [A conventional electromagnet does not retain the workpiece after a total loss of magnet power. This is a prototype limitation and must not be described as fail-safe load retention.],
  
      [Electrical fault or short circuit],
      [Fuses are installed in the prototype power branches, and exposed connections are insulated and secured before operation.],
      [Fuse ratings and conductor sizes must be finalized from the actual branch currents and selected hardware.],
  
      [Loss of position reference],
      [Normally-closed limit switches provide homing and boundary references, while the ultrasonic sensor verifies workpiece presence before the cycle begins.],
      [Sensor detection does not make entry into the machine workspace safe while motion is enabled.],
  
      [Thermal or coating exposure],
      [No heated coating material is used during prototype acceptance testing.],
      [The prototype does not validate operation at the intended industrial temperature or with a production coating medium.],
    ),
    caption: [Primary prototype hazards, controls, and residual limitations.],
  ) <table:hazards>
]

The conventional electromagnet creates an important distinction between an emergency stop and a complete power failure. The separate supply preserves holding force when only the motion subsystem is stopped, but a failure of the magnet supply may still release the load. This limitation must remain visible in the operating instructions, test procedure, and final evaluation of the prototype.

== Ethical Aspects

The ethical responsibility of the project team extends beyond demonstrating that the mechanism can complete a pick-dip-place cycle. Because Safe Dip is presented as a safety-oriented system, performance and safety claims must be based on documented tests rather than design intent alone. In particular, the report must clearly distinguish between the intended 10 kg, elevated-temperature product concept and the laboratory prototype, which is tested without heat and with several safeguards that remain incomplete relative to an industrial installation.

The team will report failed tests, unresolved hazards, and prototype limitations honestly; will not describe the conventional electromagnet as retaining the load after complete power loss; and will not claim compliance with an industrial safety standard unless the relevant architecture and validation have actually been completed. Libraries, technical references, component data, figures, and external designs used during development will be credited appropriately. Safety decisions will take priority over cycle speed, appearance, or demonstration convenience.

Safe Dip does not require the collection of personal information. Operational data communicated through the serial or Modbus TCP interface is limited to machine state, sensor values, commands, and fault information. Any future logging system should collect only the information needed for diagnostics and process traceability.

== Environmental Aspects

The laboratory prototype is not intended to use a heated bath or process chemicals. Its direct environmental impact is therefore primarily associated with electricity consumption, packaging waste, metal and plastic fabrication waste, and the eventual disposal of electronic components. Scrap aluminum, steel, wire, and electronic assemblies should be separated whenever practical so they can be reused or sent through an appropriate recycling stream rather than discarded as mixed waste.

The intended industrial application may use wax, resin, or another coating medium at elevated temperature. Because that operating condition is outside the current prototype test envelope, this report does not claim validation of spill control, fume generation, coating disposal, or thermal energy consumption. Those subjects must be evaluated using the selected coating material and production process before the system is deployed outside laboratory conditions.

== Social Aspects

Safe Dip is intended to reduce worker exposure to a repetitive and potentially hazardous manual process. Removing the operator from the immediate dipping area may reduce physical strain and, in the full-temperature application, reduce the risk of burns and contact with hot coating material. A lower-cost gantry system may also make basic automation more accessible to small and medium manufacturers that cannot justify a full industrial robotic cell.

Automation can also create concern about the replacement of manual labor. The system is better understood as transferring the operator away from direct handling and toward setup, supervision, inspection, maintenance, and process control. Its value should therefore be evaluated not only through throughput, but also through changes in worker exposure, training needs, system reliability, and the quality of the resulting work environment.

== Sustainability

The design supports long-term maintenance by using a modular frame and commercially available motors, drivers, sensors, power supplies, and communication hardware. A failed subsystem can therefore be repaired or replaced without discarding the complete machine. The aluminum structure, rails, and mechanical transmission can also remain in service when the controller, sensors, or end effector are upgraded.

The conventional electromagnet is a practical prototype choice, but it consumes power continuously while holding a workpiece. The control system should therefore energize it only when retention is required and should avoid unnecessary idle holding periods. This energy-use tradeoff should be considered when comparing the prototype with a future electro-permanent or mechanical holding solution.

Repeatable control of immersion depth and dwell time may reduce coating inconsistency and material waste in a future process implementation. That benefit is not demonstrated by the present non-heated prototype and should remain a design objective until it can be measured using the selected coating medium.
