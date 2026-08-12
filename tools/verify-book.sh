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

# A partial artifact audit can look deceptively green when an optional-looking PDF tool is
# absent. Release verification therefore requires every independent parser used below and fails
# early with one actionable diagnostic instead of silently reducing coverage.
missing_commands=""
for required_command in make git perl pdfinfo pdftotext pdffonts mutool gs; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        missing_commands="$missing_commands $required_command"
    fi
done
if [ -n "$missing_commands" ]; then
    fail "missing required verification command(s):${missing_commands}"
    exit 1
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

if grep -q "Package fancyhdr Warning: \\headheight is too small" "$log"; then
    fail "running head exceeds the reserved header height"
    grep -n -A3 "Package fancyhdr Warning: \\headheight is too small" "$log" \
        | head -20 | sed 's/^/        /'
else
    pass "running heads fit the reserved header height"
fi

overfull=$(grep -Fc 'Overfull \hbox' "$log" 2>/dev/null || true)
info "$overfull internal overfull hbox warning(s); physical PDF bounds are checked below"

# ---------------------------------------------------------------- index
echo "-- index"
ilg="$book_dir/main.ilg"
if [ -f "$ilg" ]; then
    entries=$(sed -n 's/.*(\([0-9]*\) entries accepted.*/\1/p' "$ilg" | tail -1)
    rejected=$(sed -n 's/.*entries accepted, \([0-9]*\) rejected.*/\1/p' "$ilg" | tail -1)
    warns=$(sed -n 's/.*lines written, \([0-9]*\) warnings.*/\1/p' "$ilg" | tail -1)
    info "makeindex accepted ${entries:-?} entries, ${rejected:-?} rejected, ${warns:-?} warnings"
    if [ "${rejected:-1}" != "0" ] || [ "${warns:-1}" != "0" ]; then
        fail "makeindex reported rejected entries or warnings"
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

dupes=$(grep -ho '\\label{[^}]*}' "$book_dir/main.tex" 2>/dev/null;
        grep -rho '\\label{[^}]*}' "$chapters" "$front" 2>/dev/null)
dupes=$(printf '%s\n' "$dupes" | sort | uniq -d)
if [ -n "$dupes" ]; then
    fail "duplicate \\label definitions in source:"
    echo "$dupes" | sed 's/^/        /'
else
    pass "no duplicate \\label definitions in source"
fi

# Every source \ref must have a matching label, including part, chapter, section and appendix
# aliases. LaTeX also diagnoses this after enough passes; the source check makes the invariant
# explicit and catches it without interpreting log wording.
missing=""
refs=$(
    {
        grep -ho '\\ref{[^}]*}' "$book_dir/main.tex" 2>/dev/null
        grep -rho '\\ref{[^}]*}' "$chapters" "$front" 2>/dev/null
    } | sed 's/\\ref{//;s/}//' | sort -u
)
for r in $refs; do
    if ! grep -q "\\\\label{$r}" "$book_dir/main.tex" 2>/dev/null \
       && ! grep -rq "\\\\label{$r}" "$chapters" "$front" 2>/dev/null; then
        missing="$missing $r"
    fi
done
if [ -n "$missing" ]; then
    fail "\\ref to nonexistent labels:$missing"
else
    pass "every source \\ref resolves to a \\label"
fi

# A syntactically valid chapter file can be forgotten during a restructure and never reach TeX;
# conversely, a case-mismatched input may work on one filesystem and fail on another. Require
# every chapter, appendix, and renderer fragment on disk to occur exactly once in the input graph.
input_targets_file=$(mktemp /tmp/cna-bible-input-targets.XXXXXX.txt)
chapter_sources_file=$(mktemp /tmp/cna-bible-chapter-sources.XXXXXX.txt)
orphan_sources_file=$(mktemp /tmp/cna-bible-orphan-sources.XXXXXX.txt)
duplicate_inputs_file=$(mktemp /tmp/cna-bible-duplicate-inputs.XXXXXX.txt)
missing_inputs_file=$(mktemp /tmp/cna-bible-missing-inputs.XXXXXX.txt)
{
    grep -ho '\\input{[^}]*}' "$book_dir/main.tex" 2>/dev/null
    grep -rho '\\input{[^}]*}' "$chapters" "$front" 2>/dev/null
} | sed 's/^\\input{//;s/}$//' | grep '^chapters/' | sort > "$input_targets_file"
find "$chapters" -type f -name '*.tex' -printf '%P\n' | sed 's|^|chapters/|' | sort \
    > "$chapter_sources_file"
comm -23 "$chapter_sources_file" "$input_targets_file" > "$orphan_sources_file"
uniq -d "$input_targets_file" > "$duplicate_inputs_file"
while IFS= read -r input_target; do
    [ -f "$book_dir/$input_target" ] || printf '%s\n' "$input_target"
done < "$input_targets_file" > "$missing_inputs_file"
chapter_source_count=$(wc -l < "$chapter_sources_file")
compiled_source_count=$(wc -l < "$input_targets_file")
orphan_source_count=$(wc -l < "$orphan_sources_file")
duplicate_input_count=$(wc -l < "$duplicate_inputs_file")
missing_input_count=$(wc -l < "$missing_inputs_file")
if [ "$chapter_source_count" -eq 89 ] && [ "$compiled_source_count" -eq 89 ] \
   && [ "$orphan_source_count" -eq 0 ] && [ "$duplicate_input_count" -eq 0 ] \
   && [ "$missing_input_count" -eq 0 ]; then
    pass "all 89 chapter, appendix, and fragment sources are compiled exactly once"
else
    fail "compiled-source closure failed ($chapter_source_count files, $compiled_source_count inputs, $orphan_source_count orphaned, $duplicate_input_count duplicated, $missing_input_count missing)"
    sed 's/^/        orphaned: /' "$orphan_sources_file" | head -10
    sed 's/^/        duplicated: /' "$duplicate_inputs_file" | head -10
    sed 's/^/        missing: /' "$missing_inputs_file" | head -10
fi
rm -f "$input_targets_file" "$chapter_sources_file" "$orphan_sources_file" \
    "$duplicate_inputs_file" "$missing_inputs_file"

# ---------------------------------------------------------------- stale facts
echo "-- stale-fact sweep"

# Hard-coded chapter/part/appendix/section references appeared with both TeX ties and ordinary
# spaces, including inside listings. All break silently on a restructure and none produces a
# LaTeX warning.
structure_re='Chapters?(~|[[:space:]])+[0-9]+|Ch\.(~|[[:space:]])*[0-9]+|Parts?(~|[[:space:]])+(I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)\>|Appendix(es)?(~|[[:space:]])+[A-H]\>|Sections?(~|[[:space:]])+[0-9]+([.][0-9]+)*'
hard=$(grep -rnoE "$structure_re" "$chapters" "$front" 2>/dev/null | wc -l)
if [ "$hard" -gt 0 ]; then
    fail "hard-coded structural references: $hard (use a stable \\ref unless genuinely historical)"
    grep -rnE "$structure_re" "$chapters" "$front" 2>/dev/null | head -10 | sed 's/^/        /'
else
    pass "no hard-coded chapter/part/appendix/section references"
fi

# A \ref written with a doubled backslash silently degrades to a line break plus
# literal text. It produces no warning and no undefined reference -- it is only
# visible by rendering the page. Caught for real on 2026-08-11 in Appendix E.
if grep -rq '\\\\ref{' "$chapters" "$front" 2>/dev/null; then
    fail "doubled-backslash \\\\ref{...} -- renders as a line break plus literal text"
    grep -rn '\\\\ref{' "$chapters" "$front" | head -10 | sed 's/^/        /'
else
    pass "no doubled-backslash \\ref"
fi

# \cnaclass and \cnans feed their entire argument to makeindex. Pointer/reference declarators
# therefore create misleading keys such as "Album*" or "Game& game" instead of indexing the
# underlying symbol. Keep declarators outside the semantic macro (e.g. \cnaclass{Album}\texttt{*}).
if grep -rEn '\\(cnaclass|cnans)\{[^}]*(\*|\\&)[^}]*\}' "$chapters" "$front" \
    > /tmp/cna-bible-index-declarators.txt 2>/dev/null; then
    fail "pointer/reference declarators inside semantic index macros"
    head -10 /tmp/cna-bible-index-declarators.txt | sed 's/^/        /'
else
    pass "no pointer/reference declarators inside semantic index macros"
fi

# These spellings previously split one API symbol across multiple top-level index keys. Preserve
# intentional conceptual pairs such as XNB/.xnb and free-direct/FREEDIRECT, but reject the known
# C++ symbol aliases caused by optional call parentheses, omitted owners, or C# namespace dots.
index_alias_re='\\cnaclass\{ContentManager::Load<(Song|T)>\(\)\}|\\cnaclass\{Load<Song>\(\)\}|\\cnaclass\{System\.(GC|Type)\}|\\cnaclass\{SystemException\}'
if grep -rEn "$index_alias_re" "$chapters" "$front" > /tmp/cna-bible-index-aliases.txt 2>/dev/null; then
    fail "noncanonical aliases split API symbols across index keys"
    head -10 /tmp/cna-bible-index-aliases.txt | sed 's/^/        /'
else
    pass "no known noncanonical API aliases in semantic index macros"
fi

# These source identifiers and build options were removed by CNA's renderer/CNAEXT
# naming migration. Unlike ordinary prose uses of "backend", none is contextually valid in
# the current manuscript. Historical discussion should spell out the old name without using
# it as a live identifier, or live in the audit/plan evidence outside the compiled book.
obsolete_re='IGraphicsBackend|ITextureBackend|ITexture3DBackend|ISpriteBatchBackend|IEffectBackend|ITextureCubeBackend|IRenderTargetBackend|IRenderTargetCubeBackend|IIndexBufferBackend|IVertexBufferBackend|IOcclusionQueryBackend|GraphicsBackendType|GetGraphicsBackendType|GetGraphicsBackendName|GraphicsBackendCreateArgs|CreateGraphicsBackend|D3D11RenderTargetBackend|CNA_GRAPHICS_BACKEND|CNA\\_GRAPHICS\\_BACKEND|CNA_BACKEND_|CNA\\_BACKEND\\_|CNA_RENDERER_(D3D9|D3D11|D3D12|DX3|EASYGL|ASCII)|CNA\\_RENDERER\\_(D3D9|D3D11|D3D12|DX3|EASYGL|ASCII)|NOXNA|BackendSelection\.cmake|BackendLibraries\.cmake|customEffectBackend|GraphicsRendererType::Ascii|dx3\\_(texture\\_rendertarget|no3d)\\_test\.cpp'
if grep -rEn "$obsolete_re" "$chapters" "$front" > /tmp/cna-bible-obsolete-identifiers.txt 2>/dev/null; then
    n=$(wc -l < /tmp/cna-bible-obsolete-identifiers.txt)
    fail "obsolete CNA identifiers/options in compiled manuscript: $n"
    head -10 /tmp/cna-bible-obsolete-identifiers.txt | sed 's/^/        /'
else
    pass "no obsolete CNA identifiers/options in compiled manuscript"
fi

if grep -rEn '106 headers under' "$chapters" "$front" \
    > /tmp/cna-bible-stale-graphics-header-count.txt 2>/dev/null; then
    fail "stale 106-header Graphics subtree count in compiled manuscript"
else
    pass "Graphics include count distinguishes 107 direct and 18 PackedVector headers"
fi

if grep -rEn 'production translation units' "$chapters" "$front" \
    > /tmp/cna-bible-stale-production-unit-label.txt 2>/dev/null; then
    fail "production-file inventory mislabeled as translation units"
else
    pass "physical-module inventory is labeled as production files"
fi

if grep -rEn 'Only 56 of 1\\{,\\}195|contain 159 directives|There are 109[[:space:]]*$' \
    "$chapters" "$front" > /tmp/cna-bible-stale-platform-counts.txt 2>/dev/null; then
    fail "stale platform-directive inventory in compiled manuscript"
else
    pass "platform inventory defines its 1195-file and 152-directive populations"
fi

if grep -rEn 'CNA(_|\\_)GRAPHICS(_|\\_)RENDERER=(EASYGL|DX3|D3D9|D3D11|D3D12|ASCII)' "$chapters" "$front" > /tmp/cna-bible-obsolete-selectors.txt 2>/dev/null; then
    n=$(wc -l < /tmp/cna-bible-obsolete-selectors.txt)
    fail "removed renderer selector in a live CMake assignment: $n"
    head -10 /tmp/cna-bible-obsolete-selectors.txt | sed 's/^/        /'
else
    pass "no removed renderer selectors in live CMake assignments"
fi

# Phase 70 contains 65 technical tasks (666--730); Task 731 is its closing documentation task.
# The old wording paired the inclusive 666--731 range with a 65-task total, an off-by-one claim.
if grep -rEn 'Tasks(~|[[:space:]])+666--731,? 65 tasks' "$chapters" "$front" \
    > /tmp/cna-bible-phase70-count.txt 2>/dev/null; then
    fail "Phase 70 task range is paired with the obsolete off-by-one total"
    head -10 /tmp/cna-bible-phase70-count.txt | sed 's/^/        /'
else
    pass "Phase 70 separates 65 technical tasks from its closing documentation task"
fi

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
    done > "$repeated_words_file"
if [ -s "$repeated_words_file" ]; then
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
if grep -rIn $'\t' "$chapters" "$front" "$book_dir/main.tex" > /tmp/cna-bible-tabs.txt 2>/dev/null; then
    fail "literal tab characters in compiled TeX sources"
    head -10 /tmp/cna-bible-tabs.txt | sed 's/^/        /'
else
    pass "no literal tabs in compiled TeX sources"
fi

if grep -rIl $'\r' "$chapters" "$front" "$book_dir/main.tex" > /tmp/cna-bible-crlf.txt 2>/dev/null; then
    fail "carriage returns in compiled TeX sources"
    head -10 /tmp/cna-bible-crlf.txt | sed 's/^/        /'
else
    pass "no carriage returns in compiled TeX sources"
fi

if git -C "$repo_root" diff --check > /dev/null 2>&1; then
    pass "git diff --check clean"
else
    fail "git diff --check reports whitespace errors"
    git -C "$repo_root" diff --check | head -20
fi

# ---------------------------------------------------------------- PDF output
echo "-- output"
pages=$(pdfinfo "$pdf" 2>/dev/null | awk '/^Pages:/ {print $2}')
info "main.pdf is ${pages:-?} pages"
info "chapter LaTeX: $(find "$chapters" -name '*.tex' | xargs cat 2>/dev/null | wc -l) lines across $(find "$chapters" -name '*.tex' | wc -l) files"

pdf_info=$(pdfinfo "$pdf" 2>/dev/null)
if [ -z "$pdf_info" ]; then
    fail "pdfinfo could not parse main.pdf"
else
    pass "PDF container is readable"
fi

encrypted=$(printf '%s\n' "$pdf_info" | awk -F: '/^Encrypted:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
form=$(printf '%s\n' "$pdf_info" | awk -F: '/^Form:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
javascript=$(printf '%s\n' "$pdf_info" | awk -F: '/^JavaScript:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
title=$(printf '%s\n' "$pdf_info" | awk -F: '/^Title:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
author=$(printf '%s\n' "$pdf_info" | awk -F: '/^Author:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
subject=$(printf '%s\n' "$pdf_info" | awk -F: '/^Subject:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
keywords=$(printf '%s\n' "$pdf_info" | awk -F: '/^Keywords:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
page_boxes=$(pdfinfo -f 1 -l "$pages" -box "$pdf" 2>/dev/null)
a4_pages=$(printf '%s\n' "$page_boxes" \
    | grep -cE '^Page +[0-9]+ size:  +595\.276 x 841\.89 pts \(A4\)$' || true)
unrotated_pages=$(printf '%s\n' "$page_boxes" \
    | grep -cE '^Page +[0-9]+ rot:  +0$' || true)
complete_page_boxes=1
for box_name in MediaBox CropBox BleedBox TrimBox ArtBox; do
    box_count=$(printf '%s\n' "$page_boxes" \
        | grep -cE "^Page +[0-9]+ ${box_name}: +0\.00 +0\.00 +595\.28 +841\.89$" || true)
    [ "$box_count" -eq "$pages" ] || complete_page_boxes=0
done
if [ "$encrypted" = "no" ] && [ "$a4_pages" -eq "$pages" ] \
   && [ "$unrotated_pages" -eq "$pages" ] && [ "$complete_page_boxes" -eq 1 ]; then
    pass "all $pages PDF pages are unencrypted, unrotated A4 with matching page boxes"
else
    fail "unexpected PDF page geometry or encryption ($a4_pages/$pages A4, $unrotated_pages/$pages unrotated, complete boxes=$complete_page_boxes, encrypted='${encrypted:-?}')"
fi
if [ "$form" = "none" ] && [ "$javascript" = "no" ]; then
    pass "PDF contains no forms or JavaScript"
else
    fail "unexpected active PDF content (form='${form:-?}', JavaScript='${javascript:-?}')"
fi
if [ "$title" = "The CNA Bible" ] && [ "$author" = "Robert Vokac" ] \
   && [ "$subject" = "A source-grounded guide to CNA and the Microsoft XNA 4.0 programming model" ] \
   && [ "$keywords" = "CNA, Microsoft XNA, C++23, graphics renderers, game development" ]; then
    pass "PDF title, author, subject, and keywords match the release metadata"
else
    fail "unexpected or incomplete PDF release metadata"
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

# A standalone technical book must not depend on workstation fonts, and its searchable text
# needs ToUnicode maps. Read columns from the right because the font type can contain a space
# (for example, "Type 1").
font_summary=$(
    pdffonts "$pdf" 2>/dev/null | awk '
        NR > 2 && NF >= 8 {
            total++;
            if ($(NF-4) != "yes" || $(NF-3) != "yes" || $(NF-2) != "yes") bad++;
        }
        END { print total + 0, bad + 0; }
    '
)
read -r font_total font_bad <<EOF
$font_summary
EOF
if [ "$font_total" -gt 0 ] && [ "$font_bad" -eq 0 ]; then
    pass "all $font_total fonts are embedded, subsetted, and Unicode-mapped"
else
    fail "font portability check failed ($font_bad of $font_total font rows incomplete)"
fi

# Verify the navigation structure in the produced artifact, not only the source input list.
# Hyperref names ordinary chapters chapter.N and appendices appendix.A, while Parts use part.N.
if command -v mutool >/dev/null 2>&1; then
    page_labels=$(mutool show -g "$pdf" trailer/Root/PageLabels 2>/dev/null || true)
    if printf '%s\n' "$page_labels" \
        | grep -q '/Nums\[0<</S/r>>30<</S/D>>\]'; then
        pass "PDF page labels switch from roman front matter to arabic body at page 31"
    else
        fail "unexpected or missing PDF page-label transition"
    fi

    document_language=$(mutool show -g "$pdf" trailer/Root/Lang 2>/dev/null || true)
    if [ "$document_language" = "(en-US)" ]; then
        pass "PDF catalog declares English (United States) as its document language"
    else
        fail "unexpected or missing PDF document language ('${document_language:-?}')"
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
        grep -o '#nameddest=[^[:space:]]*' "$outline_file" | sed 's/#nameddest=//' \
            | sort > "$outline_dests_file"
        perl -ne '
            print "$2\n"
                if /\\contentsline \{(part|chapter|section|subsection)\}.*\{([^{}]+)\}%$/;
        ' "$book_dir/main.toc" | sort > "$toc_outline_dests_file"
        comm -3 "$outline_dests_file" "$toc_outline_dests_file" > "$outline_toc_diff_file"
        perl -ne '
            if (/"(.*)"\s+#nameddest=([^\s]+)$/) { print "$2\t$1\n"; }
        ' "$outline_file" | LC_ALL=C sort > "$outline_titles_file"
        perl -MEncode=decode -ne '
            BEGIN { binmode STDOUT, ":encoding(UTF-8)"; }
            if (/^\\BOOKMARK \[[^]]*\]\[[^]]*\]\{([^}]*)\}\{(.*)\}\{[^}]*\}%/) {
                ($destination, $title) = ($1, $2);
                $title =~ s/\\([0-7]{3})/chr(oct($1))/ge;
                $title = decode("UTF-16BE", $title);
                $title =~ s/^\x{FEFF}//;
                print "$destination\t$title\n";
            }
        ' "$book_dir/main.out" | LC_ALL=C sort > "$source_bookmarks_file"
        comm -3 "$outline_titles_file" "$source_bookmarks_file" > "$outline_title_diff_file"
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
        ' "$outline_file" | LC_ALL=C sort > "$outline_parents_file"
        perl -ne '
            if (/^\\BOOKMARK \[[^]]*\]\[[^]]*\]\{([^}]*)\}\{.*\}\{([^}]*)\}%/) {
                print "$1\t$2\n";
            }
        ' "$book_dir/main.out" | LC_ALL=C sort > "$source_parents_file"
        comm -3 "$outline_parents_file" "$source_parents_file" > "$outline_parent_diff_file"
        outline_entries=$(grep -c '#nameddest=' "$outline_file" || true)
        outline_destinations=$(grep -o '#nameddest=[^[:space:]]*' "$outline_file" \
            | sort -u | wc -l)
        outline_empty_titles=$(awk -F'"' '$0 ~ /#nameddest=/ && (NF < 3 || $2 == "") { count++ } END { print count + 0 }' \
            "$outline_file")
        outline_parts=$(grep -c '#nameddest=part\.' "$outline_file" || true)
        outline_chapters=$(grep -c '#nameddest=chapter\.[0-9]' "$outline_file" || true)
        outline_appendices=$(grep -c '#nameddest=appendix\.[A-H]' "$outline_file" || true)
        if [ "$outline_parts" -eq 12 ] && [ "$outline_chapters" -eq 79 ] \
           && [ "$outline_appendices" -eq 8 ]; then
            pass "PDF outline contains 12 Parts, 79 chapters, and 8 appendices"
        else
            fail "unexpected PDF outline ($outline_parts Parts, $outline_chapters chapters, $outline_appendices appendices)"
        fi
        if [ "$outline_entries" -eq 1066 ] \
           && [ "$outline_destinations" -eq "$outline_entries" ] \
           && [ "$outline_empty_titles" -eq 0 ]; then
            pass "all $outline_entries PDF outline entries have non-empty titles and unique destinations"
        else
            fail "damaged PDF outline ($outline_entries entries, $outline_destinations unique destinations, $outline_empty_titles empty titles)"
        fi
        outline_toc_diff_count=$(wc -l < "$outline_toc_diff_file")
        if [ "$outline_entries" -eq 1066 ] && [ "$outline_toc_diff_count" -eq 0 ]; then
            pass "PDF outline exactly matches all 1066 Part-through-subsection TOC destinations"
        else
            fail "PDF outline/TOC mismatch ($outline_toc_diff_count differing destinations)"
            head -10 "$outline_toc_diff_file" | sed 's/^/        /'
        fi
        outline_title_count=$(wc -l < "$outline_titles_file")
        source_bookmark_count=$(wc -l < "$source_bookmarks_file")
        outline_title_diff_count=$(wc -l < "$outline_title_diff_file")
        if [ "$outline_title_count" -eq 1066 ] \
           && [ "$source_bookmark_count" -eq "$outline_title_count" ] \
           && [ "$outline_title_diff_count" -eq 0 ]; then
            pass "all 1066 PDF outline titles match their source bookmarks exactly"
        else
            fail "PDF outline title mismatch ($outline_title_count PDF, $source_bookmark_count source, $outline_title_diff_count differing pairs)"
            head -10 "$outline_title_diff_file" | sed 's/^/        /'
        fi
        outline_parent_count=$(wc -l < "$outline_parents_file")
        source_parent_count=$(wc -l < "$source_parents_file")
        outline_parent_diff_count=$(wc -l < "$outline_parent_diff_file")
        if [ "$outline_parent_count" -eq 1066 ] \
           && [ "$source_parent_count" -eq "$outline_parent_count" ] \
           && [ "$outline_parent_diff_count" -eq 0 ]; then
            pass "all 1066 PDF outline entries match their source parent hierarchy"
        else
            fail "PDF outline hierarchy mismatch ($outline_parent_count PDF, $source_parent_count source, $outline_parent_diff_count differing pairs)"
            head -10 "$outline_parent_diff_file" | sed 's/^/        /'
        fi
        rm -f "$outline_dests_file" "$toc_outline_dests_file" "$outline_toc_diff_file" \
            "$outline_titles_file" "$source_bookmarks_file" "$outline_title_diff_file" \
            "$outline_parents_file" "$source_parents_file" "$outline_parent_diff_file"
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
        perl -ne 'while (m{/URI\((https://[^()]*)\)}g) { print "$1\n"; }' "$objects_file" \
            | sort -u > "$external_uris_file"
        printf '%s\n' \
            'https://learn.microsoft.com/en-us/windows/win32/api/dxgi/nf-dxgi-idxgiswapchain-present' \
            'https://learn.microsoft.com/en-us/windows/win32/direct3d9/d3dpresent' \
            'https://wiki.libsdl.org/SDL3/SDL_Init' \
            | sort -u > "$expected_uris_file"
        comm -23 "$external_uris_file" "$expected_uris_file" > "$unexpected_uris_file"
        comm -13 "$external_uris_file" "$expected_uris_file" > "$missing_uris_file"
        unsafe_action_count=$(grep -Ec '/S/(JavaScript|JS|Launch|GoToR|SubmitForm|ImportData)([^A-Za-z]|$)|/EmbeddedFiles([^A-Za-z]|$)' "$objects_file" || true)
        external_uri_count=$(wc -l < "$external_uris_file")
        unexpected_uri_count=$(wc -l < "$unexpected_uris_file")
        missing_uri_count=$(wc -l < "$missing_uris_file")
        if [ "$unsafe_action_count" -eq 0 ] && [ "$external_uri_count" -eq 3 ] \
           && [ "$unexpected_uri_count" -eq 0 ] && [ "$missing_uri_count" -eq 0 ]; then
            pass "PDF has only the three reviewed HTTPS links and no unsafe actions or attachments"
        else
            fail "PDF external-action audit failed ($external_uri_count URIs, $unexpected_uri_count unexpected, $missing_uri_count missing, $unsafe_action_count unsafe action(s))"
            sed 's/^/        unexpected: /' "$unexpected_uris_file" | head -10
            sed 's/^/        missing: /' "$missing_uris_file" | head -10
        fi
        rm -f "$external_uris_file" "$expected_uris_file" "$unexpected_uris_file" "$missing_uris_file"

        perl -ne '
            next unless m{/S/GoTo};
            while (m{/D\(([^()]*)\)}g) { print "$1\n"; }
        ' "$objects_file" | sort -u > "$link_dests_file"
        perl -ne '
            next unless m{/Names\[};
            while (m{\(([^()]*)\)\d+ 0 R}g) { print "$1\n"; }
        ' "$objects_file" | sort -u > "$named_dests_file"
        comm -23 "$link_dests_file" "$named_dests_file" > "$missing_dests_file"
        link_dest_count=$(wc -l < "$link_dests_file")
        missing_dest_count=$(wc -l < "$missing_dests_file")
        if [ "$link_dest_count" -gt 0 ] && [ "$missing_dest_count" -eq 0 ]; then
            pass "all $link_dest_count unique internal PDF link targets exist"
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
        if [ "$link_count" -gt 0 ] && [ "$targeted_link_count" -eq "$link_count" ] \
           && [ "$rect_link_count" -eq "$link_count" ] && [ "$bad_link_count" -eq 0 ]; then
            pass "all $link_count PDF link annotations have valid A4 geometry and targets"
        else
            fail "PDF link annotation audit failed ($link_count links, $targeted_link_count targets, $rect_link_count rectangles, $bad_link_count invalid)"
        fi

        page_objects_file=$(mktemp /tmp/cna-bible-page-objects.XXXXXX.txt)
        toc_target_result_file=$(mktemp /tmp/cna-bible-toc-targets.XXXXXX.txt)
        mutool show "$pdf" pages > "$page_objects_file" 2>/dev/null || true

        # A rectangle can be valid yet float over blank paper, producing an invisible hotspot.
        # Independently extract text geometry for every physical page and require positive-area
        # overlap between each Link rectangle and at least one visible text line.
        all_link_text_file=$(mktemp /tmp/cna-bible-all-link-text.XXXXXX.json)
        all_link_text_result_file=$(mktemp /tmp/cna-bible-all-link-text-result.XXXXXX.txt)
        if mutool draw -q -F stext.json -o "$all_link_text_file" "$pdf" 1-709 \
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
                                $box->{x} + $box->{w}, $box->{y} + $box->{h}
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
                    }
                }
                print "SUMMARY " . ($checked + 0) . " " . ($bad + 0) . "\n";
            ' "$objects_file" "$page_objects_file" "$all_link_text_file" \
                > "$all_link_text_result_file"
            read -r _ visible_link_count empty_link_count <<EOF
$(tail -1 "$all_link_text_result_file")
EOF
            if [ "$visible_link_count" -eq "$link_count" ] && [ "$empty_link_count" -eq 0 ]; then
                pass "all $visible_link_count PDF link rectangles overlap visible text"
            else
                fail "PDF link/text-overlap audit failed ($empty_link_count empty of $visible_link_count checked, $link_count expected)"
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
            ' "$objects_file" "$page_objects_file" "$book_dir/main.toc" > "$toc_link_result_file"
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
            rm -f "$toc_link_result_file"

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
            if [ "$toc_target_count" -gt 0 ] && [ "$bad_toc_target_count" -eq 0 ]; then
                pass "all $toc_target_count numbered TOC entries land on their printed pages"
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

# Use an independent interpreter as a final syntax/renderability check when available. This does
# not replace the visual pass; it catches corrupt objects and page programs that Poppler or MuPDF
# may tolerate differently.
if command -v gs >/dev/null 2>&1; then
    ink_file=$(mktemp /tmp/cna-bible-ink.XXXXXX.txt)
    if gs -q -dNOPAUSE -dBATCH -sDEVICE=inkcov -o "$ink_file" "$pdf"; then
        blank_pages=$(awk '$1 == 0 && $2 == 0 && $3 == 0 && $4 == 0 {print NR}' "$ink_file" \
            | paste -sd, -)
        expected_blank_pages=$(perl -ne '
            if (/\\contentsline \{part\}.*\{(\d+)\}\{part\.\d+\}%$/) {
                push @pages, $1 + 31;
            }
            END { print join(",", @pages); }
        ' "$book_dir/main.toc")
        if [ "$blank_pages" = "$expected_blank_pages" ]; then
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
