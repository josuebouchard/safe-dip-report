#let coverpage(
  courseCode: none,
  courseName: none,
  projectName: none,
  subtitle: none,
  professor: none,
  date: datetime.today(),
) = [
  #set text(size: 14pt)

  #v(25pt)

  #align(center)[
    #set text(size: 14pt)
    
    #image("images/valencia-logo.svg", width: 70%)
    #v(20pt)
    Department of Electrical & Computer Engineering Technology (ECET)\
    School of Engineering, Technology, and Advanced Manufacturing (ETAM)
  ]

  #v(25pt)

  #align(center)[
    #stack(
      dir: ttb,
      spacing: .5em,
      text(size: 20pt, courseCode),
      text(size: 16pt, courseName)

    )
  ]

  #v(2fr)

  #align(center)[
    #stack(
      dir: ttb,
      spacing: .5em,
      text(size: 24pt)[*#projectName*],
      text(size: 16pt, subtitle),
    )
  ]

  #v(1.5fr)

  #align(center)[
    #stack(
      dir: ttb,
      spacing: .5em,
      [Submitted by],
      text(size: 16pt)[*Josué Alejandro Bouchard\ Adriano Duque Mena*],
    )
  ]

  #v(1.5em)

  #align(center)[
    #stack(
      dir: ttb,
      spacing: .5em,
      [Supervised by],
      text(size: 16pt)[*#professor*],
    )
  ]

  #v(2fr)

  #align(center)[
    #datetime.display(date, "[month repr:long] [day], [year]")
  ]

  #v(25pt)

  #metadata(true) <marker:cover-intro-end>

  #pagebreak()
]
