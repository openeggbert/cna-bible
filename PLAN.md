# The CNA Bible — Expansion Plan (1000–2000 pages per volume)

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

## Volume I — target ~1,300 pages (24 chapters + Appendix A)

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 1 | What Is CNA | 145 | 20 | More ecosystem history/context; still narrative, light expansion | Not started |
| 2 | Ecosystem Map | 141 | 25 | Deeper per-repo detail, more cross-links | Not started |
| 3 | Design Philosophy | 256 | 30 | More NOXNA-discipline worked examples | Not started |
| 4 | Building CNA | 173 | 35 | Full CMake option reference, per-platform build walkthroughs | Not started |
| 5 | First Game | 131 | 40 | Multiple complete worked example programs, step-by-step | Not started |
| 6 | Game Loop | 216 | 40 | Full `Game`/`GameTime`/`GameWindow` method-by-method docs + examples | Not started |
| 7 | Math and Core Types | 758 (was 270) | 110 | All 11 type-families now have a full method/constructor reference (Vector2/3/4, Matrix, Quaternion, Plane, Ray, Rectangle, Point, Color, MathHelper, 3 Bounding types, Curve/CurveKey) plus worked examples per group and 2 real screenshots | **In progress (~22 of ~110 pages; every type-family covered at least once, depth can still grow further)** |
| 8 | Content and Assets | 125 | 55 | Full `ContentManager` API + CNJ/XNB worked walkthroughs | Not started |
| 9 | GraphicsDevice | 622 (was 171) | 90 | Full method-by-method docs for the 887-line header; render-target worked example found and documented a real SOFTWARE-backend bug (SpriteBatch can't sample a RenderTarget2D) | **In progress (~16 of ~90 pages)** |
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

## Volume II — target ~1,200 pages (24 chapters + Appendices A–E)

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 1 | Input System | 170 | 70 | Full Keyboard/Mouse/GamePad/TouchPanel docs + examples | Not started |
| 2 | Audio System | 118 | 60 | Full SoundEffect family docs + examples | Not started |
| 3 | Media | 103 | 45 | Full Song/MediaPlayer/MediaLibrary docs + examples | Not started |
| 4 | Devices and Sensors | 115 | 45 | Full sensor API docs + examples | Not started |
| 5 | GamerServices | 117 | 55 | Full Achievement/Leaderboard/Gamer docs + examples | Not started |
| 6 | Networking | 125 | 70 | Full NetworkSession/NetworkGamer docs + worked multi-peer examples | Not started |
| 7 | Avatar | 131 | 55 | Full Avatar/SkinnedModelEXT docs + examples | Not started |
| 8 | Storage | 78 | 30 | Full StorageDevice/StorageContainer docs + examples | Not started |
| 9 | Sharp Runtime Overview | 116 | 40 | Deeper architectural detail | Not started |
| 10 | Sharp Runtime Namespaces | 90 | 70 | Full docs for TimeSpan/EventHandler/Stream/collections + examples | Not started |
| 11 | Parity Philosophy | 111 | 35 | More worked deviation examples | Not started |
| 12 | EasyGL Deep Dive | 112 | 55 | Deeper coverage | Not started |
| 13 | free-direct Deep Dive | 65 | ~2 (no change) | **Stays marginal per author confirmation 2026-07-20 — do not expand** | N/A — intentionally frozen |
| 14 | Windows/Wine | 103 | 45 | Deeper verification detail | Not started |
| 15 | Web/Emscripten | 88 | 40 | Deeper build/deploy detail | Not started |
| 16 | Android/NDK | 82 | 40 | Deeper build/deploy detail | Not started |
| 17 | Verification Methodology | 68 | 35 | More worked audit examples | Not started |
| 18 | Migration Guide | 102 | 55 | Full worked porting walkthroughs | Not started |
| 19 | Blupi Case Study | 116 | 55 | Deeper call-site audit detail | Not started |
| 20 | xna4-spec Auditing | 74 | 40 | More worked audit examples | Not started |
| 21 | Samples and Examples | 54 | 45 | Per-sample summaries, more of the 86 samples covered | Not started |
| 22 | Project Practice | 100 | 40 | Deeper task-tracking-methodology detail | Not started |
| 23 | Testing Philosophy | 103 | 45 | More worked test examples | Not started |
| 24 | Roadmap | 82 | 30 | Deeper detail | Not started |
| A | Feature Matrix | 58 | 15 | Modest expansion, stays a reference table | Not started |
| B | Glossary | 74 | 15 | More terms | Not started |
| C | Repo Map | 127 | 20 | Modest expansion | Not started |
| D | NOXNA Catalog | 114 | 20 | More entries | Not started |
| E | API Quick Reference | 155 | 25 | Modest expansion, stays a reference | Not started |

**Volume II subtotal: ~1,163 pages** (the 1,195 estimate above included a ~35-page target for
Ch.13 that is now frozen at ~2 pages per the author's confirmation above).

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
