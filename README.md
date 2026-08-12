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
`pdftotext`, and `pdffonts`, MuPDF's `mutool`, Ghostscript's `gs`, plus Perl and
Git; it reports any missing command before starting.

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
`7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af`. A manuscript or layout
change is expected to fail this gate until a new release has been independently reproduced and
reviewed; do not update the fingerprint merely to make the command pass.

The suite checks the build, references, structure, index, physical page bounds,
fonts, PDF navigation, page labels, link geometry and action safety, plus
independent Ghostscript processing. It does not replace visual verification: render and inspect every
physical PDF page changed by a content batch.

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

## Contribution rules

Claims must be checked against the live CNA ecosystem source, tests, or
authoritative plans. Code examples must be real and compilable. Screenshots
must come from an actual running build—never a mockup. See [CLAUDE.md](CLAUDE.md)
before changing manuscript content.
