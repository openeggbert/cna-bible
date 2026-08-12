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
#   tools/render-pages.sh 243 245 /tmp/out     # ...under a chosen parent directory
#
# Prints the paths of the generated PNGs, newest last, so they can be read directly.

set -eu

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pdf="$repo_root/latex/book/main.pdf"
lock_helper="$repo_root/tools/book-lock.sh"
[ -r "$lock_helper" ] || { printf 'ERROR: missing tools/book-lock.sh\n' >&2; exit 1; }
. "$lock_helper"

usage() {
    printf 'Usage: %s FIRST LAST [OUTDIR]\n' "${0##*/}"
}

case "$#:${1:-}" in
    1:--help)
        usage
        exit 0
        ;;
    2:*|3:*) ;;
    *)
        usage >&2
        exit 2
        ;;
esac

first=$1
last=$2
if [ "$#" -eq 3 ]; then
    outdir=$3
    default_outdir=0
else
    outdir="${TMPDIR:-/tmp}/cna-bible-pages-$EUID"
    default_outdir=1
fi

case "$first:$last" in
    :*|*:|*[!0-9:]*|0*:*|*:0*)
        printf 'ERROR: FIRST and LAST must be canonical positive decimal page numbers\n' >&2
        exit 2
        ;;
esac
if [ "$first" -gt "$last" ]; then
    printf 'ERROR: FIRST (%s) must not exceed LAST (%s)\n' "$first" "$last" >&2
    exit 2
fi

missing_commands=""
for required_command in pdfinfo pdftoppm mktemp flock mkdir stat sha256sum; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        missing_commands="$missing_commands $required_command"
    fi
done
if [ -n "$missing_commands" ]; then
    printf 'ERROR: missing required rendering command(s):%s\n' "$missing_commands" >&2
    exit 1
fi

acquire_book_lock shared || exit 1

[ -f "$pdf" ] || { echo "no built PDF at $pdf -- run 'make -C latex book' first" >&2; exit 1; }

pdf_info=$(pdfinfo "$pdf" 2>/dev/null) || {
    printf 'ERROR: pdfinfo could not parse %s\n' "$pdf" >&2
    exit 1
}
total=$(printf '%s\n' "$pdf_info" | awk '/^Pages:/ {print $2}')
case "$total" in
    ''|*[!0-9]*)
        printf 'ERROR: pdfinfo did not report a numeric page count for %s\n' "$pdf" >&2
        exit 1
        ;;
esac
if [ "$last" -gt "$total" ]; then
    echo "requested page $last but the book has only $total pages" >&2
    exit 1
fi

if [ "$default_outdir" -eq 1 ]; then
    if ! mkdir -m 700 "$outdir" 2>/dev/null && [ ! -d "$outdir" ]; then
        printf 'ERROR: could not create private default render directory\n' >&2
        exit 1
    fi
    read -r outdir_owner outdir_mode <<EOF
$(stat -c '%u %a' "$outdir" 2>/dev/null || true)
EOF
    if [ -L "$outdir" ] || [ ! -d "$outdir" ] || [ "$outdir_owner" != "$EUID" ] \
       || [ "$outdir_mode" != "700" ]; then
        printf 'ERROR: unsafe default render directory (owner=%s mode=%s)\n' \
            "${outdir_owner:-missing}" "${outdir_mode:-missing}" >&2
        exit 1
    fi
elif ! mkdir -p "$outdir"; then
    printf 'ERROR: could not create requested render directory: %s\n' "$outdir" >&2
    exit 1
fi
run_dir=$(mktemp -d "$outdir/render-${first}-${last}.XXXXXX") || {
    printf 'ERROR: could not create a private render directory under %s\n' "$outdir" >&2
    exit 1
}
render_complete=0
cleanup_failed_render() {
    if [ "$render_complete" -eq 0 ]; then
        find "$run_dir" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true
        rmdir "$run_dir" 2>/dev/null || true
    fi
}
trap cleanup_failed_render EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
pdftoppm -png -r 120 -f "$first" -l "$last" "$pdf" "$run_dir/page"
rendered_count=$(find "$run_dir" -maxdepth 1 -type f -name 'page-*.png' | wc -l)
expected_count=$((last - first + 1))
if [ "$rendered_count" -ne "$expected_count" ]; then
    printf 'ERROR: rendered %s PNGs, expected %s\n' "$rendered_count" "$expected_count" >&2
    exit 1
fi
render_complete=1
trap - HUP INT TERM

echo "rendered physical pages $first..$last of $total into $run_dir:"
find "$run_dir" -maxdepth 1 -type f -name 'page-*.png' -print | LC_ALL=C sort
