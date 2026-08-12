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
# Prints the generated PNG paths in ascending physical-page order for direct inspection.

set -eu -o pipefail

system_dirname=$(command -v dirname) || {
    printf 'ERROR: missing required rendering command: dirname\n' >&2
    exit 1
}
# The artifact lock must key the physical repository, not an invocation alias through a symlink.
repo_root="$(cd "$("$system_dirname" "${BASH_SOURCE[0]}")/.." && pwd -P)"
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
# This release has 709 pages, so every potentially valid operand has at most three digits. Reject
# wider decimal strings before any shell arithmetic; test/[ otherwise overflows on unbounded input
# and can let a huge request reach Poppler.
if [ "${#first}" -gt 3 ] || [ "${#last}" -gt 3 ]; then
    printf 'ERROR: FIRST and LAST exceed the supported three-digit physical-page range\n' >&2
    exit 2
fi
if [ "$first" -gt "$last" ]; then
    printf 'ERROR: FIRST (%s) must not exceed LAST (%s)\n' "$first" "$last" >&2
    exit 2
fi

missing_commands=""
for required_command in pdfinfo pdftoppm mktemp flock mkdir stat sha256sum file pngtopnm awk find \
    sort wc sed rmdir chmod; do
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
total=$(printf '%s\n' "$pdf_info" | awk '/^Pages:/ {print $2}') || {
    printf 'ERROR: could not parse the pdfinfo page-count field\n' >&2
    exit 1
}
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
        # The directory was allocated privately by this process. Remove every unexpected entry,
        # including nested paths or non-PNG objects left by a failed renderer, before rmdir.
        find "$run_dir" -mindepth 1 -delete 2>/dev/null || true
        rmdir "$run_dir" 2>/dev/null || true
    fi
}
trap cleanup_failed_render EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
pdftoppm -png -r 120 -f "$first" -l "$last" "$pdf" "$run_dir/page"
rendered_count=$(find "$run_dir" -maxdepth 1 -type f -name 'page-*.png' | wc -l) || {
    printf 'ERROR: could not count rendered PNG files\n' >&2
    exit 1
}
expected_count=$((last - first + 1))
actual_names=$(find "$run_dir" -maxdepth 1 -type f -name 'page-*.png' -printf '%f\n' \
    | LC_ALL=C sort) || {
    printf 'ERROR: could not inventory rendered PNG names\n' >&2
    exit 1
}
expected_names=""
page=$first
while [ "$page" -le "$last" ]; do
    expected_name=$(printf 'page-%03d.png' "$page")
    if [ -n "$expected_names" ]; then
        expected_names="$expected_names
$expected_name"
    else
        expected_names=$expected_name
    fi
    page=$((page + 1))
done
if [ "$rendered_count" -ne "$expected_count" ] || [ "$actual_names" != "$expected_names" ]; then
    if [ "$rendered_count" -ne "$expected_count" ]; then
        printf 'ERROR: rendered %s PNGs, expected %s\n' "$rendered_count" "$expected_count" >&2
    fi
    if [ "$actual_names" != "$expected_names" ]; then
        printf 'ERROR: rendered PNG names do not exactly cover requested physical pages\n' >&2
    fi
    exit 1
fi
bad_pngs=0
while IFS= read -r png_name; do
    png_path="$run_dir/$png_name"
    png_profile=$(LC_ALL=C file -b "$png_path" 2>/dev/null || true)
    if [ "$png_profile" != "PNG image data, 993 x 1404, 8-bit/color RGB, non-interlaced" ] \
       || ! pngtopnm "$png_path" >/dev/null 2>&1; then
        printf 'ERROR: invalid/incomplete rendered PNG: %s (%s)\n' \
            "$png_name" "${png_profile:-unreadable}" >&2
        bad_pngs=$((bad_pngs + 1))
    fi
done <<EOF
$actual_names
EOF
if [ "$bad_pngs" -ne 0 ]; then
    exit 1
fi
render_complete=1
trap - HUP INT TERM

echo "rendered physical pages $first..$last of $total into $run_dir:"
printf '%s\n' "$actual_names" | sed "s|^|$run_dir/|"
