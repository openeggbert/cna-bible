# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **478 physical PDF pages, 49 chapters, 6 appendices**.
- The book repository started this autonomous session clean. The local branch is now ahead of
  `origin/develop` by four coherent documentation commits: the roadmap correction, the
  ShaderEffect/D3D ABI correction, the general capability/feature-matrix correction, and the
  MSAA/anisotropy capability audit.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

The two device-dependent `GraphicsCapability` entries are now audited across every live
backend and synchronized through Ch.9, Ch.14, Ch.16, Ch.22, Ch.23, Ch.24, and Appendix C:

- `MultiSampleAntiAliasing` is definitely false-positive on ASCII and Software. Vulkan,
  WebGPU, SDL GPU, and D3D9 can negotiate back to one sample while their public query remains
  true. BGFX also overclaims the default legacy-OpenGL path despite its pixel-proven resolve
  failure. EasyGL performs a real live limit check; D3D11/D3D12's feature-level 11.0 floor
  makes their RGBA8 answer sound.
- `AnisotropicFiltering` is definitely false-positive on ASCII, SDL GPU, and Software. D3D9's
  query and setter do not consult `D3DCAPS9::MaxAnisotropy`; BGFX exposes only an on/off flag
  and ignores the requested maximum. EasyGL/Vulkan use live checks, WebGPU creates a real
  sampler, and D3D11/D3D12 have the required feature-level support.
- Headless records both requests for logic tests but rasterizes no pixel; its inherited
  `true` answers are not rendering evidence.
- Ch.16 now contains the complete 11-row comparison and the practical rule: after reset, read
  the applied `PresentationParameters.MultiSampleCount`, or a render target's own applied
  count. Do not infer the negotiated count from the capability boolean.
- Ch.22 explicitly connects SDL GPU's stored-but-unused anisotropy to the false public answer;
  Ch.23 distinguishes D3D9's internal sample check from the public capability query; Ch.24
  records all five ASCII false positives.

## Previous completed batch

The preceding source audit corrected the broader `GraphicsCapability` and cross-backend
summary drift:

- ASCII overclaims `ThreeD`, `CustomEffects`, and `OcclusionQuery`; `CustomEffects` also
  overclaims BGFX, WebGPU, and Software; `OcclusionQuery` also overclaims WebGPU, SDL GPU, and
  Software.
- Ch.16 now records the real per-backend `IEffectBackend` setter boundary.
- Ch.11 and Appendix B no longer present BGFX's fixed `RenderTargetCube` cast as current.
- Appendix B corrects its BGFX custom-effect and SDL_Renderer cells and now uses pageable,
  collision-free tables.

## Earlier completed batch

### Ch.15: correct the real ShaderEffect backend boundary

The previous chapter text treated a `CreateEffectBackend()` override as proof of working
cross-backend custom shading. The live implementations show a much narrower matrix:

- EasyGL compiles GLSL, supports real named uniforms/arrays and 2D/cube/volume texture binds,
  and alone consumes `GpuDrawParams::customEffectBackend` in general 3D draws.
- SDL GPU compiles GLSL to SPIR-V through `libshaderc`, then uses a fixed-layout SpriteBatch
  path (including its tested MRT shader).
- Vulkan expects raw precompiled SPIR-V bytes inside the two constructor strings; it does not
  compile GLSL. Its working custom path is fixed-layout SpriteBatch.
- D3D9 compiles HLSL to the active SM2/SM3 profile. D3D11 and D3D12 compile
  `vs_5_0`/`ps_5_0`; all three tested public paths are SpriteBatch facilities.
- BGFX's `CompileProgram()` always returns false. The object reports that binary shaders are
  required, but `ShaderEffect` exposes no binary-loading route.
- Software accepts non-empty strings and reports validity but renders through its fixed CPU
  shader. Headless records compilation/binds/uniforms/2D textures without producing pixels.
- WebGPU and DX3 inherit the null factory and reject a non-null SpriteBatch effect.
  SDL_Renderer construction is harmless and invalid; passing the non-null object to
  `SpriteBatch::Begin()` is what throws. Canvas also rejects it.

Ch.15 now states these distinctions explicitly and corrects its prior “Vulkan takes GLSL”
claim. It also labels the general-3D and arbitrary-vertex-layout worked paths as EasyGL-only.

### Ch.23: document the D3D11/D3D12 fixed custom-effect ABI

The new section is grounded in `D3D11EffectBackend`, `D3D12EffectBackend`, and the real smoke
tests:

- fixed 32-byte SpriteBatch vertex: `float2 POSITION0` at byte 0, `float2 TEXCOORD0` at byte 8,
  and `float4 COLOR0` at byte 16;
- fixed 128-byte block: backend `vpSize` at 0--15, one matrix at 16--79, one overlapping vector
  at 80--95, one float-converted scalar/int at 96--99, and padding thereafter;
- uniform names are ignored; array setters and all three extra-texture hooks remain inherited
  no-ops; SpriteBatch supplies only the primary `t0`/`s0` pair;
- D3D11 binds separate shader/input/buffer context state; D3D12 constructs one prebuilt PSO for
  a single-sample RGBA8 target with fixed pipeline state;
- both public smoke tests compile the documented HLSL and require solid red to read back as
  exact cyan. D3D11 runs windowed under Wine/DXVK; D3D12 uses `HeadlessEXT` off-screen.

## Validation

The final forced build succeeded:

```bash
cd latex/book
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex
```

Results:

- `main.pdf`: 478 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 1,978 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.9 physical pages 122--124, Ch.14 pages 166--168, Ch.16 pages
  182--186, Ch.22 pages 231--233, Ch.23 pages 239--241, Ch.24 pages 257--259, and Appendix C
  pages 451--453.
- No clipping, column collision, page-edge spill, malformed table, running-header collision,
  or folio defect was found. The new Ch.16 longtable repeats its header correctly. The changed
  Ch.14 and Ch.24 paragraphs emit no local overfull warning; older warnings elsewhere remain
  outside this batch's changed ranges.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch09-graphicsdevice.tex \
      latex/book/chapters/part3-graphics-core/ch14-state-objects.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch22-sdlgpu-backend.tex \
      latex/book/chapters/part4-backends/ch23-direct3d-backends.tex \
      latex/book/chapters/part4-backends/ch24-canvas-ascii-backends.tex \
      latex/book/chapters/appendices/appendix-c-glossary.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 478 total pages and exact current line counts: Ch.9 1,029; Ch.14 341;
  Ch.16 359; Ch.22 492; Ch.23 703; Ch.24 347; Appendix C 162.
- The durable session log records both capability-audit batches, their exact per-backend
  conclusions, and final PDF validation.
- Ch.49 describes the real Phase-G-complete XNB read pipeline, current Texture hierarchy, and
  typed EasyGL custom-effect texture support.
- `README.md` has build/navigation guidance; `CLAUDE.md` says 49 chapters.

## Repository safety

Do not modify the existing user-owned sibling-repository changes:

- `cna`: `cmake/Tests/EasyGLTests.cmake`, `cmake/Tests/SdlRendererTests.cmake`, and
  `examples/xvfb_screenshot_demo.cpp`;
- `cna-samples`: `samples/SimpleAnimation/Content/tank.model.json`.

Sibling repositories remain read-only source authorities for ordinary book work.

## Blockers and `needs_human`

- No book-writing task currently needs a human decision.
- Push is operationally blocked by the failed approval-service review described above; local
  work and commits can continue safely.
- Real Windows/D3D9-era hardware remains the only way to close the narrow authenticity limit
  around capability values synthesized by DXVK. Keep that marked `needs_human`; it does not
  block independent work.

## Recommended next starting point

The eight-entry `GraphicsCapability` audit is complete and its known consumers are
synchronized. Resume the highest-value source-grounded chapter expansion in the active
graphics/backend area. A good first candidate is Ch.16's remaining backend-interface defaults:
enumerate unreviewed permissive defaults, trace whether each has a reachable call path, and
document only source-proven gaps. Do not attempt to fix CNA itself from this book repository;
sibling repositories remain read-only source authorities.
