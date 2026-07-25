# The CNA Bible

A source-grounded technical book about
[CNA](https://github.com/openeggbert/cna), the C++23 reimplementation of the
Microsoft XNA 4.0 programming model. The single LaTeX volume covers the core
framework, graphics backends, content, input, audio, networking, sibling
libraries, cross-platform engineering, migration, and project practice.

The manuscript currently contains 49 chapters and six appendices. Its active
expansion is a long-running project; [NEXT.md](NEXT.md) records the precise
current state and [PLAN.md](PLAN.md) is the authoritative task list.

## Build

The build requires a TeX installation with `latexmk`, `pdflatex`, and
`makeindex`.

```bash
make -C latex book
```

The PDF is written to `latex/book/main.pdf`.

For a fresh verification build:

```bash
cd latex/book
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex
grep -iE 'Warning.*undefined|undefined reference|undefined control' main.log
grep -iE 'multiply defined|multiply-defined' main.log
```

Both `grep` commands should produce no output. A successful build does not
replace visual verification: render and inspect every physical PDF page changed
by a content batch.

## Repository guide

- `latex/book/main.tex` — the complete book and chapter order.
- `latex/book/chapters/` — chapters grouped into nine parts, plus appendices.
- `latex/common/preamble.tex` — shared styles, macros, indexing, and hyperlinks.
- `PLAN.md` — durable expansion targets, status, and session history.
- `NEXT.md` — concise handoff for the next autonomous session.
- `CLAUDE.md` — writing, source-grounding, validation, and Git conventions.
- `PROGRESS.md` — historical record of the original complete-book pass.
- `tools/cna-screenshot-infra/` — reproducible real-screenshot support for
  graphics chapters.

## Contribution rules

Claims must be checked against the live CNA ecosystem source, tests, or
authoritative plans. Code examples must be real and compilable. Screenshots
must come from an actual running build—never a mockup. See [CLAUDE.md](CLAUDE.md)
before changing manuscript content.
