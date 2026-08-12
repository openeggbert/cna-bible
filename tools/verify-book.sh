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

# Do not use `set -e`: this verifier intentionally accumulates independent failures. Pipe status
# must still include every producer, otherwise a failed parser can be hidden by a successful awk,
# sort or sed consumer and make an empty diagnostic look authoritative.
set -u -o pipefail

system_dirname=$(command -v dirname) || {
    printf 'ERROR: missing required verification command: dirname\n' >&2
    exit 1
}
# Canonicalize the physical repository root. Otherwise invoking this same script through a
# directory symlink hashes a different lock key while still reading/writing the same PDF inode.
repo_root="$(cd "$("$system_dirname" "${BASH_SOURCE[0]}")/.." && pwd -P)"
book_dir="$repo_root/latex/book"
log="$book_dir/main.log"
pdf="$book_dir/main.pdf"
lock_helper="$repo_root/tools/book-lock.sh"
[ -r "$lock_helper" ] || { printf 'ERROR: missing tools/book-lock.sh\n' >&2; exit 1; }
. "$lock_helper"

usage() {
    printf 'Usage: %s [--no-build]\n' "${0##*/}"
}

do_build=1
case "$#:${1:-}" in
    0:) ;;
    1:--no-build) do_build=0 ;;
    1:--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

# A partial artifact audit can look deceptively green when an optional-looking PDF or text tool
# is absent. Resolve the complete external command set before allocating scratch state or starting
# a build, so the run fails once with an actionable diagnostic and cannot silently reduce coverage.
missing_commands=""
required_commands="git perl pdfinfo pdftotext pdffonts pdfimages pngtopnm cmp \
    mutool gs mktemp flock mkdir stat sha256sum grep sed awk find sort uniq wc head tail comm diff \
    paste xargs cat rm rmdir chmod"
if [ "$do_build" -eq 1 ]; then
    required_commands="make latexmk pdflatex makeindex $required_commands"
fi
for required_command in $required_commands; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        missing_commands="$missing_commands $required_command"
    fi
done
if [ -n "$missing_commands" ]; then
    printf 'ERROR: missing required verification command(s):%s\n' "$missing_commands" >&2
    exit 1
fi

# Keep every scratch output in one private session directory. Besides preventing concurrent runs
# from colliding, this lets one EXIT trap remove text, JSON, PDF and decoded-image intermediates
# after normal completion, a failed check, or an interrupt. Resolve mktemp before its first use so
# a missing bootstrap dependency produces one controlled diagnostic rather than shell fallout.
system_mktemp=$(command -v mktemp) || {
    printf 'ERROR: missing required verification command: mktemp\n' >&2
    exit 1
}
diagnostic_dir=$("$system_mktemp" -d /tmp/cna-bible-verify.XXXXXX) || {
    printf 'ERROR: could not create private verification scratch directory\n' >&2
    exit 1
}
mktemp() {
    if [ "${1:-}" = "-d" ]; then
        shift
        "$system_mktemp" -d "$diagnostic_dir/${1##*/}"
    else
        "$system_mktemp" "$diagnostic_dir/${1##*/}"
    fi
}
cleanup_diagnostics() {
    find "$diagnostic_dir" -mindepth 1 -delete 2>/dev/null || true
    rmdir "$diagnostic_dir" 2>/dev/null || true
}
trap cleanup_diagnostics EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

failures=0
pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; failures=$((failures + 1)); }
info() { printf '  ----  %s\n' "$1"; }
forbid_matches() {
    local result_file=$1
    local finding_message=$2
    local clean_message=$3
    shift 3
    grep "$@" > "$result_file" 2>/dev/null
    local scan_status=$?
    case "$scan_status" in
        0)
            fail "$finding_message"
            head -10 "$result_file" | sed 's/^/        /'
            ;;
        1)
            pass "$clean_message"
            ;;
        *)
            fail "source/log scan failed while checking: $clean_message (grep status $scan_status)"
            ;;
    esac
}
append_inventory_matches() {
    local result_file=$1
    shift
    grep "$@" >> "$result_file" 2>/dev/null
    local scan_status=$?
    [ "$scan_status" -eq 0 ] || [ "$scan_status" -eq 1 ]
}
grep_count() {
    local count scan_status
    count=$(grep "$@" 2>/dev/null)
    scan_status=$?
    case "$scan_status" in
        0|1) printf '%s\n' "${count:-0}" ;;
        *) return "$scan_status" ;;
    esac
}
line_count() {
    local count
    count=$(wc -l < "$1") || return $?
    printf '%s\n' "$count"
}

echo "== The CNA Bible: verification pass =="

if [ "$do_build" -eq 1 ]; then
    acquire_book_lock exclusive || exit 1
else
    acquire_book_lock shared || exit 1
fi

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
forbid_matches "$diagnostic_dir/undefined-log.txt" \
    "undefined references or control sequences" \
    "no undefined references or control sequences" \
    -nE "LaTeX Warning: Reference .* undefined|undefined reference|Undefined control sequence" "$log"
forbid_matches "$diagnostic_dir/multiply-defined-log.txt" \
    "multiply-defined labels" "no multiply-defined labels" \
    -niE "multiply.defined|Label .* multiply defined" "$log"
forbid_matches "$diagnostic_dir/citation-log.txt" \
    "undefined citations" "no undefined citations" -nE "LaTeX Warning: Citation" "$log"
forbid_matches "$diagnostic_dir/headheight-log.txt" \
    "running head exceeds the reserved header height" \
    "running heads fit the reserved header height" \
    -n -A3 "Package fancyhdr Warning: \\headheight is too small" "$log"

if ! overfull=$(grep_count -Fc 'Overfull \hbox' "$log"); then
    fail "could not count overfull-box diagnostics"
    overfull=unknown
fi
info "$overfull internal overfull hbox warning(s); physical PDF bounds are checked below"

# ---------------------------------------------------------------- index
echo "-- index"
ilg="$book_dir/main.ilg"
if [ -f "$ilg" ]; then
    index_log_scan_ok=1
    entries=$(sed -n 's/.*(\([0-9]*\) entries accepted.*/\1/p' "$ilg" | tail -1) \
        || index_log_scan_ok=0
    rejected=$(sed -n 's/.*entries accepted, \([0-9]*\) rejected.*/\1/p' "$ilg" | tail -1) \
        || index_log_scan_ok=0
    warns=$(sed -n 's/.*lines written, \([0-9]*\) warnings.*/\1/p' "$ilg" | tail -1) \
        || index_log_scan_ok=0
    info "makeindex accepted ${entries:-?} entries, ${rejected:-?} rejected, ${warns:-?} warnings"
    if [ "$index_log_scan_ok" -ne 1 ] || [ "${entries:-0}" != "2389" ] \
       || [ "${rejected:-1}" != "0" ] \
       || [ "${warns:-1}" != "0" ]; then
        fail "makeindex inventory changed or reported rejected entries/warnings"
    else
        pass "makeindex accepted the complete 2389-entry inventory cleanly"
    fi
else
    fail "no main.ilg -- index was not generated"
fi

idx="$book_dir/main.idx"
ind="$book_dir/main.ind"
if [ -f "$idx" ] && [ -f "$ind" ]; then
    index_count_scan_ok=1
    if ! idx_entry_count=$(line_count "$idx"); then
        idx_entry_count=0
        index_count_scan_ok=0
    fi
    # Each source record must have a non-empty key, the hyperlink encapsulator, and one printed
    # page in the book's exact arabic range. The key may itself contain TeX braces.
    if ! idx_valid_count=$(grep_count -Ec '^\\indexentry\{.+\|hyperpage\}\{([1-9][0-9]?|[1-5][0-9]{2}|6[0-6][0-9]|670)\}$' "$idx"); then
        idx_valid_count=0
        index_count_scan_ok=0
    fi
    if ! idx_unique_key_count=$(sed -n 's/^\\indexentry{\(.*\)|hyperpage}{[0-9][0-9]*}$/\1/p' "$idx" \
        | LC_ALL=C sort -fu | wc -l); then
        idx_unique_key_count=0
        index_count_scan_ok=0
    fi
    if ! ind_item_count=$(grep_count -c '^  \\item ' "$ind"); then
        ind_item_count=0; index_count_scan_ok=0
    fi
    if ! ind_subitem_count=$(grep_count -c '^    \\subitem ' "$ind"); then
        ind_subitem_count=0; index_count_scan_ok=0
    fi
    if ! ind_subsubitem_count=$(grep_count -c '^      \\subsubitem ' "$ind"); then
        ind_subsubitem_count=0; index_count_scan_ok=0
    fi
    ind_key_count=$((ind_item_count + ind_subitem_count + ind_subsubitem_count))
    if [ "$index_count_scan_ok" -eq 1 ] && [ "$idx_entry_count" -eq 2389 ] \
       && [ "$idx_valid_count" -eq 2389 ] \
       && [ "$idx_unique_key_count" -eq 681 ] && [ "$ind_item_count" -eq 676 ] \
       && [ "$ind_subitem_count" -eq 5 ] && [ "$ind_subsubitem_count" -eq 0 ] \
       && [ "$ind_key_count" -eq "$idx_unique_key_count" ]; then
        pass "all 2389 index records form 681 non-empty in-range keys (676 items + 5 subitems)"
    else
        fail "index structure changed ($idx_entry_count records, $idx_valid_count valid/in-range, $idx_unique_key_count unique; $ind_item_count items + $ind_subitem_count subitems + $ind_subsubitem_count subsubitems)"
    fi
else
    fail "no main.idx/main.ind -- index source or output is missing"
fi

# ---------------------------------------------------------------- labels
echo "-- label/reference hygiene"

chapters="$book_dir/chapters"
front="$book_dir/front"

label_inventory_file=$(mktemp /tmp/cna-bible-label-inventory.XXXXXX.txt)
label_names_file=$(mktemp /tmp/cna-bible-label-names.XXXXXX.txt)
label_scan_ok=1
: > "$label_inventory_file"
if ! append_inventory_matches "$label_inventory_file" \
    -ho '\\label{[^}]*}' "$book_dir/main.tex"; then
    label_scan_ok=0
fi
if ! append_inventory_matches "$label_inventory_file" \
    -rho '\\label{[^}]*}' "$chapters" "$front"; then
    label_scan_ok=0
fi
if ! dupes=$(sort "$label_inventory_file" | uniq -d); then
    dupes=""
    label_scan_ok=0
fi
if [ "$label_scan_ok" -ne 1 ]; then
    fail "source label inventory scan failed"
elif [ -n "$dupes" ]; then
    fail "duplicate \\label definitions in source:"
    echo "$dupes" | sed 's/^/        /'
else
    pass "no duplicate \\label definitions in source"
fi

# Every source \ref must have a matching label, including part, chapter, section and appendix
# aliases. LaTeX also diagnoses this after enough passes; the source check makes the invariant
# explicit and catches it without interpreting log wording.
missing=""
ref_inventory_file=$(mktemp /tmp/cna-bible-ref-inventory.XXXXXX.txt)
raw_ref_inventory_file=$(mktemp /tmp/cna-bible-raw-ref-inventory.XXXXXX.txt)
missing_refs_file=$(mktemp /tmp/cna-bible-missing-refs.XXXXXX.txt)
ref_scan_ok=1
: > "$raw_ref_inventory_file"
if ! append_inventory_matches "$raw_ref_inventory_file" \
    -ho '\\ref{[^}]*}' "$book_dir/main.tex"; then
    ref_scan_ok=0
fi
if ! append_inventory_matches "$raw_ref_inventory_file" \
    -rho '\\ref{[^}]*}' "$chapters" "$front"; then
    ref_scan_ok=0
fi
if ! sed 's/^\\ref{//;s/}$//' "$raw_ref_inventory_file" \
    | sort -u > "$ref_inventory_file"; then
    ref_scan_ok=0
fi
if ! sed 's/^\\label{//;s/}$//' "$label_inventory_file" \
    | sort -u > "$label_names_file"; then
    label_scan_ok=0
fi
if ! comm -23 "$ref_inventory_file" "$label_names_file" > "$missing_refs_file"; then
    ref_scan_ok=0
fi
if ! missing=$(paste -sd, "$missing_refs_file"); then
    missing=""
    ref_scan_ok=0
fi
if [ "$label_scan_ok" -ne 1 ] || [ "$ref_scan_ok" -ne 1 ]; then
    fail "source reference inventory scan failed"
elif [ -n "$missing" ]; then
    fail "\\ref to nonexistent labels: $missing"
else
    pass "every source \\ref resolves to a \\label"
fi
rm -f "$label_inventory_file" "$label_names_file" "$ref_inventory_file" \
    "$raw_ref_inventory_file" "$missing_refs_file"

# A syntactically valid chapter file can be forgotten during a restructure and never reach TeX;
# conversely, a case-mismatched input may work on one filesystem and fail on another. Require
# every front-matter, chapter, appendix, and renderer-fragment source on disk to occur exactly once
# in the input graph. Keep the 89-content-source count explicit as a second structural invariant.
input_targets_file=$(mktemp /tmp/cna-bible-input-targets.XXXXXX.txt)
chapter_sources_file=$(mktemp /tmp/cna-bible-chapter-sources.XXXXXX.txt)
orphan_sources_file=$(mktemp /tmp/cna-bible-orphan-sources.XXXXXX.txt)
duplicate_inputs_file=$(mktemp /tmp/cna-bible-duplicate-inputs.XXXXXX.txt)
missing_inputs_file=$(mktemp /tmp/cna-bible-missing-inputs.XXXXXX.txt)
input_graph_ok=1
{
    grep -ho '\\input{[^}]*}' "$book_dir/main.tex" 2>/dev/null
    grep -rho '\\input{[^}]*}' "$chapters" "$front" 2>/dev/null
} | sed 's/^\\input{//;s/}$//' | grep '^chapters/' | sort > "$input_targets_file" \
    || input_graph_ok=0
grep -ho '\\input{[^}]*}' "$book_dir/main.tex" 2>/dev/null \
    | sed 's/^\\input{//;s/}$//' | grep '^front/' >> "$input_targets_file" \
    || input_graph_ok=0
sort -o "$input_targets_file" "$input_targets_file" || input_graph_ok=0
{
    find "$chapters" -type f -name '*.tex' -printf '%P\n' | sed 's|^|chapters/|'
    find "$front" -type f -name '*.tex' -printf '%P\n' | sed 's|^|front/|'
} | sort > "$chapter_sources_file" || input_graph_ok=0
comm -23 "$chapter_sources_file" "$input_targets_file" > "$orphan_sources_file" \
    || input_graph_ok=0
uniq -d "$input_targets_file" > "$duplicate_inputs_file" || input_graph_ok=0
while IFS= read -r input_target; do
    [ -f "$book_dir/$input_target" ] || printf '%s\n' "$input_target"
done < "$input_targets_file" > "$missing_inputs_file" || input_graph_ok=0
chapter_source_count=$(line_count "$chapter_sources_file") || { chapter_source_count=0; input_graph_ok=0; }
compiled_source_count=$(line_count "$input_targets_file") || { compiled_source_count=0; input_graph_ok=0; }
orphan_source_count=$(line_count "$orphan_sources_file") || { orphan_source_count=0; input_graph_ok=0; }
duplicate_input_count=$(line_count "$duplicate_inputs_file") || { duplicate_input_count=0; input_graph_ok=0; }
missing_input_count=$(line_count "$missing_inputs_file") || { missing_input_count=0; input_graph_ok=0; }
content_source_count=$(find "$chapters" -type f -name '*.tex' | wc -l) \
    || { content_source_count=0; input_graph_ok=0; }
if [ "$input_graph_ok" -eq 1 ] && [ "$content_source_count" -eq 89 ] \
   && [ "$chapter_source_count" -eq 91 ] \
   && [ "$compiled_source_count" -eq 91 ] \
   && [ "$orphan_source_count" -eq 0 ] && [ "$duplicate_input_count" -eq 0 ] \
   && [ "$missing_input_count" -eq 0 ]; then
    pass "all 2 front-matter + 89 content sources are compiled exactly once"
else
    fail "compiled-source closure failed ($content_source_count content, $chapter_source_count total files, $compiled_source_count inputs, $orphan_source_count orphaned, $duplicate_input_count duplicated, $missing_input_count missing)"
    sed 's/^/        orphaned: /' "$orphan_sources_file" | head -10
    sed 's/^/        duplicated: /' "$duplicate_inputs_file" | head -10
    sed 's/^/        missing: /' "$missing_inputs_file" | head -10
fi
rm -f "$input_targets_file" "$chapter_sources_file" "$orphan_sources_file" \
    "$duplicate_inputs_file" "$missing_inputs_file"

# The declared input graph and the files TeX actually opened are independent evidence. Compare
# all project-owned manuscript/image inputs recorded by -recorder in main.fls with a filesystem-
# derived expected set; ignore TeX-distribution and generated auxiliary inputs by construction.
recorder_expected_file=$(mktemp /tmp/cna-bible-recorder-expected.XXXXXX.txt)
recorder_actual_file=$(mktemp /tmp/cna-bible-recorder-actual.XXXXXX.txt)
recorder_diff_file=$(mktemp /tmp/cna-bible-recorder-diff.XXXXXX.txt)
recorder_graph_ok=1
{
    printf '%s\n' main.tex ../common/preamble.tex
    find "$front" "$chapters" -type f -name '*.tex' -printf '%P\n' \
        | while IFS= read -r source; do
            if [ -f "$front/$source" ]; then printf './front/%s\n' "$source"
            else printf './chapters/%s\n' "$source"
            fi
        done
    find "$book_dir/images" -maxdepth 1 -type f -name '*.png' -printf './images/%f\n'
} | sort -u > "$recorder_expected_file" || recorder_graph_ok=0
if [ -f "$book_dir/main.fls" ]; then
    awk '/^INPUT / {print substr($0, 7)}' "$book_dir/main.fls" \
        | grep -E '^(main\.tex|\.\./common/preamble\.tex|\./(front|chapters)/.*\.tex|\./images/.*\.png)$' \
        | sort -u > "$recorder_actual_file" || recorder_graph_ok=0
else
    : > "$recorder_actual_file"
fi
comm -3 "$recorder_expected_file" "$recorder_actual_file" > "$recorder_diff_file" \
    || recorder_graph_ok=0
recorder_expected_count=$(line_count "$recorder_expected_file") \
    || { recorder_expected_count=0; recorder_graph_ok=0; }
recorder_actual_count=$(line_count "$recorder_actual_file") \
    || { recorder_actual_count=0; recorder_graph_ok=0; }
recorder_diff_count=$(line_count "$recorder_diff_file") \
    || { recorder_diff_count=0; recorder_graph_ok=0; }
if [ "$recorder_graph_ok" -eq 1 ] && [ "$recorder_expected_count" -eq 98 ] \
   && [ "$recorder_actual_count" -eq 98 ] \
   && [ "$recorder_diff_count" -eq 0 ]; then
    pass "TeX recorder opened exactly the expected 98 project manuscript/image inputs"
else
    fail "TeX recorder provenance mismatch ($recorder_expected_count expected, $recorder_actual_count actual, $recorder_diff_count differences)"
    head -10 "$recorder_diff_file" | sed 's/^/        /'
fi
rm -f "$recorder_expected_file" "$recorder_actual_file" "$recorder_diff_file"

# Recorder input is a set, so it cannot distinguish one image included twice from five images each
# included once. Close the declared image graph separately: every source PNG must have exactly one
# case-correct includegraphics target and no target may name a missing/non-PNG asset.
image_targets_file=$(mktemp /tmp/cna-bible-image-targets.XXXXXX.txt)
image_sources_file=$(mktemp /tmp/cna-bible-image-sources.XXXXXX.txt)
image_orphans_file=$(mktemp /tmp/cna-bible-image-orphans.XXXXXX.txt)
image_duplicates_file=$(mktemp /tmp/cna-bible-image-duplicates.XXXXXX.txt)
image_missing_file=$(mktemp /tmp/cna-bible-image-missing.XXXXXX.txt)
image_graph_ok=1
find "$chapters" "$front" -type f -name '*.tex' -print0 \
    | xargs -0 perl -ne '
        while (/\\includegraphics(?:\[[^]]*\])?\{([^{}]+)\}/g) { print "$1\n"; }
    ' | LC_ALL=C sort > "$image_targets_file" || image_graph_ok=0
find "$book_dir/images" -maxdepth 1 -type f -name '*.png' -printf 'images/%f\n' \
    | LC_ALL=C sort > "$image_sources_file" || image_graph_ok=0
comm -23 "$image_sources_file" "$image_targets_file" > "$image_orphans_file" \
    || image_graph_ok=0
uniq -d "$image_targets_file" > "$image_duplicates_file" || image_graph_ok=0
comm -13 "$image_sources_file" "$image_targets_file" > "$image_missing_file" \
    || image_graph_ok=0
image_source_count=$(line_count "$image_sources_file") || { image_source_count=0; image_graph_ok=0; }
image_target_count=$(line_count "$image_targets_file") || { image_target_count=0; image_graph_ok=0; }
image_orphan_count=$(line_count "$image_orphans_file") || { image_orphan_count=0; image_graph_ok=0; }
image_duplicate_count=$(line_count "$image_duplicates_file") \
    || { image_duplicate_count=0; image_graph_ok=0; }
image_missing_count=$(line_count "$image_missing_file") || { image_missing_count=0; image_graph_ok=0; }
if [ "$image_graph_ok" -eq 1 ] && [ "$image_source_count" -eq 5 ] \
   && [ "$image_target_count" -eq 5 ] \
   && [ "$image_orphan_count" -eq 0 ] && [ "$image_duplicate_count" -eq 0 ] \
   && [ "$image_missing_count" -eq 0 ]; then
    pass "all 5 source PNGs are included exactly once with case-correct paths"
else
    fail "image-source closure failed ($image_source_count files, $image_target_count includes, $image_orphan_count orphaned, $image_duplicate_count duplicated, $image_missing_count missing/non-PNG)"
    sed 's/^/        orphaned: /' "$image_orphans_file" | head -10
    sed 's/^/        duplicated: /' "$image_duplicates_file" | head -10
    sed 's/^/        missing/non-PNG: /' "$image_missing_file" | head -10
fi
rm -f "$image_targets_file" "$image_sources_file" "$image_orphans_file" \
    "$image_duplicates_file" "$image_missing_file"

# ---------------------------------------------------------------- stale facts
echo "-- stale-fact sweep"

# Hard-coded chapter/part/appendix/section references appeared with both TeX ties and ordinary
# spaces, including inside listings. All break silently on a restructure and none produces a
# LaTeX warning.
structure_re='Chapters?(~|[[:space:]])+[0-9]+|Ch\.(~|[[:space:]])*[0-9]+|Parts?(~|[[:space:]])+(I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)\>|Appendix(es)?(~|[[:space:]])+[A-H]\>|Sections?(~|[[:space:]])+[0-9]+([.][0-9]+)*'
forbid_matches "$diagnostic_dir/hard-coded-structure.txt" \
    "hard-coded structural references (use a stable \\ref unless genuinely historical)" \
    "no hard-coded chapter/part/appendix/section references" \
    -rnoE "$structure_re" "$chapters" "$front"

# A \ref written with a doubled backslash silently degrades to a line break plus
# literal text. It produces no warning and no undefined reference -- it is only
# visible by rendering the page. Caught for real on 2026-08-11 in Appendix E.
forbid_matches "$diagnostic_dir/doubled-ref.txt" \
    "doubled-backslash \\\\ref{...} -- renders as a line break plus literal text" \
    "no doubled-backslash \\ref" -rn '\\\\ref{' "$chapters" "$front"

# \cnaclass and \cnans feed their entire argument to makeindex. Pointer/reference declarators
# therefore create misleading keys such as "Album*" or "Game& game" instead of indexing the
# underlying symbol. Keep declarators outside the semantic macro (e.g. \cnaclass{Album}\texttt{*}).
forbid_matches "$diagnostic_dir/index-declarators.txt" \
    "pointer/reference declarators inside semantic index macros" \
    "no pointer/reference declarators inside semantic index macros" \
    -rEn '\\(cnaclass|cnans)\{[^}]*(\*|\\&)[^}]*\}' "$chapters" "$front"

# These spellings previously split one API symbol across multiple top-level index keys. Preserve
# intentional conceptual pairs such as XNB/.xnb and free-direct/FREEDIRECT, but reject the known
# C++ symbol aliases caused by optional call parentheses, omitted owners, or C# namespace dots.
index_alias_re='\\cnaclass\{ContentManager::Load<(Song|T)>\(\)\}|\\cnaclass\{Load<Song>\(\)\}|\\cnaclass\{System\.(GC|Type)\}|\\cnaclass\{SystemException\}'
forbid_matches "$diagnostic_dir/index-aliases.txt" \
    "noncanonical aliases split API symbols across index keys" \
    "no known noncanonical API aliases in semantic index macros" \
    -rEn "$index_alias_re" "$chapters" "$front"

# These source identifiers and build options were removed by CNA's renderer/CNAEXT
# naming migration. Unlike ordinary prose uses of "backend", none is contextually valid in
# the current manuscript. Historical discussion should spell out the old name without using
# it as a live identifier, or live in the audit/plan evidence outside the compiled book.
obsolete_re='IGraphicsBackend|ITextureBackend|ITexture3DBackend|ISpriteBatchBackend|IEffectBackend|ITextureCubeBackend|IRenderTargetBackend|IRenderTargetCubeBackend|IIndexBufferBackend|IVertexBufferBackend|IOcclusionQueryBackend|GraphicsBackendType|GetGraphicsBackendType|GetGraphicsBackendName|GraphicsBackendCreateArgs|CreateGraphicsBackend|D3D11RenderTargetBackend|CNA_GRAPHICS_BACKEND|CNA\\_GRAPHICS\\_BACKEND|CNA_BACKEND_|CNA\\_BACKEND\\_|CNA_RENDERER_(D3D9|D3D11|D3D12|DX3|EASYGL|ASCII)|CNA\\_RENDERER\\_(D3D9|D3D11|D3D12|DX3|EASYGL|ASCII)|NOXNA|BackendSelection\.cmake|BackendLibraries\.cmake|customEffectBackend|GraphicsRendererType::Ascii|dx3\\_(texture\\_rendertarget|no3d)\\_test\.cpp'
forbid_matches "$diagnostic_dir/obsolete-identifiers.txt" \
    "obsolete CNA identifiers/options in compiled manuscript" \
    "no obsolete CNA identifiers/options in compiled manuscript" \
    -rEn "$obsolete_re" "$chapters" "$front"

forbid_matches "$diagnostic_dir/stale-graphics-header-count.txt" \
    "stale 106-header Graphics subtree count in compiled manuscript" \
    "Graphics include count distinguishes 107 direct and 18 PackedVector headers" \
    -rEn '106 headers under' "$chapters" "$front"

forbid_matches "$diagnostic_dir/stale-production-unit-label.txt" \
    "production-file inventory mislabeled as translation units" \
    "physical-module inventory is labeled as production files" \
    -rEn 'production translation units' "$chapters" "$front"

forbid_matches "$diagnostic_dir/stale-platform-counts.txt" \
    "stale platform-directive inventory in compiled manuscript" \
    "platform inventory defines its 1195-file and 152-directive populations" \
    -rEn 'Only 56 of 1\\{,\\}195|contain 159 directives|There are 109[[:space:]]*$' \
    "$chapters" "$front"

forbid_matches "$diagnostic_dir/stale-metagl-consumer-count.txt" \
    "stale easy-gl direct meta-gl consumer count" \
    "easy-gl names 3 header and 15 implementation meta-gl consumers" \
    -rEn '19 production files include.*meta-gl|sixteen implementation files' "$chapters" "$front"

forbid_matches "$diagnostic_dir/obsolete-selectors.txt" \
    "removed renderer selector in a live CMake assignment" \
    "no removed renderer selectors in live CMake assignments" \
    -rEn 'CNA(_|\\_)GRAPHICS(_|\\_)RENDERER=(EASYGL|DX3|D3D9|D3D11|D3D12|ASCII)' \
    "$chapters" "$front"

# Phase 70 contains 65 technical tasks (666--730); Task 731 is its closing documentation task.
# The old wording paired the inclusive 666--731 range with a 65-task total, an off-by-one claim.
forbid_matches "$diagnostic_dir/phase70-count.txt" \
    "Phase 70 task range is paired with the obsolete off-by-one total" \
    "Phase 70 separates 65 technical tasks from its closing documentation task" \
    -rEn 'Tasks(~|[[:space:]])+666--731,? 65 tasks' "$chapters" "$front"

for term in NOXNA "both volumes" "this volume" "Volume I" "Volume II"; do
    if [ "$term" = "NOXNA" ]; then
        # Three compatibility labels intentionally retain the old spelling so incoming links
        # from the previous edition keep resolving; they are not compiled terminology.
        n=$(grep -riw "$term" "$chapters" "$front" 2>/dev/null \
            | grep -ivE '\\label\{[^}]*noxna' | wc -l)
    else
        n=$(grep -riw "$term" "$chapters" "$front" 2>/dev/null | wc -l)
    fi
    [ "$n" -gt 0 ] && info "term '$term': $n occurrence(s) -- inspect each, some may be legitimately historical"
done

# Accidental doubled function words are easy to miss in a long technical manuscript because TeX
# can place the copies on different source and output lines. This caught real "to to" and "is is"
# defects during the final proofread; identifiers such as "SoundBank soundBank" are deliberately
# outside this narrow prose-only vocabulary.
repeated_words_file=$(mktemp /tmp/cna-bible-repeated-words.XXXXXX.txt)
repeated_scan_status=0
find "$chapters" "$front" -name '*.tex' -type f -print0 \
    | while IFS= read -r -d '' source_file; do
        perl -0777 -ne '
            while (/\b(the|a|an|and|or|of|to|in|is|are|was|were|that|this|with|for|from|by|as|at|on|it|its|be|been|has|have|had|not|no)\b[~\s]+\1\b/ig) {
                $prefix = substr($_, 0, $-[0]);
                $line = 1 + ($prefix =~ tr/\n//);
                $match = $&;
                $match =~ s/[~\s]+/ /g;
                print "$ARGV:$line:$match\n";
            }
        ' "$source_file"
    done > "$repeated_words_file" || repeated_scan_status=$?
if [ "$repeated_scan_status" -ne 0 ]; then
    fail "repeated-word source scan failed (pipeline status $repeated_scan_status)"
elif [ -s "$repeated_words_file" ]; then
    fail "repeated common word(s) in compiled prose"
    head -10 "$repeated_words_file" | sed 's/^/        /'
else
    pass "no repeated common words in compiled prose"
fi
rm -f "$repeated_words_file"

# ---------------------------------------------------------------- whitespace
echo "-- working tree"

# A literal tab can silently replace the backslash of a mistyped \texttt command and still yield
# a green LaTeX build (caught visually in Appendix D on 2026-08-12). The manuscript uses spaces,
# so tabs and CRLF carriage returns are always defects in compiled TeX sources.
forbid_matches "$diagnostic_dir/tabs.txt" "literal tab characters in compiled TeX sources" \
    "no literal tabs in compiled TeX sources" -rIn $'\t' \
    "$chapters" "$front" "$book_dir/main.tex"
forbid_matches "$diagnostic_dir/crlf.txt" "carriage returns in compiled TeX sources" \
    "no carriage returns in compiled TeX sources" -rIl $'\r' \
    "$chapters" "$front" "$book_dir/main.tex"

# Compare the resulting worktree to HEAD, not merely unstaged content to the index. Otherwise a
# staged whitespace defect disappears from plain `git diff --check` and can be reported clean.
if git -C "$repo_root" diff HEAD --check > /dev/null 2>&1; then
    pass "git diff HEAD --check clean"
else
    fail "git diff HEAD --check reports whitespace errors"
    git -C "$repo_root" diff HEAD --check | head -20
fi

# ---------------------------------------------------------------- PDF output
echo "-- output"
if ! pdf_info=$(pdfinfo "$pdf" 2>/dev/null); then
    fail "pdfinfo could not parse main.pdf"
    exit 1
fi
pdf_info_scan_ok=1
pages=$(printf '%s\n' "$pdf_info" | awk '/^Pages:/ {print $2}') || pdf_info_scan_ok=0
case "$pages" in
    ''|*[!0-9]*)
        fail "pdfinfo could not parse main.pdf or report a numeric page count"
        exit 1
        ;;
esac
if [ "$pdf_info_scan_ok" -ne 1 ]; then
    fail "could not parse the pdfinfo page-count field"
    exit 1
fi
if [ -z "$pdf_info" ]; then
    fail "pdfinfo could not parse main.pdf"
    exit 1
else
    pass "PDF container is readable"
fi
info "main.pdf is $pages pages"
info "chapter LaTeX: $(find "$chapters" -name '*.tex' | xargs cat 2>/dev/null | wc -l) lines across $(find "$chapters" -name '*.tex' | wc -l) files"

pdf_info_fields_ok=1
encrypted=$(printf '%s\n' "$pdf_info" | awk -F: '/^Encrypted:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
form=$(printf '%s\n' "$pdf_info" | awk -F: '/^Form:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
javascript=$(printf '%s\n' "$pdf_info" | awk -F: '/^JavaScript:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
pdf_version=$(printf '%s\n' "$pdf_info" | awk -F: '/^PDF version:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
tagged=$(printf '%s\n' "$pdf_info" | awk -F: '/^Tagged:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
suspects=$(printf '%s\n' "$pdf_info" | awk -F: '/^Suspects:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
user_properties=$(printf '%s\n' "$pdf_info" | awk -F: '/^UserProperties:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
title=$(printf '%s\n' "$pdf_info" | awk -F: '/^Title:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
author=$(printf '%s\n' "$pdf_info" | awk -F: '/^Author:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
subject=$(printf '%s\n' "$pdf_info" | awk -F: '/^Subject:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
keywords=$(printf '%s\n' "$pdf_info" | awk -F: '/^Keywords:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
creator=$(printf '%s\n' "$pdf_info" | awk -F: '/^Creator:/ {sub(/^[[:space:]]+/, "", $2); print $2}') || pdf_info_fields_ok=0
info_object_ok=1
if ! trapped=$(mutool show -g "$pdf" trailer/Info 2>/dev/null \
    | sed -n 's/.*\/Trapped\/\([^/>]*\).*/\1/p'); then
    trapped=""
    info_object_ok=0
fi
page_boxes_ok=1
if ! page_boxes=$(pdfinfo -f 1 -l "$pages" -box "$pdf" 2>/dev/null); then
    page_boxes=""
    page_boxes_ok=0
fi
page_profile_scan_ok=1
if ! a4_pages=$(printf '%s\n' "$page_boxes" \
    | grep_count -cE '^Page +[0-9]+ size:  +595\.276 x 841\.89 pts \(A4\)$'); then
    a4_pages=0; page_profile_scan_ok=0
fi
if ! unrotated_pages=$(printf '%s\n' "$page_boxes" \
    | grep_count -cE '^Page +[0-9]+ rot:  +0$'); then
    unrotated_pages=0; page_profile_scan_ok=0
fi
complete_page_boxes=1
for box_name in MediaBox CropBox BleedBox TrimBox ArtBox; do
    if ! box_count=$(printf '%s\n' "$page_boxes" \
        | grep_count -cE "^Page +[0-9]+ ${box_name}: +0\.00 +0\.00 +595\.28 +841\.89$"); then
        box_count=0; page_profile_scan_ok=0
    fi
    [ "$box_count" -eq "$pages" ] || complete_page_boxes=0
done
if [ "$pdf_info_fields_ok" -eq 1 ] && [ "$pages" -eq 709 ] \
   && [ "$pdf_version" = "1.7" ] && [ "$encrypted" = "no" ] \
   && [ "$tagged" = "no" ] && [ "$suspects" = "no" ] && [ "$user_properties" = "no" ] \
   && [ "$page_boxes_ok" -eq 1 ] && [ "$page_profile_scan_ok" -eq 1 ] \
   && [ "$a4_pages" -eq "$pages" ] \
   && [ "$unrotated_pages" -eq "$pages" ] && [ "$complete_page_boxes" -eq 1 ]; then
    pass "PDF 1.7 has 709 untagged, unencrypted, unsuspect A4 pages with matching boxes"
else
    fail "unexpected PDF profile/geometry ($pages pages, version=$pdf_version, tagged=$tagged, suspects=$suspects, user-properties=$user_properties, encrypted=$encrypted, $a4_pages A4, $unrotated_pages unrotated, boxes=$complete_page_boxes)"
fi
if [ "$pdf_info_fields_ok" -eq 1 ] && [ "$form" = "none" ] && [ "$javascript" = "no" ]; then
    pass "PDF contains no forms or JavaScript"
else
    fail "unexpected active PDF content (form='${form:-?}', JavaScript='${javascript:-?}')"
fi
if [ "$title" = "The CNA Bible" ] && [ "$author" = "Robert Vokac" ] \
   && [ "$subject" = "A source-grounded guide to CNA and the Microsoft XNA 4.0 programming model" ] \
   && [ "$keywords" = "CNA, Microsoft XNA, C++23, graphics renderers, game development" ] \
   && [ "$creator" = "LaTeX with hyperref" ] && [ "$pdf_info_fields_ok" -eq 1 ] \
   && [ "$info_object_ok" -eq 1 ] \
   && [ "$trapped" = "False" ]; then
    pass "PDF title, author, subject, keywords, creator, and trapped state match release metadata"
else
    fail "unexpected or incomplete PDF release metadata (creator='${creator:-?}', trapped='${trapped:-?}')"
fi

# LaTeX's Overfull diagnostics include harmless internal boxes as well as real clipping. Parse
# Poppler's word coordinates against each page's own MediaBox to catch the release-blocking case:
# visible text that actually crosses a physical PDF edge. This invariant was added after Phase G
# found 44 clipped words despite a successful build and clean contact-sheet overview.
bbox_file=$(mktemp /tmp/cna-bible-bbox.XXXXXX.html)
if pdftotext -bbox-layout "$pdf" "$bbox_file" 2>/dev/null; then
    outside=$(
        perl -0777 -ne '
            $n = 0;
            while (/<page width="([0-9.]+)" height="([0-9.]+)">(.*?)<\/page>/sg) {
                ($w, $h, $body) = ($1, $2, $3);
                while ($body =~ /<word xMin="([0-9.]+)" yMin="([0-9.]+)" xMax="([0-9.]+)" yMax="([0-9.]+)">/sg) {
                    $n++ if $1 < 0 || $2 < 0 || $3 > $w || $4 > $h;
                }
            }
            END { print $n; }
        ' "$bbox_file"
    )
    if [ "$outside" -eq 0 ]; then
        pass "no extracted text crosses a physical page edge"
    else
        fail "$outside extracted word(s) cross a physical page edge"
    fi
else
    fail "pdftotext could not inspect PDF text bounds"
fi
rm -f "$bbox_file"

# Bind the searchable layer to the reviewed corrected release. Besides catching an unexpectedly
# missing prose block, reject byte-level extraction corruption that a simple non-empty check would
# overlook. The word count deliberately uses the same Poppler layout mode recorded in the plan.
text_layer_file=$(mktemp /tmp/cna-bible-text-layer.XXXXXX.txt)
if pdftotext -layout "$pdf" "$text_layer_file" 2>/dev/null; then
    text_layer_scan_ok=1
    text_layer_words=$(wc -w < "$text_layer_file") || { text_layer_words=0; text_layer_scan_ok=0; }
    text_layer_counts=$(perl -0777 -ne '
        $nul += () = /\x00/g;
        $replacement += () = /\xEF\xBF\xBD/g;
        END { print (($nul + 0) . " " . ($replacement + 0)); }
    ' "$text_layer_file") || { text_layer_counts="0 0"; text_layer_scan_ok=0; }
    read -r text_layer_nuls text_layer_replacements <<EOF
$text_layer_counts
EOF
    if [ "$text_layer_scan_ok" -eq 1 ] && [ "$text_layer_words" -eq 302448 ] \
       && [ "$text_layer_nuls" -eq 0 ] \
       && [ "$text_layer_replacements" -eq 0 ]; then
        pass "searchable text layer has 302448 words and no NUL/U+FFFD corruption"
    else
        fail "unexpected searchable text layer ($text_layer_words words, $text_layer_nuls NUL, $text_layer_replacements U+FFFD)"
    fi
else
    fail "pdftotext could not extract the searchable text layer"
fi
rm -f "$text_layer_file"

# A standalone technical book must not depend on workstation fonts, and its searchable text
# needs ToUnicode maps. Read columns from the right because the font type can contain a space
# (for example, "Type 1").
font_parser_ok=1
if ! font_summary=$(
    pdffonts "$pdf" 2>/dev/null | awk '
        NR > 2 && NF >= 8 {
            total++;
            if ($(NF-4) != "yes" || $(NF-3) != "yes" || $(NF-2) != "yes") bad++;
        }
        END { print total + 0, bad + 0; }
    '
); then
    font_summary="0 0"
    font_parser_ok=0
fi
read -r font_total font_bad <<EOF
$font_summary
EOF
if [ "$font_parser_ok" -eq 1 ] && [ "$font_total" -eq 27 ] && [ "$font_bad" -eq 0 ]; then
    pass "all 27 fonts are embedded, subsetted, and Unicode-mapped"
else
    fail "font portability check failed ($font_bad of $font_total font rows incomplete)"
fi

# Prove that every reviewed source PNG survives PDF embedding pixel-for-pixel. pdfTeX stores each
# RGBA source as one RGB image plus one grayscale soft mask, so compare both decoded Netpbm planes
# in compilation order. This checks content rather than compression bytes or object numbers.
image_audit_dir=$(mktemp -d /tmp/cna-bible-images.XXXXXX)
if pdfimages -png "$pdf" "$image_audit_dir/image" >/dev/null 2>&1; then
    image_decode_scan_ok=1
    embedded_image_files=$(find "$image_audit_dir" -maxdepth 1 -type f -name 'image-*.png' | wc -l) \
        || { embedded_image_files=0; image_decode_scan_ok=0; }
    source_image_files=$(find "$book_dir/images" -maxdepth 1 -type f -name '*.png' | wc -l) \
        || { source_image_files=0; image_decode_scan_ok=0; }
    image_mismatches=0
    image_number=0
    for source_image in \
        "$book_dir/images/ch07-matrix-rotation-software.png" \
        "$book_dir/images/ch09-rendertarget-roundtrip-software.png" \
        "$book_dir/images/ch09-drawprimitives-software.png" \
        "$book_dir/images/ch18-spritebatch-rotation-easygl.png" \
        "$book_dir/images/ch17-spritebatch-rotation-sdlrenderer.png"; do
        rgb_image=$(printf '%s/image-%03d.png' "$image_audit_dir" "$image_number")
        alpha_image=$(printf '%s/image-%03d.png' "$image_audit_dir" "$((image_number + 1))")
        source_rgb=$(printf '%s/source-rgb-%03d.pnm' "$image_audit_dir" "$image_number")
        source_alpha=$(printf '%s/source-alpha-%03d.pnm' "$image_audit_dir" "$image_number")
        embedded_rgb=$(printf '%s/embedded-rgb-%03d.pnm' "$image_audit_dir" "$image_number")
        embedded_alpha=$(printf '%s/embedded-alpha-%03d.pnm' "$image_audit_dir" "$image_number")
        if ! pngtopnm "$source_image" > "$source_rgb" 2>/dev/null \
           || ! pngtopnm -alpha "$source_image" > "$source_alpha" 2>/dev/null \
           || ! pngtopnm "$rgb_image" > "$embedded_rgb" 2>/dev/null \
           || ! pngtopnm "$alpha_image" > "$embedded_alpha" 2>/dev/null \
           || ! cmp -s "$source_rgb" "$embedded_rgb" \
           || ! cmp -s "$source_alpha" "$embedded_alpha"; then
            image_mismatches=$((image_mismatches + 1))
        fi
        image_number=$((image_number + 2))
    done
    if [ "$image_decode_scan_ok" -eq 1 ] && [ "$source_image_files" -eq 5 ] \
       && [ "$embedded_image_files" -eq 10 ] \
       && [ "$image_mismatches" -eq 0 ]; then
        pass "all 5 source PNGs match their 5 embedded RGB/alpha image pairs pixel-for-pixel"
    else
        fail "PDF image provenance failed ($source_image_files sources, $embedded_image_files extracted planes, $image_mismatches mismatches)"
    fi
else
    fail "pdfimages could not extract the embedded image inventory"
fi
find "$image_audit_dir" -mindepth 1 -maxdepth 1 -type f -delete
rmdir "$image_audit_dir"

# Verify the navigation structure in the produced artifact, not only the source input list.
# Hyperref names ordinary chapters chapter.N and appendices appendix.A, while Parts use part.N.
if command -v mutool >/dev/null 2>&1; then
    page_labels_ok=1
    if ! page_labels=$(mutool show -g "$pdf" trailer/Root/PageLabels 2>/dev/null); then
        page_labels=""
        page_labels_ok=0
    fi
    # Match the complete number tree, not a substring: any unnoticed later entry would relabel
    # the rest of the document while preserving the expected transition at physical page 31.
    if [ "$page_labels_ok" -eq 1 ] \
       && [ "$page_labels" = '<</Nums[0<</S/r>>30<</S/D>>]>>' ] && [ "$pages" -eq 709 ]; then
        pass "all 709 page labels run i--xxx, then 1--679"
    else
        fail "unexpected PDF page-label number tree ('${page_labels:-?}')"
    fi

    document_language_ok=1
    if ! document_language=$(mutool show -g "$pdf" trailer/Root/Lang 2>/dev/null); then
        document_language=""
        document_language_ok=0
    fi
    if [ "$document_language_ok" -eq 1 ] && [ "$document_language" = "(en-US)" ]; then
        pass "PDF catalog declares English (United States) as its document language"
    else
        fail "unexpected or missing PDF document language ('${document_language:-?}')"
    fi

    # Positively bind the catalog surface. Object numbers are intentionally normalized because
    # harmless content edits can renumber them; keys and action semantics must remain exact.
    catalog_reads_ok=1
    if ! catalog=$(mutool show -g "$pdf" trailer/Root 2>/dev/null); then
        catalog=""
        catalog_reads_ok=0
    fi
    if ! catalog_normalized=$(printf '%s\n' "$catalog" \
        | sed -E 's/^[0-9]+ 0 obj /OBJ obj /; s/[0-9]+ 0 R/OBJ/g'); then
        catalog_normalized=""
        catalog_reads_ok=0
    fi
    if ! names_root=$(mutool show -g "$pdf" trailer/Root/Names 2>/dev/null); then
        names_root=""
        catalog_reads_ok=0
    fi
    if ! names_root_normalized=$(printf '%s\n' "$names_root" \
        | sed -E 's/^[0-9]+ 0 obj /OBJ obj /; s/[0-9]+ 0 R/OBJ/g'); then
        names_root_normalized=""
        catalog_reads_ok=0
    fi
    if ! open_action=$(mutool show -g "$pdf" trailer/Root/OpenAction 2>/dev/null); then
        open_action=""
        catalog_reads_ok=0
    fi
    if ! open_action_page=$(printf '%s\n' "$open_action" \
        | sed -n 's/.*\/S\/GoTo\/D\[\([0-9]*\) 0 R\/Fit\].*/\1/p'); then
        open_action_page=""
        catalog_reads_ok=0
    fi
    if ! first_page_object=$(mutool show -g "$pdf" pages/1 2>/dev/null \
        | sed -n 's/^\([0-9]*\) 0 obj .*/\1/p'); then
        first_page_object=""
        catalog_reads_ok=0
    fi
    expected_catalog='OBJ obj <</Type/Catalog/Pages OBJ/Outlines OBJ/Names OBJ/PageMode/UseOutlines/Lang(en-US)/PageLabels<</Nums[0<</S/r>>30<</S/D>>]>>/OpenAction OBJ>>'
    if [ "$catalog_reads_ok" -eq 1 ] && [ "$catalog_normalized" = "$expected_catalog" ] \
       && [ "$names_root_normalized" = 'OBJ obj <</Dests OBJ>>' ] \
       && [ -n "$first_page_object" ] && [ "$open_action_page" = "$first_page_object" ]; then
        pass "PDF catalog exposes only outline, destinations, labels, language, and first-page GoTo"
    else
        fail "unexpected PDF catalog, Names root, or OpenAction"
    fi

    outline_file=$(mktemp /tmp/cna-bible-outline.XXXXXX.txt)
    if mutool show "$pdf" outline > "$outline_file" 2>/dev/null; then
        outline_dests_file=$(mktemp /tmp/cna-bible-outline-dests.XXXXXX.txt)
        toc_outline_dests_file=$(mktemp /tmp/cna-bible-toc-outline-dests.XXXXXX.txt)
        outline_toc_diff_file=$(mktemp /tmp/cna-bible-outline-toc-diff.XXXXXX.txt)
        outline_titles_file=$(mktemp /tmp/cna-bible-outline-titles.XXXXXX.txt)
        source_bookmarks_file=$(mktemp /tmp/cna-bible-source-bookmarks.XXXXXX.txt)
        outline_title_diff_file=$(mktemp /tmp/cna-bible-outline-title-diff.XXXXXX.txt)
        outline_parents_file=$(mktemp /tmp/cna-bible-outline-parents.XXXXXX.txt)
        source_parents_file=$(mktemp /tmp/cna-bible-source-parents.XXXXXX.txt)
        outline_parent_diff_file=$(mktemp /tmp/cna-bible-outline-parent-diff.XXXXXX.txt)
        outline_order_file=$(mktemp /tmp/cna-bible-outline-order.XXXXXX.txt)
        source_order_file=$(mktemp /tmp/cna-bible-source-order.XXXXXX.txt)
        outline_graph_ok=1
        grep -o '#nameddest=[^[:space:]]*' "$outline_file" | sed 's/#nameddest=//' \
            | sort > "$outline_dests_file" || outline_graph_ok=0
        perl -ne '
            print "$2\n"
                if /\\contentsline \{(part|chapter|section|subsection)\}.*\{([^{}]+)\}%$/;
        ' "$book_dir/main.toc" | sort > "$toc_outline_dests_file" || outline_graph_ok=0
        comm -3 "$outline_dests_file" "$toc_outline_dests_file" > "$outline_toc_diff_file" \
            || outline_graph_ok=0
        perl -ne '
            if (/"(.*)"\s+#nameddest=([^\s]+)$/) { print "$2\t$1\n"; }
        ' "$outline_file" | LC_ALL=C sort > "$outline_titles_file" || outline_graph_ok=0
        perl -MEncode=decode -ne '
            BEGIN { binmode STDOUT, ":encoding(UTF-8)"; }
            if (/^\\BOOKMARK \[[^]]*\]\[[^]]*\]\{([^}]*)\}\{(.*)\}\{[^}]*\}%/) {
                ($destination, $title) = ($1, $2);
                $title =~ s/\\([0-7]{3})/chr(oct($1))/ge;
                $title = decode("UTF-16BE", $title);
                $title =~ s/^\x{FEFF}//;
                print "$destination\t$title\n";
            }
        ' "$book_dir/main.out" | LC_ALL=C sort > "$source_bookmarks_file" \
            || outline_graph_ok=0
        comm -3 "$outline_titles_file" "$source_bookmarks_file" > "$outline_title_diff_file" \
            || outline_graph_ok=0
        perl -ne '
            if (/^[+|]\t(\t*)".*"\t#nameddest=([^\s]+)$/) {
                $depth = 1 + length($1);
                $destination = $2;
                $parent = $depth > 1 ? ($at_depth{$depth - 1} // "") : "";
                print "$destination\t$parent\n";
                $at_depth{$depth} = $destination;
                for $candidate (keys %at_depth) {
                    delete $at_depth{$candidate} if $candidate > $depth;
                }
            }
        ' "$outline_file" | LC_ALL=C sort > "$outline_parents_file" || outline_graph_ok=0
        perl -ne '
            if (/^\\BOOKMARK \[[^]]*\]\[[^]]*\]\{([^}]*)\}\{.*\}\{([^}]*)\}%/) {
                print "$1\t$2\n";
            }
        ' "$book_dir/main.out" | LC_ALL=C sort > "$source_parents_file" \
            || outline_graph_ok=0
        comm -3 "$outline_parents_file" "$source_parents_file" > "$outline_parent_diff_file" \
            || outline_graph_ok=0
        grep -o '#nameddest=[^[:space:]]*' "$outline_file" | sed 's/#nameddest=//' \
            > "$outline_order_file" || outline_graph_ok=0
        sed -n 's/^\\BOOKMARK \[[^]]*\]\[[^]]*\]{\([^}]*\)}.*/\1/p' \
            "$book_dir/main.out" > "$source_order_file" || outline_graph_ok=0
        outline_count_scan_ok=1
        if ! outline_entries=$(grep_count -c '#nameddest=' "$outline_file"); then
            outline_entries=0; outline_count_scan_ok=0
        fi
        if ! outline_destinations=$(grep -o '#nameddest=[^[:space:]]*' "$outline_file" \
            | sort -u | wc -l); then
            outline_destinations=0; outline_graph_ok=0
        fi
        if ! outline_empty_titles=$(awk -F'"' '$0 ~ /#nameddest=/ && (NF < 3 || $2 == "") { count++ } END { print count + 0 }' \
            "$outline_file"); then
            outline_empty_titles=0; outline_graph_ok=0
        fi
        if ! outline_parts=$(grep_count -c '#nameddest=part\.' "$outline_file"); then
            outline_parts=0; outline_count_scan_ok=0
        fi
        if ! outline_chapters=$(grep_count -c '#nameddest=chapter\.[0-9]' "$outline_file"); then
            outline_chapters=0; outline_count_scan_ok=0
        fi
        if ! outline_appendices=$(grep_count -c '#nameddest=appendix\.[A-H]' "$outline_file"); then
            outline_appendices=0; outline_count_scan_ok=0
        fi
        if [ "$outline_graph_ok" -eq 1 ] && [ "$outline_count_scan_ok" -eq 1 ] \
           && [ "$outline_parts" -eq 12 ] \
           && [ "$outline_chapters" -eq 79 ] \
           && [ "$outline_appendices" -eq 8 ]; then
            pass "PDF outline contains 12 Parts, 79 chapters, and 8 appendices"
        else
            fail "unexpected PDF outline ($outline_parts Parts, $outline_chapters chapters, $outline_appendices appendices)"
        fi
        if [ "$outline_graph_ok" -eq 1 ] && [ "$outline_count_scan_ok" -eq 1 ] \
           && [ "$outline_entries" -eq 1066 ] \
           && [ "$outline_destinations" -eq "$outline_entries" ] \
           && [ "$outline_empty_titles" -eq 0 ]; then
            pass "all $outline_entries PDF outline entries have non-empty titles and unique destinations"
        else
            fail "damaged PDF outline ($outline_entries entries, $outline_destinations unique destinations, $outline_empty_titles empty titles)"
        fi
        outline_toc_diff_count=$(line_count "$outline_toc_diff_file") \
            || { outline_toc_diff_count=0; outline_graph_ok=0; }
        if [ "$outline_graph_ok" -eq 1 ] && [ "$outline_entries" -eq 1066 ] \
           && [ "$outline_toc_diff_count" -eq 0 ]; then
            pass "PDF outline exactly matches all 1066 Part-through-subsection TOC destinations"
        else
            fail "PDF outline/TOC mismatch ($outline_toc_diff_count differing destinations)"
            head -10 "$outline_toc_diff_file" | sed 's/^/        /'
        fi
        outline_title_count=$(line_count "$outline_titles_file") \
            || { outline_title_count=0; outline_graph_ok=0; }
        source_bookmark_count=$(line_count "$source_bookmarks_file") \
            || { source_bookmark_count=0; outline_graph_ok=0; }
        outline_title_diff_count=$(line_count "$outline_title_diff_file") \
            || { outline_title_diff_count=0; outline_graph_ok=0; }
        if [ "$outline_graph_ok" -eq 1 ] && [ "$outline_title_count" -eq 1066 ] \
           && [ "$source_bookmark_count" -eq "$outline_title_count" ] \
           && [ "$outline_title_diff_count" -eq 0 ]; then
            pass "all 1066 PDF outline titles match their source bookmarks exactly"
        else
            fail "PDF outline title mismatch ($outline_title_count PDF, $source_bookmark_count source, $outline_title_diff_count differing pairs)"
            head -10 "$outline_title_diff_file" | sed 's/^/        /'
        fi
        outline_parent_count=$(line_count "$outline_parents_file") \
            || { outline_parent_count=0; outline_graph_ok=0; }
        source_parent_count=$(line_count "$source_parents_file") \
            || { source_parent_count=0; outline_graph_ok=0; }
        outline_parent_diff_count=$(line_count "$outline_parent_diff_file") \
            || { outline_parent_diff_count=0; outline_graph_ok=0; }
        if [ "$outline_graph_ok" -eq 1 ] && [ "$outline_parent_count" -eq 1066 ] \
           && [ "$source_parent_count" -eq "$outline_parent_count" ] \
           && [ "$outline_parent_diff_count" -eq 0 ]; then
            pass "all 1066 PDF outline entries match their source parent hierarchy"
        else
            fail "PDF outline hierarchy mismatch ($outline_parent_count PDF, $source_parent_count source, $outline_parent_diff_count differing pairs)"
            head -10 "$outline_parent_diff_file" | sed 's/^/        /'
        fi
        outline_order_count=$(line_count "$outline_order_file") \
            || { outline_order_count=0; outline_graph_ok=0; }
        source_order_count=$(line_count "$source_order_file") \
            || { source_order_count=0; outline_graph_ok=0; }
        if [ "$outline_graph_ok" -eq 1 ] && [ "$outline_order_count" -eq 1066 ] \
           && [ "$source_order_count" -eq "$outline_order_count" ] \
           && cmp -s "$outline_order_file" "$source_order_file"; then
            pass "all 1066 PDF outline entries preserve source bookmark order"
        else
            fail "PDF outline order mismatch ($outline_order_count PDF, $source_order_count source)"
            diff -u "$source_order_file" "$outline_order_file" | head -20 | sed 's/^/        /'
        fi
        rm -f "$outline_dests_file" "$toc_outline_dests_file" "$outline_toc_diff_file" \
            "$outline_titles_file" "$source_bookmarks_file" "$outline_title_diff_file" \
            "$outline_parents_file" "$source_parents_file" "$outline_parent_diff_file"
        rm -f "$outline_order_file" "$source_order_file"
    else
        fail "mutool could not read the PDF outline"
    fi
    rm -f "$outline_file"

    # Hyperref can leave a syntactically valid link annotation whose named destination vanished.
    # Compare every unique internal GoTo target with the PDF name tree, so a clickable but dead
    # TOC, index, or prose link fails release verification even when TeX resolved its source ref.
    objects_file=$(mktemp /tmp/cna-bible-objects.XXXXXX.txt)
    link_dests_file=$(mktemp /tmp/cna-bible-link-dests.XXXXXX.txt)
    named_dests_file=$(mktemp /tmp/cna-bible-named-dests.XXXXXX.txt)
    missing_dests_file=$(mktemp /tmp/cna-bible-missing-dests.XXXXXX.txt)
    if mutool show -g "$pdf" grep > "$objects_file" 2>/dev/null; then
        # This edition intentionally links to exactly three primary API references. Refuse remote
        # navigation, launch/script/form actions, embedded files, or an unreviewed external URI.
        # A future legitimate link must therefore be reviewed and added to this explicit allowlist.
        external_uris_file=$(mktemp /tmp/cna-bible-external-uris.XXXXXX.txt)
        expected_uris_file=$(mktemp /tmp/cna-bible-expected-uris.XXXXXX.txt)
        unexpected_uris_file=$(mktemp /tmp/cna-bible-unexpected-uris.XXXXXX.txt)
        missing_uris_file=$(mktemp /tmp/cna-bible-missing-uris.XXXXXX.txt)
        action_graph_ok=1
        perl -ne 'while (m{/URI\((https://[^()]*)\)}g) { print "$1\n"; }' "$objects_file" \
            | sort -u > "$external_uris_file" || action_graph_ok=0
        printf '%s\n' \
            'https://learn.microsoft.com/en-us/windows/win32/api/dxgi/nf-dxgi-idxgiswapchain-present' \
            'https://learn.microsoft.com/en-us/windows/win32/direct3d9/d3dpresent' \
            'https://wiki.libsdl.org/SDL3/SDL_Init' \
            | sort -u > "$expected_uris_file" || action_graph_ok=0
        comm -23 "$external_uris_file" "$expected_uris_file" > "$unexpected_uris_file" \
            || action_graph_ok=0
        comm -13 "$external_uris_file" "$expected_uris_file" > "$missing_uris_file" \
            || action_graph_ok=0
        action_count_scan_ok=1
        if ! unsafe_action_count=$(grep_count -Ec '/S/(JavaScript|JS|Launch|GoToR|SubmitForm|ImportData)([^A-Za-z]|$)|/EmbeddedFiles([^A-Za-z]|$)' "$objects_file"); then
            unsafe_action_count=0
            action_count_scan_ok=0
        fi
        if ! annotation_action_census=$(
            perl -ne '
                next unless m{/Type/Annot};
                $annotations++;
                $links++ if m{/Subtype/Link(?:[^A-Za-z]|$)};
                if (m{/A<<.*?/S/GoTo(?:[^A-Za-z]|$)}) { $goto++; }
                elsif (m{/A<<.*?/S/URI(?:[^A-Za-z]|$)}) { $uri++; }
                elsif (m{/Dest[\[(]}) { $direct++; }
                else { $other++; }
                END { print join(" ", map { $_ + 0 }
                    ($annotations, $links, $goto, $uri, $direct, $other)); }
            ' "$objects_file"
        ); then
            annotation_action_census="0 0 0 0 0 0"
            action_graph_ok=0
        fi
        read -r annotation_count link_subtype_count goto_action_count uri_action_count \
            direct_destination_count other_annotation_count <<EOF
$annotation_action_census
EOF
        external_uri_count=$(line_count "$external_uris_file") \
            || { external_uri_count=0; action_graph_ok=0; }
        unexpected_uri_count=$(line_count "$unexpected_uris_file") \
            || { unexpected_uri_count=0; action_graph_ok=0; }
        missing_uri_count=$(line_count "$missing_uris_file") \
            || { missing_uri_count=0; action_graph_ok=0; }
        if [ "$action_graph_ok" -eq 1 ] && [ "$action_count_scan_ok" -eq 1 ] \
           && [ "$unsafe_action_count" -eq 0 ] \
           && [ "$external_uri_count" -eq 3 ] \
           && [ "$annotation_count" -eq 3653 ] && [ "$link_subtype_count" -eq 3653 ] \
           && [ "$goto_action_count" -eq 3650 ] && [ "$uri_action_count" -eq 3 ] \
           && [ "$direct_destination_count" -eq 0 ] && [ "$other_annotation_count" -eq 0 ] \
           && [ "$unexpected_uri_count" -eq 0 ] && [ "$missing_uri_count" -eq 0 ]; then
            pass "all annotations are 3650 internal GoTo + 3 reviewed HTTPS Link actions"
        else
            fail "PDF action audit failed ($annotation_count annotations, $link_subtype_count Link, $goto_action_count GoTo, $uri_action_count URI, $direct_destination_count direct, $other_annotation_count other, $unsafe_action_count blacklisted)"
            sed 's/^/        unexpected: /' "$unexpected_uris_file" | head -10
            sed 's/^/        missing: /' "$missing_uris_file" | head -10
        fi
        rm -f "$external_uris_file" "$expected_uris_file" "$unexpected_uris_file" "$missing_uris_file"

        destination_graph_ok=1
        perl -ne '
            next unless m{/S/GoTo};
            while (m{/D\(([^()]*)\)}g) { print "$1\n"; }
        ' "$objects_file" | sort -u > "$link_dests_file" || destination_graph_ok=0
        perl -ne '
            next unless m{/Names\[};
            while (m{\(([^()]*)\)\d+ 0 R}g) { print "$1\n"; }
        ' "$objects_file" | sort -u > "$named_dests_file" || destination_graph_ok=0
        comm -23 "$link_dests_file" "$named_dests_file" > "$missing_dests_file" \
            || destination_graph_ok=0
        link_dest_count=$(line_count "$link_dests_file") \
            || { link_dest_count=0; destination_graph_ok=0; }
        missing_dest_count=$(line_count "$missing_dests_file") \
            || { missing_dest_count=0; destination_graph_ok=0; }
        if [ "$destination_graph_ok" -eq 1 ] && [ "$link_dest_count" -eq 1542 ] \
           && [ "$missing_dest_count" -eq 0 ]; then
            pass "all 1542 unique internal PDF link targets exist"
        else
            fail "internal PDF link audit failed ($missing_dest_count missing of $link_dest_count unique targets)"
            head -10 "$missing_dests_file" | sed 's/^/        /'
        fi

        # Validate the complete named-destination tree, not only names reached by current links.
        # Every name must map one-to-one to an XYZ destination on a real page object, with finite
        # in-page coordinates and inherited zoom. This catches dormant corrupt destinations that
        # would otherwise surface only when a future link begins using them.
        named_destination_result_file=$(mktemp /tmp/cna-bible-named-destinations.XXXXXX.txt)
        complete_pages_file=$(mktemp /tmp/cna-bible-complete-pages.XXXXXX.txt)
        if mutool show "$pdf" pages > "$complete_pages_file" 2>/dev/null; then
            perl -e '
                my ($objects, $pages) = @ARGV;
                open P, "<", $pages or die $!;
                while (<P>) { $page_object{$1} = 1 if /page \d+ = (\d+) 0 R/; }
                close P;
                open O, "<", $objects or die $!;
                while (<O>) {
                    if (/^(\d+) 0 obj .*\/D\[(\d+) 0 R\/XYZ ([^ ]+) ([^ ]+) ([^\]]+)\]/) {
                        $destination{$1} = [$2, $3, $4, $5];
                    }
                    if (/\/Names\[/) {
                        while (/\(([^()]*)\)(\d+) 0 R/g) {
                            $name{$1} = $2;
                            $name_pairs++;
                        }
                    }
                }
                close O;
                for $name (sort keys %name) {
                    $record = $destination{$name{$name}};
                    unless (defined $record) {
                        $bad++;
                        print "name=$name missing-destination-object=$name{$name}\n";
                        next;
                    }
                    ($page, $x, $y, $zoom) = @$record;
                    $invalid = !$page_object{$page}
                        || $x eq "null" || $y eq "null"
                        || $x !~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/
                        || $y !~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/
                        || $x < 0 || $x > 595.276 || $y < 0 || $y > 841.89
                        || $zoom ne "null";
                    if ($invalid) {
                        $bad++;
                        print "name=$name page-object=$page xyz=$x,$y,$zoom\n";
                    }
                    $used_destination{$name{$name}}++;
                }
                for $object (sort { $a <=> $b } keys %destination) {
                    unless (exists $used_destination{$object}) {
                        $bad++;
                        print "orphan-destination-object=$object\n";
                    }
                }
                $duplicate_names = $name_pairs - scalar(keys %name);
                $duplicate_objects = 0;
                for $object (keys %used_destination) {
                    $duplicate_objects += $used_destination{$object} - 1
                        if $used_destination{$object} > 1;
                }
                $bad += $duplicate_names + $duplicate_objects;
                print "SUMMARY " . scalar(keys %name) . " " . scalar(keys %destination)
                    . " " . ($bad + 0) . "\n";
            ' "$objects_file" "$complete_pages_file" > "$named_destination_result_file"
            read -r _ named_destination_count destination_object_count bad_named_destination_count <<EOF
$(tail -1 "$named_destination_result_file")
EOF
            if [ "$named_destination_count" -eq 5054 ] \
               && [ "$destination_object_count" -eq "$named_destination_count" ] \
               && [ "$bad_named_destination_count" -eq 0 ]; then
                pass "all 5054 named destinations map one-to-one to valid in-page XYZ targets"
            else
                fail "PDF named-destination audit failed ($named_destination_count names, $destination_object_count objects, $bad_named_destination_count invalid/duplicate/orphan records)"
                grep -v '^SUMMARY ' "$named_destination_result_file" | head -10 | sed 's/^/        /'
            fi
        else
            fail "MuPDF could not map pages for the complete named-destination audit"
        fi
        rm -f "$named_destination_result_file" "$complete_pages_file"

        # Every clickable annotation also needs a non-inverted rectangle inside A4 and either an
        # action or a direct destination. Broken geometry can make a valid target unclickable.
        link_geometry=$(
            perl -ne '
                next unless m{/Subtype/Link};
                $links++;
                $targeted++ if m{/A<<} || m{/Dest[\[(]};
                if (m{/Rect\[([-.0-9]+) ([-.0-9]+) ([-.0-9]+) ([-.0-9]+)\]}) {
                    ($x0, $y0, $x1, $y1) = ($1, $2, $3, $4);
                    $rects++;
                    $bad++ if $x0 < 0 || $y0 < 0 || $x1 > 595.276 || $y1 > 841.89
                              || $x1 < $x0 || $y1 < $y0;
                }
                END { print join(" ", $links + 0, $targeted + 0, $rects + 0, $bad + 0); }
            ' "$objects_file"
        )
        read -r link_count targeted_link_count rect_link_count bad_link_count <<EOF
$link_geometry
EOF
        if [ "$link_count" -eq 3653 ] && [ "$targeted_link_count" -eq "$link_count" ] \
           && [ "$rect_link_count" -eq "$link_count" ] && [ "$bad_link_count" -eq 0 ]; then
            pass "all 3653 PDF link annotations have valid A4 geometry and targets"
        else
            fail "PDF link annotation audit failed ($link_count links, $targeted_link_count targets, $rect_link_count rectangles, $bad_link_count invalid)"
        fi

        page_objects_file=$(mktemp /tmp/cna-bible-page-objects.XXXXXX.txt)
        toc_target_result_file=$(mktemp /tmp/cna-bible-toc-targets.XXXXXX.txt)
        page_objects_ok=1
        if ! mutool show "$pdf" pages > "$page_objects_file" 2>/dev/null; then
            page_objects_ok=0
        fi

        # A rectangle can be valid yet float over blank paper, producing an invisible hotspot.
        # Independently extract text geometry for every physical page and require positive-area
        # overlap between each Link rectangle and at least one visible text line.
        all_link_text_file=$(mktemp /tmp/cna-bible-all-link-text.XXXXXX.json)
        all_link_text_result_file=$(mktemp /tmp/cna-bible-all-link-text-result.XXXXXX.txt)
        if [ "$page_objects_ok" -eq 1 ] \
           && mutool draw -q -F stext.json -o "$all_link_text_file" "$pdf" 1-709 \
            >/dev/null 2>&1; then
            perl -MJSON::PP -e '
                my ($objects, $pages, $text_file) = @ARGV;
                open P, "<", $pages or die $!;
                while (<P>) { $page_object{$1} = $2 if /page (\d+) = (\d+) 0 R/; }
                close P;
                open O, "<", $objects or die $!;
                while (<O>) { $object{$1} = $2 if /^(\d+) 0 obj (.*)$/; }
                close O;
                open J, "<", $text_file or die $!;
                { local $/; $json = decode_json(<J>); }
                close J;
                for ($i = 0; $i < @{$json->{pages}}; $i++) {
                    $physical = $i + 1;
                    for $block (@{$json->{pages}[$i]{blocks} // []}) {
                        for $line (@{$block->{lines} // []}) {
                            $box = $line->{bbox};
                            push @{$text{$physical}}, [
                                $box->{x}, $box->{y},
                                $box->{x} + $box->{w}, $box->{y} + $box->{h},
                                ($line->{text} // "")
                            ];
                        }
                    }
                }
                for $physical (1 .. 709) {
                    $page = $object{$page_object{$physical}} // "";
                    ($annotations) = $page =~ m{/Annots\[(.*?)\]};
                    while (($annotations // "") =~ /(\d+) 0 R/g) {
                        $object_number = $1;
                        $annotation = $object{$object_number} // "";
                        next unless $annotation =~ m{/Subtype/Link};
                        next unless $annotation
                            =~ m{/Rect\[([-.0-9]+) ([-.0-9]+) ([-.0-9]+) ([-.0-9]+)\]};
                        ($x0, $y0, $x1, $y1) = ($1, $2, $3, $4);
                        ($top0, $top1) = (841.89 - $y1, 841.89 - $y0);
                        $covered = 0;
                        for $line (@{$text{$physical} // []}) {
                            $intersection_x0 = $line->[0] > $x0 ? $line->[0] : $x0;
                            $intersection_y0 = $line->[1] > $top0 ? $line->[1] : $top0;
                            $intersection_x1 = $line->[2] < $x1 ? $line->[2] : $x1;
                            $intersection_y1 = $line->[3] < $top1 ? $line->[3] : $top1;
                            if ($intersection_x1 > $intersection_x0
                                && $intersection_y1 > $intersection_y0) {
                                $covered = 1;
                                last;
                            }
                        }
                        $checked++;
                        unless ($covered) {
                            $bad++;
                            print "page=$physical object=$object_number rectangle=$x0,$top0,$x1,$top1\n";
                        }
                        if ($annotation =~ m{/S/URI/URI\((https://[^()]*)\)}) {
                            $uri = $1;
                            @visible = ();
                            for $line (@{$text{$physical} // []}) {
                                $center_x = ($line->[0] + $line->[2]) / 2;
                                $center_y = ($line->[1] + $line->[3]) / 2;
                                push @visible, $line->[4]
                                    if $center_x >= $x0 - 1 && $center_x <= $x1 + 1
                                    && $center_y >= $top0 - 1 && $center_y <= $top1 + 1;
                            }
                            $printed = join("", @visible);
                            $printed =~ s/^\s+|\s+$//g;
                            # MuPDF exposes the sentence-final full stop as a separate tiny line
                            # whose centre still touches the SDL_Init annotation by <1 pt.
                            $printed =~ s/[.,;:]$//;
                            $uri_checked++;
                            if ($printed ne $uri) {
                                $uri_bad++;
                                print "uri-page=$physical target=$uri printed=$printed\n";
                            }
                        }
                    }
                }
                print "SUMMARY " . ($checked + 0) . " " . ($bad + 0) . " "
                    . ($uri_checked + 0) . " " . ($uri_bad + 0) . "\n";
            ' "$objects_file" "$page_objects_file" "$all_link_text_file" \
                > "$all_link_text_result_file"
            read -r _ visible_link_count empty_link_count visible_uri_count wrong_uri_text_count <<EOF
$(tail -1 "$all_link_text_result_file")
EOF
            if [ "$visible_link_count" -eq "$link_count" ] && [ "$empty_link_count" -eq 0 ] \
               && [ "$visible_uri_count" -eq 3 ] && [ "$wrong_uri_text_count" -eq 0 ]; then
                pass "all $visible_link_count links overlap text; all 3 URI targets equal their printed URLs"
            else
                fail "PDF link/text audit failed ($empty_link_count empty of $visible_link_count links, $wrong_uri_text_count wrong of $visible_uri_count URIs)"
                grep -v '^SUMMARY ' "$all_link_text_result_file" | head -10 | sed 's/^/        /'
            fi
        else
            fail "MuPDF could not extract all 709 pages for link/text-overlap verification"
        fi
        rm -f "$all_link_text_file" "$all_link_text_result_file"

        # Existence is not enough: a TOC destination can be valid yet land on the wrong page.
        # Resolve each numbered TOC target through the name tree and destination object to its
        # physical page. Main matter starts after 30 front-matter pages, so printed N must land on
        # physical N+30. Appendices and the index continue that same arabic sequence.
        if mutool show "$pdf" pages > "$page_objects_file" 2>/dev/null; then
            # The visible TOC occupies physical pages 5--29; page 30 is its intentional blank
            # verso. A valid destination elsewhere in the PDF does not prove the printed TOC row
            # is clickable, so collect every Link target on those pages and require the exact
            # 1,066-entry visible TOC set. Long rows may legitimately use two rectangles.
            toc_link_result_file=$(mktemp /tmp/cna-bible-toc-links.XXXXXX.txt)
            toc_pdf_order_file=$(mktemp /tmp/cna-bible-toc-pdf-order.XXXXXX.txt)
            toc_source_order_file=$(mktemp /tmp/cna-bible-toc-source-order.XXXXXX.txt)
            perl -e '
                my ($objects, $pages, $toc) = @ARGV;
                open P, "<", $pages or die $!;
                while (<P>) { $page_object{$1} = $2 if /page (\d+) = (\d+) 0 R/; }
                close P;
                open O, "<", $objects or die $!;
                while (<O>) { $object{$1} = $2 if /^(\d+) 0 obj (.*)$/; }
                close O;
                open T, "<", $toc or die $!;
                while (<T>) {
                    $expected{$1} = 1
                        if /\\contentsline \{(?:part|chapter|section|subsection)\}.*\{([^{}]+)\}%$/;
                }
                close T;
                for $physical (5 .. 29) {
                    $page = $object{$page_object{$physical}} // "";
                    ($annotations) = $page =~ m{/Annots\[(.*?)\]};
                    while (($annotations // "") =~ /(\d+) 0 R/g) {
                        $annotation = $object{$1} // "";
                        next unless $annotation =~ m{/Subtype/Link};
                        next unless $annotation =~ m{/D\(([^()]*)\)};
                        $actual{$1}++;
                        push @order, $1 unless $seen_order{$1}++;
                        $links++;
                    }
                }
                for $destination (sort keys %expected) {
                    print "missing $destination\n" unless exists $actual{$destination};
                }
                for $destination (sort keys %actual) {
                    print "unexpected $destination\n" unless exists $expected{$destination};
                }
                $differences = 0;
                for $destination (keys %expected) { $differences++ unless exists $actual{$destination}; }
                for $destination (keys %actual) { $differences++ unless exists $expected{$destination}; }
                print "SUMMARY " . ($links + 0) . " " . scalar(keys %actual) . " "
                    . scalar(keys %expected) . " " . $differences . "\n";
                open Q, ">", $ARGV[3] or die $!;
                print Q "$_\n" for grep { exists $expected{$_} } @order;
                close Q;
            ' "$objects_file" "$page_objects_file" "$book_dir/main.toc" "$toc_pdf_order_file" \
                > "$toc_link_result_file"
            perl -ne '
                print "$1\n"
                    if /\\contentsline \{(?:part|chapter|section|subsection)\}.*\{([^{}]+)\}%$/;
            ' "$book_dir/main.toc" > "$toc_source_order_file"
            read -r _ toc_link_count toc_link_target_count toc_expected_target_count bad_toc_link_count <<EOF
$(tail -1 "$toc_link_result_file")
EOF
            if [ "$toc_link_count" -eq 1129 ] && [ "$toc_link_target_count" -eq 1066 ] \
               && [ "$toc_expected_target_count" -eq 1066 ] \
               && [ "$bad_toc_link_count" -eq 0 ]; then
                pass "all 1066 visible TOC entries are covered by 1129 link rectangles"
            else
                fail "TOC clickable-coverage audit failed ($toc_link_count links, $toc_link_target_count actual targets, $toc_expected_target_count expected targets, $bad_toc_link_count differing)"
                grep -v '^SUMMARY ' "$toc_link_result_file" | head -10 | sed 's/^/        /'
            fi
            toc_pdf_order_count=$(line_count "$toc_pdf_order_file") || toc_pdf_order_count=0
            if [ "$toc_pdf_order_count" -eq 1066 ] \
               && cmp -s "$toc_pdf_order_file" "$toc_source_order_file"; then
                pass "all 1066 visible TOC destinations preserve source order"
            else
                fail "visible TOC destination order differs from main.toc"
                diff -u "$toc_source_order_file" "$toc_pdf_order_file" | head -20 \
                    | sed 's/^/        /'
            fi
            rm -f "$toc_link_result_file" "$toc_pdf_order_file" "$toc_source_order_file"

            # Coverage alone would miss two TOC annotations whose valid destinations were
            # swapped. Independently extract visible text under every rectangle and require the
            # destination's own printed structural token: roman Part number, chapter/section
            # number, appendix letter, or the two unnumbered labels Preface and Index.
            toc_text_file=$(mktemp /tmp/cna-bible-toc-text.XXXXXX.json)
            toc_identity_result_file=$(mktemp /tmp/cna-bible-toc-identities.XXXXXX.txt)
            if mutool draw -q -F stext.json -o "$toc_text_file" "$pdf" 5-29 \
                >/dev/null 2>&1; then
                perl -MJSON::PP -e '
                    my ($objects, $pages, $text_file, $toc) = @ARGV;
                    open P, "<", $pages or die $!;
                    while (<P>) { $page_object{$1} = $2 if /page (\d+) = (\d+) 0 R/; }
                    close P;
                    open O, "<", $objects or die $!;
                    while (<O>) { $object{$1} = $2 if /^(\d+) 0 obj (.*)$/; }
                    close O;
                    open J, "<", $text_file or die $!;
                    { local $/; $json = decode_json(<J>); }
                    close J;
                    open T, "<", $toc or die $!;
                    while (<T>) {
                        if (/\\contentsline \{(?:part|chapter|section|subsection)\}\{\\numberline\s*\{[^}]+\}([0-9]).*\}\{[^{}]+\}\{([^{}]+)\}%$/) {
                            ($first_character, $destination) = ($1, $2);
                            $numeric_title_start{$destination} = $first_character;
                        }
                    }
                    close T;
                    for ($i = 0; $i < @{$json->{pages}}; $i++) {
                        $physical = 5 + $i;
                        for $block (@{$json->{pages}[$i]{blocks} // []}) {
                            for $line (@{$block->{lines} // []}) {
                                $box = $line->{bbox};
                                push @{$text{$physical}}, [
                                    $line->{text} // "", $box->{x}, $box->{y},
                                    $box->{x} + $box->{w}, $box->{y} + $box->{h}
                                ];
                            }
                        }
                    }
                    for $physical (5 .. 29) {
                        $page = $object{$page_object{$physical}} // "";
                        ($annotations) = $page =~ m{/Annots\[(.*?)\]};
                        while (($annotations // "") =~ /(\d+) 0 R/g) {
                            $annotation = $object{$1} // "";
                            next unless $annotation =~ m{/Subtype/Link};
                            next unless $annotation =~ m{/D\(([^()]*)\)};
                            $destination = $1;
                            next unless $annotation
                                =~ m{/Rect\[([-.0-9]+) ([-.0-9]+) ([-.0-9]+) ([-.0-9]+)\]};
                            ($x0, $y0, $x1, $y1) = ($1, $2, $3, $4);
                            ($top0, $top1) = (841.89 - $y1, 841.89 - $y0);
                            @matching = grep {
                                $cx = ($_->[1] + $_->[3]) / 2;
                                $cy = ($_->[2] + $_->[4]) / 2;
                                $cx >= $x0 - 1 && $cx <= $x1 + 1
                                    && $cy >= $top0 - 1 && $cy <= $top1 + 1;
                            } @{$text{$physical} // []};
                            push @{$fragments{$destination}}, map { $_->[0] } @matching;
                        }
                    }
                    @roman = qw(0 I II III IV V VI VII VIII IX X XI XII);
                    for $destination (sort keys %fragments) {
                        $visible = join(" ", @{$fragments{$destination}});
                        if ($destination eq "chapter*.1") {
                            $expected = "Preface";
                            $ok = $visible =~ /\Q$expected\E/;
                        } elsif ($destination eq "section*.30") {
                            $expected = "Index";
                            $ok = $visible =~ /\Q$expected\E/;
                        } elsif ($destination =~ /^part\.(\d+)$/) {
                            $expected = $roman[$1] // "";
                            $quoted = quotemeta($expected);
                            $ok = length($expected) > 0
                                && $visible =~ /(?<![A-Za-z])$quoted(?![A-Za-z])/;
                        } elsif ($destination =~ /^appendix\.([A-H])$/) {
                            $expected = $1;
                            $quoted = quotemeta($expected);
                            $ok = $visible =~ /(?<![A-Za-z])$quoted(?![A-Za-z])/;
                        } elsif ($destination =~ /^(?:chapter|section|subsection)\.(.+)$/) {
                            $expected = $1;
                            $quoted = quotemeta($expected);
                            if (exists $numeric_title_start{$destination}) {
                                $following = quotemeta($numeric_title_start{$destination});
                                $ok = $visible
                                    =~ /(?<![0-9.])$quoted(?:(?=$following)|(?=[^0-9.]))/;
                            } else {
                                $ok = $visible =~ /(?<![0-9.])$quoted(?![0-9.])/;
                            }
                        } else {
                            $expected = "";
                            $ok = 0;
                        }
                        $checked++;
                        unless ($ok) {
                            $bad++;
                            print "destination=$destination expected=$expected text=$visible\n";
                        }
                    }
                    print "SUMMARY " . ($checked + 0) . " " . ($bad + 0) . "\n";
                ' "$objects_file" "$page_objects_file" "$toc_text_file" "$book_dir/main.toc" \
                    > "$toc_identity_result_file"
                read -r _ toc_identity_count bad_toc_identity_count <<EOF
$(tail -1 "$toc_identity_result_file")
EOF
                if [ "$toc_identity_count" -eq 1066 ] && [ "$bad_toc_identity_count" -eq 0 ]; then
                    pass "all 1066 TOC links cover their own printed structural identities"
                else
                    fail "TOC link/text identity audit failed ($bad_toc_identity_count wrong of $toc_identity_count targets)"
                    grep -v '^SUMMARY ' "$toc_identity_result_file" | head -10 | sed 's/^/        /'
                fi
            else
                fail "MuPDF could not extract the 25 TOC pages for link/text verification"
            fi
            rm -f "$toc_text_file" "$toc_identity_result_file"

            perl -e '
                my ($objects, $pages, $toc) = @ARGV;
                open P, "<", $pages or die $!;
                while (<P>) { $page{$2} = $1 if /page (\d+) = (\d+) 0 R/; }
                close P;
                open O, "<", $objects or die $!;
                while (<O>) {
                    $dest_page{$1} = $page{$2}
                        if /^(\d+) 0 obj .*\/D\[(\d+) 0 R\/XYZ/;
                    if (/\/Names\[/) {
                        while (/\(([^()]*)\)(\d+) 0 R/g) { $name_obj{$1} = $2; }
                    }
                }
                close O;
                open T, "<", $toc or die $!;
                while (<T>) {
                    next unless /\\contentsline \{(?:part|chapter|section|subsection)\}.*\{([^{}]+)\}\{([^{}]+)\}%$/;
                    ($printed, $name) = ($1, $2);
                    next if $printed !~ /^\d+$/;
                    $expected = $printed + 30;
                    $actual = $dest_page{$name_obj{$name}};
                    $checked++;
                    if (!defined $actual || $actual != $expected) {
                        $bad++;
                        print "printed=$printed expected=$expected actual="
                              . (defined($actual) ? $actual : "?") . " destination=$name\n";
                    }
                }
                print "SUMMARY " . ($checked + 0) . " " . ($bad + 0) . "\n";
            ' "$objects_file" "$page_objects_file" "$book_dir/main.toc" \
                > "$toc_target_result_file"
            read -r _ toc_target_count bad_toc_target_count <<EOF
$(tail -1 "$toc_target_result_file")
EOF
            if [ "$toc_target_count" -eq 1065 ] && [ "$bad_toc_target_count" -eq 0 ]; then
                pass "all 1065 numbered TOC entries land on their printed pages"
            else
                fail "TOC destination audit failed ($bad_toc_target_count wrong of $toc_target_count numbered entries)"
                grep -v '^SUMMARY ' "$toc_target_result_file" | head -10 | sed 's/^/        /'
            fi

            # Hyperlinked index numbers need a stronger check than target existence. Match every
            # Link rectangle on physical index pages 703--709 to MuPDF's independently extracted
            # numeric text fragment, then resolve its named destination to a physical page. This
            # handles compact ranges such as 154--156, whose two endpoints are separate links.
            index_text_file=$(mktemp /tmp/cna-bible-index-text.XXXXXX.json)
            index_target_result_file=$(mktemp /tmp/cna-bible-index-targets.XXXXXX.txt)
            if mutool draw -q -F stext.json -o "$index_text_file" "$pdf" 703-709 \
                >/dev/null 2>&1; then
                perl -MJSON::PP -e '
                    my ($objects, $pages, $text_file) = @ARGV;
                    open P, "<", $pages or die $!;
                    while (<P>) {
                        if (/page (\d+) = (\d+) 0 R/) {
                            $physical_for_page_object{$2} = $1;
                            $page_object_for_physical{$1} = $2;
                        }
                    }
                    close P;
                    open O, "<", $objects or die $!;
                    while (<O>) {
                        next unless /^(\d+) 0 obj (.*)$/;
                        ($number, $body) = ($1, $2);
                        $object{$number} = $body;
                        $destination_page{$number} = $physical_for_page_object{$1}
                            if $body =~ m{/D\[(\d+) 0 R/XYZ};
                        if ($body =~ m{/Names\[}) {
                            while ($body =~ /\(([^()]*)\)(\d+) 0 R/g) {
                                $name_object{$1} = $2;
                            }
                        }
                    }
                    close O;
                    open J, "<", $text_file or die $!;
                    local $/;
                    $json = decode_json(<J>);
                    close J;
                    for ($i = 0; $i < @{$json->{pages}}; $i++) {
                        $source_page = 703 + $i;
                        for $block (@{$json->{pages}[$i]{blocks} // []}) {
                            for $line (@{$block->{lines} // []}) {
                                $printed = $line->{text} // "";
                                $printed =~ s/^\s+|\s+$//g;
                                next unless $printed =~ /^\d+$/;
                                $box = $line->{bbox};
                                push @{$numbers{$source_page}}, [
                                    $printed + 0, $box->{x}, $box->{y},
                                    $box->{x} + $box->{w}, $box->{y} + $box->{h}
                                ];
                            }
                        }
                    }
                    for $source_page (703 .. 709) {
                        $page_body = $object{$page_object_for_physical{$source_page}} // "";
                        ($annotations) = $page_body =~ m{/Annots\[(.*?)\]};
                        while (($annotations // "") =~ /(\d+) 0 R/g) {
                            $annotation = $object{$1} // "";
                            next unless $annotation =~ m{/Subtype/Link};
                            next unless $annotation =~ m{/D\(page\.(\d+)\)};
                            $target_printed = $1 + 0;
                            if ($annotation !~ m{/Rect\[([-.0-9]+) ([-.0-9]+) ([-.0-9]+) ([-.0-9]+)\]}) {
                                $bad++; print "source=$source_page target=$target_printed missing-rectangle\n";
                                next;
                            }
                            ($x0, $y0, $x1, $y1) = ($1, $2, $3, $4);
                            ($top0, $top1) = (841.89 - $y1, 841.89 - $y0);
                            @matching = grep {
                                $cx = ($_->[1] + $_->[3]) / 2;
                                $cy = ($_->[2] + $_->[4]) / 2;
                                $cx >= $x0 - 1 && $cx <= $x1 + 1
                                    && $cy >= $top0 - 1 && $cy <= $top1 + 1;
                            } @{$numbers{$source_page} // []};
                            $checked++;
                            $actual_page = $destination_page{$name_object{"page.$target_printed"}};
                            $expected_page = $target_printed + 30;
                            if (@matching != 1 || $matching[0][0] != $target_printed
                                || !defined($actual_page) || $actual_page != $expected_page) {
                                $bad++;
                                $seen = join(",", map { $_->[0] } @matching);
                                $seen = "?" if $seen eq "";
                                print "source=$source_page printed=$seen target=$target_printed "
                                    . "expected=$expected_page actual="
                                    . (defined($actual_page) ? $actual_page : "?") . "\n";
                            }
                        }
                    }
                    print "SUMMARY " . ($checked + 0) . " " . ($bad + 0) . "\n";
                ' "$objects_file" "$page_objects_file" "$index_text_file" \
                    > "$index_target_result_file"
                read -r _ index_target_count bad_index_target_count <<EOF
$(tail -1 "$index_target_result_file")
EOF
                if [ "$index_target_count" -eq 1850 ] && [ "$bad_index_target_count" -eq 0 ]; then
                    pass "all $index_target_count clickable index numbers match their printed and physical pages"
                else
                    fail "index destination audit failed ($bad_index_target_count wrong of $index_target_count links)"
                    grep -v '^SUMMARY ' "$index_target_result_file" | head -10 | sed 's/^/        /'
                fi
            else
                fail "MuPDF could not extract the seven index pages for link verification"
            fi
            rm -f "$index_text_file" "$index_target_result_file"
        else
            fail "mutool could not map PDF page objects"
        fi
        rm -f "$page_objects_file" "$toc_target_result_file"
    else
        fail "mutool could not inspect internal PDF links"
    fi
    rm -f "$objects_file" "$link_dests_file" "$named_dests_file" "$missing_dests_file"
else
    fail "mutool unavailable; PDF navigation checks cannot run"
fi

# A parser can sometimes read a damaged cross-reference or stream leniently without proving that
# it can serialize the complete object graph again. Rewrite to a disposable PDF with MuPDF, then
# require Poppler's layout text to remain byte-identical and Ghostscript to interpret every page.
roundtrip_pdf=$(mktemp /tmp/cna-bible-roundtrip.XXXXXX.pdf)
roundtrip_text=$(mktemp /tmp/cna-bible-roundtrip-text.XXXXXX.txt)
source_roundtrip_text=$(mktemp /tmp/cna-bible-source-text.XXXXXX.txt)
if mutool clean "$pdf" "$roundtrip_pdf" >/dev/null 2>&1 \
   && [ "$(pdfinfo "$roundtrip_pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')" = "709" ] \
   && pdftotext -layout "$pdf" "$source_roundtrip_text" 2>/dev/null \
   && pdftotext -layout "$roundtrip_pdf" "$roundtrip_text" 2>/dev/null \
   && cmp -s "$source_roundtrip_text" "$roundtrip_text" \
   && gs -q -dNOPAUSE -dBATCH -sDEVICE=nullpage -o /dev/null "$roundtrip_pdf"; then
    pass "MuPDF rewrite preserves all 709 pages and byte-identical layout text; Ghostscript parses it"
else
    fail "PDF parse/rewrite round trip changed text/pages or failed independent interpretation"
fi
rm -f "$roundtrip_pdf" "$roundtrip_text" "$source_roundtrip_text"

# Use an independent interpreter as a final syntax/renderability check when available. This does
# not replace the visual pass; it catches corrupt objects and page programs that Poppler or MuPDF
# may tolerate differently.
if command -v gs >/dev/null 2>&1; then
    ink_file=$(mktemp /tmp/cna-bible-ink.XXXXXX.txt)
    if gs -q -dNOPAUSE -dBATCH -sDEVICE=inkcov -o "$ink_file" "$pdf"; then
        blank_page_scan_ok=1
        blank_pages=$(awk '$1 == 0 && $2 == 0 && $3 == 0 && $4 == 0 {print NR}' "$ink_file" \
            | paste -sd, -) || blank_page_scan_ok=0
        expected_blank_pages=$(perl -ne '
            if (/\\contentsline \{part\}.*\{(\d+)\}\{part\.\d+\}%$/) {
                push @pages, $1 + 31;
            }
            END { print join(",", @pages); }
        ' "$book_dir/main.toc") || blank_page_scan_ok=0
        if [ "$blank_page_scan_ok" -eq 1 ] && [ "$blank_pages" = "$expected_blank_pages" ]; then
            pass "Ghostscript processed all pages; exactly the 12 Part-derived open-right versos are blank"
        else
            fail "unexpected blank-page set from Ghostscript ink coverage (actual='${blank_pages:-none}', expected='${expected_blank_pages:-none}')"
        fi
    else
        fail "Ghostscript could not process the complete PDF"
    fi
    rm -f "$ink_file"
else
    fail "Ghostscript unavailable; independent PDF interpreter check cannot run"
fi

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
