# Next session — start here

Read this file, then `PLAN.md`, then `AUDIT.md`. The raw per-area research evidence is in
`audit/` (ten files). CNA-side defects found along the way are in `cnabugs.md`. The previous
edition's plan and handoff are archived as `PLAN-ARCHIVE-2026-07-26.md` and
`NEXT-ARCHIVE-2026-07-26.md` — history, not instructions.

## State at handoff (2026-08-11)

| | |
|---|---|
| cna-bible branch | `next`; local commits are ahead of `origin/next` (push requires explicit external-publication approval) |
| CNA pinned SHA | `7a64362efef4119bf880459ef1704fb2c52199e2` (`develop` == `origin/develop`, 2026-08-11) |
| Book builds | **yes** — 645 pages, all automated and visual checks green |
| Phase | **A and B complete. Phase C structure is complete and verified; terminology/path sweep remains.** No chapter prose has been substantively rewritten. |

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
8. **Phase B is complete.** `PLAN.md` §4 settles a 12-Part / 79-chapter / 8-appendix TOC, gives
   every chapter a depth band and evidence remit, and maps every old Ch.01–49 to its new home.
   Content, 3D/glTF and Testing/Verification now have dedicated Parts; Math and Devices split;
   sharp-runtime expands to six chapters; the free-direct library material merges into one
   chapter distinct from CNA's `FREEDIRECT` renderer treatment.
9. **Phase C's structural half is complete and verified.** The filesystem and `main.tex` now
   contain exactly 12 Parts, Ch.01–79 and Appendices A–H. Every old label survived; every new
   chapter has a semantic label; all old prose remains compiled. Split/new chapters are honest
   structural placeholders. The three old Vulkan/WebGPU/SDL GPU chapters are preserved together
   under the new native-modern chapter until Part IV is rewritten.

## Do this next

**1. Finish Phase C with the edition-wide terminology and path sweep.** Use implementation context, not a
blind word replacement: `backend` remains correct for input/devices/net platform backends but is
wrong for graphics renderers. Mechanically safe identifier/path replacements include
`IGraphicsBackend` → `IGraphicsRenderer`, `GraphicsBackendType` → `GraphicsRendererType`,
`CNA_GRAPHICS_BACKEND` → `CNA_GRAPHICS_RENDERER`, `NOXNA` → `CNAEXT`, and stale root
`src/…`/`include/…` paths → `modules/<owner>/…`; verify each against the pinned source.

**2. Before writing Part IV specifically: complete the per-renderer draw-path divergence
matrix** (`PLAN.md` §3.2). This is the one deliberately-identified research gap. It matters
because the effect-aware draw defaults **silently degrade rather than fail** — a renderer that
never implemented `DrawPrimitivesEx` renders an untextured, unlit picture with no error, and
nothing currently records which renderers those are.

**3. Then Phase D:** write chapters in batches, per the project's batched-verification
methodology (`CLAUDE.md`) — write across ~8–10 chapters, then one consolidated `make book` +
visual pass, not one verification per chapter.

## Do not do these

- **Do not mix structural migration with substantive rewriting.** Complete and verify the file,
  label, `main.tex`, terminology and source-path migration first; Phase D owns prose changes.
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

Everything through the Phase C structural checkpoint is verified:

- `make -C latex book` succeeds; **645 pages**.
- makeindex: 2,367 entries accepted, 0 rejected, 0 warnings.
- No undefined references, no undefined control sequences, no duplicate labels, no doubled-
  backslash `\ref`, no hard-coded chapter numbers.
- `git diff --check` clean.
- Structural inventory: 12 Parts, 79 sequential chapter inputs/files, 8 appendix inputs/files;
  zero missing inputs, lost old labels, duplicate labels or hard-coded chapter numbers.
- Visual pass: all 645 pages rendered into 26 contact sheets and inspected; affected title pages
  opened at full size. One Ch.18 overflow and fifteen poor mid-word title breaks were fixed and
  the changed pages re-rendered clean. WebGPU/SDL GPU legacy-fragment joins were inspected at
  physical pages 252 and 259.

**No chapter prose has been substantively rewritten, so no writing batch is pending PDF
verification.** Phase C's structure is already fully verified. After the terminology/path sweep,
run one further consolidated build and targeted visual pass before Phase D starts; after that,
follow the normal ~8–10 chapter batch rule.

## Environment notes

- **TeX Live** was absent at session start and was installed mid-session at the owner's
  direction. `latexmk`, `pdflatex`, `makeindex`, `pdftoppm` are all present and confirmed working.
- **No blocking questions for the project owner** at this time.
- Push status: local checkpoints are committed, but publishing them to `origin/next` was rejected
  by the external-action approval gate. Do not work around it; push only after explicit approval.

## The short version, if you read nothing else

The book describes eleven rendering backends; CNA has forty-six renderers under a different name
for the concept ("backend" now means something else — input/devices/net platform services). Its
ASCII chapter documents a renderer that was deleted; its DX3 chapter documents a renderer that
was renamed while a *different* renderer took the old name; its shader chapter's premise is now
about a quarter true; every `cmake` command in it fails to configure; and it has no idea that
glTF, CNJ, or the `modules/` physical-module system exist. Ten parallel research passes have
fully re-audited the source against the pinned SHA and every finding is written up in `audit/`
with `path:line` citations. Phase B turned those findings into a settled 12-Part, 79-chapter
structure; Phase C has put that structure on disk and verified all 645 pages. The remaining
pre-writing work is the context-sensitive terminology/path sweep and the renderer draw-path
matrix. Prose rewriting begins only after those steps build and render cleanly.
