# Safe Dip — Senior Design Report

Source of the Senior Design report for **Safe Dip**, the EET 4950 capstone
project at Valencia College by Josué Bouchard and Adriano Duque Mena. The report
is written in [Typst](https://typst.app); this repository also holds the
electrical schematic and the team's shared spreadsheets.

The report's content (requirements, design, budgets, timeline and results) is
also published on the project website, <https://safe-dip.vercel.app>.

## Building

Install Typst 0.15.1 and run, from the repository root:

```sh
typst compile main.typ                                  # the report, main.pdf
typst compile gantt-modified.typ gantt-modified.svg     # the Gantt chart alone
```

The schematic needs KiCad 10:

```sh
kicad-cli sch export pdf --output kicad_schematic.pdf kicad_schematic/kicad_schematic.kicad_sch
kicad-cli sch export svg --output . kicad_schematic/kicad_schematic.kicad_sch
```

Build output is not committed (see `.gitignore`).

## Automatic builds

Two GitHub Actions workflows build the generated files, so there is no need to
build them by hand. Each file appears as its own download at the bottom of the
run's page in the **Actions** tab, and is kept for 7 days.

| Workflow | Runs when | Produces |
|---|---|---|
| Build report assets | Anything except the schematic changes | `safe-dip-senior-design-report.pdf`, `gantt-modified.svg` |
| Build schematic | `kicad_schematic/` changes | `kicad_schematic.pdf`, `kicad_schematic.svg` |

Both also run on pull requests, and from the **Run workflow** button. The report
build fails if a photo in `images/` or the PDF contains location or device
metadata.

## Working on the report

- Strip the metadata of every photo before adding it to `images/`. Phone photos
  carry the GPS location, device and time they were taken.
- `kicad_schematic/kicad_schematic.kicad_sch` is the schematic's source. After
  changing it, take `kicad_schematic.svg` from the Build schematic run and copy
  it to `images/hardware/schematic.svg`, which is the image the report uses.
- The website keeps its own copies of the report PDF, the Gantt chart, the
  schematic and the Task Plan. Update them there whenever they change here.

## Copyright

© 2026 Josué Bouchard and Adriano Duque Mena. All rights reserved. Product
photos of third-party components belong to their respective owners.
