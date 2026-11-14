#import "@preview/zero:0.5.0": zi, ztable
#import "../template.typ": chapter, todo

#chapter(
  description: [In this chapter, we introduce Safe Dip, a safety-oriented hot-dip pick-and-place system designed to remove operators from the hazardous environment of manual wax coating operations. We establish the motivation for automating this process, identify the risks associated with manual dipping, and review existing commercial solutions. We conclude by identifying the gap in the market that Safe Dip is designed to fill.]
)[Introduction]

// Provide a general background of the problem that you are proposing to solve. Establish the need and motivation for a solution to this problem. Go over different approaches that have been employed to solve similar types of problems. Discuss different projects or products similar to your idea. This section should be comprehensive and should be divided into several sections or sub-sections.

== Background and Problem Statement

Hot-melt dip coating, also referred to as hot dipping or hot-melt wax coating, involves submerging a part into a heated liquid medium such as molten wax, resin, or a similar coating compound. Upon removal, the liquid solidifies as it cools, forming a protective layer around the part that can be cleanly stripped away when needed. This process is commonly applied before long-term storage or bulk packaging to shield parts from corrosion, prevent contact damage that could dull sharp edges, and, in some cases, enhance a tool's grip or handling comfort @dipseal-hot-melt-wax @dominessy-endmill-coating.

Safe Dip seeks to address this gap by providing an affordable, safety-conscious, and instrumented automation solution tailored to this class of hot-dip operations. It targets the small-to-medium production scale where off-the-shelf industrial robots are cost-prohibitive and general-purpose systems lack the domain-specific safety integration required by industrial electrical standards.


== Need and Motivation

In facilities where this process is still performed manually, workers face sustained exposure to elevated temperatures, repetitive motion injuries, and the risk of burns or chemical contact. As soon as the weight of the objects surpasses a couple of kilograms, long-handled tongs or clippers are introduced, adding to the physical strain. Finally, most coating products are not only hot but also viscous, meaning that even the smallest splash can cause serious injuries. Together, these hazards make manual dipping one of the more accident-prone tasks on the shop floor.

Automating the dipping cycle would remove the operator from the hazard zone entirely, yet many smaller manufacturers have not adopted automated solutions due to cost barriers, system complexity, and the lack of scalable, application-specific equipment suited to their production scale.

In addition to improving operator safety, an effective automation solution should remain useful when the coating process changes. Many commercially available systems are designed around a particular chemical, workpiece geometry, or production workflow, making them difficult or expensive to repurpose. Safe Dip instead treats the dipping liquid as an external process variable: the system performs the same controlled pick, immersion, dwell, and placement sequence regardless of the specific coating, cleaning, or treatment medium being used. This chemical flexibility allows laboratories, prototype facilities, and small manufacturers to adapt to new formulations, suppliers, or applications without redesigning the automation equipment.

By combining this flexibility with a comparatively simple Cartesian architecture, Safe Dip seeks to address the gap between manual dipping and highly specialized industrial machinery. The objective is not to reproduce the throughput or complexity of a complete robotic coating cell, but to provide a lower-cost platform that improves safety, process repeatability, and adaptability at a scale accessible to smaller operations.

== Similar Products and Comparison

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: 6,
      align: center + horizon,
      inset: (x: .5em, y: 1em),
      table.header(
        [*Product*], [*Price*], [*Conveyor Feed*], [*Variable Dip Depth*], [*Pick & Place*], [*Chemical Flexibility*]
      ),
      [Safe Dip (Ours)], [\~\$500-\$600], [YES], [YES], [YES], [YES],
      [Dip-Spin (EFFCO DS-250)], [est.\ \$15k–\$25k], [NO], [NO], [NO], [YES],
      [MS800 Tiltable\ Dip-Spin], [est.\ \$40k–\$80k], [NO], [NO], [NO], [YES],
      [Monorail Headstand Screw Machine], [\$2,999–\$3,999], [YES], [NO], [NO], [Partial],
      [Thread Locker Machine (TH-2004L3)], [On Request], [YES], [NO], [NO], [Partial],
      [Full Auto Thread Coater], [\$20k–\$30k], [YES], [NO], [NO], [NO],
      [Emmeti WAX-ON], [est. \$50k–\$150k+], [YES], [YES], [YES], [Partial],
      [South Shore Robotic Dip Cell], [Custom Quote], [NO], [YES], [YES], [YES],
    ),
    caption: [Comparison of commercial dip coating systems against Safe Dip]
  )
]

Chemical flexibility is the ability of a system to operate with different coating, cleaning, and treatment liquids without requiring changes to its mechanical architecture or control logic. The system interacts with the process only through part detection, controlled handling, programmable immersion, and placement; therefore, the chemical composition of the liquid is treated as an external process variable rather than a machine-specific design input. Compatibility is limited primarily by the temperature tolerance and chemical resistance of the end effector and other exposed hardware, rather than by the operating principle of the system itself.

This separation between the machine and the dipping chemistry is important because it allows the same platform to be repurposed as process requirements, suppliers, or formulations change. Instead of designing dedicated equipment for each liquid or application, users can adapt the process by changing the dip medium and operating parameters while retaining the same automation hardware. This reduces dependence on a single chemical process, lowers the risk of future redesign, and makes Safe Dip more suitable for laboratories, prototyping environments, and small-scale manufacturing where process requirements may change frequently.


=== Aramfix EFFCO DS-250 Dip-Spin Machine 

The EFFCO DS-250 is a batch-type industrial dip-spin coating machine designed for high-volume processing of small metal components such as fasteners, nuts, bolts, and stampings. The machine operates by loading parts into a perforated basket, submerging the entire basket into a coating tank, and then spinning the basket at high RPM to centrifugally remove excess coating and achieve a uniform film thickness. This process enables extremely consistent results across thousands of parts per cycle, making it well-suited for mass production environments. The DS-250 features a heated coating tank and programmable dip and spin cycles, allowing operators to fine-tune coating thickness to specification. However, its batch-based design means individual part handling and positional control are not possible, as all parts in the basket are processed simultaneously without differentiation. The machine requires manual loading and unloading of the basket, meaning human intervention is necessary at each production cycle. Its industrial footprint and price range of \$15,000 to \$25,000 place it well beyond the reach of small-scale or research-oriented operations. Unlike Safe Dip, the DS-250 cannot adapt to varying part geometries within a single run or interact with a conveyor-based workflow.

=== MS800 Tiltable Dip-Spin Machine

The MS800 is a fully automatic, tiltable dip-spin coating machine designed for heavy-duty industrial production of fasteners and small precision components. Its distinguishing feature is a motorized tilting mechanism that repositions the basket during the drain cycle, improving coating drainage and reducing waste compared to standard vertical-axis spin machines. The system is PLC-controlled, offering precise regulation of dip duration, spin speed, tilt angle, and temperature, resulting in coating uniformity that is difficult to match with manual or semi-automatic methods. With a throughput capacity in the thousands of parts per hour, the MS800 is optimized for large-scale manufacturing lines rather than flexible or small-batch applications. The machine's price range of \$40,000 to \$80,000 reflects its industrial-grade construction and automation level. Like other dip-spin systems, it is fundamentally a batch processor and cannot handle individual components, vary dip depth per part, or interface with a pick-and-place conveyor system. Its complexity also demands trained operators and dedicated maintenance protocols. While it represents the high end of coating machine capability, it addresses a fundamentally different operational context than Safe Dip.

=== Monorail Headstand Screw Coating Machine

The monorail headstand screw coating machine is a continuous-flow system designed specifically for the automated surface treatment of headed fasteners such as screws, bolts, and rivets. Parts are loaded onto an overhead rail conveyor by their heads, hanging inverted as they travel through a dip station where their threaded sections are coated in the desired chemical or lubricant. The continuous rail feed allows throughput rates of 10,000 to 20,000 parts per hour, making it one of the most efficient solutions for large-volume screw coating applications. Because parts self-hang from their heads, no gripper or pick-and-place mechanism is required, which simplifies the mechanical design significantly. However, this same feature makes it incompatible with any component that lacks a head or flange to hang from, limiting its applicability to a narrow category of fastener geometry. The coating type per production run is fixed, and changing the chemical requires a full tank flush and reconfiguration. Priced between \$2,999 and \$3,999, it is the most affordable automated option reviewed, but its single-purpose nature and geometric constraints make it unsuitable for the diverse component handling that Safe Dip is designed to support.

=== Thread Locker Coating Machine — TH-2004L3

The TH-2004L3 is a purpose-built automatic dispensing machine designed to apply thread-locking adhesive, such as Loctite or Vibra-Seal equivalents, directly onto the threads of screws and bolts prior to assembly. The machine integrates a bowl feeder for bulk part loading, a precision dispensing head that applies a metered quantity of adhesive to each thread zone, and a conveyor exit for processed parts. Its dispensing mechanism is calibrated to apply only to the thread region, avoiding contamination of the head or shank, which is critical for assembly line compatibility. The system handles fastener sizes from M3 to M36 and operates at high throughput, making it appropriate for automotive, electronics, and aerospace assembly environments. Priced between \$3,300 and \$4,500, it sits at the lower end of the industrial machine spectrum, though it is still an order of magnitude more expensive than Safe Dip. Its fundamental limitation is that it is chemically and geometrically constrained: it applies a single fluid type to a single class of headed fasteners, with no capability to handle other part geometries or coating materials. It also has no pick-and-place functionality and cannot interface with a generalized conveyor workflow.

=== Full Automatic Thread Coater

The full automatic thread coater is a high-capacity, end-to-end automated machine designed for the uninterrupted production-line application of thread-locking compounds or sealants on screws and bolts. It integrates automated part feeding, precision coating application, and a discharge conveyor into a single self-contained unit, eliminating the need for manual intervention during normal operation. The system is optimized for single-fluid, single-geometry workflows and is typically configured for a specific fastener size range at installation. Throughput is very high, and the machine is engineered for continuous multi-shift operation in demanding industrial environments. Priced between \$20,000 and \$30,000, it represents a significant capital investment best justified in high-volume production contexts. Its automation level, while impressive within its domain, comes at the cost of flexibility: changing the coating fluid or accommodating a different part geometry requires machine reconfiguration and downtime. It lacks any conveyor-integrated pick-and-place capability and cannot adjust dip depth or dwell time per individual part. These constraints make it an effective solution for its intended use case but a poor match for the adaptive, multi-geometry coating scenario that Safe Dip is designed to address.

=== Emmeti WAX-ON Machine

The Emmeti WAX-ON is a fully robotic, end-to-end bottle waxing line developed for high-volume industrial winery and spirits production. The system integrates a depalletizer, an infeed conveyor, a robotic dipping arm, a multi-tank wax station with interchangeable color tanks on rails, and a vision-based defect inspection camera, all feeding into an automated case packer. Its robotic arm performs true pick-and-place operations, selecting individual bottles from the conveyor and submerging them into the wax tank with consistent depth and dwell time control. The 3D part identification system allows the machine to adapt to minor variations in bottle positioning without human correction. Coating uniformity is achieved through a combination of precise dip speed, controlled withdrawal rate, and optional rotation of the bottle during extraction. The system is capable of processing hundreds of bottles per hour with minimal operator involvement, making it one of the most capable waxing machines commercially available. However, its price range of \$50,000 to \$150,000 and its large industrial footprint place it entirely outside the scope of small-scale or research applications. It is also purpose-designed for bottles and is not adaptable to other component geometries without significant engineering modification.

=== South Shore Controls Robotic Dip Cell

The South Shore Controls robotic dip cell is a custom-engineered industrial automation solution designed for precision dipping, coating, and chemical treatment of components across a range of industries, including food processing, medical device manufacturing, and industrial finishing. The system is built around a 6-degree-of-freedom industrial robot arm that provides full spatial control over the component throughout the dip cycle, enabling complex dip trajectories, variable dip angles, and multi-stage coating sequences that rigid gantry systems cannot replicate. Custom end-effectors, or grippers, are designed to match the specific geometry of the target component, ensuring reliable handling even for irregular or delicate parts. The system is PLC-controlled and fully programmable, with PID-regulated temperature control on the coating tank and real-time process monitoring. Pricing is entirely quote-based and typically falls in the range of \$50,000 to \$100,000 depending on configuration, making it accessible only to well-capitalized industrial clients. Unlike Safe Dip, it does not incorporate a conveyor-based intake and exit workflow; parts must be presented to the robot by separate handling systems. Its strength lies in precision and flexibility within a controlled cell environment, rather than inline conveyor integration.

=== Other Alternatives

Before arriving at the final design, several alternative approaches were evaluated across three key areas of the system: the overall mechanical architecture, the end effector mechanism, and the fail-safe strategy for power loss events. Each alternative was assessed against the project's core priorities of operator safety, cost, mechanical simplicity, and suitability for the hot-dip environment. The following subsections document the options considered and the reasoning behind the decisions made.

==== Mechanical Architecture

From the very beginning of the project, the idea of a gantry competed against the idea of a robotic arm, as the one in @robotic-arm-example. While it presented enough dexterity for the task at hand, a couple of issues remained, regardless of the degrees of freedom it presented:

#v(1em)
- The bigger the number of degrees of freedom it had, the bigger the electronic and computer complexity the system would carry, as each degree of freedom would require at least an additional actuator.
- Mechanically, the fact that the arm is only anchored at one point at the bottom, offset from the object's position, meant that the motors would have to generate and support the entirety of the weight of the object.
- Given the height of some hot-dipping pots, the arm would either require unusually long sections, which would toll even more the motors to sustain the torque, all this to be able to get deep enough for the pot, and high enough to avoid it while grabbing the object.
#v(1em)

#figure(
  image("robotic-arm-example.png", width: 50%),
  caption: [Universal Robots UR5e Collaborative Robot Arm],
  placement: auto,
)<robotic-arm-example>

In contrast, the mechanics of a cartesian gantry are pretty straightforward: only a motor per axis is required, and the positioning of them makes it such that the structure bears most of the weight in a predictable way.

Finally, a last alternative was considered where the objects being dipped could just move through a conveyor belt and have the liquid poured from the top, but that was not acceptable, since materials like hot wax would harden and break the belt, and a uniform coating would be hard to achieve.

==== Effector Alternatives

Another aspect worth consideration is the end effector (i.e., the mechanism that grabs the objects). While a claw is usually the first option everyone thinks of, it also comes with its own disadvantages:

#v(1em)
- Claws must have a strong enough grip to ensure the object doesn't slip, while being soft enough as to not deform it or break it.
- The grip strength is dependent on the geometry of the object and the positioning of the claw.
- As the weight of the objects to be picked increases, it's been recommended to use a pneumatic claw, which introduces a new design dimension, complications, and considerations.
#v(1em)

While an electro-permanent magnet would have been a more suitable effector, more aligned with the safety-conscious objective of this project, its availability is limited, and its price is cost-prohibitive for a prototype.

==== E-Stop Alternatives

Finally, for a project created out of the need for a safe alternative to manual operation, a lot of thought has been put into how the system should behave in the case an emergency stop was required. International standard IEC 60204-1 specifies three categories of emergency stops @se-faq-fa225420:

#v(1em)
- Category 0: uncontrolled stop by immediate removal of actuator power.
- Category 1: controlled stop, with power retained long enough to stop, followed by power removal.
- Category 2: controlled stop with actuator power remaining available.
#v(1em)

Category 1 requires more complexity than category 0, since it requires hardware to disconnect power after a specific time. While stepper motors could benefit from a soft deceleration, given the speed they reach, the complexity outweighed the benefits for this project. Furthermore, the microcontroller cannot be used to trigger a power-off sequence; it is always assumed that it can fail too.

Category 2 simply didn't fit the requirements of this project.

== System Requirements and Success Criteria

Each requirement below describes a specific, observable behavior with a defined pass condition. The system is treated as a black box for these requirements, and emphasis is placed on interactions with system boundaries, the required level of performance, and physical requirements.

#include "02-d-system-requirements.typ"


== Operating Limitations

The following constraints define the boundaries within which Safe Dip is designed to operate, which are outside the control of the system. They are not subject to pass/fail testing, but scope the design and inform component selection.

#v(1em)
- Safe Dip operates along two axes only: a horizontal axis for transfer between the input station, dipping bath, and output station, and a vertical axis for picking, dipping, and placing the workpiece. The system does not support rotation or movement perpendicular to the horizontal travel path.
- The system is designed to handle cylindrical workpieces within the specified size and payload limits.
- Workpieces must be presented at a known, fixed input position. The system does not perform lateral alignment, orientation correction, or vision-based localization.
- Each workpiece must provide a clean, flat, ferromagnetic attachment surface that remains outside the required coating area. Because the electromagnet remains in contact with this surface throughout the cycle, the attachment area will not be dipped or coated. Workpieces requiring complete surface coverage would require a different end effector or a secondary coating operation. 
#v(1em)

For the laboratory prototype, the following additional operating limitations apply:

#v(1em)
- The laboratory prototype is designed and validated for workpieces with a maximum mass of 1 lb. Operation above this payload is outside the prototype's validated operating range.
- The prototype shall not be operated with a heated dipping bath or exposed to temperatures beyond the rated limits of its selected components. All acceptance testing was performed using an unheated, laboratory-safe medium under room-temperature conditions.
- The prototype does not validate operation near molten wax, heated resin, process fumes, splashing hot material, or other industrial hot-dip conditions.
- Because of budget limitations and component availability, the prototype uses a conventional electromagnet rather than one that holds the workpiece without power. A loss of the effector power supply or of mains power will therefore release the workpiece, although axis motion stops.
#v(1em)

This limitation keeps the prototype safe and practical to demonstrate in the laboratory. Using molten wax or another heated material would introduce burn, splash, spill, and fume hazards that would require additional protective equipment and facilities. Heat could also affect the frame, wiring, sensors, motors, lubrication, and end effector.

Although these issues would need to be addressed in an industrial version, detailed thermal and mechanical design is outside the main scope of the ECET prototype. The project therefore focuses on demonstrating the electrical, control, sensing, communication, and safety systems at room temperature.

== System Block Diagram

// Block diagram + especifications for each module

The Safe Dip system can be divided into 7 modules as shown in @block-diagram:general.

#figure(
  image("../images/block-diagram/00-system.svg"),
  caption: [System-wide block diagram],
  placement: auto
)<block-diagram:general>

#v(.75em)

The power distribution module is composed of the power supply and is in charge of converting wall power into the different types of voltage needed.

The E-stop module will contain all the mechanisms needed to perform a category-0 emergency stop, able to cut the power to the movement module. It is also in charge of alerting the processing module about the E-stop so that it can handle it gracefully.

The processing module is the heart of the system, encapsulating the microcontroller, which receives all inputs and translates them into the corresponding actuator responses. It also includes any and all components to ensure that the incoming data is at an acceptable input voltage for the microcontroller. This module receives its power from the power distribution module, and through the microcontroller's on-board power converter, it feeds #zi.V[3.3] to the other modules.

The sensing module is composed of the limit switches used to home each axis. Because the conveyor is outside the project scope, the system that supplies the workpieces also signals when one is ready, through a part-ready trigger input on the controller. For the demonstration, this input is driven by a push button.

The movement module is composed of all the stepper motors and controllers required for the horizontal movement of the gantry and the movement of the vertical assembly.

The effector module controls the part of the system that grabs the object and is composed of an electromagnet. It is nonetheless designed to be as modular as possible, so that a change of effector type is not hard to implement.

The communications module is an addition to the processing module in case communications are decided to be done via Ethernet TCP-Modbus. It would include a module capable of Ethernet communications.

The functional modules described above are expanded in @block-diagram:hardware to show the electrical implementation of Safe Dip and the interfaces between its major components. The diagram identifies the system's power-distribution paths, control signals, sensor connections, communication interfaces, and actuator drivers. It also distinguishes between the high-power circuitry used by the motion and end-effector subsystems and the low-voltage circuitry used by the processing, sensing, and communications modules. This hardware-level representation provides the basis for selecting components, defining subsystem specifications, preparing the power budget, and verifying that the modules can operate together as an integrated system.

#v(1em)

#figure(
  image("../images/block-diagram/01-hardware-architecture.svg"),
  caption: [Hardware architecture],
)<block-diagram:hardware>

== Engineering Specifications <sec:specs>

#include "02-a-system-specification.typ"
