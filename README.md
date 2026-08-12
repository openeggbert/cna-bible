# The CNA Bible

A source-grounded technical book about
[CNA](https://github.com/openeggbert/cna), the C++23 reimplementation of the
Microsoft XNA 4.0 programming model. The single LaTeX volume covers the core
framework, graphics renderers, content, input, audio, networking, sibling
libraries, cross-platform engineering, migration, and project practice.

The verified edition contains 79 chapters and eight appendices in one 709-page
volume. Phases A--G are complete against the pinned source baseline;
[NEXT.md](NEXT.md) records the precise handoff and [PLAN.md](PLAN.md) preserves
the authoritative plan and verification history.

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

To reproduce the sealed reviewed release with its fixed source date, exact byte fingerprint and
the complete verifier, run:

```bash
tools/build-release.sh
```

That command must produce a 3,314,744-byte PDF with SHA-256
`7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af` and PDF creation/modification
date `D:20260812100654Z`. A manuscript or layout
change is expected to fail this gate until a new release has been independently reproduced and
reviewed. The command requires the reviewed committed `latex/` tree plus clean `latex/` and
`tools/` worktree state before invoking TeX, so committed, staged, unstaged, or untracked release-
input/tool drift fails early; do not update its tree or PDF fingerprints merely to make the
command pass. Its header records the exact HEAD and source/tool trees, and the transaction checks
that provenance again after verification. Sealed builds are serialized by physical repository
identity even through path aliases; if a build, fingerprint check, verifier, or final provenance
check fails, the command restores the prior reviewed PDF (or removes a newly created partial
artifact) while retaining its log for diagnosis.

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
- `PLAN.md` — durable expansion targets, status, and session history.
- `NEXT.md` — concise handoff for the next autonomous session.
- `CLAUDE.md` — writing, source-grounding, validation, and Git conventions.
- `PROGRESS.md` — historical record of the superseded two-volume edition; not
  an active status or source path guide.
- `tools/cna-screenshot-infra/` — reproducible real-screenshot support for
  graphics chapters.
- `tools/build-release.sh` — fixed-date sealed release build, fingerprint check and full verifier.
- `tools/book-lock.sh` — shared/exclusive artifact-lock helper sourced by all build, verify, and
  visual-render entry points; do not bypass it when adding another PDF consumer or writer.

## Contribution rules

Claims must be checked against the live CNA ecosystem source, tests, or
authoritative plans. Code examples must be real and compilable. Screenshots
must come from an actual running build—never a mockup. See [CLAUDE.md](CLAUDE.md)
before changing manuscript content.
