#!/bin/sh
# Turns each .mmd diagram in this folder into the .pdf the report uses.
# Needs mermaid-cli (the mmdc command). Run it after editing a diagram:
#   sh images/chapter-3/design-integration-and-flow-charts/build.sh
cd "$(dirname "$0")" || exit 1
for f in *.mmd; do
  mmdc -i "$f" -o "${f%.mmd}.pdf" -c mermaid-config.json -b white --pdfFit -w 2000 || exit 1
done
