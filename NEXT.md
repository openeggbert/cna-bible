# Next session — start here

Read this file, then `PLAN.md`, then `AUDIT.md`. The raw per-area research evidence is in
`audit/` (ten files). CNA-side defects found along the way are in `cnabugs.md`. The previous
edition's plan and handoff are archived as `PLAN-ARCHIVE-2026-07-26.md` and
`NEXT-ARCHIVE-2026-07-26.md` — history, not instructions.

## State at handoff (2026-08-12)

| | |
|---|---|
| cna-bible branch | `next`; local commits are ahead of `origin/next` (push requires explicit external-publication approval) |
| CNA pinned SHA | `7a64362efef4119bf880459ef1704fb2c52199e2` (`develop` == `origin/develop`, 2026-08-11) |
| Book builds | **yes** — 705 pages, all automated checks green; all completed Phase D/E writing and three Phase F corrective batches are visually verified |
| Phase | **A–E complete; F in progress:** Chapters 19–79 and Appendices A–H are complete. Phase F has filled omitted Chapters 8–11 and 18, corrected early graphics/lifecycle drift, and continues the whole-book consistency sweep. |

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
   chapter has a semantic label; all old prose remained compiled at the migration checkpoint.
   The old Vulkan/WebGPU/SDL GPU material was preserved together under the native-modern chapter
   and was integrated in Phase D batch 1.
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
14. **Phase D batch 3 is complete and verified.** Chapters 37–45 now cover content robustness,
    all four model routes, the shared glTF importer, stride ABI, skinning/animation, CNJ toolchain,
    the five implemented oracle layers, current Input facts and current SDL3_mixer/XACT behavior.
    The consolidated book is 675 pages; physical pages 392–455 were all inspected.
15. **Phase D batch 4 is complete and verified.** Chapters 46–54 now cover the Media layer's
    real codec and ownership boundaries; SDL/Android sensor delivery; the optional CNA.Devices
    host seam; local GamerServices identity and persistence; Storage containment asymmetry;
    session delivery, discovery and hostile-input behavior; Avatar's inert API and rendered EXT
    path; sharp-runtime's honest object model; and its current 44-component CNA consumption seam.
    The consolidated book is 683 pages. Physical pages 456–523 were inspected as eight full
    contact sheets plus a tail sheet; component tables, link closures and long include paths were
    checked at full size. That zoomed pass found and corrected two overflowing include paths in
    Chapter 54, after which the full build and affected-page render were repeated.
16. **Phase D batch 5 is complete and verified.** Chapters 55–63 now separate sharp-runtime's
    actual C++ object model, include/component map, permanent-deviation taxonomy and layered
    verification apparatus; give meta-gl equal treatment with easy-gl; expand free-direct/free-api
    around the 56/23/16 status census and `fopen` quarantine; and establish the platform evidence
    vector, MinGW/SDL/DLL cross-build chain, i686 wall, six Wine prefixes and runtime-engagement
    gates. The consolidated book is 691 pages. Every touched physical page 523–572 plus the
    Chapter 64 boundary at 573 was inspected as six full contact sheets plus a tail sheet. Full-
    size inspection found one overlapping namespace/component table on page 528; manual line
    breaks fixed it, the full build was rerun, and pages 528–529 were re-rendered cleanly.
17. **Phase D batch 6 is complete and verified.** Chapters 64–72 now separate Web translation,
    host-owned main-loop lifetime and per-renderer browser evidence; bound Android claims to the
    two recorded emulator campaigns and keep adapted Metal/iOS as explicit non-claims; and rebuild
    the testing Part around CnaTests composition, reproducible counting, oracle authority,
    hostile-runtime engagement and executable discipline gates. The consolidated book is 689
    pages. Every touched physical page 573–606 plus the Chapter 73 boundary at 607 was rendered
    and inspected as nine contact sheets. The Web evidence and counting tables, long literals,
    and gate checklists were also read at full size; no visual correction was required.
18. **Phase D batch 7 is complete and verified.** Chapters 73–79 now distinguish workflow
    presence from executed CI; replace the stale migration guide with a current evidence ladder;
    preserve the source-grounded Blupi case study while translating obsolete selectors; audit
    xna4-spec as a 544-entry documentation corpus rather than CNA's live gate; reconcile the
    samples/examples catalogs; derive durable project counts from their sources; and close with
    a roadmap grounded in the 54 static CNA findings. The consolidated book is 685 pages. Every
    touched physical page 607–640 through the Appendix A boundary was rendered and inspected;
    the performance table, long headings, lists and database query were checked at full size.
    No visual correction was required.
19. **Phase E is complete and verified.** Appendices A–F are now bounded lookup surfaces derived
    from pinned code and the completed chapters rather than stale exhaustive catalogs. Appendix B
    carries the 46-identity / 42-family registry and evidence matrix; D maps the pinned repository,
    module and renderer-family graph; E separates all three CNAEXT mechanisms. Former placeholder
    Appendices G/H now define the evidence hierarchy and the importer/runtime/oracle glTF matrix.
    The consolidated book remains 685 pages. Physical pages 641–678 were inspected as five contact
    sheets, dense tables were read at full size, five visual collisions were fixed and re-rendered,
    and the final index tail on physical page 685 was also checked.
20. **Phase F corrective batch 1 is complete and verified.** The first whole-book sweep exposed
    five chapters that had labels and titles but no body: Chapters 8–11 and 18. They now cover
    geometry/color/value layout, physical modules, boundary enforcement, dependency/tooling
    semantics, and vertex streams/capabilities against the pinned source. The same batch removed
    stale universal 6,171-test claims and residual graphics uses of “backend.” The consolidated
    book is 699 pages; physical pages 107–126 and 203–210 plus thirteen isolated correction pages
    were read, all detected layout collisions were fixed, and the final build is clean.
21. **Phase F corrective batch 2 is complete and verified.** Chapters 1–4, 12–15, 23–24, 45
    and 51 plus Appendix C now distinguish translation from binary compatibility, recorded test
    campaigns from current totals, and historical defects from pinned behavior. The batch corrected
    submodule commands, CI scope, `CNA_CNAEXT`, GraphicsDevice reset/disposal forwarding,
    SpriteBatch coordinate quantization, Skia's 26/27 texture-format exception, closed stock-effect
    gaps, the two distinct audio crash signatures, and the fixed NetworkSession action leak. The
    verification script's manual-term scan now uses whole-word matching. The consolidated book is
    703 pages; all 31 touched physical pages were rendered and read in six contact sheets with no
    visual defect.
22. **Phase F corrective batch 3 is complete and verified.** Chapters 5–7 now teach the live
    base-loop contract instead of the stale README pattern: examples call base `Update`/`Draw`,
    presentation occurs once in `EndDraw`, explicit disposal reaches `Game::UnloadContent`, and
    the desktop/Emscripten timing split is tabulated. The math reference now states opposite
    matrix/quaternion composition orders, `[0,1]` depth, copy-only `ToColumnMajor`, the live
    aliased-transpose defect in `Plane::Transform`, 141/140/139 Color counts, non-four-byte Color
    layout, degenerate-input behavior, exception splits, and three marker-free geometry gaps.
    The consolidated book is 705 pages; every physical page 55–108 was rendered and read, with no
    clipping, collision, broken float, or table defect.

## Do this next

**Continue Phase F with the whole-book consistency sweep.** Search all remaining compiled chapters and
appendices for factual drift, duplicate or contradictory explanations, inconsistent evidence
language, stale counts and pins, weak transitions, glossary/index gaps, and cross-reference
problems. Resolve findings against pinned source rather than archived prose. Rebuild after each
bounded correction batch; finish with an edition-wide visual and automated pass before Phase G.

## Do not do these

- **Do not reopen Phase C casually.** Structural, label, terminology, selector, and path migration
  is complete; Phase F owns only consistency corrections that are justified by current evidence.
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

Everything through Phase E and Phase F corrective batch 3 is verified:

- `make -C latex book` succeeds; **705 pages**.
- makeindex: 2,173 entries accepted, 0 rejected, 0 warnings.
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
- Phase D batch 3 rendered and reviewed every touched physical page, 392–455, as 8 contact sheets;
  the stride table, defect ledger, and audio equations were also inspected at full size.
- Phase D batch 4 rendered and reviewed every touched physical page, 456–523, as 8 contact sheets
  plus a tail sheet; high-risk component tables, link closures and include paths were inspected
  at full size, and the one detected overflow was fixed and re-rendered cleanly.
- Phase D batch 5 rendered and reviewed every touched physical page, 523–572, as 6 contact sheets
  plus a tail sheet through the Chapter 64 boundary at 573; high-risk namespace, status and Wine
  runtime tables were inspected at full size, and the one detected overlap was fixed, rebuilt and
  re-rendered cleanly.
- Phase D batch 6 rendered and reviewed every touched physical page, 573–606, as 9 contact sheets
  through the Chapter 73 boundary at 607; the two tables, long literals and gate checklist were
  inspected at full size and were clean on the first visual pass.
- Phase D batch 7 rendered and reviewed every touched physical page, 607–640, as 4 contact sheets
  through the Appendix A boundary at 641; the performance table, long headings, lists and query
  literals were inspected at full size and were clean on the first visual pass.
- Phase E rendered and reviewed physical pages 641–678 as 5 contact sheets; high-risk renderer,
  repository, CNAEXT, ecosystem, verification and glTF tables were inspected full-size. Five
  collisions were fixed, rebuilt and re-rendered cleanly. Physical page 685 closed the index tail.
- Phase F corrective batch 1 rendered and reviewed physical pages 107–126 and 203–210 plus pages
  46, 309, 349, 432, 444, 473, 514, 562, 591–592, 617–618 and 628. The Chapter 8 table and Chapter
  18 interface identifiers were inspected full-size; detected overflows were fixed and the full
  verification and visual pass repeated cleanly.
- Phase F corrective batch 2 rendered and reviewed physical pages 31–35, 38, 49–51, 53, 128,
  130, 133–134, 157, 167, 169, 175, 177, 181–182, 186–188, 269, 271, 278, 298, 473, 513 and 669.
  Chapter openers, source-note boxes, code listings, long identifiers and the glossary were read
  in six contact sheets; all were clean on the first visual pass.
- Phase F corrective batch 3 rendered and reviewed every physical page 55–108 across Chapters
  5–7. The four evolving game examples, Emscripten divergence table, composition/depth contracts,
  Plane warning, Color/MathHelper reference, geometry gaps, long code listings and chapter
  boundaries were read in fifteen contact sheets; all were clean on the first visual pass.

**No completed writing batch is pending PDF verification.** Continue with the Phase F whole-book
consistency sweep, then perform Phase G final verification.

## Environment notes

- **TeX Live** was absent at session start and was installed mid-session at the owner's
  direction. `latexmk`, `pdflatex`, `makeindex`, `pdftoppm` are all present and confirmed working.
- **No blocking questions for the project owner** at this time.
- Push status: local checkpoints are committed, but publishing them to `origin/next` was rejected
  by the external-action approval gate. Do not work around it; push only after explicit approval.

## The short version, if you read nothing else

Ten source-audit reports and the 42-family draw-path matrix are complete against pinned CNA
`7a64362e`. Phase B settled a 12-Part, 79-chapter, 8-appendix edition; Phase C put it on disk,
migrated terminology, selectors and paths, and verified all 645 pages. Phase D batches 1–7
rewrote Chapters 19–79; Phase E rebuilt Appendices A–H. Phase F is now active: two verified
batches filled omitted Chapters 8–11 and 18, removed stale totals/terminology, and reconciled the
early graphics, lifecycle and math narrative with pinned source. The book is 705 pages; continue the
remaining whole-book consistency sweep.
