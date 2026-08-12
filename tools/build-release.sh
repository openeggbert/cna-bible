#!/usr/bin/env bash
# build-release.sh -- reproduce and verify the sealed CNA Bible release artifact.
#
# This intentionally fails when tracked book inputs change the PDF. Establishing a new release
# fingerprint requires the same independent clean-build and visual-review workflow recorded in
# NEXT.md and PLAN.md; do not update these constants merely to make the command green.

set -eu -o pipefail

usage() {
    printf 'Usage: %s\n' "${0##*/}"
}

case "$#:${1:-}" in
    0:) ;;
    1:--help)
        usage
        exit 0
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

system_dirname=$(command -v dirname) || {
    printf 'ERROR: missing required sealed-pipeline command: dirname\n' >&2
    exit 1
}
# The artifact lock must key the physical repository, not an invocation alias through a symlink.
repo_root="$(cd "$("$system_dirname" "${BASH_SOURCE[0]}")/.." && pwd -P)"
book_dir="$repo_root/latex/book"
pdf="$book_dir/main.pdf"
lock_helper="$repo_root/tools/book-lock.sh"
[ -r "$lock_helper" ] || { printf 'ERROR: missing tools/book-lock.sh\n' >&2; exit 1; }
. "$lock_helper"
release_profile="$repo_root/tools/release-profile.sh"
[ -r "$release_profile" ] || {
    printf 'ERROR: missing tools/release-profile.sh\n' >&2
    exit 1
}
. "$release_profile"

# Preflight the union of release-build and complete-verifier dependencies before invoking TeX.
# Otherwise an absent PDF parser can waste a full fixed-date rebuild and fail only at the final
# verification handoff.
missing_commands=""
for required_command in git latexmk pdflatex makeindex mutool sha256sum stat perl pdfinfo pdftotext pdffonts \
    pdfimages pngtopnm cmp gs mktemp cp rm flock mkdir grep sed awk find sort uniq wc head tail \
    comm diff paste xargs cat rmdir chmod env; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        missing_commands="$missing_commands $required_command"
    fi
done
if [ -n "$missing_commands" ]; then
    printf 'ERROR: missing required sealed-pipeline command(s):%s\n' "$missing_commands" >&2
    exit 1
fi

# A sealed build mutates the shared aux/log/PDF set and its failure path can restore the prior
# artifact. Hold the repository-wide exclusive artifact lock through its nested verifier.
acquire_book_lock exclusive || exit 1

if ! git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'ERROR: sealed release build requires a Git worktree\n' >&2
    exit 1
fi
actual_head=$(git -C "$repo_root" rev-parse HEAD)
actual_latex_tree=$(git -C "$repo_root" rev-parse HEAD:latex 2>/dev/null || true)
actual_tools_tree=$(git -C "$repo_root" rev-parse HEAD:tools)
latex_status=$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- latex)
tools_status=$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- tools)
if [ "$actual_latex_tree" != "$expected_latex_tree" ] || [ -n "$latex_status" ] \
   || [ -n "$tools_status" ]; then
    printf 'ERROR: sealed source/tool preflight failed\n' >&2
    printf 'expected tree: %s\nactual tree:   %s\n' \
        "$expected_latex_tree" "${actual_latex_tree:-missing}" >&2
    [ -n "$latex_status" ] && printf '%s\n' "$latex_status" >&2
    if [ -n "$tools_status" ]; then
        printf 'ERROR: sealed build/verification tools differ from HEAD\n' >&2
        printf '%s\n' "$tools_status" >&2
    fi
    exit 1
fi

# Treat the reviewed PDF as a transaction. A TeX failure, fingerprint mismatch, verifier failure
# or common signal restores the prior artifact byte-for-byte; if none existed, remove the partial
# output. Logs and auxiliary files remain available for diagnosis.
prior_pdf=""
release_succeeded=0
transaction_started=0
restore_or_commit_pdf() {
    snapshot_may_be_removed=1
    if [ "$transaction_started" -eq 1 ] && [ "$release_succeeded" -eq 0 ]; then
        if [ -n "$prior_pdf" ] && [ -f "$prior_pdf" ]; then
            if ! cp -p "$prior_pdf" "$pdf"; then
                printf 'ERROR: could not restore the prior PDF; snapshot retained at %s\n' \
                    "$prior_pdf" >&2
                snapshot_may_be_removed=0
            fi
        else
            rm -f "$pdf"
        fi
    fi
    if [ "$snapshot_may_be_removed" -eq 1 ] && [ -n "$prior_pdf" ]; then
        rm -f "$prior_pdf"
    fi
}
trap restore_or_commit_pdf EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [ -f "$pdf" ]; then
    if ! prior_pdf_candidate=$(mktemp /tmp/cna-bible-prior-release.XXXXXX.pdf); then
        printf 'ERROR: could not allocate the prior-PDF snapshot\n' >&2
        exit 1
    fi
    if ! cp -p "$pdf" "$prior_pdf_candidate"; then
        rm -f "$prior_pdf_candidate"
        printf 'ERROR: could not snapshot the prior reviewed PDF\n' >&2
        exit 1
    fi
    prior_pdf=$prior_pdf_candidate
fi
transaction_started=1

printf '%s\n' '== The CNA Bible: sealed release build =='
printf 'repository HEAD: %s\n' "$actual_head"
printf 'latex tree: %s\n' "$actual_latex_tree"
printf 'tools tree: %s\n' "$actual_tools_tree"
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
if ! actual_sha256_line=$(sha256sum "$pdf"); then
    printf 'ERROR: could not hash the rebuilt release artifact\n' >&2
    exit 1
fi
actual_sha256=${actual_sha256_line%% *}
case "$actual_sha256" in
    *[!0-9a-f]*|'')
        printf 'ERROR: invalid SHA-256 returned for the rebuilt release artifact\n' >&2
        exit 1
        ;;
esac
if [ "${#actual_sha256}" -ne 64 ]; then
    printf 'ERROR: invalid SHA-256 length for the rebuilt release artifact\n' >&2
    exit 1
fi
if ! pdf_info_object=$(mutool show -g "$pdf" trailer/Info 2>/dev/null); then
    printf 'ERROR: MuPDF could not read release metadata\n' >&2
    exit 1
fi
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

CNA_BIBLE_LOCK_FD="$book_lock_fd" "$repo_root/tools/verify-book.sh" --no-build

# The artifact lock serializes this project's PDF tools, not Git or arbitrary editors. Re-read the
# exact provenance immediately before committing the transaction so a concurrent checkout/commit
# or source/tool edit cannot leave a successful log describing a different repository state.
final_head=$(git -C "$repo_root" rev-parse HEAD)
final_latex_tree=$(git -C "$repo_root" rev-parse HEAD:latex 2>/dev/null || true)
final_tools_tree=$(git -C "$repo_root" rev-parse HEAD:tools)
final_latex_status=$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- latex)
final_tools_status=$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- tools)
if [ "$final_head" != "$actual_head" ] || [ "$final_latex_tree" != "$actual_latex_tree" ] \
   || [ "$final_tools_tree" != "$actual_tools_tree" ] || [ -n "$final_latex_status" ] \
   || [ -n "$final_tools_status" ]; then
    printf 'ERROR: repository source/tool provenance changed during sealed build\n' >&2
    printf 'HEAD:  %s -> %s\nlatex: %s -> %s\ntools: %s -> %s\n' \
        "$actual_head" "$final_head" "$actual_latex_tree" "$final_latex_tree" \
        "$actual_tools_tree" "$final_tools_tree" >&2
    [ -n "$final_latex_status" ] && printf '%s\n' "$final_latex_status" >&2
    [ -n "$final_tools_status" ] && printf '%s\n' "$final_tools_status" >&2
    exit 1
fi
release_succeeded=1
trap - HUP INT TERM
