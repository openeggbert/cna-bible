# Next session — start here

Read this file, then `PLAN.md`, then `AUDIT.md`. The raw per-area research evidence is in
`audit/`. The previous edition's plan and handoff are archived as `PLAN-ARCHIVE-2026-07-26.md`
and `NEXT-ARCHIVE-2026-07-26.md` — history, not instructions.

## State at handoff (2026-08-11)

| | |
|---|---|
| cna-bible branch | `next` |
| CNA pinned SHA | `7a64362efef4119bf880459ef1704fb2c52199e2` (`develop` == `origin/develop`, 2026-08-11) |
| Book builds | **yes** — 575 pages, all checks green |
| Phase | **A (source audit) nearly complete; B, D, E, F, G not started; C partially done** |

A new edition of the book has been opened. Nothing has been *written* yet — no chapter prose has
changed. What exists is a pinned baseline, a large body of verified source research, reproducible
verification tooling, and one completed structural safety change.

## What was done this session

1. **Pinned the source baseline.** CNA `develop` and `origin/develop` are identical at
   `7a64362e`; all eleven sibling repository HEADs are recorded in `PLAN.md` §2. CNA and every
   sibling were treated as **read-only** throughout — no build, checkout, reset, commit or fix.
2. **Ran ten parallel read-only research passes.** Seven delivered; **four are on disk** in
   `audit/` at handoff, three more were still being written out, and three were still
   researching (see "Do this next").
3. **Built `AUDIT.md`** — the canonical audit matrix, contradiction log, and a register of CNA
   defects found but deliberately not fixed here.
4. **Added verification tooling.** `tools/verify-book.sh` runs build + reference/label/index/
   stale-term/whitespace checks in one pass; `tools/render-pages.sh FIRST LAST` drives the visual
   PNG pass.
5. **Migrated all 112 hard-coded chapter references to `\ref{}`.** Two styles existed
   (`Chapter~N`, 84; `Ch.N`, 28). Every occurrence was inspected; all were internal
   cross-references, so all were converted. This had to happen *before* any restructuring.
6. **Archived the old `PLAN.md`/`NEXT.md`** and opened the new-edition plan.

### One methodological result worth carrying forward

The first conversion pass emitted `\\ref` instead of `\ref`. LaTeX renders that as a line break
followed by the literal text `refch:audio-system`. It produced **no error, no warning, and no
undefined reference** — `make book` succeeded and both grep checks passed clean. It was found
only by rendering Appendix E to PNG and reading the page. `tools/verify-book.sh` now tests for
that exact shape. **Treat a green log as necessary and not sufficient, every time.**

## Do this next

1. **Collect the six outstanding research reports.** Each agent was instructed to write its own
   report into `audit/`. **On disk at handoff:** `architecture-build.md`, `renderer-catalog.md`,
   `content-xnb-cnj.md`, `3d-gltf-cnj.md`. **Delivered to the coordinator and being written out
   when the session stopped** (their findings are already summarised in `AUDIT.md` §4, so nothing
   load-bearing is lost even if the file never appeared):
   - `audit/graphics-core-effects.md`
   - `audit/testing-verification.md`
   - `audit/sibling-libraries.md`

   **Still researching, nothing delivered:**
   - `audit/input-audio-net-services.md` — input, devices, audio, media, net, GamerServices,
     Avatar, storage
   - `audit/platforms.md` — Linux/Windows/Wine/Proton/Emscripten/Android/macOS state matrix
   - `audit/framework-core-math.md` — Game lifecycle ordering, GraphicsDeviceManager, math types

   For any missing file the research must be re-commissioned; each brief is reconstructable from
   `PLAN.md` §3.1.

2. **Commission the per-renderer draw-path divergence matrix** (`PLAN.md` §3.2). This is the one
   deliberately-identified gap. It matters because the effect-aware draw defaults **silently
   degrade rather than fail**, so a renderer that never implemented `DrawPrimitivesEx` renders an
   untextured, unlit picture with no error. Part IV cannot be written honestly without it.

3. **Then finish Phase B — the new Table of Contents.** Part IV is settled (`PLAN.md` §4: eight
   renderer clusters partitioning all 46 identities, arithmetic checked). The rest is provisional
   and blocked only on the three reports above.

4. **Then Phase C proper:** create/move/split chapter files, establish labels, update `main.tex`,
   rename `part4-backends/`, and run the terminology sweep (`backend` → `renderer` where it means
   a renderer; `NOXNA` → `CNAEXT`; the two-volume wording).

## Do not do these

- **Do not start writing chapter prose before the TOC is settled.** The task's own instruction:
  do not spend hundreds of pages polishing a structure that is about to change.
- **Do not modify CNA or any sibling repository.** Defects found are recorded in `AUDIT.md` §5.1
  for upstream reporting, never patched from here.
- **Do not trust the old `PLAN-ARCHIVE`/`NEXT-ARCHIVE` per-chapter page targets or their
  "PDF-verified clean" labels.** They were verified against a CNA state that no longer exists.
- **Do not quote any count from a CNA `docs/*.md` or `plan_*.md`.** See `PLAN.md` §5.

## Verification status

Everything committed this session is verified:

- `make -C latex book` succeeds; **575 pages**.
- makeindex: 2,367 entries accepted, 0 rejected, 0 warnings.
- No undefined references, no undefined control sequences, no duplicate labels, no doubled-
  backslash `\ref`, no hard-coded chapter numbers.
- `git diff --check` clean.
- Visual pass: Appendix E physical pages 559–560 rendered and read; both reference styles render
  as correct hyperlinked chapter numbers.

**No chapter content has been written, so no chapter is pending verification.** The next batch of
actual writing will be the first thing that needs one.

## Open items

- **Environment:** TeX Live was absent at session start and was installed mid-session at the
  owner's direction. `latexmk`, `pdflatex`, `makeindex`, `pdftoppm` are all present and working.
- **No blocking questions for the project owner.**
- **Push status:** committed and pushed to `origin/next` at the owner's explicit instruction.

## The short version, if you read nothing else

The book describes eleven rendering backends. CNA has forty-six renderers. It calls them
"backends"; CNA now uses that word for something else entirely. Its ASCII chapter documents a
renderer that was deleted, its DX3 chapter documents a renderer that was renamed while a
*different* renderer took the old name, its shader chapter is built on a premise that is now
roughly one-quarter true, every `cmake` command in it fails, and it has no idea that glTF, CNJ,
or the module system exist. The research to fix all of that is done and on disk. The writing has
not started.
