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
| Book builds | **yes** — 709 pages, all automated and release-artifact checks green; every physical page has passed the final visual review |
| Phase | **A–G complete.** The source audit, restructuring, writing, appendices, whole-book consistency sweep and final artifact verification are closed against the pinned source. |

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
23. **Phase F corrective batch 4 is complete and verified.** Chapter 17 now separates CNA's four
    real shader strategies instead of claiming MojoShader is absent: renderer-owned stock
    reimplementations, D3D9 recompilation of Microsoft sources (61/66 matching instruction
    streams), FNA3D execution of six vendored stock `.fxb` blobs through MojoShader, and the
    renderer-specific `ShaderEffect` route. The remaining boundary is stated as arbitrary user
    bytecode plus general parameter plumbing. Chapters 2 and 17 no longer present the stale
    “23 of 86” sample ratio as a current measurement; they use the pinned 153-entry catalog and
    its dated-evidence warning. The consolidated book is 707 pages; physical page 42 and every
    Chapter 17 page 200–208 were rendered and read, including full-size checks of the new section
    sequence and long identifiers, with no visual defect.
24. **Phase F corrective batch 5 is complete and verified.** Chapters 16 and 18 now match the live
    state/stream bridge: `BlendWriteState` forwards four color masks plus the state-object sample
    mask; the separate device sample mask and rasterizer MSAA switch remain CPU-only; sampler mip
    controls have a four-renderer override matrix rather than being universally absent;
    `SpriteBatch::Begin` submits rasterizer state again; and DepthStencilState has three real
    presets with only five of eight comparison modes covered by the named selection test. Vertex
    declarations now document the zero-stride default-constructor exception and semantic-pair
    composition across streams. Capability prose adds WebGPU/BGFX custom-effect false positives
    and the truthful closed-stock FNA3D contrast. The book remains 707 pages; every physical page
    191–200 and 209–216 was rendered and read. A full-size pass found one overflowing
    `DepthBuffer*` run on page 195; it was rebroken, rebuilt, and re-rendered cleanly.
25. **Phase F corrective batch 6 is complete and verified.** Chapters 19 and 22 now match the
    post-audit renderer contract rather than their pre-remediation snapshots. The shared vertex
    bridge carries complete declaration/slot/stride/offset/frequency tuples through all three draw
    routes, validates every stream, and gates same-rate multiplicity; the instancing account now
    includes Magnum, native and replicated divisor mechanisms, explicit refusals, and the remaining
    Headless/SDL GPU capability false positives. Singular/plural vertex bindings and
    `SpriteBatch::Begin` rasterizer submission are current. EasyGL prose now distinguishes its
    resolved MRT lifetime, wireframe, fog, colour-mask, mip-storage and SpriteBatch viewport work
    from the real base-vertex, RGBA8/recovery, effect-unbind and 16-bit batch boundaries. The book
    remains 707 pages; physical pages 235–239, 248–250 and 262–270 were rendered and read, with the
    instancing table, long identifiers and `SetDataRaw` listing inspected full-size and clean.
26. **Phase F corrective batch 7 is complete and verified.** Chapters 12, 14, 16, 19, 23–25
    and the SDL_GPU/WebGPU renderer fragments now agree on the normalized 2D/cube render-target
    descriptor, shared `DiscardContents` predicate, aspect-selective ordered clears and deferred
    per-command viewport/scissor state. Vulkan, BGFX, WebGPU and SDL_GPU accounts describe their
    current segmented replay rather than the superseded last-value model. Renderer-specific
    corrections close stale SDL_GPU validation, lifetime, bias, anisotropy, mip and lazy-
    backbuffer-readback gaps; record BGFX's one-plus-one instancing transport and non-GLSL matrix-
    profile fault; close WebGPU's target-size and one-attachment blend gaps; and bound Sokol
    Texture3D support to exact CPU-side resource transfer rather than GPU volume sampling.
    Chapters 26–27 were audited against the same pin and required no correction. The book remains
    707 pages; all 31 touched physical pages were rendered and read, with dense matrices and
    representative WebGPU, SDL_GPU and BGFX pages inspected full-size and visually clean.
27. **Phase F corrective batch 8 is complete and verified.** Chapters 14, 19 and 28–32 now
    reconcile the remaining renderer families with the post-remediation target/resource contract.
    D3D11/12 public cube finalization, preserve forwarding, exact rendered-face readback and D3D12
    dynamic viewport state are current; D3D12's color-bound/depthless clear nuance and independent
    depth/stencil attachment mask are explicit. GDI is described as an independent renderer that
    privately composes its software 2D core, with standalone stencil and opt-in CPU 4x MSAA;
    Direct2D's workflow presence is separated from missing recorded native release evidence.
    SDL_RENDERER now claims only additive blending, refuses rather than discards unsupported
    cube/volume storage, and retains one blocked Wrap/Mirror decision. SVG_DOM's browser-dependent
    `plus-lighter` path and weaker non-CI evidence are recorded. SOFTWARE's bounded CPU 3D/cube
    surface and its inherited MRT/query overclaims are separated from HEADLESS trace-only behavior.
    Shared readback/upload matrices now encode the boolean complete-or-refuse contract, including
    Skia and LLGL, instead of the obsolete transparent-black no-op. The book remains 707 pages;
    all 49 touched physical pages were rendered and read, and the two cube matrices plus dense
    renderer pages were inspected full-size and visually clean.
28. **Phase F corrective batch 9 is complete and verified.** Chapters 33–35 and 37 now match the
    integrated Content/XNB remediation state. Top-level absolute asset names remain intentionally
    open, while logical XNB references reject rooted/above-root spellings and filesystem-shaped
    Song/Video/CNJ/sidecar paths add weak-canonical containment, extension-candidate revalidation,
    and confined explicit bundles. The XNB limits account now distinguishes the post-read
    type-reader-name bound from ordinary String fields and records live type-name/object recursion
    guards. Texture2D now has exact raw/compressed bytes, checked arithmetic, device-axis and mip-
    topology admission; Texture3D/TextureCube arithmetic, raw cube bytes, Texture3D capability and
    complete-or-refuse uploads are current without erasing their remaining mip/compressed-byte
    gaps. SpriteFont's default-character invariant and regression evidence are also current. The
    book remains 707 pages; all physical pages 337–388 spanning Chapters 33–37 were rendered and
    read, with the dense limits and reader pages inspected full-size and visually clean.
29. **Phase F corrective batch 10 is complete and verified.** Chapters 38–42 now distinguish the
    direct-glTF synthetic scene-node hierarchy, complete CNJ-v2 hierarchy and legacy CNJ-v1
    fallback; document checked collection indices and the real hand-built-model lifetime/draw
    boundaries; and describe the parser's optional version check and unconstrained external-URI
    resolution. The stride ABI now separates its eight-layout diagnostic oracle from the seven
    glTF-emitted layouts, records the unchecked positive-stride and typed-index-pointer gaps, and
    no longer claims unknown strides are rejected. Skinning now states the negative-parent and
    negative-count boundaries, the piecewise cubic-skeletal approximation, and the skin-gated D6
    limitation. CNJ-v2 hierarchy and sidecar validation gaps are explicit. Chapter 43's current
    oracle counts and open D6/D7 evidence were re-audited without correction. The book remains
    707 pages; all physical pages 421–448 across Chapters 38–42 were rendered and read, with dense
    ABI, animation and toolchain pages inspected full-size and visually clean.
30. **Phase F corrective batch 11 is complete and verified.** Chapters 44–48 now match the live
    event-driven input contract, including relative-mouse draining, debug-key visibility, layout
    mapping, touch connectivity and removable text-input subscriptions. Audio now separates the
    fixed same-domain dynamic-buffer regression from the still-open resampling accounting and
    frame-alignment gaps, and its microphone example no longer leaks a process-wide callback.
    Media records Opus as genuinely decodable, gives the raw `Song::FromUri` result an RAII owner,
    and retains the AAC/WMA and native-Windows video-gate defects. Sensor dispatch/lifecycle wording
    now distinguishes the SDL and Android paths and the correct Accelerometer/Gyroscope pair.
    Host devices records 25 installed headers and the uncaught file-dialog/tray callback boundary.
    The book remains 707 pages; all physical pages 455–498 across Chapters 44–48 were rendered and
    read in six contact sheets, with the RAII media example and dense sensor lifecycle page inspected
    full-size and visually clean.
31. **Phase F corrective batch 12 is complete and verified.** Chapters 49–52 now match the live
    service contracts. GamerServices records JSON-double precision loss across persisted 64-bit
    values and the exact inert Guide/dispatcher boundary.
    Storage separates its two unchecked traversal seams from normal container creation and states
    its post-dispose, sharing and exception limits. Networking now documents synchronous joined-
    gamer replay, the real migration retry, all five send options, the broken `PacketReader`
    receive count and byte-versus-float colour mismatch, plus the remaining synthetic-session and
    voice stubs. Avatar now uses the
    actual 19-bone bundled rigs, content/clip APIs, explicit lighting path, exact tint routing and
    renderer evidence boundary. The book remains 707 pages; all physical pages 499–530 were
    rendered and read in eight contact sheets, with dense examples and the two repaired closing
    pages inspected full-size and visually clean.
32. **Phase F corrective batch 13 is complete and verified.** Chapters 53–58 now match the pinned
    sharp-runtime tree rather than older continuation prose. The public surface is 1,032 headers
    plus five private implementation headers; the component graph has 92 direct production edges;
    and the repository now has a nine-configuration selective GitHub Actions matrix plus full and
    Doxygen jobs. Task cancellation, generic continuations, UTF-8 tests, writable-buffer
    `MemoryStream`, atomic `TimeSpan` diagnostics, GC sentinel behavior, delegate tiers, crypto
    scope and platform/compiler boundaries are reconciled to source. The book remains 707 pages;
    all physical pages 533–568 were rendered and read. Full-size review found two prose overflows
    on pages 522–523;
    both were rewritten, rebuilt and re-rendered cleanly.
33. **Phase F corrective batch 14 is complete and verified.** Chapters 59–63 now distinguish
    easy-gl's 19 production meta-gl includes from public headers, the eleven generation-tracked
    integer resources from `Sync`, and built recovery infrastructure from its zero concrete
    adopters. Free-direct's 95 markers are correctly scoped as documentation annotations, CNA's
    FREEDIRECT evidence is 21 registered binaries, and DirectSound pan is recorded as stored but
    not audibly applied. The platform taxonomy, MinGW fallback mismatch and Wine gate evidence
    are also reconciled. The book remains 707 pages; physical pages 569–594 were rendered and
    read. One target-name overflow on printed page 545 was rewritten and re-rendered cleanly.
34. **Phase F corrective batch 15 is complete and verified.** Chapters 61 and 64–67 now separate
    one Android `std::thread` construction site from potentially several bridge workers, five
    web-focused identities from 24 Emscripten-admissible identities, and Web ENet transport from
    its fixed-port/outbound-only/no-discovery topology. Android evidence now follows the primary
    commits: 230 network cases plus 1,831 others passed, and the pre-adaptation APK presented an
    SDL-renderer UI, but no durable artifact or current adapted run exists. Metal's 207 portable
    cases, two native registrations, stale workflow filters and iOS/tvOS non-claim are explicit.
    The book is 709 pages; physical pages 583–610 were rendered and read without visual defect.
35. **Phase F corrective batch 16 is complete and verified.** Chapters 71–73 now distinguish the
    pinned Direct2D Proton lane from moving D3D12 Proton Experimental evidence, and executable
    Windows workflow commands from stale comments. The D3D default build includes `CnaTests`;
    Direct2D runs its filtered unit entry, while GDI's explicit targets exclude the binary. The
    Input label's 541 cases execute five times (2,705 case executions), despite an adjacent stale
    “x3” workflow comment. The book remains 709 pages; physical pages 611–636 across Chapters
    68–73 were rendered and read without visual defect.
36. **Phase F corrective batch 17 is complete and verified.** Chapters 74–79 and related
    ecosystem/sharp-runtime passages now distinguish the Blupi audit's historical performance
    baseline from free-direct's current Release default, 1:1 row-copy fast path and 0.466-ms /
    14.8-times follow-up. `SetPan()` computes but discards stereo gains, while CNA's vendored
    SDL3_mixer retains Timidity and the missing boundary is CNA's public `.mid` mapping and asset
    policy. The sharp-runtime SQLite database is an exact tracked blob at its pin despite matching
    an ignore rule, and Android roadmap language now preserves the historical pre-adaptation frame
    without turning it into current renderer evidence. Chapters 74, 76–78 were mechanically
    re-audited without further correction. The book remains 709 pages; physical pages 39–42,
    563–568 and 637–668 were rendered and read without visual defect.
37. **Phase F corrective batch 18 is complete and verified.** Appendices A–H were re-audited as
    one bounded reference surface. Renderer, module, pin, CNAEXT, service, CI and glTF inventories
    were mechanically checked against the pinned repositories and corrected chapters. Appendix D
    now distinguishes immutable edition pins from a sibling branch that later advanced; Appendix E
    records the reproducible 1,876 whole-token CNAEXT occurrences across 302 headers; Appendix F
    separates Timidity decoder presence from a supported `.mid` Song/Content route; and Appendix G
    states Android installation and renderer-frame presentation as separate required evidence.
    The book remains 709 pages; physical pages 665–702 were rendered and read. Visual review found
    and corrected one malformed monospace paragraph on page 649, then re-rendered it cleanly.
38. **Phase F corrective batch 19 is complete and verified.** Four stale chapter-number claims
    hidden inside code listings were replaced by direct behavioral wording. All twelve Parts now
    have stable labels, and live Part, appendix and local section citations use references rather
    than fixed numbers. The verifier now resolves every source `\ref`, catches singular/plural
    hard-coded structural numbers with spaces or TeX ties, and rejects literal tabs and carriage
    returns. The book remains 709 pages. A whole-PDF rendered-pixel comparison against batch 18
    isolated 53 changed physical pages; every one was rendered and read, with four reflow spans
    checked separately and no visual defect found.
39. **Phase F corrective batch 20 is complete and verified.** The generated index was audited as
    a navigation surface, not merely counted. All 46 renderer selectors, 43 glossary terms and
    the principal platform/testing/porting concepts now have canonical destinations; unique keys
    rose from 517 to 684. Pointer/reference pollution such as `Album*`, `Gamer*` and `Game& game`
    was removed, and the verifier rejects recurrence. A compact `\footnotesize` index retains the
    709-page book size while accepting 2,387 entries with zero rejection/warning. Only physical
    pages 703–709 changed visibly against checkpoint 19; all seven were rendered and read clean.
40. **Phase F corrective batch 21 is complete and verified.** A Poppler coordinate audit found
    44 long technical words crossing the physical A4 edge even though the build succeeded. A
    bounded 2.5em emergency stretch and targeted semantic breakpoints eliminated every crossing
    without increasing the 709-page extent. The running-head allocation was corrected without
    moving the body block. All 709 pages were then rendered and read a second time, clean.
41. **Phase G is complete and verified.** The final artifact is a readable, unencrypted A4 PDF
    with all 27 fonts embedded, subsetted and Unicode-mapped; its outline contains 12 Parts, 79
    chapters and 8 appendices; its 302,443-word searchable text layer stays inside every page.
    The complete verifier and a MuPDF parse/rewrite round trip are green.
42. **The post-G release hardening pass is complete and verified.** An independent clean-tree
    build reproduced the 709-page artifact. Mechanical proofreading removed two duplicated
    function words and regularized two awkward constructions; all four affected pages were
    rendered and read clean. The verifier now checks every page's A4 geometry and rotation, the
    roman-to-arabic page-label transition, all 1,076 unique internal targets, all 1,802 link
    rectangles, the printed-page landing of all 1,065 numbered TOC entries, and complete
    Ghostscript interpretation. It fails early rather than silently reducing coverage when a
    required PDF tool is unavailable. Two clean builds under the same `SOURCE_DATE_EPOCH` are
    byte-identical (SHA-256 `c61e4121d5afd7524cc0c1a8143489279409abc2600b45b01ca409c5388aab32`).
    All 89 chapter, appendix and renderer-fragment sources are compiled exactly once; the PDF has
    only the three reviewed primary-reference HTTPS links and no active or remote-launch actions.

## Do this next

**Preserve the verified edition for owner review and publication.** No writing or verification
batch is pending. Do not silently advance the pinned CNA or sibling baselines; if any source pin
moves, open a new bounded re-audit and treat the present A–G completion as the prior checkpoint.

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

Everything through Phase G is verified:

- `make -C latex book` succeeds; **709 pages**.
- makeindex: 2,387 entries accepted, 0 rejected, 0 warnings.
- No undefined references, no undefined control sequences, no duplicate labels, no doubled-
  backslash `\ref`, no hard-coded chapter/Part/appendix/section numbers, and no literal tabs or
  carriage returns in compiled TeX.
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
- Phase F corrective batch 4 rendered and reviewed physical page 42 plus every Chapter 17 page,
  200–208. The revised catalog paragraph, four-answer sequence, renderer matrix, listings and
  honest summary were read in contact sheets, with high-risk headings and identifiers inspected
  full-size; all were visually clean.
- Phase F corrective batch 5 rendered and reviewed every Chapter 16 and Chapter 18 page, physical
  191–200 and 209–216. State-object lists, worked examples, the capability table, long hook names
  and the Part IV boundary were read at full size. One `DepthBuffer*` overflow was corrected and
  the full verification plus affected-page render repeated cleanly.
- Phase F corrective batch 6 rendered and reviewed physical pages 235–239, 248–250 and 262–270.
  The two-page instancing mechanism table, declaration and binding contracts, viewport/scissor
  tail, EasyGL gap reconciliation, long GL identifiers, `SetDataRaw` listing and test-baseline
  transition were read in contact sheets; pages 237–238, 264 and 269 were also inspected full-size.
  The final rebuild and rerender were visually clean with no overfull box in the LaTeX log.
- Phase F corrective batch 7 rendered and reviewed physical pages 140, 154–155, 177, 197,
  243–248, 274–277, 286–290, 294–301, 307–309 and 312. Five contact sheets covered every
  touched page; matrices on pages 244, 246 and 248 and representative WebGPU, SDL_GPU and BGFX
  pages 286, 289, 295, 299 and 307 were inspected full-size. No clipping, overlap, malformed
  listing, broken heading or other visual defect was found.
- Phase F corrective batch 8 rendered and reviewed physical pages 176, 238–245 and 327–366.
  Three contact sheets covered all 49 pages; readback/transition matrices on pages 240–242 and
  representative renderer pages 327 and 348 were inspected full-size. No clipping, overlap,
  malformed table, broken heading or other visual defect was found.
- Phase F corrective batch 9 rendered and reviewed every physical page 337–388 across Chapters
  33–37. Six contact sheets covered the complete affected chapter span; the initially low-contrast
  pages 373–381 were regenerated in sRGB and read separately. The path-policy prose, limits tables,
  texture-reader sections and robustness summary showed no clipping, overlap, malformed table,
  broken heading or other visual defect.
- Phase F corrective batch 10 rendered and reviewed every physical page 421–448 across Chapters
  38–42. Seven contact sheets covered the complete affected span; pages 437–444 were additionally
  read from the original full-resolution renders after their grayscale contact sheets displayed
  at low contrast. The stride table, pointer-boundary prose, animation equations and CNJ-v2 schema
  discussion showed no clipping, overlap, malformed table, broken heading or other visual defect.
- Phase F corrective batch 11 rendered and reviewed every physical page 455–498 across Chapters
  44–48. Six contact sheets covered the complete affected span; pages 482 and 491 were also read
  full-size. The input/audio listings, RAII media example, sensor lifecycle prose and host-device
  callback boundary showed no clipping, overlap, malformed listing, broken heading or other visual
  defect.
- Phase F corrective batch 12 rendered and reviewed every physical page 499–530 across Chapters
  49–52. Eight contact sheets covered the complete affected span; pages 509, 514, 523 and 528–530
  were also read full-size. The persistence, storage and networking examples, avatar renderer proof,
  repaired Task 13.2 prose and closing comparison table showed no clipping, overlap, malformed
  listing/table, broken heading or other visual defect.
- Phase F corrective batch 13 rendered and reviewed every physical page 533–568 across Chapters
  53–58. Five contact sheets covered the full sharp-runtime span; chapter openers, component and
  namespace tables, task/stream listings, permanent-deviation boundaries and audit totals were
  read at full size. Two overflows on printed pages 522–523 were corrected, the full verification
  rerun, and physical pages 552–554 re-rendered cleanly.
- Phase F corrective batch 14 rendered and reviewed every physical page 569–594 across Chapters
  59–63. Five contact sheets covered the sibling-library and cross-platform span; state-marker,
  runtime-map and long-identifier pages were also read full-size. One target-name overflow on
  printed page 545 was rewritten, the full verification rerun, and physical page 575 re-rendered
  cleanly.
- Phase F corrective batch 15 rendered and reviewed physical pages 583–610 across the updated
  Chapter 61 context and Chapters 64–67. Five contact sheets plus full-size web-networking,
  Android and Metal pages covered the complete affected span through the Part XI boundary. No
  clipping, overlap, malformed table, broken heading or other visual defect was found.
- Phase F corrective batch 16 rendered and reviewed physical pages 611–636 across Chapters
  68–73. Five contact sheets plus full-size hostile-host, discipline and CI pages covered the
  complete Testing and Verification Part through the Part XII boundary. No clipping, overlap,
  malformed table, broken heading or other visual defect was found.
- Phase F corrective batch 17 rendered and reviewed physical pages 39–42, 563–568 and 637–668
  across the corrected ecosystem/sharp-runtime context and Chapters 74–79. Eight contact sheets
  plus full-size database, performance, DirectSound, MIDI and Android-roadmap pages covered the
  affected span. Blank printed pages 626 and 630 are intentional chapter-end recto alignment;
  no clipping, overlap, malformed table, broken heading or other visual defect was found.
- Phase F corrective batch 18 rendered and reviewed every appendix page, physical pages 665–702.
  Seven contact sheets plus full-size pin, CNAEXT, MIDI, Android-evidence and glTF-tail pages
  covered Appendices A–H. A malformed monospace paragraph on physical page 679 (printed 649) was
  corrected, the complete verifier rerun, and pages 679–680 re-rendered cleanly. Physical page 702
  is the intentional blank verso before the index.
- Phase F corrective batch 19 compared rendered pixels for all 709 physical pages against the
  batch-18 checkpoint and isolated 53 visible changes. All 53 were rendered at review resolution
  and read in contact sheets; multi-page reflow spans 99–107, 256–258, 422–431 and page 529 were
  reviewed separately. No clipping, overlap, malformed listing, broken heading or unintended
  blank page was found.
- Phase F corrective batch 20 compared all rendered pages against the batch-19 checkpoint. Only
  the seven index pages 703–709 changed; all seven were rendered at review resolution and read,
  with first, middle and final pages inspected full-size. The enlarged 684-key index has no
  overfull box, clipped entry or sparse tail page.
- Phase F corrective batch 21 rendered and read all 709 pages, then repeated that whole-book
  review after the final typography fixes. The final artifact has zero extracted words outside
  any physical page, no running-head height warning and no unintended blank page.
- Phase G independently checked the PDF container, A4 geometry, encryption state, all 27 font
  rows, the complete 12/79/8 outline, text extraction and a MuPDF parse/rewrite round trip.
- The post-G pass rebuilt from a clean copy of the tracked and intentional untracked sources;
  validated every physical page box, page label, internal destination, link rectangle and
  numbered TOC landing; and independently interpreted all 709 pages with Ghostscript. A negative
  test proved the new multiline repeated-word check, and a deliberately displaced TOC page proved
  the destination audit. A third fixture substituted an unreviewed URI while preserving the
  709-page layout and proved the external-action allowlist. Two clean, independently located
  builds with a fixed source date produced byte-identical PDFs.

**No known writing, correction or PDF-verification defect is pending.**

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
rewrote Chapters 19–79; Phase E rebuilt Appendices A–H. Phase F's twenty-one verified batches
filled omitted Chapters 8–11 and 18, removed stale totals/terminology, reconciled the
early graphics, lifecycle and math narrative, and separated the four current shader strategies
from the still-missing arbitrary-effect path. State, stream, instancing and programmable-GL
contracts now also match the pinned renderer interface and post-audit remediation state. Shared
render-target binding, usage, ordered-clear and dynamic viewport/scissor semantics now match the
four deferred modern renderers as well. Modern Direct3D, Windows/vector/DOM 2D families and the
diagnostic renderers now also agree with the complete-or-refuse cube/resource boundary. The book
is 709 pages. Content/XNB path containment, limits, texture hardening and SpriteFont invariants now
also match the integrated remediation state. The Model/glTF/CNJ chapters now distinguish the live
hierarchies, stride and animation contracts from their remaining validation and conformance gaps;
Input, Audio, Media and both device-service layers now match their live event, ownership,
capability and callback boundaries. GamerServices, Storage, networking and Avatar now also match
their live persistence, path, session and rendering contracts. The sharp-runtime chapters now
also match the current modular graph, task/stream behavior, parity boundaries, test surfaces and
tracked CI. All live structural citations are stable references, and the index now covers both
API symbols and the book's major platform, verification and porting concepts. Phase G confirmed
the final 709-page PDF's physical bounds, fonts, outline, text layer and container integrity. A
post-G clean build and navigation audit additionally proved its page labels, links and numbered
TOC landings; Phases A–G are closed.
