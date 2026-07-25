# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **470 physical PDF pages, 49 chapters, 6 appendices**.
- The book repository started this autonomous session clean. The local branch is now ahead of
  `origin/develop`: the roadmap correction (`a8b38ae`, `docs: correct roadmap source drift`)
  and the current ShaderEffect batch are local.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

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

- `main.pdf`: 470 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 1,969 accepted, 0 rejected, 0 warnings.
- Ch.15 physical pages 167--172 rendered at 120 dpi and inspected in full.
- Ch.23 new/reflowed physical pages 240--246 rendered at 140 dpi and inspected; page 246 is
  the intentional open-right blank before Ch.24.
- No page-edge overflow, malformed table, listing spill, running-header collision, or folio
  defect was found. The new Ch.23 section emits no local overfull warning. Ch.15 retains older
  logged overfull lines, but every final rendered page was inspected and remains visually
  inside the page geometry.

Run before the next commit:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch15-shader-fx-gap.tex \
      latex/book/chapters/part4-backends/ch23-direct3d-backends.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` now records 470 total pages and exact line counts: Ch.15 is 327 lines; Ch.23 is
  696 lines.
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

Audit the cross-backend summaries that consume the corrected ShaderEffect facts, especially
Appendix B's feature matrix and Ch.16's `IEffectBackend` description. Correct only claims that
the live source disproves, then continue with the next source-grounded chapter expansion in
the active graphics/backend area.
