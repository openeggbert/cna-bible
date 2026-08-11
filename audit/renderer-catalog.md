# Audit report — the renderer catalog (46 public identities)

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root.

---

## Executive summary

CNA declares **46 public renderer identities** mapped onto **42 implementation families**
(`docs/renderer-registry.md`; `modules/renderers/CMakeLists.txt:4-8`). The count is mechanically
pinned by `scripts/check_renderer_identities.py`, which cross-checks the
`CNA::GraphicsRendererType` enum against the `CNA_GRAPHICS_RENDERER` CMake `STRINGS` list.

Three facts dominate the book impact:

1. **The book's Part IV covers 11 of 46 identities, and 3 of those 11 names no longer exist**
   (`EASYGL`, `ASCII`, `DX3`).
2. **The project's own central cross-renderer document,
   `docs/graphics-renderer-feature-matrix.md`, covers 8 of 46** and names one renderer (`EasyGL`)
   that is no longer an accepted build selector at all.
3. **The per-renderer docs are the trustworthy tier.** 42 of 46 identities have a current, precise
   `docs/<x>-renderer.md`. The failure mode in this repository is *not* renderers over-claiming in
   documentation — it is one central matrix lagging roughly a month behind the code, plus a handful
   of stale in-code comments.

Live code defects found during this pass are collected in FACTS 3, 5, 6, 7 and CONTRADICTIONS
C1–C10; four of them are worth reporting upstream independently of the book.

---

## 1. RENDERER TABLE

Grouped by the clustering proposed in §7. `CTests` counts CTest registration call sites under
`modules/renderers/<family>/` unless noted; registration count is **not** assertion count (for
example `DirectX12_Smoke` is 2 registrations containing dozens of internal named checks).

### Cluster 1 — The OpenGL family (10 identities, 6 families)

| Identity | Enum | Family | Platform gate (mechanism) | Dependency & acquisition | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `OPENGLES2` | `OpenGLES2` | `easygl` (shared ×5) | non-Emscripten `FATAL_ERROR` `cmake/RendererSelection.cmake:434`; `WARNING` if non-Linux `:446` | `../easy-gl` **sibling checkout**, not a submodule; `FATAL_ERROR` if absent `:453`; `add_subdirectory` `:462` | 2D + 3D; **GLSL ES 1.00**, rewritten from ES 3.00 source | implemented — deliberately the narrowest GL profile | 293 (shared across all 5) | Bounded by core OpenGL ES 2.0; 55 of 61 `CNA_GL_PROFILE_*` sites exist to work around it |
| `OPENGLES3` | `OpenGLES3` | `easygl` (×5) | as above; **Linux default** `:11` | as above | 2D + 3D; GLSL ES 3.00 | implemented — broadest 3D coverage in the repo | ″ | Non-`Color` `SurfaceFormat` GPU forwarding is a long-standing BLOCKED item (Task 732) |
| `OPENGL33` | `OpenGL33` | `easygl` (×5) | as above | as above | 2D + 3D; **GLSL 330 core**, real core-profile context | implemented | ″ | Genuinely distinct context, not a cosmetic alias — see FACT 9 |
| `WEBGL1` | `WebGL1` | `easygl` (×5) | **Emscripten-only** `FATAL_ERROR` `:439` | as above | 2D + 3D; GLSL ES 1.00 | implemented | ″ | 11 dedicated `CNA_GL_PROFILE_WEBGL1` workaround sites |
| `WEBGL2` | `WebGL2` | `easygl` (×5) | **Emscripten-only** `FATAL_ERROR` `:439`; **Emscripten default** `:9` | as above | 2D + 3D; GLSL ES 3.00 | implemented | ″ | Bit-for-bit the same code path as `OPENGLES3` — see FACT 9 |
| `OPENGL1` | `OpenGL1` | `opengl1` | Linux **or** Windows only, `FATAL_ERROR` `:374` | system OpenGL (`find_package(OpenGL)`) | 2D + 3D **fixed-function**; **no shader stage at all** | implemented | 38 | No programmable pipeline by definition; permanent GL 1.x ceilings |
| `OPENGL2` | `OpenGL2` | `opengl2` | none (implicit `find_package`) | system OpenGL | 2D + 3D; **GLSL 1.10** | implemented | 48 | Compatibility-profile only; cannot be served by EasyGL (`:135-139`) |
| `OPENGL4` | `OpenGL4` | `opengl4` | none (implicit) | system OpenGL + hand-rolled loader; `find_package(OpenGL REQUIRED)` `:794` | 2D + 3D; **GLSL 410 core** | implemented | 25 | Deliberately independent of the EasyGL family (`:127-131`) |
| `OPENGLES1` | `OpenGLES1` | `opengles1` | **system-library `FATAL_ERROR`** in the module's own CMake | `libGLESv1_CM` + `GLES/gl.h`, hard system dependency, not vendored (`:120-125`) | 2D + 3D **fixed-function**; **no shaders** | implemented | 7 | Needs a **custom ES1-enabled Mesa build** (`scripts/opengles1-test-env.sh`); stock Mesa ships `-Dgles1=disabled` |
| `PORTABLEGL` | `PortableGL` | `portablegl` | none (CPU-only) | FetchContent, pinned `63a55db` (tag 0.100.0), `cmake/ThirdPartyPortableGL.cmake` | 2D + 3D on CPU; **shaders are C function pointers** | partial (bounded, explicit refusals) | 12 | No GPU resource of any kind; bounded feature set with deliberate rejections |

### Cluster 2 — Native modern GPU (4)

| Identity | Enum | Family | Platform gate | Dependency & acquisition | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `VULKAN` | `Vulkan` | `vulkan` | none; `find_package(Vulkan REQUIRED)` `:600` | system Vulkan SDK / loader | 2D + 3D; **SPIR-V, precompiled and checked in** (`src/shaders/spirv_shaders.hpp`, 3,545 lines) | **implemented** — 136 overrides, zero `HandleUnsupported3DCall` | 211 | One open item: `RasterizerState.DepthBias` extreme-magnitude sub-case |
| `SDL_GPU` | `SdlGpu` | `sdl-gpu` | none | vendored SDL3 submodule only; `libshaderc.so.1` needed for `ShaderEffect` | 2D + 3D; **SPIR-V only** (`SdlGpuRenderer.cpp:1206-1222`) | **implemented**, but Vulkan-backend-only by design | 83 | No DXIL/MSL path exists; **claims `OcclusionQuery` while `CreateOcclusionQuery()` returns `nullptr`** (FACT 5) |
| `WEBGPU` | `WebGPU` | `webgpu` | **native desktop only**; Emscripten hits `FATAL_ERROR` `cmake/ThirdPartyWebGPU.cmake:53` | **downloaded prebuilt** wgpu-native `v29.0.1.1` release archive at configure time (network required) | 2D + 3D; **WGSL**, 20 inline `R"WGSL(...)"` literals, no `.wgsl` files | **partial** — the enum's "experimental" label is conservative given 23k lines and 80 CTests | 80 | No MRT, no mip regeneration, no custom SpriteBatch effects, no WireFrame; **same occlusion-query defect as SDL_GPU** (FACT 5) |
| `METAL` | `Metal` | `metal` | **macOS-only** `FATAL_ERROR` `:366`; `enable_language(OBJCXX)` `:770` | Apple system frameworks | 2D + 3D; **MSL**, embedded string, `newLibraryWithSource:` at runtime | **partial**, unusually transparently so | 3 | MRT, MSAA, custom effects, occlusion queries, instancing, multi-stream input **and `ReadBackbuffer` all throw by design**, each citing missing macOS pixel evidence (`MetalRenderer.mm:3240-3246`) |

### Cluster 3 — Abstraction-layer wrappers (7)

| Identity | Enum | Family | Gate | Dependency & acquisition | Native backend & when resolved | Shader pipeline | Maturity | CTests |
|---|---|---|---|---|---|---|---|---|
| `BGFX` | `Bgfx` | `bgfx` | `WARNING` if non-Linux `:485` | FetchContent `bgfx.cmake` @ `572868c0cb952add48019d267223453958e958b8` **+ local patch** `cmake/patches/bgfx-max-render-target-msaa.patch` via `PATCH_COMMAND` `:588-589` | Compile+runtime hybrid: `BgfxRendererSelection.cpp:31-38` hardcodes `RendererType::OpenGL` on Linux, `Count`(auto) elsewhere; `CNA_BGFX_RENDERER` env override `:40-92` | `.sc` sources → **offline** `shaderc` (external binary; `CNA_BGFX_BUILD_SHADERC` defaults **OFF** `:569-571`) → checked-in `bgfx_shaders.hpp` (15,545 lines) | implemented | 179 |
| `MAGNUM` | `Magnum` | `magnum` | **Emscripten `FATAL_ERROR`** `:416-421` | `find_package(Magnum QUIET)` first, else FetchContent Corrade `783e4e48` + Magnum `5a742464`; `CNA_MAGNUM_ROOT` override | Compile-time only; desktop GL via **GLX** by default, EGL behind `-DCNA_MAGNUM_USE_EGL=ON` (`cmake/ThirdPartyMagnum.cmake:36-49`) | **GLSL as raw C++ string literals** in `MagnumStockShaders.cpp` (835 lines), driver-compiled at runtime — **the only one of the 7 with zero offline shader tooling** | partial | 8 |
| `LLGL` | `Llgl` | `llgl` | none | FetchContent tag `Release-v0.04b`; `CNA_LLGL_ROOT` override | **Runtime**, own module-loader probe: `LlglRendererSelection.cpp:89-101` offers only `{OpenGL}` on Linux; `:134-140` **throws** if `CNA_LLGL_RENDERER=vulkan` | Dual GLSL flavours both checked in: `*.vert.glsl` → SPIR-V via `glslangValidator`, `*.gl.vert.glsl` → verbatim GLSL, both in `llgl_shaders.hpp` (5,188 lines); has `--check` staleness mode | partial (self-declared narrower-than-upstream boundary, `docs/llgl-renderer.md:23`) | 97 |
| `DILIGENT` | `Diligent` | `diligent` | none | FetchContent `v2.5.6` | **Runtime**, ordered fallback `D3D12 → Vulkan → D3D11 → OpenGL` (`DiligentRenderer.cpp:315-330`), filtered by `CNA_DILIGENT_HAS_*`; on Linux the real list is `[Vulkan, OpenGL]` (`cmake/ThirdPartyDiligent.cmake:42-45`) | **Single HLSL source cross-compiled by DiligentCore at runtime**, per device type; `#pragma pack_matrix(row_major)` required because the HLSL2GLSL converter only recognizes the pragma form | partial — closest to full parity of the 7 | **~63 entries** = 31 binaries × 2 device types + 1 non-doubled |
| `SOKOL` | `Sokol` | `sokol` | none | FetchContent `27b49604` | **Compile-time only** via `CNA_SOKOL_API` ∈ {GLCORE, GLES3, DIRECTX11, METAL, WGPU}; `WARNING` for anything but GLCORE `:525-531` | `.glsl` → **offline sokol-shdc** (11 MB prebuilt binary, not vendored) → `sokol_shaders.hpp` (13,726 lines) with `#ifdef SOKOL_*` blocks per API; has `--check` | partial — functionally single-backend | 37 |
| `WICKED` | `Wicked` | `wicked` | Emscripten `FATAL_ERROR` `:493-497`; `WARNING` if not Linux/Windows `:498-500` | FetchContent + **three local patches**: `wicked-sdl3-platform.patch`, `wicked-device-teardown.patch`, `wicked-staging-footprint.patch` | **Hardcoded** — `WickedRenderer.cpp:1469-1480` unconditionally constructs `GraphicsDevice_Vulkan`; D3D12 explicitly not selected (`WICKED-60`) | HLSL compiled **at device creation** by Wicked's DXC wrapper; 22 entry points; `minshadermodel = SM_6_0` (`:1597-1605`) | **experimental** | 5 (4 real + 1 gated smoke), registered in `cmake/Tests/WickedTests.cmake` |
| `FNA3D` | `Fna3d` | `fna3d` | none | FetchContent FNA3D @ `3240147`; **effect blobs vendored separately** | **Runtime, inside the vendored library**: `FNA3D_CreateDevice` picks SDL_GPU / D3D11 / OpenGL; `FNA3D_FORCE_DRIVER` hint | **No CNA-authored shaders exist.** 6 pre-compiled **D3D9 Effect Framework `.fxb`** blobs from pinned FNA rev `30a427365a...`, checked into git, executed through **MojoShader** | implemented within its declared OpenGL-driver scope | 12 |

**FNA3D is pedagogically unique:** per `modules/renderers/fna3d/effects/README.md:10-14`,
`FNA3D_CreateEffect()` is the library's *only* shader entry point, making this **the one CNA
renderer that executes XNA's own `BasicEffect`/`SkinnedEffect` shader programs rather than a
reimplementation of them.**

### Cluster 4 — The legacy DirectX / retro ladder (9)

All nine are covered by the single Windows-only `FATAL_ERROR` at
`cmake/RendererSelection.cmake:347-353` except `FREEDIRECT`, which is deliberately **not**
Windows-gated.

| Identity | Enum | Family | Gate | Dependency & acquisition | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `DIRECTX1` | `DirectX1` | `directx1` | Windows `FATAL_ERROR` `:347` | `ddraw dxguid` via mingw-w64 cross toolchain (`cmake/toolchains/mingw-w64.cmake`) | 2D DirectDraw v1 only; **no shaders** | implemented (2D) | 10 | DirectX 1 shipped no Direct3D at all — 3D is *permanently* unavailable, not unimplemented |
| `DIRECTX2` | `DirectX2` | `directx2` | ″ | ″ | 2D + D3D v2 `DrawPrimitive` fixed-function | implemented | 19 | Execute buffers deliberately **not** used — see FACT 22 |
| `DIRECTX3` | `DirectX3` | `directx3` | ″ | ″ | 2D DDraw v2 + D3D v2 | implemented | 19 | Landed as `DX30` while `FREEDIRECT` still owned the `DIRECTX3` name (`:76-79`) |
| `DIRECTX5` | `DirectX5` | `directx5` | ″ | ″ | DDraw v4 + D3D v3 FVF `DrawPrimitive` | implemented | 19 | First era with execute buffers fully gone |
| `DIRECTX6` | `DirectX6` | `directx6` | ″ | ″ | Same COM interfaces as DX5 + **real stencil** | implemented | 20 | **Reports `SupportsCapability(StencilBuffer) == false` despite shipping tested stencil** (FACT 7) |
| `DIRECTX7` | `DirectX7` | `directx7` | ″ | ″ | DDraw v7 + D3D v7, flattened device model (no viewport object) | implemented | 20 | Same stencil-capability defect as DX6 (FACT 7) |
| `DIRECTX8` | `DirectX8` | `directx8` | ″ **plus** `FATAL_ERROR` if `/usr/lib/dxvk/wine64/d3d8.dll.a` is absent | **DXVK / D8VK import library** — mingw-w64 ships no real x86_64 d3d8 import lib (`:104-112`) | Real GPU 2D quads + fixed-function 3D; **no shaders, by explicit scope decision** | implemented (fixed-function ceiling) | 20 | Same stencil-capability defect (FACT 7); SM1.x deliberately skipped as unusable for real XNA content |
| `FREEDIRECT` | `FreeDirect` | `freedirect` | **not Windows-gated**; `FATAL_ERROR` if `../free-direct` missing `:472-483` | `free-direct` **sibling clone**, not a submodule | 2D only | implemented (2D) | 21 | Formerly named `DIRECTX3`; SDL3-backed, genuinely native-Linux-buildable |
| `GLIDE` | `Glide` | `glide` | Windows `FATAL_ERROR` **plus 32-bit-only `FATAL_ERROR`** `:358-362` | user-supplied `glide3x.dll` at **runtime**; dgVoodoo2 deliberately not vendored (licence) `:154-155` | 3D fixed-function; **no shaders** | implemented (ABI layer) | 3 | **Rendering is never automatically tested anywhere** (FACT 17) |

**Measured port lineage** (normalized diff, identifiers collapsed): DX1→DX2 ≈48% churn (new 3D
layer); **DX2→DX3 ≈3.7%** (near-verbatim); DX3→DX5 ≈17%; **DX5→DX6 ≈6%**; DX6→DX7 ≈21%; DX7→DX8
near-total rewrite. DX2–DX8 each declare exactly **35** overrides; DX1 declares 29.

### Cluster 5 — Modern Direct3D + Windows 2D (6)

| Identity | Enum | Family | Gate | Dependency & acquisition | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `DIRECTX9` | `DirectX9` | `directx9` | Windows `FATAL_ERROR` `:347` | Wine + DXVK; own vendored MS-PL `.fx` + offline SM2 bytecode | 2D + 3D; **`vs_2_0`/`ps_2_0`** (Reach) or **`vs_3_0`/`ps_3_0`** (HiDef), runtime `D3DCompile` | **implemented** — 52 overrides; the only oracle-exact renderer | 51 | `Texture3D` has no GPU round-trip or oracle coverage; not validated on real Windows hardware (`D9-140`) |
| `DIRECTX10` | `DirectX10` | `directx10` | ″ | Wine builtin `d3d10.dll`/`d3d10_1.dll` forwarding to DXVK `d3d10core` + `dxgi` (`:113-118`) | 2D + 3D; **`vs_4_0`/`ps_4_0`**, 2 embedded shaders, no stock effects | **partial by explicit design** — 34 overrides | 10 | `CreateEffectRenderer`, `CreateOcclusionQuery`, `CreateTexture3D`, `CreateTextureCube`, `CreateRenderTargetCube` all left at the base `nullptr` |
| `DIRECTX11` | `DirectX11` | `directx11` | ″ | DXVK; shares `modules/renderers/common/d3d` (`modules/renderers/CMakeLists.txt:68-72`) | 2D + 3D; **`vs_5_0`/`ps_5_0`** + shared precompiled `hlsl_shaders.hpp` (38,867 lines) | implemented — 48 overrides | 41 | `cna_reference_dump`/`cna_demo_2d` fail to link (pre-existing, unrelated) |
| `DIRECTX12` | `DirectX12` | `directx12` | ″ | **vkd3d-proton** via Proton; shares `common/d3d` | 2D + 3D; `vs_5_0`/`ps_5_0` + root-signature/PSO caches | implemented — 45 overrides | 2 (one large multi-check smoke binary) | Routine CTests are all off-screen; presentation proven only via a manual Proton diagnostic |
| `DIRECT2D` | `Direct2D` | `direct2d` | ″ | **Wine/Proton's own builtin d2d1/d3d11/dxgi — explicitly NOT DXVK**; `CNA_D3D11_SKIP_DXVK_GATE=1` in every registration | 2D only; **no shader stage** (ID2D1 API) | implemented for its 2D scope — 84 overrides | 4 | Release gate self-declared BLOCKED pending a native-Windows run (`docs/direct2d-release-gate.md:29-33`) |
| `GDI` | `Gdi` | `gdi` | ″ | `gdi32`; **reuses the SOFTWARE rasterizer** | 2D only; **no shaders** (CPU raster) | implemented (2D) — real CPU stencil, honest 4× CPU MSAA | 19 | All 19 CTests are gated `if(NOT CMAKE_CROSSCOMPILING)` — none run on the Linux host (FACT 17) |

**GDI/SOFTWARE sharing is structural, not nominal:** `modules/renderers/CMakeLists.txt:75-81`
enters `software` when `GDI` is selected; `software/CMakeLists.txt:17-27` exports 8 `.cpp` files as
`CNA_GDI_SOFTWARE_SOURCES`; and `GdiRenderer.cpp:36` declares
`class GdiSoftware2DCore final : public Software::SoftwareRenderer`.

### Cluster 6 — 2D / vector rasterizers (4)

| Identity | Enum | Family | Gate | Dependency & acquisition | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `SKIA` | `Skia` | `skia` | none | **manually-supplied prebuilt artifact** via `CNA_SKIA_ROOT` + `CNA_SKIA_BUILD_DIR`, `FATAL_ERROR` if absent — the only dependency not fetched | 2D only; bounded **SkSL** extensions (`CNA_SKIA_SKSL_V1`, `CNA_SKIA_SKSL_MESH_V1`) | implemented for a rigorously bounded 2D contract | 178 | `CNA_SKIA_MODE` RASTER/GANESH sub-selector is *not* a separate identity; no MRT, no MSAA, no occlusion query, no 3D — each with a written rejection rationale |
| `BLEND2D` | `Blend2D` | `blend2d` | none | FetchContent Blend2D `def0d1238c` + AsmJit `b56f4176`; `*_ROOT` overrides | 2D only; no shaders | implemented (2D) | 4 | CPU raster presented through a streaming SDL texture; no native per-channel colour write mask |
| `OPENVG` | `OpenVg` | `openvg` | Linux / Windows / macOS only, `FATAL_ERROR` `:383` | FetchContent ShivaVG @ its **only** commit `6122ccb3` (2010) + leak patch + synthesized `config.h` + GL type shim + `OpenGL::GLU` | 2D only; no shaders (OpenVG 1.1 on fixed-function GL) | implemented (2D) | 7 | **`SupportsCapability` returns `false` for all 13 flags**; needs a real fixed-function GL context |
| `SDL_RENDERER` | `SdlRenderer` | `sdl-renderer` | none; **default on non-Linux, non-Emscripten** `:13` | vendored SDL3 submodule `third_party/SDL` @ `cbe3fbe9f` | 2D only; no shader stage | implemented (2D); 3D is **intentionally-unsupported** via 17 `HandleUnsupported3DCall` sites | 80 | `TextureAddressMode::Wrap`/`Mirror` BLOCKED (Tasks 686/687); `Texture3D`/`TextureCube` construction BLOCKED (Task 725) |

### Cluster 7 — Web / DOM (3)

| Identity | Enum | Family | Gate | Dependency | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `CANVAS` | `Canvas` | `canvas` | **Emscripten `FATAL_ERROR`** `:387-392` | browser `canvas.getContext('2d')` | 2D only; no shaders | implemented (2D) | **0 — test executables are built but deliberately never registered** | Capabilities true only for `AdditiveBlending` |
| `HTML_DOM` | `HtmlDom` | `html-dom` | **Emscripten `FATAL_ERROR`** `:395-400` | browser DOM + CSS | 2D only; no shaders (pooled CSS-transformed `<div>`s) | implemented (2D) | 1 host contract + real Playwright/Chromium CI | `AdditiveBlending` is browser-version-dependent (`plus-lighter`); 3D refusal **bypasses the `WarnAndStub` policy** (FACT 4) |
| `SVG_DOM` | `SvgDom` | `svg-dom` | **Emscripten `FATAL_ERROR`** `:404-409` | browser SVG DOM | 2D only; SVG-native `feColorMatrix` tint | implemented (2D) | 0 — host target behind an OFF-by-default option with no CI reference | Same policy-bypass as HTML_DOM (FACT 4) |

### Cluster 8 — Non-GPU / diagnostic (3)

| Identity | Enum | Family | Gate | Dependency | 2D / 3D / Shader | Maturity | CTests | Real limitations |
|---|---|---|---|---|---|---|---|---|
| `HEADLESS` | `Headless` | `headless` | none | none | Renders no pixels; validation modes, trace log, draw/state counters | implemented (for its stated purpose) | 48 | Makes no pixel-fidelity claim by design |
| `SOFTWARE` | `Software` | `software` | none | none | 2D + bounded 3D on CPU; no shader stage | implemented, bounded v1 | 60 | `TriangleList` only, BasicEffect subset (no lighting/fog), nearest-neighbour texturing, simplified Opaque/AlphaBlend; `Texture3D` honestly reports `false` |
| `STUB` | `Stub` | `stub` | none | none | Renders nothing | **intentionally-minimal** — 232 lines | 1 | `SupportsCapability` returns `false` unconditionally; keeps no bookkeeping at all |

---

## 2. THE RENDERER CONTRACT

The interface is `CNA::IGraphicsRenderer`, declared at
`modules/graphics/include/CNA/Internal/Renderers/Common/IGraphicsRenderer.hpp:1322-1955`
(the file is 2,079 lines). There is no `IGraphicsBackend` any more — the project renamed
*backend* → *renderer* on 2026-08-10 (commit `57aee5f88`). Stale `audit/**/…GraphicsBackend…`
files survive from before that rename and describe a layout (`CNA/Internal/Backends/…`) that no
longer exists.

### Virtual surface

**70 virtual declarations, of which 25 are pure virtual.** The mandatory set is small and
deliberately 2D-shaped:

`Clear`, `Present`, `GetViewportSize`, `SetVirtualResolution`, `SetPresentationMode`,
`GetWindowInternal`, `GetRendererInternal`, `CreateTexture`, `CreateSpriteBatch`,
`SetRenderTargets`, the six `Clear*` depth/stencil combinations (`:1612-1641`),
`SetDepthTestEnabled` / `SetBlendEnabled` / `SetDepthWriteEnabled` (`:1649-1651`),
`CreateVertexBuffer`, `CreateIndexBuffer16`, and the two `Draw*ColoredPrimitives`.

Ten sub-interfaces are declared in the same header and carry most of the real work:
`IVertexBufferRenderer` (`:94`), `IIndexBufferRenderer` (`:150`), `IOcclusionQueryRenderer`
(`:183`), `ITextureCubeRenderer` (`:201`), `ITexture3DRenderer` (`:297`), `ITextureRenderer`
(`:366`), `IRenderTargetRenderer` (`:430`), `IRenderTargetCubeRenderer` (`:482`),
`IEffectRenderer` (`:652`), `ISpriteBatchRenderer` (`:704`).

### Throwing and no-op defaults

Everything genuinely optional defaults to **`return nullptr;`**:

```
:1427  virtual std::unique_ptr<IOcclusionQueryRenderer> CreateOcclusionQuery() { return nullptr; }
:1428  virtual std::unique_ptr<ITexture3DRenderer>      CreateTexture3D(...)   { return nullptr; }
:1429  virtual std::unique_ptr<ITextureCubeRenderer>    CreateTextureCube(...) { return nullptr; }
:1449  virtual std::unique_ptr<IRenderTargetRenderer>   CreateRenderTarget2D(...)   { return nullptr; }
:1482  virtual std::unique_ptr<IRenderTargetCubeRenderer> CreateRenderTargetCube(...) { return nullptr; }
```

Other defaults are silent no-ops (`SetScissorRect` `:1567`, `SetViewport` `:1570`,
`ApplySamplerMipState` `:1553`, `SetBlendFactor` `:1557`, `SetReferenceStencil` `:1564`,
`SetStringMarkerEXT` `:1870`, `DebugSimulateContextLoss` `:1876`), and
`DrawInstancedPrimitivesEx` throws a `std::runtime_error` unless overridden (`:1784-1785`).

The header's own design note (`DirectX9Renderer.hpp:289-292`) captures the intent:
*"inheriting 'throws' is fine, only inheriting silence is the trap."* FACT 5 and CONTRADICTION
C6 show that trap firing in current code.

### How a renderer opts out of 3D — three non-equivalent idioms

1. **`HandleUnsupported3DCall(rendererName, methodName)`** (`:1916-1936`) — the shared,
   **policy-aware** route. Under the default `Unsupported3DGraphicsCallBehavior::Throw` it throws;
   under `WarnAndStub` it logs one warning per method name and returns. The companion
   `ShouldStubUnsupported3DResource()` (`:1939-1943`) lets factories return safe null-objects
   instead of `nullptr`.
2. **Overriding `Ensure3DSupported(const char*)`** (`:1604`, default no-op) — an early guard
   invoked by shared draw/model entry points *before* they inspect, pack, allocate or bind any 3D
   input.
3. **Leaving the optional factory at its `nullptr` default** — the silent path the codebase's own
   documentation criticises (`GraphicsCapability.hpp:56-58`, REMED-CONTENT-004).

**Only 6 of roughly 14 2D-limited renderers use the policy-aware route.**
`HandleUnsupported3DCall` call-site counts by family: `direct2d` 18, `canvas` 17, `freedirect` 17,
`openvg` 17, `sdl-renderer` 17, `blend2d` 6 — and nothing else.
`ShouldStubUnsupported3DResource` appears in only 4 families (`canvas`, `freedirect`, `openvg`,
`sdl-renderer`).

SKIA, HTML_DOM and SVG_DOM instead use unconditional `[[noreturn]]` local helpers —
`SkiaUnsupported3D.hpp:13-16` (`ThrowSkiaUnsupported3D`), `HtmlDomRenderer.cpp:594-597` and
`SvgDomRenderer.cpp:295-298` (both `ThrowNo3D` → `NotYetImplemented`). Consequently the documented
public knob `GraphicsDevice::SetUnsupported3DGraphicsCallBehavior(WarnAndStub)`
(`GraphicsDevice.hpp:1041`) is **silently inert on those three renderers**.

There is also a separate, finer-grained trio of queries used by `GraphicsDevice::Clear` to mask
impossible clear bits rather than forward them: `SupportsDepthStencil()` (`:1586`, default `true`),
`SupportsDepthBuffer()` (`:1590`) and `SupportsStencilBuffer()` (`:1596`), the latter two
delegating to the first by default. The comment at `:1592-1595` notes these are kept separate
"because historical APIs such as Glide expose Z but no stencil."

---

## 3. CAPABILITIES

`CNA::GraphicsCapability` — `modules/graphics/include/CNA/GraphicsCapability.hpp:14-114`.
**13 flags:**

| Flag | Meaning (per its own doc comment) |
|---|---|
| `ThreeD` | The 3D pipeline as a whole — vertex/index buffers, 3D draws, depth/stencil clears and state |
| `DepthStencilBuffer` | A complete real depth/stencil attachment on the active target |
| `MultiSampleAntiAliasing` | Any sample count above 1 |
| `MultipleRenderTargets` | More than one simultaneous render target |
| `AnisotropicFiltering` | Anisotropic texture filtering (device/driver-dependent on some renderers) |
| `WireFrame` | `RasterizerState.FillMode = FillMode::WireFrame` |
| `OcclusionQuery` | Real GPU occlusion queries |
| `CustomEffects` | A custom (non-stock) `Effect` passed to `SpriteBatch.Begin()` |
| `Texture3D` | Real volume texture **storage** — explicitly *not* a promise of shader sampling |
| `MultiStreamVertexInput` | More than one `VertexBufferBinding` of the same input rate |
| `Instancing` | Hardware instancing |
| `StencilBuffer` | A real stencil plane usable independently of depth |
| `AdditiveBlending` | `BlendState.Additive` uses the documented additive path, not a silent degrade |

### How renderers declare them — and the default-true polarity

Declared by overriding `IGraphicsRenderer::SupportsCapability()` (`:1823-1834`), surfaced publicly
as `GraphicsDevice::SupportsCapability()` (`GraphicsDevice.hpp:1019`).

**The base default returns `true` for everything except `MultiStreamVertexInput`:**

```cpp
:1823  [[nodiscard]] virtual bool SupportsCapability(CNA::GraphicsCapability capability) const
:1825      if (capability == CNA::GraphicsCapability::StencilBuffer)
:1826          return SupportsStencilBuffer();
:1831      if (capability == CNA::GraphicsCapability::MultiStreamVertexInput)
:1832          return false;
:1833      return true;
```

This **opt-out polarity is the root cause of FACTS 5 and 7.** The header itself acknowledges the
hazard at `:1818-1822`: *"Every renderer with a narrower contract … must override the applicable
entries truthfully."* A renderer that forgets, or that overrides wholesale and drops the
`StencilBuffer` delegation at `:1825-1826`, produces a confident wrong answer rather than a
conservative one.

**38 of 42 families override it. Four do not: `directx9`, `directx11`, `directx12`, `sdl-gpu`** —
they inherit "true for all but `MultiStreamVertexInput`".

Three override styles exist, in descending order of safety:

- **Exhaustive `switch`, no `default:` arm** — a `-Wswitch` diagnostic fires when a flag is added.
  Used by SKIA (`SkiaRenderer.cpp:867-897`, whose comment at `:870-872` states this rationale
  explicitly), MAGNUM (`MagnumRenderer.cpp:177-215`), DIRECT2D (`Direct2DRenderer.cpp:326-350`),
  GLIDE (`GlideCapability.hpp:8-31`), METAL (`MetalPolicy.hpp:171-190`).
- **`switch` with `default:`** — silently absorbs new flags. Used by BGFX
  (`BgfxRenderer.cpp:1928+`), DX1–DX8, SOKOL, WICKED.
- **One-line equality test** — `SDL_RENDERER` and `CANVAS` both use
  `return capability == CNA::GraphicsCapability::AdditiveBlending;`.

Some renderers answer from real runtime queries rather than constants, which is the strongest
form: MAGNUM returns `maxMrtTargets_ > 1`, `Mg::GL::Sampler::maxMaxAnisotropy() > 1.0f`,
`Mg::GL::Renderbuffer::maxSamples() > 1`; BGFX returns
`(bgfx::getCaps()->supported & BGFX_CAPS_OCCLUSION_QUERY) != 0`; SOKOL gates both `OcclusionQuery`
and `CustomEffects` on `CNA_SOKOL_HAS_GL_READBACK` — its compile-time backend axis leaking into
the capability answer.

**Notable outliers:** `STUB` returns `false` unconditionally. `OPENVG` returns `false` for all 13.
`LLGL`'s switch (`LlglRenderer.cpp:6313-6366`) has **no `default:` and no cases for
`StencilBuffer`, `Instancing` or `MultiStreamVertexInput`**, so all three fall through to `false`
— intentional and doc-matched (`docs/llgl-renderer.md:28-38`), and a deliberate divergence from
the permissive base.

Two supporting queries round out the system: `GetMaxVertexStreams()` (`:1847`, default
`kMaxVertexStreams` = 16) and `GetMaxTextureDimension()` (`:1860`, default 16384).

---

## 4. VERIFICATION REALITY

### Tier 1 — runs on Linux here, with real pixel verification

`OPENGLES2` / `OPENGLES3` / `OPENGL33` (easygl, 293 CTests), `VULKAN` (211), `BGFX` (179),
`SKIA` (178), `LLGL` (97, GL path only), `SDL_GPU` (83, Vulkan only), `WEBGPU` (80),
`SDL_RENDERER` (80), `SOFTWARE` (60), `HEADLESS` (48), `OPENGL2` (48), `OPENGL1` (38),
`SOKOL` (37, GLCORE only), `DILIGENT` (~63 entries), `OPENGL4` (25), `FREEDIRECT` (21, runs with
`SDL_VIDEODRIVER=dummy` — no display needed), `PORTABLEGL` (12), `FNA3D` (12), `MAGNUM` (8),
`OPENVG` (7), `BLEND2D` (4), `STUB` (1).

Display-dependent tests use `SDL_VIDEODRIVER=x11;DISPLAY=${CNA_TEST_DISPLAY}` and the project-wide
`SKIP_RETURN_CODE 77` convention (`cmake/TestHelpers.cmake:60-70`), so a headless CI reports
SKIPPED rather than FAILED.

Two important qualifications:

- **This is llvmpipe/lavapipe territory, not real GPU silicon**, for most of these.
  `WICKED` runs here, but only on a software Vulkan device.
- **`OPENGLES1` needs a custom ES1-enabled Mesa build** (`scripts/opengles1-test-env.sh`), because
  stock Mesa ships `-Dgles1=disabled`.

### Tier 2 — Wine / Proton, manual invocation

`DIRECTX1`, `DIRECTX2`, `DIRECTX3`, `DIRECTX5`, `DIRECTX6`, `DIRECTX7` (vanilla Wine's builtin
`ddraw.dll` — DXVK does not translate DirectDraw at all); `DIRECTX8` (DXVK/D8VK, dedicated prefix,
`DXVK_FILTER_DEVICE_NAME=llvmpipe`); `DIRECTX9`, `DIRECTX10`, `DIRECTX11` (DXVK); `DIRECTX12`
(vkd3d-proton via `proton run`); `DIRECT2D` (Wine/Proton builtins, explicitly not DXVK).

**Their only always-running CTests are static source-discipline greps** (FACT 14). Real execution
requires manually invoking `scripts/run-wine-directx*.sh` / `run-wine-dxvk*.sh` /
`run-proton-*.sh`.

### Tier 3 — browser

`HTML_DOM` has real Playwright/Chromium CI (`.github/workflows/htmldom-ci.yml`, emsdk + Xvfb).
`SVG_DOM` has `scripts/run-svgdom-browser-test.sh` but no CI job.
`CANVAS`, `WEBGL1` and `WEBGL2` have **no registered automated tests at all**.

### Tier 4 — foreign-OS CI only

`DIRECTX11` / `DIRECTX12` / `DIRECT2D` — `.github/workflows/d3d-windows-ci.yml`, native MSVC on
`windows-latest`, **`workflow_dispatch`-only**.
`GDI` — `.github/workflows/gdi-windows-ci.yml`, native MSVC.
`METAL` — `.github/workflows/metal-macos-ci.yml`, `macos-14`, runs on every push/PR.

**`DIRECTX9` and `DIRECTX10` have no CI job whatsoever** — all their evidence is manual local Wine
runs.

### Tier 5 — never executed as a renderer

`GLIDE` — needs a user-supplied `glide3x.dll`; its one real example is deliberately unregistered
(`glide/examples/CMakeLists.txt:62-63`) and no `run-wine-glide.sh` exists.

**`METAL`'s draw correctness also belongs here.** Its CI runs only `Metal_Smoke` (60 frames of
Clear/Present, explicitly avoiding readback) and `Metal_Capabilities` — **no pixel comparison of a
real draw**. A real 4-check custom-effect pixel test exists at
`modules/renderers/metal/examples/metal_spritebatch_customeffect_test.cpp` but **is referenced by
no CMakeLists — it is dead code.**

### Pixel/oracle diffing — the gold-standard tier is only five renderers wide

`tools/xna-oracle/` holds **39 `.scene` files and 39 checked-in reference PNGs** captured from the
real XNA 4.0 runtime under Wine. Only five renderers build a `cna_oracle_render_*` binary against
it: **`directx9`, `easygl`, `fna3d`, `opengles1`, `skia`.**

**None of BGFX, MAGNUM, LLGL, DILIGENT, SOKOL or WICKED have real-XNA oracle diffing.** Their
pixel verification is entirely self-referential — CNA's own expected-value assertions inside each
renderer's suite, never compared against a real XNA reference image.

And of those five, **only the D3D9 script is a pass/fail gate** (`D3D9_XNA_Diff` CTest, tolerance
0). The EasyGL, OpenGLES1 and FNA3D scripts are **measurements, not gates** — see FACT 12.

### This environment's own history

`cmake-build-debug/CMakeCache.txt` records `CNA_GRAPHICS_RENDERER=OPENGLES3` with a **41-entry**
`STRINGS` list that still contains `ASCII` — i.e. the last configure here predates the 2026-08-11
expansion to 46.

---

## 5. FACTS

**F1. 46 identities, 42 families, mechanically enforced.** `scripts/check_renderer_identities.py`
compares the enum against the CMake `STRINGS` list; running it prints
`OK: 46 public renderer identities preserved in both registries`. `NEXT.md` records the arithmetic:
41 → −1 (ASCII removed) → +6 (`OPENGLES2`, `BLEND2D`, `FNA3D`, `SVG_DOM`, `OPENVG`, `PORTABLEGL`)
= 46, with families 38 → 42. **VERIFIED**

**F2. The gate script's own docstring says 42.** `scripts/check_renderer_identities.py:4`
("CNA has exactly 42 public renderer identities") and `:19` ("42 entries") sit above a 46-entry
table at `:20-67`. Cosmetic — the check compares lists, not the number — but it is the count a
reader would quote. **VERIFIED**

**F3. `EASYGL` is not an accepted selector, and two CI workflows still pass it.** No
`STREQUAL "EASYGL"` branch exists in `cmake/RendererSelection.cmake`; it is absent from the
`STRINGS` list at `:16`; and `docs/renderer-registry.md` states outright that `EASYGL` and `DX30`
"are not accepted selectors or compatibility aliases." It therefore falls through to
`message(FATAL_ERROR "CNA: Unknown graphics renderer: ${CNA_GRAPHICS_RENDERER}")` at `:869`.
Yet `.github/workflows/general-tests-ci.yml:133` — the flagship "full unfiltered CnaTests suite"
job — and `.github/workflows/input-ci.yml:38,44` (matrix entries `EasyGL` and `ASan+UBSan`) all
pass `-DCNA_GRAPHICS_RENDERER=EASYGL`. Both files were touched by the very rename commits
(`57aee5f88`, `8c61cea95`, `ea31cabc1`) that retired the name. **Three of roughly eight CI jobs
would fail at configure time.** **VERIFIED**

**F4. The `WarnAndStub` policy is honoured by only 6 renderers.** `HandleUnsupported3DCall`
call-site counts: `direct2d` 18, `canvas` 17, `freedirect` 17, `openvg` 17, `sdl-renderer` 17,
`blend2d` 6, all others 0. `ShouldStubUnsupported3DResource` appears in only `canvas`,
`freedirect`, `openvg`, `sdl-renderer`. SKIA, HTML_DOM and SVG_DOM use unconditional
`[[noreturn]]` helpers (`SkiaUnsupported3D.hpp:13-16`; `HtmlDomRenderer.cpp:594-597`;
`SvgDomRenderer.cpp:295-298`), making the public policy knob silently inert there. **VERIFIED**

**F5. SDL_GPU and WEBGPU both report `OcclusionQuery == true` while `CreateOcclusionQuery()`
silently returns `nullptr`.** `modules/renderers/sdl-gpu/` contains **zero** occurrences of either
`SupportsCapability` or `OcclusionQuery`, so it inherits both the permissive base default
(`:1823-1834`) and the `nullptr` factory (`:1427`). WEBGPU overrides `SupportsCapability` only to
force `WireFrame=false` and otherwise delegates to the base
(`WebGPURenderer.cpp:6065-6074`: `return IGraphicsRenderer::SupportsCapability(capability);`),
while having zero `CreateOcclusionQuery` occurrences. This is exactly the silent-`nullptr` trap
`GraphicsCapability.hpp:56-58` warns about for `Texture3D`. **VERIFIED**

**F6. The capability test enshrines the wrong expectation rather than catching F5.**
`modules/graphics/tests/Microsoft/Xna/Framework/Graphics/GraphicsDeviceCapabilityTests.cpp`
selects a `kExpectOcclusionQuery` constant per renderer via `#if defined(CNA_RENDERER_*)`, and its
**`#else` fallback sets `true`** — covering SDL_GPU and WEBGPU. `TEST(GraphicsDeviceCapabilityTest,
SupportsOcclusionQuery)` at `:218-221` asserts only that the reported value equals the expectation;
it never checks that `CreateOcclusionQuery()` returns a usable object. The test passes while the
behaviour is wrong. **VERIFIED**

**F7. DIRECTX6/7/8 report `SupportsCapability(StencilBuffer) == false` while shipping real,
pixel-tested stencil.** Each overrides `SupportsCapability` with a switch listing only
`ThreeD` / `DepthStencilBuffer` / `WireFrame` / `AdditiveBlending` (DX8 adds
`AnisotropicFiltering`) plus `default: return false` — **no `StencilBuffer` arm**
(`DirectX6Renderer.hpp:193-205`, `DirectX7Renderer.hpp`, `DirectX8Renderer.hpp:162-169`).
Meanwhile each declares `SupportsDepthStencil() const override { return true; }`
(`DirectX6Renderer.hpp:167`, `DirectX7Renderer.hpp:177`, `DirectX8Renderer.hpp:149`), so the
base's `SupportsStencilBuffer()` returns **true** — and the wholesale override discards the base's
own `StencilBuffer → SupportsStencilBuffer()` delegation at `:1825-1826`. Within one class,
`SupportsStencilBuffer()` says yes and `SupportsCapability(StencilBuffer)` says no. Sources
contain 31 / 31 / 25 stencil render-state references respectively, plus dedicated
`directx{6,7,8}_stencil_test.cpp` pixel tests. **The provenance is proven stale copy-paste:** the
DX6/DX7 comment block still cites `plan_dx2.md`'s Boundaries and `dx2_spike10`, and still describes
the buffer as "depth-only". **VERIFIED (confirmed first-hand)**

**F8. Shaders are never compiled by CNA's build.** Four families each pair authored shader sources
with a dev-time `compile_shaders.py` and a **git-tracked generated byte-array header**: bgfx
(`.sc` → `bgfx_shaders.hpp`, 15,545 lines), vulkan (`.glsl` → `spirv_shaders.hpp`, 3,545 lines,
via ctypes → `libshaderc.so.1`), sdl-gpu (`.glsl` → `spirv_shaders.hpp`, 2,259 lines), sokol
(`.glsl` → sokol-shdc → `sokol_shaders.hpp`, 13,726 lines). D3D9 and D3D11/12 do the same with
offline HLSL bytecode (`hlsl_shaders.hpp`, 38,867 lines). This is why `CNA_BGFX_BUILD_SHADERC` can
default OFF (`:569-571`).
**The exception: MAGNUM is the one renderer with zero offline shader tooling** — its GLSL lives as
raw C++ string literals in `MagnumStockShaders.cpp` (835 lines) and is compiled by the driver at
runtime through `Magnum::GL::Shader`. DILIGENT and WICKED also compile at runtime, but from a
single HLSL source cross-compiled by their middleware. **VERIFIED**

**F9. `OPENGL33` is a genuinely distinct context; `OPENGLES3` and `WEBGL2` are the same code
path.** `EasyGLRenderer.cpp:2830-2841` requests `SDL_GL_CONTEXT_PROFILE_CORE` 3.3 rather than
`PROFILE_ES`; `:531-585` rewrites `#version 300 es` → `#version 330 core`; `:587-611` adds a
core-only `glEnable(GL_PROGRAM_POINT_SIZE)` fix-up. Of 61 `CNA_GL_PROFILE_*` sites, `OPENGLES2`
appears 55×, `WEBGL1` 11×, `OPENGL33` 5×, while **`OPENGLES3` and `WEBGL2` appear only inside
comments** — they are separate identities to name the platform, not the behaviour. **VERIFIED**

**F10. BGFX bakes four shader profiles and cannot use bgfx's D3D or Metal backends.**
`modules/renderers/bgfx/src/shaders/compile_shaders.py:104-113` defines `TARGETS` as exactly
`glsl` (140 / OpenGL), `essl` (300_es / OpenGLES), `spv` (SPIR-V / Vulkan) and `wgsl` (WebGPU) —
108 arrays total (27 shaders × 4). **No DXBC and no Metal blobs exist**; the comment at `:100-103`
explains why: *"Do NOT use BGFX_EMBEDDED_SHADER macro — it activates DXBC on Linux too … which
can't be compiled without D3D4Linux."* So bgfx's D3D11/D3D12/Metal renderer backends, while
enumerable via `CNA_BGFX_RENDERER`, have **no shader content at all** and would fail to draw —
consistent with `BgfxRendererSelection.cpp:31-38` never offering them on Linux. Additionally,
`compile_shaders.py` has **no `--check`/staleness mode** and no CI reference, so a `.sc` edit
without regeneration drifts silently (LLGL's and Sokol's generators both *do* have `--check`).
**VERIFIED**

**F11. Vulkan's and SDL_GPU's SPIR-V are deliberately non-interchangeable.**
`modules/renderers/sdl-gpu/src/shaders/compile_shaders.py:9-13` states SDL_GPU's binding convention
(vertex textures set 0, vertex UBOs set 1, fragment textures set 2, fragment UBOs set 3) is "NOT
the plain Vulkan convention this project's VulkanRenderer shaders use." Two independent SPIR-V
shader sets are maintained. **VERIFIED**

**F12. Oracle diffing exists for five renderers, and is a pass/fail gate for only one.**
`tools/xna-oracle/` holds 39 `.scene` files and 39 reference PNGs; `scripts/run-oracle-corpus-diff.sh`
diffs at `--tolerance 0` and is wired as the `D3D9_XNA_Diff` CTest. Variants exist for easygl,
opengles1 and fna3d, plus `run-skia-2d-oracle-diff.sh`.
`scripts/run-oracle-corpus-diff-fna3d.sh` pins `FNA3D_FORCE_DRIVER=OpenGL`, tallies
`TOTAL/EXACT/DIFFERENT/RENDER_FAILED`, and **its exit code is governed solely by `RENDER_FAILED`**
— a scene that renders but differs from the real-XNA reference is reported, never failed. It is a
**measurement**, gating only on "every scene must at least render." Measured at this commit:
**10/39 exact, 29 differing, 0 render-failed**, byte-identical to the EasyGL baseline on most
scenes and *better* than it on five. The EasyGL and OpenGLES1 scripts state the same
measurement-not-gate rationale in their headers (a fixed-function pipeline cannot match a
programmable one). **VERIFIED**

**F13. The Wine runners are engagement gates — neither pixel comparators nor bare crash checks.**
`scripts/run-wine-directx7.sh` exits 3 if no `trace:ddraw:` line appears in `WINEDEBUG=+ddraw`
output, guarding against a silently-missing DirectDraw producing a false pass.
`run-wine-dxvk*.sh` greps for `DXVK: <version>`; `run-wine-vkd3d.sh` for
`vkd3d-proton - applicationVersion:`. Actual pixel assertions live inside the compiled `.exe`s.
**VERIFIED**

**F14. A fourth verification category exists: static source-discipline greps.**
`scripts/check-directx1-v1-only.sh` strips `//` comments and greps for forbidden symbols
(`IDirectDraw[247]`, `IDirectDrawSurface[234567]`, `DDSURFACEDESC2`, `IDirect3D`, `d3d.h`), with
equivalents for DX2/3/5/6/7 (execute-buffer discipline) and DX8/DX10 (legacy-interface discipline).
Its header describes it as a "pure text check, no compiled binary, no Wine needed." **These are the
only always-running CTests for DIRECTX1–8 and DIRECTX10.** **VERIFIED**

**F15. 1,618 CTest registration call sites across the 42 families**, ranging from easygl 293 /
vulkan 211 / bgfx 179 / skia 178 down to stub 1 and canvas / svg-dom / wicked 0 in-family.
Registration count is not assertion count. **DILIGENT is the sharpest example of why:** its
`cna_register_diligent_test` macro (`modules/renderers/diligent/examples/CMakeLists.txt:47-56`)
registers **two** CTest entries per binary — `<Name>` (device from the preference order, Vulkan
first on Linux) and `<Name>_OpenGL` (`CNA_DILIGENT_DEVICE=opengl` forced) — across 31 binaries,
plus one deliberately non-doubled integration test, for **~63 entries**. The comment at `:41-46`
gives the reason: without it, `ctest -R "^Diligent"` "only ever exercises whichever device type
sorts first … exactly how the OpenGL-specific defects DILIGENT-30/DILIGENT-66 went unnoticed."
This is a real coverage increase, but it is **the same 31 programs run against two APIs, not 62
distinct feature proofs.** **VERIFIED**

**F16. METAL's and GLIDE's test suites run on every renderer configuration and touch neither Metal
nor Glide.** `modules/renderers/CMakeLists.txt:60-65` adds both subdirectories unconditionally
because "their policy suites … are deliberately host-portable and compile into the CnaTests corpus
on every renderer." Their 26 and 14 test files are pure-logic policy tests. **VERIFIED**

**F17. Three identities have effectively no automated rendering verification anywhere.**
GDI: all 17 CTests are wrapped in `if(NOT CMAKE_CROSSCOMPILING)`
(`gdi/examples/CMakeLists.txt:66`), so nothing runs on the Linux host — though
`gdi-windows-ci.yml` runs them on real Windows.
GLIDE: `glide/examples/CMakeLists.txt:62-63` — "This target intentionally has no `add_test()`: it
executes real Glide commands and needs an externally supplied emulator DLL"; no
`run-wine-glide.sh` exists.
CANVAS: test executables are built but deliberately unregistered
(`canvas/examples/CMakeLists.txt:7`). **VERIFIED**

**F18. SVG_DOM's and HTML_DOM's native host-test targets are structurally unreachable.**
`modules/renderers/CMakeLists.txt:88-105` documents that they are only entered via the
selected-renderer dispatch, which requires Emscripten — "no CI/script reference to it exists
anywhere in this repo either." The SVG_DOM host target is additionally behind
`CNA_BUILD_SVG_DOM_HOST_TESTS`, default OFF. **VERIFIED**

**F19. Dependency acquisition is uniform and pinned, with two exceptions.** All fetched
dependencies use `FetchContent` with a pinned SHA or tag plus an optional `CNA_<X>_ROOT` local
override: Corrade `783e4e48` + Magnum `5a742464`, LLGL `Release-v0.04b`, Diligent `v2.5.6`, Sokol
`27b49604`, FNA3D `3240147`, Blend2D `def0d1238c` + AsmJit `b56f4176`, PortableGL `63a55db`,
ShivaVG `6122ccb3`, bgfx.cmake `572868c0`.
**SKIA alone** requires a manually built, externally supplied artifact (`CNA_SKIA_ROOT` +
`CNA_SKIA_BUILD_DIR`, `FATAL_ERROR` if absent). **WEBGPU alone** downloads a prebuilt release
binary (wgpu-native `v29.0.1.1`) over the network at configure time.
SDL3 is a git submodule at `third_party/SDL` pinned to `cbe3fbe9f`.
Three dependencies carry local patches: bgfx (1), ShivaVG (1), Wicked (3).
Two dependencies are **sibling checkouts, not submodules**: `../easy-gl` and `../free-direct`,
each with its own explanatory `FATAL_ERROR`. **VERIFIED**

**F20. Documentation coverage is inversely correlated with maturity.** 42 of 46 identities have a
`docs/<x>-renderer.md`. The four without are **`SDL_RENDERER`, `BGFX`, `VULKAN`, `SDL_GPU`** — the
four oldest and most-tested, documented only via the stale central matrix (plus
`docs/sdl-renderer-2d-completeness.md` and `plan_sdlgpu.md`). BGFX in particular has no dedicated
renderer doc at all; only `.audit.md` files under the stale pre-rename `audit/` tree. **VERIFIED**

**F21. Real Windows/macOS CI exists but is narrow.** `d3d-windows-ci.yml` is
`workflow_dispatch`-only with matrix `[DIRECTX11, DIRECTX12, DIRECT2D]`. `gdi-windows-ci.yml` runs
GDI on native MSVC. `metal-macos-ci.yml` runs on every push/PR but executes only `Metal_Smoke`
(Clear/Present, readback avoided) and `Metal_Capabilities`. **`DIRECTX9` and `DIRECTX10` have no
CI job at all.** **VERIFIED**

**F22. The `dx2-spike/` … `dx10-spike/` directories are checked-in proof records, not build
inputs** (no `add_subdirectory` reference anywhere). `dx2-spike/README.md` is the load-bearing one:
14 ruled-out variants proved DirectX-v1 execute buffers render unconditionally black under this
environment's Wine, while `IDirect3DDevice2::DrawPrimitive` works (real Gouraud interpolation, real
Z-test occlusion, real texture sampling). **This is why DIRECTX2 through DIRECTX8 all use
immediate-mode `DrawPrimitive` rather than the more period-accurate execute-buffer model** —
recorded in `cmake/RendererSelection.cmake:66-74` as an owner-confirmed scope choice. **VERIFIED**

**F23. DIRECT2D uses a materially different delivery model from every other Windows renderer** —
Wine's/Proton's *own builtin* d2d1/d3d11/dxgi, with `CNA_D3D11_SKIP_DXVK_GATE=1` set in every
registration. `scripts/run-proton-direct2d.sh` pins to `Proton 9.0 (Beta)` / `Proton 8.0` and
refuses the moving "Experimental" runtime (`scripts/direct2d-proton-pin.txt`). **VERIFIED**

**F24. Two further silent-failure instances beyond F5.**
LLGL's `SlopeScaleDepthBias` remains **wired and unguarded** at `LlglRenderer.cpp:3029-3034`
while its capability answer is false: a caller who ignores `SupportsCapability` and requests
slope-scale depth bias gets **silently wrong output, not a thrown rejection**
(`known_bugs.md:1493-1504` records the effect as demonstrably inert with no root cause found).
SOKOL's `Texture3D` reports `true` while allocating **no GPU resource at all** — pure CPU storage,
since nothing samples it yet. Both are the same class of defect as F5: a confident capability
answer that outruns the implementation. **VERIFIED**

**F25. WICKED carries a packaging trap.** `libdxcompiler.so` / `dxcompiler.dll` is resolved
**relative to the process's current working directory, not the executable path**
(`docs/wicked-renderer.md:113-118`; `cmake/ThirdPartyWicked.cmake:229-239`). A packaged game must
both ship the library next to the binary *and* be launched from that directory. **VERIFIED**

---

## 6. CONTRADICTIONS

**C1 — The feature matrix says D3D9 has no occlusion query; the code has one.**
*Doc side:* `docs/graphics-renderer-feature-matrix.md:199` — "⬜ **not built at all** …
`CreateOcclusionQuery()` falls through to `IGraphicsRenderer`'s own silent `nullptr` default."
*Code side:* `DirectX9Renderer.cpp:1309-1315` implements it with the official
`CreateQuery(D3DQUERYTYPE_OCCLUSION, nullptr)` support-probe idiom and returns a real
`D3D9OcclusionQueryRenderer`; declared at `DirectX9Renderer.hpp:159`.
*Conclusion:* **the doc is wrong.** A doc claiming absence is as suspect as one claiming
completeness. **VERIFIED**

**C2 — DirectX9's own header comment is stale in the same direction.**
*Comment side:* `DirectX9Renderer.hpp:289-292` — "Every other IGraphicsRenderer virtual (e.g.
CreateOcclusionQuery, CreateTexture3D) … left un-overridden here on purpose."
*Code side:* both are overridden; `CreateOcclusionQuery` at `:159`.
*Conclusion:* stale in-code comment; the design principle it states
("inheriting 'throws' is fine, only inheriting silence is the trap") remains sound and is worth
quoting in the book. **VERIFIED**

**C3 — The feature matrix understates WICKED.**
*Matrix side:* `docs/graphics-renderer-feature-matrix.md:59-65` — "nothing in it has been executed
on real hardware yet. It compiles and links … and its device-independent logic is unit tested;
**that is all**."
*Other-doc side:* `docs/wicked-renderer.md:218-225` (2026-08-05) records that it creates a real
`GraphicsDevice_Vulkan`, compiles all 22 shader entry points at device creation, and passes its
unit suites *plus a 2D demo smoke run* on a software Vulkan device (llvmpipe/lavapipe under Xvfb).
*Conclusion:* both agree it has never touched real GPU silicon; the matrix's "that is all" is
false. **VERIFIED**

**C4 — Two CMake files disagree about where FNA3D's shaders come from.**
*Claim side:* `cmake/RendererSelection.cmake:172-173` — "the stock-effect blobs are **fetched from
the pinned FNA checkout** alongside FNA3D itself (see cmake/ThirdPartyFNA3D.cmake)."
*Code side:* `cmake/ThirdPartyFNA3D.cmake` has exactly **one** `FetchContent_Declare` (FNA3D only,
no FNA), and its own `:23-24` says "modules/renderers/fna3d/effects/ **holds** stock-effect
binaries." The six `.fxb` files are git-tracked with their own `LICENSE.StockEffects`, vendored
from pinned FNA revision `30a427365a1684d6599329560efcfb90233701a9`, and are explicitly not
rebuildable in-repo (compiling `.fx` → `.fxb` needs `fxc` from the DirectX SDK).
*Conclusion:* the `RendererSelection.cmake` comment is wrong. **VERIFIED**

**C5 — A stale `@note` inside the interface header itself.**
*Comment side:* `IGraphicsRenderer.hpp:1646-1647`, on `SetDepthTestEnabled` — "Status: PARTIAL.
**Only the EasyGL renderer honors this**; other renderers throw on first 3D usage."
*Code side:* Vulkan, bgfx, D3D11/12, OpenGL1/2/4, sokol, Diligent, LLGL and others all implement
it; DIRECTX12's own history records fixing a crash caused by these being unimplemented stubs.
*Conclusion:* stale by a wide margin, and it sits in the single most-read file in the graphics
layer. **VERIFIED**

**C6 — `GraphicsCapability.hpp`'s own worked example is stale.**
*Doc side:* `:55-58` — "Headless … and Software's Texture3D … **both currently leave
`IGraphicsRenderer::CreateTexture3D()` at its shared default (returns `nullptr`)**."
*Code side:* Software still does (and honestly reports `Texture3D == false`,
`SoftwareRenderer2DState.cpp:101-106`); **Headless now overrides it**
(`HeadlessRenderer.hpp:577`, implementation `HeadlessRenderer.cpp:579`).
*Conclusion:* half-stale; the surrounding design rationale is still correct and still the clearest
statement of the silent-`nullptr` hazard in the codebase. **VERIFIED**

**C7 — WEBGPU carries a self-contradicting throw string.**
*Code side:* `WebGPURenderer.cpp:7199-7203`'s `ThrowUnsupported3DDraw` says "Clear/present,
Texture2D, SpriteBatch and buffer upload are implemented; see plan_webgpu.md Phase 58+ for 3D
parity."
*Other code side:* the family ships colored / textured / lit / dual-texture / env-map / skinned /
PBR / instanced 3D shaders and 80 CTests.
*Conclusion:* legacy error string; **the code is better than its own error message.** **STRONG**

**C8 — A legacy-analysis doc dismisses renderers that now exist.**
*Doc side:* `docs/directx-legacy-renderers-analysis.md` §5 — "DirectX 1/2/4 — not worth
analyzing."
*Code side:* `DIRECTX1` and `DIRECTX2` are fully implemented, capability-declaring, tested
identities in the same repository.
*Conclusion:* the doc predates the work it dismisses. **VERIFIED**

**C9 — `docs/llgl-renderer.md` contradicts itself, and says so.**
*Top side:* `:3-70` (2026-08-09) — the supported route is OpenGL-only; Vulkan is rejected.
*Lower side:* `:76-90` — still describes "the 2D pipeline, on **both** the Vulkan and the OpenGL
module" as implemented and verified.
*Conclusion:* self-aware, but easy to misread. The doc flags it at `:6-7`: "This section …
supersedes the broader historical implementation diary below wherever the two disagree." The code
agrees with the top section: `LlglRendererSelection.cpp:134-140` **throws** on an explicit
`CNA_LLGL_RENDERER=vulkan` request. **STRONG**

**C10 — Diligent's justification for its own absence from the feature matrix does not hold for the
matrix's grandfathered Bgfx column.**
*Claim side:* `docs/diligent-renderer.md:385-387` — Diligent is "deliberately absent from
`docs/graphics-renderer-feature-matrix.md`: that document's columns mean 'verified on a real
hardware GPU', and everything here was measured on a software Vulkan device."
*Matrix side:* the matrix *does* carry a `Bgfx` column, while its own inline text describes Bgfx's
environment as software — `:200` "⚠️ can't verify in this sandbox's software GL2.1 driver" — and
reserves the explicit real-GPU language for D3D11/D3D12 only (`:14-15`, "verified through
Wine+DXVK/vkd3d-proton on this dev machine's real GPU").
*Conclusion:* the stated bar holds for the D3D11/12 columns and not uniformly for Bgfx, which is
grandfathered into a comparison table whose bar that same document's inline caveats say it does not
clearly meet. **PROBABLE** (authorship intent could not be independently confirmed; the textual
evidence is internally inconsistent).

**C11 — "Skepticism in both directions", stated plainly.** Two docs are *conservative* rather than
optimistic and should be trusted accordingly: `docs/direct2d-release-gate.md:29-33` declares
Direct2D's release gate **BLOCKED** for want of a native-Windows run and a physical-DPI capture,
despite extensive Wine/Proton/MSVC-CI infrastructure and real pixel tests; and
`docs/d3d9-divergence-report.md` claims 36/36 oracle scenes byte-identical *while naming what is
excluded*. Likewise `docs/fna3d-renderer.md`, `docs/sokol-renderer.md` and
`docs/magnum-renderer.md` were each checked against code and found precisely accurate in both
directions (CTest counts of 37 and 8 reproduced exactly by grep; capability tables matching the
`SupportsCapability` switches).
*Conclusion:* **the failure mode in this repository is not renderers over-claiming in their own
docs — it is one central matrix lagging, plus a handful of stale in-code comments.** **STRONG**

---

## 7. BOOK IMPACT

### What the book currently has

Part IV is 10 chapters, `ch16`–`ch25`, covering **11 identities**:

| Chapter | Covers | Status |
|---|---|---|
| `ch16-backend-architecture` | — | Needs full rewrite (see Cluster 0) |
| `ch17-sdl-renderer` | `SDL_RENDERER` | Current |
| `ch18-easygl-backend` | the 5 GL profiles, as "EasyGL" | **Stale name** — `EASYGL` is not a selector (F3); 54 mentions in Part IV |
| `ch19-vulkan-backend` | `VULKAN` | Current |
| `ch20-bgfx-backend` | `BGFX` | Current |
| `ch21-webgpu-backend` | `WEBGPU` | Current |
| `ch22-sdlgpu-backend` | `SDL_GPU` | Current |
| `ch23-direct3d-backends` | `DIRECTX9`, `DIRECTX11`, `DIRECTX12` only (59 `D3D11` / 55 `D3D12` / 35 `D3D9` mentions; zero `DIRECT2D` / `DIRECTX1-8` / `DIRECTX10`) | Covers 3 of the 15 DirectX-lineage identities |
| `ch24-canvas-ascii-backends` | `CANVAS` + `ASCII` | **`ASCII` identity was removed** 2026-08; 59 mentions in Part IV |
| `ch25-dx3-freedirect-backend` | `FREEDIRECT` under its old name | **`DX3` now denotes a different renderer** — the real DirectX 3; 30 mentions |

Part VII adds `ch37-easygl-deep-dive` and `ch38-freedirect-deep-dive`.
`appendix-b-feature-matrix.tex` lists 11 backends — `ASCII`, `BGFX`, `CANVAS`, `D3D11`, `D3D12`,
`D3D9`, `DX3`, `EASYGL`, `SDL_RENDERER`, `VULKAN`, `WEBGPU` — of which **three are stale names**,
and it omits `SDL_GPU` even though `ch22` covers it.

**Net: 11 of 46 identities covered, 3 under names that no longer exist, 35 uncovered.**

### Proposed clustering

Cluster by **what the renderer talks to and how it obtains shaders**, not by age or vendor —
because that is the axis on which CNA's own code actually differs.

| # | Cluster | Identities (count) | Depth | Justification |
|---|---|---|---|---|
| **0** | **The renderer contract** (rewrite `ch16`) | — | **22–28 pp** | The single highest-value new chapter. 70 virtuals / 25 pure; the ten sub-interfaces; the 13 capability flags and their **default-true polarity**; the **three non-equivalent 3D opt-out idioms** and the `WarnAndStub` policy only 6 renderers honour; identity-vs-family (46/42); the checked-in-generated-shader-header pattern and MAGNUM as its one exception. None of this is in the book today. |
| **1** | **The OpenGL family** | `OPENGLES2`, `OPENGLES3`, `OPENGL33`, `WEBGL1`, `WEBGL2`, `OPENGL1`, `OPENGL2`, `OPENGL4`, `OPENGLES1`, `PORTABLEGL` (10) | **30 pp, 2 ch** | **Ch A:** one implementation, five public names — what actually differs (context attributes, shader-header rewriting, ES2 workarounds, capability deltas) and the honest fact that `OPENGLES3` and `WEBGL2` are the same code path (F9). **Ch B:** the independent GL ladder — GL 1.x fixed-function → GLSL 1.10 → GLSL 410 core → ES 1.1 → CPU software GL. The same XNA API across 25 years of OpenGL. Replaces `ch18`. |
| **2** | **Native modern GPU** | `VULKAN`, `SDL_GPU`, `WEBGPU`, `METAL` (4) | **24 pp, 1–2 ch** | Explicit APIs with explicit shader toolchains: the SPIR-V-convention split (F11), SDL_GPU's Vulkan-only reality, and Metal's unusually disciplined disclosure of what is unproven. Extends `ch19`/`ch21`/`ch22`; adds `METAL`. |
| **3** | **Abstraction-layer wrappers** | `BGFX`, `MAGNUM`, `LLGL`, `DILIGENT`, `SOKOL`, `WICKED`, `FNA3D` (7) | **26 pp, 1–2 ch** | *An abstraction inside an abstraction* — the most conceptually interesting cluster and almost entirely uncovered. Compile-time vs runtime backend resolution; SOKOL's second axis (`CNA_SOKOL_API`); patched upstreams; the six distinct shader strategies in one table. **Give FNA3D its own section:** it is the only renderer executing XNA's own shader programs, making it CNA's de-facto reference oracle. Extends `ch20`. |
| **4** | **The legacy DirectX / retro ladder** | `DIRECTX1`, `DIRECTX2`, `DIRECTX3`, `DIRECTX5`, `DIRECTX6`, `DIRECTX7`, `DIRECTX8`, `FREEDIRECT`, `GLIDE` (9) | **30 pp, 2 ch** | **Zero coverage today and the book's most distinctive material.** One modern API projected onto 1995–2000 hardware APIs, with a measured port lineage (DX2→DX3 3.7%, DX5→DX6 6%), a spike-driven methodology, and the execute-buffer finding that shaped seven renderers (F22). Absorbs and corrects `ch25`. |
| **5** | **Modern Direct3D + Windows 2D** | `DIRECTX9`, `DIRECTX10`, `DIRECTX11`, `DIRECTX12`, `DIRECT2D`, `GDI` (6) | **24 pp, 1–2 ch** | D3D9 as the XNA-native, oracle-exact renderer; D3D10's deliberate MVP scope; D3D11/12 sharing `common/d3d`; Direct2D's genuinely different delivery model (F23). Expands `ch23` from 3 identities to 6. |
| **6** | **2D / vector rasterizers** | `SKIA`, `BLEND2D`, `OPENVG`, `SDL_RENDERER` (4) | **16 pp, 1 ch** | "CPU or vector raster presented through an SDL texture." Skia's bounded-contract discipline is the best worked example of honest capability reporting in the repository — its 429-line companion matrix is a model worth teaching. Extends `ch17`. |
| **7** | **Web / DOM** | `CANVAS`, `HTML_DOM`, `SVG_DOM` (3) | **12 pp, 1 ch** | Three different ways to put XNA sprites in a browser *without* WebGL: rasterize into `<canvas>`, CSS-transform pooled `<div>`s, emit real `<svg>`/`<image>` with `feColorMatrix` tint. Replaces `ch24`; drop ASCII and point to `docs/ascii-post-process-effect.md`. |
| **8** | **Non-GPU / diagnostic** | `HEADLESS`, `SOFTWARE`, `STUB` (3) | **12 pp, 1 ch** | `STUB` at 232 lines is the ideal teaching device for Cluster 0's contract — the smallest complete `IGraphicsRenderer`. **Recommend teaching `GDI` here too**, cross-referenced from Cluster 5: `GdiRenderer.cpp:36` literally subclasses `Software::SoftwareRenderer`, so the code sharing is more instructive than the Win32 framing. |

Total: 10 + 4 + 7 + 9 + 6 + 4 + 3 + 3 = **46**.

### Additional recommendations

1. **Rename "backend" → "renderer" book-wide**, matching the project's own 2026-08-10 rename
   (commit `57aee5f88`). The book's Part IV is titled "Backends" and uses the term throughout;
   CNA no longer does.
2. **Retire three stale chapter identities:** `ch18` (`EasyGL` — an internal implementation name,
   not a selector), `ch24` (`ASCII` — identity removed, now
   `CNA::Graphics::AsciiPostProcessEffect` in `modules/graphics-ext/`), `ch25` (`DX3` — the name
   now denotes the *real* DirectX 3 renderer, while the free-direct-backed one is `FREEDIRECT`).
3. **Rebuild Appendix B from `docs/renderer-registry.md`, not from the feature matrix.** The
   registry is current, authoritative and dated to the pin; the matrix is neither. This is the
   single highest-leverage correction available.
4. **Add a verification-tiers appendix** modelled on §4. "Which renderers are actually proven, and
   by what evidence" is the question the current book cannot answer, and it is precisely the
   question a reader choosing a renderer most needs answered. The five-tier model plus the
   oracle-coverage fact (only 5 of 46 renderers diff against real XNA; only 1 of those is a gate)
   is more useful than any feature matrix.
5. **Report FACTS 3, 5, 6, 7 upstream.** The broken `EASYGL` CI selector, the SDL_GPU/WEBGPU
   occlusion-query capability lie plus the test that enshrines it, and the DIRECTX6/7/8
   stencil-capability regression are live code defects, not merely book material.
