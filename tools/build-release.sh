#!/usr/bin/env bash
# build-release.sh -- reproduce and verify the sealed CNA Bible release artifact.
#
# This intentionally fails when tracked book inputs change the PDF. Establishing a new release
# fingerprint requires the same independent clean-build and visual-review workflow recorded in
# NEXT.md and PLAN.md; do not update these constants merely to make the command green.

set -eu

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
book_dir="$repo_root/latex/book"
pdf="$book_dir/main.pdf"
source_date_epoch=1786529214
expected_bytes=3314744
expected_sha256=7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af
expected_latex_tree=406104d29871dab11757fdd72ded5d9fbc7fc9f1
expected_pdf_date=D:20260812100654Z

for required_command in git latexmk mutool sha256sum stat; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'ERROR: missing required release command: %s\n' "$required_command" >&2
        exit 1
    fi
done

if ! git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'ERROR: sealed release build requires a Git worktree\n' >&2
    exit 1
fi
actual_latex_tree=$(git -C "$repo_root" rev-parse HEAD:latex 2>/dev/null || true)
latex_status=$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- latex)
if [ "$actual_latex_tree" != "$expected_latex_tree" ] || [ -n "$latex_status" ]; then
    printf 'ERROR: tracked release inputs do not match the reviewed clean latex tree\n' >&2
    printf 'expected tree: %s\nactual tree:   %s\n' \
        "$expected_latex_tree" "${actual_latex_tree:-missing}" >&2
    [ -n "$latex_status" ] && printf '%s\n' "$latex_status" >&2
    exit 1
fi

printf '%s\n' '== The CNA Bible: sealed release build =='
printf 'latex tree: %s\n' "$actual_latex_tree"
printf 'SOURCE_DATE_EPOCH=%s\n' "$source_date_epoch"
if ! (
    cd "$book_dir"
    env SOURCE_DATE_EPOCH="$source_date_epoch" \
        latexmk -gg -pdf -interaction=nonstopmode -halt-on-error -file-line-error main.tex
) > "$repo_root/latex/release-build.log" 2>&1; then
    printf 'ERROR: release build failed; see latex/release-build.log\n' >&2
    exit 1
fi

actual_bytes=$(stat -c '%s' "$pdf")
actual_sha256=$(sha256sum "$pdf" | awk '{print $1}')
pdf_info_object=$(mutool show -g "$pdf" trailer/Info 2>/dev/null || true)
creation_date=$(printf '%s\n' "$pdf_info_object" \
    | sed -n 's/.*\/CreationDate(\([^)]*\)).*/\1/p')
modification_date=$(printf '%s\n' "$pdf_info_object" \
    | sed -n 's/.*\/ModDate(\([^)]*\)).*/\1/p')
printf 'main.pdf: %s bytes\n' "$actual_bytes"
printf 'SHA-256: %s\n' "$actual_sha256"
printf 'PDF dates: %s / %s\n' "${creation_date:-missing}" "${modification_date:-missing}"

if [ "$actual_bytes" -ne "$expected_bytes" ] || [ "$actual_sha256" != "$expected_sha256" ] \
   || [ "$creation_date" != "$expected_pdf_date" ] \
   || [ "$modification_date" != "$expected_pdf_date" ]; then
    printf 'ERROR: PDF does not match the reviewed release fingerprint\n' >&2
    printf 'expected: %s bytes, %s, dates %s\n' \
        "$expected_bytes" "$expected_sha256" "$expected_pdf_date" >&2
    exit 1
fi

"$repo_root/tools/verify-book.sh" --no-build
