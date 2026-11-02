#import "@preview/timeliney:0.4.0"

#let adriano-color = rgb("#ffc000")
#let josue-color = rgb("#d00000")
#let both-color = blue.lighten(20%)

#align(center)[
  *Legend:*
  #box(fill: adriano-color, inset: 3pt)[*A*] Adriano
  #h(1em)
  #box(fill: josue-color, inset: 3pt)[#text(fill: white, weight: "bold")[J]] Josué
  #h(1em)
  #box(fill: both-color, inset: 3pt)[#text(fill: white, weight: "bold")[B]] Both
]

#figure(
  timeliney.timeline(
    show-grid: true,
    {
      import timeliney: *

      headerline(
        group(("August", 4)), group(("September", 4)), group(("October", 4)), group(("November", 4)),
      )
      headerline(
        group(..range(16).map(week => strong("W" + str(week + 1))))
      )

      taskgroup(title: [*Preparation*], {
        task(
          "Gather materials and components",
          (from: 0, to: 1, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
        task(
          "Assemble the metal frame",
          (from: 1, to: 2, content: text(size: 7pt, weight: "bold")[A]),
          style: (stroke: 10pt + adriano-color),
        )
      })

      taskgroup(title: [*Sensors and Conveyor Integration*], {
        task(
          "Install motion sensors",
          (from: 1, to: 2, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
        task(
          "Program and test sensors",
          (from: 1, to: 3, content: text(size: 7pt, fill: white, weight: "bold")[J/B]),
          style: (stroke: 10pt + josue-color),
        )
        task(
          "Integrate external conveyors",
          (from: 2, to: 4, content: text(size: 7pt, weight: "bold")[A/B]),
          style: (stroke: 10pt + adriano-color),
        )
        task(
          "Program and test conveyor interface",
          (from: 2, to: 4, content: text(size: 7pt, fill: white, weight: "bold")[J/B]),
          style: (stroke: 10pt + josue-color),
        )
      })

      taskgroup(title: [*Horizontal Axis*], {
        task(
          "Install horizontal-axis mechanism",
          (from: 4, to: 7, content: text(size: 7pt, weight: "bold")[A/B]),
          style: (stroke: 10pt + adriano-color),
        )
        task(
          "Program and test horizontal-axis motion",
          (from: 4, to: 7, content: text(size: 7pt, fill: white, weight: "bold")[J/B]),
          style: (stroke: 10pt + josue-color),
        )
      })

      taskgroup(title: [*Vertical Axis*], {
        task(
          "Install vertical-axis mechanism",
          (from: 7, to: 11, content: text(size: 7pt, weight: "bold")[A/B]),
          style: (stroke: 10pt + adriano-color),
        )
        task(
          "Program and test vertical-axis motion",
          (from: 7, to: 11, content: text(size: 7pt, fill: white, weight: "bold")[J/B]),
          style: (stroke: 10pt + josue-color),
        )
      })

      taskgroup(title: [*Integration and Validation*], {
        task(
          "Debug axes and sensors",
          (from: 10, to: 12, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
        task(
          "Test the complete system",
          (from: 11, to: 12, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
        task(
          "Debug the complete system",
          (from: 12, to: 14, content: text(size: 7pt, fill: white, weight: "bold")[J/B]),
          style: (stroke: 10pt + josue-color),
        )
        task(
          "Test rated load under laboratory conditions",
          (from: 12, to: 14, content: text(size: 7pt, weight: "bold")[A/B]),
          style: (stroke: 10pt + adriano-color),
        )
      })

      taskgroup(title: [*Project Closeout*], {
        task(
          "Complete final refinements",
          (from: 14, to: 15, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
        task(
          "Prepare the presentation",
          (from: 14, to: 15, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
        task(
          "Present the project",
          (from: 15, to: 16, content: text(size: 7pt, fill: white, weight: "bold")[B]),
          style: (stroke: 10pt + both-color),
        )
      })
    },
  ),
  caption: [Sixteen-week Safe Dip implementation schedule.],
) <figure:gantt>