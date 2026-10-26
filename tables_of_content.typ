#metadata(false)<marker:tables-of-content-start>


= Table of Contents

// Introductory things
#{
  show outline.entry.where(level: 1): it => {
    if it.element.supplement == [Chapter] {
      let chapter_number = counter(heading).at(it.element.location()).first()
      let space_above = if chapter_number != 1 { 2em } else { auto }

      block(above: space_above)[
        #link(
          it.element.location(),
          it.indented(none, [*Chapter #chapter_number #it.inner()*]),
        )
      ]
    } else {
      link(
        it.element.location(),
        it.indented(none, [*#it.inner()*]),
      )
    }
  }

  // Abstract and Acknowledgements
  outline(
    title: none,
    target: selector(heading).before(<marker:tables-of-content-start>),
  )

  v(1em)

  // Tables of contents
  outline(
    title: none,
    target: selector(heading).after(<marker:tables-of-content-start>).before(<marker:tables-of-content-end>),
  )

  v(1em)

  // Chapters
  outline(
    title: none,
    target: selector(heading).after(<marker:tables-of-content-end>).before(<marker:references-start>),
  )

  v(1em)

  // Bibliography and appendices
  outline(
    title: none,
    target: selector(heading.where(level: 1)).after(<marker:references-start>),
  )
}

= List of Figures
#outline(
  title: none,
  target: selector(
    figure.where(kind: image).or(figure.where(kind: raw)).or(figure.where(kind: math.equation)),
  ),
)

= List of Tables
#outline(
  title: none,
  target: selector(
    figure.where(kind: table),
  ),
)

#metadata(false)<marker:tables-of-content-end>