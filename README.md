# The CNA Bible

A source-grounded technical book about
[CNA](https://github.com/openeggbert/cna), the C++23 reimplementation of the
Microsoft XNA 4.0 programming model. The single LaTeX volume covers the core
framework, graphics renderers, content, input, audio, networking, sibling
libraries, cross-platform engineering, migration, and project practice.

The current source candidate is the **CNA 0.1.0-alpha.1 edition**, pinned to
`v0.1.0-alpha.1` @ `1bb2145d99ed572dd4eb15009c34e2e5f410fcf0`. It contains 79 chapters and
nine appendices in one 584-page volume while preserving the preceding editorial pass's separation of
current contracts, evidence, limitations, and historical notes.
[NEXT.md](NEXT.md) records the precise handoff, [PLAN.md](PLAN.md) preserves the
authoritative plan and verification history, and
[EDITORIAL-AUDIT.md](EDITORIAL-AUDIT.md) records the quality pass.

The edition records a release-level limitation discovered by an exact-tag build: the experimental
native C API's final library target is compile-blocked because its public renderer map has 49
entries while CNA has 50 identities. The source/header inventory remains documented, but the book
does not present `cna_c_api` as a consumable alpha.1 artifact.

The sealed release is 2,602,878 bytes with SHA-256
`f4916143649d3e5e64bf6c4a5e2e0027ef136b8510ba338f58450c33a984870e`. Two clean builds at
`SOURCE_DATE_EPOCH=1787253313` produced byte-identical PDFs, the complete verifier passes, and
every materially changed page has been rendered and reviewed.

## Build

The build requires a TeX installation with `latexmk`, `pdflatex`, and
`makeindex`. The complete verifier additionally requires Poppler's `pdfinfo`,
`pdftotext`, `pdffonts`, and `pdfimages`; Netpbm's `pngtopnm`; MuPDF's `mutool`;
Ghostscript's `gs`; plus Perl, Git, and standard `cmp`. The visual-page driver
uses Poppler's `pdftoppm`, `file`, and Netpbm `pngtopnm`. The sealed workflow also uses util-linux
`flock` to serialize builds; the artifact-lock protocol expects Linux procfs at `/proc/self/fd`
and GNU `stat`. Each tool reports missing prerequisites before doing expensive work.

```bash
make -C latex book
```

The PDF is written to `latex/book/main.pdf`.

For a fresh build plus the complete source and PDF-artifact verification suite:

```bash
tools/verify-book.sh
```

To reproduce a sealed reviewed release with its fixed source date, exact byte fingerprint and
the complete verifier, run:

```bash
tools/build-release.sh
```

The alpha.1 release profile produces a 2,602,878-byte PDF with SHA-256
`f4916143649d3e5e64bf6c4a5e2e0027ef136b8510ba338f58450c33a984870e` and PDF
creation/modification date `D:20260820191513Z`. The command requires the reviewed
committed `latex/` tree plus clean `latex/` and `tools/` worktree state before invoking TeX, so
committed, staged, unstaged, or untracked release-input/tool drift fails early. Its header records
the exact HEAD and source/tool trees, and the transaction checks that provenance again after
verification. Sealed builds are serialized by physical repository identity even through path
aliases; if a build, fingerprint check, verifier, or final provenance check fails, the command
restores the prior reviewed PDF (or removes a newly created partial artifact) while retaining its
log for diagnosis.

The suite checks the build, references, structure, index, physical page bounds,
fonts, PDF navigation, page labels, link geometry and action safety, plus
independent Ghostscript processing. It does not replace visual verification: render and inspect every
physical PDF page changed by a content batch. `tools/render-pages.sh FIRST LAST` writes each run to
a fresh child below the private default `/tmp/cna-bible-pages-$EUID`, or below an explicit third
`OUTDIR` operand.

## Repository guide

- `latex/book/main.tex` — the complete book and chapter order.
- `latex/book/chapters/` — chapters grouped into twelve parts, plus appendices.
- `latex/common/preamble.tex` — shared styles, macros, indexing, and hyperlinks.
- `EDITORIAL-AUDIT.md` — measured editorial findings, decisions, and closure evidence.
- `PLAN.md` — current status, future proposals, and the edition's verification history.
- `NEXT.md` — concise handoff for the next autonomous session.
- `CLAUDE.md` — writing, source-grounding, validation, and Git conventions.
- `PROGRESS.md` — historical record of the superseded two-volume edition; not
  an active status or source path guide.
- `tools/cna-screenshot-infra/` — reproducible real-screenshot support for
  graphics chapters.
- `tools/build-release.sh` — fixed-date sealed release build, fingerprint check and full verifier.
- `tools/editorial-metrics.sh` — stable prose/style and structural inventory for editorial review.
- `tools/verify-edition-facts.sh` — pin-based checks for renderer, scene, and sibling facts.
- `tools/book-lock.sh` — shared/exclusive artifact-lock helper sourced by all build, verify, and
  visual-render entry points; do not bypass it when adding another PDF consumer or writer.

## Contribution rules

Claims must be checked against the edition-pinned CNA ecosystem source, tests, or
authoritative plans. Code examples must be real and compilable. Screenshots
must come from an actual running build—never a mockup. See [CLAUDE.md](CLAUDE.md)
before changing manuscript content.
