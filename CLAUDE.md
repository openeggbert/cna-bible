# The CNA Bible — project guide for Claude Code sessions

This repository is a single, unified LaTeX technical book about the `openeggbert/cna`
ecosystem (CNA: a C++23 reimplementation of the Microsoft XNA 4.0 programming model, built on
SDL3 with pluggable graphics backends). It is being written incrementally, across many
sessions, by Claude Code itself, under the direction of the repository's author.

**The book was originally drafted as two separate volumes and merged into one book on
2026-07-20** (same chapters and content, renumbered and combined into a single compilation,
single index, single table of contents). `PLAN.md`'s session log has the full details of the
merge (directory moves, chapter renumbering table, cross-reference fixes) if that history is
ever needed; don't re-litigate the one-book decision.

**Start every session by reading `NEXT.md`**, not just this file — it carries the specific,
current-state context (what was just finished, what's in progress, what to do immediately
next) that this file deliberately does not repeat. Then read `PLAN.md` for the full task list
and per-chapter page targets. `PROGRESS.md` is the historical log of everything completed
before the current expansion phase started; useful for background, not for "what's next."

## Repository layout

- `latex/book/` — the whole book. Chapters under `chapters/part{1-12}-*/chNN-slug.tex` (1
  through 79, continuous across all twelve parts), eight appendices under
  `chapters/appendices/` (`appendix-{a-h}-slug.tex`), front matter (`front/titlepage.tex`,
  `front/preface.tex`), and `main.tex` (the single top-level file — one
  `\part{}`/`\input{}` sequence, Parts I–XII, then `\appendix` for A–H, then `\printindex`).
  Parts I–IV cover identity, architecture, the renderer-independent graphics machine and the
  renderers; Parts V–XII cover content, 3D/glTF, services, foundation libraries, platforms,
  verification and porting practice.
- `latex/common/preamble.tex` — shared preamble (fonts, `cnacpp`/`cnashell` listings styles,
  hyperref, the `\cnaclass`/`\cnans`/`\repolink` macros, the `sourcenote` callout box).
- `latex/Makefile` — `make book` (latexmk, pdflatex).
- `PLAN.md` — the expansion project's task list, per-chapter page targets, methodology, open
  questions/conflicts, and a dated session log. This is the durable source of truth for what
  page count each chapter is aiming for and why.
- `NEXT.md` — short, current-state briefing for whichever session picks up work next. Update
  this at the **end** of every session (not just when a chapter finishes) so a fresh session
  with no memory of this conversation can resume correctly without re-deriving context.
- `PROGRESS.md` — historical record of the original ~230-page book's construction (both
  volumes' first complete pass, back when it was still two volumes, the content-completeness
  pass, the API quick-reference appendices, the index fix). Read for background; don't add new
  entries here — new work goes in `PLAN.md`'s session log and `NEXT.md`.
- `tools/cna-screenshot-infra/` — a patch, a demo source file, and a README documenting how to
  build CNA and capture a real, headless screenshot via its `SOFTWARE` graphics backend.
  `/workspace/cna` (or wherever `cna` gets cloned for a given session) does **not** persist
  across sessions — reapply this patch to a fresh clone whenever screenshot capture is needed.
- `tools/verify-book.sh` — the authoritative build/source/PDF verification suite. Use it once per
  writing batch; its PDF checks still do not replace reading rendered images of touched pages.
- `tools/build-release.sh` — the sealed fixed-date release reproduction. It requires the reviewed
  byte fingerprint and is not the command for an in-progress manuscript change.
- `tools/book-lock.sh` — sourced lock protocol shared by the release, verifier and page renderer.
  New commands that read the built artifact must take its shared lock; commands that write TeX
  auxiliaries, logs or the PDF must take its exclusive lock. Key locks by the physical repository
  root (`pwd -P`) so directory symlinks cannot split one artifact into multiple lock namespaces.

## Build

```bash
cd latex && make book   # -> book/main.pdf
```

Uses `latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error`.

**As of 2026-07-21, the build/verify step is deliberately batched, not per-chapter** (an
explicit author decision, trading slower error discovery for faster writing throughput — see
"Batched verification" below). Do not rebuild after every single chapter edit; do rebuild and
fully verify once per batch of roughly 8–10 chapters/appendices.

When a verification pass does run, use the complete suite:

```bash
tools/verify-book.sh
```

It builds the book and performs the tight reference/label/index/source checks as well as the
complete PDF artifact audit. For a sealed owner-review release only, `tools/build-release.sh`
forces the recorded source date, exact byte fingerprint and then the same verifier. A normal
manuscript change should fail that sealed hash gate until a new release checkpoint is authorized.
Neither command substitutes for the PNG-render visual pass described below — only rendering the
affected pages and reading them closes a real text/layout change.

## Non-negotiable methodology (established across this whole project, not just the expansion)

- **Every claim is grounded in an actual source read.** Read the real header, `.cpp`
  implementation, test file, or `docs/*.md`/`plan_*.md`/`CHECKLIST.md` file before writing a
  sentence about it. Never paraphrase from memory or invent a plausible-sounding API surface.
  This project has caught and corrected its own stale/incorrect claims more than once
  (Vol. I Ch.8's original ".xnb reader doesn't exist" claim, later corrected) — treat that as
  the standard to hold every new page to, not an embarrassment to hide.
- **Screenshots: real or not at all.** Never fabricate, mock up, or AI-generate an image
  presented as a screenshot of running code. If a real one can't be captured for a given
  backend (see `tools/cna-screenshot-infra/README.md` for exactly which backends currently
  can/can't), say so explicitly in the chapter text instead of skipping the question silently.
- **Code examples must be real, compilable code**, adapted from an actual test or example call
  site wherever one exists — not invented from scratch, and never presented as verified when it
  wasn't actually compiled.
- **Batched verification (author decision, 2026-07-21): write across roughly 8–10
  chapters/appendices, then do one consolidated build-and-verify pass, not one per chapter.**
  This is a deliberate speed/safety tradeoff — writing throughput matters more than catching a
  layout defect the moment it's introduced. During the writing part of a batch: run the
  spacing-fix regex on each touched file as usual, but do **not** run `make book`, and do
  **not** render pages to PNG. Once a batch's writing is done (or a natural stopping point is
  reached), run the full verification pass once: `tools/verify-book.sh`, locate
  each touched chapter's physical page range (`pdftotext -f N -l N`), render every touched page
  to PNG (`pdftoppm -png -f N -l N -r 120`), read each one, and fix whatever is found — stale
  cross-references (this project's most common real failure mode: a plain-text "Chapter~17"
  citation left behind after inserting or renumbering a chapter — grep for `Chapter~[0-9]`
  patterns project-wide after any renumbering), overfull-hboxes, running-header/folio
  collisions, and any hard LaTeX compile error, all fixed together in the same pass rather than
  chased one at a time. A batch can compile broken (or overflow) for the length of the batch —
  that is the accepted cost of this policy, not an oversight if it happens.
- **Mark each row's verification status honestly while a batch is in flight.** A `PLAN.md` row
  written during the writing part of a batch is not yet PDF-verified — say so explicitly (e.g.
  `**In progress (~N of ~M pages, pending batch verification)**`) rather than claiming
  `PDF-verified clean` before the batch's own verification pass has actually run. Only relabel
  a row `PDF-verified clean` once the consolidated pass has actually rendered and inspected its
  pages. `NEXT.md` should likewise always state, at handoff, which chapters in the current
  batch are still pending verification, so a future session (or this one, after an
  interruption) knows exactly where the batch left off.
- **Commit in small, descriptive increments and push after each one** — not one giant commit at
  the end of a session. This is what makes a multi-session project actually resumable. This is
  independent of the batched-verification policy above: keep committing per chapter even while
  deferring the build/PNG-verify step to the end of the batch.
- **Honor explicit author scope decisions even when they conflict with a later, broader
  instruction** — flag the conflict in `PLAN.md` and ask, don't resolve it silently by picking
  whichever reading is more convenient. (Two such conflicts already came up and were resolved
  this way: free-direct/cna-extended's scope cap vs. "every chapter must expand.")
- Cross-chapter citations should use real `\ref{ch:label}` wherever a label already exists,
  now that the whole book compiles as one document (a single `\ref{}` resolves correctly
  everywhere since the 2026-07-20 volume merge). A number of plain-text `Chapter~N` citations
  survive from the two-volume era where cross-volume `\ref{}` wasn't possible — these are
  correct as of the merge (renumbered by hand), but drifting to real `\ref{}` opportunistically
  when touching a paragraph that has one is worth doing, not required as a standalone pass.
- `\cnaclass{}` and `\cnans{}` (in `preamble.tex`) both wrap their argument in `\texttt{}` *and*
  emit `\index{}` for it — this is how the back-of-book index gets populated. Keep using these
  macros for every class/method/namespace name rather than bare `\texttt{}`, or the index stops
  growing.
