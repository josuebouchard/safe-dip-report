= Abstract

Manual hot-dip coating operations expose workers to elevated temperatures, repetitive strain, and the risk of burns from hot, viscous materials. This project presents Safe Dip, a two-axis Cartesian gantry designed to automate the pick, dip, and place cycle while reducing direct operator exposure. The system provides controlled workpiece positioning, immersion depth, dwell time, and transfer between fixed input, dipping, and output stations.

An STM32 microcontroller coordinates the complete sequence through a cooperative, nonblocking control architecture. Horizontal motion is produced by a stepper-driven timing belt and linear rails, while a stepper-driven leadscrew controls the vertical axis. A conventional electromagnet handles ferromagnetic workpieces, an ultrasonic sensor detects their presence, and normally-closed limit switches provide homing and travel references. Serial and Modbus TCP communications report operating states, sensor information, and fault conditions.

Safety is treated as a primary design consideration. A hardwired Category 0 emergency-stop circuit removes power from the motor drivers independently of the microcontroller, while the electromagnet remains on a separate supply to avoid intentionally releasing a suspended workpiece during a motion stop. The laboratory prototype will be evaluated without a heated coating bath and will demonstrate the integration of the mechanical, electrical, sensing, control, communication, and safety subsystems. Supporting calculations evaluate the design's scalability toward the intended 10 kg payload.

= Acknowledgements

We would like to express our sincere gratitude to Professor Mayra Socarras for her supervision, guidance, and constructive feedback throughout the development of Safe Dip. Her questions and recommendations encouraged us to examine the project more critically, clarify its scope, and improve the technical, safety, and documentation aspects of the proposed design.

We also thank Dean Lara Sharp and the members of the project review board for dedicating their time to evaluating our work and providing feedback. Their observations have helped us identify areas requiring greater clarity and have contributed to the continued refinement of the project.

We are grateful to Valencia College and the Department of Electrical and Computer Engineering Technology for providing the instruction, facilities, laboratory resources, and technical foundation that made this project possible. We also appreciate the faculty, staff, classmates, and laboratory personnel who shared their knowledge and assistance during the development of this proposal.

Finally, we would like to acknowledge our families, friends, coworkers, and employers for their patience, encouragement, and understanding while we balanced the academic and professional responsibilities associated with this project. Their continued support has been invaluable throughout this process.