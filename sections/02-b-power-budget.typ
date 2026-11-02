The power budget of the Safe Dip prototype is given in @power-budget, which lists the voltage, current, and power of each load, and @power-sources compares the resulting demand with the rating of each supply. The two stepper motors and their drivers are powered from the 24 V rail, the electromagnet from the 12 V rail, and the emergency-stop, communications, and processing modules from the 5 V and 3.3 V rails derived from them. The figures for the motors and drivers are worst-case values, computed as the supply voltage multiplied by the rated current.

#figure(
  table(
    columns: (
      0.45fr,
      1.8fr,
      0.8fr,
      0.9fr,
      0.9fr,
      0.55fr,
      1fr,
    ),
    align: center + horizon,
    inset: (x: 0.5em, y: 0.5em),
    stroke: 0.5pt,

    table.header(
      [],
      [*Component*],
      [*Voltage\ (V)*],
      [*Current\ (A)*],
      [*Unit Power\ (W)*],
      [*Qty*],
      [*Total Power\ (W)*],
    ),

    // Movement module
    table.cell(
      rowspan: 2,
      align: center + horizon,
      inset: (x: 0.5em, y: 1em),
    )[
      #rotate(-90deg, reflow: true)[*Movement*]
    ],
    [Stepper motor \ (max usage per phase)],
    [24],
    [2.8],
    [67.2],
    [2],
    [134.4],

    [Stepper motor driver],
    [24],
    [0.5],
    [12],
    [2],
    [24],

    // E-stop module
    table.cell(
      align: center + horizon,
      inset: (x: 0.5em, y: 1em),
    )[
      #rotate(-90deg, reflow: true)[*E-Stop*]
    ],
    [E-stop relay],
    [5],
    [≈0.07–0.10],
    [≈0.5],
    [2],
    [≈1],

    // End-effector module
    table.cell(
      rowspan: 2,
      align: center + horizon,
      inset: (x: 0.5em, y: 1em),
    )[
      #rotate(-90deg, reflow: true)[*End Effector*]
    ],
    [Electromagnet],
    [12],
    [1.5],
    [18],
    [1],
    [18],

    [Electromagnet driver],
    [5],
    [≈0.07–0.10],
    [≈0.5],
    [1],
    [≈0.5],

    // Communications module
    table.cell(
      align: center + horizon,
      inset: (x: 0.5em, y: 1em),
    )[
      #rotate(-90deg, reflow: true)[*Communications*]
    ],
    [Ethernet module],
    [3.3],
    [0.132],
    [≈0.436],
    [1],
    [≈0.436],

    // Processing module
    table.cell(
      align: center + horizon,
      inset: (x: 0.5em, y: 1em),
    )[
      #rotate(-90deg, reflow: true)[*Processing*]
    ],
    [STM32 \ (at max rate)],
    [3.3/5],
    [≈0.1],
    [≈0.33],
    [1],
    [≈0.33],

    // Total
    table.cell(
      colspan: 6,
      align: right + horizon,
      inset: (x: 0.5em, y: 1em),
    )[
      *Total operational power*
    ],
    [*178.7 W*],
  ),
  caption: [Power budget for the Safe Dip prototype.]
)<power-budget>

#figure(
  table(
    columns: (
      1fr,
      2fr,
      1fr,
      1.2fr,
      1.2fr,
    ),
    align: (
      center + horizon,
      left + horizon,
      center + horizon,
      center + horizon,
      center + horizon,
    ),
    inset: (x: 0.6em, y: 0.6em),
    stroke: 0.5pt,

    table.header(
      [*Power Rail*],
      [*Power Adapter*],
      [*Voltage\ (V)*],
      [*Maximum Current\ (A)*],
      [*Maximum Power\ (W)*],
    ),

    [24 V],
    [Mean Well LRS-350-24],
    [24],
    [14.6],
    [350.4],

    [12 V],
    [12 V AC-DC power adapter],
    [12],
    [5],
    [60],

    table.cell(
      colspan: 4,
      align: right + horizon,
      inset: (x: 0.6em, y: 0.8em),
    )[
      *Total available power*
    ],
    [*410.4 W*],
  ),
  caption: [Maximum power available from the Safe Dip AC-DC power adapters.]
)<power-sources>

The Safe Dip prototype uses two independent AC-DC power adapters. The 24 V supply provides a maximum of 14.6 A, corresponding to approximately 350.4 W, and powers the movement subsystem. The 12 V adapter provides a maximum of 5 A, corresponding to 60 W, and powers the electromagnet and low-voltage circuitry. Together, the two adapters provide a total rated output capacity of approximately 410.4 W. @power-rails compares the load on each rail with the rating of its adapter.

#figure(
  table(
    columns: (0.8fr, 3fr, 1fr, 1fr, 1fr),
    align: (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
    inset: (x: 0.6em, y: 0.6em),
    stroke: 0.5pt,

    table.header(
      [*Power Rail*],
      [*Loads*],
      [*Load\ (W)*],
      [*Adapter Rating\ (W)*],
      [*Share of Rating*],
    ),

    [24 V],
    [Two stepper motors and two stepper motor drivers],
    [158.4],
    [350.4],
    [45%],

    [12 V],
    [Electromagnet, and, through the 12 V to 5 V buck converter, the e-stop relays, electromagnet driver, Ethernet module, and STM32 (conversion losses neglected)],
    [20.3],
    [60],
    [34%],

    table.cell(
      colspan: 2,
      align: right + horizon,
      inset: (x: 0.6em, y: 0.8em),
    )[
      *Total*
    ],
    [*178.7*],
    [*410.4*],
    [*44%*],
  ),
  caption: [Load on each power rail compared with the rating of its AC-DC power adapter.]
)<power-rails>