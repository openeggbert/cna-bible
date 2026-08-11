# Renderer draw-path divergence matrix

This report closes the last deliberately deferred research item in `PLAN.md` §3.2. It audits all
**42 implementation families / 46 public identities** at CNA
`7a64362efef4119bf880459ef1704fb2c52199e2`. CNA and its siblings remained read-only.

The matrix answers four narrowly defined questions:

1. Does the family override both `DrawPrimitivesEx` and `DrawIndexedPrimitivesEx`, or inherit the
   shared colored-primitive fallback?
2. What does that route ultimately do: renderer-owned effect dispatch, explicit refusal,
   validation/trace only, or silent parameter loss?
3. Can the family create and bind a real `RenderTarget2D`?
4. Does the implementation genuinely support multiple simultaneous render targets (MRT) and real
   occlusion queries, independently of what `SupportsCapability()` claims?

This is a **routing and contract matrix**, not a claim that every renderer-owned route implements
every stock-effect field with equal fidelity. The family chapters still own those narrower
effect/state differences.

## 1. Contract baseline

`IGraphicsRenderer` establishes three materially different defaults:

- `DrawPrimitivesEx` and `DrawIndexedPrimitivesEx` discard the entire `GpuDrawParams` object and
  call `DrawColoredPrimitives` / `DrawIndexedColoredPrimitives`
  (`modules/graphics/include/CNA/Internal/Renderers/Common/IGraphicsRenderer.hpp:1718-1744`).
- `CreateOcclusionQuery()` and `CreateRenderTarget2D()` return `nullptr`
  (`IGraphicsRenderer.hpp:1427,1449`).
- `SetRenderTargets()` is pure virtual (`IGraphicsRenderer.hpp:1502-1503`), so every concrete
  family must at least choose how to accept or reject a target set.

Capability reporting is a separate path. `SupportsCapability()` returns `true` for every entry
except `MultiStreamVertexInput` (and delegates `StencilBuffer`) unless a family opts out
(`IGraphicsRenderer.hpp:1818-1834`). A green capability answer therefore does **not** prove a
factory or draw path exists.

### Legend

| Code | Meaning |
|---|---|
| **native** | Both `Draw*Ex` methods are renderer-owned. “Native” includes bounded fixed-function and CPU raster routes; it does not imply full stock-effect parity. |
| **native/hybrid** | Both methods are renderer-owned, but one or more unmatched effect/layout combinations explicitly re-enter the colored route. Some combinations then throw; others can draw an approximation. |
| **fallback→reject** | The family inherits the shared parameter-discarding fallback, but its colored route rejects 3D. No wrong image is submitted. |
| **fallback→colored** | The family inherits the fallback and really draws through the colored path. Effect parameters are silently lost. |
| **reject** | The family overrides both methods specifically to reject them. |
| **trace** | The family validates/records the request but rasterizes nothing. |
| **fallback→no-op** | The shared fallback reaches an intentional no-op colored path. |
| **yes** | Real/bounded implementation exists. |
| **conditional** | Depends on the selected profile, compile-time API, driver entry points, or device feature. |
| **trace-only** | Resource/query object exists for validation, not for pixels or real sample counts. |
| **no (claims yes)** | Implementation rejects/returns null, but `SupportsCapability()` reports true. This is a CNA defect, not support. |

## 2. The 42-family matrix

| Family | Public identity / identities | `Draw*Ex` route | `RenderTarget2D` | MRT, actual | Occlusion query, actual |
|---|---|---|---|---|---|
| `bgfx` | `BGFX` | native | yes | yes | conditional (bgfx capability bit) |
| `blend2d` | `BLEND2D` | fallback→reject | yes, CPU raster | no | no |
| `canvas` | `CANVAS` | fallback→reject | yes, Canvas2D | no | no |
| `diligent` | `DILIGENT` | native | yes | yes | conditional (device features) |
| `direct2d` | `DIRECT2D` | fallback→reject | yes | no | no |
| `directx1` | `DIRECTX1` | fallback→reject | yes, off-screen surface | no | no |
| `directx2` | `DIRECTX2` | native, fixed-function | yes | no | no |
| `directx3` | `DIRECTX3` | native, fixed-function | yes | no | no |
| `directx5` | `DIRECTX5` | native, fixed-function | yes | no | no |
| `directx6` | `DIRECTX6` | native, fixed-function | yes | no | no |
| `directx7` | `DIRECTX7` | native, fixed-function | yes | no | no |
| `directx8` | `DIRECTX8` | native, fixed-function | yes | no | no |
| `directx9` | `DIRECTX9` | native | yes | yes | yes |
| `directx10` | `DIRECTX10` | **fallback→colored** | yes | yes | no |
| `directx11` | `DIRECTX11` | native | yes | yes | yes |
| `directx12` | `DIRECTX12` | native | yes | yes | yes |
| `easygl` | `OPENGLES2`, `OPENGLES3`, `OPENGL33`, `WEBGL1`, `WEBGL2` | native | yes | conditional: false on ES2/WebGL1, true otherwise | conditional: false on ES2/WebGL1, true otherwise |
| `fna3d` | `FNA3D` | native | yes | yes | yes |
| `freedirect` | `FREEDIRECT` | fallback→reject | yes, DirectDraw surface | no | no |
| `gdi` | `GDI` | reject | yes, CPU bitmap | no | no |
| `glide` | `GLIDE` | native, fixed-function | **no; factory throws** | no | no |
| `headless` | `HEADLESS` | trace | trace-only | **no (claims yes)** | **trace-only (claims yes)** |
| `html-dom` | `HTML_DOM` | fallback→reject | yes, DOM off-screen target | no | no |
| `llgl` | `LLGL` | native | yes | yes | yes |
| `magnum` | `MAGNUM` | native | yes | conditional (`maxMrtTargets_`) | yes |
| `metal` | `METAL` | native | yes | no | no |
| `opengl1` | `OPENGL1` | native, fixed-function | conditional (FBO availability) | no | conditional (ARB/core query availability) |
| `opengl2` | `OPENGL2` | native | yes | conditional (`glDrawBuffers`) | conditional (`glGenQueries`) |
| `opengl4` | `OPENGL4` | native/hybrid | yes | yes | yes |
| `opengles1` | `OPENGLES1` | native/hybrid, fixed-function | yes | no | no |
| `openvg` | `OPENVG` | fallback→reject | no | no | no |
| `portablegl` | `PORTABLEGL` | native, CPU fixed pipeline | no | no | no |
| `sdl-gpu` | `SDL_GPU` | native/hybrid | yes | yes | **no (claims yes)** |
| `sdl-renderer` | `SDL_RENDERER` | fallback→reject | yes | no | no |
| `skia` | `SKIA` | reject | yes, CPU raster | no | no |
| `software` | `SOFTWARE` | native, CPU raster | yes, CPU raster | **no (claims yes)** | **no (claims yes)** |
| `sokol` | `SOKOL` | native | yes | yes | conditional (GL build only) |
| `stub` | `STUB` | fallback→no-op | no | no | no |
| `svg-dom` | `SVG_DOM` | fallback→reject | yes, DOM off-screen target | no | no |
| `vulkan` | `VULKAN` | native | yes | yes | yes |
| `webgpu` | `WEBGPU` | native/hybrid | yes | **no (claims yes)** | **no (claims yes)** |
| `wicked` | `WICKED` | native | yes | yes | yes |

Mechanical partition checks:

- 42 family rows exactly; EasyGL contributes four additional identities, so the table covers
  46 identities.
- 31 families override **both** ordinary effect-aware methods; 11 inherit both defaults.
- Of the 31 override families: 28 own a rendering path (24 direct, four hybrid), GDI and SKIA
  reject, and HEADLESS validates/traces.
- Of the 11 inheritance families: nine reach an explicit 3D refusal, STUB reaches an intentional
  no-op, and **DIRECTX10 alone reaches a real colored draw after discarding `GpuDrawParams`**.

## 3. Colored fallback topology

### 3.1 DIRECTX10 is the only unconditional inherited downgrade

The eleven families with no `DrawPrimitivesEx` or `DrawIndexedPrimitivesEx` declaration are:

```
blend2d canvas direct2d directx1 directx10 freedirect html-dom openvg
sdl-renderer stub svg-dom
```

Nine terminate in their colored routes with `HandleUnsupported3DCall`, `ThrowNo3D`, or an
equivalent refusal (`Blend2DRenderer.hpp:407-423`; `CanvasRenderer.cpp:370-376`;
`Direct2DRenderer.cpp:3242-3253`; `DirectX1Renderer.cpp:1171-1179`;
`FreeDirectRenderer.cpp:1356-1364`; `HtmlDomRenderer.cpp:1048-1054`;
`OpenVgRenderer.cpp:731-738`; `SdlRenderer.cpp:918-926`; `SvgDomRenderer.cpp:691-697`). STUB's
colored routes are empty by design (`StubRenderer.hpp:155-173`).

DIRECTX10 is different: it has real colored vertex/index buffer submission
(`DirectX10Renderer.cpp:1323-1380`) but no effect-aware override. The base therefore drops texture,
lighting, fog, skinning, alpha-test, draw offsets, and the rest of `GpuDrawParams`, then produces a
plausible untextured colored result. It is the only family where **every** ordinary effect-aware
draw is forced through the inherited colored fallback.

### 3.2 Four overrides still contain a conditional colored fallback

An override-presence grep alone would miss a second tier. Four renderer-owned implementations
explicitly call their own colored route when dispatch does not find a supported combination:

- OPENGLES1 sends skinning, PBR, custom effects, instancing, and unavailable dual-texture/env-map
  combinations to colored rendering (`OpenGLES1Renderer.cpp:2088-2105,2198-2215`). This is an
  intentional fixed-function ceiling, but the call still succeeds with reduced semantics for
  layouts the colored reader accepts.
- SDL_GPU exhaustively dispatches its supported stride/effect combinations, then calls colored
  rendering (`SdlGpuRenderer.cpp:5636-5696,5698-5752`). Non-16-byte layouts fail in
  `QueueColoredDraw`, but an unsupported effect combined with the 16-byte colored layout can still
  produce a colored approximation.
- WEBGPU has the same unmatched-combination tail (`WebGPURenderer.cpp:7298-7389,7392-7459`). Its
  own comment says non-16-byte layouts then throw; the 16-byte case can still draw.
- OPENGL4 calls colored rendering when `BindProgramForStride()` returns false
  (`OpenGL4Renderer.cpp:3550-3581,3584-3630`). The colored route's faithful-declaration guard
  makes unsupported non-colored layouts fail loudly, so this is principally a rejection fallback,
  not the unconditional semantic downgrade DIRECTX10 embodies.

The result is a three-level answer for Chapters 19 and 32: **11 families inherit the default;
four more override it but retain a conditional colored tail; 27 override families have no direct
colored-tail call** (24 rendering, two refusal, one trace). This report does not claim that the
remaining 24 rendering routes consume every individual `GpuDrawParams` field; that is effect
fidelity, not call routing.

## 4. Capability contradictions found by the matrix

### M1. Three families claim MRT but reject every multi-target set

- HEADLESS returns true by default from its capability switch (`HeadlessRenderer.cpp:644-661`)
  but throws for `count > 1` (`:617-629`).
- SOFTWARE returns true from its switch's default (`SoftwareRenderer2DState.cpp:96-120`) but
  throws for `count > 1` (`:143-153`).
- WEBGPU special-cases only `WireFrame`, then delegates to the permissive base
  (`WebGPURenderer.cpp:6065-6074`); its `SetRenderTargets` throws for `count > 1`
  (`:7108-7123`).

The public `GraphicsCapability::MultipleRenderTargets` contract is “more than one simultaneous
render target,” so all three answers contradict reachable implementation behavior.

### M2. Four families claim real occlusion queries without a real query path

- SDL_GPU and WEBGPU inherit the `nullptr` factory while reporting true; this is the already
  recorded `cnabugs.md` CNA-BUG-012 / `audit/renderer-catalog.md` F5.
- SOFTWARE also inherits the `nullptr` factory — its own header says so
  (`SoftwareRenderer.hpp:504-507`) — but its capability switch falls through to true.
- HEADLESS returns a bookkeeping object whose `PixelCount()` is the constant 1 and whose class
  documentation says it touches no GPU (`HeadlessRenderer.hpp:512-535`), while reporting true.

This is not a dispute over whether a no-op renderer is useful. The enum's documented meaning is a
**real GPU occlusion query**; validation objects and null factories do not meet it.

### M3. The shared capability test preserves these wrong answers

`GraphicsDeviceCapabilityTests.cpp:66-152` has special cases for only a subset of renderers and a
catch-all expectation of true for MRT, occlusion queries, and custom effects. HEADLESS, SOFTWARE,
SDL_GPU and WEBGPU all reach that catch-all for the relevant entries. The assertions at
`:212-221` compare one reported Boolean with another hard-coded Boolean; they never exercise a
two-target bind or require a usable query object.

## 5. Book impact

1. Chapter 19 must teach inherited fallback versus hybrid fallback versus direct dispatch, not
   merely “override versus no override.”
2. Chapter 23 must call out WEBGPU's real RT2D/cube support while keeping MRT and occlusion query
   explicitly open; SDL_GPU has real MRT but no occlusion-query API.
3. Chapter 27 must distinguish HEADLESS validation objects from pixel/query capabilities and
   SOFTWARE's real CPU raster path from its unsupported MRT/query paths.
4. Chapter 32 and Appendix B must derive capability tables from implementation behavior, then
   annotate reporting defects. They must not reproduce `SupportsCapability()` blindly.
5. DIRECTX10 needs a visible warning in Chapters 19 and 25; OPENGLES1, SDL_GPU, WEBGPU and
   OPENGL4 need narrower hybrid-route notes. A successful effect-aware draw call is not by itself
   evidence that the requested effect was honored.

## 6. Verification boundary

This report was produced by exhaustive static source inspection and mechanically checked family
partitioning. No CNA build or renderer execution was performed, preserving the pinned source's
read-only audit rule. “Actual” means the reachable implementation path at the pin, not a fresh
runtime reproduction on every native API/device combination. Runtime-conditional entries are
labelled rather than collapsed into yes/no.
