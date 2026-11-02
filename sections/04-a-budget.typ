#[
  #show figure: set block(breakable: true)
  #let price(x) = grid(
    columns: (1fr, auto),
    align: (left, right),
    [\$], text(x, number-width: "tabular")
  )

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
      [TR8x2 Lead Screw (300 mm)],
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

      [Buzzer],
      [Gikfun Passive Electronic Buzzer],
      [2],
      price[1.80],

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

      [Nut Block],
      [Lysee Lead-Screw Nut Block],
      [2],
      price[20.19],

      table.hline(stroke: 1pt),

      table.cell(colspan: 3, align: right)[
        *Total (before tax)*
      ],
      [*#price[547.89]*],
    ),

    caption: [Project component budget],
  ) <table:project-budget>
]