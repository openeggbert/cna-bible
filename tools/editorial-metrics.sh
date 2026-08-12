#!/usr/bin/env bash
# editorial-metrics.sh -- stable source-level measurements for the 2026 editorial pass.

set -eu -o pipefail

system_dirname=$(command -v dirname) || {
    printf 'ERROR: dirname is required\n' >&2
    exit 1
}
repo_root="$(cd "$("$system_dirname" "${BASH_SOURCE[0]}")/.." && pwd -P)"
book_dir="$repo_root/latex/book"
baseline_prose_tokens=246787

for required_command in find perl wc awk sort head mktemp rm; do
    command -v "$required_command" >/dev/null 2>&1 || {
        printf 'ERROR: %s is required\n' "$required_command" >&2
        exit 1
    }
done

scratch=$(mktemp /tmp/cna-bible-editorial-metrics.XXXXXX)
cleaned=$(mktemp /tmp/cna-bible-editorial-prose.XXXXXX)
chapter_rows=$(mktemp /tmp/cna-bible-editorial-chapters.XXXXXX)
cleanup() {
    rm -f "$scratch" "$cleaned" "$chapter_rows"
}
trap cleanup EXIT HUP INT TERM

find "$book_dir" -type f -name '*.tex' -print0 | sort -z | xargs -0 cat > "$scratch"
perl -0777 -pe '
    s/\\begin\{lstlisting\}.*?\\end\{lstlisting\}//sg;
    s/(?<!\\)%.*$//mg;
' "$scratch" > "$cleaned"

source_files=$(find "$book_dir" -type f -name '*.tex' | wc -l)
source_lines=$(wc -l < "$scratch")
source_words=$(wc -w < "$scratch")
prose_tokens=$(perl -0777 -ne '
    @w = /\b[\w][\w:+.\/'"'"'~-]*\b/g;
    print scalar(@w);
' "$cleaned")
reduction=$(awk -v base="$baseline_prose_tokens" -v now="$prose_tokens" \
    'BEGIN { printf "%.2f", (base-now)*100/base }')

printf '%s\n' '== The CNA Bible: editorial metrics =='
printf 'TeX files:                         %s\n' "$source_files"
printf 'source lines:                      %s\n' "$source_lines"
printf 'source words (wc -w):              %s\n' "$source_words"
printf 'prose tokens (listings removed):   %s\n' "$prose_tokens"
printf 'editorial baseline prose tokens:   %s\n' "$baseline_prose_tokens"
printf 'reduction from baseline:           %s%%\n' "$reduction"

printf '\n%s\n' 'Rhetorical review queue (outside listings):'
perl -0777 -ne '
    $t = lc $_;
    @patterns = (
      "real", "genuine", "genuinely", "actually", "precisely",
      "worth knowing", "worth noting", "rather than", "not merely",
      "not just", "this is not", "read directly", "a worked example",
      "a real bug", "a real finding", "does not prove"
    );
    for $p (@patterns) {
        $q = quotemeta($p);
        $n = () = $t =~ /\b$q\b/g;
        printf "  %-24s %6d\n", $p, $n;
    }
' "$cleaned"

printf '\n%s\n' 'Structural inventory:'
part_count=$(find "$book_dir/chapters" -mindepth 1 -maxdepth 1 -type d -name 'part*' | wc -l)
chapter_count=$(find "$book_dir/chapters" -type f -name 'ch[0-9][0-9]-*.tex' | wc -l)
appendix_count=$(find "$book_dir/chapters/appendices" -type f -name 'appendix-*.tex' | wc -l)
printf '  %-24s %6d\n' 'parts' "$part_count"
printf '  %-24s %6d\n' 'chapters' "$chapter_count"
printf '  %-24s %6d\n' 'appendices' "$appendix_count"
perl -0777 -ne '
    @checks = (
      ["sections", qr/\\section\{/],
      ["subsections", qr/\\subsection\{/],
      ["listings", qr/\\begin\{lstlisting\}/],
      ["figures", qr/\\begin\{figure\}/],
      ["figure descriptions", qr/\\begin\{figurealt\}/],
      ["tables", qr/\\begin\{(?:table|longtable|tabularx|tabular)\}/]
    );
    for $check (@checks) {
        ($label, $re) = @$check;
        $n = () = $_ =~ /$re/g;
        printf "  %-24s %6d\n", $label, $n;
    }
' "$scratch"

find "$book_dir/chapters" -type f -name '*.tex' -print0 \
    | xargs -0 perl -0777 -e '
        for $path (@ARGV) {
            open F, "<", $path or die "$path: $!";
            local $/; $t = <F>; close F;
            next unless $t =~ /\\chapter\{([^}]*)\}/;
            $title = $1;
            $t =~ s/\\begin\{lstlisting\}.*?\\end\{lstlisting\}//sg;
            @w = $t =~ /\b[\w][\w:+.\/'"'"'~-]*\b/g;
            $score = 0;
            for $p ("real", "genuine", "genuinely", "actually", "precisely",
                    "worth knowing", "rather than", "not merely", "not just",
                    "this is not", "worked example") {
                $q = quotemeta($p);
                $score += () = lc($t) =~ /\b$q\b/g;
            }
            $rate = @w ? 1000 * $score / @w : 0;
            printf "%09.3f\t%6d\t%4d\t%s\t%s\n", $rate, scalar(@w), $score, $path, $title;
        }
    ' > "$chapter_rows"

printf '\n%s\n' 'Highest rhetoric-pattern density (occurrences per 1,000 tokens):'
sort -rn "$chapter_rows" | head -15 | awk -F '\t' \
    '{printf "  %6.1f  %6d tokens  %3d hits  %s\n", $1, $2, $3, $5}'
