#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
cna_repo=${CNA_SOURCE_DIR:-"$repo_root/../cna"}
sharp_repo=${SHARP_RUNTIME_SOURCE_DIR:-"$repo_root/../sharp-runtime"}
preamble="$repo_root/latex/common/preamble.tex"
registry_appendix="$repo_root/latex/book/chapters/appendices/appendix-b-feature-matrix.tex"
cna_pin=7a64362efef4119bf880459ef1704fb2c52199e2
sharp_pin=f827a6c5349234d5ac938886788ed8eca8fe1c10

die()
{
    printf 'FAIL  %s\n' "$*" >&2
    exit 1
}

[ -d "$cna_repo/.git" ] || die "CNA repository not found at $cna_repo"
[ -d "$sharp_repo/.git" ] || die "sharp-runtime repository not found at $sharp_repo"
git -C "$cna_repo" cat-file -e "$cna_pin^{commit}" 2>/dev/null \
    || die "pinned CNA commit $cna_pin is unavailable"
git -C "$sharp_repo" cat-file -e "$sharp_pin^{commit}" 2>/dev/null \
    || die "pinned sharp-runtime commit $sharp_pin is unavailable"
[ -f "$preamble" ] || die "book preamble not found"
[ -f "$registry_appendix" ] || die "renderer-registry appendix not found"

tmp_dir=$(mktemp -d /tmp/cna-bible-edition-facts.XXXXXX)
trap 'rm -rf -- "$tmp_dir"' EXIT

selection="$tmp_dir/selection.cmake"
renderer_header="$tmp_dir/GraphicsRendererType.hpp"
git -C "$cna_repo" show "$cna_pin:cmake/RendererSelection.cmake" > "$selection"
git -C "$cna_repo" show \
    "$cna_pin:modules/core/include/CNA/GraphicsRendererType.hpp" > "$renderer_header"

selectors="$tmp_dir/selectors.txt"
header_names="$tmp_dir/header-names.txt"
source_families="$tmp_dir/source-families.txt"
book_selectors="$tmp_dir/book-selectors.txt"
book_families="$tmp_dir/book-families.txt"
cna_tree="$tmp_dir/cna-tree.txt"
sharp_tree="$tmp_dir/sharp-tree.txt"
listing_includes="$tmp_dir/listing-includes.txt"
sed -n '/set_property(CACHE CNA_GRAPHICS_RENDERER PROPERTY STRINGS/ {
    s/.*STRINGS //
    s/)$//
    p
}' "$selection" | tr ' ' '\n' | tr -d '"' | sed '/^$/d' | LC_ALL=C sort > "$selectors"

sed -n '/switch (getCurrentGraphicsRendererType())/,/^        }/p' "$renderer_header" \
    | sed -n 's/.*return "\([A-Z0-9_]*\)";.*/\1/p' \
    | LC_ALL=C sort > "$header_names"

git -C "$cna_repo" ls-tree -d --name-only "$cna_pin" modules/renderers/ \
    | awk -F/ '$NF != "common" { print $NF }' | LC_ALL=C sort > "$source_families"

perl -ne '
    $on = 1 if /^OpenGL fixed function &/;
    if ($on) {
        while (/\\texttt\{([^}]*)\}/g) {
            $name = $1;
            $name =~ s/\\_/_/g;
            print "$name\n";
        }
    }
    $on = 0 if /^Diagnostic \/ non-GPU &/;
' "$registry_appendix" | LC_ALL=C sort > "$book_selectors"

sed -n '/^bgfx &/,/^wicked &/s/^\([a-z0-9-][a-z0-9-]*\) &.*/\1/p' \
    "$registry_appendix" | LC_ALL=C sort > "$book_families"

git -C "$cna_repo" ls-tree -r --name-only "$cna_pin" | LC_ALL=C sort > "$cna_tree"
git -C "$sharp_repo" ls-tree -r --name-only "$sharp_pin" | LC_ALL=C sort > "$sharp_tree"
find "$repo_root/latex/book/front" "$repo_root/latex/book/chapters" -type f -name '*.tex' -print0 \
    | xargs -0 perl -ne '
        while (/#include\s*[<"]((?:CNA|Microsoft|System|SharpRuntime)\/[^>"]+)[>"]/g) {
            print "$1\n";
        }
    ' | LC_ALL=C sort -u > "$listing_includes"

listing_include_count=0
while IFS= read -r include_path; do
    [ -n "$include_path" ] || continue
    listing_include_count=$((listing_include_count + 1))
    case "$include_path" in
        CNA/*|Microsoft/*) tree=$cna_tree ;;
        System/*|SharpRuntime/*) tree=$sharp_tree ;;
        *) die "unclassified project include in manuscript: $include_path" ;;
    esac
    grep -Fq "/$include_path" "$tree" \
        || die "manuscript include is absent at the applicable edition pin: $include_path"
done < "$listing_includes"

identity_count=$(wc -l < "$selectors")
identity_unique_count=$(sort -u "$selectors" | wc -l)
header_identity_count=$(wc -l < "$header_names")
family_count=$(wc -l < "$source_families")
oracle_scene_count=$(git -C "$cna_repo" ls-tree -r --name-only "$cna_pin" tools/xna-oracle \
    | awk '/\.scene$/ { n++ } END { print n+0 }')

macro_value()
{
    local name=$1
    sed -n "s/^\\\\newcommand{\\\\$name}{\([0-9][0-9]*\)}$/\\1/p" "$preamble"
}

macro_pin=$(sed -n 's/^\\newcommand{\\CnaRevisionShort}{\\texttt{\([0-9a-f]*\)}}$/\1/p' "$preamble")
macro_identities=$(macro_value RendererIdentityCount)
macro_families=$(macro_value RendererFamilyCount)
macro_scenes=$(macro_value XnaOracleSceneCount)

[ "$identity_count" -eq "$identity_unique_count" ] \
    || die "pinned selector list contains duplicates ($identity_count entries, $identity_unique_count unique)"
[ "$identity_count" -eq "$header_identity_count" ] \
    || die "selector/header identity counts differ ($identity_count vs $header_identity_count)"
cmp -s "$selectors" "$header_names" \
    || die "CMake selector names and GraphicsRendererType public names differ at the pin"
cmp -s "$selectors" "$book_selectors" \
    || die "Appendix B public identities differ from the pinned CMake selector registry"
cmp -s "$source_families" "$book_families" \
    || die "Appendix B implementation families differ from the pinned renderer directories"
[ "$macro_identities" = "$identity_count" ] \
    || die "RendererIdentityCount=$macro_identities but pinned source derives $identity_count"
[ "$macro_families" = "$family_count" ] \
    || die "RendererFamilyCount=$macro_families but pinned source derives $family_count"
[ "$macro_scenes" = "$oracle_scene_count" ] \
    || die "XnaOracleSceneCount=$macro_scenes but pinned source derives $oracle_scene_count"
[ "$macro_pin" = "${cna_pin:0:8}" ] \
    || die "CnaRevisionShort=$macro_pin but the edition pin begins ${cna_pin:0:8}"

printf 'PASS  CNA %s derives %d renderer identities, %d implementation families, and %d XNA-oracle scenes; book macros and %d project-header includes match the edition pins\n' \
    "$cna_pin" "$identity_count" "$family_count" "$oracle_scene_count" "$listing_include_count"
