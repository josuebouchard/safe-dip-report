#import "@preview/oxifmt:1.0.0": strfmt

#let num-func(n) = strfmt("{:02}", n)

#let sr(sr-label: none) = {
  let fig-counter = counter(figure.where(kind: "R"))

  [
    #figure(
      kind: "R",
      caption: none,
      supplement: "R",
      numbering: n => num-func(n),
      context [
        #let current-val = fig-counter.get().first()
        R-#num-func(current-val)
      ]
    )

    #sr-label
  ]
}