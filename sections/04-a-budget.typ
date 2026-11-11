#[
  #show figure: set block(breakable: true)
  #let price(x) = grid(
    columns: (1fr, auto),
    align: (left, right),
    [\$], text(x, number-width: "tabular")
  )

  === Proposed Budget

  @table:budget-proposed is the budget submitted with the Senior Design Proposal.

  #figure(
    table(
      columns: (1.15fr, 2.15fr, 0.45fr, 0.7fr),
      align: (
        left + horizon,
        left + horizon,
        center + horizon,
        right + horizon,
      ),
      inset: (x: 0.45em, y: 0.35em),
      stroke: 0.45pt,

      table.header(
        [*Item*],
        [*Component*],
        [*Qty.*],
        [*Price total*],
      ),

      [Single Output Switchable Power],
      [Mean Well LRS-350-48],
      [1],
      price[35.06],

      [Microcontroller],
      [STM32 NUCLEO-F446RE],
      [1],
      price[31.00],

      [4-channel digital buffer/line driver],
      [SN74AHCT125N Quadruple Buffer],
      [1],
      price[0.80],

      [Stepper Motor],
      [23HS22-2804S NEMA 23],
      [2],
      price[26.74],

      [Stepper Controller],
      [DM542TE Stepper Controller],
      [2],
      price[42.00],

      [Ethernet Module],
      [W5500 Ethernet LAN Module],
      [1],
      price[6.50],

      [E-Stop],
      [1NC 1NO Red Mushroom Emergency Stop],
      [1],
      price[9.99],

      [Transformer],
      [ALITOVE Power Supply Adapter Converter Transformer],
      [1],
      price[14.00],

      [Buck Converter],
      [LM2596 DC-DC Buck Converter],
      [1],
      price[1.60],

      [Electromagnet],
      [Electromagnet Solenoid BM-P 80-38],
      [1],
      price[44.98],

      [Proximity Laser Sensor],
      [VL53L0X ToF Sensor],
      [1],
      price[2.98],

      [Shaft Coupler],
      [Shaft Coupler (6.35 x 8 mm)],
      [2],
      price[11.99],

      [Limit Switch],
      [HiLetgo KW12-3 Micro Limit Switch],
      [1],
      price[0.60],

      [Rail Guide],
      [MGN12H 300 mm Linear Rail Guide],
      [2],
      price[35.99],

      [Lead Screw],
      [TR8x8 Lead Screw (300 mm)],
      [1],
      price[11.99],

      [Bearings],
      [Pillow Block Bearing, 5/16 in (8 mm)],
      [4],
      price[8.49],

      [Guide Rails],
      [Linear Rail Slide SBR20-800 mm],
      [2],
      price[44.90],

      [Belt],
      [GT2 Timing Belt],
      [1],
      price[16.88],

      [Aluminum Beams],
      [4040 T-Slot Extruded Aluminum Profile, 1000 mm],
      [4],
      price[79.99],

      [Relay],
      [One-Channel Relay Module],
      [1],
      price[3.70],

      [Buzzer],
      [Gikfun Passive Electronic Buzzer],
      [2],
      price[1.80],

      [MOSFET Transistor],
      [IRLZ44N MOSFET Transistors],
      [4],
      price[4.00],

      [Terminal Block],
      [Glarks Terminal Block Set],
      [2],
      price[0.26],

      [Flyback Diode],
      [BOJACK 1N4007 Rectifier Diode],
      [1],
      price[0.05],

      [Wires],
      [22 AWG Stranded Wire Spool],
      [1],
      price[12.29],

      [Cable Wrap Insulation],
      [Eventronic Heat-Shrink Tubing 2:1],
      [1],
      price[6.99],

      [Fuse Holder],
      [FEBRYTOLD 0-Gauge Inline Fuse Holder],
      [1],
      price[4.25],

      [Resistor Kit],
      [Upvivi Resistor Assortment Kit],
      [1],
      price[6.99],

      [T-Nuts],
      [4040 Series T-Sliding Nuts],
      [15],
      price[9.99],

      [Bolt and Nut Kit],
      [M5 Button-Head Socket Cap Screw and Nut Kit],
      [1],
      price[16.99],

      [Motor Mounting],
      [NEMA 23 Steel Mounting Bracket],
      [4],
      price[11.99],

      [Nut Block],
      [Lysee Lead-Screw Nut Block],
      [2],
      price[20.19],

      [Conveyor Belt],
      [12 V DC Electric Desktop Conveyor Belt],
      [1],
      price[99.51],

      table.hline(stroke: 1pt),

      table.cell(colspan: 3, align: right)[
        *Total without conveyor belt (before tax)*
      ],
      [*#price[525.94]*],

      table.cell(colspan: 3, align: right)[
        *Total with conveyor belt (before tax)*
      ],
      [*#price[625.45]*],
    ),

    caption: [Proposed component budget, from the Senior Design Proposal.],
  ) <table:budget-proposed>

  === Total Expenses to Date

  @table:budget-expenses lists what has been spent on the prototype so far. Parts sold in packs are counted at the price of the whole pack, and parts that were bought but later dropped from the design are included.

  #figure(
    table(
      columns: (1.15fr, 2.15fr, 0.45fr, 0.7fr),
      align: (
        left + horizon,
        left + horizon,
        center + horizon,
        right + horizon,
      ),
      inset: (x: 0.45em, y: 0.35em),
      stroke: 0.45pt,

      table.header(
        [*Item*],
        [*Component*],
        [*Qty. bought*],
        [*Amount spent*],
      ),

      [Power Supply (24 V)],
      [Mean Well LRS-350-24],
      [1],
      price[31.47],

      [Microcontroller],
      [STM32 NUCLEO-F446RE],
      [1],
      price[31.00],

      [Stepper Motor],
      [23HS22-2804S NEMA 23],
      [2],
      price[26.74],

      [Stepper Controller],
      [DM542TE Stepper Controller],
      [2],
      price[42.00],

      [Ethernet Module],
      [W5500 Ethernet LAN Module],
      [2],
      price[12.99],

      [E-Stop],
      [Red Mushroom Emergency Stop],
      [1],
      price[9.99],

      [Power Supply (12 V)],
      [ALITOVE Power Supply],
      [1],
      price[14.00],

      [Buck Converter],
      [LM2596 DC-DC Buck Converter],
      [3],
      price[13.99],

      [Electromagnet],
      [Electromagnet Solenoid BM-P 80-38],
      [1],
      price[44.98],

      [Shaft Coupler],
      [Shaft Coupler (6.35 x 8 mm)],
      [2],
      price[11.99],

      [Limit Switch],
      [HiLetgo KW12-3 Micro Limit Switch],
      [10],
      price[5.99],

      [Rail Guide],
      [MGN12H 300 mm Linear Rail Guide],
      [2],
      price[35.99],

      [Lead Screw],
      [TR8x8 Lead Screw (300 mm)],
      [2],
      price[11.99],

      [Bearings],
      [Pillow Block Bearing, 5/16 in (8 mm)],
      [4],
      price[8.49],

      [Guide Rails],
      [Linear Rail Slide SBR20-800 mm],
      [2],
      price[44.90],

      [Belt],
      [GT2 Timing Belt],
      [1],
      price[16.88],

      [Aluminum Beams],
      [4040 T-Slot Aluminum Profile 1000 mm],
      [4],
      price[79.99],

      [Buzzer],
      [Gikfun Passive Electronic Buzzer],
      [10],
      price[8.98],

      [Flyback Diode],
      [BOJACK 1N4007 Rectifier Diode],
      [125],
      price[5.99],

      [Wires],
      [18 AWG 2-Conductor Wire, 100 ft],
      [1],
      price[12.29],

      [Heat Shrink],
      [Eventronic Heat-Shrink Tubing 2:1],
      [560],
      price[6.99],

      [Fuse Holder],
      [FEBRYTOLD 0-Gauge Inline Fuse Holder],
      [2],
      price[8.49],

      [Resistor Kit],
      [Upvivi Resistor Assortment Kit],
      [1],
      price[6.99],

      [T-Nuts],
      [4040 Series T-Sliding Nuts],
      [15],
      price[9.99],

      [Bolt and Nut Kit],
      [M5 Screw and Nut Kit],
      [1],
      price[16.99],

      [Relay],
      [DC 5V One-Channel Relay Module],
      [10],
      price[11.99],

      [Motor Mounting],
      [NEMA 23 Steel Mounting Bracket],
      [4],
      price[11.99],

      [Wago Connectors],
      [WAGO 221 Connector Assortment],
      [1],
      price[30.00],

      [Nut Block],
      [Lysee Lead-Screw Nut Block],
      [2],
      price[20.19],

      [M3 Screws],
      [M3 40 mm Screw Set],
      [1],
      price[12.00],

      [M5 Screws],
      [M5 30 mm Screw Set],
      [1],
      price[17.00],

      [Screw],
      [5/16 in Screw, 1 ft],
      [1],
      price[6.00],

      [Nuts and Washers],
      [5/16 in Nuts and Washers],
      [1],
      price[5.00],

      [Small L-Brackets],
      [Small L Metal Bracket],
      [2],
      price[3.00],

      [L-Brackets],
      [L Metal Bracket],
      [16],
      price[20.00],

      [PLA Filament],
      [PLA 3D Printer Filament Spool],
      [4],
      price[53.96],

      [Aluminum Beams],
      [4040 T-Slot Aluminum Profile 1000 mm],
      [4],
      price[80.00],

      table.hline(stroke: 1pt),

      table.cell(colspan: 3, align: right)[
        *Total spent (before tax)*
      ],
      [*#price[791.22]*],
    ),

    caption: [Total expenses to date.],
  ) <table:budget-expenses>

  === Cost of the Final Design

  @table:project-budget lists the parts used in the final design, each at the cost of the quantity used.

  #figure(
    table(
      columns: (1.15fr, 2.15fr, 0.45fr, 0.7fr),
      align: (
        left + horizon,
        left + horizon,
        center + horizon,
        right + horizon,
      ),
      inset: (x: 0.45em, y: 0.35em),
      stroke: 0.45pt,

      table.header(
        [*Item*],
        [*Component*],
        [*Qty.*],
        [*Price total*],
      ),

      [Power Supply (24 V)],
      [Mean Well LRS-350-24],
      [1],
      price[31.47],

      [Microcontroller],
      [STM32 NUCLEO-F446RE],
      [1],
      price[31.00],

      [Stepper Motor],
      [23HS22-2804S NEMA 23],
      [2],
      price[26.74],

      [Stepper Controller],
      [DM542TE Stepper Controller],
      [2],
      price[42.00],

      [Ethernet Module],
      [W5500 Ethernet LAN Module],
      [1],
      price[6.50],

      [E-Stop],
      [Red Mushroom Emergency Stop],
      [1],
      price[9.99],

      [Power Supply (12 V)],
      [ALITOVE Power Supply],
      [1],
      price[14.00],

      [Buck Converter],
      [LM2596 DC-DC Buck Converter],
      [1],
      price[4.67],

      [Electromagnet],
      [Electromagnet Solenoid BM-P 80-38],
      [1],
      price[44.98],

      [Shaft Coupler],
      [Shaft Coupler (6.35 x 8 mm)],
      [2],
      price[11.99],

      [Limit Switch],
      [HiLetgo KW12-3 Micro Limit Switch],
      [2],
      price[1.20],

      [Rail Guide],
      [MGN12H 300 mm Linear Rail Guide],
      [2],
      price[35.99],

      [Lead Screw],
      [TR8x8 Lead Screw (300 mm)],
      [1],
      price[11.99],

      [Bearings],
      [Pillow Block Bearing, 5/16 in (8 mm)],
      [4],
      price[8.49],

      [Guide Rails],
      [Linear Rail Slide SBR20-800 mm],
      [2],
      price[44.90],

      [Belt],
      [GT2 Timing Belt],
      [1],
      price[16.88],

      [Aluminum Beams],
      [4040 T-Slot Aluminum Profile 1000 mm],
      [4],
      price[79.99],

      [Flyback Diode],
      [BOJACK 1N4007 Rectifier Diode],
      [1],
      price[0.05],

      [Wires],
      [18 AWG 2-Conductor Wire, 100 ft],
      [1],
      price[12.29],

      [Heat Shrink],
      [Eventronic Heat-Shrink Tubing 2:1],
      [1],
      price[6.99],

      [Fuse Holder],
      [FEBRYTOLD 0-Gauge Inline Fuse Holder],
      [1],
      price[4.25],

      [Resistor Kit],
      [Upvivi Resistor Assortment Kit],
      [1],
      price[6.99],

      [Bolt and Nut Kit],
      [M5 Screw and Nut Kit],
      [1],
      price[16.99],

      [Relay],
      [DC 5V One-Channel Relay Module],
      [3],
      price[3.60],

      [Motor Mounting],
      [NEMA 23 Steel Mounting Bracket],
      [4],
      price[11.99],

      [Wago Connectors],
      [WAGO 221 Connector Assortment],
      [1],
      price[30.00],

      [M3 Screws],
      [M3 40 mm Screw Set],
      [1],
      price[12.00],

      [M5 Screws],
      [M5 30 mm Screw Set],
      [1],
      price[17.00],

      [Screw],
      [5/16 in Screw, 1 ft],
      [1],
      price[6.00],

      [Nuts and Washers],
      [5/16 in Nuts and Washers],
      [1],
      price[5.00],

      [Small L-Brackets],
      [Small L Metal Bracket],
      [2],
      price[3.00],

      [L-Brackets],
      [L Metal Bracket],
      [16],
      price[20.00],

      [PLA Filament],
      [PLA 3D Printer Filament Spool],
      [4],
      price[53.96],

      [Aluminum Beams],
      [4040 T-Slot Aluminum Profile 1000 mm],
      [4],
      price[80.00],

      table.hline(stroke: 1pt),

      table.cell(colspan: 3, align: right)[
        *Total (before tax)*
      ],
      [*#price[712.87]*],
    ),

    caption: [Cost of the final design.],
  ) <table:project-budget>
]
