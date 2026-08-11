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
| Book builds | **yes** — 661 pages, all automated checks green; Phase D batches 1–2 visually verified |
| Phase | **A, B, and C complete. Phase D in progress:** two verified batches, Chapters 19–36, are complete. |

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
4. **`cnabugs.md`** records 54 genuine CNA-side defects found during the audit, in English, for
   upstream triage. CNA was never patched — this is a record, not a fix.
5. **Verification tooling added.** `tools/verify-book.sh` runs build + reference/label/index/
   stale-term/whitespace checks in one pass; `tools/render-pages.sh FIRST LAST` drives the visual
   PNG pass a log grep cannot replace.
6. **All 112 hard-coded chapter references migrated to `\ref{}`** (two styles: `Chapter~N`,
   `Ch.N`). This had to happen before any restructuring could safely begin.
7. **Part IV's taxonomy and draw-path evidence are settled** — see `PLAN.md` §4 and
   `audit/renderer-draw-path-matrix.md`: eight clusters partition all 46 renderer identities
   exactly (10+4+7+9+6+4+3+3 = 46, checked), and all 42 implementation families now have
   effect-aware draw, RT2D, MRT and occlusion-query behavior mapped from source.
8. **Phase B is complete.** `PLAN.md` §4 settles a 12-Part / 79-chapter / 8-appendix TOC, gives
   every chapter a depth band and evidence remit, and maps every old Ch.01–49 to its new home.
   Content, 3D/glTF and Testing/Verification now have dedicated Parts; Math and Devices split;
   sharp-runtime expands to six chapters; the free-direct library material merges into one
   chapter distinct from CNA's `FREEDIRECT` renderer treatment.
9. **Phase C is complete and verified.** The filesystem and `main.tex` now
   contain exactly 12 Parts, Ch.01–79 and Appendices A–H. Every old label survived; every new
   chapter has a semantic label; all old prose remains compiled. Chapters not yet reached by
   Phase D remain honest structural placeholders. The old Vulkan/WebGPU/SDL GPU material was
   preserved together under the native-modern chapter and was integrated in Phase D batch 1.
10. **The edition-wide terminology and path migration is complete.** The live manuscript uses
    current renderer/CNAEXT identifiers and selectors, distinguishes `FREEDIRECT` from
    `DIRECTX3`, leads with the authoritative **46 identities / 42 implementation families**
    registry, keeps “backend” only for real service/platform backends, and cites CNA files under
    their `modules/<owner>/…` paths. Every explicit module file citation was existence-checked
    against the pin. The sweep also corrected Storage's current boundary: five `StorageDevice`
    tests exist; `StorageContainer` remains untested.
11. **The renderer draw-path divergence matrix is complete.** Thirty-one families override both
    ordinary `Draw*Ex` methods and eleven inherit both; DIRECTX10 is the sole unconditional
    inherited colored downgrade. Four override families retain conditional colored tails.
    RT2D/MRT/occlusion behavior is mapped separately from capability claims, exposing the further
    default-true contradictions recorded as CNA-BUG-054.
12. **Phase D batch 1 is complete and verified.** Chapters 19–27 now cover the renderer
    contract and selection, all ten OpenGL identities, the four native-modern identities, all
    seven abstraction-layer identities, and the nine historical DirectX/Glide identities.
    The consolidated book is 661 pages; physical pages 194–303 were rendered and inspected.
13. **Phase D batch 2 is complete and verified.** Chapters 28–32 finish all renderer clusters;
    Chapters 33–36 split the ContentManager façade, XNB container, XNB object graph, and CNJ
    format at their real implementation seams. Physical pages 304–391 were all inspected.

## Do this next

**Continue Phase D with Chapters 37–45** as the next nine-chapter batch: content robustness;
the Model runtime; glTF import, packing, skinning, CNJ toolchain and conformance; then Input and
Audio. Read `audit/content-xnb-cnj.md`, `audit/3d-gltf-cnj.md`, and
`audit/input-audio-net-services.md` before writing, then run one consolidated build and visual
pass.

## Do not do these

- **Do not reopen Phase C casually.** Structural, label, terminology, selector, and path migration
  is complete; Phase D owns substantive prose changes.
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

Everything through Phase D batch 2 is verified:

- `make -C latex book` succeeds; **661 pages**.
- makeindex: 2,345 entries accepted, 0 rejected, 0 warnings.
- No undefined references, no undefined control sequences, no duplicate labels, no doubled-
  backslash `\ref`, no hard-coded chapter numbers.
- `git diff --check` clean.
- Structural inventory: 12 Parts, 79 sequential chapter inputs/files, 8 appendix inputs/files;
  zero missing inputs, lost old labels, duplicate labels or hard-coded chapter numbers.
- Terminology/path pass: no obsolete CNA identifier, option, live selector assignment, or legacy
  renderer macro remains; all explicit `modules/...` file citations exist at the pin.
- Phase C's full 645-page pass remains green. Phase D batch 1 additionally rendered and reviewed
  every touched physical page, 194–303, as 11 contact sheets.
- Phase D batch 2 rendered and reviewed every touched physical page, 304–391, as 9 contact sheets.

**No completed writing batch is pending PDF verification.** Continue with Chapters 37–45 and
follow the normal ~8–10 chapter batch rule.

## Environment notes

- **TeX Live** was absent at session start and was installed mid-session at the owner's
  direction. `latexmk`, `pdflatex`, `makeindex`, `pdftoppm` are all present and confirmed working.
- **No blocking questions for the project owner** at this time.
- Push status: local checkpoints are committed, but publishing them to `origin/next` was rejected
  by the external-action approval gate. Do not work around it; push only after explicit approval.

## The short version, if you read nothing else

Ten source-audit reports and the 42-family draw-path matrix are complete against pinned CNA
`7a64362e`. Phase B settled a 12-Part, 79-chapter, 8-appendix edition; Phase C put it on disk,
migrated terminology, selectors and paths, and verified all 645 pages. Phase D batches 1–2
rewrote Chapters 19–36 and verified the resulting 661-page book; Chapters 37–45 are next.
