#let config(body) = [
  #set page(
    paper: "us-letter",
    margin: (
      left: 1.25in,
      right: 1in,
      top: 1in,
      bottom: 1in
    ),
  )
  #set text(
    size: 12pt,
    // top-edge - bottom-edge = 1em 
    bottom-edge: -0.2em,
    top-edge: 0.8em,
  )
  #set par(
    justify: true,
    first-line-indent: .5in,
    // Equivalent to Microsoft Word's 1.5 spacing
    leading: 0.5em,
    spacing: .5em,
  ) 

  // General headings
  #show heading: it => block(below: 1em, it)

  // Don't justify text in tables
  #show table: set par(justify: false)

  // Chapter headings
  #show heading.where(level: 1): it => {
    pagebreak(weak: true)

    if it.supplement == [Chapter] {
      // Chapter heading
      
      set text(weight: "regular", size: 12pt)

      let number = counter(heading).get().first()
      align(left)[
        #set text(size: 2.5em, weight: "regular")
        *Chapter #number*
      ]

      align(right)[
        #set text(size: 2.5em, weight: "regular", fill: red)
        *#it.body*
      ]
    } else {
      // Regular heading
      align(center)[
        #block(below: 2em)[
          #text(size: 24pt)[#it]
        ]
      ]
    }

    

    // Reset figure counters
    // While it says kind:image, it works for all figures
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
  }


  // Numberings
  // #set list(indent: .25in)
  // #show enum.where(): set enum(indent: .25in)
  #set enum(numbering: "1.a)")
  // #set math.equation(numbering: "(1)")

  // Figures - general
  #show figure: set figure(numbering: (..nums) => (
    numbering("1.1", counter(heading).get().first(), ..nums)
  ))

  // Figures - normal case
  #let FIGURE_SUPPLEMENT = "Fig."
  #show figure.where(kind: image): set figure(supplement: FIGURE_SUPPLEMENT)
  #show figure.where(kind: image): set figure.caption(separator: [: ])

  // Figures - tables
  #let TABLE_SUPPLEMENT = "Table"
  #show figure.where(kind: table): set figure(supplement: TABLE_SUPPLEMENT)
  #show figure.where(kind: table): set figure.caption(separator: [\ ], position: top)

  // Show system requirements
  #show ref: it => {
    if it.element != none and it.element.func() == figure and it.element.kind == "SR" {
      let counter = it.element.counter
      let loc = it.element.location()
      let number = counter.at(loc).first()
      let output = [SR-#(it.element.numbering)(number)]
      link(it.element.location(), output)
    } else {
      link(it.location(), it)
    }
  }

  

  #body
]

#let chapter(description: none, numbering: none, title) = [
  #heading(level: 1, supplement: "Chapter", title)

  #v(1fr)

  #if (description != none) [
    #set par(first-line-indent: 0in)

    #rect(width: 100%, inset: 1em)[
      #align(center)[
        #text(size: 1.2em)[*Summary*]
      ]

      #v(0.2em)

      #par(justify: true, description)
    ]
  ]

  #v(1fr)

  #context [

    #let next_chapter = query(heading.where(level: 1).after(here())).first()

    #outline(
      title: none,
      indent: 0in,
      target: selector(heading.where(depth: 2)).after(here()).before(next_chapter.location()),
    )
  ]

  #v(30pt)

  #pagebreak()

]

#let TODO_ENABLE = true

#let todo(bridge: false, body) = if (TODO_ENABLE) {
  block(
    fill: rgb("fff5f5"),
    stroke: 1.5pt + rgb("e03131"),
    inset: 12pt,
    radius: 4pt,
    width: 100%,
    breakable: false,
    [
      #set par(first-line-indent: 0in)
      
      #text(fill: rgb("c92a2a"), weight: "bold")[
        ⚠️ HEMINGWAY BRIDGE:
      ]
      #v(2pt) 
      #text(fill: rgb("212529"))[#body]
    ]
  )
}