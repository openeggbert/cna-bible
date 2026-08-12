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

# These source identifiers and build options were removed by CNA's renderer/CNAEXT
# naming migration. Unlike ordinary prose uses of "backend", none is contextually valid in
# the current manuscript. Historical discussion should spell out the old name without using
# it as a live identifier, or live in the audit/plan evidence outside the compiled book.
obsolete_re='IGraphicsBackend|ITextureBackend|ITexture3DBackend|ISpriteBatchBackend|IEffectBackend|ITextureCubeBackend|IRenderTargetBackend|IRenderTargetCubeBackend|IIndexBufferBackend|IVertexBufferBackend|IOcclusionQueryBackend|GraphicsBackendType|GetGraphicsBackendType|GetGraphicsBackendName|GraphicsBackendCreateArgs|CreateGraphicsBackend|D3D11RenderTargetBackend|CNA_GRAPHICS_BACKEND|CNA\\_GRAPHICS\\_BACKEND|CNA_BACKEND_|CNA\\_BACKEND\\_|CNA_RENDERER_(D3D9|D3D11|D3D12|DX3|EASYGL|ASCII)|CNA\\_RENDERER\\_(D3D9|D3D11|D3D12|DX3|EASYGL|ASCII)|NOXNA|BackendSelection\.cmake|BackendLibraries\.cmake|customEffectBackend|GraphicsRendererType::Ascii'
if grep -rEn "$obsolete_re" "$chapters" "$front" > /tmp/cna-bible-obsolete-identifiers.txt 2>/dev/null; then
    n=$(wc -l < /tmp/cna-bible-obsolete-identifiers.txt)
    fail "obsolete CNA identifiers/options in compiled manuscript: $n"
    head -10 /tmp/cna-bible-obsolete-identifiers.txt | sed 's/^/        /'
else
    pass "no obsolete CNA identifiers/options in compiled manuscript"
fi

if grep -rEn 'CNA(_|\\_)GRAPHICS(_|\\_)RENDERER=(EASYGL|DX3|D3D9|D3D11|D3D12|ASCII)' "$chapters" "$front" > /tmp/cna-bible-obsolete-selectors.txt 2>/dev/null; then
    n=$(wc -l < /tmp/cna-bible-obsolete-selectors.txt)
    fail "removed renderer selector in a live CMake assignment: $n"
    head -10 /tmp/cna-bible-obsolete-selectors.txt | sed 's/^/        /'
else
    pass "no removed renderer selectors in live CMake assignments"
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

page_size=$(printf '%s\n' "$pdf_info" | awk -F: '/^Page size:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
encrypted=$(printf '%s\n' "$pdf_info" | awk -F: '/^Encrypted:/ {sub(/^[[:space:]]+/, "", $2); print $2}')
if printf '%s\n' "$page_size" | grep -q '^595\.276 x 841\.89 pts (A4)$' \
   && [ "$encrypted" = "no" ]; then
    pass "PDF is unencrypted A4"
else
    fail "unexpected PDF page format or encryption (size='$page_size', encrypted='${encrypted:-?}')"
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
    outline_file=$(mktemp /tmp/cna-bible-outline.XXXXXX.txt)
    if mutool show "$pdf" outline > "$outline_file" 2>/dev/null; then
        outline_parts=$(grep -c '#nameddest=part\.' "$outline_file" || true)
        outline_chapters=$(grep -c '#nameddest=chapter\.[0-9]' "$outline_file" || true)
        outline_appendices=$(grep -c '#nameddest=appendix\.[A-H]' "$outline_file" || true)
        if [ "$outline_parts" -eq 12 ] && [ "$outline_chapters" -eq 79 ] \
           && [ "$outline_appendices" -eq 8 ]; then
            pass "PDF outline contains 12 Parts, 79 chapters, and 8 appendices"
        else
            fail "unexpected PDF outline ($outline_parts Parts, $outline_chapters chapters, $outline_appendices appendices)"
        fi
    else
        fail "mutool could not read the PDF outline"
    fi
    rm -f "$outline_file"
else
    info "mutool unavailable; PDF outline counts not checked"
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
