#import "@preview/timeliney:0.4.0"

#let adriano-color = rgb("#ffc000")
#let josue-color = rgb("#d00000")
#let both-color = blue.lighten(20%)

#let iv(a, b, who) = {
  let lead = who.at(0)
  let color = if lead == "A" { adriano-color } else if lead == "J" { josue-color } else { both-color }
  let label = if lead == "A" {
    text(size: 7pt, weight: "bold")[#who]
  } else {
    text(size: 7pt, fill: white, weight: "bold")[#who]
  }
  (from: a - 1, to: b, content: label, style: (stroke: 10pt + color))
}
  #align(center)[
    *Legend:*
    #box(fill: adriano-color, inset: 3pt)[*A*] Adriano
    #h(1em)
    #box(fill: josue-color, inset: 3pt)[#text(fill: white, weight: "bold")[J]] Josué
    #h(1em)
    #box(fill: both-color, inset: 3pt)[#text(fill: white, weight: "bold")[B]] Both
    #h(1em)
    (the first letter is the person leading the task)
  ]

  
    #timeliney.timeline(
      show-grid: true,
      spacing: 3.5pt,
      {
        import timeliney: *

        headerline(
          group(("Aug", 1)), group(("Sep", 4)), group(("Oct", 5)), group(("Nov", 4)), group(("Dec", 1)),
        )
        headerline(
          group(..range(15).map(week => strong("W" + str(week + 1))))
        )

        taskgroup(title: [*Preparation*], {
          task("Gather materials and components", iv(1, 2, "A"))
          task("Assemble the metal frame and install rails", iv(1, 2, "A"))
        })

        taskgroup(title: [*Sensors*], {
          task("Install limit switches and test homing", iv(11, 12, "J/A"))
          task("Select the part-detection sensor", iv(9, 9, "J/A"))
          task("Part-ready trigger input", iv(13, 13, "A/J"))
        })

        taskgroup(title: [*Horizontal Axis*], {
          task("Install horizontal-axis mechanism", iv(7, 9, "A"))
          task("Program and test horizontal-axis motion", iv(4, 5, "J"), iv(8, 8, "A/J"))
        })

        taskgroup(title: [*Vertical Axis*], {
          task("Install vertical-axis mechanism", iv(9, 9, "A"))
          task("Program and test vertical-axis motion", iv(5, 6, "J"), iv(9, 9, "A/J"), iv(11, 12, "A/J"))
        })

        taskgroup(title: [*End Effector and Safety*], {
          task("Electromagnet driver and 12 V supply", iv(7, 7, "J/A"), iv(9, 9, "J"))
          task("Wire and verify the emergency stop", iv(10, 10, "A/J"), iv(13, 13, "J/A"))
        })

        taskgroup(title: [*Integration and Validation*], {
          task("Run cycles with a part (retention, dwell)", iv(10, 10, "A/J"))
          task("Record the formal viability video", iv(10, 10, "A/J"))
          task("Test the complete system", iv(11, 11, "J/A"))
          task("Ten consecutive cycles and rated load", iv(12, 13, "J/A"))
          task("Debug the complete system", iv(13, 13, "J/A"))
        })

        taskgroup(title: [*Project Closeout*], {
          task("Prepare the presentation", iv(14, 15, "A/J"))
          task("Present the project", iv(15, 15, "B"))
        })

        taskgroup(title: [*Software, Electrical, and Documentation*], {
          task("Firmware, started in early August", iv(1, 8, "J"), iv(10, 12, "J"))
          task("Electrical design (power, wiring, schematic)", iv(4, 7, "J"))
          task("Mechanical design (CAD) and 3D printing", iv(3, 7, "A"), iv(9, 9, "A"), iv(13, 14, "A"))
          task("Project expenses and budget", iv(10, 10, "A"), iv(13, 13, "A"))
          task("Website, weekly records, and report", iv(3, 15, "J/A"))
        })

        milestone(text(size: 7pt)[*Oct 11* Checkpoint 1], at: 7)
        milestone(text(size: 7pt)[*Oct 25* Checkpoint 2], at: 9)
        milestone(text(size: 7pt)[*Nov 13* Report draft], at: 11.7)
        milestone(text(size: 7pt)[*Nov 20* Final report], at: 12.7)
        milestone(text(size: 7pt)[*Dec 4* Presentation], at: 14.7)
      },
    )