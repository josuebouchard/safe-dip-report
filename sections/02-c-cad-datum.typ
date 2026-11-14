#import "@preview/zero:0.6.1": zi

The values in @cad-dimensions describe the operating envelope of the prototype. The usable travels are the ones set in the firmware. Homing sets the origin of each axis a fixed back-off past its limit switch, 40 mm on the horizontal axis and 20 mm on the vertical axis, and a travel is measured from that origin. The distances are taken to the surface of the carriage that is closest to the limit switch: the left side of the horizontal carriage and the top of the vertical carriage.

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
    [$#zi.cm[55]$],
    [Allows movement between the input, dipping, and output stations.],

    [Usable vertical travel],
    [$#zi.cm[20]$],
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