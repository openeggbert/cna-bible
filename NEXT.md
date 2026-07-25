# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **474 physical PDF pages, 49 chapters, 6 appendices**.
- The book repository started this autonomous session clean. The local branch is now ahead of
  `origin/develop` by three coherent documentation commits: the roadmap correction, the
  ShaderEffect/D3D ABI correction, and the capability/feature-matrix correction.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

A source audit following the ShaderEffect batch found a broader
`GraphicsCapability`/cross-backend-summary drift. Ch.9, Ch.11, Ch.16, Ch.24, Appendix B, and
Appendix C now agree with the live implementations:

- ASCII is 2D-only but inherits `IGraphicsBackend::SupportsCapability()`'s default-true answer,
  so `ThreeD`, `CustomEffects`, and `OcclusionQuery` are confirmed false positives.
- `CustomEffects` also overclaims BGFX, WebGPU, and Software for four distinct failure shapes;
  Ch.9 and Ch.16 now enumerate them rather than calling the capability system uniformly
  reliable.
- `OcclusionQuery` overclaims WebGPU, SDL GPU, and Software (null factory) plus ASCII
  (SDL renderer's throwing factory). Both capability worked examples now guard the known
  false positives explicitly.
- Ch.16 now records the actual per-backend `IEffectBackend` setter boundary rather than
  claiming every working backend overrides every hook.
- Ch.11 and Appendix B no longer present BGFX's fixed `RenderTargetCube` wrong-handle cast as
  current.
- Appendix B corrects its stale BGFX custom-effect `OK` cell and reclassifies SDL_Renderer's
  intentional no-shader-stage result from `BLK` to `N/A`.
- Appendix B's top summary is now a page-breaking `longtable`, not a clipped `tabular`; its
  status grid uses documented `P` cells for `PARTIAL`, eliminating visible column collisions.
  Ch.24's pre-existing page-edge spills were also removed while validating its new ASCII text.

## Previous completed batch

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

- `main.pdf`: 474 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 1,973 accepted, 0 rejected, 0 warnings.
- Rendered and inspected the final affected pages: Ch.9 physical 117--118 and 123; Ch.11
  page 141; Ch.16 pages 179--181; Ch.24 pages 253--254; Appendix B pages 443--446; Appendix C
  page 448.
- No clipping, column collision, page-edge spill, malformed table, listing spill,
  running-header collision, or folio defect was found. Ch.24 and Appendix B emit zero local
  overfull warnings. Older warnings elsewhere in Ch.9/11/16/C remain outside the changed text;
  every changed final page was inspected directly.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch09-graphicsdevice.tex \
      latex/book/chapters/part3-graphics-core/ch11-textures-rendertargets.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch24-canvas-ascii-backends.tex \
      latex/book/chapters/appendices/appendix-b-feature-matrix.tex \
      latex/book/chapters/appendices/appendix-c-glossary.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` now records 474 total pages and exact line counts: Ch.9 1,002; Ch.11 391; Ch.16
  290; Ch.24 340; Appendix B 164; Appendix C 159.
- The durable session log records the capability false positives, feature-matrix corrections,
  Appendix B pagination fix, and exact final validation.
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

If continuing the capability audit, directly verify the two remaining entries not exhaustively
covered in this pass: `MultiSampleAntiAliasing` and `AnisotropicFiltering`, including
device-dependent answers on backends that inherit the default `true`. Otherwise resume the
highest-value source-grounded chapter expansion in the active graphics/backend area; all
ShaderEffect and capability-summary consumers identified in this pass are now synchronized.
