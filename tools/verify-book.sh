#!/usr/bin/env bash
# verify-book.sh -- one reproducible verification pass for The CNA Bible.
#
# Runs the checks the project's methodology requires after a writing batch, in one
# place, with one exit status. It deliberately does NOT render pages to PNG: the
# visual pass needs a human (or a model) to actually look at the pages, so it is
# driven separately by tools/render-pages.sh.
#
# Usage:
#   tools/verify-book.sh            # build, then check
#   tools/verify-book.sh --no-build # check an already-built book
#
# Exit status is 0 only when every check passes.

set -u

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
book_dir="$repo_root/latex/book"
log="$book_dir/main.log"
pdf="$book_dir/main.pdf"

do_build=1
[ "${1:-}" = "--no-build" ] && do_build=0

failures=0
pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; failures=$((failures + 1)); }
info() { printf '  ----  %s\n' "$1"; }

echo "== The CNA Bible: verification pass =="

# ---------------------------------------------------------------- build
if [ "$do_build" = 1 ]; then
    echo "-- building"
    if make -C "$repo_root/latex" book > "$repo_root/latex/build.log" 2>&1; then
        pass "make book succeeded"
    else
        fail "make book FAILED -- see latex/build.log"
        echo
        grep -E "^(!|.*:[0-9]+:)" "$repo_root/latex/build.log" | head -40
        exit 1
    fi
fi

[ -f "$log" ] || { fail "no main.log; nothing to check"; exit 1; }
[ -f "$pdf" ] || { fail "no main.pdf; nothing to check"; exit 1; }

# ---------------------------------------------------------------- references
echo "-- LaTeX integrity"

# Tight patterns only. A plain substring search for "undefined" false-positives on
# ordinary prose containing the word (e.g. "...an address, undefined behavior...").
if grep -qE "LaTeX Warning: Reference .* undefined|undefined reference|Undefined control sequence" "$log"; then
    fail "undefined references or control sequences"
    grep -nE "LaTeX Warning: Reference .* undefined|Undefined control sequence" "$log" | head -20
else
    pass "no undefined references or control sequences"
fi

if grep -qiE "multiply.defined|Label .* multiply defined" "$log"; then
    fail "multiply-defined labels"
    grep -niE "multiply.defined" "$log" | head -20
else
    pass "no multiply-defined labels"
fi

if grep -qE "LaTeX Warning: Citation" "$log"; then
    fail "undefined citations"
else
    pass "no undefined citations"
fi

# ---------------------------------------------------------------- index
echo "-- index"
ilg="$book_dir/main.ilg"
if [ -f "$ilg" ]; then
    entries=$(grep -oE "Accepted [0-9]+" "$ilg" | tail -1 | grep -oE "[0-9]+" || echo "?")
    rejected=$(grep -oE "[0-9]+ rejected" "$ilg" | tail -1 | grep -oE "^[0-9]+" || echo 0)
    info "makeindex accepted ${entries} entries, ${rejected} rejected"
    if [ "${rejected:-0}" != "0" ]; then
        fail "makeindex rejected ${rejected} entries"
    else
        pass "makeindex clean"
    fi
else
    fail "no main.ilg -- index was not generated"
fi

# ---------------------------------------------------------------- labels
echo "-- label/reference hygiene"

chapters="$book_dir/chapters"
front="$book_dir/front"

dupes=$(grep -rho '\\label{[^}]*}' "$chapters" "$front" 2>/dev/null | sort | uniq -d)
if [ -n "$dupes" ]; then
    fail "duplicate \\label definitions in source:"
    echo "$dupes" | sed 's/^/        /'
else
    pass "no duplicate \\label definitions in source"
fi

# Every \ref{ch:...} must have a matching \label{ch:...}.
missing=""
for r in $(grep -rho '\\ref{ch:[^}]*}' "$chapters" "$front" 2>/dev/null | sed 's/\\ref{//;s/}//' | sort -u); do
    grep -rq "\\\\label{$r}" "$chapters" "$front" || missing="$missing $r"
done
if [ -n "$missing" ]; then
    fail "\\ref to nonexistent chapter labels:$missing"
else
    pass "every \\ref{ch:...} resolves to a \\label"
fi

# ---------------------------------------------------------------- stale facts
echo "-- stale-fact sweep"

hard=$(grep -rno 'Chapter~[0-9]\+' "$chapters" "$front" 2>/dev/null | wc -l)
if [ "$hard" -gt 0 ]; then
    info "hard-coded Chapter~N references: $hard (each must be a deliberate historical statement)"
    grep -rn 'Chapter~[0-9]\+' "$chapters" "$front" 2>/dev/null | head -10 | sed 's/^/        /'
else
    pass "no hard-coded Chapter~N references"
fi

for term in NOXNA "both volumes" "this volume" "Volume I" "Volume II"; do
    n=$(grep -rio "$term" "$chapters" "$front" 2>/dev/null | wc -l)
    [ "$n" -gt 0 ] && info "term '$term': $n occurrence(s) -- inspect each, some may be legitimately historical"
done

# ---------------------------------------------------------------- whitespace
echo "-- working tree"
if git -C "$repo_root" diff --check > /dev/null 2>&1; then
    pass "git diff --check clean"
else
    fail "git diff --check reports whitespace errors"
    git -C "$repo_root" diff --check | head -20
fi

# ---------------------------------------------------------------- size
echo "-- output"
pages=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
info "main.pdf is ${pages:-?} pages"
info "chapter LaTeX: $(find "$chapters" -name '*.tex' | xargs cat 2>/dev/null | wc -l) lines across $(find "$chapters" -name '*.tex' | wc -l) files"

echo
if [ "$failures" -eq 0 ]; then
    echo "RESULT: all checks passed."
    echo "NOTE: this does NOT replace the visual pass. Render every touched page range"
    echo "      with tools/render-pages.sh and actually read the images."
    exit 0
else
    echo "RESULT: $failures check(s) failed."
    exit 1
fi
