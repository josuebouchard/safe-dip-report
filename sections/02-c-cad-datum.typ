#import "@preview/zero:0.6.1": zi

The values in @cad-dimensions describe the operating envelope of the prototype.

#figure(
  table(
    columns: (1.8fr, 1fr, 2.2fr),
    align: (left + horizon, center + horizon, left + horizon),
    inset: (x: 0.6em, y: 0.55em),
    stroke: 0.5pt,

    table.header(
      [*Dimension*],
      [*Value*],
      [*Design Purpose*],
    ),

    [Overall prototype dimensions],
    [$#zi.cm[108] × #zi.cm[60] × #zi.cm[80]$],
    [Defines the approximate laboratory floor space and vertical clearance required by the prototype.],

    [Usable horizontal travel],
    [$approx #zi.cm[100]$],
    [Allows movement between the input, dipping, and output stations.],

    [Usable vertical travel],
    [$approx #zi.cm[30]$],
    [Provides sufficient lifting clearance and programmed immersion depth.],

    [Bath envelope],
    [$#zi.cm[30] × #zi.cm[30] × #zi.cm[30]$],
    [Defines the approximate size of the dipping container accommodated by the prototype.],

    [Clearance above dipping bath],
    [$approx #zi.cm[5]$],
    [Allows the workpiece and end effector to pass above the bath during horizontal transfer.],

    [Maximum workpiece envelope],
    [$#zi.cm[10] × #zi.cm[10]$],
    [Defines the approximate maximum workpiece size supported by the prototype geometry.],
  ),
  caption: [Principal dimensions of the Safe Dip prototype.]
)<cad-dimensions>