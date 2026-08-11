# Next session — start here

Read this file, then `PLAN.md`, then `AUDIT.md`. The raw per-area research evidence is in
`audit/` (ten files). CNA-side defects found along the way are in `cnabugs.md`. The previous
edition's plan and handoff are archived as `PLAN-ARCHIVE-2026-07-26.md` and
`NEXT-ARCHIVE-2026-07-26.md` — history, not instructions.

## State at handoff (2026-08-11)

| | |
|---|---|
| cna-bible branch | `next`, pushed to `origin/next` |
| CNA pinned SHA | `7a64362efef4119bf880459ef1704fb2c52199e2` (`develop` == `origin/develop`, 2026-08-11) |
| Book builds | **yes** — 575 pages, all checks green, nothing rewritten yet |
| Phase | **A (source audit) is complete — 10 of 10 areas.** B (new TOC) not started. No chapter prose has changed. |

## What is done

1. **Source baseline pinned**, read-only throughout — CNA and every sibling repository were only
   ever read, never built, checked out, reset, or fixed. `PLAN.md` §2 has all eleven sibling HEADs.
2. **Phase A source audit is complete.** All ten research areas delivered full reports, now on
   disk in `audit/`:
   - `architecture-build.md` — identity, module system, build system, renderer selection
   - `renderer-catalog.md` — all 46 renderer identities, one profile each
   - `graphics-core-effects.md` — GraphicsDevice, resources, state objects, effects, shaders
   - `content-xnb-cnj.md` — ContentManager, XNB container, type readers, CNJ format
   - `3d-gltf-cnj.md` — Model runtime, glTF importer, skinning, the CNJ toolchain
   - `testing-verification.md` — test infrastructure, oracles, CI, the 56-script catalog
   - `input-audio-net-services.md` — input, devices/sensors, audio, media, net, GamerServices,
     Avatar, storage
   - `platforms.md` — Linux/Windows/Wine/Proton/Emscripten/Android/macOS state matrix
   - `sibling-libraries.md` — sharp-runtime, easy-gl, meta-gl, free-direct, free-api
   - `framework-core-math.md` — exact Game lifecycle order, math/core type semantics
3. **`AUDIT.md`** is the curated cross-report matrix and contradiction log. Its §4 has the
   headline conclusions from every area, cited back to the raw reports.
4. **`cnabugs.md`** records 53 genuine CNA-side defects found during the audit, in English, for
   upstream triage. CNA was never patched — this is a record, not a fix.
5. **Verification tooling added.** `tools/verify-book.sh` runs build + reference/label/index/
   stale-term/whitespace checks in one pass; `tools/render-pages.sh FIRST LAST` drives the visual
   PNG pass a log grep cannot replace.
6. **All 112 hard-coded chapter references migrated to `\ref{}`** (two styles: `Chapter~N`,
   `Ch.N`). This had to happen before any restructuring could safely begin.
7. **Part IV (the renderers) is settled** — see `PLAN.md` §4: eight clusters partitioning all 46
   renderer identities exactly (10+4+7+9+6+4+3+3 = 46, checked). No further research needed for
   Part IV; it is ready to draft once Phase C creates the chapter files.

## Do this next

**1. Phase B — finish the new Table of Contents for the rest of the book.**
All research is in. This is a synthesis pass, not a research pass: read `AUDIT.md` §4 and the
"BOOK IMPACT" section of each relevant `audit/*.md` report, then decide the Part/chapter
structure for everything except Part IV. Concretely:
- Content deserves its own Part (currently one 2,247-line chapter spans four separable
  subsystems and has zero glTF coverage) — see `audit/content-xnb-cnj.md` and
  `audit/3d-gltf-cnj.md` BOOK IMPACT sections for two independent, converging proposals.
- Testing/Verification deserves a ~6-chapter Part, including a chapter on *counting discipline*
  (`audit/testing-verification.md` BOOK IMPACT) — this is original, load-bearing material with no
  precedent in the old book.
- Effects/shaders needs retitling and restructuring around CNA's four real answers to `.fx`, not
  around a gap (`audit/graphics-core-effects.md` CONTRADICTIONS + BOOK IMPACT).
- Part V (input/audio/media/net/services) needs the largest single rewrite in the book for
  Ch. 29 (Devices/Sensors) — `CNA_DEVICES` defaults OFF and silently removes half its current
  subject matter — and real corrections to Ch. 31 (Networking) and Ch. 33 (Storage). Full detail
  and a chapter-by-chapter verdict is in `audit/input-audio-net-services.md` §10.
- sharp-runtime likely goes from 3 to 5–6 chapters; free-direct's two chapters (322+65 lines)
  should merge into one ~600-line chapter. See `audit/sibling-libraries.md` §7.
- Framework core (Ch. 06) and math (Ch. 07) both need substantial correction and Ch. 07 should
  split in two — see `audit/framework-core-math.md` BOOK IMPACT, including a real bug
  (`Plane::Transform`, F136 / CNA-BUG-001) the old book's own "numerically verified" claim
  contradicts.

**2. Before writing Part IV specifically: commission the per-renderer draw-path divergence
matrix** (`PLAN.md` §3.2). This is the one deliberately-identified research gap. It matters
because the effect-aware draw defaults **silently degrade rather than fail** — a renderer that
never implemented `DrawPrimitivesEx` renders an untextured, unlit picture with no error, and
nothing currently records which renderers those are.

**3. Then Phase C proper:** create/move/split chapter files per the new TOC, establish semantic
labels, update `main.tex`, rename `part4-backends/`, and run the terminology sweep (`backend` →
`renderer` where it means a renderer; `NOXNA` → `CNAEXT`; the two-volume wording; every stale
`src/…`/`include/…` path → `modules/…`).

**4. Then Phase D:** write chapters in batches, per the project's batched-verification
methodology (`CLAUDE.md`) — write across ~8–10 chapters, then one consolidated `make book` +
visual pass, not one verification per chapter.

## Do not do these

- **Do not start writing chapter prose before Phase B's TOC decisions are made for the Part in
  question.** Part IV is the exception — it is settled and can be drafted now if that is more
  convenient than finishing the rest of the TOC first.
- **Do not modify CNA or any sibling repository.** Defects found are recorded in `cnabugs.md` and
  `AUDIT.md` §5.1 for upstream reporting, never patched from here.
- **Do not trust the old `PLAN-ARCHIVE`/`NEXT-ARCHIVE` per-chapter page targets or their
  "PDF-verified clean" labels.** They were verified against a CNA state that no longer exists.
- **Do not quote any count from a CNA `docs/*.md` or `plan_*.md`.** See `PLAN.md` §5 for the ten
  standing rules this edition follows, including which CNA documents are known-stale and why.
- **Do not treat a green LaTeX log as sufficient verification.** Proven this session: a
  doubled-backslash `\ref` passed every automated check (no error, no warning, no undefined
  reference) and was caught only by rendering the page and reading it.

## Verification status

Everything committed this session is verified:

- `make -C latex book` succeeds; **575 pages**.
- makeindex: 2,367 entries accepted, 0 rejected, 0 warnings.
- No undefined references, no undefined control sequences, no duplicate labels, no doubled-
  backslash `\ref`, no hard-coded chapter numbers.
- `git diff --check` clean.
- Visual pass: Appendix E physical pages 559–560 rendered and read; both chapter-reference styles
  render as correct hyperlinked chapter numbers.

**No chapter content has been rewritten, so no chapter is pending PDF verification.** The next
batch of actual writing will be the first thing that needs one — follow the batched-verification
rule in `CLAUDE.md` (write ~8–10 chapters, then one consolidated build + visual pass).

## Environment notes

- **TeX Live** was absent at session start and was installed mid-session at the owner's
  direction. `latexmk`, `pdflatex`, `makeindex`, `pdftoppm` are all present and confirmed working.
- **No blocking questions for the project owner** at this time.
- Push status: everything through this handoff is committed and pushed to `origin/next`.

## The short version, if you read nothing else

The book describes eleven rendering backends; CNA has forty-six renderers under a different name
for the concept ("backend" now means something else — input/devices/net platform services). Its
ASCII chapter documents a renderer that was deleted; its DX3 chapter documents a renderer that
was renamed while a *different* renderer took the old name; its shader chapter's premise is now
about a quarter true; every `cmake` command in it fails to configure; and it has no idea that
glTF, CNJ, or the `modules/` physical-module system exist. Ten parallel research passes have
fully re-audited the source against the pinned SHA and every finding is written up in `audit/`
with `path:line` citations. The synthesis into a new Table of Contents (Phase B) is the next
piece of work — Part IV is already done as a worked example of what that synthesis looks like.
