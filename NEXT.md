# Next session — start here

Read this file, then `PLAN.md`, then `AUDIT.md`. The raw per-area research evidence is in
`audit/` (ten files). CNA-side defects found along the way are in `cnabugs.md`. The previous
edition's plan and handoff are archived as `PLAN-ARCHIVE-2026-07-26.md` and
`NEXT-ARCHIVE-2026-07-26.md` — history, not instructions.

## State at handoff (2026-08-12)

| | |
|---|---|
| cna-bible branch | `next`; local commits are ahead of `origin/next` (push requires explicit external-publication approval) |
| CNA pinned SHA | `7a64362efef4119bf880459ef1704fb2c52199e2` (`develop` == `origin/develop` at pin time, 2026-08-11; later drift is item 43) |
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
41. **Phase G is complete and verified.** At that checkpoint the artifact was a readable,
    unencrypted A4 PDF
    with all 27 fonts embedded, subsetted and Unicode-mapped; its outline contains 12 Parts, 79
    chapters and 8 appendices; its 302,443-word searchable text layer stays inside every page.
    The complete verifier and a MuPDF parse/rewrite round trip are green.
42. **The post-G release hardening pass is complete and verified.** An independent clean-tree
    build reproduced the 709-page artifact. Mechanical proofreading removed two duplicated
    function words and regularized two awkward constructions; all four affected pages were
    rendered and read clean. The verifier now checks every page's A4 geometry and rotation, the
    roman-to-arabic page-label transition, all 1,076 unique internal targets, all 1,803 link
    rectangles, the printed-page landing of all 1,065 numbered TOC entries, and complete
    Ghostscript interpretation. It fails early rather than silently reducing coverage when a
    required PDF tool is unavailable. Two clean builds under the same `SOURCE_DATE_EPOCH` are
    byte-identical (pre-interactive-index SHA-256
    `c61e4121d5afd7524cc0c1a8143489279409abc2600b45b01ca409c5388aab32`; current release hash is
    item 53).
    All 89 chapter, appendix and renderer-fragment sources are compiled exactly once; the PDF has
    only the three reviewed primary-reference HTTPS links and no active or remote-launch actions.
43. **Post-pin repository movement is recorded, not absorbed.** CNA's branch later advanced one
    commit to `d316653a`, adding only the proposal document `cnaplatform.md`; `cna-template`
    advanced three material commits to `4d0a2c8`. Both recorded pins still exist and are ancestors
    of those HEADs. `PLAN.md` §2 now distinguishes the immutable evidence baseline from this later
    observation; no claim was silently rebased.
44. **PDF metadata and image provenance received a second postflight.** The catalog now declares
    `en-US` and carries a descriptive subject and keywords in addition to the existing title and
    author. Extracted text and low-resolution rasters of all 709 pages are identical to the
    pre-metadata artifact. The five source PNGs map exactly to the five PDF image objects; all are
    opaque and non-empty. The byte-identical SDL Renderer/EasyGL pair is intentional: Git history
    and the retained Xvfb reproduction recipe show two separately executed renderers producing
    the same three-colour oracle scene.
45. **The generated index has passed a semantic-deduplication audit.** Six accidental aliases of
    the same C++ symbols were merged: the owner-qualified `ContentManager::Load<Song>` and
    `Load<T>` keys no longer split on optional call parentheses or an omitted owner; `System::GC`,
    `System::Type` and `System::SystemException` no longer split between C#, C++ and abbreviated
    spellings. Intentional concept pairs such as XNB/`.xnb` and free-direct/`FREEDIRECT` remain.
    A verifier rule prevents the known aliases from returning. Only physical index pages 704–709
    changed; all six were rendered and read at full size, clean.
46. **Visible and embedded authorship now agree.** The custom title page displays Robert Vokac,
    matching the long-standing `pdfauthor`, and the otherwise-unused `main.tex` author field is no
    longer contradictory. A whole-PDF pixel comparison found only physical page 1 changed; it was
    rendered and inspected at full size, clean. The verifier now fixes the title, author, subject
    and keywords as release invariants. Publication still needs an owner-selected license, and the
    current PDF is searchable but untagged rather than claiming PDF/UA; both are explicit owner
    decisions in `PLAN.md` §7.
47. **Software and publication licensing are now unambiguous.** Chapter 1's generic
    “Licensing” heading now says “CNA's software license,” so CNA's pinned Ms-PL terms cannot be
    mistaken for the still-owner-selected book license. The same source check corrected “vendored
    Stock Effects HLSL bytecode” to “sources”: the pinned D3D9 tree contains six `.fx` files and
    four `.fxh` includes and compiles them with its retained tools. The complete verifier is green
    and now additionally proves that all 1,066 PDF outline entries have non-empty titles and unique
    destinations. Only physical pages 5 and 37 changed; both were rendered and read full-size,
    clean.
48. **The preface again matches the completed structure and evidence horizon.** Its Part III
    overview no longer assigns 3D models to the graphics-machine chapters; it names draw geometry
    and vertex streams, leaving the model runtime and asset pipeline in Part VI. Its date note now
    distinguishes July-dated facts quoted from CNA's documentation from this edition's complete
    repository-pin audit on 2026-08-11. The stable Appendix D reference raises the current link-
    annotation total at that checkpoint to 1,803; every target and rectangle remained valid. The complete verifier is
    green, and both physical preface pages 3–4 were rendered and read full-size, clean.
49. **Every compiled Task citation has been re-audited against its owning pin.** The sweep
    covered all 92 manuscript lines containing “Task,” including 46 distinct CNA numeric IDs,
    range and slash endpoints, four decimal/avatar IDs, easy-gl's `U2`, and the three `WEBGPU-*`
    IDs. One arithmetic ambiguity was real: Tasks 666–731 are 66 entries, not 65. Chapter 30 now
    accurately identifies Tasks 666–730 as the 65-task technical audit and Task 731 as its closing
    document, matching the pinned Phase 70 plan and completion report. A verifier rule rejects the
    former off-by-one wording. The complete verifier is green; physical page 349 was rendered and
    read full-size, clean.
50. **The back-of-book index is now genuinely interactive and end-to-end verified.** The
    `imakeidx`/`hyperref` load order had left all seven index pages without link annotations even
    though their printed numbers and generated ranges were correct. Loading the index package
    first activates hyperref's standard `hyperpage` integration: the artifact now contains 1,848
    clickable index numbers, 3,651 total link annotations and 1,541 unique internal targets. A new
    independent MuPDF text/geometry audit proves that every index rectangle covers exactly its
    printed number and lands on physical page `number + 30`, including both endpoints of ranges.
    The pre-fix PDF fails this check at 0 of 0 links. Extracted text is byte-identical; all seven
    visibly recoloured index pages 703–709 were rendered and read, with first/middle/last pages
    inspected full-size and clean.
51. **The PDF outline and visible TOC now agree entry-for-entry.** Beyond checking counts and
    title/destination hygiene, the verifier compares the complete sorted destination sets: all
    1,066 Part-through-subsection TOC targets occur exactly once in the outline, with nothing
    extra. The 27 deeper `paragraph`/`subsubsection` records written internally to `.toc` are
    intentionally outside the standard `book` class's `tocdepth=2` and therefore outside both
    visible navigation surfaces. A fixture replacing one `chapter.1` destination with
    `chapter.9999` triggered both the new two-entry set mismatch and the existing landing-page
    audit. This verifier-only hardening does not alter the PDF.
52. **Print geometry and intentional blank pages are mechanically closed.** `pdfinfo -box`
    confirms that MediaBox, CropBox, BleedBox, TrimBox and ArtBox all resolve to the same A4
    rectangle on every one of 709 pages. Ghostscript ink coverage finds exactly twelve fully blank
    physical pages: all even versos immediately between a Part title and its following right-hand
    chapter. The verifier derives their expected physical positions from the twelve Part entries
    in `main.toc` rather than preserving a hand-written page list, so structural movement remains
    safe. This verifier-only hardening leaves the already-reviewed PDF unchanged.
53. **The interactive-index release is independently reproducible.** Two clean archives of
    commit `4b217a1`, built concurrently in different paths with the same `SOURCE_DATE_EPOCH`,
    produced byte-identical PDFs with SHA-256
    `b62f0644740a28fc05c8a5cb76320c563c49a55461e6503c5b48054ed13fd010`. One clean output then
    passed the complete current verifier, including all 709 page boxes, 1,066 outline/TOC targets,
    1,848 index links, 3,651 link rectangles and twelve derived blank versos. This supersedes the
    earlier pre-hyperindex release hash while preserving it as a historical checkpoint.
54. **All compiled Git citations resolve to the claimed pinned evidence.** A hex-token sweep
    separated numeric constants from sixteen commit-like spellings representing fourteen distinct
    Git objects across CNA and the eleven sibling repositories. Every abbreviated prefix resolves
    uniquely in its owning repository and every object is a commit. Role checks also confirm that
    `b6686bfba` is CNA's twelve-example Emscripten-lifetime repair, `f827a6c5` contains the exact
    tracked sharp-runtime database blob, the easy-gl/meta-gl seven- and eight-character spellings
    name the same two rewritten public heads, and the cna-template pin/drift pair names the intended
    ancestor and later descendant. No manuscript correction was required; this read-only audit did
    not alter the PDF.
55. **Filename citations have a bounded provenance audit.** A sweep of 295 filename-like
    occurrences (194 distinct spellings) classified pinned-tree paths, wildcards, external
    dependency headers, intentionally absent interface examples and historical labels. It found
    two real pre-normalization basenames in Chapter 26: the registered FreeDirect tests are
    `freedirect_texture_rendertarget_test.cpp` and `freedirect_no3d_test.cpp`, not `dx3_*`.
    Chapter 75 now also identifies `free-eggbert/cna.md` accurately as an untracked supplemental
    working-tree document and records the exact inspected copy's size and SHA-256 instead of
    implying membership in an immutable Git pin. The verifier rejects both stale test basenames;
    the complete build is green with 3,652 valid link annotations, and a whole-artifact pixel
    comparison isolated only physical pages 318, 319 and 645; all three were rendered and read
    full-size, clean.
56. **PDF bookmark titles now have source-level integrity.** The verifier already proved that
    the 1,066 outline destinations equal the visible Part-through-subsection TOC destinations;
    it now also decodes all 1,066 UTF-16 entries in `main.out` and requires the exact
    `(destination, title)` set emitted by MuPDF. A fixture changing only `Preface` to `PrefacX`
    while retaining `chapter*.1` and the untouched PDF failed with exactly two differing pairs.
    The current artifact has zero title mismatch. This is verifier-only hardening and does not
    change any PDF page.
57. **PDF bookmark hierarchy now has source-level integrity.** MuPDF's outline indentation is
    converted into all 1,066 `(destination, parent)` pairs and compared with the explicit parent
    recorded for every `main.out` bookmark. A fixture retaining `chapter.1` and its title but
    moving its parent from `part.1` to `part.2` left the destination/title checks green and made
    only the new hierarchy guard fail with two differing pairs. The current artifact has zero
    parent mismatch. This verifier-only hardening does not change any PDF page.
58. **Every visible table-of-contents entry is demonstrably clickable.** Physical TOC pages
    5--29 contain 1,129 link rectangles covering exactly all 1,066 visible Part-through-
    subsection destinations; 63 long titles legitimately use a second rectangle. In a
    decompressed PDF fixture, changing only the `Preface` annotation subtype from `Link` to
    `Text` left every destination, title, parent, page landing and remaining link geometry green,
    while the new guard alone reported 1,128 rectangles / 1,065 targets and missing
    `chapter*.1`. This is verifier-only hardening and does not change the release PDF.
59. **Every TOC rectangle is bound to its own printed entry, not merely some valid target.**
    MuPDF text geometry now matches all 1,066 linked destinations to the structural identity
    printed under their 1,129 rectangles: Part roman numeral, chapter/section/subsection number,
    appendix letter, `Preface`, or `Index`. A decompressed-PDF fixture swapped only the two TOC
    destinations `chapter.1` and `chapter.2`; target coverage, landings and all prior navigation
    checks stayed green, while the new guard alone reported the two crossed printed identities.
    This verifier-only hardening does not change the release PDF.
60. **The PDF contains no invisible or blank-paper link hotspots.** A single MuPDF structured-
    text pass across all 709 pages now requires every one of 3,652 Link rectangles to have
    positive-area overlap with visible text. A decompressed-PDF fixture moved only preface link
    object 4302 to an in-bounds blank rectangle at `[10 10 20 20]`; target and geometry checks
    remained green, while the new guard alone reported one empty rectangle on physical page 3.
    The release artifact has zero empty link rectangle. This verifier-only hardening does not
    change the PDF.
61. **The complete PDF named-destination tree is geometrically valid.** All 5,054 names map
    one-to-one to 5,054 destination objects; every object uses an actual one of 709 page objects,
    an in-A4 numeric XYZ position, and inherited (`null`) zoom. A decompressed-PDF fixture changed
    only `part.1`'s Y coordinate from 558.81 to 900; every existing link, landing, outline and
    page check stayed green, while the new guard alone reported the out-of-page target on page
    object 5587. The release artifact has no invalid, duplicate or orphan destination record.
    This verifier-only hardening does not change the PDF.
62. **The Graphics include inventory matches the pin and its namespace boundary.** The prior
    prose called the subtree “106 headers” and flattened its namespace. The pinned tree actually
    contains 125 `.hpp` files: 107 directly under
    `Microsoft/Xna/Framework/Graphics/` and 18 under its `PackedVector/` child. Chapter 3 now
    reports both counts and preserves that nested namespace. The two new semantic namespace index
    entries intentionally bring makeindex to 2,389 accepted entries, the back-of-book index to
    1,850 valid links, and the artifact to 3,653 link annotations / 1,542 unique internal targets.
    A verifier guard rejects the stale wording. A whole-artifact pixel comparison isolated only
    physical page 47 and index pages 706--709; all five were rendered and read full-size, clean.
63. **The physical-module no-loss inventory uses the source evidence's unit of measure.** A broad
    numeric-claim audit directly recounted all 1,776 records in the seven cited move commits and
    confirmed every record is `R100`. The pinned reconciliation does preserve 1,357 before and
    after, split into 1,287 byte-identical moves and 70 directive-only edits, but these are
    production *files*, not translation units: the committed inventory also includes headers.
    Chapter 9 now uses the correct term without changing any count, and the verifier rejects the
    misleading old label. The complete build is green; physical page 117 was rendered and read
    full-size, clean.
64. **The platform-directive metric now has a reproducible denominator and boundary.** The pin has
    exactly 1,195 production C++ files under `modules/` when defined as 720 `.hpp`, 474 `.cpp`,
    and one `.mm`, excluding tests and examples. An independent line-oriented recount finds 55
    files / 152 directive lines naming OS macros, 97 in renderers and 55 elsewhere; compiler-only
    generated branches are excluded rather than mixed into “OS platform” counts. Chapter 61 now
    states that definition, updates the independent `CNA_RENDERER_*` count from 109 to 110, and
    labels the roughly 6,000 SDL-family tokens as lexical magnitude rather than API call sites.
    The complete build is green; physical pages 584–585 were rendered and read full-size, clean.
65. **The easy-gl/meta-gl direct-consumer count matches the recorded easy-gl pin.** An exact
    include-directive scan across `include/**/*.hpp` and `src/*.cpp` finds 18 production files,
    not 19: three public headers and fifteen implementation files. Chapter 59 no longer overstates
    the implementation side by one, and the verifier rejects both stale count phrasings. The
    complete build is green; physical page 569 was rendered and read full-size, clean.
66. **The free-direct status census now states its exact token boundary.** A broad word grep
    appears to contradict the 95-row table because `dsound.h` opens with twelve untagged summary
    classifications, then repeats them in the annotated declarations. Counting explicit
    `Status: IMPLEMENTED|PARTIAL|STUB` lines reproduces the table exactly: ddraw 24/12/7, dplay
    12/7/7, dsound 20/4/2, total 56/23/16. Chapter 60 now records this rule so the marker census
    cannot be mistaken for either a bare-word census or a public-method count. The complete build
    is green; physical page 577 was rendered and read full-size, clean.
67. **The remaining high-risk numeric claims were directly reproduced at their recorded pins.**
    The sweep confirmed CNA's 6,818 GoogleTest definitions across 433 globbed sources, 1,233 module
    example `.cpp` files / 1,169 `*_test.cpp`, 1,785 renderer-test registrations, 141 Color
    constants / 139 packed values, 46 renderer identities / 42 families, 39 oracle scenes/PNGs,
    and 1,876 CNAEXT tokens in 302 module headers. Sibling recounts confirmed xna4-spec's 544 type
    XMLs in 19 namespace directories, cna-samples' 63/23/67 = 153 catalog, cna-examples' 13/79/249
    catalog, easy-gl/meta-gl's line and API inventories, free-direct/free-api's test registrations,
    and sharp-runtime's 41 modules / 44 components / 92 edges plus its exact SQLite task/ticket
    totals. No further manuscript correction was warranted; this checkpoint has no PDF delta.
68. **The corrected release is independently reproducible.** Two clean archives of commit
    `3db9edc`, built concurrently in different paths with `SOURCE_DATE_EPOCH=1786529214`, produced
    byte-identical 709-page PDFs (3,314,744 bytes) with SHA-256
    `7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af`. One clean output passed
    the complete current verifier: 2,389 accepted index entries, 1,850 clickable index numbers,
    3,653 visible-text-backed links, 1,542 unique link targets, 5,054 valid named destinations,
    1,066 exact outline/TOC identities and parents, and twelve derived blank versos. This
    supersedes the interactive-index checkpoint's `b62f064...` hash as the current release
    fingerprint while retaining that earlier result as historical evidence.
69. **The final navigation and searchable-text summaries match the corrected artifact.** Exact
    comparison of the complete PDF page-label number tree, bound to the fixed page count, proves
    the full 709-label sequence `i`--`xxx`, then `1`--`679`, rather than recording only the
    physical-page-31 boundary. A simulated 710-page artifact with the same transition passed the
    old label predicate and fails the new combined invariant. The current
    `pdftotext -layout` layer contains 302,448 words; the 302,443 count remains the accurate
    historical Phase-G checkpoint before the later prose corrections.
70. **Release cardinalities can no longer regress silently.** The verifier now requires exactly
    2,389 accepted / zero rejected / zero-warning makeindex entries and exactly 3,653 targeted,
    in-bounds link rectangles, rather than accepting any clean non-empty populations. It also
    extracts the full searchable layer in Poppler layout mode, requires the corrected 302,448-word
    inventory and rejects NUL bytes or UTF-8 U+FFFD replacement characters. Reduced-count
    predicates fail directly; the complete verifier remains green on the fixed-date release PDF.
71. **PDF annotations and actions are positively allowlisted.** A complete object census proves
    that all 3,653 annotations are `/Link`: 3,650 use internal `/GoTo`, and exactly three use the
    reviewed HTTPS `/URI` actions. There are no direct-destination or unclassified annotations.
    The verifier now requires that exact distribution in addition to its existing blacklist and
    URI allowlist, so an unfamiliar media, attachment, widget or action subtype cannot pass merely
    because its spelling was absent from the blacklist. The release PDF remains unchanged.
72. **The PDF catalog is positively allowlisted.** After normalizing volatile object numbers, the
    catalog contains only the page tree, outline, destination names, `UseOutlines` mode, `en-US`,
    the exact page-label tree and an opening action. The Names root contains only `Dests`; the
    opening action is an internal `GoTo /Fit` to the actual first page object. A synthetic extra
    `/AA` catalog branch fails exact comparison. This closes script/name-tree additions at the
    document root independently of the annotation-action census, with no PDF delta.
73. **The reviewed release has a single reproducible entry point.** `tools/build-release.sh`
    forces a complete `latexmk` rebuild with `SOURCE_DATE_EPOCH=1786529214`, requires exactly
    3,314,744 bytes and SHA-256 `7c877ef...`, then runs the complete verifier on that artifact.
    The fixed fingerprint is intentionally a sealed-release gate: manuscript or layout changes
    fail until a new independent reproducibility and visual-review checkpoint authorizes new
    constants. README documents the command and warns against hash-only updates.
74. **Font and image populations are release invariants.** Font portability now requires exactly
    27 rows, not merely a non-empty all-good set. The verifier extracts all embedded images and
    uses Netpbm plus binary comparison to match both decoded RGB and alpha planes, in compile
    order, to exactly five source PNGs. All five pairs are pixel-identical; the intentionally
    identical SDL Renderer/EasyGL sources remain separate occurrences. README records the added
    `pdfimages`/`pngtopnm` requirements. No artifact change was needed.
75. **The PDF parse/rewrite round trip is automated again.** The verifier rewrites the release to
    a disposable PDF with MuPDF, requires Poppler to report all 709 pages and extract layout text
    byte-identical to the source artifact, then has Ghostscript interpret the rewritten document.
    The current round trip passes all three stages. This turns the historical Phase-G manual
    result into a repeatable invariant and leaves the sealed release bytes untouched.
76. **The declared PDF profile matches the owner-decision boundary.** The artifact gate now
    requires PDF 1.7, exactly 709 pages, `Tagged: no`, `Suspects: no`, `UserProperties: no` and no
    encryption, alongside the existing per-page A4/rotation/box checks. Requiring the consciously
    untagged state prevents a partial or accidental tag tree from being presented as an accessible
    edition; a future tagged/PDF-UA release remains an explicit owner-selected, separately audited
    change. Producer and linearization details remain outside the semantic gate.
77. **Claude Code's durable workflow now points at the real release tooling.** `CLAUDE.md` names
    `tools/verify-book.sh` as the authoritative once-per-batch automated suite and keeps rendered
    touched-page inspection as a separate requirement. It distinguishes that workflow from the
    sealed `tools/build-release.sh`, which should fail ordinary manuscript changes until a new
    release is authorized. Historical batched-writing, source-grounding and push rules remain
    unchanged.
78. **The compiled-source closure includes front matter.** The input-graph verifier previously
    required all 89 chapter/appendix/renderer-fragment sources exactly once but left
    `front/titlepage.tex` and `front/preface.tex` outside that census. It now requires exactly 89
    content plus two front-matter files, all 91 present, input exactly once and case-correct, with
    zero orphan, duplicate or missing targets. The release already satisfies the stronger graph;
    no PDF change was required.
79. **TeX's recorder agrees with the declared input graph.** `main.fls` is now compared against a
    filesystem-derived set of exactly 98 project-owned inputs: `main.tex`, the shared preamble,
    91 front/content `.tex` files and five PNGs. TeX-distribution and generated auxiliary files
    are excluded by explicit path/type boundary. The release recorder has zero missing or
    unexpected project inputs, closing the gap between source declarations and files actually
    opened during compilation; no artifact change was needed.
80. **Every external URI equals the URL printed under its rectangle.** The existing exact
    allowlist could not detect swapping two already-approved targets. The all-link MuPDF geometry
    pass now gathers the visible line(s) centered under each of the three URI rectangles and
    requires the trimmed text, after removing terminal sentence punctuation, to equal that
    action's target byte-for-byte. SDL Init and both
    Microsoft Present links match. A two-target swap preserves URI allowlist/cardinality but
    yields two identity failures; the release PDF needs no change.
81. **The PDF outline preserves source bookmark order.** Destination, title and parent checks
    previously compared sorted sets, so two complete bookmark subtrees could theoretically trade
    positions without failing. The verifier now compares the unsorted 1,066-destination sequence
    emitted by MuPDF with the sequence in `main.out`, byte-for-byte. The release order matches;
    swapping any two records changes two sequence positions even when all former set checks stay
    green. This verifier-only closure has no PDF delta.
82. **The visible TOC preserves source order.** Physical TOC pages contain six legitimate extra
    duplicate links from surrounding navigation, so the verifier filters to the first occurrence
    of each expected destination. The resulting 1,066-link sequence matches `main.toc`
    byte-for-byte. This supplements the existing target coverage, visible identity and landing
    checks: swapping two otherwise-valid rows preserves their set but fails the new order guard.
    The release artifact is unchanged.
83. **Internal-target and numbered-landing populations are fixed.** The verifier no longer accepts
    any non-empty internally consistent population: it requires exactly 1,542 unique internal
    link targets and exactly 1,065 numbered TOC entries with correct physical landings. These
    counts join the already-fixed 3,653 links, 5,054 names, 1,066 visible TOC identities and 1,850
    index numbers, preventing silent removal of a valid subgroup. The release passes unchanged.
84. **Concurrent verifier diagnostics are isolated and cleaned.** Eleven stale-fact/whitespace
    checks previously wrote predictable `/tmp/cna-bible-*.txt` names, allowing simultaneous runs
    to overwrite one another and leaving empty files behind. Each run now creates a private
    `mktemp` directory, routes named diagnostics there and removes it on normal exit or
    `HUP`/`INT`/`TERM`. Generated artifacts and verification semantics are unchanged.
85. **The sealed workflow passes from the current clean tracked archive.** A `git archive` of
    commit `d551a3f` was extracted into a new path, initialized with a local baseline solely for
    `git diff --check`, and ran `tools/build-release.sh` without workspace-only inputs. It rebuilt
    3,314,744-byte SHA-256 `7c877ef...` and passed the complete expanded verifier, including the
    98-input recorder, pixel image provenance, catalog/action allowlists, outline/TOC order and
    round trip. Later documentation of this run has no typesetting delta.
86. **Sealed builds reject typesetting drift before invoking TeX.** `tools/build-release.sh` now
    requires a Git worktree, exact `HEAD:latex` tree
    `406104d29871dab11757fdd72ded5d9fbc7fc9f1`, and empty tracked/untracked `git status` under
    `latex/`. Documentation and verifier-only commits remain compatible, but committed, staged,
    unstaged or non-ignored untracked release-input changes fail with the actual tree/status.
    Positive clean-tree and negative mutated-archive fixtures exercise both paths.
87. **The sealed source date is verified semantically as well as by hash.** After the fixed-epoch
    build, `tools/build-release.sh` reads the PDF Info object through MuPDF and requires both
    CreationDate and ModDate to equal `D:20260812100654Z`, the UTC form of epoch `1786529214`.
    This gives an actionable timestamp diagnostic before the full verifier; ordinary working
    builds remain exempt. README records the date alongside size and SHA-256.
88. **Verifier arguments are fail-closed.** The script previously treated any unknown argument as
    a normal build request. It now accepts only no argument, exactly `--no-build`, or `--help`;
    unknown/multiple arguments print usage and return 2 before invoking make. Negative CLI
    fixtures confirm that no build log or temporary diagnostic directory is created, while both
    supported verification modes retain their prior behavior.
89. **Release-builder arguments are fail-closed too.** `tools/build-release.sh` now accepts only
    its argument-free sealed workflow or `--help`. Unknown or multiple arguments print usage and
    return 2 before resolving the repository, checking dependencies or touching the release log,
    so a mistyped option cannot silently start a full fixed-date rebuild.
90. **The generated index structure is an explicit invariant.** Beyond makeindex's clean exit and
    the PDF's 1,850 clickable page numbers, the verifier now parses all 2,389 `main.idx` records.
    Every record must have a non-empty key, use `hyperpage` and cite printed page 1–670; the 681
    case-folded logical keys must produce exactly 676 top-level items and five subitems, with no
    lost or unexpected level. The current source/output pair satisfies the complete census.
91. **All verifier scratch data has one lifecycle.** The earlier concurrency repair covered the
    eleven named source diagnostics, but more than forty unique text/JSON/PDF/image intermediates
    still relied on reaching their individual `rm` lines. `mktemp` calls now resolve inside the
    run's private directory; one recursive EXIT cleanup covers normal, failed and interrupted
    runs, while HUP/INT/TERM retain meaningful exit status. No artifact or check changed.
92. **PDF Info semantics include creator and trapping state.** The release metadata guard now
    requires `Creator: LaTeX with hyperref` and `/Trapped /False` alongside title, author, subject
    and keywords. Producer/version and fixed dates remain covered separately by the sealed byte
    fingerprint and release entry point; ordinary verifier diagnostics now identify these two
    previously implicit Info-field drifts directly.
93. **Visual-range rendering is fail-closed and run-isolated.** `tools/render-pages.sh` now accepts
    exactly two/three operands or `--help`, requires positive decimal pages in ascending order and
    preflights its three commands. Each invocation renders into a fresh child directory, verifies
    exactly `LAST-FIRST+1` PNGs and lists only that run, so stale images in a reused parent cannot
    masquerade as newly reviewed pages.
94. **Unreadable PDF containers fail before dependent audits.** The verifier now invokes `pdfinfo`
    once, requires a numeric page count and exits immediately if either condition fails. Geometry,
    metadata, extraction and navigation checks therefore never consume an empty page variable or
    emit a cascade of secondary shell/parser errors for one damaged input.
95. **Scratch bootstrap failure is diagnosed before scratch allocation.** `mktemp` is now resolved
    explicitly before the verifier creates its private run directory, and allocation failure has
    its own controlled error. A missing bootstrap command can no longer bypass the ordinary
    dependency preflight and cascade through an empty scratch path.
96. **The source-image graph is closed, not merely observed by TeX.** The recorder and embedded-
    pixel audits operate on sets, so neither alone detects one PNG included twice while another is
    orphaned. The verifier now requires exactly five case-correct `images/*.png` targets, each
    matching one of the five source files exactly once, with no duplicate, orphan or missing/
    non-PNG target before checking their embedded RGB/alpha pixels.
97. **Visual rendering fails cleanly on unreadable inputs and allocation errors.** The page-range
    tool now requires `pdfinfo` success plus a numeric total before comparing bounds, and gives a
    dedicated error when its private output directory cannot be created. A damaged PDF or invalid
    output parent therefore cannot leak shell arithmetic or partial-render confusion into the
    mandatory visual review.
98. **The sealed workflow preflights its complete downstream toolchain.** Before invoking TeX,
    `tools/build-release.sh` now checks the union of its build/fingerprint commands and all
    verifier parsers: Git/latexmk/core utilities, Perl, Poppler, Netpbm, MuPDF and Ghostscript.
    Missing commands are reported together; an absent late-stage parser can no longer waste a
    full fixed-date rebuild before failing.
99. **The reviewed release PDF is transactionally preserved.** Before TeX, the sealed workflow
    snapshots any existing `main.pdf` outside the source tree. Build, fingerprint, verifier or
    HUP/INT/TERM failure restores that file byte-for-byte (or removes a partial output if none
    existed); only complete success commits the rebuilt artifact. Logs and auxiliary files stay
    available for diagnosis, but a failed attempt cannot masquerade as the latest release PDF.
100. **Sealed release transactions are serialized per repository.** A non-blocking `flock`, keyed
     by the absolute repository path, is acquired before Git preflight and the PDF snapshot. A
     second invocation fails immediately with a specific message instead of racing on shared
     auxiliaries, release log and transactional restore state; the kernel releases the lock on
     every normal, failed, signalled or crashed process exit.
101. **A failed rollback never destroys its only snapshot.** If copying the prior PDF back into
     place itself fails, the transaction handler now retains the private snapshot and reports its
     exact path rather than deleting it during generic cleanup. Normal success and successful
     rollback still remove the temporary copy; the exceptional branch therefore favors manual
     recovery over a falsely tidy `/tmp`.
102. **The release lock cannot be redirected through world-writable `/tmp`.** The predictable
     repository-keyed filename now lives below `/tmp/cna-bible-release-locks-$EUID`; the script
     creates that parent as `0700` and refuses it unless it is a real directory owned by the
     effective user with exactly that mode. This preserves cross-invocation locking without a
     symlink/open redirection surface at the public temporary-directory level.
103. **The public workflow documentation matches the hardened tools.** README now names
     `pdftoppm` for mandatory visual rendering and `flock` for sealed serialization, and explains
     transactional restoration/removal of the PDF on a failed sealed attempt. Users can therefore
     provision the full toolchain and interpret failed releases without reverse-engineering the
     scripts; this documentation-only change has no typesetting delta.
104. **All artifact readers and writers share one lock protocol.** `tools/book-lock.sh` now gives
     default verification and sealed release an exclusive repository lock, while `--no-build`
     verification and isolated visual rendering take a shared lock. Multiple read-only audits can
     still run together, but none can observe a PDF/aux set mid-build; sealed release passes its
     inherited exclusive descriptor into the nested verifier without weakening the transaction.
     The child accepts that descriptor only when its device/inode identity matches the correct
     repository lock, so an arbitrary environment-supplied open file cannot bypass serialization.
105. **The shared lock is part of the durable contributor contract.** README lists the helper
     beside the public tools, and `CLAUDE.md` requires every future artifact reader to take a
     shared lock and every aux/log/PDF writer an exclusive lock. This prevents a later entry point
     from silently reintroducing mid-build reads after the current three tools were reconciled.
106. **Lock acquisition is idempotent and leak-free.** Repeated compatible calls in one shell now
     reuse the validated repository descriptor; an exclusive holder may satisfy either request,
     while a shared-to-exclusive upgrade fails explicitly instead of racing. Fresh descriptors are
     closed immediately when non-blocking acquisition fails, so future composed tools cannot leak
     FDs even when they recover from contention rather than exiting.

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
- makeindex: 2,389 entries accepted, 0 rejected, 0 warnings.
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
- A metadata-only comparison proved the searchable text and every one of 709 rendered pages
  unchanged after adding the PDF language/subject/keywords. The verifier now requires `en-US`.
- The index audit found no empty key or out-of-range page reference; all generated references stay
  within printed pages 1–670. Six duplicate API aliases were consolidated, and final physical
  pages 704–709 were individually inspected at full size.
- The title page and embedded metadata now identify the same author. Only physical page 1 changed
  visually and it was inspected clean; license and tagged-PDF policy remain owner release choices.
- CNA's Ms-PL section now identifies itself explicitly as the software license rather than the
  book's publication license, and its D3D9 derivation wording correctly names the vendored HLSL
  sources. Physical pages 5 and 37 were rendered and read clean. The verifier also checks all
  1,066 outline entries for non-empty titles and unique destinations.
- The preface's Part map now keeps 3D models in Part VI and describes Part III's actual geometry/
  vertex-stream remit. Its evidence note binds the complete audit to the 2026-08-11 repository
  pins via Appendix D. The later interactive-index repair and current supplemental-evidence link
  bring that checkpoint to 3,652 valid link annotations and 1,541 unique targets. Physical
  pages 3–4 were read full-size and are clean.
- All 92 compiled lines containing “Task” were checked against the relevant pinned CNA/easy-gl
  evidence. Chapter 30's sole count mismatch now separates the 65 technical Tasks 666–730 from
  Task 731's closing document; a verifier guard prevents the off-by-one wording from returning.
  Physical page 349 was rendered and read full-size, clean.
- Corrected package order so all 1,848 back-of-book index numbers are clickable. The verifier now
  matches every link rectangle to its printed number and physical target; all pass, giving 3,651
  valid annotations and 1,541 unique targets overall. The pre-fix artifact fails the new guard.
  Extracted text is identical, and all seven recoloured index pages were visually reviewed clean.
- The 1,066-entry outline now must exactly match every visible Part-through-subsection TOC
  destination, not merely its aggregate counts. A one-destination negative fixture triggered both
  the set comparison and landing audit. The 27 deeper internal `.toc` records remain deliberately
  hidden at the standard `tocdepth=2`; this verifier-only change did not alter the PDF.
- Every page now must expose matching A4 Media/Crop/Bleed/Trim/Art boxes. Ghostscript ink coverage
  must find exactly the twelve blank versos derived from the Part-page entries in `main.toc`; the
  current physical pages are 32, 50, 130, 216, 366, 420, 454, 532, 568, 582, 610 and 636. This
  verifier-only change did not alter the PDF.
- Two clean builds of the final corrected checkpoint in different paths are byte-identical at
  SHA-256 `7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af`; one clean artifact
  passed the complete current verifier. The earlier `b62f064...` interactive-index hash remains
  a historical checkpoint; `7c877e...` is the current release fingerprint.
- All sixteen commit-like spellings in the compiled manuscript resolve uniquely to fourteen
  intended commit objects in CNA or the eleven sibling repositories, and sampled role/content
  claims match those objects. Hex-like numeric constants were excluded explicitly. No correction
  or PDF change was required.

**No known writing, correction or PDF-verification defect is pending.**

## Environment notes

- **TeX Live** was absent at session start and was installed mid-session at the owner's
  direction. `latexmk`, `pdflatex`, `makeindex`, `pdftoppm` are all present and confirmed working.
- **No blocking questions for the project owner** at this time.
- Post-pin drift: CNA is now at documentation-only descendant `d316653a`; `cna-template` is at
  material descendant `4d0a2c8`. The edition remains intentionally pinned to the recorded commits;
  see item 43 and `PLAN.md` §2.
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
