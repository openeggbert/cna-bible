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
| 1 | What Is CNA | 145 | 20 | More ecosystem history/context; still narrative, light expansion | Not started |
| 2 | Ecosystem Map | 141 | 25 | Deeper per-repo detail, more cross-links | Not started |
| 3 | Design Philosophy | 256 | 30 | More NOXNA-discipline worked examples | Not started |
| 4 | Building CNA | 173 | 35 | Full CMake option reference, per-platform build walkthroughs | Not started |
| 5 | First Game | 131 | 40 | Multiple complete worked example programs, step-by-step | Not started |
| 6 | Game Loop | 216 | 40 | Full `Game`/`GameTime`/`GameWindow` method-by-method docs + examples | Not started |
| 7 | Math and Core Types | 1632 (was 270) | 110 | All 11 type-families have full reference + worked examples, most with 2-4; chapter-wide "shared surface" section; Vector Length/LengthSquared, Vector4 clip-space Transform (tied to real SOFTWARE-backend code); Matrix arithmetic statics + Decompose, CreateBillboard/CreateConstrainedBillboard (two independent epsilon fallbacks), CreateShadow/CreateReflection (normalization asymmetry), CreateOrthographic (shadow-map worked example, tied to real CNA test source) worked examples; Quaternion Concatenate-vs-Multiply and Lerp-vs-Slerp angular-velocity findings (both numerically verified); Plane::Transform inverse-transpose finding (numerically verified); Point and CurveKeyCollection full references; Rectangle IsEmpty corrected; Ray second worked example; BoundingBox-specific, BoundingFrustum-specific, and BoundingSphere::Transform (non-uniform-scale, numerically verified) worked examples | **In progress (~33 of ~110 pages) --- three consecutive sessions focused entirely on this chapter; still well short of target, see PLAN.md session log for what's still missing** |
| 8 | Content and Assets | 125 | 55 | Full `ContentManager` API + CNJ/XNB worked walkthroughs | Not started |
| 9 | GraphicsDevice | 872 (was 171) | 90 | Full method-by-method docs for the 887-line header; two real, verified backend-specific gaps found and documented (SpriteBatch can't sample a RenderTarget2D; SupportsCapability(MultipleRenderTargets) always returns true even where MRT silently fails); full private-implementation lifecycle section (window/backend/virtual-resolution) traced from GraphicsDevice.cpp, ties directly to Ch.6's PresentationMode; new GraphicsAdapter multi-monitor enumeration + a third real gap (IsProfileSupported/QueryRenderTargetFormat/QueryBackBufferFormat are only genuinely hardware-checked on D3D9, honestly documented as `true`/simplified stubs on the other nine backends) | **In progress (~23 of ~90 pages)** |
| 10 | SpriteBatch | 130 | 55 | Every `Begin`/`Draw`/`DrawString` overload documented + examples | Not started |
| 11 | Textures and Render Targets | 207 | 60 | Full `Texture2D`/`RenderTarget2D` API + examples | Not started |
| 12 | Models and Meshes | 103 | 60 | Full `Model`/`ModelMesh`/`ModelBone` family + examples | Not started |
| 13 | Stock Effects | 191 | 80 | Full property/method docs for all 5 effects + examples each | Not started |
| 14 | State Objects | 159 | 55 | Full `BlendState`/`DepthStencilState`/`RasterizerState`/`SamplerState` docs | Not started |
| 15 | Shader/.fx Gap | 78 | 30 | More worked examples of the runtime-compiled path | Not started |
| 16 | Backend Architecture | 133 | 40 | Deeper interface-by-interface backend contract docs | Not started |
| 17 | SDL_Renderer Backend | 115 | 55 | Full bug-list detail, more worked examples | Not started |
| 18 | EasyGL Backend | 100 | 65 | Deeper feature-by-feature coverage | Not started |
| 19 | Vulkan Backend | 110 | 65 | Deeper feature-by-feature coverage | Not started |
| 20 | BGFX Backend | 87 | 55 | Full 38-gap-list detail with worked repro examples | Not started |
| 21 | WebGPU Backend | 108 | 45 | Deeper feature-by-feature coverage | Not started |
| 22 | Direct3D Backends | 152 | 85 | Split attention across D3D9/D3D11/D3D12 in full | Not started |
| 23 | Canvas/ASCII Backends | 139 | 40 | More worked examples | Not started |
| 24 | DX3/free-direct Backend | 65 | 30 | Deeper coverage (see free-direct conflict note above) | Not started |
| A | API Quick Reference | 229 | 40 | Expand summary tables into fuller per-class entries, still a reference (not full docs — that lives in the narrative chapters above) | Not started |

**Volume I subtotal: ~1,305 pages.**

## Parts V–IX (formerly "Volume II") — target ~1,200 pages (chapters 25–48 + Appendices B–F)

Merged into a single book on 2026-07-20. Chapter and appendix numbers below are the
**post-merge** numbers (originally chapters 1–24 and Appendices A–E within old Volume II;
the renumbering table is in the 2026-07-20 session log entry below if the old numbers are
ever needed).

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 25 | Input System | 534 (was 170) | 70 | Full method references + worked examples for KeyboardState/Keyboard's EXT scancode surface, MouseState/Mouse's relative-mouse-mode EXT surface, GamePadState/the three GamePadDeadZone modes, TouchCollection/TouchLocation/GestureSample, TextInputEXT (IME-aware composition), and all five NOXNA-only device subsystems (Clipboard/Joysticks/Sensors/Power/Haptics) | **In progress (~10 of ~70 pages)** |
| 26 | Audio System | 378 (was 118) | 60 | Full method references + worked examples for SoundEffect, SoundEffectInstance/Apply3D 3D audio, DynamicSoundEffectInstance streaming, the AudioEngine/SoundBank/WaveBank/Cue XACT playback model, Microphone capture, AudioCategory retroactive volume, AudioEngine::RendererDetails, SoundEffect::FromStream, and the three audio exception types | **In progress (~8 of ~60 pages)** |
| 27 | Media | 300 (was 103) | 45 | Full method references + worked examples for Song, the AudioTagParser tag-reading pipeline, MediaQueue's ownership model, MediaPlayer playback/shuffle/repeat internals, VideoPlayer multi-track switching (three real bugs found by external review), and the GetVisualizationData FFT pipeline (lock-free ring buffer + from-scratch radix-2 FFT) | **In progress (~6 of ~45 pages)** |
| 28 | Devices and Sensors | 208 (was 115) | 45 | Worked examples for Accelerometer/VibrateController/Camera grounded in real headers, plus the SetCurrentValueAndMarkDataValid race-closing finding and the vibrate intensity-zero-is-not-Stop() finding | **In progress (~6 of ~45 pages)** |
| 29 | GamerServices | 169 (was 117) | 55 | Worked examples for SignedInGamer achievements/presence, LeaderboardWriter scoring, and Guide's real overlay message-box UI, grounded in real headers | **In progress (~5 of ~55 pages)** |
| 30 | Networking | 125 | 70 | Full NetworkSession/NetworkGamer docs + worked multi-peer examples | Not started |
| 31 | Avatar | 131 | 55 | Full Avatar/SkinnedModelEXT docs + examples | Not started |
| 32 | Storage | 78 | 30 | Full StorageDevice/StorageContainer docs + examples | Not started |
| 33 | Sharp Runtime Overview | 116 | 40 | Deeper architectural detail | Not started |
| 34 | Sharp Runtime Namespaces | 90 | 70 | Full docs for TimeSpan/EventHandler/Stream/collections + examples | Not started |
| 35 | Parity Philosophy | 111 | 35 | More worked deviation examples | Not started |
| 36 | EasyGL Deep Dive | 112 | 55 | Deeper coverage | Not started |
| 37 | free-direct Deep Dive | 65 | ~2 (no change) | **Stays marginal per author confirmation 2026-07-20 — do not expand** | N/A — intentionally frozen |
| 38 | Windows/Wine | 103 | 45 | Deeper verification detail | Not started |
| 39 | Web/Emscripten | 88 | 40 | Deeper build/deploy detail | Not started |
| 40 | Android/NDK | 82 | 40 | Deeper build/deploy detail | Not started |
| 41 | Verification Methodology | 68 | 35 | More worked audit examples | Not started |
| 42 | Migration Guide | 102 | 55 | Full worked porting walkthroughs | Not started |
| 43 | Blupi Case Study | 116 | 55 | Deeper call-site audit detail | Not started |
| 44 | xna4-spec Auditing | 74 | 40 | More worked audit examples | Not started |
| 45 | Samples and Examples | 54 | 45 | Per-sample summaries, more of the 86 samples covered | Not started |
| 46 | Project Practice | 100 | 40 | Deeper task-tracking-methodology detail | Not started |
| 47 | Testing Philosophy | 103 | 45 | More worked test examples | Not started |
| 48 | Roadmap | 82 | 30 | Deeper detail | Not started |
| B | Feature Matrix | 58 | 15 | Modest expansion, stays a reference table | Not started |
| C | Glossary | 74 | 15 | More terms | Not started |
| D | Repo Map | 127 | 20 | Modest expansion | Not started |
| E | NOXNA Catalog | 114 | 20 | More entries | Not started |
| F | API Quick Reference: Ecosystem and Platforms | 155 | 25 | Modest expansion, stays a reference | Not started |

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
