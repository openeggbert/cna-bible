#!/usr/bin/env bash
# render-pages.sh -- render a physical page range of the built book to PNG for the
# visual verification pass.
#
# A successful LaTeX compile does not prove the book is visually correct: overfull
# boxes, clipped listings, oversized tables, running-header collisions and orphaned
# headings all compile cleanly. `grep -i overfull` on main.log has proven unreliable
# in both directions on this project. The only check that works is looking at the page.
#
# Usage:
#   tools/render-pages.sh 243 245              # render physical pages 243..245
#   tools/render-pages.sh 243 245 /tmp/out     # ...into a chosen directory
#
# Prints the paths of the generated PNGs, newest last, so they can be read directly.

set -eu

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pdf="$repo_root/latex/book/main.pdf"

first="${1:?usage: render-pages.sh FIRST LAST [OUTDIR]}"
last="${2:?usage: render-pages.sh FIRST LAST [OUTDIR]}"
outdir="${3:-${TMPDIR:-/tmp}/cna-bible-pages}"

[ -f "$pdf" ] || { echo "no built PDF at $pdf -- run 'make -C latex book' first" >&2; exit 1; }

total=$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')
if [ "$last" -gt "$total" ]; then
    echo "requested page $last but the book has only $total pages" >&2
    exit 1
fi

mkdir -p "$outdir"
pdftoppm -png -r 120 -f "$first" -l "$last" "$pdf" "$outdir/page"

echo "rendered physical pages $first..$last of $total into $outdir:"
ls -1 "$outdir"/page-*.png | sort
