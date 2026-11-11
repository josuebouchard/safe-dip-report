#import "@preview/zebraw:0.6.0": *


= Programming Code <appendix:code>

= Applicable Engineering Codes and Standards

The codes and standards in @applicable-standards were identified as relevant references for the design and development of Safe Dip. Their inclusion does not represent a claim of certification or complete compliance. Formal compliance would require evaluation of the finished system against the complete requirements of each applicable document.

#v(1em)

#[
  #show figure: set block(breakable: true)
  #show table.cell: set block(breakable: false)
  #show table.cell: set par(justify: true)

  #figure(
    table(
      columns: (
        auto,
        auto,
        1fr,
        1fr,
      ),
      align: (
        left + horizon,
        left + horizon,
        left + horizon,
        left + horizon,
      ),
      inset: (x: 0.55em, y: 0.5em),
      stroke: 0.5pt,

      table.header(
        [*Code\ or Standard*],
        [*Organization*],
        [*Explanation*],
        [*Relevance to Safe Dip*],
      ),

      [IEEE\ Code of Ethics],
      [Institute of\ Electrical\ and\ Electronics\ Engineers],
      [Defines ethical duties related to safety, honesty, competence, and public welfare.],
      [Supports safe design, truthful reporting, and clear disclosure of prototype limitations.],

      [NSPE\ Code of Ethics\ for Engineers],
      [National\ Society of\ Professional\ Engineers],
      [Requires engineers to prioritize public safety and communicate technical information honestly.],
      [Applies to safety decisions, testing, risk disclosure, and performance claims.],

      [ISO\ 13850:2015],
      [International\ Organization\ for\ Standardization],
      [Defines requirements and design principles for machinery emergency-stop functions.],
      [Guides the latching E-stop, immediate motion cutoff, manual reset, and restart inhibition.],

      [ISO\ 14118:2017],
      [International\ Organization\ for\ Standardization],
      [Addresses prevention of unexpected machine start-up.],
      [Requires a deliberate restart action after the E-stop is reset.],

      [NFPA 79],
      [National\ Fire\ Protection\ Association],
      [Covers electrical equipment, wiring, protection, and controls for industrial machinery.],
      [Guides internal wiring, branch protection, grounding, control circuits, and E-stop wiring.],

      [NFPA 70\ National\ Electrical\ Code],
      [National\ Fire\ Protection\ Association],
      [Defines requirements for safe electrical installations and supply connections.],
      [Guides power connections, wiring, fuses, grounding, and electrical fault protection.],

      [IEC\ 60204-1],
      [International\ Electrotechnical\ Commission],
      [Covers the safety of electrical equipment of machines and defines the emergency-stop categories.],
      [Defines the Category 0 stop architecture of the movement subsystem.],
    ),
    caption: [Engineering codes and standards applicable to the Safe Dip project.]
  )<applicable-standards>
]

= Datasheets

#bibliography(
  "../datasheet-citations.yaml",
  title: none,
  style: "ieee",
  full: true
)

= Calculations <appendix:calculations>

== Leadscrew calculations<sec:leadscrew-calculations>

The vertical-axis capacity is determined by combining the leadscrew kinematics with the motor's torque--speed characteristic. For a leadscrew with lead $L$, the required rotational speed is obtained from the desired linear speed using @eq:linear-speed-to-angular-speed. The motor's torque--speed curve then provides the available torque $T(omega)$ at that operating speed. Finally, @eq:max-safe-weight-vertical converts the available torque into the maximum safe payload.

#v(1em)

#figure(
  $ v = n L $,
  caption: [Relationship between leadscrew rotational speed and linear speed.],
)<eq:linear-speed-to-angular-speed>

#v(1em)

#figure(
  $
    F_"axial" = (2 pi T(omega) eta) / L
    \
    m_"max" = F_"axial" / g = (2 pi T(omega) eta) / (L g)
    \
    m_"safe" = m_"max" / S = (2 pi T(omega) eta) / (S L g)
  $,
  caption: [Maximum safe payload mass produced by the vertical leadscrew.],
)<eq:max-safe-weight-vertical>

#v(1em)

In these equations, $L$ is the leadscrew lead, defined as the axial distance traveled by the nut during one complete revolution @moons-thrust-generation. The term $eta$ represents the mechanical efficiency of the leadscrew and accounts for frictional losses, while $S$ is the selected safety factor. For this design, a safety factor of $S = 2$ is applied to account for uncertainties in loading, acceleration, drivetrain losses not captured by the nominal efficiency, and variations between the theoretical and available motor torque.

The torque used in @eq:max-safe-weight-vertical should be obtained from the motor's torque--speed curve at the intended operating speed. The static holding torque should not be used for a moving-axis calculation because the available motor torque decreases as rotational speed increases.

= Team Biographies

#grid(
  columns: (150pt, 1fr),
  column-gutter: 1em,
  row-gutter: 3em,

  image("../images/meet-the-team/josue-picture.JPEG"), [
    Josué Bouchard is originally from Argentina and is completing his Bachelor’s degree in Electrical and Computer Engineering Technology at Valencia College. His interest in engineering began with an Arduino board and grew from a fascination with using software to interact with the physical world. After beginning his studies in Computer Engineering at the Universidad de Buenos Aires, he transferred to Valencia College, where he combined his theoretical background with hands-on experience in electronics, microcontrollers, and embedded systems. Josué also enjoys helping others understand technical concepts through his work as a laboratory aide. After graduation, he hopes to pursue a career in embedded systems and eventually work in aerospace or robotics.
  ],

  image("../images/meet-the-team/adriano-foto.jpg"), [
    Adriano Mena Duque de Estrada was born in Colón, Matanzas, Cuba, and immigrated to the United States with his family in 2016, crossing the border with very little and no knowledge of English. With faith and perseverance, he is now completing his Bachelor’s degree in Electrical and Computer Engineering Technology at Valencia College, having switched from Aerospace Engineering after realizing it wasn’t the right fit — though designing spacecraft remains a personal dream. Outside of coursework, Adriano enjoys strategy video games, spends time with his dog and bearded dragon, and loves building electrical projects, which is what ultimately drew him into this career path.
  ]
)
