# The CNA Bible — Expansion Plan (1000–2000 pages per part-group; single book since 2026-07-20)

**Status: Phase 1 planning complete, execution starting. This is a long-running,
multi-session project — this file is the durable task list and progress tracker across
sessions. Update the status column and the session log at the bottom every session.**

## The ask, restated honestly

The author's target is roughly 1000–2000 pages **per volume** (currently ~114 pages in
Volume I, ~119 in Volume II — each chapter needs to grow to roughly 10–20× its current
length). This is not achievable in one sitting; it is a genuine multi-session content
project, expected to take many further sessions of focused writing, verification, and
compilation. This file exists so that work can stop and resume cleanly across sessions
without losing track of what's done, what's next, and what page target each chapter is
aiming for.

**Phase 1 target (this plan's committed scope): ~1,300 pages for Volume I, ~1,200 pages
for Volume II (~2,500 combined).** This lands solidly inside the requested 1000–2000/volume
range without overclaiming the top of it. Reaching the very top of the range (2000/volume)
is a **Phase 2 stretch goal** — once every chapter below hits its Phase 1 target, a second
pass can go deeper still (more worked examples, more edge-case coverage) if the author wants
to keep going. Phase 2 targets are not yet broken out per chapter; revisit once Phase 1 is
done.

## Author's answers to the scoping questions (2026-07-20)

- **Expansion style:** full API documentation (every method, overload, parameter, exception,
  per class — not the condensed summary style the two Quick Reference appendices already
  use) **plus** more worked examples/tutorials. Not a narrative/history-depth expansion —
  design rationale and FNA/XNA comparisons stay at their current depth unless a worked
  example naturally needs one.
- **Structure:** expand the existing ~24 chapters per volume in place. Do **not** fragment
  into one-chapter-per-class. The Part/chapter structure in both `main.tex` files stays as-is.
- **Pace:** long-running incremental project. Work through this list across many sessions;
  commit and push after each chapter (or small batch of chapters); recompile and check for
  new undefined references/errors before every push, exactly as every prior pass in this
  project has done.
- **Code examples and screenshots (2026-07-20, follow-up instruction):** every expanded
  chapter needs real, compilable code examples (already implied by "worked examples" above,
  now stated explicitly), and graphics-facing chapters should additionally include real
  screenshots of the example programs actually running wherever that's feasible. A feasibility
  check of building/running CNA and capturing real screenshots in this environment is
  in progress as of this session — see the session log for what it found and how screenshot
  coverage got scoped as a result (this environment is a headless remote container with no
  guaranteed GPU/display, so the realistic answer may be "some backends yes, others no" rather
  than uniform coverage across every chapter).

## Methodology (unchanged from the rest of this project)

- Every new page must be grounded in an actual source read: the class's own header, its
  `.cpp` implementation where it clarifies behavior, and its test file where one exists (test
  files are often the best source of a realistic, runnable usage example — prefer adapting a
  real test's call pattern over inventing a new example from scratch).
- "Full API documentation" means: every public method and overload gets its own subsection —
  signature, each parameter's meaning/units/valid range, return value, every documented
  exception and when it's thrown, and (per the author's second answer) a short worked example
  showing it called in context, not just a signature restated in prose.
- Every worked example must be real, compilable code — adapted from an actual test/example
  call site wherever one exists, not invented from scratch and never presented as tested when
  it wasn't actually compiled.
- **Screenshots: real or not at all.** Where a chapter includes a screenshot of an example
  program running, it must be a real, actually-captured image from an actually-built and
  actually-run CNA program in this environment — never a mockup, a hand-drawn diagram
  presented as a screenshot, or an AI-generated image. If a given backend/chapter genuinely
  cannot produce a real screenshot in this environment (no GPU, no display, a backend that
  needs Windows/Wine, etc.), the chapter says so explicitly and either omits the screenshot or
  substitutes a real, clearly-labeled textual/ASCII capture instead — it does not fake one.
- Recompile (`make volume1` / `make volume2`) after every chapter or small batch; grep the log
  for `undefined` before moving on; fix any stale cross-references immediately (this project's
  established failure mode after any renumbering or heavy insertion).
- Keep committing in small, reviewable increments with descriptive messages — not one giant
  commit at the end. Push after each one.
- Update this file's status column and append a dated entry to the session log at the bottom
  every time work stops, so the next session (which may not share this conversation's context)
  can pick up correctly.

## Resolved: free-direct and cna-extended stay marginal (author confirmation, 2026-07-20)

The author confirmed explicitly: **free-direct and cna-extended stay marginal in the book**,
overriding the blanket "every chapter must expand" instruction for these two specifically.

1. **Vol. II Ch.13 (free-direct deep dive)** stays at its current, already-capped size (~2
   pages, part of the original "5–10 pages total for free-direct across both volumes"
   instruction) — **not** expanded to the ~35-page Phase 1 target below. The table row below
   is kept for reference but its target is now "no change."
2. **cna-extended**, in Vol. II Appendix C, stays "one paragraph, not a dedicated chapter" —
   no change needed there either; it was never going to be touched by this expansion pass
   regardless (appendices aren't chapters), so this is just confirmation, not a new decision.

This was an open conflict flagged in this file until the author resolved it directly.

## Screenshot feasibility check (2026-07-20)

A background research pass confirmed real, in-environment screenshots are achievable for at
least one backend. Full findings, a reusable patch, and step-by-step reproduction instructions
are saved in `tools/cna-screenshot-infra/` (read that directory's `README.md` before any
session attempts to build CNA or capture a screenshot — `/workspace/cna` itself does not
persist across sessions, so the patch there needs reapplying to a fresh clone each time).

- **CNA's `SOFTWARE` backend is the realistic path.** It's a real CPU rasterizer (edge
  functions, perspective-correct interpolation, depth test) that never touches SDL
  video/X11/a GPU — confirmed working with no `DISPLAY` set at all. A demo program built
  against it and run headlessly produced a genuine, visually-correct 256×256 RGBA PNG.
- CNA already has golden-image test infrastructure (`SaveBackBufferScreenshotEXT`,
  `Texture2D::SaveAsPng`, ~17 checked-in reference PNGs) to build real per-chapter examples on.
- CNA's checked-out HEAD did not compile without a small, diagnostic-quality stopgap fix to
  `ContentReader::ReadDecimal()`/`ReadChar()` (never implemented, but called by two content
  type readers) — saved as a patch in `tools/cna-screenshot-infra/`, worth a one-line honest
  mention in Chapter 4 ("Building CNA") if still reproducible when that chapter is actually
  written, framed as a real, current gap rather than a permanent characteristic.
- `EASYGL`/`SDL_RENDERER` screenshots are plausible via `Xvfb` + Mesa llvmpipe (packages were
  already available) but this was **not actually tried** — untested, not confirmed feasible.
- **D3D9/D3D11/D3D12/BGFX are Windows/GPU-only and unrealistic to screenshot in this container
  at all.** Their chapters (Vol. I Ch.20, Ch.22) should say so plainly rather than force a fake
  image — per this file's own "real or not at all" rule above.
- `CANVAS` (Emscripten/browser-only) and `ASCII` (needs a real X11 window, same as
  `SDL_RENDERER`) are lower-priority screenshot candidates; `HEADLESS` cannot produce one at
  all (it never rasterizes a real pixel).

**Practical per-chapter implication, folded into the table below:** Vol. I chapters most
likely to get a real screenshot are Ch.9–14 (GraphicsDevice/SpriteBatch/Textures/Models/Stock
Effects/State Objects, all backend-agnostic enough to render via SOFTWARE) and Ch.17/18
(SDL_Renderer/EasyGL, via the untested-but-plausible Xvfb path). Ch.19–22 (Vulkan/BGFX/WebGPU/
Direct3D) should state explicitly why no real screenshot was attempted rather than skip the
question silently.

## Parts I–IV (formerly "Volume I") — target ~1,300 pages (chapters 1–24 + Appendix A)

Merged into a single book on 2026-07-20 (see the session log entry for that date); chapter
numbers below are unchanged by the merge.

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 1 | What Is CNA | 271 (was 145) | 20 | Added a concrete completion-numbers paragraph, a worked audit-methodology example, project history, Licensing, plus (depth pass) a "Design goals in the project's own words" section (6 README goals) and a cross-backend "scale of verification" comparison table (test counts + method per backend) | **In progress (~6 of ~20 pages, PDF-verified clean, still short of target)** |
| 2 | Ecosystem Map | 197 (was 141) | 25 | Fixed three stale placeholders into real \ref{}s; added easy-gl/free-direct detail; (depth pass) added a real, previously-undocumented second-level sibling dependency: free-direct itself depends on a third repo, free-api (WinAPI-subset via SDL3), confirmed via BackendSelection.cmake, plus real error-message text and free-eggbert/planetblupi as independent consumers | **In progress (~4 of ~25 pages, PDF-verified clean)** |
| 3 | Design Philosophy | 336 (was 256) | 30 | Added NOXNA self-check worked example, corrected an imprecise claim; (depth pass) added a `SkinnedEffect::WeightsPerVertex` worked example for validated property setters, and a full missing-dependency lifecycle worked example (sharp-runtime's `BinaryReader::ReadChar`/`ReadDecimal` — real gap, documented stopgap, proper fix now landed, verified against real sharp-runtime source) | **In progress (~8 of ~30 pages, PDF-verified clean)** |
| 4 | Building CNA | 294 (was 173) | 35 | Added full CMake option reference table; (depth pass) added real per-platform build walkthroughs for Android/NDK (grounded in docs/devices-build.md, incl. the compile-only/no-APK caveat) and Web/Emscripten (real emcc 6.0.2 verification, incl. the real sharp-runtime FileSystemWatcher bug found along the way); fixed a pre-existing overfull-hbox | **In progress (~6 of ~35 pages, PDF-verified clean)** |
| 5 | First Game | 286 (was 131) | 40 | Added second worked example (keyboard movement); (depth pass) added a third complete program (edge-bounce + SoundEffect, real Viewport-based bounds check, real clamp-in-same-branch finding) | **In progress (~6 of ~40 pages, PDF-verified clean)** |
| 6 | Game Loop | 346 (was 216) | 40 | Added GameServiceContainer + PresentationMode worked examples; (depth pass) added a full DrawableGameComponent worked example (FpsCounterComponent, real Add(IGameComponent*) ownership finding, DrawOrder), caught a real TimeSpan API mistake (no operator+=) before commit; fixed a second header-overflow (same defect class, different section) | **In progress (~7 of ~40 pages, PDF-verified clean)** |
| 7 | Math and Core Types | 1675 (was 270) | 110 | All 11 type-families have full reference + worked examples, most with 2-4; chapter-wide "shared surface" section; Vector Length/LengthSquared, Vector4 clip-space Transform (tied to real SOFTWARE-backend code); Matrix arithmetic statics + Decompose, CreateBillboard/CreateConstrainedBillboard (two independent epsilon fallbacks), CreateShadow/CreateReflection (normalization asymmetry), CreateOrthographic (shadow-map worked example, tied to real CNA test source) worked examples; Quaternion Concatenate-vs-Multiply and Lerp-vs-Slerp angular-velocity findings (both numerically verified); Plane::Transform inverse-transpose finding (numerically verified); Point and CurveKeyCollection full references; Rectangle IsEmpty corrected; Ray second worked example; BoundingBox-specific, BoundingFrustum-specific, and BoundingSphere::Transform (non-uniform-scale, numerically verified) worked examples; (depth pass, fresh gap found via header/test diff) added a genuinely new worked example — `Curve`'s real `.xnb`/`.cnj` content-pipeline support, previously undocumented anywhere in this chapter, quoting a real `CnjCurveTests.cpp` fixture in full and correcting a plausible-but-wrong reading of its own `continuity: "Step"` field (only meaningful with a third key, not visible in this two-key fixture) | **In progress (~34 of ~110 pages) --- four sessions now focused on this chapter; still well short of target, see PLAN.md session log for what's still missing** |
| 8 | Content and Assets | 242 (was 125) | 55 | Added ContentManager reference + manifest worked example; (depth pass) quoted two real .cnj files directly from cnj.md (a self-contained SpriteFont document and a Texture2D sourceFile/colorKey metadata sidecar); fixed two pre-existing overfull-hboxes | **In progress (~6 of ~55 pages, PDF-verified clean)** |
| 9 | GraphicsDevice | 910 (was 171) | 90 | Full method-by-method docs for the 887-line header; two real, verified backend-specific gaps found and documented (SpriteBatch can't sample a RenderTarget2D; SupportsCapability(MultipleRenderTargets) always returns true even where MRT silently fails); full private-implementation lifecycle section (window/backend/virtual-resolution) traced from GraphicsDevice.cpp, ties directly to Ch.6's PresentationMode; new GraphicsAdapter multi-monitor enumeration + a third real gap (IsProfileSupported/QueryRenderTargetFormat/QueryBackBufferFormat are only genuinely hardware-checked on D3D9, honestly documented as `true`/simplified stubs on the other nine backends); (depth pass, fresh gap found via source diff) added a new subsection on `ExtractMatrices`, the internal free function in `GraphicsDevice.cpp` (not in the header) that pulls World/View/Projection from the applied `Effect` via `dynamic_cast<IEffectMatrices*>` at every one of 7 draw-dispatch call sites — previously undocumented, ties together Ch.13/15/21's effect chapters with this chapter's own draw dispatch; found and fixed 6 pre-existing overfull-hboxes in the same section while reading it (item labels with combined multi-method signatures were the common cause) | **In progress (~24 of ~90 pages)** |
| 10 | SpriteBatch | 268 (was 131) | 55 | Added a `Draw` overload-family reference table (longtable, wraps correctly) and two worked examples (rotate-around-center via `origin`, tied to the SDL\_RENDERER pivot bug already covered; `MeasureString`-based text centering); (depth pass) added the `SpriteSortMode::Texture` pointer-sort non-determinism finding (Task~668/414) and a full worked section on `Begin()`'s lasting `GraphicsDevice.BlendState` side effect (Task~956 fix + still-open Task~933 caveat, both real, sourced from `migration-guide.md` and the EasyGL blend-leak regression test) | **In progress (~6 of ~55 pages, PDF-verified clean)** |
| 11 | Textures and Render Targets | 318 (was 207) | 60 | Added a worked `Texture2D` example (procedural checkerboard via `SetData`/`GetData`), incl. a real finding that `SetData`/`GetData` have no generic-template overload unlike real XNA's `T[]` form; fixed a pre-existing overfull-hbox in the `VertexBuffer` struct list; (depth pass) added a `TextureCube` six-face worked example and a `RenderTargetCube` render-into-face worked example (`GraphicsDevice::SetRenderTarget(RenderTargetCube*, CubeMapFace)`, verified against the real header — not a `RenderTargetBinding*` overload as a first draft assumed), tying both directly to the chapter's already-documented EasyGL/Vulkan/BGFX render-target divergence | **In progress (~8 of ~60 pages, PDF-verified clean)** |
| 12 | Models and Meshes | 252 (was 103) | 60 | Added two worked examples: the classic per-mesh bone-transform draw loop (grounded in real `CopyAbsoluteBoneTransformsTo`/`IEffectMatrices` signatures, tied to the two-loaders `ParentBone` gap), and an `AnimationPlayer` example adapted directly from its own two-bone test fixture, incl. the `GetWorldTransforms` vs `GetSkinTransforms` distinction verified against the real `.cpp`; (depth pass) added a full `MorphTargetEXT` worked example adapted from `MorphTargetEXTTests.cpp`'s own two-target fixture (additive combination, normal renormalization, `EvaluateMorphWeightsEXT`'s three interpolation modes) | **In progress (~8 of ~60 pages, PDF-verified clean)** |
| 13 | Stock Effects | 360 (was 191) | 80 | Added a worked `BasicEffect` example (lit, textured cube), incl. a real `EnableDefaultLighting()`-ordering hazard verified against its own `.cpp` implementation (it unconditionally overwrites `DirectionalLight0-2` every call); (depth pass) added worked examples for all 4 remaining stock effects, each tied directly to that effect's own already-documented audit findings — `AlphaTestEffect` (cutout fence, Vulkan/BGFX `VertexColorEnabled` no-op), `DualTextureEffect` (lightmapped floor, the doubled-RGB blend fix), `EnvironmentMapEffect` (chrome car body, Fresnel/lerp/normal-transform fixes), `SkinnedEffect` (driven from Ch.12's `AnimationPlayer` example, `MaxBones`/`WeightsPerVertex` gating) | **In progress (~10 of ~80 pages, PDF-verified clean)** |
| 14 | State Objects | 319 (was 159) | 55 | Added a worked example making the chapter's own by-value-not-by-reference architectural finding concrete: mutating a `BlendState` after assigning it to the device has no effect, mutating through `getBlendStateProperty()` does, verified against the real `setBlendStateProperty(const BlendState&)` signature; (depth pass) added worked examples for the remaining 3 state classes — `DepthStencilState` (two-pass stencil-masked mirror reflection), `RasterizerState` (shadow-map depth bias + wireframe debug toggle), `SamplerState` (pixel-art `PointClamp` vs. a mipmapped floor needing `PointMipLinear` for CNA's mip-unaware-plain-filters deviation); found and fixed one new overfull-hbox from a too-long ternary in the RasterizerState example (restructured to if/else) and one genuinely pre-existing overfull-hbox in the SamplerState prose (long overload-name list, restructured into shorter clauses) | **In progress (~9 of ~55 pages, PDF-verified clean)** |
| 15 | Shader/.fx Gap | 192 (was 78) | 30 | Corrected a real, significant inaccuracy: the chapter previously said `ShaderEffect` exists only on the three Direct3D backends with HLSL source, but `CreateEffectBackend()` is real on EasyGL/Vulkan/BGFX/SdlGpu too (EasyGL alone has 38 real tests, GLSL source) — rewrote both the main section and "honest summary" to match; added a worked GLSL example adapted from a real EasyGL test; (depth pass) added a matching real D3D9 HLSL worked example (adapted from `d3d9_spritebatch_customeffect_test.cpp`, the same color-inversion technique in SM2/SM3 syntax), incl. a real minor doc-comment inaccuracy noted (`ShaderEffect`'s own header calls itself "GLSL-source-based" despite compiling this HLSL just as validly) | **In progress (~7 of ~30 pages, PDF-verified clean)** |
| 16 | Backend Architecture | 222 (was 133) | 40 | Added an `ISpriteBatchBackend` deep-dive tying Ch.10's SDL_RENDERER transform-matrix bug to its real no-op default (and a new finding: no `GraphicsCapability` value exists to ask about it), plus a worked `SupportsCapability` example; fixed three pre-existing overfull-hboxes; (depth pass) added `IRenderTargetBackend` deep-dive (ties `GetMultiSampleCount()`/`HasRealDepthBuffer()` defaults directly to Ch.11's per-backend render-target findings) and an `IEffectBackend`/`IOcclusionQueryBackend` deep-dive (real finding: every `IEffectBackend::SetUniform*` setter defaults to a silent no-op, same shape as the SpriteBatch transform-matrix gap, one level deeper than Ch.15's `IsEffectValid()` check) | **In progress (~7 of ~40 pages, PDF-verified clean)** |
| 17 | SDL_Renderer Backend | 188 (was 115) | 55 | Added a worked example showing this backend's real `SupportsCapability` override (unconditional `false` for all eight values, verified against the real header) as the "ask, don't catch" pattern in concrete use, contrasted with Ch.16's `MultipleRenderTargets` finding; (depth pass) added a concrete pixel-value worked example for the blocked Wrap/Mirror decision, adapted from `sdlrenderer_texture_address_mode_clamp_test.cpp` (2x1 red/blue texture, oversized source rect, PointClamp correctly gives blue, PointWrap wrongly also gives blue instead of the XNA-correct red) | **In progress (~5 of ~55 pages, PDF-verified clean)** |
| 18 | EasyGL Backend | 154 (was 100) | 65 | Added a worked example computing the exact SpriteBatch quad ceiling (16,384) from the chapter's own `uint16_t`-index finding, with practical mitigations for a game likely to approach it; (depth pass) **stale-claim correction**: the two "real, large, whole-primitive bugs" from the D3D9-oracle cross-measurement (negative-`FogEnd` solid-black, Fresnel Gouraud-interpolation) were logged as open in `d3d9-divergence-report.md` but are BOTH fixed in the current source — verified directly by reading `EasyGLGraphicsBackend.cpp`'s own Task~1111/1112 fix comments (which name the exact failing oracle scene) and hand-checking the corrected fog formula's arithmetic against the scene's real `FogStart=0`/`FogEnd=-1` values | **In progress (~5 of ~65 pages, PDF-verified clean)** |
| 19 | Vulkan Backend | 186 (was 110) | 65 | Added a worked `OcclusionQuery` culling example (real `Begin`/`End`/`getIsCompleteProperty`/`getPixelCountProperty` surface), incl. a restated rule for the chapter's own render-pass-boundary summing gap; (depth pass) expanded Ch.11's one-sentence `RenderTargetCube` black-render preview into a full section naming both root causes (Task~875 clear-only-RT gap with a worked trigger example; Task~876 still-unresolved between two named candidates), sourced from `docs/rendertarget-support.md`; found/fixed one new overfull-hbox (`GetOrCreateEnvMapDescSet`, restructured into two sentences) | **In progress (~6 of ~65 pages, PDF-verified clean)** |
| 20 | BGFX Backend | 149 (was 87) | 55 | Added a worked example checking a `VertexDeclaration` for a `Color` attribute (real `VertexElement`/`VertexElementUsage` accessors) to recognize the black-mesh bug's real trigger condition ahead of time; (depth pass) added the full wrong-handle-type-cast diagnosis Ch.19 previewed for Vulkan's own comparison (Tasks 873/874, sourced from `docs/rendertarget-support.md`, explaining precisely why the cast compiles and doesn't crash — both handle types share an identical `struct{uint16_t idx;}` ABI shape); fixed two pre-existing/newly-introduced overfull-hboxes and one running-header/folio collision (`\section[short]{long}`) | **In progress (~6 of ~55 pages, PDF-verified clean)** |
| 21 | WebGPU Backend | 178 (was 108) | 45 | Added a worked example walking through the still-open `RenderTargetCube` sprite-geometry bug (real `SetRenderTarget` call), showing the silent-wrong-size failure mode and its practical mitigation; (depth pass) added a full worked `PbrEffect` example (first coverage anywhere in the book of this NOXNA glTF-2.0 metallic-roughness material, incl. verifying the G=roughness/B=metallic channel packing directly against the real EasyGL GLSL shader source); fixed two character-wrap code-listing overflows (one pre-existing) | **In progress (~7 of ~45 pages, PDF-verified clean)** |
| 22 | Direct3D Backends | 207 (was 152) | 85 | Added a worked example computing exactly why `zFarPlane=1` vs `-1` mattered (D3D9's [0,1] clip-space Z range vs. XNA's `layerDepth` range), placed correctly after the bug's own first mention (moved once after an initial ordering mistake caught before commit); (depth pass) added a worked example quoting a real oracle scene file in full (`colored3d.scene`, 11 lines), tying its declarative flags directly to Ch.13's `BasicEffect` coverage and cross-referencing Ch.18's `fog_gradient_quad` scene as the same format scaled up | **In progress (~5 of ~85 pages, PDF-verified clean)** |
| 23 | Canvas/ASCII Backends | 197 (was 139) | 40 | Added a worked pixel-to-glyph example (hand-computed luminance/ramp-index math for a real color, verified arithmetically) tied to why the `BlendState.AlphaBlend` bug was easy to miss visually; fixed a pre-existing overfull-hbox; (depth pass) added a matching worked un-premultiply example for the CANVAS backend (real numbers through the actual per-pixel formula in `CanvasSpriteBatchBackend.cpp`, explaining bug #2's root cause arithmetically) | **In progress (~5 of ~40 pages, PDF-verified clean)** |
| 24 | DX3/free-direct Backend | 129 (was 65) | 30 | Fixed a stale plain-text cross-reference ("Chapters~6 and~5") to real `\ref{}`s; added a worked example with real `BlendState::AlphaBlend` factors (verified against `BlendState.cpp`) showing why the bug is visible for `AlphaBlend` but was harmless for `Opaque`'s own degenerate factors — a math error caught and corrected in this session's own draft before commit; (depth pass) added a direct, parallel worked example to Ch.17's SDL_RENDERER Wrap/Mirror gap, adapted from the real `dx3_sampling_test.cpp` (identical 2-texel red/green setup, this backend gets the correct wrap/mirror/clamp answer where SDL_RENDERER cannot) | **In progress (~4 of ~30 pages, PDF-verified clean)** |
| A | API Quick Reference | 316 (was 229) | 40 | Added the previously-missing `GraphicsDevice` and four state-object classes as a new section (grouped by real property/method shape, read directly from `GraphicsDevice.hpp`), the most glaring omission from an appendix otherwise covering every other Part II/III class; fixed three pre-existing overfull-hboxes; (depth pass) added a new section covering `VertexBuffer`/`IndexBuffer`/Dynamic variants, the `Effect` base class + `EffectParameter`'s full `GetValueXxx`/`SetValueXxx` surface, and `OcclusionQuery` — three classes used throughout Parts III-IV with no quick-reference entry until now; found/fixed one new overfull-hbox | **In progress (~7 of ~40 pages, PDF-verified clean)** |

**Volume I subtotal: ~1,305 pages.**

## Parts V–IX (formerly "Volume II") — target ~1,200 pages (chapters 25–48 + Appendices B–F)

Merged into a single book on 2026-07-20. Chapter and appendix numbers below are the
**post-merge** numbers (originally chapters 1–24 and Appendices A–E within old Volume II;
the renumbering table is in the 2026-07-20 session log entry below if the old numbers are
ever needed).

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 25 | Input System | 559 (was 534) | 70 | Added three more real findings from `plan_input.md` (GamePad's SDL_INIT_GAMEPAD shutdown-symmetry fix, Mouse's read-direction DPI-transform test-gap finding, GestureSample.Timestamp's deliberate non-replication of an FNA unit-mismatch bug); fixed five pre-existing newline-continuation `}/%` defects never caught before | **In progress (~12 of ~70 pages)** |
| 26 | Audio System | 438 (was 118) | 60 | Full method references + worked examples for SoundEffect, SoundEffectInstance/Apply3D 3D audio, DynamicSoundEffectInstance streaming, the AudioEngine/SoundBank/WaveBank/Cue XACT playback model, Microphone capture, AudioCategory retroactive volume, AudioEngine::RendererDetails, SoundEffect::FromStream, and the three audio exception types; (depth pass) mined `plan_audio20260717.md`'s Phase 14 (dated 2026-07-17, not previously used as a source) for two fresh, real bugs: `SoundBank::GetCue()`'s never-registered-until-Play() cue-lifetime gap (a held-but-unplayed Cue could outlive its bank), and `DynamicSoundEffectInstance`'s byte-accounting bug (popped a whole chunk for one byte of real consumption, worked through with the audit's own real timing numbers) | **In progress (~10 of ~60 pages)** |
| 27 | Media | 315 (was 103) | 45 | Full method references + worked examples for Song, the AudioTagParser tag-reading pipeline, MediaQueue's ownership model, MediaPlayer playback/shuffle/repeat internals, VideoPlayer multi-track switching (three real bugs found by external review), and the GetVisualizationData FFT pipeline (lock-free ring buffer + from-scratch radix-2 FFT); (depth pass) mined `plan_media.md`'s Phase 16 Group B for a fresh finding not yet covered — MEDIA-181, `Song::TrackNumber` silently discarded one call-layer above a correctly-working tag parser, caught by a real mutation-verified fixture using 4 distinct non-identical track numbers | **In progress (~7 of ~45 pages)** |
| 28 | Devices and Sensors | 244 (was 115) | 45 | Worked examples for Accelerometer/VibrateController/Camera grounded in real headers, plus the SetCurrentValueAndMarkDataValid race-closing finding and the vibrate intensity-zero-is-not-Stop() finding; (depth pass) mined `plan_devices.md`'s LIFE-001 (dated 2026-07-17) for a fourth concurrency finding: a genuine TSan-only-detectable race discovered inside an already-CLOSED two-phase Start/Stop fix (orphaned-start cleanup racing a fresh Start, real heap corruption under an 8-thread stress test) — a second, deeper instance of the same "closed label isn't proof" methodology point Ch.18 made for EasyGL | **In progress (~7 of ~45 pages)** |
| 29 | GamerServices | 207 (was 117) | 55 | Worked examples for SignedInGamer achievements/presence, LeaderboardWriter scoring, and Guide's real overlay message-box UI, grounded in real headers; (depth pass, mined `plan_net.md` Phase 4 Task 4.5, no dedicated GamerServices plan doc exists) added a worked example on exactly which `Achievement` fields `GetAchievements()` actually populates — `Key`/`IsEarned`/`EarnedDateTime` are real, but `Name`/`Description`/`GamerScore` stay at fixed defaults since real XNA's own `AwardAchievement` carries no catalog metadata at all | **In progress (~6 of ~55 pages)** |
| 30 | Networking | 243 (was 170) | 70 | Added a full worked account of host migration (the min-wire-ID deterministic promotion algorithm, the HostChanged event, the reconnect-via-LAN-discovery path), grounded in `plan_net.md` Phase 5 and the real headers; added a fifth real bug (GamerCollectionEnumerator::MoveNext() null-deref after Dispose()) with a worked repro; fixed two pre-existing newline-continuation `}/%` defects; (depth pass) mined `plan_net.md`'s ENetBackend.cpp source directly for the pre-handshake queue's real bound (64, oldest-evicted-first) and its internal `GetDroppedAppDataCount()` diagnostic counter, not previously named with specifics | **In progress (~8 of ~70 pages)** |
| 31 | Avatar | 211 (was 131) | 55 | Worked examples for the faithful-vs-real-rendering bridge (EnableRealRenderingEXT/DrawRealEXT) and wardrobe hot-swapping (AttachPartEXT/RemovePartEXT), grounded in real headers; (depth pass) mined `plan_net.md`'s Phase 15 (2026-07-18) for two fresh lighting bugs found via avatar work: `DrawRealEXT`'s `EnableDefaultLighting()`-after-custom-ambient ordering bug (verified fixed against the real, currently-shipping source and its own explanatory comment), and EasyGL's project-wide EmissiveColor-double-multiplied-by-DiffuseColor formula bug (real before/after near-black-pixel percentages, 4.1-6.0% to 0.0%) | **In progress (~5 of ~55 pages)** |
| 32 | Storage | 152 (was 78) | 30 | Worked examples for the full device-selection-to-open-container lifecycle and file read/write, plus the unique_ptr-ownership finding, grounded in real headers; (depth pass, no dedicated plan doc — found by reading `StorageContainer.cpp` directly) added a real, previously-undocumented finding: `ResolvePath()`'s entire implementation is `(fs::path(storagePath_) / relative).string()` with no `..`-traversal guard anywhere in the namespace, only an empty-string check — confirmed against both the header docs and test suite, neither of which mention it as a scoped decision | **In progress (~4 of ~30 pages)** |
| 33 | Sharp Runtime Overview | 177 (was 116) | 40 | Worked examples for MulticastAction token-based removal and Task::ContinueWith's synchronous-execution contract, grounded in real headers; (depth pass, mined sharp-runtime's own `NEXT.md`, dated 2026-07-14) corrected/extended the version-counter finding from a 2-type pattern to project-wide (10 types), plus `OrderedDictionary::EnsureCapacity`'s own follow-up version-bump fix | **In progress (~6 of ~40 pages)** |
| 34 | Sharp Runtime Namespaces | 257 (was 162) | 70 | Added two more real audit findings as worked examples (Dictionary's operator[] ValueProxy fix, ConcurrentDictionary::GetOrAdd's reentrancy-deadlock fix), grounded in `POST_STABILIZATION_AUDIT.md` and confirmed both fixes are live in the real headers; (depth pass) mined sharp-runtime's own `audit.md`-remediation findings (A-01 through A-07, dated 2026-07-14, distinct from the already-covered post-stabilization audit) for a third, previously-uncovered worked example: `TaskCompletionSource::TrySetResult`'s claim-then-publish race (A-04) — a throwing `TResult` copy ctor used to strand every waiter forever; fixed a running-header/folio collision the new content's page shift exposed | **In progress (~8 of ~70 pages)** |
| 35 | Parity Philosophy | 134 (was 111) | 35 | Worked example contrasting the three delegate tiers (Action/Func alias, System::Delegate::Combine/Remove, MulticastAction), grounded in real headers | **In progress (~6 of ~35 pages)** |
| 36 | EasyGL Deep Dive | 190 (was 112) | 55 | Worked examples for Device's per-feature capability gating and the Program::uniform_block_index/Framebuffer typed-reference fixes, grounded in real headers; also fixed two pre-existing single-long-identifier overfull-hbox defects; (depth pass, mined easy-gl's own `NEXT.md`) added worked examples for two real RAII additions added after the chapter's original pass — `ScopedDebugGroup` (exception-safe debug-group balancing) and `UniformCache` (with the real, undocumented "a failed lookup is memoized too" behavior noted, verified against the actual .cpp) | **In progress (~6 of ~55 pages)** |
| 37 | free-direct Deep Dive | 65 | ~2 (no change) | **Stays marginal per author confirmation 2026-07-20 — do not expand** | N/A — intentionally frozen |
| 38 | Windows/Wine | 168 (was 103) | 45 | Real shell-invocation worked examples for the MinGW-w64 toolchain and the DXVK self-verifying gate (including its two escape hatches), grounded in the actual scripts; (depth pass, mined `cna`'s own root `NEXT.md`) added a real D3D9 API restriction found closing out D9-30/D9-31 — DXVK correctly refuses `D3DFMT_A8B8G8R8` as a swap-chain format (legal for a texture, illegal for the back buffer), fixed with a back-buffer-only substitution to `A8R8G8B8` | **In progress (~5 of ~45 pages)** |
| 39 | Web/Emscripten | 121 (was 88) | 40 | Real shell-invocation worked examples for the Emscripten-specific compile/link flags and the confirmed CANVAS build success story, grounded in the actual CMakeLists.txt/cmake/UnitTests.cmake | **In progress (~3 of ~40 pages)** |
| 40 | Android/NDK | 168 (was 82) | 40 | Real shell-invocation worked examples for the NDK cross-compile/llvm-nm verification and the emulator boot/install/sensor-injection sequence, grounded in the project's own build notes; (depth pass, mined `plan_devices.md`'s ANDR2-003) added a real, general-lesson concurrency bug: a genuine bounded 5s timeout in the Android sensor bridge's `Start()` was defeated by an unconditional `join()` immediately afterward in `Stop()`'s cleanup path, affecting 3 call paths at once; fixed with a second bounded wait plus a sticky `abandoned_` flag and `detach()` fallback | **In progress (~5 of ~40 pages)** |
| 41 | Verification Methodology | 83 (was 68) | 35 | Added a macOS row to the comparative table (a genuine, honestly-named documentation gap: no dedicated chapter exists for it), plus fixed a stale "Part~IV" cross-reference left over from the volume merge | **In progress (~3 of ~35 pages)** |
| 42 | Migration Guide | 175 (was 102) | 55 | Worked examples for the C#-to-CNA Update()/Draw() mechanical translation (signatures verified against Game.hpp) and hand-computing a custom vertex format's byte stride against the five recognized strides; (depth pass) cross-referenced Ch.29's fresh Achievement-fields finding into Step 4 as a concrete, actionable porting gotcha (achievement-toast UI reading Name/GamerScore directly will compile clean and render blank) | **In progress (~5 of ~55 pages)** |
| 43 | Blupi Case Study | 196 (was 116) | 55 | Added a new performance-audit section (measured BltFast/memcpy benchmarks, the CMAKE_BUILD_TYPE default-build finding, exact call-site line numbers in both games, and a confirmed-dead-code call site), grounded in `free-direct/docs/audit_ddraw.md`; (depth pass) investigated an apparent contradiction between this chapter's own BltFast counts (6/5) and `directplay-callsite-audit.md`'s newer re-count (18/17) by independently re-grepping both real game repos line-by-line — confirmed BOTH numbers are correct, just scoped to different questions (real DirectDraw-interface calls vs. every raw occurrence incl. each game's own wrapper method), added as a worked methodology lesson rather than a correction, since neither number was actually wrong | **In progress (~6 of ~55 pages)** |
| 44 | xna4-spec Auditing | 117 (was 74) | 40 | Added a full worked member-by-member audit of \cnaclass{Ray} against `xna4-spec`'s own XML, grounded in the real header; fixed a pre-existing long-URL overfull-hbox defect found while verifying | **In progress (~4 of ~40 pages)** |
| 45 | Samples and Examples | 133 (was 54) | 45 | Corrected an imprecise claim ("every one of the 23 failures traces to the same root cause") with a real, checked-per-sample breakdown into three distinct root causes; added the SimpleAnimation "Done can still hide a bug" finding, grounded in `cna-samples`' own `PLAN.md`/`DEFERRED.md`/`missing.md` files; (depth pass, mined `cna-samples`' own `NEXT.md`) added two real framework bugs found via samples, not unit tests — LensFlare's still-open `ColorWriteChannels`/EasyGL gap (verified no `glColorMask` call exists), and `GraphicsDevice::Clear(Color)`'s once-real depth-buffer-not-cleared bug, verified fixed in the current source (Task 928) | **In progress (~5 of ~45 pages)** |
| 46 | Project Practice | 178 (was 100) | 40 | Added a real task entry (`ASCII-40`) quoted almost in full from `plan_ascii.md`, plus a new finding on the task-splitting convention (Task~868→923, Task~878→899) grounded in `plan_graphics.md`; (depth pass) added a synthesizing section citing 4 independently-confirmed, first-hand instances of this session's own "stale CLOSED status" pattern across unrelated subsystems (Ch.18 EasyGL, Ch.28 Android TSan, Ch.45 Clear-depth) as concrete, first-person evidence for this chapter's own abstract argument | **In progress (~6 of ~40 pages)** |
| 47 | Testing Philosophy | 157 (was 103) | 45 | Added a real worked pixel test (`sdlrenderer_transform_matrix_test.cpp`) quoted directly, showing the transformMatrix bug's own discovery mechanism; fixed a genuine 95pt-overfull identifier defect found while verifying; (depth pass) extended the sanitizer section with sharp-runtime's own first full sanitizer-trio run (Channel notify_all deadlock, heap-buffer-overflow, miniz UB) and the Android LIFE-001 TSan-inside-a-closed-fix finding, both cross-referenced from their own chapters | **In progress (~5 of ~45 pages)** |
| 48 | Roadmap | 137 (was 82) | 30 | Added a real seven-backend comparison table for the Texture3D/TextureCube sampler-bind gap, grounded in `docs/graphics-backend-feature-matrix.md`; verified all four named architecture-decision gaps are still current (no drift found); fixed a genuine overfull-hbox defect (a long path) found while verifying, plus an identical pre-existing one caught incidentally in Chapter 10; (depth pass) strengthened the closing cross-platform-validation section with 3 concrete precedents from this pass (Android bounded-timeout, sharp-runtime Channel deadlock, D3D9 swap-chain format), showing the roadmap item already has real momentum, not just aspiration — **this is the last chapter in the book; task #41 is now complete** | **In progress (~5 of ~30 pages)** |
| B | Feature Matrix | 67 (was 58) | 15 | Fixed a real, stale defect: every "See" column entry used a leftover plain-text "Ch.~N (Vol.~I)" citation from the pre-merge two-volume era (no longer accurate — there is no "Vol. I" anymore); converted all 12 to real `\ref{}`s, verified against real chapter labels (0 undefined refs after rebuild); enriched several rows with fresh findings from this session's own depth pass (EasyGL's two now-fixed oracle bugs, Vulkan/BGFX's distinct RenderTargetCube diagnoses, D3D9's swap-chain format fix, DX3's verified Wrap/Mirror win) | **In progress (~2 of ~15 pages)** |
| C | Glossary | 89 (was 74) | 15 | Added 4 new entries (ContentManager, ENet, GraphicsCapability, PbrEffect); fixed a pre-existing misalphabetization ("Storage" was stranded after "xna4-spec"); fixed one new overfull-hbox found while verifying | **In progress (~3 of ~15 pages)** |
| D | Repo Map | 136 (was 127) | 20 | Added a real, genuinely missing repository (`free-api`, `free-direct`'s own second-level dependency, verified as a real substantial repo) with a paragraph explaining why a first-level-only dependency list misses it, cross-referenced to the Ch.2 finding that discovered it | **In progress (~3 of ~20 pages)** |
| E | NOXNA Catalog | 131 (was 114) | 20 | Added 3 genuinely missing Graphics-section entries (`PbrEffect`, `AnimationPlayer`, `MorphTargetEXT` — all entirely NOXNA, all already covered narratively in Ch.12/21 but never catalogued here) and `ContentManager`'s 3 build-auditing NOXNA methods to the Content section | **In progress (~3 of ~20 pages)** |
| F | API Quick Reference: Ecosystem and Platforms | 181 (was 155) | 25 | Added a genuinely missing section, F.4 Storage: StorageDevice and StorageContainer (this appendix had Input/Audio/Networking/GamerServices/SharpRuntime-core-types quick-reference sections but no Storage entry at all, despite it being covered in depth in Ch.32) — grounded in a fresh header re-verification, closing with a cross-reference to the real, still-open `..`-path-traversal gap Ch.32 documents | **In progress (~4 of ~25 pages)** |

**Parts V–IX subtotal: ~1,163 pages** (the 1,195 estimate above included a ~35-page target for
Ch.37 that is now frozen at ~2 pages per the author's confirmation above).

**Combined book target: ~2,468 pages** (Parts I–IV ~1,305 + Parts V–IX ~1,163), against a
current real total of 266 pages.

## Session log

- **2026-07-20 (this session):** Author restated the original 1000–2000-page/volume target
  and asked for this plan. Asked 3 scoping questions (expansion style, structure, pace) via
  AskUserQuestion; answers recorded above. Surveyed current per-chapter line counts for both
  volumes. Wrote this file with per-chapter Phase 1 page targets summing to ~1,305 (Vol. I)
  and ~1,195 (Vol. II). Flagged the free-direct and cna-extended scope conflicts. Execution has
  not yet started — next session should begin with Volume I Chapter 7 (Math and Core Types) or
  Chapter 9 (GraphicsDevice), the two largest, most mechanically tractable targets (full method
  documentation pulled directly from already-read headers), to establish the expanded-chapter
  template other chapters will follow.
- **2026-07-20 (same session, follow-up):** Author added two requirements: every chapter needs
  real code examples (already implied, now explicit), and graphics chapters should have real
  screenshots of running examples where feasible — with an explicit rule that screenshots must
  be genuine captures, never fabricated. Ran a background feasibility check: confirmed CNA's
  `SOFTWARE` backend can render and screenshot headlessly with no `DISPLAY`/GPU at all; found
  and patched (locally, saved to `tools/cna-screenshot-infra/`) a real pre-existing build gap
  in `ContentReader`; produced and visually verified one real sample PNG. Findings and a
  reproduction guide saved to `tools/cna-screenshot-infra/README.md`. Author separately
  confirmed free-direct (Vol.II Ch.13) and cna-extended stay marginal, resolving the conflict
  flagged earlier — Ch.13's target reverted to "no change," Vol. II subtotal adjusted to
  ~1,163 pages. Execution of the actual chapter expansions still has not started; that remains
  the very next step for whichever session picks this up next.
- **2026-07-20 (same session, execution started):** Added `CLAUDE.md` (durable project guide)
  and `NEXT.md` (short, overwritten-each-session handoff briefing) for cross-session
  continuity. Started Volume I Chapter 9 (GraphicsDevice), the first chapter actually
  expanded: re-read the full 887-line header, kept the existing accurate narrative sections,
  and added full coverage of render targets, vertex/index buffer binding, the complete
  `DrawUserPrimitives`/`DrawUserIndexedPrimitives` overload family (17 overloads total),
  back-buffer readback, and all `NOXNA` helper/diagnostic methods — none of which the original
  chapter covered at all. Built CNA's `SOFTWARE` backend from the patch in
  `tools/cna-screenshot-infra/`, wrote a `GraphicsDevice`-focused worked example (raw
  `SetVertexBuffer`/`DrawPrimitives` calls, no `SpriteBatch`), ran it headlessly, and embedded
  the real resulting screenshot (`latex/volume1/images/ch09-drawprimitives-software.png`) with
  a `Figure` environment — verified by rendering the actual compiled PDF page to confirm the
  image displays correctly. Chapter grew from 171 to 556 lines, ~4 to ~13 pages (against a
  90-page target — real, verified progress, not yet complete). This chapter now establishes
  the template — narrative kept, full method-by-method reference added per section, one real
  worked example with a real screenshot where feasible — for every subsequent chapter. Volume
  I recompiled clean (123 pages total, 577 index entries, 0 undefined references). Not yet
  committed as of this log entry — see the actual commit log for what landed.
- **2026-07-20 (same session, Chapter 7 started):** Moved to Volume I Chapter 7 (Math and Core
  Types) to validate the Chapter 9 template on a structurally different chapter (many small
  types sharing one method shape, rather than one large class). Added a full method reference
  for the shared `Vector2`/`Vector3`/`Vector4` operation set (documented once since all three
  share it identically) and a full `Matrix` factory-method reference (all ~15 `CreateXxx`
  forms). Registered a second CMake demo target (`cna_math_rotation_demo`, added to
  `tools/cna-screenshot-infra/` alongside the Chapter 9 demo and an updated patch file covering
  both), built and ran it headlessly: a real `Matrix::CreateRotationZ`/`CreateTranslation`/
  `CreateLookAt`/`CreatePerspectiveFieldOfView` chain rotating a triangle 30 degrees, confirmed
  genuinely rotated (not the unrotated upright triangle a stubbed transform would produce) by
  visually inspecting the actual compiled PDF page. Chapter grew from 270 to 471 lines. The
  remaining 7 of 11 type-families (Quaternion, Point, Rectangle, Color, Plane, Ray, the three
  Bounding types) plus MathHelper and Curve/CurveKey are **not yet** expanded to the same
  depth — still at their original narrative-summary level. Volume I recompiled clean (127
  pages total, 598 index entries, 0 undefined references).
- **2026-07-20 (same session, Chapter 7 completed to first-pass depth):** Continued straight
  through the remaining 7 type-families rather than stopping at Vector/Matrix: added full
  method/constructor references for Quaternion, Plane, Ray, Rectangle, Color, MathHelper, and
  the shared BoundingBox/BoundingSphere/BoundingFrustum operation set, each with a worked code
  example (Slerp-based turning, ray/sphere picking, rectangle clamping, frustum culling, a
  Curve-driven camera flythrough). Every one of the 11 type-families this chapter covers now
  has at least a full method reference and one worked example — the chapter is no longer
  lopsided toward just Vector/Matrix. Chapter grew from 471 to 758 lines (~22 of ~110 target
  pages — real depth added throughout, but there is still plenty of room to go deeper per type
  before the page target is actually reached; treat "every type covered once" as this pass's
  real accomplishment, not "chapter complete"). Volume I recompiled clean (131 pages total,
  632 index entries, 0 undefined references).
- **2026-07-20 (same session, Chapter 9 deepened — found a real bug):** Per author instruction
  to keep deepening an in-progress chapter, returned to Vol.I Ch.9 (GraphicsDevice) and built a
  third worked example: a render-target round trip (draw into an offscreen `RenderTarget2D`,
  restore the back buffer, draw the render target's own content back as a `SpriteBatch` inset).
  Registered a third CMake demo target (`cna_rendertarget_roundtrip_demo`); numerically verified
  via `GetBackBufferData` that the render target was drawn into correctly (`R=255 G=144 B=0`,
  matching the triangle) while still bound. Running the full example surfaced a real,
  live-discovered bug rather than a clean success: the `SpriteBatch`-drawn inset renders blank
  white instead of the verified-correct offscreen content. Traced the root cause directly in
  `SoftwareGraphicsBackend.cpp`: `SoftwareSpriteBatchBackend::Draw`'s
  `dynamic_cast<const SoftwareTextureBackend*>(&texture)` fails silently for a
  `RenderTarget2D`'s backend (`SoftwareRenderTargetBackend`, a sibling class under
  `ITextureBackend`/`IRenderTargetBackend`, not a subclass of `SoftwareTextureBackend`) — an
  inconsistency with the raw `DrawPrimitivesEx`/`DrawIndexedPrimitivesEx` paths, which throw a
  real `std::runtime_error` for the same null-texture case instead of silently drawing
  untextured. Wrote this up honestly in the chapter as a `sourcenote` finding with the actual
  (partially broken) screenshot as evidence, per this project's "real or not at all" rule —
  did not hide the gap or fake a working result. Chapter grows from 556 to 622 lines (~13 to
  ~16 of a ~90-page target). Volume I recompiled clean (131 pages total, 636 index entries, 0
  undefined references). This finding, the demo source, and the updated CMake patch are all
  preserved in `tools/cna-screenshot-infra/` for reproducibility.
- **2026-07-20 (same session, Chapter 9 deepened further):** Continued on Ch.9 per author
  instruction. Added a multiple-render-target (MRT) subsection: read every backend's own
  `SetRenderTargets` override directly rather than assuming uniform support, confirmed EasyGL
  genuinely implements per-target MRT while the `SOFTWARE` backend never overrides the shared
  `IGraphicsBackend` default (which silently binds only `rts[0]` and drops the rest, per its
  own doc comment) — deliberately did *not* screenshot an MRT example against `SOFTWARE`, since
  it would misleadingly look successful while only writing one of two targets; explained the
  gap from source instead. While writing a `SupportsCapability` worked example, found a related,
  second real gap: `GraphicsCapability::MultipleRenderTargets` exists in the enum but is never
  referenced by any backend's `SupportsCapability` override, so it returns `true` universally
  (via the interface's own "default: true for everything" fallback) even on `SOFTWARE`, where
  MRT demonstrably fails — the capability check that exists specifically to guard against this
  gap doesn't actually catch it. Also added worked examples for back-buffer readback (single-
  pixel probe) and a working `SupportsCapability(ThreeD)` pattern (verified against real
  SDL_Renderer/DX3/Canvas source, unlike the MRT capability). Chapter grows from 622 to 722
  lines (~16 to ~19 of a ~90-page target). Volume I recompiled clean (133 pages total, 638
  index entries, 0 undefined references).
- **2026-07-20 (same session, Chapter 9 deepened a third time):** Continued on Ch.9 again per
  author instruction. Read `GraphicsDevice.cpp` directly for the eight private methods behind
  construction/teardown/resize (`createOrAttachWindow`, `createBackend`,
  `destroyNativeResources`, `UpdateViewportFromWindow`, `SetVirtualResolution`,
  `SetPresentationMode`, `applyPresentationParametersToWindow`,
  `applySamplerStatesToBackend`) and added a new "Private implementation" section documenting
  each from its actual body, not just its declaration — including the real mechanism behind
  Chapter 6's `PresentationMode` enum (`SetVirtualResolution`/`SetPresentationMode` are the
  methods that actually forward it to the backend), the `HeadlessEXT`/no-window construction
  path's real three-way branch, and the `UpdateViewportFromWindow` subtlety about comparing
  against its own last-recorded size rather than the live `Viewport` (to avoid stomping a
  split-screen sub-viewport on every `Present()`). This is a real, useful cross-chapter tie-in
  (Ch.6 introduces `PresentationMode`; Ch.9 now explains how it actually reaches the backend),
  not just more prose for its own sake. Chapter grows from 722 to 790 lines (~19 to ~21 of a
  ~90-page target). Volume I recompiled clean (135 pages total, 641 index entries, 0 undefined
  references).
- **2026-07-20 (same session, back to Chapter 7 per author instruction):** Added a fourth
  screenshot demo (`cna_quaternion_vs_matrix_demo`, registered in the same CMake patch) that
  numerically and visually verifies `Matrix::CreateRotationZ(30°)` and the equivalent
  `Quaternion::CreateFromAxisAngle(Vector3::Backward, 30°) -> Matrix::CreateFromQuaternion`
  path produce identical results: max absolute difference across all 16 matrix components
  measured exactly `0`, and a transformed test point matched to 6 decimal places via both
  paths. Deliberately did not embed a second screenshot for this (it would be pixel-identical
  to the existing Figure 7.1) — cited the numeric proof and the existing figure instead, an
  explicit choice to avoid a redundant image. Added two more worked examples: Color's
  `FromNonPremultiplied` (why constructing a `Color` directly from straight-alpha data produces
  the wrong blended result under CNA's premultiplied-alpha pipeline) and Curve's
  `Cycle`/`Oscillate`/`CycleOffset` loop types (the three are easy to confuse from their names
  alone; explained precisely which produces a snap vs. a ping-pong vs. an accumulating repeat).
  Chapter grows from 758 to 840 lines (~22 to ~24 of a ~110-page target). Volume I recompiled
  clean (137 pages total, 643 index entries, 0 undefined references).
- **2026-07-20 (same session, "pokracuj na kapitolach 7 a 9"):** Deepened both chapters in one
  pass per author instruction. Ch.7: filled a real, previously undocumented gap —
  `Vector3::Cross` (the one shared-vector-family method that is genuinely Vector3-only, since a
  cross product has no Vector2/Vector4 equivalent) had never been mentioned anywhere in the
  chapter despite `Plane`'s own three-point constructor using it internally — added a worked
  example computing a triangle face normal from two edges, tied explicitly to that `Plane`
  constructor. Added four more second-worked-examples grounded in direct source reads: `Plane`
  (`DotCoordinate` as a half-space test, reading `Plane.cpp` to confirm the exact
  `DotNormal + D` relationship), `Rectangle` (`Intersect`/`Union` for scissor-clamping and
  dirty-rectangle merging), `MathHelper` (`WrapAngle`, including its real early-return fast
  path read from `MathHelper.cpp`), and `BoundingSphere` (`CreateFromPoints`, with an honest
  note — read from `BoundingSphere.cpp` — that it is a fast axis-extreme-pair approximation,
  not an exact minimum-enclosing-sphere solver). Chapter grows from 840 to 974 lines (~24 to
  ~28 of a ~110-page target). Ch.9: expanded the previously single-paragraph
  "GraphicsAdapter, DisplayMode" section into two new subsections. First, multi-monitor
  enumeration via the static `Adapters` list (`getAdaptersProperty()`), reading
  `GraphicsAdapter.cpp` to confirm its lazy-populate-once-then-cache contract and showing a
  worked example of enumerating displays and constructing a `GraphicsDevice` against a
  player-chosen adapter directly (there is no `GraphicsDeviceManager`-level adapter selector —
  `GraphicsDevice`'s own constructor and `Reset` take the adapter argument directly). Second, a
  third real, verified backend-specific gap: `IsProfileSupported`, `QueryRenderTargetFormat`,
  and `QueryBackBufferFormat` are only genuinely hardware-checked (real `D3DCAPS9`/
  `CheckDeviceFormat`/`CheckDeviceType` queries) on the D3D9 backend; the other nine backends'
  `#else` branches are honestly commented in the source itself (labelled `D9-101`/`D9-102`) as
  deliberately not faking a hardware capability table, falling back to unconditional `true` /
  simplified format checks / a hardcoded `SurfaceFormat::Color` result instead — the same
  category of finding as the `SupportsCapability(MultipleRenderTargets)` gap documented
  earlier in this chapter. Chapter grows from 790 to 872 lines (~21 to ~23 of a ~90-page
  target). Volume I recompiled clean (139 pages total, 654 index entries, 0 undefined
  references).
- **2026-07-20 (same session, "pracuj pouze na kapitole 7, zjisti co tam vše chybí a vše
  dokonči"):** Author asked to work exclusively on Chapter 7 and find/finish everything
  missing. Systematically grepped every type's real header against this chapter's existing
  prose to find genuine gaps rather than guessing what to add next, and found a chapter-wide
  one worth fixing first: `Equals`/`GetHashCode`/`ToString` are implemented by literally every
  type in this chapter (confirmed by grepping all eleven headers) but had never been mentioned
  anywhere in the chapter's text. Added a new `\section` right after the chapter intro
  documenting this shared triad once (rather than eleven times), which also let this pass make
  good on the intro's own claim about `CheckForNaNs()`/`getDebugDisplayStringProperty()` ---
  reading every header precisely rather than trusting the intro's generalization turned up two
  real findings: (1) neither helper is ever called from anywhere outside its own defining
  `.cpp` file anywhere in the codebase — no test, no example, no other framework class; no
  `.natvis` or LLDB summary-provider file exists either, so both are currently unreachable
  through any public code path; (2) the three vector types' `CheckForNaNs()` run
  unconditionally in every build, while `Matrix`'s and `Quaternion`'s are wrapped in
  `#if !defined(NDEBUG)` and compile to nothing in a release build — a real, harmless-for-now
  inconsistency. Also found and fixed a genuine accuracy gap in the vector "full method
  reference": it never mentioned `Length()`/`LengthSquared()`, despite the chapter's own very
  first worked example already calling `toTarget.Length()` without ever having named the
  method. Added: a full reference + worked example for `Point` (previously only described in
  passing inside the Rectangle section); a full reference for `CurveKeyCollection`'s
  `Count`/`IsReadOnly`/`Item`/`Clear`/`Clone`/`Contains`/`CopyTo`/`IndexOf`/`RemoveAt` (all
  read from and verified against the real `.cpp`, including `IndexOf`'s `-1` sentinel and
  `RemoveAt`'s `std::out_of_range` bounds check); a `Matrix` arithmetic-statics reference plus
  a `Decompose` worked example, which turned up two more findings while reading `Matrix.cpp`
  directly — `Decompose` only fails (returning `false`, with rotation reset to
  `Quaternion::Identity`) when an axis scale is within epsilon of zero, and that epsilon check
  is a locally-duplicated `WithinEpsilon` in `Matrix.cpp`'s own anonymous namespace (hardcoding
  `FLT_EPSILON` rather than calling `MathHelper::WithinEpsilon`, specifically to avoid a
  circular dependency, per the source's own comment), plus a documented, practically-harmless
  FNA-vs-CNA divergence in negative-zero sign handling; a Quaternion `Concatenate`-vs-`Multiply`
  finding — derived by hand from both methods' component formulas, then verified numerically
  with a standalone Python script across five random quaternion pairs — that
  `Concatenate(value1, value2)` computes exactly `Multiply(value2, value1)` (equivalently
  `value2 * value1` via the operator), meaning the ``value1 applied first'' reading
  `Concatenate` promises is actually the right-to-left reading of `operator*`/`Multiply`, not
  the left-to-right one the method's own argument order suggests; a second `Ray` worked
  example (picking the nearest of several candidates, since `Intersects` calls don't return
  hits in any particular order); and a precise correction to `Rectangle::IsEmpty` (checks all
  four fields equal zero, not just zero area, so a rectangle with zero size but a nonzero
  position is not "empty" by this property). Chapter grows from 974 to 1240 lines (~24-25 of
  a ~110-page target by direct PDF page inspection — pdftotext-searched for the chapter's own
  opening sentence and Chapter 8's heading to bound its actual page range, rather than
  estimating from line count alone). Volume I recompiled clean (145 pages total, 716 index
  entries, 0 undefined references). **Honest scope note**: this was a thorough pass that fixed
  several real, previously-unnoticed gaps (the missing Equals/GetHashCode/ToString mention
  chief among them), but the chapter remains well short of its ~110-page target even after a
  session focused on it exclusively — reaching that target for real, source-grounded content
  (not padding) will take several more sessions of the same kind of direct-source-reading work.
  Remaining known gaps as of this entry: Vector2/Vector4-specific worked examples (both are
  currently only exercised via the shared Vector2 example and Matrix/Quaternion Transform
  overloads, never with anything Vector4-specific); a Plane `Transform` worked example; a
  `BoundingBox`/`BoundingFrustum`-specific (as opposed to shared-bounding-volume) worked
  example; and deeper coverage of `Matrix`'s billboard/shadow/reflection factory methods, none
  of which have a worked example at all yet.
- **2026-07-20 (same session, "pokracuj na kapitole 7, zjisti co vse v te kapitole muze byt a
  dej to do podkapitol, musi tam byt i priklady kodu"):** Continued the same chapter, working
  straight through the previous entry's own "known remaining gaps" list, each as a new
  `\subsection` with source-grounded code. `Vector4`'s extra `Transform(Vector2/Vector3 input)
  -> Vector4` overloads got a worked example tied to something real rather than invented: grep
  found CNA's own `SOFTWARE` backend rasterizer (`SoftwareGraphicsBackend.cpp`) calls exactly
  this overload, `Vector4::Transform(position, combined)`, to build clip-space vertices before
  the perspective divide and near-plane clipping — `Vector3::Transform` would have silently
  discarded the very `W` component that pipeline needs, which is precisely why the distinct
  overload exists. `Matrix::CreateBillboard` got a worked example plus its real degenerate-case
  handling (a `BillboardEpsilon = 0.0001f` guard against object/camera coincidence, falling back
  to `cameraForwardVector` or `Vector3::Forward`). `CreateShadow`/`CreateReflection` got a
  worked example plus a real asymmetry: `CreateReflection` normalizes its input `Plane`
  defensively (reusing the same file-local-helper pattern as the `WithinEpsilon` finding from
  the prior entry); `CreateShadow` does not, matching `Plane::Transform`'s own documented
  normalization requirement but in the opposite direction from `CreateReflection` — caught and
  fixed a matrix-composition-order mistake in the shadow example's own draft (had the shadow
  and character-world matrices multiplied in the wrong order relative to XNA's row-vector
  convention; corrected against the chapter's own established convention before finalizing).
  `Plane::Transform` got a worked example demonstrating the real inverse-transpose technique it
  uses internally — and a numerically-verified correction along the way: the first drafted
  example used an axis-aligned normal (`Vector3::Up`) under a diagonal scale, which a quick
  Python check showed produces *no* visible discrepancy between the naive and correct
  approaches (an axis-aligned normal under a diagonal scale doesn't change direction, only
  magnitude) — replaced with a genuinely sloped normal, re-verified numerically
  (`naive ≈ (0, 0.447, 0.894)` vs. `correct ≈ (0, 0.894, 0.447)`, a real, large directional
  difference) before writing it into the book. `BoundingBox::Contains(Vector3)` got a
  dedicated trigger-volume worked example; `BoundingFrustum::Contains` (as opposed to
  `Intersects`) got a worked example built around a real finding read from
  `BoundingFrustum.cpp`: it short-circuits to `ContainmentType::Disjoint` the moment any one of
  the six frustum planes tests `Front`, without checking the remaining planes, and only
  reports full `Contains` when every plane comes back cleanly `Back` — exactly the distinction
  a level-of-detail system can use to skip per-submesh culling for fully-visible objects.
  Chapter grows from 1240 to 1473 lines; its actual page span (bounded by pdftotext-searching
  for the chapter's own opening sentence and Chapter 8's heading) grows from ~24-25 to ~29 of
  the ~110-page target. Volume I recompiled clean (149 pages total, 740 index entries, 0
  undefined references). **Honest scope note, unchanged in spirit from the prior entry**: two
  consecutive sessions have now focused exclusively on this one chapter and it is still under
  30% of its page target — every addition so far has been a real, source-verified worked
  example or finding, not padding, but reaching ~110 pages this way will take several more
  sessions of the same density of work, not one or two.
- **2026-07-20 (same session, "pokracuj"):** Third consecutive session on Chapter 7, working
  through the prior entry's own remaining-gaps list again. `Matrix::CreateConstrainedBillboard`
  got a worked example (a tree-foliage billboard constrained to the vertical axis) plus a real
  second finding: it reuses `CreateBillboard`'s object/camera-coincidence epsilon but adds an
  independent second guard, `BillboardParallelEpsilon = 0.9982547f` (computed precisely as
  ${\approx}3.39°$ from exactly parallel), for the case where the camera direction is nearly
  parallel to the constrained rotation axis itself. `Matrix::CreateOrthographic` got a worked
  example built around a real one in CNA's own test suite
  (`easygl_shadowmapping_createshadowmap_shader_test.cpp`): a directional light's shadow-map
  view-projection matrix, with a precise explanation of *why* orthographic (not perspective)
  is correct here — its `M14`/`M24`/`M34` are always zero and `M44` is always `1.0f`, so clip-space
  `W` never varies with depth, unlike the perspective case this chapter's own
  `Vector4::Transform` clip-space finding (prior session) already covered. Added a
  `Quaternion::Lerp`-vs-`Slerp` angular-velocity worked example, numerically verified with a
  standalone script before writing it down (same discipline as the `Concatenate`/`Multiply`
  and `Plane::Transform` findings): both agree exactly at $t=0$, $0.5$, and $1$ for a
  150-degree test rotation, but disagree everywhere else — `Slerp` tracks $t \times 150°$
  exactly at every sampled point, while `Lerp` measured $11.9°$ (not $15°$) at $t=0.1$ and
  symmetrically overshot to $138.1°$ (not $135°$) at $t=0.9$, an ease-in/ease-out pattern
  symmetric around the midpoint where both necessarily agree. Added a
  `BoundingSphere::Transform` worked example under a non-uniform scale, confirming precisely
  (both by reading `BoundingSphere.cpp` and by hand-computing the expected value) that the
  resulting radius is the original radius times the *largest* single axis scale factor — a
  deliberately conservative choice that keeps the sphere a valid (if loose) bounding volume
  rather than merely wrong. Chapter grows from 1473 to 1632 lines; its actual page span grows
  from ~29 to ~33 of the ~110-page target (pdftotext-bounded, same method as before). Volume I
  recompiled clean (153 pages total, 744 index entries, 0 undefined references). **Scope note,
  unchanged in spirit**: three consecutive sessions now, still at ~30% of target — the
  remaining known gaps list (in `NEXT.md`) is nearly exhausted at this point, meaning a future
  session returning to this chapter will need to find fresh gaps the same grep-every-header
  way the earlier sessions did, rather than working off an existing list.
- **2026-07-20 (same session, "sluč svazky 1 a 2, bude to jenom jedna kniha"):** Author asked
  to merge Volume I and Volume II into a single book. Executed as a structural migration
  rather than a content pass:
  - **Directories**: `latex/volume1/` and `latex/volume2/` retired; everything moved into
    `latex/book/` via `git mv` (preserving history). Vol.I's four parts (chapters 1–24 +
    Appendix A) kept their numbers unchanged. Vol.II's five parts became Parts V–IX, with
    every chapter file and directory renamed under a fixed offset: `ch01`–`ch24` → `ch25`–
    `ch48` (`part1-input-audio-net`→`part5-input-audio-net`, `part2-sharp-runtime`→
    `part6-sharp-runtime`, `part3-easygl-freedirect`→`part7-easygl-freedirect`,
    `part4-crossplatform`→`part8-crossplatform`, `part5-porting-practice`→
    `part9-porting-practice`). Vol.II's five appendices (`appendix-a` through `appendix-e`)
    became `appendix-b` through `appendix-f` (Vol.I's own appendix stays `appendix-a`); both
    volumes' "API Quick Reference" appendices kept as two separate appendices (A and F) with
    disambiguated titles ("Core Framework and Graphics" / "Ecosystem and Platforms") since
    they cover disjoint class sets.
  - **Verified no label collisions** between the two volumes' `\label{}` namespaces before
    merging (`comm -12` on sorted label lists from both, zero matches) — the merge would have
    silently produced wrong `\ref{}` resolutions if any collided.
  - **`latex/volume2/xrefs-volume1.tex`** (the `\newlabel` shim that let Vol.II's `\ref{}`
    calls resolve Vol.I chapter numbers across the old two-document compilation) was deleted
    entirely — real `\ref{}` now resolves correctly on its own within one compilation, which
    is strictly better than the shim it replaces (auto-updates if a chapter ever moves again,
    rather than needing manual shim maintenance).
  - **Cross-reference fixing, by category**: (1) plain-text `Chapter~N` citations with an
    explicit `Volume~I`/`Volume~II` qualifier — Vol.I-referencing ones needed only the
    qualifier stripped (Vol.I's own numbers are unchanged by the merge); Vol.II-referencing
    ones needed both the qualifier stripped and a +24 offset applied to the number. (2) bare
    `Chapter~N` citations with no qualifier at all, found only inside former-Vol.II files —
    these are same-volume (Vol.II-internal) references and needed the +24 offset applied.
    (3) `Volume~I/II Part~N` citations — offset applied via Roman-numeral lookup (Vol.II's
    Parts I–V → the merged book's Parts V–IX). (4) generic, number-free prose mentions
    ("Volume~I's ecosystem chapter", "in Volume~II", "this volume's migration chapter") —
    handled with a scripted regex pass converting to volume-neutral phrasing ("the ecosystem
    chapter", "later in this book", "the migration chapter"), followed by a manual review pass
    that caught and fixed: two sentences left with a lowercase-mid-substitution "this book" at
    a paragraph or sentence start (needed manual capitalization back to "This book"); one
    doubled artifact ("this book's this book ultimately stands on" from two separate
    substitution rules firing on the same original sentence); and one genuine temporal-
    direction error (a Sharp Runtime chapter's own text said it had "already touched on" a
    networking finding "later in this book" — backwards, since Networking is Part V and Sharp
    Runtime is Part VI, i.e. earlier, not later — caught by checking each `earlier`/`later`
    substitution's actual chapter order rather than trusting the mechanical replacement).
  - **Front matter merged**: one title page (dropped the "Volume I" subtitle line, widened the
    subtitle to name all five topic areas), one preface (rewrote the "how this book is
    organized" section to walk all nine parts in one continuous paragraph sequence, folding in
    the former Volume II preface's own per-part descriptions), one `main.tex` (nine
    `\part{}`/chapter-`\input{}` blocks, then `\appendix` with six `\input{}` lines, then
    `\backmatter`/`\printindex` — structurally identical to each old volume's `main.tex`, just
    concatenated and renumbered).
  - **Also fixed in passing** (found while doing an unrelated build-log check): thirteen
    instances of a math-mode `\textdegree` LaTeX warning in Chapter 7 (degree symbols written
    directly inside `$...$` math delimiters, e.g. `$150°$`) from this session's own earlier
    Quaternion `Lerp`-vs-`Slerp` and `CreateConstrainedBillboard` additions — moved the `°`
    outside the math delimiters (`$150$°`) to eliminate the warning; unrelated to the merge
    itself but caught because the merge's full rebuild surfaced it.
  - **Makefile**: `volume1`/`volume2` targets replaced with a single `book` target.
    `CLAUDE.md` updated to describe the new single-book layout and retire the two-volume
    build/citation conventions it used to document.
  - **Verification**: rebuilt clean — 266 pages, 0 undefined references, 0 duplicate-label
    warnings, 0 remaining `\textdegree` warnings, 1111 combined index entries (fewer than the
    pre-merge sum of both volumes' separate index counts, because identical class names now
    correctly merge into one shared index entry instead of two near-duplicates). Spot-checked
    the title page and the Part V transition page (physical PDF page 153, printed page 137)
    by rendering them to PNG and reading them back, confirming correct part numbering and
    prose flow across the former volume boundary.
  - This was a large, mechanical, high-file-count change (48 chapter files + 6 appendices
    moved/renumbered, ~90 cross-reference instances fixed across ~30 files) but a
    **structural** one, not a content-expansion pass — no new page-count progress was made on
    any chapter's target in this entry; the per-chapter tables above are otherwise unchanged
    from the prior entry except for chapter/appendix number relabeling.
- **2026-07-20 (same session, "pokracuj na nejake dalsi kapitole pote"):** Per the author's
  explicit instruction to move to a different chapter after the merge, started Chapter 25
  (Input System) — the first real expansion-pass work on any former-Volume-II chapter, since
  Parts V–IX were completely untouched (0%) before this. Read the real headers for
  `Keyboard`/`KeyboardState`, `Mouse`/`MouseState`, `GamePad`/`GamePadState`/
  `GamePadCapabilities`/`GamePadThumbSticks`, and `TouchPanel`/`TouchCollection`/
  `TouchLocation`/`GestureSample` directly, and added full method references + worked examples
  for each: `Keyboard`'s `GetKeyFromScancodeEXT`/layout-independent scancode surface (worked
  example: physical-position WASD that stays correct on AZERTY); `Mouse`'s relative-mouse-mode
  EXT surface, with a real, verified mechanism finding — `InputManager::GetMouseState()`
  substitutes `MouseState.X`/`Y` with an accumulated-then-reset relative-delta pair while
  relative mode is active, meaning the same two fields genuinely mean different things
  depending on mode, not just by documentation convention (worked example: FPS-style
  mouse-look); `GamePadState`'s three `GamePadDeadZone` modes, with a precise finding read from
  `GamePadThumbSticks`'s constructor — `IndependentAxes` excludes each axis independently (can
  distort diagonal input right at the dead-zone boundary), `Circular` excludes radially by
  magnitude instead, and the two also differ in post-dead-zone clamp shape (square vs. circle)
  (worked example: dead-zone-aware movement plus rumble); `TouchCollection`/`TouchLocation`/
  `GestureSample`, with a verified finding that `EnabledGestures` is a genuine filter (checked
  via bitwise AND in `GestureDetector.cpp` before a gesture is ever enqueued), not merely
  advisory (worked example: per-finger drag tracking by stable `Id`, plus a pinch-to-zoom
  gesture example).
  **Also found and fixed a real, pre-existing-pattern typographic defect while rebuilding**:
  several `\texttt{A}/\texttt{B}` chains with no space around the slash are one unbreakable
  LaTeX token when long enough, causing severe (up to 225pt/~3 inch) overfull-hbox overflows
  that visibly ran text off the page edge — worst case, `SdlInputBridge::ProcessEvent` was cut
  off mid-word in the chapter's own intro paragraph. Fixed by adding breaking spaces around
  long `/`-joined texttt chains project-wide within this file (32 instances) and rewording the
  two or three paragraphs where that alone wasn't enough (shortened two overlong `\item[]`
  labels; restructured the intro sentence naming `SdlInputBridge::ProcessEvent`; reworded the
  `GamePadDeadZone` paragraph). Verified via full rebuild that severe overflows are gone
  (worst remaining is 36pt, comparable to pre-existing tolerance levels elsewhere in the book)
  and by rendering the affected pages to PNG and reading them back. **This defect risk is worth
  watching for in any future chapter with dense multi-method-name descriptions** — it wasn't
  caught by the "build clean, check for undefined references" habit alone, since overfull-hbox
  warnings are easy to skim past in a long build log; a targeted `grep -i overfull` pass
  (comparing point-widths, not just presence) is what actually surfaced it here.
  Chapter grows from 170 to 422 lines (~4 to ~8 of a ~70-page target). Volume recompiled clean
  (270 pages total, 1138 index entries, 0 undefined references, 0 duplicate-label warnings).
- **2026-07-20 (same session, "commitni pushni. pokracuj"):** Continued Chapter 25, covering
  the two remaining named-but-undocumented sections: `TextInputEXT` and the five NOXNA-only
  device subsystems. Added a full method reference for `TextInputEXT` (read directly from
  `TextInputEXT.hpp`), distinguishing `TextInput` (fires once per composed, IME-resolved
  character) from `TextEditing` (fires for in-progress, not-yet-committed composition text) ---
  a distinction easy to conflate — plus a worked example (an in-game chat box). Added full
  references + worked examples for `Clipboard`, `Joysticks`, `Sensors`, `Power`, and
  `Haptics` — the last with real internal lifecycle state (`HapticDevice` handles from
  `OpenEXT`/`OpenFromJoystickEXT`/`OpenFromMouseEXT`, a simple rumble tier and a full
  `HapticEffectEXT` create/update/run/stop/destroy tier), including a verified finding that
  `HapticDevice`'s destructor calls `Dispose()` directly (confirmed by reading
  `HapticDevice.cpp`), so a locally-scoped handle closes automatically at scope exit without
  needing an explicit call. Worked examples: dual host-device/gamepad battery check (a real,
  easy-to-conflate distinction between `Power::GetInfoEXT` and
  `GamePad::GetPowerInfoEXT`), and a haptic-mouse rumble pulse (a case
  `GamePad::SetVibration` cannot reach at all, since it's gamepad-only).
  **Proactively re-applied the same `/`-spacing fix from the prior entry** to this session's
  own new content before the first build (9 more instances caught pre-emptively), then still
  found and fixed one more instance of the specific `}/%`-line-continuation variant of the bug
  (a `Clipboard` method list) that the regex-based fix doesn't catch, since it doesn't match a
  literal `}/\texttt{` pattern. Verified by rendering all four affected pages to PNG and
  reading them back; one moderate (45pt) overfull warning remains in the log but the
  corresponding page renders with no visible cutoff when read back, confirming the numeric
  warning doesn't always correspond to a real visible defect — the actual bar is the rendered
  page, not a clean log. Chapter grows from 422 to 534 lines (~8 to ~10 of a ~70-page target).
  Volume recompiled clean (272 pages total, 1146 index entries, 0 undefined references, 0
  duplicate-label warnings).
- **2026-07-20 (same session, "udelej kapitolu audio"):** Chapter 26 (Audio System) — the
  second former-Volume-II chapter to get its first real expansion pass. Read the real headers
  for `SoundEffect`, `SoundEffectInstance`, `DynamicSoundEffectInstance`, `AudioEngine`,
  `SoundBank`, `WaveBank`, `Cue`, `AudioListener`/`AudioEmitter`, and `Microphone` directly,
  and added full method references + worked examples for each: `SoundEffect`'s four static
  process-wide mixing knobs and three constructor families (worked example: loading from raw
  headerless PCM); `SoundEffectInstance`'s `Apply3D`, with a verified finding read from
  `SoundEffectInstance.cpp` — calling `Apply3D` even once permanently latches an internal
  `is3D` flag that never resets, so its derived attenuation/pan/Doppler values keep governing
  output on every later call, even though `Volume`/etc.\ setters still update their own
  properties independently (worked example: a 3D explosion sound tracking a moving listener);
  `DynamicSoundEffectInstance`'s pull-based `BufferNeeded`/`SubmitBuffer`/`SubmitFloatBufferEXT`
  streaming model (worked example: a procedurally generated tone); the `AudioEngine`/
  `SoundBank`/`WaveBank`/`Cue` XACT object model, distinguishing `GetCue` (caller-owned) from
  `PlayCue` (bank-owned, fire-and-forget, cleaned up by `AudioEngine::Update()`'s sweep)
  (worked example: a footstep cue driven by a global XACT runtime variable, plus a held
  looping engine-sound `Cue`); and `Microphone`'s capture/enumeration surface, with a verified
  finding that `BufferDuration`'s 100–1000ms-in-multiples-of-10 constraint is enforced by
  actually throwing `ArgumentOutOfRangeException`, not just documented (worked example:
  microphone capture piped directly into a `DynamicSoundEffectInstance` for live playback).
  Caught and fixed one constructor-signature mistake in a first draft before finalizing
  (`SoundBank`/`WaveBank` take an `AudioEngine*` pointer, not a reference — the worked example
  originally passed the engine by value). Applied the same `/`-spacing fix for the
  overfull-hbox defect class (29 instances caught proactively before the first build) and
  verified all eight of the chapter's own pages by rendering to PNG and reading them back —
  confirmed clean with no visible cutoff despite a few residual overfull-hbox log warnings
  under 40pt, consistent with the "log warning alone doesn't mean a visible defect" lesson
  from the prior two entries. Chapter grows from 118 to 317 lines (~4 to ~8 of a ~60-page
  target). Volume recompiled clean (276 pages total, 1164 index entries, 0 undefined
  references, 0 duplicate-label warnings).
- **2026-07-20 (same session, "jak moc tam pises o audio? ma to byt bible tedy ma tam byt
  vyskyt vseho"):** a direct response to the author checking whether Chapter 26's first pass
  was actually living up to the "bible = comprehensive" standard. Answered honestly (the
  317-line/~8-page first pass was real but nowhere near the ~60-page target), then re-grepped
  the real headers against the chapter's prose to find concrete, still-missing surface rather
  than padding with restated content. Found and closed four genuine gaps: `AudioCategory`,
  with a worked example showing `SetVolume` retroactively re-applying to already-playing cues
  in that category (confirmed via a "T-4D" tagged source comment), not just future `Play()`
  calls; `AudioEngine::RendererDetails`, with a verified finding read directly from
  `RendererDetail.hpp`'s own source comment — production code only ever constructs the single
  hardcoded SDL3\_mixer renderer, a second instance existing only in test code to exercise the
  not-equal comparison path, so the enumeration always yields exactly one entry in practice
  regardless of real attached hardware; `SoundEffect::FromStream`, the one construction path
  that parses a complete WAV container (RIFF header included) from a `std::istream`, in
  explicit contrast to every other constructor's headerless-PCM requirement; and the
  namespace's three exception types (`InstancePlayLimitException`, `NoAudioHardwareException`,
  `NoMicrophoneConnectedException`), with a verified asymmetry — two of the three derive from
  a COM-interop-style external exception base matching real XNA's own choice, but
  `NoMicrophoneConnectedException` derives from a plain exception base instead. Hit the
  session's most stubborn instance yet of the `/`-spacing overfull-hbox defect class while
  writing the exception-types paragraph: a single long `\cnaclass{NoMicrophoneConnectedException}`
  token (31 characters) caused a severe, visibly-confirmed text cutoff (up to 128.66667pt)
  that survived three different fix attempts (proactive `/`-spacing regex pass; shortening an
  adjacent long fully-qualified name; restructuring which exceptions were named together) —
  the technique that finally worked, applied to the one sentence that was still cut off after
  the other three attempts, was giving that sentence its own paragraph break so the long
  identifier gets a full line width from its very first character, confirmed fixed by
  rendering page 170 to PNG and reading it back. Along the way, caught and corrected a factual
  slip in a first draft (misattributed which exception derives from which base class) via a
  fresh `grep -n "class.*Exception.*:"` header check before finalizing. Chapter grows from 317
  to 378 lines (still ~8 of a ~60-page target — this pass closed real gaps but did not yet
  reach the page target; more chapters/sections of real API surface remain to be checked
  against the header for further gaps in a future pass). Volume recompiled clean (277 pages
  total, 1173 index entries, 0 undefined references, 0 duplicate-label warnings).
- **2026-07-20 (same session, "pokracuj"):** Chapter 27 (Media) — first real expansion pass,
  following NEXT.md's recommendation to move to a fresh chapter. Read the real headers and
  `.cpp` implementations for `Song`, `MediaQueue`, `MediaPlayer`, `MediaLibrary`,
  `AudioTagParser`, `MediaLibraryPaths`, `PlaylistParser`, `Video`/`VideoPlayer`,
  `VisualizationData`, `VisualizationCapture`, and `VisualizationFFT` directly, and added full
  method references + worked examples grounded in each: `Song`'s content-based `GetHashCode`
  (a documented, deliberate deviation from FNA's own identity-based, contract-violating
  version) and `FromUri` factory; the real tag-reading pipeline (Vorbis comments, ID3v2.3/2.4
  with all four text-encoding-byte variants, native-FLAC `VORBIS_COMMENT`, and Ogg-Opus
  `OpusTags` — two formats beyond what the chapter's introduction already covered — plus the
  filename/folder fallback chain and the real cross-format rating-scale ambiguity, a documented
  CNA decision since neither XNA nor FNA defines one); `MediaLibraryPaths` resolving real
  per-OS Music/Pictures roots via SDL's `SDL_GetUserFolder()`; `MediaQueue`'s ownership model,
  with a verified finding read directly from `MediaPlayer.cpp` — `LoadSong()` defensively
  clones every song via `new Song(handle, name)` before handing it to the owning queue,
  specifically because `SongCollection` (the type `Play(const SongCollection&)` accepts) holds
  non-owning pointers, so handing those directly to an owning queue would let the next
  `Play()`'s `Clear()` delete songs a `MediaLibrary` still expects alive; a second verified
  finding that `MediaPlayer::Stop()` resets every queued song's `PlayCount` to zero, not just
  the one that was playing; the real shuffle (uniform random over the whole queue, can repeat)
  versus repeat (wraps to index zero) versus linear (clamped) `NextSong` logic; three real bugs
  in `VideoPlayer` multi-track switching found by external code review and fixed
  (`DrainAndFlushAudioBuffer` fixing an unbounded-memory-growth leak on the no-audio-device
  path; `ReconfigureVideoOutputForCurrentTrack` fixing a stale frame-texture-size bug on a
  video-track switch; splitting what used to be one coupled reconfigure function into
  independent audio-side/video-side helpers so an audio-only or video-only track switch no
  longer needlessly tears down the other side); and `GetVisualizationData`'s genuine,
  from-scratch pipeline — a lock-free single-producer/single-consumer ring buffer using
  `std::atomic<float>` with relaxed ordering (a verified finding: this specifically avoids real
  undefined behavior from cross-thread plain-`float` access, not mere pedantry, at effectively
  zero runtime cost) feeding a from-scratch 512-sample radix-2 FFT with Hann windowing and a
  documented CNA-chosen (not XNA-specified) magnitude-normalization constant, plus two further
  real bugs found in the enable/disable state machine around it. Hit and fixed one more
  instance of the single-long-identifier overfull-hbox variant (`ReconfigureAudioOutputForCurrentTrack()`
  paired with `ReconfigureVideoOutputForCurrentTrack()` on one line in an itemized list,
  confirmed visibly cut off on the rendered page) by splitting the pair into two sentences
  instead of trying to fix it with `/`-spacing alone — consistent with the technique already
  established in the Chapter 26 entry above. Chapter grows from 103 to 300 lines (~4 to ~6 of a
  ~45-page target). Volume recompiled clean (279 pages total, 0 undefined references, 0
  duplicate-label warnings); all six of the chapter's own pages verified by rendering to PNG
  and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 28 (Devices and Sensors) — first
  expansion pass. This chapter's prose was already unusually dense and well-grounded before
  this pass (the concurrency-engineering narrative for `SensorBase`'s disposal protocol and the
  update-throttle integer-overflow bug were already present and accurate), but it had zero
  worked code examples anywhere in it — every other expanded Part V–IX chapter this session
  established full method reference + worked example as the pattern, so that was the concrete
  gap here rather than missing API surface. Read `SensorBase.hpp`, `Accelerometer.hpp`,
  `AccelerometerReading.hpp`, `SensorReadingEventArgs.hpp`, `EventHandler.hpp`,
  `VibrateController.hpp`, `Camera.hpp`, and `CameraState.hpp` directly. Added one genuinely
  new verified finding not previously in the chapter: `SensorBase::SetCurrentValueAndMarkDataValid`
  closes a real observable-inconsistency window — `IsDataValid` and `CurrentValue` used to be
  set via two separate, individually race-free locked calls, but a concurrent reader could still
  observe the gap between them (data marked valid while `CurrentValue` still held stale data);
  combining both into one lock scope closes it. Added a second new finding for
  `VibrateController`: `Start(duration, 0.0f)` is deliberately NOT treated as an implicit
  `Stop()` — it still uploads and plays a genuine zero-strength effect for the full duration,
  re-confirmed against SDL3's own haptic source and its own test suite, not merely documented.
  Added three worked examples grounded in the real signatures: subscribing to
  `Accelerometer::CurrentValueChanged` with the correct `const SensorReadingEventArgs<T>&`
  handler signature (verified against `EventHandler.hpp` directly rather than assumed);
  `VibrateController::StartLeftRight` plus an explicit `Stop()`; and `Camera::TryAcquireFrame`'s
  poll-every-frame contract, including the exact-dimension-match requirement on the destination
  `Texture2D`. Chapter grows from 115 to 208 lines (~4 to ~6 of a ~45-page target). Volume
  recompiled clean (281 pages total, 0 undefined references, 0 duplicate-label warnings); all
  six of the chapter's own pages verified by rendering to PNG and reading them back — no
  overfull-hbox defect found this time (the proactive `/`-spacing regex pass caught its one
  instance before the first build).
- **2026-07-20 (same session, "pokracuj"):** Chapter 29 (GamerServices) — first expansion
  pass. Same gap shape as Chapter 28: the prose (the three-way Implemented/Locally-persisted/
  documented-stub split, the LeaderboardWriter aliasing hazard, the Guide real-vs-stub
  distinction) was already dense and accurate, but zero worked code examples existed anywhere
  in the chapter. Read `SignedInGamer.hpp`, `GamerPresence.hpp`, `GamerPresenceMode.hpp`,
  `LeaderboardWriter.hpp`, `LeaderboardEntry.hpp`, `LeaderboardIdentity.hpp`,
  `LeaderboardKey.hpp`, and `Guide.hpp` directly. Added one real detail not previously named:
  `SignedInGamer` exposes a NOXNA non-`const` overload of `getPresenceProperty()` specifically
  to preserve real XNA's own get-only-property-returning-a-mutable-reference-type idiom
  (`gamer.Presence.PresenceMode = ...`), which a plain `const`-only C++ accessor could not
  reproduce. Added three worked examples grounded in the real signatures: awarding an
  achievement and mutating presence through `SignedInGamer`; submitting a leaderboard score
  through `LeaderboardWriter::GetLeaderboard` + `LeaderboardEntry::setRatingProperty` (the
  "assigning Rating is the whole commit step" behavior, now shown, not just described); and a
  full `Guide::BeginShowMessageBox`/`RenderPendingMessageBoxEXT`/`EndShowMessageBox` overlay
  round-trip, matching the real three-step pending-until-Draw()-renders-it contract. Chapter
  grows from 117 to 169 lines (~4 to ~5 of a ~55-page target). Volume recompiled clean (281
  pages total, 0 undefined references, 0 duplicate-label warnings); all four of the chapter's
  own pages verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 30 (Networking) — first expansion pass.
  Same gap shape as 28/29 again: the prose (caller-owned `NetworkSession` lifecycle, the real
  host-migration/simulated-latency behavior, the real-versus-stub `NetworkSessionType` table,
  the bug-fix history) was already dense and accurate, but zero worked examples existed. Read
  `NetworkSession.hpp`, `GamerJoinedEventArgs.hpp`, `LocalNetworkGamer.hpp`, `PacketWriter.hpp`,
  and `PacketReader.hpp` directly. Added one real detail not previously spelled out as
  concretely: real XNA's `GamerJoined` is documented to replay itself immediately upon
  subscription for every gamer already in the session, but this port's `EventHandler` has no
  such replay hook, so the documented, permanent workaround — call `Update()` once immediately
  after subscribing — is now shown in a worked example, not just described in prose. Added a
  second worked example for the `PacketReader`/`PacketWriter` `Color` read/write asymmetry
  (four bytes on write, four floats on read) already documented in prose, now shown as an
  actual send/receive round-trip a reader could get wrong if they assumed symmetry. Chapter
  grows from 125 to 170 lines (~4 to ~5 of a ~70-page target). Volume recompiled clean (281
  pages total, 0 undefined references, 0 duplicate-label warnings); all four of the chapter's
  own pages verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 31 (Avatar) — first expansion pass. Same
  gap shape as 28/29/30 once more: the prose (the faithful base API's provable inertness, the
  separate SkinnedModelEXT real-rendering extension, the appearance-tint invention, the
  content-pipeline bug history) was already dense and accurate, but zero worked examples
  existed. Read `SkinnedModelEXT.hpp`, `AvatarRenderer.hpp`, and `AvatarAppearanceEXT.hpp`
  directly. Added one real detail not previously in the text: `SkinnedModelEXT::AttachPartEXT`/
  `RemovePartEXT`'s own history had two real, found-and-fixed bugs — a genuine GPU-resource
  leak (erasing a part directly from the public `Parts` vector only discarded a non-owning
  descriptor, never freeing the underlying `VertexBuffer`/`IndexBuffer`/`ModelMeshPart`/
  `Texture2D`) and a real ordering bug (re-attaching a same-named replacement part, e.g.
  swapping a hairstyle at runtime, used to render both the old and new part simultaneously
  because `AttachPartEXT` only ever appended, until it was changed to remove any same-named
  part first). Added two worked examples: the full faithful-versus-real-rendering bridge
  (`AvatarRenderer` construction, `EnableRealRenderingEXT`, `SetAppearanceEXT`, the per-frame
  `DrawRealEXT` call); and a wardrobe hot-swap via `AttachPartEXT` demonstrating the
  replace-by-name fix. Also proactively fixed two pre-existing instances of the `/`-spacing
  overfull-hbox defect class found while editing this file (one in this session's own new
  content, one left over from before this session). Chapter grows from 131 to 179 lines (~4 to
  ~4 of a ~55-page target — line growth this pass came mostly from prose depth per topic
  rather than page count, since dense worked-example code blocks compress efficiently). Volume
  recompiled clean (281 pages total, 0 undefined references, 0 duplicate-label warnings); all
  four of the chapter's own pages verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 32 (Storage) — first expansion pass, and
  the last untouched chapter in Part V (Ch.25-32), which now has a first expansion pass on
  every chapter. Same gap shape once more: the prose (the fake-async pattern's Xbox~360
  origin, the free-space/connection-state properties, the NOXNA app-name/storage-root
  extension point) was already dense and accurate, but zero worked examples existed. Read
  `StorageDevice.hpp` and `StorageContainer.hpp` directly. Added one real detail not previously
  in the text: unlike `NetworkSession`'s and `Guide`'s own `Begin`/`End` families (both
  returning caller-owned raw pointers requiring a matching manual `delete`), every `Begin`/
  `End` result in this namespace is a real `std::unique_ptr` — `EndOpenContainer` returns
  `std::unique_ptr<StorageContainer>`, `EndShowSelector` returns
  `std::unique_ptr<StorageDevice>` — a cleaner ownership story than most of the rest of this
  book's ported XNA surface. Added two worked examples: the full device-selection-to-
  open-container lifecycle (`SetAppNameEXT`, `BeginShowSelector`/`EndShowSelector`,
  `BeginOpenContainer`/`EndOpenContainer`), and a save-file write/read-back round-trip through
  `StorageContainer::CreateFile`/`OpenFile`/`FileExists`. Chapter grows from 78 to 124 lines
  (~3 to ~3 of a ~30-page target). Volume recompiled clean (283 pages total, 0 undefined
  references, 0 duplicate-label warnings); the chapter's three real content pages verified by
  rendering to PNG and reading them back (a fourth, blank padding page before the Part~VI
  title page is expected book layout, not a defect).
- **2026-07-20 (same session, "pokracuj"):** Chapter 33 (Sharp Runtime Overview) — first
  expansion pass, and the first Part VI chapter touched this session (following NEXT.md's
  recommendation to move on from Part V once every chapter there had a first pass). Same gap
  shape as the Part V chapters: dense, accurate prose already existed (the `Object`/
  `IDisposable` root-type substitution, `EventHandler`/`MulticastAction`'s reason for existing,
  the `TimeSpan` copy/move-counter race, `Dictionary::Remove`'s version-counter deviation) but
  zero worked examples. Read `Object.hpp`, `MulticastAction.hpp`, `TimeSpan.hpp`, and
  `Threading/Tasks/Task.hpp` directly. Added one real detail not previously in the text:
  `Task::ContinueWith` always runs its continuation synchronously and inline — this port has no
  thread pool or scheduler at all, so a continuation runs on whichever thread completes the
  antecedent, or immediately on the calling thread if the antecedent was already complete,
  effectively as if `TaskContinuationOptions::ExecuteSynchronously` were always set regardless
  of whether a caller passes it; most predicate-filter options are genuinely honored, while the
  scheduler/parent-task-related ones are accepted only for API-surface parity. Added two worked
  examples: `MulticastAction`'s token-based `Add`/`Remove`, demonstrating the exact
  re-parenting scenario named in its own header comment; and a `Task::Run`/`ContinueWith`
  round-trip showing that a continuation must inspect the antecedent's fault state explicitly,
  since it is not rethrown automatically the way `Wait()` does. Fixed two pre-existing/newly
  introduced instances of the `/`-spacing overfull-hbox defect class. Chapter grows from 116 to
  167 lines (~4 to ~5 of a ~40-page target). Volume recompiled clean (283 pages total, 0
  undefined references, 0 duplicate-label warnings); all five of the chapter's own pages
  verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 34 — first expansion pass. **Documentation
  drift caught and corrected**, the same discipline this whole project holds itself to: this
  table row's own description ("Full docs for TimeSpan/EventHandler/Stream/collections") is
  stale — the chapter's actual `\chapter{}` title is "Sharp Runtime: Strings, Streams, and a
  Real Audit History," and its real content is `String`/`StringBuilder`, `Stream`, and two
  post-stabilization audit narratives; `TimeSpan`/`EventHandler` are already covered in Chapter
  33, added just last session, not in this chapter at all. Corrected the table row above rather
  than silently reading the stale description and expanding the wrong scope. Read `String.hpp`,
  `Text/StringBuilder.hpp`, and `IO/Stream.hpp` directly. Added one real detail not previously
  in the text: `StringBuilder::ChunkEnumerator` always yields exactly one chunk, because unlike
  real .NET's internal linked list of separate character chunks, this port's `StringBuilder` is
  backed by a single `std::string` — the enumeration *shape* is preserved faithfully even
  though the simpler implementation underneath never produces more than one chunk to walk.
  Added three worked examples: `String`'s pure-static-utility usage (`Split`/`Trim`) alongside
  `StringBuilder`'s real mutable-buffer usage; a minimal three-override `Stream` subclass
  matching the base class's actual read-only contract; and the exact `Convert::ToInt32`
  round-half-to-even repro the chapter's own prose already named numerically
  (`ToInt32(2.9) == 3`, `ToInt32(3.5) == 4`), now shown as runnable assertions rather than only
  described. Chapter grows from 90 to 162 lines (~3 to ~5 of a ~70-page target — note the
  target itself may need revisiting given the corrected, narrower actual scope). Volume
  recompiled clean (285 pages total, 0 undefined references, 0 duplicate-label warnings); all
  four of the chapter's own pages verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 35 (Parity Philosophy) — first expansion
  pass. This chapter is more policy-narrative than API-reference in character (reflection/GC/
  serialization/crypto scope decisions, quoted directly from the project's own reasoning), so
  the natural worked-example opportunity was narrower than in API-heavy chapters, but one
  section — the three-tier delegate model — is concrete and code-shaped enough for a real
  worked example. Read `Delegate.hpp`, `Action.hpp`, and `MulticastAction.hpp` directly. Added
  one worked example showing all three tiers side by side against the same kind of problem
  each is meant to solve: a plain `System::ActionT<int>` alias for the single-target common
  case; `System::Delegate::Combine`/`Remove` building and later shrinking a real multicast
  invocation list; and `System::MulticastAction`'s token-based `Add`/`Remove` for an event
  field, contrasting directly with why `Delegate`'s own equality-based `Remove` doesn't work
  for `std::function`-backed fields. No new verified finding surfaced this pass beyond what the
  prose already stated precisely (the chapter's existing prose was unusually exact already,
  quoting the project's own reasoning directly rather than paraphrasing). Chapter grows from
  111 to 134 lines (~4 to ~6 of a ~35-page target). Volume recompiled clean (285 pages total, 0
  undefined references, 0 duplicate-label warnings); all six of the chapter's own pages
  verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 36 (easy-gl Deep Dive) — first expansion
  pass, and the last chapter in Part VI to get one (Chapter 37/free-direct stays explicitly
  frozen per the author's 2026-07-20 confirmation, not expanded). Same gap shape as most of
  this session's chapters: dense, accurate prose but zero worked examples. Read
  `Capabilities.hpp`, `Feature.hpp`, `Device.hpp`, `Program.hpp`, and `Framebuffer.hpp`
  directly (the last two cross-checked against `Framebuffer.cpp`'s own real test usage to
  confirm exact enumerator names like `FramebufferAttachment::Depth`, since the enum
  definitions themselves live in the sibling `meta-gl` repo, not cloned this session — a
  worked example was adjusted mid-pass to use only enumerator names directly confirmed in this
  codebase's own source, not guessed at). Added two worked examples: `Device::supports`/
  `require` querying the real per-feature capability table directly (`TessellationShader`,
  `FramebufferObject`), and the `Program::uniform_block_index`/`Framebuffer` typed-reference
  fixes shown together in one snippet. While proactively checking this chapter for the
  single-long-identifier overfull-hbox variant, found and fixed **two** instances — one in this
  session's own new content (`Program::uniform_block_index()`) and one pre-existing from before
  this session (`Config::enable_debug_logging`) — both fixed with the established
  own-paragraph-break technique and confirmed via PNG re-render. Chapter grows from 112 to 151
  lines (~4 to ~5 of a ~55-page target). Volume recompiled clean (285 pages total, 0 undefined
  references, 0 duplicate-label warnings); all four of the chapter's own pages verified by
  rendering to PNG and reading them back.

**Part VI (Chapters 33-37) is now fully swept**: 33-36 all have a first expansion pass; 37
stays frozen by explicit author decision, not left incomplete.
- **2026-07-20 (same session, "pokracuj"):** Chapter 38 (Windows/Wine) — first expansion pass,
  and the first Part VIII chapter touched this session. This chapter is tooling/verification-
  methodology narrative, not a C++ API reference, so "worked examples" here meant real shell
  invocations grounded in the actual scripts rather than C++ code. Read
  `cmake/toolchains/mingw-w64.cmake` and `scripts/run-wine-dxvk.sh` directly (both from the
  `cna` repo, already cloned earlier this session at `/workspace/cna`). Added one real detail
  not previously in the text: the DXVK self-verifying gate is not unconditional — it has two
  deliberate, narrowly-scoped escape hatches its own comments explain precisely,
  `CNA_D3D11_ALLOW_WINED3D=1` (a genuinely deliberate one-off non-DXVK diagnostic run, not for
  normal test runs) and `CNA_D3D11_SKIP_DXVK_GATE=1` (for a binary that legitimately never
  creates a D3D11 device at all, which would otherwise be misreported as a silent fallback for
  entirely unrelated reasons). Added two worked examples: the exact cross-compilation
  invocation from the toolchain file's own header comment, and all three real invocation shapes
  of `run-wine-dxvk.sh` (normal gated run, the diagnostic bypass, the device-less-binary
  bypass). Chapter grows from 103 to 137 lines (~4 to ~4 of a ~45-page target). Volume
  recompiled clean (285 pages total, 0 undefined references, 0 duplicate-label warnings); all
  four of the chapter's own pages verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 39 (Web/Emscripten) — first expansion
  pass. Same tooling-narrative shape as Chapter 38, not a C++ API reference: real Emscripten
  compile/link flags and the honest, carefully-hedged "what has actually been built and run"
  account. Read the real `CMakeLists.txt` (its `if(EMSCRIPTEN)` block) and
  `cmake/UnitTests.cmake` (the `CnaTests`-only link options) directly, plus
  `docs/web-emscripten-graphics-limitations.md` for the CANVAS build-success wording. Added one
  real detail sharpened from paraphrase to exact quote: the project's own build comments record
  the literal error `"window is not defined"` as the precise exception a genuine CANVAS
  smoke-test build hits under Node (not just "SDL\_Init throws," which the chapter already
  said, but the actual underlying JS exception string). Added three worked examples: the exact
  `-fexceptions`/`-sNO_DISABLE_EXCEPTION_CATCHING=1` compile/link options CNA applies globally
  under Emscripten; the two `CnaTests`-only link flags (`-sEXIT_RUNTIME=1`, `-sASYNCIFY=1`)
  with their real `target_link_options` CMake syntax; and the real `emcmake`/`cmake --build`/
  `node` invocation shape behind the CANVAS build-and-run success story, following this book's
  own already-established `-DCNA_GRAPHICS_BACKEND=X` convention. Chapter grows from 88 to 121
  lines (~3 to ~3 of a ~40-page target). Volume recompiled clean (287 pages total, 0 undefined
  references, 0 duplicate-label warnings); all four of the chapter's own pages verified by
  rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 40 (Android/NDK) — first expansion pass.
  Same tooling-narrative shape as Chapters 38-39: real shell/build invocations, not C++ API
  worked examples. Read `docs/devices-build.md` directly (the `cna` repo's own real Android
  cross-compile and emulator-verification notes), grounding every command in the project's
  actual recorded session rather than reconstructing a plausible-looking one. No major new
  finding beyond what the prose already stated precisely (this chapter's honest-regression
  narrative was already unusually exact). Added two worked examples: the real, exact NDK
  cross-compile invocation (`-DCMAKE_TOOLCHAIN_FILE=.../android.toolchain.cmake
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 -DCNA_BUILD_TESTS=OFF`) plus the
  matching `llvm-nm` verification that an Android-specific code path actually compiled in; and
  the full real emulator boot/`adb install`/`adb shell am start`/liveness-check/sensor-injection
  command sequence (`sensor set acceleration ...`, `sensor set magnetic-field ...`) exactly as
  the project's own verification session ran it. Chapter grows from 82 to 123 lines (~3 to ~4
  of a ~40-page target). Volume recompiled clean (289 pages total, 0 undefined references, 0
  duplicate-label warnings); all four of the chapter's own pages verified by rendering to PNG
  and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 41 (Verification Methodology, Compared
  Across Platforms) — first expansion pass, and the last chapter in Part VIII, which is now
  fully swept (Ch.38-41 all have a first pass). This chapter is a synthesis/comparison chapter
  across the three preceding ones, not an API reference or a tooling-invocation narrative, so
  neither the "worked examples" nor the "real shell commands" pattern fit directly. Instead,
  found and closed a genuine content gap the same way this project catches its own: read
  `docs/platform-input-notes.md` and the real `README.md` directly, and noticed this chapter's
  own comparative table covers Linux/Windows/Web/Android but omits macOS entirely, even though
  the project's own docs confirm macOS is a real, distinct platform with working input support
  (mouse warp and global cursor position genuinely work through the SDL3 Cocoa backend) that is
  explicitly flagged "manual-gated" in the project's own notes, since the CI matrix is
  Linux-only. Added a full macOS row to the comparative table and an honest paragraph
  acknowledging this book's own coverage has the same gradient shape — Windows/Web/Android each
  earned a full chapter because each has a substantial verification story to tell, while macOS
  has real support but no comparably deep narrative to expand into its own chapter, since unlike
  Wine (Windows) or the emulator (Android) there is no automated or semi-automated stand-in for
  a real Mac in this project's own dev loop. Also found and fixed one genuine, pre-existing
  stale cross-reference left over from the two-volume merge: this chapter's own opening
  paragraph said "this short closing chapter of Part~IV," a leftover from when this was Volume
  II's own internal Part IV, never updated to Part~VIII during the merge's renumbering pass —
  fixed. Chapter grows from 68 to 83 lines (~3 to ~3 of a ~35-page target). Volume recompiled
  clean (289 pages total, 0 undefined references, 0 duplicate-label warnings); all six of the
  chapter's own pages verified by rendering to PNG and reading them back.

**Part VIII (Chapters 38-41) is now fully swept**: every chapter has a first expansion pass.

- **2026-07-20 (same session, "pokkracuj"):** Chapter 42 (Migrating an XNA or FNA Game to CNA)
  — first expansion pass, and the first chapter of Part IX. This is a checklist-style synthesis
  chapter (six numbered "Step" sections plus a closing "realistic expectation" section) that
  references many earlier chapters rather than introducing new API surface itself, so its gap
  shape was "add concrete worked examples to the two steps that most invite one" rather than
  "grep real headers for missing coverage." Added two worked examples: (1) after Step one's
  intro paragraph, a full XNA/FNA `Update()`/`Draw()` C# pair (as commented-out reference code)
  followed by its mechanical CNA C++23 translation — every signature verified directly against
  `Game.hpp` before finalizing, catching and fixing two real mistakes in the first draft:
  `getGraphicsDeviceProperty()` returns `Graphics::GraphicsDevice&` (a reference, not a
  pointer, so `.Clear(...)` not `->Clear(...)`), and the real virtual override signatures are
  `Update(GameTime& gameTime)` and `Draw(const GameTime& gameTime)`, not by-value `GameTime
  gameTime` as first drafted; (2) at the end of Step three, a worked example hand-computing a
  custom 48-byte vertex struct's stride (`Vector3 Position + Vector3 Normal + Vector2 TexCoord +
  Vector4 Tangent`) and showing explicitly that 48 is not one of the five recognized strides
  (16/20/24/32/52), with a `static_assert` confirming the arithmetic. Also fixed the
  newline-continuation variant of the `/`-spacing overfull-hbox defect (`\texttt{ColorTexture}/%`
  followed by a continued `\texttt{NormalTexture}` on the next line) by hand, since the regex
  pass doesn't catch it. Chapter grows from 102 to 165 lines (~4 of a ~55-page target). Volume
  recompiled clean (289 pages total, 0 undefined references, 0 duplicate-label warnings); all
  four of the chapter's own pages (243-246) verified by rendering to PNG and reading them back.
  One unrelated overfull-hbox warning surfaced in the build log for pre-existing Chapter 36
  content (`easygl::Capabilities::detect_common_features()`) — rendered that page too and
  confirmed it is a false positive with no visible clipping, consistent with this project's
  standing rule that the numeric warning alone is never sufficient evidence either way.
- **2026-07-20 (same session, "pokkracuj"):** Chapter 43 (Case Study: Speedy Blupi and Planet
  Blupi) — first expansion pass. This chapter was already dense with real, specific call-site
  audit findings (exact `Blt`/`BltFast` call counts, the `PCMWAVEFORMAT` layout hazard, the
  `GetDC` live-gameplay dependency), so its gap shape ("Deeper call-site audit detail" per
  PLAN.md) meant finding a genuinely new, real source to deepen it from, not re-deriving what
  was already covered. Read `/workspace/free-direct/docs/audit_ddraw.md` directly — a later,
  dedicated performance audit of the same DirectDraw implementation this chapter already
  discusses, which benchmarked the real compiled library headlessly rather than reasoning from
  Big-O alone. Added one new section, "A performance audit adds exact costs to the same call
  sites," covering: the missing 1:1 fast path in the shared `BlitFrom` blit engine, measured at
  29x slower than a raw `memcpy` at an optimized build and 206x slower at the project's own
  default (unoptimized) build configuration, with a benchmark table; the exact real `BltFast`
  call-site line numbers in both games (`free-eggbert: pixmap.cpp:406,574,580,612,1762,1818`;
  `Planet Blupi: pixmap.cpp:395,401,433,1235,1291`), proving every one is structurally 1:1 per
  the real DirectDraw~3 API's own `BltFast` signature (no destination-size parameter); the
  single highest-leverage finding in the audit (`CMAKE_BUILD_TYPE` defaults to unset, giving a
  6.6x performance penalty project-wide, confirmed via `CMakeCache.txt`); the one confirmed
  real call site where scaling math is genuinely necessary (`free-eggbert`'s
  `CPixmap::Display()`, this chapter's own previously-named hottest call); and a newly-found
  piece of confirmed dead code (`CPixmap::DrawMap`, `pixmap.cpp:640`, zero real callers found
  anywhere in `free-eggbert`'s reconstructed source). Chapter grows from 116 to 172 lines (~4 to
  ~5 of a ~55-page target). Volume recompiled clean (289 pages total, 0 undefined references, 0
  duplicate-label warnings); all four of the chapter's own pages (247-250) verified by rendering
  to PNG and reading them back, including the new benchmark table.
- **2026-07-20 (same session, "pokkracuj"):** Chapter 44 (Auditing Compatibility with
  xna4-spec) — first expansion pass. PLAN.md's gap description ("More worked audit examples")
  was taken literally: the chapter described the three-step audit methodology in the abstract
  but never actually ran it against a real type. Picked `Ray`
  (`Microsoft.Xna.Framework/Ray.xml` in the already-cloned `/workspace/xna4-spec`) as a small,
  complete type worth auditing in full rather than partially, then read CNA's real
  `include/Microsoft/Xna/Framework/Ray.hpp` and checked every field/constructor/method in the
  spec against it member by member. Added a new section documenting a complete, correctly-shaped
  match (both fields, the constructor, all four `Intersects` overload families including the
  detail that `BoundingFrustum` correctly has no `ref`/`out` pair, `ToString`, and the
  `operator==`/`operator!=` pair) plus two precisely-named deviations that are genuinely new
  methodological findings for this book: (1) `Ray` has no `Equals(Object)` overload, which is
  correctly not a gap but a third, previously-undocumented audit-outcome category — a member
  that cannot be translated at all because C++ has no universal boxed root type the way every
  C# value type inherits from `System.Object`; (2) `GetHashCode` returns `std::size_t` rather
  than the spec's `int`, a deliberate convention substitution, not a signature bug. Also noted
  `Ray`'s defaulted zero-argument constructor as a routine, unflagged addition, distinct from an
  "Extra-unmarked" finding. While verifying, found and fixed one genuine, pre-existing
  overfull-hbox defect in this chapter's opening section (a 98.99pt-overfull long URL,
  `learn.microsoft.com/.../previous-versions/windows/xna/`, visibly running off the page edge in
  the rendered PNG) by inserting `\allowbreak{}` after each path segment — confirmed fixed by
  re-rendering the page. Chapter grows from 74 to 117 lines (~3 to ~4 of a ~40-page target).
  Volume recompiled clean (291 pages total, 0 undefined references, 0 duplicate-label warnings);
  all four of the chapter's own pages (251-254, the last one a normal blank right-hand-start
  padding page) verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokkracuj"):** Chapter 45 (cna-samples and cna-examples) —
  first expansion pass. PLAN.md's gap description asked for "per-sample summaries, more of the
  86 samples covered," and cloning `/workspace/cna-samples` fresh (not previously cloned this
  session) turned up something more valuable than a plain summary: the chapter's own existing
  claim — "every one of those 23 failures traces to the same root cause [the .fx bytecode
  gap]" — is measurably imprecise. Read `cna-samples/PLAN.md`'s full 153-sample task list,
  `DEFERRED.md`'s numbered gap items, and the individual `missing.md` write-up for every one of
  the 23 currently-blocked samples directly (not assumed from the summary table) and found the
  real breakdown is three distinct root causes, not one: 16 samples (plus `Spacewar`, blocked on
  a compound of gaps including a shader) trace to the `.fx` gap as claimed, but 4
  (`CustomModelAnimation`, `SkinningSample`, `SkinnedModelExtensions`, `CPUSkinning`) are blocked
  on missing skeletal-animation-playback support (no `AnimationClip`/`Keyframe`/
  `AnimationPlayer` equivalent, a real unimplemented CNA capability) and 2 more (`SplitScreen`,
  `TankOnHeightmap`) are blocked on a narrower, related gap — CNA's `.model.json` reader only
  ever builds a single flat root bone, so a rigid multi-part mesh needing independent per-part
  transforms has nowhere to attach one, even with no animation involved at all. Corrected the
  chapter's existing sentence and added a full new section, "The 23 failures, by actual root
  cause," naming all 23 samples by their real bucket. Also added a second new section covering a
  genuinely instructive finding from the same source material: `SimpleAnimation` was marked
  "Done" once its underlying multi-bone fix landed, but a later session that actually built and
  ran it (rather than trusting the status line) found two real, previously-unnoticed CNA bugs (a
  tank-mesh winding reversal, a `GraphicsDevice` default-state depth-occlusion defect) — serious
  enough that the project opened a dedicated one-task-per-sample re-audit of all 153 catalogued
  samples rather than trusting any existing "Done" status line at face value. Chapter grows from
  54 to 104 lines (~2 to ~4 of a ~45-page target). Volume recompiled clean (293 pages total, 0
  undefined references, 0 duplicate-label warnings); all four of the chapter's own pages
  (255-258, the last one a normal blank right-hand-start padding page) verified by rendering to
  PNG and reading them back.
- **2026-07-20 (same session, "pokkracuj"):** Chapter 46 (Project Practice and Task Tracking) —
  first expansion pass. This chapter described its own `NEXT.md`/`AUDIT.md`/`CHECKLIST.md`/
  `plan_<subsystem>.md`/Doxygen-tag layers entirely in the abstract, with no single task entry
  ever actually quoted — the same "make the abstract concrete" gap shape as Chapter 44. Read
  `/workspace/cna/plan_ascii.md` (already cloned) directly and quoted its `ASCII-40` task row
  almost in full as a new worked example, showing every element the chapter names (a stable
  task ID, a terminal status, a plain description, and a real bug found and fixed mid-task,
  confirmed via a new pixel test) in its native form. Also read `/workspace/cna/plan_graphics.md`
  and found a genuinely new methodological convention not previously described anywhere in this
  book: when a single numbered task turns out to span multiple independent backends, this
  project splits it into one new sub-task per backend (Task~868→923, Task~878→899, each split
  explicitly citing the other as precedent) and rewrites the original row into a "tracking
  pointer" rather than deleting it — the same stale-but-retained-with-a-warning discipline this
  chapter's own opening section already named for `NEXT.md`. One build error was hit and fixed
  along the way: `\checkmark` (from the unloaded `amssymb` package) caused a fatal
  "Undefined control sequence" error; replaced with the plain word "done" rather than adding a
  new package dependency for one symbol. Chapter grows from 100 to 150 lines (~4 to ~5 of a
  ~40-page target). Volume recompiled clean (295 pages total, 0 undefined references, 0
  duplicate-label warnings); all four of the chapter's own pages (259-262, the last one a normal
  blank right-hand-start padding page) verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokkracuj"):** Chapter 47 (Testing Philosophy) — first
  expansion pass. PLAN.md's gap description ("More worked test examples") pointed at the same
  "make the abstract concrete" pattern used for Chapters 44 and 46: this chapter names the
  \texttt{transformMatrix}/\cnaclass{SpriteBatch::Begin()} bug and the Vulkan blend-state bug as
  its two headline pixel-test findings but never actually shows a test. Read
  `/workspace/cna/examples/sdlrenderer_transform_matrix_test.cpp` directly and added a new
  section quoting its core mechanism (draw a sprite at a position only correct if
  `transformMatrix` was actually applied, then `GetBackBufferData()` a specific pixel and assert
  on the real color) as a condensed, verified worked example. While rendering the chapter's
  pages to PNG, found a real, severe (95.37pt) overfull-hbox defect — `SpriteEffects::%
  FlipHorizontally` visibly clipped running off the page edge, mid-paragraph — and fixed it by
  restructuring the sentence so the identifier becomes the very first word of its own paragraph,
  matching the established single-long-identifier fix technique. Chapter grows from 103 to 139
  lines (~3 to ~4 of a ~45-page target). Volume recompiled clean (295 pages total, 0 undefined
  references, 0 duplicate-label warnings); all four of the chapter's own pages (263-266, the
  last one a normal blank right-hand-start padding page) verified by rendering to PNG and reading
  them back, including a second render confirming the overfull-hbox fix.
- **2026-07-20 (same session, "pokkracuj"):** Chapter 48 (Roadmap and Open Gaps) — first
  expansion pass, and the last chapter of Part IX and of the book's main chapter sequence.
  Read `/workspace/cna/docs/graphics-backend-feature-matrix.md` (the project's own internal
  per-feature, per-backend tracking doc) directly to check whether the chapter's four named
  architecture-decision gaps are still current — all four are (`SDL_RENDERER`'s
  `TextureAddressMode`/`Texture3D`/`TextureCube` items and `EASYGL`'s `SurfaceFormat` item all
  still show their original BLOCKED status in the live matrix), so no correction was needed, but
  the check itself is worth recording as a real verification, not an assumption. Added a new
  section expanding the fourth named gap (`Texture3D`/`TextureCube` sampler-bind architecture)
  into a real seven-backend comparison table, condensed from the feature matrix's own row for
  "Texture3D/TextureCube sampled in a shader" — showing the gap is a single architectural
  decision propagating an identical limitation shape into EasyGL/Vulkan/Bgfx (fully blocked) and
  a matching partial-verification shape into all three Direct3D backends (real, working
  `TextureCube` support, but no tested `Texture3D`-in-shader path anywhere). While rendering the
  chapter's pages to PNG, found and fixed a real, severe (139.1pt) overfull-hbox defect — the
  long path `docs/graphics-backend-feature-matrix.md` running off the page edge — via
  `\allowbreak{}` inserted after each path/hyphen segment, the same technique already
  established for the Chapter 44 URL fix. This same fix technique also closed one incidental,
  pre-existing defect found in the same log sweep: an identical long-path overflow (106.7pt) in
  Chapter 10 (SpriteBatch and 2D Rendering), mentioning the same filename in an unrelated
  sentence about `SpriteFont` cross-backend verification status — confirmed via PNG render
  before and after. Chapter 48 grows from 82 to 123 lines (~3 to ~4 of a ~30-page target);
  Chapter 10 grows from 130 to 131 lines (incidental fix only, not a content pass). Volume
  recompiled clean (297 pages total, 0 undefined references, 0 duplicate-label warnings); all
  four of Chapter 48's own pages (267-270, the last one a normal blank right-hand-start padding
  page) and the corrected Chapter 10 page (102) verified by rendering to PNG and reading them
  back. **Part IX (Chapters 42-48) is now fully swept** — every chapter has a first expansion
  pass.
- **2026-07-20 (same session, "pokracuj"):** Dedicated stale-"Part~N"-reference sweep, flagged
  as worth doing in `NEXT.md` since the Chapter 41 merge-era fix earlier this session, but never
  yet done as its own pass. Grepped the entire book for the `Part~[IVX]+` pattern (30+ matches
  across 19 files) and checked every single one against the real `\part{}` structure in
  `main.tex` (Part I = Ecosystem/Ch.1-3, II = Getting Started/Ch.4-8, III = Graphics
  Machine/Ch.9-15, IV = Backends/Ch.16-24, V = Input-Audio-Net/Ch.25-32, VI = Sharp
  Runtime/Ch.33-35, VII = easy-gl-freedirect/Ch.36-37, VIII = Cross-Platform/Ch.38-41, IX =
  Porting-Practice/Ch.42-48). Result: the two-volume merge's own renumbering pass held up very
  well — every reference checked out correct except one genuine (non-merge-related) imprecision
  in Chapter 45: its closing claim that `cna-examples`' intended final shape covers "every area
  this book's own Part~V chapters describe" undercounts, since the areas `cna-examples` itself
  lists (Input, Audio, Devices, Net, Media, 2D Graphics, 3D Graphics) span Parts III-IV
  (graphics) as well as Part V (input/audio/devices/net) — corrected to name both spans
  precisely. Also confirmed no stale plain-text "Volume I"/"Volume II" references remain
  anywhere in the chapter bodies. Volume recompiled clean (297 pages, 0 undefined references, 0
  duplicate-label warnings); the corrected Chapter 45 page (256) verified by rendering to PNG.
- **2026-07-20 (same session, "pokracuj"):** Chapter 30 (Networking) — depth pass, the first
  return to a Part V chapter this session (Part V was breadth-passed in an earlier session).
  Picked this chapter specifically because it had one of the largest absolute page-target gaps
  in the whole book (~5 of ~70 pages). Read `/workspace/cna/plan_net.md`'s Phase 5 ("Real host
  migration") in full — the chapter already named the host-migration claim
  ("lowest remaining wire ID, no election round-trip") but never unpacked the actual algorithm.
  Added a full new section: the disconnect-handler branch point, the deterministic
  `min(every other known wire ID)` promotion computed independently by every survivor with no
  negotiation round-trip, the shared cleanup step (real `GamerLeave` events plus a full
  wire-ID-bookkeeping reset), a worked example subscribing to the real `HostChanged` event, and
  the reconnecting side's real LAN-discovery-then-handshake path — including the explicitly
  confirmed "full reconnect, not live socket migration" scope boundary. Also found, while
  reading the same plan file's Phase 14, a genuinely new real bug not yet in the chapter's "Real
  bugs found and fixed" section: every `GamerCollection<T>` specialization (including
  `NetworkSession`'s own `AllGamers`/`LocalGamers`) had an enumerator whose `MoveNext()`
  unconditionally dereferenced a null collection pointer after `Dispose()` — added with a worked
  repro (`it.Dispose(); it.MoveNext();`) and its fix (the same nullptr guard `getCurrent()`
  already had). Verified every new method/class name (`getAllGamersProperty()`,
  `GetEnumerator()`, `HostChangedEventArgs`) against the real headers before finalizing. While
  running the proactive regex pass, found two genuine pre-existing newline-continuation `}/%`
  defects in this chapter's own original content (never caught before this session) and fixed
  both by hand. Chapter grows from 170 to 235 lines (~5 to ~7 of a ~70-page target). Volume
  recompiled clean (299 pages total, 0 undefined references, 0 duplicate-label warnings); all
  six of the chapter's own pages (189-194, the last one a normal blank right-hand-start padding
  page) verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 34 (Sharp Runtime: Strings, Streams, and a
  Real Audit History) — depth pass, picked as the chapter with the next-largest page-target gap
  after Chapter 30. Read `/workspace/sharp-runtime/POST_STABILIZATION_AUDIT.md` in full (already
  the chapter's own source for its one named finding, `Convert::ToXxx` truncation) and picked
  two more of its twenty findings for full worked treatment: (1)
  `Dictionary<TKey,TValue>`'s non-`const` indexer used to silently auto-insert a default value
  on a missing key rather than throwing `KeyNotFoundException`, exactly the same bug the audit
  notes had already been found and fixed once before in `ConcurrentDictionary` via a dedicated
  `ValueProxy` wrapper — the fix had simply never been propagated; (2)
  `ConcurrentDictionary::GetOrAdd`/`AddOrUpdate` held their lock across the user-supplied
  factory callback's own invocation, so a reentrant factory (a realistic memoization pattern)
  would deadlock against itself, fixed by moving the factory call outside the lock to match
  real .NET's own documented contract. Verified both fixes are live in the real headers
  (`Dictionary.hpp`'s `ValueProxy`, `ConcurrentDictionary.hpp`'s unlocked `factory(key)` call)
  before writing either worked example, rather than assuming the audit's own "subsequently
  fixed" framing without checking. Chapter grows from 162 to 221 lines (~5 to ~7 of a ~70-page
  target). Volume recompiled clean (301 pages total, 0 undefined references, 0 duplicate-label
  warnings); all six of the chapter's own pages (209-214, the last one a normal blank
  right-hand-start padding page) verified by rendering to PNG and reading them back.
- **2026-07-20 (same session, "pokracuj"):** Chapter 25 (The Input System) — depth pass. Despite
  already being the single largest chapter file in the book (534 lines), it still had one of
  the largest absolute page-target gaps (~10 of ~70 pages), confirmed by checking its actual
  physical page count (155-164, 10 pages) before starting rather than assuming line count alone
  meant it was already deep enough. Read `/workspace/cna/plan_input.md` (505 tasks across 13
  phases) looking specifically for real findings not yet named anywhere in the chapter, beyond
  the four bugs already covered (Keyboard/Mouse/GamePad/Touch). Found and added three: (1) a
  GamePad shutdown-symmetry gap — `SDL_INIT_GAMEPAD` was correctly initialized but never
  explicitly quit, unlike FNA's own shutdown path, fixed with a new, idempotent
  `ShutdownGamepadSubsystem()` helper; (2) a genuine asymmetric-test-coverage finding on Mouse —
  the chapter already named `SetPosition`'s write-direction letterbox scaling on
  `SDL_RENDERER`, but a later audit found the read-direction conversion (an incoming motion
  event's window coordinates back to logical ones) had never actually been tested, only fixed
  by adding the missing test; (3) `GestureSample.Timestamp`'s deliberate non-replication of a
  real unit-mismatch bug in FNA's own source (`TimeSpan.FromTicks(Environment.TickCount)` — a
  ~10000x units mismatch between milliseconds and 100ns ticks), documented as a judged,
  accepted deviation rather than an oversight. While running the proactive regex pass, found
  and fixed five genuine pre-existing newline-continuation `}/%` defects in this chapter's own
  original content (MouseState's button-property list, the relative-mouse-mode X/Y note, and
  three in the Haptics section) — never caught in any prior session's pass over this chapter.
  Chapter grows from 534 to 559 lines (~10 to ~12 of a ~70-page target). Volume recompiled
  clean (303 pages total, 0 undefined references, 0 duplicate-label warnings); all twelve of
  the chapter's own pages (155-166, the last one a normal blank right-hand-start padding page)
  verified by rendering to PNG and reading them back.
- **2026-07-20/21 (new session, "podivej se do NEXT.md plan.md... navrhni jak pokracovat" →
  author picked the recommended option, breadth pass on Parts I-IV):** Merged the
  `claude/cna-bible-book-09gxp0` feature branch into `develop` (clean fast-forward, 55 commits,
  per explicit author instruction) and worked directly on `develop` for the rest of the session,
  pushing after every chapter. Installed `latexmk`/`texlive-latex-extra`/
  `texlive-fonts-recommended` (the author ran `apt-get install` interactively; not previously
  present in this session's container). Confirmed sibling repos (`cna`, `sharp-runtime`,
  `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`, `cna-extended`, `cna-template`,
  `libcna.com`) are real, persistent checkouts at
  `/rv/data/development/github.com/openeggbert/<name>` in this environment, not the transient
  `/workspace` path older session notes assumed.

  Executed a full first breadth pass on all 22 previously-untouched Part I-IV chapters (1-6, 8,
  10-24) plus Appendix A — the same chapters that had sat at "Not started" through every prior
  session, while Ch.7 and Ch.9 alone had already been worked. Every chapter got at least one
  real, source-grounded worked example or a corrected inaccuracy, a full rebuild, and its own
  physical PDF pages rendered to PNG and read back before committing (23 separate commits, one
  per chapter, all pushed). Full per-chapter detail is in each chapter's own PLAN.md table-row
  description above and in `NEXT.md`'s own summary; the highlights not to lose track of:

  - **Ch.15 (Shader/.fx Gap): a real, significant correction**, not just an addition — the
    chapter previously claimed `ShaderEffect` exists only on the three Direct3D backends using
    HLSL source. Grepping `CreateEffectBackend()` overrides across
    `src/CNA/Internal/Backends/*/` showed it is also real on EasyGL, Vulkan, BGFX, and SdlGpu —
    EasyGL alone has 38 real tests using it (GLSL source, not HLSL), versus one each for
    D3D11/D3D12. Rewrote both the main section and the "honest summary" paragraph, which had
    the identical stale claim independently.
  - **Two self-authored math errors caught and fixed before commit**, worth remembering as a
    concrete argument for the "verify hand-derived numeric/algebraic claims" rule already in
    this file's Housekeeping section: Ch.22's zFarPlane worked example was initially placed
    *before* the section that first introduces the bug it explains (a structural ordering
    mistake, not a math one, caught by re-reading the rendered page); Ch.24's blend-formula
    worked example initially claimed Add-vs-Subtract "happen to" produce identical output only
    when `dst=0`, which is wrong for `BlendState::Opaque`'s own factors specifically (they
    coincide for *any* `dst` value, since the destination factor itself is `Blend::Zero`) —
    caught by working the arithmetic through by hand, and rewritten using `AlphaBlend`'s
    genuinely nonzero destination factor as the correct illustrative case instead.
  - **A new defect class found this session**: a non-floating `tabularx` table taller than one
    page corrupts silently (empty second column, huge row-height gaps) rather than raising a
    LaTeX error — hit once (Ch.10's Draw-overload table), fixed by switching to `longtable`,
    which paginates correctly. Worth using `longtable` by default for any new reference table
    with more than ~5-6 rows of wrapped prose, not just tabularx-in-a-center-block.
  - **`\allowbreak{}` sometimes needs 2-3 rounds** inside the same long compound identifier
    before an overfull-hbox actually resolves (Ch.16's `std::unique_ptr<IGraphicsBackend>`,
    Ch.24's `ColorDestinationBlend=Blend::InverseSourceAlpha`) — when two rounds don't fix it,
    restructuring the sentence into short independent clauses (proven reliable in Ch.24) beats
    continuing to chase allowbreak placement.
  - **8+ stale plain-text `Chapter~N` citations found and fixed** across Ch.1/2/8/24, several
    pointing at the *wrong* chapter entirely (Ch.8's `tools/fna-reference/` mention cited
    Chapter 37 instead of Chapter 1, where that tool is actually described; Ch.24 cited
    "Chapters~6 and~5" for Audio/Networking, which are actually Chapters 26/30) — not just
    missing a `\ref{}`, genuinely wrong numbers left over from the pre-merge/pre-`\ref{}` era.
  - The recurring `grep -i overfull main.log` unreliability (documented in earlier session-log
    entries) was reconfirmed repeatedly: several real, visible overflows this session produced
    zero log matches, so PNG rendering remained the only trustworthy check throughout.

  Volume recompiled clean throughout, ending the session at **321 pages, 0 undefined
  references, 0 duplicate-label warnings, 1321 index entries**. `NEXT.md` fully rewritten for
  the next session (the old "start with Ch.25" framing is now obsolete — every chapter in the
  whole book has at least a first pass as of this session).

- **2026-07-21 (new session, full autonomous depth pass, tasks #24-41):** Author gave a long,
  explicit autonomous-work authorization (after clarifying this was the target repo, not
  `cna`), directing continued work without further questions unless a major/irreversible
  decision arose. Executed a **depth pass** — a second, deeper touch adding real worked
  examples/findings — across every chapter in the book that had not already received one:
  Ch.1-6/8/10-24 + Appendix A (Parts I-IV, tasks #24-40) and Ch.25-48 (Parts V-IX, task #41),
  one chapter at a time, each rebuilt/undefined-ref-checked/PNG-rendered/visually verified
  before commit (47 commits to `develop` this session, pushed after each). Ch.25/35/39/44
  were checked and found already thoroughly covered from very recent prior work, no edit made;
  Ch.37 was checked, found explicitly author-frozen ("do not expand," confirmed 2026-07-20),
  and correctly skipped rather than treated as just another under-target chapter.

  **The single highest-value technique found this session**: for any chapter about a specific
  CNA subsystem or sibling repo, check that repo's own most-recently-dated `plan_*.md`/
  `NEXT.md`/`audit.md` before assuming a chapter is already exhaustive — found real,
  substantial, previously-uncovered material in well over a dozen chapters this way, even in
  chapters that already looked thorough (full recipe recorded in `NEXT.md`).

  **A recurring meta-finding, confirmed independently at least four separate times across
  totally unrelated subsystems, tracked in entirely separate documents with no cross-reference
  between them**: a status that looked settled (a bug list item marked fixed, a `CLOSED` task,
  an already-run audit round) turned out to be stale once checked against the current, live
  source. Concrete instances: EasyGL's own bug list still called two oracle-methodology bugs
  "logged, not fixed" when both had since been closed (Task 1111/1112, Ch.18); a
  `sharp-runtime` concurrency fix already marked `CLOSED` hid a second, deeper race a later
  dedicated TSan run alone caught (Ch.34's `TaskCompletionSource` writeup and, structurally
  identical one repo over, Ch.28/40's Android `LIFE-001` TSan-inside-a-closed-fix finding); and
  a `cna-samples` bug report describing `GraphicsDevice::Clear(Color)` as still dropping the
  depth buffer turned out to already carry an explicit, commented fix (Task 928, Ch.45). Ch.46
  and Ch.48 both cite this pattern explicitly as a closing methodological observation, tying
  the whole session's own research method back to this project's own stated values from
  Chapter 1. A fifth, different-shaped case: Ch.43 found two audits of the same two-game
  codebase reporting very different `BltFast` call counts (6/5 vs. 18/17) and, rather than
  assuming one was wrong, independently re-grepped both real game repos to confirm *both*
  numbers were correct, just scoped to different questions — added as a worked methodology
  lesson in its own right.

  Other notable individual findings: Ch.9's `ExtractMatrices` mechanism (undocumented internal
  free function, not in any header, that pulls World/View/Projection from the applied `Effect`
  at every draw-dispatch call site) and 6 pre-existing overfull-hboxes found in the same
  section despite Ch.9 already having had "three consecutive prior sessions" of dedicated
  attention, per its own then-current PLAN.md row — a heavily-worked chapter is not
  automatically layout-clean, worth remembering going forward. Ch.32 (Storage) found a real,
  currently undocumented `..`-path-traversal gap in `StorageContainer::ResolvePath()` by
  reading the source directly, with neither the header docs nor the test suite treating it as
  a scoped decision. Ch.19/20 diagnosed the precise, distinct root causes behind Vulkan's and
  BGFX's own separate `RenderTargetCube` black-render bugs (a clear-only-RT gap plus a
  root-cause-still-unresolved sampling bug on Vulkan; a real wrong-handle-type cast on BGFX,
  explained precisely via both backends sharing an identical `struct{uint16_t idx;}` ABI
  shape for framebuffer and texture handles). Several plausible-but-wrong API-name guesses
  were caught and fixed before commit (`TimeSpan::operator+=`, a `RenderTargetBinding`-taking
  `SetRenderTarget` overload, `Device::set_uniform_1f` on `easy-gl`, `AvatarRenderer::%
  setAmbientColorEXTProperty`) — confirming this remains a real, recurring risk category for
  this kind of writing, not a one-off from earlier sessions.

  Volume recompiled clean throughout, ending the session at **347 pages (up from 321), 0
  undefined references, 0 duplicate-label warnings**. `NEXT.md` fully rewritten for the next
  session: every task on the active list (#24-41) is complete; the natural next body of work
  is Appendices B-F (never depth-passed this expansion cycle, all "Not started") or a further,
  third pass continuing to grow every chapter toward its still-distant page target (most
  chapters remain at roughly 10-30% of target after this session's work) — see `NEXT.md`'s own
  "What is NOT yet done" section for the full detail.
