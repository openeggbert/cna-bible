# Audit report — graphics core, resources, state objects, effects and shaders

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root.

**Coverage note:** items 1–7 of the brief and the `.fx`/shader question are direct source reads.
Item 8 (per-renderer divergence) is covered by direct reads of the renderer interface plus a
completed per-renderer shader/capability sweep; a third parallel lane on renderer *draw-path*
divergence did not return, so the per-renderer drawing matrix below is thinner than the shader
matrix. That gap is stated explicitly at the end.

---

# FACTS

## A. Architecture and build model

**A1.** Exactly **one** renderer is compiled into any CNA build. `modules/graphics/CMakeLists.txt:22`
links `cna_graphics_core` against `${RENDERER_TARGET}`, a single variable set by renderer selection.
`cmake/RendererSelection.cmake:15-16` declares `CNA_GRAPHICS_RENDERER` as a cache STRING and pins its
`STRINGS` property to **46** accepted public identity values. CNA is **not** runtime-pluggable across
backends; a "renderer" is a compile-time identity. — **VERIFIED**

> *Counting method (corrected).* An earlier pass of this audit reported 47; that was an eye-count of
> the prose list inside the `CACHE STRING` docstring and was wrong. Recounted mechanically:
> extracting every quoted token from the `set_property(... PROPERTY STRINGS ...)` block on
> `cmake/RendererSelection.cmake:16` yields **46 tokens, 46 unique, zero duplicates**; the prose list
> on `:15` independently yields **46** names. Three in-repo sources agree:
> `modules/renderers/CMakeLists.txt:5` ("The 46 public renderer identities"),
> `docs/physical-modules.md:54` ("42 implementation families carry the 46 public renderer
> identities"), and `scripts/check_renderer_identities.py:106` which compares the CMake list against
> a pinned table by sorted set **and** length — a 47-entry STRINGS block would fail that gate.

**A2.** `modules/renderers/` holds **42 implementation families** (directories, excluding `common/`).
The 46 identities map onto them because one family carries several: `docs/physical-modules.md:54-55`
states "the easygl family implements the five GL-profile identities
OPENGLES2/OPENGLES3/OPENGL33/WEBGL1/WEBGL2". 46 − 42 = 4, exactly the four extra identities easygl
carries beyond its own one. The public enum `CNA::GraphicsRendererType`
(`modules/core/include/CNA/GraphicsRendererType.hpp:8`) is the C++ half of the same registry, using
PascalCase enumerators (`SdlRenderer`, `OpenGLES2`, …). Throughout this report, **"renderer" means
family** unless an identity is named explicitly. — **VERIFIED**

**A3.** The graphics core is split into two CMake targets: `cna_graphics_core`
(`modules/graphics/CMakeLists.txt:5`, sources `src/Xna/*.cpp` + `src/Internal/*.cpp`) and
`cna_graphics_ext` (`modules/graphics-ext/CMakeLists.txt:11`, which
`target_link_libraries(... PUBLIC cna_graphics_core)`). graphics-ext is the former `cna_noxna`
library, renamed in the 2026-08 CNAEXT naming normalization
(`modules/graphics-ext/CMakeLists.txt:1-6`). — **VERIFIED**

**A4.** There is a deliberate, documented static-archive cycle: `cna_graphics_core` links `cna_input`
PRIVATE and `${RENDERER_TARGET}` PRIVATE, while renderers link back
(`modules/graphics/CMakeLists.txt:12-23`, with the rationale spelled out in the comments). — **VERIFIED**

**A5.** **CNA's vertex structures are not blittable, unlike XNA's.** `Color` implements
`IPackedVector` and most vertex types implement `IVertexType`; both are polymorphic C++ bases, so a
vertex object carries a vtable pointer.
`modules/graphics/include/CNA/Internal/Graphics/BuiltInVertexStreams.hpp:17-28` states this
explicitly. A parallel "stream" struct layer is therefore the single source of truth for GPU bytes:
`PositionColorStream` (16 B), `PositionTextureStream` (20 B), `PositionColorTextureStream` (24 B),
`PositionNormalTextureStream` (32 B), `PositionNormalTextureSkinnedStream` (52 B),
`PositionNormalTangentTextureStream` (48 B), `PositionNormalTangentTextureSkinnedStream` (68 B) —
each with `static_assert`ed size and member offsets (`BuiltInVertexStreams.hpp:32-119`). Every
`VertexDeclaration` takes its stride from `sizeof(stream)` and its offsets from
`offsetof(stream, member)`. — **VERIFIED**

**A6.** Consequence of A5, visible in the public API: `GraphicsDevice::GetBackBufferData` cannot write
into a `Color*` directly. It reads into a `std::vector<uint8_t>` and reconstructs each
`Color(r,g,b,a)` (`modules/graphics/src/Xna/GraphicsDevice.cpp:2854-2864`, with the vtable rationale
in the comment). `Texture3D.cpp:107-119` (`colorsToRgba`) does the same, noting
`sizeof(Color) == 24`. — **VERIFIED**

---

## B. GraphicsDevice

**B1.** `GraphicsDevice` is `public System::Object, public System::IDisposable`; copy and move are all
`= delete` (`GraphicsDevice.hpp:69`, `:103-106`). Two public constructors: default (headless-ish,
delegates with `GraphicsProfile::Reach` + default `PresentationParameters`,
`GraphicsDevice.cpp:273-280`) and
`(GraphicsAdapter&, GraphicsProfile, const PresentationParameters&)` (`:282`). — **VERIFIED**

**B2.** Construction order is: `SDL_InitSubSystem(SDL_INIT_VIDEO)` (guarded) →
`createOrAttachWindow()` → `applyPresentationParametersToWindow()` → `createRenderer()` →
`UpdateViewportFromWindow()` → push the three default state objects to the renderer
(`GraphicsDevice.cpp:317-355`). The default-state push (`setBlendStateProperty` /
`setDepthStencilStateProperty` / `setRasterizerStateProperty`) mirrors FNA's own constructor and was
added by Tasks 896/955. Notably `setDepthStencilStateProperty` is **conditional** on
`renderer_->SupportsDepthStencil()` (`:353-354`). — **VERIFIED**

**B3.** **SDL subsystem init/quit is asymmetric.** Init is skipped entirely for
`CNA_RENDERER_HEADLESS`/`SOFTWARE`/`STUB`/`PORTABLEGL` and for
`PresentationParameters.HeadlessEXT` (`GraphicsDevice.cpp:317-329`), but `Dispose()` calls
`SDL_QuitSubSystem(SDL_INIT_VIDEO)` **unconditionally** (`:682`). — **VERIFIED**

**B4.** **Disposal ordering is explicit and correct.** `Dispose()` moves the tracked-resource list
out, clears it, then disposes each resource *before* `destroyNativeResources()` tears down the
renderer (`GraphicsDevice.cpp:671-683`). The move-then-clear makes `RemoveResourceReference` a
re-entrant no-op, matching FNA. `destroyNativeResources()` resets `renderer_` first, then clears
shared `TextInputEXT`/`Mouse` window handles, then `SDL_DestroyWindow` only if `ownsWindow_`
(`:2441-2465`). — **VERIFIED**

**B5.** Resource tracking is a plain `std::vector<GraphicsResource*> resources_`
(`GraphicsDevice.hpp:1153`) with unordered swap-removal (`GraphicsDevice.cpp:705-714`) — O(n)
removal, O(1) after the match. Registration happens in `GraphicsResource`'s constructor
(`GraphicsResource.cpp:10-15`), deregistration in `Dispose(bool)` (`:94-98`).
`GetTrackedResourceCount()` is exposed for debug/test (`GraphicsDevice.hpp:942`). — **VERIFIED**

**B6.** Six public events: `Disposing`, `DeviceLost`, `DeviceReset`, `DeviceResetting`,
`ResourceCreated`, `ResourceDestroyed` (`GraphicsDevice.hpp:74-84`). — **VERIFIED**

**B7.** **Device-loss is real on exactly one renderer.** `deviceStatus_` is driven by a
`deviceEventCallback` lambda installed at renderer creation (`GraphicsDevice.cpp:2400-2417`), mapping
`RendererDeviceEvent::Lost/Resetting/Reset` to `GraphicsDeviceStatus::Lost/NotReset/Normal` and
raising the matching public event. The header states "Every renderer except D3D9 never calls that
callback, so this stays Normal there" (`GraphicsDevice.hpp:1131-1135`, echoed at
`GraphicsDevice.cpp:2642-2646`). `DeviceLost` is documented as "never raised on desktop"
(`GraphicsDevice.hpp:75`). — **VERIFIED**

**B8.** **`Reset()` is not a real device reset.** It raises `DeviceResetting`, normalizes formats,
stores new `PresentationParameters`, resizes the window, forwards
`SetVirtualResolution`/`ApplyMultiSampleCount`/`SetSwapInterval`/`UpdatePresentationFormatEXT`,
updates the viewport, and raises `DeviceReset` (`GraphicsDevice.cpp:570-662`). It never recreates the
renderer or reallocates GPU resources. The header for `RecreateRendererForMultiSampleCount` states
plainly that "real mid-game device reset/recreation (FNA's `GraphicsDevice.Reset`) is a separate,
not-yet-implemented feature" (`GraphicsDevice.hpp:1090-1094`). — **VERIFIED**

**B9.** `Reset()` has a **transactional rollback**: if window resize or `SetVirtualResolution` throws,
all presentation bookkeeping (parameters, adapter, virtual size, TouchPanel metrics) is restored and
the original exception rethrown (`GraphicsDevice.cpp:596-631`, REMED-GFX-029). A secondary failure
during rollback is swallowed via `SDL_ClearError()` so the precise original diagnostic survives. — **VERIFIED**

**B10.** Four `Clear` overloads (`GraphicsDevice.hpp:220`, `:228`, `:236`, `:242`). `Clear(Color)`
clears **Target | DepthBuffer | Stencil** using the device's *current* `Viewport.MaxDepth` — not a
hardcoded 1.0 (`GraphicsDevice.cpp:415-425`, Task 928, matching FNA literally). XNA's
`Clear(ClearOptions, Vector4, float, int)` overload does **not** exist. — **VERIFIED**

**B11.** **`Clear` silently masks unsupported aspects.** `ClearOptions::DepthBuffer` is stripped when
no real depth buffer exists, `Stencil` when no real stencil plane exists — asked *independently*
(GDI-050), and asked of the *bound render target* when one is bound, of the renderer otherwise
(`GraphicsDevice.cpp:456-504`). A depth-only or stencil-only clear on an unsupporting target
therefore becomes a **silent no-op**: nothing dispatches (`:518-545`). Depth outside `[0,1]` throws
`ArgumentOutOfRangeException` *before* masking (`:442-448`). Dispatch is a 7-way fan-out to
`ClearColorDepthAndStencil` / `ClearColorAndDepth` / `ClearColorAndStencil` / `ClearDepthAndStencil` /
`Clear` / `ClearDepth` / `ClearStencil`. — **VERIFIED**

**B12.** `Present()` throws `InvalidOperationException("Cannot present while render targets are
bound")` (`GraphicsDevice.cpp:555-556`), then calls `renderer_->Present()` and re-derives the viewport
from the window (`:558-562`). XNA's `Present(Rectangle?, Rectangle?, IntPtr)` overload does not
exist. — **VERIFIED**

**B13.** **`GetBackBufferData` sizes from `PresentationParameters`, never the live viewport**
(REMED-GFX-165, `GraphicsDevice.cpp:2802-2813`). A rectangle is bounds-checked against the real
backbuffer before any native copy (`:2822-2827`); `elementCount < w*h` throws (`:2850-2851`);
`Texture::ValidateGetDataFormat(backBufferFormat, 4)` gates the element size (`:2852`). There is an
env-var trace hook, `CNA_BACKBUFFER_READ_TRACE` (`:2837-2848`). Three overloads, all funnelling into
the rect version (`:2787-2797`). — **VERIFIED**

**B14.** **Render targets.** `MAX_RENDERTARGET_BINDINGS = 4` (`GraphicsDevice.cpp:83`, matching FNA).
`SetRenderTarget(RenderTarget2D*)` and `SetRenderTarget(RenderTargetCube*, CubeMapFace)` are both thin
wrappers over `SetRenderTargets()` — a deliberate consolidation that closed a real bypass where a
renderer without RT support silently rendered to the backbuffer (`:2873-2914`,
REMED-GFX-PGL-AUDIT; this is the fix in commit `913d39e66`, 2026-08-11). `SetRenderTargets` normalizes
each public binding into a `RenderTargetBindingDescriptor`, rejects null/disposed targets, rejects
`arraySlice != 0`, rejects a renderer with no RT support (`NotSupportedException`), validates cube-face
range, and enforces matching dimensions + matching *applied* sample counts + no duplicate subresource
across slots (`:2916-3029`). D3D9 additionally enforces `GraphicsProfile.Reach`'s MaxRenderTargets=1
(`:2922-2939`). — **VERIFIED**

**B15.** Every `SetRenderTarget*` call **resets Viewport and ScissorRectangle** to the first bound
target's size (or the backbuffer's, when unbinding) — matching FNA; a game's previously-set viewport
never survives a target switch (`GraphicsDevice.cpp:2867-2871`, `:3038-3040`, `:2949-2950`;
documented at `GraphicsDevice.hpp:1249-1259`). `RenderTargetUsage::DiscardContents` triggers exactly
one `Clear` with independently-derived depth/stencil flags (`:3041-3063`). — **VERIFIED**

**B16.** **Vertex/index binding.** `SetVertexBuffer(vb)` / `SetVertexBuffer(vb, vertexOffset)` clear
the binding list and install a single binding (`GraphicsDevice.cpp:3071-3084`);
`SetVertexBuffers(vector)` caps at **16** (XNA4 HiDef limit) and permits null-buffer bindings as legal
unused slots (`:3086-3102`). `SetIndexBuffer`/`setIndicesProperty`/`Indices(...)` are three names for
one operation, all throwing `ObjectDisposedException` on a disposed buffer (`:742-747`, `:405-408`,
`:764-767`). — **VERIFIED**

**B17.** **Draw-call preconditions are uniform and strict.** Every 3D draw calls
`renderer_->Ensure3DSupported("...")` first (`GraphicsDevice.cpp:1073`, `:1145`, `:1235`), then
requires a bound vertex buffer, index buffer (indexed routes), and — critically — a **currently
applied Effect**, throwing `std::runtime_error("... no effect has been applied.")` otherwise
(`:1076-1079`, `:1148-1154`, `:1237-1247`, and on every `DrawUser*` overload, e.g. `:1342`, `:1394`,
`:1572`, `:2090`). Note the exception type: plain `std::runtime_error`, not an XNA-shaped
exception. — **VERIFIED**

**B18.** **Range validation precedes capability validation, deliberately** — "an out-of-range request
is wrong on every renderer, so it must report the same public exception everywhere"
(`GraphicsDevice.cpp:1120-1125`). `DrawPrimitives` rejects a range leaving the bound buffer
(REMED-GFX-113/200, `:1084-1100`); `DrawIndexedPrimitives` rejects both an index range leaving the
index buffer and a declared vertex range leaving the vertex buffer (`:1162-1185`). — **VERIFIED**

**B19.** **Multi-stream vertex input is a gated capability.** `ValidateVertexStreamCapability` throws
`NotSupportedException` naming `GraphicsCapability::MultiStreamVertexInput` when more than one
per-vertex stream, more than one per-instance stream, or more streams than the renderer's native slot
ceiling are bound (`GraphicsDevice.cpp:977-1013`, `:989-1007`). The classic shapes — one per-vertex
stream, or one per-vertex plus one per-instance — never reach these checks
(`GraphicsDevice.hpp:1191-1199`). — **VERIFIED**

**B20.** The `VertexBufferBinding.VertexOffset` fold (REMED-GFX-200/201) is subtle and worth a book
box: the *smallest* offset among per-vertex streams is folded into `vertexStart`/`baseVertex` (the
element-unit channel every renderer already multiplies by the stream's own stride exactly once), and
each stream carries the non-negative remainder (`GraphicsDevice.cpp:831-849`, `:1106-1119`,
`:1192-1206`; rationale at `GraphicsDevice.hpp:1170-1178`). With one stream this is byte-identical to
the pre-REMED behaviour. — **VERIFIED**

**B21.** **Occlusion queries** are a thin forward. `OcclusionQuery(device)` constructs via
`device.GetRenderer().CreateOcclusionQuery()` (`OcclusionQuery.cpp:8-12`).
`Begin`/`End`/`getIsCompleteProperty`/`getPixelCountProperty` all **null-guard and silently degrade**
— a renderer with no query support yields `IsComplete == false` and `PixelCount == 0` forever, with no
exception (`OcclusionQuery.cpp:22-41`). `Dispose(bool)` resets the renderer *before* the base marks
the resource disposed, so the native handle dies before GL/device teardown (`:16-20`, plan_sokol
SOKOL-42). The header documents that on OpenGL ES 3.0 `PixelCount` is 0-or-1, not a real count
(`OcclusionQuery.hpp:40-42`). — **VERIFIED**

**B22.** **`GraphicsDevice.Textures[]` / `VertexTextures[]` are bookkeeping only — they never reach
the GPU.** `applySamplerStatesToRenderer()` forwards *sampler* state for 16 slots but no textures
(`GraphicsDevice.cpp:2573-2587`), and nothing else reads `textures_`. Grepping all non-test call sites
of `getTexturesProperty()` finds only `Texture::Dispose` unbinding itself (`Texture.cpp:132-133`).
`TextureCollection` does enforce real invariants — out-of-range throws, disposed textures throw
`ObjectDisposedException`, and a texture currently bound as a render target throws
`InvalidOperationException` (`TextureCollection.cpp:24-56`) — but a texture placed in a slot has no
rendering effect. Textures reach the GPU only via `Effect::FillGpuDrawParams`
(`p.texture0`/`texture1`/`envMap`) or `ShaderEffect::SetTexture(unit, tex)`. — **VERIFIED**

**B23.** `TextureCollection` uses `operator()(int, Texture*)` as its setter, not `operator[]=`
(`TextureCollection.hpp:29`, `TextureCollection.cpp:32`) — an unavoidable C++ shape change from XNA's
`device.Textures[i] = tex`. `MaxTextures = MaxSamplers = 16` (`TextureCollection.hpp:16`,
`SamplerStateCollection.hpp:15`). `SamplerStateCollection` defaults every slot to
`SamplerState::LinearWrap` (`SamplerStateCollection.cpp:9-10`). — **VERIFIED**

**B24.** **Dead / partially-wired device properties:**

- `GraphicsDevice.MultiSampleMask` setter is a pure field write with no renderer call
  (`GraphicsDevice.cpp:2764-2765`). (`BlendState.MultiSampleMask` *is* forwarded, via
  `BlendWriteState::multiSampleMask`, `:2678`.)
- `RasterizerState.MultiSampleAntiAlias` never reaches a renderer:
  `IGraphicsRenderer::ApplyRasterizerState` takes only
  `cullMode, fillMode, scissorTestEnable, depthBias, slopeScaleDepthBias`
  (`IGraphicsRenderer.hpp:1536-1539`); `setRasterizerStateProperty` passes exactly those five
  (`GraphicsDevice.cpp:2732-2742`). This is acknowledged in-tree at
  `modules/renderers/directx11/src/D3D11StateObjectCache.cpp:164`.
- `SamplerState.AddressW` is never forwarded — `ApplySamplerState` takes only
  filter/U/V/maxAnisotropy (`IGraphicsRenderer.hpp:1546-1549`; call site
  `GraphicsDevice.cpp:2579-2583`). `MaxMipLevel` and `MipMapLevelOfDetailBias` *are*, via the separate
  `ApplySamplerMipState` (`:2584-2585`). — **VERIFIED**

**B25.** State setters **commit the public cache only after the native call succeeds** — a deliberate
pattern so a rejected D3D9 update never leaves CNA claiming state that was not installed
(`GraphicsDevice.cpp:394-397` viewport, `:2693-2697` blend, `:2724-2727` depth-stencil, `:2772-2775`
reference stencil). `setRasterizerStateProperty` and `setScissorRectangleProperty` follow the same
shape (`:2741`, `:2749`). — **VERIFIED**

**B26.** CNAEXT device extensions beyond XNA: `PrimitiveVerts`, `OnResourceCreated`/`OnResourceDestroyed`,
`AddResourceReference`/`RemoveResourceReference`/`GetTrackedResourceCount`,
`SetDepthTestEnabled`/`SetBlendEnabled`/`SetDepthWriteEnabled`, `SetGraphicsProfileEXT`,
`SetContextRecoveryEnabled`, `SetStringMarkerEXT`, `GetRenderer`,
`GetGraphicsRendererType`/`GetGraphicsRendererName` (both `constexpr`), `SupportsCapability`,
`GetMaxTextureDimension`, `SetUnsupported3DGraphicsCallBehavior`/`GetUnsupported3DGraphicsCallBehavior`,
`SetCurrentEffect`, `SetPresentationParameters`, `RecreateRendererForMultiSampleCount`
(`GraphicsDevice.hpp:899-1102`). `SetStringMarkerEXT` is real only on Vulkan with
`VK_EXT_debug_utils`; a no-op elsewhere (`:974-983`). — **VERIFIED**

---

## C. Graphics resources

**C1.** `GraphicsResource : System::Object, System::IDisposable` (`GraphicsResource.hpp:18`). **Copy is
permitted and carries identity but resets lifecycle** — device/name/tag are copied, `isDisposed_` is
forced false, and `Disposing` handlers are deliberately *not* copied (`GraphicsResource.hpp:67-72`,
`GraphicsResource.cpp:17-37`). Move is `= default` (`:74-75`). The destructor calls `Dispose(false)`
(`:39-42`). — **VERIFIED**

**C2.** **A copied `GraphicsResource` is never registered with the device.** The copy constructor sets
`graphicsDevice_` but does not call `AddResourceReference` (contrast the normal constructor,
`GraphicsResource.cpp:10-15` vs `:17-24`). Its `Dispose` will nonetheless call
`RemoveResourceReference` (`:97`), which is a harmless no-op for an unregistered pointer. Practical
effect: copies are untracked by `GetTrackedResourceCount()` and are not disposed by
`GraphicsDevice::Dispose()`. — **VERIFIED**

**C3.** **Ownership/copy semantics vary sharply by resource type** — this is a genuine API-fidelity
story:

| Type | Copy | Move |
|---|---|---|
| `Texture2D` | `= default` (both) — `Texture2D.hpp:97-98` | `= default` noexcept — `:99-100` |
| `Texture3D` | not declared (implicitly suppressed by move) | explicit noexcept — `Texture3D.hpp:60-62` |
| `TextureCube` | — | — (see C4) |
| `VertexBuffer` | `= delete` — `VertexBuffer.hpp:69-71` | explicit noexcept — `:73-75` |
| `IndexBuffer` | `= delete` — `IndexBuffer.hpp` | explicit noexcept — `:56-58` |
| `RenderTarget2D` | `= delete` — `RenderTarget2D.hpp:64-65` | `= default` — `:66-67` |
| `Effect` | `= delete` both — `Effect.hpp:54-57` | — |
| `GraphicsDevice` | `= delete` all four — `GraphicsDevice.hpp:103-106` | |

`Texture2D` being freely copyable (sharing a `shared_ptr<ITextureRenderer>`) is the outlier, and is
what lets `SpriteFont` hold one **by value** (`SpriteFont.hpp:117`) and `Texture2D::FromStream` return
by value (`:416`). — **VERIFIED**

**C4.** `Texture2D` holds `std::shared_ptr<ITextureRenderer> renderer_`,
`std::shared_ptr<std::vector<uint8_t>> cpuPixels_`, and
`std::shared_ptr<std::vector<std::vector<uint8_t>>> extraMipLevels_` (`Texture2D.hpp:588-592`). The CPU
shadow exists for GL context-loss recovery and is freed when recovery is disabled
(`MaybeFreeCpuPixels`, `:609`; `GraphicsDevice::SetContextRecoveryEnabled` documents "saves
approximately one copy of texture RAM per loaded texture", `GraphicsDevice.hpp:964-972`). — **VERIFIED**

**C5.** `Texture2D::gpuOnlyContent_` marks a real `RenderTarget2D` whose pixels come only from GPU
rendering, so an empty CPU shadow means "ask the renderer" rather than "the shadow was freed".
`ReconstructFromCache()` borrows the same protected constructor but **clears** the flag, because a
cache hit is an ordinary content texture (`Texture2D.hpp:594-606`, REMED-GFX-223). — **VERIFIED**

**C6.** **A partial `SetData` on level 0 with a freed CPU shadow throws** rather than silently
corrupting already-uploaded pixels outside the rect (`Texture2D.hpp:132-136`; enforcement
`Texture2D.cpp:482`). — **VERIFIED**

**C7.** **`SurfaceFormat` (27 values, complete enum),** `SurfaceFormat.hpp:7-63`:
`Color, Bgr565, Bgra5551, Bgra4444, Dxt1, Dxt3, Dxt5, NormalizedByte2, NormalizedByte4, Rgba1010102,
Rg32, Rgba64, Alpha8, Single, Vector2, Vector4, HalfSingle, HalfVector2, HalfVector4, HdrBlendable,
ColorBgraEXT, ColorSrgbEXT, Dxt5SrgbEXT, Bc7EXT, Bc7SrgbEXT, ByteEXT, UShortEXT`.
The last seven are CNAEXT (not XNA 4.0); XNA's 20 are the first twenty. — **VERIFIED**

**C8.** **★ The `SurfaceFormat` enum is almost entirely decorative on every renderer except Skia.**
`Texture::ValidateFormat` accepts **only `SurfaceFormat::Color`** and throws
`std::runtime_error("Texture: SurfaceFormat N is not implemented by the selected graphics renderer")`
for everything else (`Texture.cpp:109-116`). Its callers are `Texture3D.cpp:83`, `TextureCube.cpp:68`
and `:85`, `RenderTarget2D.cpp:78`, and `Texture2D.cpp:130` (via `ValidateTexture2DFormatEXT`'s
`#else` branch). Only the `CNA_RENDERER_SKIA` build swaps in a 27-entry allow-list for `Texture2D`
(`Texture2D.cpp:95-131`) and a 14-entry renderable-format list for `RenderTarget2D`
(`RenderTarget2D.cpp:42-62`). So on a D3D11/Vulkan/EasyGL/bgfx/… build,
`Texture2D(device, w, h, false, SurfaceFormat::Dxt5)` **throws**, and `Texture3D`/`TextureCube` support
`Color` and nothing else on *every* renderer including Skia. — **VERIFIED**

**C9.** **Compressed textures are CPU-decompressed to RGBA8 before ever reaching the GPU** (except on
Skia). `DxtUtil::DecompressDxt1/3/5` is called from the XNB readers —
`modules/content/src/Xnb/Texture2DContentTypeReader.cpp:198,202,206`,
`TextureCubeContentTypeReader.cpp:88,91,94`, `Texture3DContentTypeReader.cpp:104,107,110` — and from
`modules/renderers/skia/src/SkiaTextureRenderer.cpp:95` (the only renderer-side consumer, which also
uses `Bc7Util`). `DxtUtil.cpp` is 337 lines, `Bc7Util.cpp` 474.
`modules/graphics/examples/dxt1_texture_test.cpp:1-8` confirms the DDS-through-`FromStream` route is a
decode path, not a native-compressed upload. — **VERIFIED**

**C10.** Block-format metadata is centralized: `Texture::GetBlockSizeSquaredEXT` returns 16 for
`Dxt1/3/5`, `Dxt5SrgbEXT`, `Bc7EXT`, `Bc7SrgbEXT` and 1 for the 21 uncompressed formats, throwing
`std::out_of_range` on an invalid enum value (`Texture.cpp:15-51`). `GetFormatSizeEXT` returns 8 for
Dxt1, 16 for Dxt3/Dxt5/Dxt5Srgb/Bc7/Bc7Srgb and Vector4, 1/2/4/8 for the rest (`:53-94`).
`GetPixelStoreAlignment` = `min(8, GetFormatSizeEXT(f))`, matching the OpenGL 2.1 cap (`:96-99`).
`ValidateGetDataFormat` throws `std::invalid_argument` when the destination element size does not
evenly divide the format size (`:101-107`). — **VERIFIED**

**C11.** `Texture2D` allocates block-compressed levels as
`ceil(w/4) * ceil(h/4) * GetFormatSizeEXT(format)` bytes, uncompressed as
`w * h * GetFormatSizeEXT(format)` (`Texture2D.cpp:317-331`). Mip chains use `CalculateMipLevels(w,h)`
= repeated halving until 1×1 (`:292-296`); `RenderTarget2D.cpp:17-21` and
`TextureCube`/`RenderTargetCube.cpp:15-20` carry mirrored copies of the same helper. — **VERIFIED**

**C12.** **`Texture2D::SetData`/`GetData` is an enormous typed-overload family** (2716 lines of
`Texture2D.cpp`). Both come in a `(data, count)` short form and a
`(level, rect, data, startIndex, count)` full form, specialised for: `Color`, 12 `PackedVector` types
(`Bgr565, Bgra4444, Bgra5551, Rgba1010102, Alpha8, Rg32, Rgba64, NormalizedByte2, NormalizedByte4,
HalfSingle, HalfVector2, HalfVector4`), `float`, `Vector2`, `Vector4`, `uint8_t` (CNAEXT — also the
compressed-block route), and `uint16_t` (CNAEXT). Plus `nullptr_t` shims to preserve legacy overload
resolution (`Texture2D.hpp:231-241`, `:393-408`). Each typed overload validates that the texture's
format matches, e.g. `"Bgr565 data requires Bgr565 format"` (`Texture2D.cpp:981`). — **VERIFIED**

**C13.** For a compressed format there is **no CPU mirror**: `SetCompressedDataBytes` reads back,
patches, and re-uploads through the renderer on every call, because compressed storage cannot be
sliced by texel row (`Texture2D.hpp:629-636`). Rect coordinates are texel-space and must be
block-aligned or reach the level's edge; `elementCount` is the exact padded block byte count
(`:217-224`). — **VERIFIED**

**C14.** Texture creation is gated on **three** independent checks: D3D9 profile size ceiling
(`ValidateTextureSizeForProfileEXT`, D3D9-only), the renderer's real max dimension
(`ValidateTextureDimensionEXT` → `device.GetMaxTextureDimension()`, default 16384 per
`IGraphicsRenderer.hpp:1860-1863`), and format (`ValidateTexture2DFormatEXT`) — in that order
(`Texture2D.cpp:301-306`). Over-size throws `NotSupportedException` (`:89`, REMED-CONTENT-001). — **VERIFIED**

**C15.** `Texture2D` CNAEXT extras: `FromStream(device, stream)` and
`FromStream(device, stream, w, h, zoom)` (fit vs scale-and-crop), `SaveAsPng`/`SaveAsJpeg` (stream and
filename forms), `SetDataRGBA`, `CreateFromPixels`, `CreateCpuOnlyForTests`,
`CreateWithRendererForTests`, `ReconstructFromCache`,
`GetRenderer`/`GetRendererWeak`/`GetCpuPixelsWeak`/`HasRenderer` (`Texture2D.hpp:410-585`). — **VERIFIED**

**C16.** **`Texture3D` refuses construction outright when unsupported.** It throws
`NotSupportedException("Texture3D: this renderer does not support real volume (3D) texture storage")`
if `SupportsCapability(GraphicsCapability::Texture3D)` is false — checked *before* renderer creation
(`Texture3D.cpp:76-80`, REMED-CONTENT-004). Previously a null renderer let `SetData`/`GetData`
silently no-op. Headless and Software both report false by design. — **VERIFIED**

**C17.** `TextureCube` exposes `getSizeProperty()`, face-indexed `SetData`/`GetData(CubeMapFace, ...)`,
and a CNAEXT `DDSFromStreamEXT(device, stream)` (`TextureCube.hpp:55`, `:66-121`, `:158`). `Texture3D`
exposes `getWidth/Height/DepthProperty` and `Color`-only transfer (`Texture3D.hpp:68-159`). — **VERIFIED**

**C18.** **`RenderTarget2D` construction never fails on an unsupporting renderer.**
`CreateValidatedRenderTargetRenderer` may return nullptr and construction succeeds anyway; every
operation that needs real storage (`SetData`/`GetData`, `SetRenderTargets`' bind path) checks and
throws `NotSupportedException` at its own point of use — the same "null-object" convention
`Texture3D`/`TextureCube` use (`RenderTarget2D.cpp:77-87`). MSAA counts round *down* to the nearest
power of two, with 1 → 0, via `ClosestMSAAPower` mirroring FNA's `MathHelper.ClosestMSAAPower`
(`:23-36`). `RenderTargetCube` carries an identical copy (`RenderTargetCube.cpp:23-36`). — **VERIFIED**

**C19.** `RenderTargetCube` derives from `TextureCube` **and** `IRenderTarget`, sharing one GPU image
between sampling and rendering (`RenderTargetCube.cpp:38-67`). Its `MultiSampleCount` is re-read from
the renderer after construction, reflecting the device-clamped value rather than the requested one
(`:64-66`, matching FNA's `FNA3D_GetMaxMultiSampleCount`). `RenderTarget2D` does the same. — **VERIFIED**

**C20.** **Disposing a bound render target throws.** Both `RenderTarget2D::Dispose(bool)` and
`RenderTargetCube::Dispose(bool)` scan `GetRenderTargets()` and throw `InvalidOperationException` if
still bound (`RenderTargetCube.cpp:72-81`; `RenderTarget2D.hpp:53-62` documents the same). — **VERIFIED**

**C21.** `getIsContentLostProperty()` **returns a hardcoded `false`** on `RenderTarget2D` (`:89`),
`RenderTargetCube` (`:69`), `DynamicVertexBuffer` (`:31`), and `DynamicIndexBuffer` (`:32`), and the
matching `ContentLost` events are documented as "never raised in CNA". — **VERIFIED**

**C22.** `DynamicVertexBuffer`/`DynamicIndexBuffer` add **nothing** but `getIsContentLostProperty`, a
`ContentLost` event, and `SetData(..., SetDataOptions)` overloads forwarding to protected
`SetDataWithOptions` (`DynamicVertexBuffer.hpp:12-119`, `DynamicIndexBuffer.hpp:12-79`). Their own doc
comments state honestly that "Most CNA renderers honor `options` as a real GPU mapping hint …; a few
still ignore it and always behave like `Discard`", and — importantly — **"the destination write always
starts at the buffer's own beginning; `startIndex` only selects where reading from `data` begins."**
That is a real deviation from XNA, where `offsetInBytes` addresses the destination. — **VERIFIED**

**C23.** `VertexBuffer` typed transfer covers seven vertex types (`VertexPositionColor`,
`…ColorTexture`, `…NormalTexture`, `…Texture`, plus CNAEXT `…NormalTextureSkinned`,
`…NormalTangentTexture`, `…NormalTangentTextureSkinned`), each with `(data,count)` and
`(data,startIndex,elementCount)` forms for both `SetData` and `GetData`, plus a CNAEXT
`SetDataRaw(const void*, count, stride)` (`VertexBuffer.hpp:105-356`). `IndexBuffer` covers `uint16_t`
and `uint32_t` (`IndexBuffer.hpp:92-159`). — **VERIFIED**

**C24.** `VertexDeclaration` derives from `GraphicsResource` and is immutable after construction: three
constructors (element list with auto-computed stride = `max(offset + sizeof(format))` matching FNA;
explicit stride + initializer_list; explicit stride + vector), throwing `ArgumentNullException` on
empty elements and `ArgumentOutOfRangeException` on non-positive stride
(`VertexDeclaration.hpp:20-53`). `VertexElement` is a plain struct with mutable
offset/format/usage/usageIndex properties (`VertexElement.hpp:19-60`). Both
`VertexElement::GetHashCode()` and the vertex types' return `0`, consistent with FNA's own TODO
(`VertexElement.hpp:131`, `VertexPositionTexture.hpp:75`, etc.). — **VERIFIED**

**C25.** **No content-side premultiplication anywhere.** Grepping `modules/content/` and
`modules/graphics/src/Internal/` for "premultipl" returns nothing. The CNA-side pixel representation
is always straight (non-premultiplied) — stated explicitly in `docs/blend2d-renderer.md:130`. XNA's
Content Pipeline premultiplies by default and `SpriteBatch.Begin()` defaults to
`BlendState::AlphaBlend` (the premultiplied equation, `SpriteBatch.cpp:109`), so the CNA pairing
differs from XNA's out of the box. — **VERIFIED**

---

## D. State objects

**D1.** All four state objects derive from `GraphicsResource` and are **plain mutable value types with
no freeze, no device binding, and no `GraphicsDevice` back-pointer**. There is no XNA-style "you cannot
modify a state object that is bound to a device" `InvalidOperationException` anywhere: every setter is
an unconditional field write (`BlendState.cpp:42-76`, `DepthStencilState.cpp:38+`,
`RasterizerState.cpp:27-44`, `SamplerState.cpp:36-58`). — **VERIFIED**

**D2.** **`GraphicsDevice` stores state objects by value, not by reference.**
`BlendState blendState_; DepthStencilState depthStencilState_; RasterizerState rasterizerState_;`
(`GraphicsDevice.hpp:1137-1139`), and every setter takes `const T&` and copies
(`GraphicsDevice.cpp:2695`, `:2726`, `:2741`). So
`device.BlendState = myState; myState.ColorSourceBlend = ...;` has **no effect** on the device — the
opposite of XNA's reference semantics. The mutable `getBlendStateProperty()` overload returns a
reference to the device's *copy*, and mutating it does **not** re-push to the renderer. — **VERIFIED**

**D3.** **Built-in static instances** (all `const`, all name-tagged):

- `BlendState`: `Additive`, `AlphaBlend`, `NonPremultiplied`, `Opaque` (`BlendState.cpp:6-9`).
  Factors, in `(colorSrc, alphaSrc, colorDst, alphaDst)` order: Additive
  `(SourceAlpha, SourceAlpha, One, One)`; AlphaBlend `(One, One, InverseSourceAlpha, InverseSourceAlpha)`;
  NonPremultiplied `(SourceAlpha, SourceAlpha, InverseSourceAlpha, InverseSourceAlpha)`; Opaque
  `(One, One, Zero, Zero)`.
- `DepthStencilState`: `Default` (test+write), `DepthRead` (test only), `None` (neither)
  (`DepthStencilState.cpp:6-8`).
- `RasterizerState`: `CullClockwise`, `CullCounterClockwise`, `CullNone` (`RasterizerState.cpp:6-8`).
- `SamplerState`: `AnisotropicClamp`, `AnisotropicWrap`, `LinearClamp`, `LinearWrap`, `PointClamp`,
  `PointWrap` (`SamplerState.cpp:6-11`). — **VERIFIED**

**D4.** Default-constructed values: `BlendState` = opaque (`One/Zero`, `Add`, all four
`ColorWriteChannels::All`, blendFactor opaque white, multiSampleMask `-1`) (`BlendState.cpp:11-30`).
`DepthStencilState` = depth on, write on, `LessEqual`, stencil off, masks `0x7FFFFFFF`, all ops `Keep`,
two-sided off (`DepthStencilState.cpp:10-28`). `RasterizerState` = `CullCounterClockwiseFace`, `Solid`,
MSAA-AA true, scissor off, biases 0 (`RasterizerState.cpp:10-18`). `SamplerState` = `Wrap` on all three
axes, `Linear`, maxAnisotropy 4, maxMipLevel 0, LOD bias 0 (`SamplerState.cpp:14-23`). — **VERIFIED**

**D5.** `BlendState` constructing its blend factor **in place** (`blendFactor_(255,255,255,255)`)
rather than from `Color::White` is a deliberate static-initialization-order fix, documented at
`BlendState.cpp:22-27` — the four namespace-scope presets run during static init and `Color::White`
lives in another TU. A concrete C++-porting anecdote for the book. — **VERIFIED**

**D6.** Application to the renderer is one-shot and complete-per-call: `ApplyBlendState` carries six
factor/function ordinals plus a `BlendWriteState` struct holding four per-MRT `ColorWriteChannels` and
the coverage `multiSampleMask` (REMED-GFX-077, `GraphicsDevice.cpp:2669-2691`);
`ApplyDepthStencilState` carries **16** parameters including full two-sided stencil (`:2705-2721`);
`ApplyRasterizerState` carries five (`:2735-2740`). Sampler state is applied lazily, for all 16 slots,
immediately before each draw (`applySamplerStatesToRenderer()`, called at `:1126`, `:1214`, and the
instanced route). — **VERIFIED**

---

## E. Stock effects

**E1.** **All five XNA stock effects are fully implemented**, plus `SpriteEffect`: `BasicEffect`
(232 lines), `AlphaTestEffect` (405), `DualTextureEffect` (300), `EnvironmentMapEffect` (492),
`SkinnedEffect` (544), `SpriteEffect` (52). Each has a real `OnApply()`, `Clone()`, and
`FillGpuDrawParams()`. — **VERIFIED**

**E2.** CNAEXT effects beyond XNA, all in the same namespace: `PbrEffect` (387 lines, glTF 2.0
metallic-roughness with GGX+Smith-Schlick+Schlick Fresnel), `SkinnedPbrEffect` (437),
`ColorMatrixEffect` (94, "a fixed CPU colour transform for SpriteBatch on the GDI and SOFTWARE
renderers", `ColorMatrixEffect.hpp:15`), `ShaderEffect` (129), plus `EffectMaterial`,
`AnimationPlayer`, `MorphTargetEXT`, `SkinnedModelEXT`. `PbrEffect.hpp:29-33` names the renderers with
real PBR shaders and states that Software/Canvas/Ascii/Headless/SDL_Renderer/FreeDirect "accept a
bound PbrEffect without erroring but currently render it as an untextured/unlit fallback". — **VERIFIED**

**E3.** **★ There is no shader-parameter mechanism. The Effect→renderer contract is a single closed
struct.** `GpuDrawParams` (`IGraphicsRenderer.hpp:846-990+`) is a fixed aggregate of every
stock-effect uniform CNA knows about: `texture0/texture1/envMap`, `diffuseColor[4]`,
`ambientColor[3]`, `light0/1/2Dir/Diffuse/Specular[3]`, `specularColor[3]`, `specularPower`,
`emissiveColor[3]`, `eyePositionWorld[3]`, `worldColMajor[16]`, `alphaTest[4]`,
`fogEnabled/fogColor[3]/fogVector[4]`, `envMapAmount/fresnelEnabled/fresnelFactor/envMapSpecular[3]`,
`boneTransforms[72*16]`, `boneCount`, `weightsPerVertex`, the boolean variant selectors
`textureEnabled/vertexColorEnabled/lightingEnabled/preferPerPixelLighting/dualTexture/envMapping/skinned/pbr`,
the CPU-only `cpu2DColorMatrix[16]`/`cpu2DColorOffset[4]`, `instanceCount`,
`vertexStreams[]`/`vertexStreamCount`/`combinedVertexStride`, and `customEffectRenderer`.
`GraphicsDevice` fills it by calling the virtual `currentEffect_->FillGpuDrawParams(p)` before every
draw (`GraphicsDevice.cpp:1105`, `:1190`). **Adding a new uniform means editing this struct and every
renderer** — that is the architectural heart of the shader story. — **VERIFIED**

**E4.** **`EffectParameter` is a CPU-side value bag with no GPU connection.** It stores
`intData_`/`floatData_`/`stringData_` and offers `GetValue*`/`SetValue`
(`EffectParameter.cpp:33-100+`). Nothing reads these values on the way to a renderer — the renderer
sees `GpuDrawParams` only. Setting `effect.Parameters["DiffuseColor"]->SetValue(...)` therefore does
**not** change what is drawn, except where a stock effect's own property getter happens to read back
through the parameter (e.g. `AlphaTestEffect::getFogColorProperty` returns
`fogColorParam_->GetValueVector3()`, `AlphaTestEffect.cpp:120-123`). — **VERIFIED**

**E5.** **Parameter collections are populated inconsistently across the stock effects.**
`AlphaTestEffect` adds 6 (`DiffuseColor, AlphaTest, FogColor, FogVector, WorldViewProj, ShaderIndex` —
`AlphaTestEffect.cpp:69-74`); `DualTextureEffect` 5 (`DualTextureEffect.cpp:70-74`);
`EnvironmentMapEffect` 12 (`EnvironmentMapEffect.cpp:90-101`); `SkinnedEffect` 12 including `Bones` at
`MaxBones × 4` (`SkinnedEffect.cpp:102-113`); `PbrEffect` and `SkinnedPbrEffect` likewise.
**`BasicEffect` adds none at all** — `BasicEffect.cpp` never calls `getParametersProperty()`, so
`basicEffect.Parameters.Count == 0` and `Parameters["DiffuseColor"]` returns `nullptr`. — **VERIFIED**

**E6.** **★ `SpriteEffect::OnApply()` is a permanent no-op — a real, untested defect.**
`CacheEffectParameters()` looks up `getParametersProperty()["MatrixTransform"]`
(`SpriteEffect.cpp:29`), but nothing ever *adds* a parameter by that name: `Effect`'s base constructor
adds only a technique (`Effect.cpp:14-15`), and `SpriteEffect` has no `AddParam` call. So
`matrixParam_` is always `nullptr`, and `OnApply()` returns at its first line
(`SpriteEffect.cpp:32-33`) without ever computing the orthographic projection + half-pixel offset the
rest of the method describes. Grepping `MatrixTransform` repo-wide finds only this lookup plus
renderer-side uniform names (`modules/renderers/opengl2/src/OpenGL2Renderer.cpp:1709`, `:1916`) — i.e.
**the sprite transform is supplied by each renderer, not by `SpriteEffect`**, so the bug is invisible
in practice. `modules/graphics/tests/.../SpriteEffectTests.cpp` (38 lines) only tests `Clone()` and
that `Apply()` does not throw; it never asserts the parameter exists. — **VERIFIED**

**E7.** **Every `EffectTechnique` gets exactly one pass named `"P0"`.** `EffectTechnique(owner, name)`
unconditionally does `passes_.Add(EffectPass(owner, "P0", id_))` (`EffectTechnique.cpp:15-19`), and
`Effect`'s constructor adds exactly one technique named `"Default"` (`Effect.cpp:14-15`). So the
canonical XNA idiom `foreach (var pass in effect.CurrentTechnique.Passes) { pass.Apply(); ... }`
**works** and iterates once, but the technique and pass names are synthetic placeholders, never the
names from an `.fx` file. — **VERIFIED**

**E8.** `EffectPass::Apply()` validates that the pass belongs to the effect's *current* technique using
a stable `uint64_t` identity token (`EffectTechnique::getIdInternal()`, monotonic atomic counter at
`EffectTechnique.cpp:10-13`) rather than a raw pointer — because `EffectTechniqueCollection` may
reallocate. Mismatch throws `InvalidOperationException("Applied a pass not in the current
technique!")`, matching FNA; a null `CurrentTechnique` maps to the same defined exception where FNA
would `NullReferenceException` (`EffectPass.cpp:22-31`, documented `EffectPass.hpp:56-66`). — **VERIFIED**

**E9.** `Effect::Apply()` is CNAEXT — FNA has no public `Effect.Apply()`, only `EffectPass.Apply()`
(`Effect.hpp:106-107`). It throws `ObjectDisposedException` if disposed, calls the pure-virtual
`OnApply()`, then `device_->SetCurrentEffect(this)` (`Effect.cpp:53-59`). — **VERIFIED**

**E10.** **`Effect::Clone()` is pure virtual and returns a raw owning pointer** — a documented CNAEXT
deviation, since CNA has no GC (`Effect.hpp:126`, rationale `:118-125`). Stock effects clone via a
private copy constructor that calls `Effect(*src.device_)` (rebuilding fresh Parameters/Techniques for
the clone's own identity) and then copies field values — e.g. `BasicEffect.cpp:14-44`,
`AlphaTestEffect.cpp:55-64`. `ShaderEffect::Clone()` deliberately **recompiles** a new program from the
same source strings rather than sharing the original's `unique_ptr<IEffectRenderer>`
(`ShaderEffect.cpp:125-128`, rationale `ShaderEffect.hpp:151-163`). — **VERIFIED**

**E11.** `BasicEffect` implements `IEffectMatrices`, `IEffectFog`, `IEffectLights`;
`World`/`View`/`Projection`/`VertexColorEnabled` are **public fields**, not properties
(`BasicEffect.hpp:39-46`). It has no dirty-flag machinery — `OnApply()` is empty and all work happens
in `FillGpuDrawParams` (`BasicEffect.cpp:46-161`). The other stock effects *do* use FNA-style dirty
flags (`DirtyWorldViewProj | DirtyFog | DirtyMaterialColor | DirtyShaderIndex | …`, e.g.
`AlphaTestEffect.cpp:85-140`). — **VERIFIED**

**E12.** `BasicEffect::FillGpuDrawParams` reproduces several exact FNA formulas with the reasoning
inline — worth quoting in the book: `EmissiveColor` is baked into the forwarded diffuse when lighting
is *off* and added on the lit path when *on* (`BasicEffect.cpp:65-75`); each `DirectionalLight`'s
diffuse/specular are **zeroed here** when disabled, because CNA's `DirectionalLight.Enabled` setter has
no side effect while FNA's does (`:81-107`); the fog vector bakes the third column of `World*View` with
the `fogStart == fogEnd` degenerate case mapped to `{0,0,0,1}` (`:139-160`, REMED-GFX-010).
`EnableDefaultLighting()` uses FNA's literal constants (`:206-225`). — **VERIFIED**

**E13.** `SkinnedEffect::MaxBones = 72` (`SkinnedEffect.hpp:28`), matching
`GpuDrawParams::boneTransforms[72*16]` (`IGraphicsRenderer.hpp:924`).
`SetBoneTransforms(vector<Matrix>)`/`GetBoneTransforms(int)` and `WeightsPerVertex` (1/2/4) are exposed
(`SkinnedEffect.hpp:324-346`). `EnvironmentMapEffect` exposes `EnvironmentMap` (a `TextureCube*`),
`EnvironmentMapAmount`, `EnvironmentMapSpecular`, `FresnelFactor`, plus CNAEXT
`SetOwnedTexture`/`SetOwnedEnvironmentMap` shared-ownership helpers
(`EnvironmentMapEffect.hpp:253-334`). — **VERIFIED**

**E14.** `GpuDrawParams::specularEnabled` is populated by `EnvironmentMapEffect` but **read by no
renderer** — stated in the field's own comment (`IGraphicsRenderer.hpp:914-922`). It exists so a future
renderer can distinguish "specular disabled" from "specular enabled but black". — **VERIFIED**

---

## F. Custom effects and shaders — the `.fx` question

**F1.** **★ The public compiled-`.fx` constructor still throws unconditionally.**
`Effect(GraphicsDevice&, const std::vector<SharpRuntime::bytecs>&)` ignores its `effectCode` parameter
entirely and throws
`System::NotImplementedException("… compiled XNA .fx bytecode is not yet supported (tracked as Phase
74, see docs/fx-bytecode-support-plan.md). Use a hand-authored ShaderEffect or one of the built-in
stock effects instead.")` (`modules/graphics/src/Xna/Effect.cpp:18-26`; declared and documented at
`Effect.hpp:33-48`). This is the **only** unconditional `NotImplementedException` in the graphics
module. — **VERIFIED**

**F2.** **★ The content pipeline mirrors that split.** The XNB reader registry registers the **five
stock effects** as real readers (`RegisterStockEffectXnbReaders()`,
`modules/content/src/Xnb/XnbBuiltInReaders.cpp:13,41`, header
`CNA/Internal/Xnb/StockEffectContentTypeReaders.hpp`), but the **general**
`Microsoft.Xna.Framework.Content.EffectReader` is registered as a `KnownUnsupportedContentTypeReader`
with reason `CompiledPlatformShaderBytecode`, which throws
`ContentLoadException("The 'Microsoft.Xna.Framework.Graphics.Effect' content type reader is recognized
but not supported by CNA (…)")` (`modules/content/src/Xna/KnownUnsupportedContentTypeReader.cpp:30-47`).
So `Content.Load<Effect>("MyShader")` fails cleanly and by name; `Content.Load<BasicEffect>(...)`
works. — **VERIFIED**

**F3.** **★★ BUT: real Microsoft XNA `.fxb` bytecode is now committed in the repo and executed at
runtime through MojoShader — on one renderer.** `modules/renderers/fna3d/effects/` contains six
binaries vendored verbatim from FNA `src/Graphics/Effect/StockEffects/FXB/` @
`30a427365a1684d6599329560efcfb90233701a9`, Ms-PL: `SpriteEffect.fxb` (1104 B), `BasicEffect.fxb`
(28824), `AlphaTestEffect.fxb` (5592), `DualTextureEffect.fxb` (4680), `EnvironmentMapEffect.fxb`
(10968), `SkinnedEffect.fxb` (55532) — provenance table at
`modules/renderers/fna3d/effects/README.md:19-35`. They are embedded by `effects/embed_effects.py` into
a generated `Fna3dStockEffectBlobs.hpp` (`modules/renderers/fna3d/CMakeLists.txt:32-45`), then loaded
at renderer construction: `Fna3dRenderer.cpp:205-219` calls
`Fna3dStockEffect::Load(device_, kBasicEffectFxb, sizeof(kBasicEffectFxb), "BasicEffect")` etc., and
`Load()` calls **`FNA3D_CreateEffect`** — i.e. `MOJOSHADER_compileEffect` — validating
`error_count == 0` and `technique_count >= 1`
(`modules/renderers/fna3d/src/Fna3dStockEffects.cpp:9-42`). Parameters are then set by name through
`MOJOSHADER_effectParam` lookups (`:56-137`) and the effect applied via `FNA3D_SetEffectTechnique` +
`FNA3D_ApplyEffect` (`:154-165`). — **VERIFIED**

**F4.** **MojoShader is a real, pinned build dependency of CNA at this SHA** — contrary to the plan
document. `cmake/ThirdPartyFNA3D.cmake` `FetchContent_Declare`s `https://github.com/FNA-XNA/FNA3D.git`
at tag `3240147` **with submodules**, hard-fails if `MojoShader/mojoshader.h` is absent (`:66-69`), and
exposes an INTERFACE target `cna_fna3d` carrying the MojoShader include root and the switches
`MOJOSHADER_EFFECT_SUPPORT`, `MOJOSHADER_NO_VERSION_INCLUDE`, `MOJOSHADER_USE_SDL_STDLIB` (`:89-100`).
`modules/renderers/fna3d/include/CNA/Internal/Renderers/Fna3d/Fna3dApi.hpp:8-20` includes
`<mojoshader.h>` before `<FNA3D.h>` and explains why the order matters. — **VERIFIED**

**F5.** **FNA3D structurally cannot compile shader *source*, and says so.**
`modules/renderers/fna3d/effects/README.md:5-10`: "`FNA3D.h` exposes exactly one way to get a shader
onto the GPU: `FNA3D_CreateEffect()` … There is no 'compile this GLSL/HLSL string' entry point anywhere
in the library." Accordingly `Fna3dRenderer::CreateEffectRenderer` returns `nullptr` unconditionally
(`Fna3dRenderer.cpp:934-938`) and `SupportsCapability(CustomEffects)` returns `false` with the reason
inline (`:884-889`). It also returns `false` for `Instancing`, because none of XNA's stock effects
declares a per-instance vertex input, so reporting true "would promise instancing that renders every
instance from record 0" (`:891-898`). The `.fxb` blobs are **not** rebuildable in-repo — compiling
`.fx` → `.fxb` needs `fxc` from the DirectX SDK, which exists on no platform CNA builds on
(`effects/README.md:53-55`). — **VERIFIED**

**F6.** **★ A third, independent strand: D3D9 vendors Microsoft's XNA `.fx` HLSL *sources* and
byte-verifies its own compiled output against Microsoft's shipped `.fxb`.**
`modules/renderers/directx9/src/shaders/xna/` holds `BasicEffect.fx`, `AlphaTestEffect.fx`,
`DualTextureEffect.fx`, `EnvironmentMapEffect.fx`, `SkinnedEffect.fx`, `SpriteEffect.fx` plus
`Common.fxh`/`Lighting.fxh`/`Macros.fxh`/`Structures.fxh` and a `LICENSE` (84 KB total).
`compile_shaders_sm2.py` *parses* the entry-point list from those `.fx` files' own
`compile [vp]s_2_0 …` statements (never hand-maintained) and compiles them with the real Microsoft
`d3dcompiler_47.dll` under a dedicated Wine prefix (`:1-25`). `compare_against_fxb.py:1-16` records the
measured result: after stripping CTAB/creator comment tokens, **61 of 66 shaders match Microsoft's
shipped instruction stream exactly**; the 5 misses are all PixelLighting vertex variants, attributed to
`d3dcompiler_47` vs the XNA-era `D3DCompiler_43`, with `OPTIMIZATION_LEVEL0/1/2/3`,
`SKIP_OPTIMIZATION` and `AVOID_FLOW_CONTROL` all tried and none matching. Compile flags are
consequently locked to `D3DCOMPILE_OPTIMIZATION_LEVEL3` alone (`compile_shaders_sm2.py:18-21`). — **VERIFIED**

**F7.** **`ShaderEffect` is the only user-facing custom-shader route, and it is source-string based.**
`ShaderEffect(device, vertSrc, fragSrc)` calls `device.renderer_->CreateEffectRenderer(vertSrc,
fragSrc)` and, on compile failure, prints to `std::cerr` and **continues** — construction never throws
(`ShaderEffect.cpp:13-26`). `IsEffectValid()` is the caller's only signal (`:28-31`). Parameters are
set through typed setters, not `EffectParameter`:
`SetUniformMat4/Vec4/Vec3/Vec2/Float/Int/FloatArray/Vec2Array` and three
`SetTexture(unit, Texture2D&|TextureCube&|Texture3D&)` overloads (`ShaderEffect.hpp:49-96`). Every one
is a null-guarded forward (`ShaderEffect.cpp:33-86`). `ShaderEffect` implements `IEffectMatrices` so it
can drive real 3D draws, not just `SpriteBatch` (`ShaderEffect.hpp:98-118`, Task 1079).
`FillGpuDrawParams` sets **only** `params.customEffectRenderer` and leaves every other field defaulted
(`ShaderEffect.cpp:114-117`). — **VERIFIED**

**F8.** **`CreateEffectRenderer`'s base default returns `nullptr`** (`IGraphicsRenderer.hpp:1486-1488`),
and the interface is deliberately language-agnostic — `IEffectRenderer::CompileProgram` is doc'd as
"Compiles the program from GLSL/HLSL/SPIR-V sources" (`:656-658`). **22 of 42 renderers override it**,
but the override often exists *only to define a rejection contract*. What each accepts (all VERIFIED
unless noted):

- **Raw GLSL, compiled natively:** easygl (ESSL 3.00, with a runtime ES 3.00→ES 1.00 downgrade
  transform for WebGL1 — `EasyGLRenderer.cpp:402-480`), opengl2 (versionless GLSL ~110), opengl4
  (GLSL 410 core), magnum (GLSL 330+, strips and re-derives `#version`; **never rejects** — logs to
  `std::cerr` and returns the invalid effect, `MagnumRenderer.cpp:556-560`), sokol (GL-only, and the
  whole body is inside `#if CNA_SOKOL_HAS_GL_READBACK`).
- **Raw GLSL → SPIR-V at runtime via libshaderc:** sdl-gpu (`SdlGpuRenderer.cpp:1003-1056`), llgl
  (prefers verbatim GLSL when the module supports it; the SPIR-V path **rejects any shader using a
  descriptor set ≠ 0**, `LlglRenderer.cpp:1196-1241`).
- **Raw HLSL, runtime `D3DCompile`:** directx11 and directx12 (`vs_5_0`/`ps_5_0`, entry `main`) — but
  scoped: a **fixed 32-byte SpriteBatch vertex layout and 128-byte constant buffer**, "a
  SpriteBatch-custom-shader facility, not a general arbitrary-vertex-format one"
  (`D3D11EffectRenderer.cpp:64-80`); directx9 (`vs_3_0/ps_3_0` on HiDef, `vs_2_0/ps_2_0` on Reach,
  `D3D9EffectRenderer.cpp:35-37`).
- **Pre-compiled SPIR-V bytes packed in a `std::string`, NOT GLSL:** vulkan — validates only
  `size % 4 == 0`, then `vkCreateShaderModule` (`VulkanRenderer.cpp:3175-3194`). A caller handing
  Vulkan GLSL gets garbage or a driver error, not a compile diagnostic.
- **Marker-gated:** skia — only the literals `"CNA_SKIA_SKSL_MESH_V1"` / `"CNA_SKIA_SKSL_V1"` are
  accepted; anything else returns `nullptr` rather than "asking SkSL to guess their language"
  (`SkiaRenderer.cpp:520-540`).
- **Hardcoded failure stub:** bgfx — `CompileProgram` is `{ return false; }` with the message "bgfx
  renderer requires pre-compiled binary shaders (not GLSL source)" (`BgfxRenderer.hpp:182-188`).
- **Always throws:** metal (`NotSupportedException`, `MetalRenderer.mm:3274-3280`), gdi
  (`ThrowUnsupportedFeature("ShaderEffect programs")`), html-dom and svg-dom (shared
  `ThrowNo3D("CreateEffectRenderer (custom programmable effects)")`).
- **Accepts anything, never compiles:** headless (`HeadlessRenderer.cpp:385-395`), software
  (`compiled_ = true; return true`, `SoftwareRenderer.cpp:2593-2599`).
- **Returns nullptr / no override:** fna3d (explicitly), webgpu, wicked, diligent, opengl1, opengles1,
  portablegl, sdl-renderer, and the fixed-function DirectX 1–8 family.

**F9.** **Shader authorship is overwhelmingly offline-generated, checked-in binary.** Generated headers
and their sizes: `common/d3d/src/shaders/hlsl_shaders.hpp` **3.41 MB** (DXBC, 34 `.hlsl`),
`bgfx/src/shaders/bgfx_shaders.hpp` **1.75 MB** (28 `.sc`), `sokol/src/shaders/sokol_shaders.hpp`
**832 KB** (8 annotated `.glsl` → 5 backends via sokol-shdc), `llgl/src/shaders/llgl_shaders.hpp`
**458 KB** (50 `.glsl`, dual Vulkan/GL flavours), `directx9/src/shaders/d3d9_shaders.hpp` **390 KB**,
`vulkan/src/shaders/spirv_shaders.hpp` **370 KB** (36 `.glsl`),
`sdl-gpu/src/shaders/spirv_shaders.hpp` **236 KB** (23 `.glsl`). On-disk shader source counts: llgl 50,
vulkan 36, common/d3d 34, bgfx 28, sdl-gpu 23, directx9 10, sokol 8; every other renderer has zero.
**No shader generation is wired into any CMake target** — every generator is documented as run-by-hand
with a checked-in output, so an ordinary build needs no shader toolchain and no network
(`compile_shaders_hlsl.py:19-21`, `compile_shaders_sm2.py:24-25`,
`sokol/src/shaders/compile_shaders.py:4-8`, `llgl/src/shaders/compile_shaders.py:10-11`). Three
renderers keep shaders as inline C++ strings *because* the backend compiles at runtime: diligent
(HLSL), wicked (HLSL), webgpu (WGSL), plus metal (one MSL literal) and directx10
(`vs_4_0`/`ps_4_0`). — **VERIFIED**

**F10.** The two verification scripts do **different** things.
`scripts/verify_d3d_shaders_reproducible.sh` (112 lines) proves the committed D3D bytecode is
**byte-for-byte reproducible** — leg 1 regenerates `hlsl_shaders.hpp` under Wine's builtin
`d3dcompiler_47.dll` and asserts an empty whole-file `diff`; leg 2 recompiles 6 D3D9 entry points
against the real Microsoft DLL and md5-compares each array (`:62-100`).
`scripts/verify_hlsl_shaders_native_msvc.py` (91 lines) proves only that **real Windows `cl.exe` +
genuine `D3DCOMPILER_47.dll` still accept the HLSL**, deliberately *not* byte-diffing because a
different compiler build can emit different-but-equivalent DXBC (`:14-18`). — **VERIFIED**

**F11.** **`scripts/verify_hlsl_shaders_native_msvc.py` is dead code at this SHA.** Line 30 points at
`REPO_ROOT / "src" / "CNA" / "Internal" / "Renderers" / "D3DCommon" / "shaders"`; there is no top-level
`src/` in the repo (shaders live under `modules/renderers/common/d3d/src/shaders/`), so the
`from compile_shaders_hlsl import SHADERS` on line 32 raises `ModuleNotFoundError`. Any Windows CI job
invoking it fails on import, not on a shader regression. — **VERIFIED**

**F12.** **Two renderers claim `GraphicsCapability::CustomEffects == true` while being unable to honour
it.** The base `SupportsCapability` returns `true` for everything except `StencilBuffer` (delegated) and
`MultiStreamVertexInput` (`IGraphicsRenderer.hpp:1823-1834`). **webgpu** has zero occurrences of
`CreateEffectRenderer` anywhere and its `SupportsCapability` special-cases only `WireFrame` before
falling through (`WebGPURenderer.cpp:6065-6075`) — so it reports `CustomEffects == true` while
returning `nullptr`; the only backstop is `WebGPUSpriteBatchRenderer::SetCustomEffect` throwing
(`:2211-2215`). **bgfx** has no `CustomEffects` case at all outside its examples, so it inherits `true`
while its `CompileProgram` is a hardcoded `return false`. Every other non-supporting renderer returns
`false` explicitly (diligent `DiligentRenderer.cpp:2665`, wicked `WickedRenderer.cpp:3552`, opengl1
`:508`, skia `SkiaRenderer.cpp:897`, fna3d `Fna3dRenderer.cpp:888`, portablegl `:1614`). — **VERIFIED**
(the code paths); **STRONG** (that this is a defect rather than a deliberate "throw later" design)

**F13.** `docs/fx-bytecode-support-plan.md` (124 lines) is an honest planning document — it opens with
"It is a planning document, not a status report — every item below is currently unimplemented (⬜)
except where noted" (`:7-8`) — and lays out Phase 74 / Tasks 10200–10208: vendor MojoShader, wrap
`mojoshader_effects.c`'s parser, EasyGL GLSL path, Vulkan glslang investigation + implementation, bgfx
feasibility, wire reflection into `Effect`, source test fixtures, docs (`:95-122`). It correctly
identifies that MojoShader has **no SPIR-V output profile**, so Vulkan needs a second GLSL→SPIR-V hop
(`:52-56`). — **VERIFIED**

---

## G. SpriteBatch and SpriteFont

**G1.** `SpriteBatch : GraphicsResource`, holding `unique_ptr<ISpriteBatchRenderer> renderer_`, a
`bool begun`, `sortMode_`, `transformMatrix_`, `Effect* customEffect_` (non-owning), and
`vector<SpriteInfo> spriteQueue_` (`SpriteBatch.hpp:42-68`). Three constructors: from a
`GraphicsDevice` (creates the renderer via `graphicsDevice.GetRenderer().CreateSpriteBatch()`), a
default one, and a CNAEXT test-only one taking an explicit renderer (`SpriteBatch.cpp:85-97`). — **VERIFIED**

**G2.** **SpriteBatch is implemented once in the core and lowered to a per-renderer
`ISpriteBatchRenderer`.** `flushSingle` is the single submission point:
`renderer_->Draw(texture->GetRenderer(), destRect, srcRect, color, rotation, origin, effects,
layerDepth)` (`SpriteBatch.cpp:267-273`). Sorting, queueing, string layout, and argument validation are
all shared; only rasterization is per-renderer. — **VERIFIED**

**G3.** Five `Begin` overloads, all funnelling into the 7-argument one (`SpriteBatch.cpp:107-214`). That
one: throws `std::runtime_error("Begin has been called before calling End.")` on re-entry; pushes
`blendState`, `depthStencilState ?? DepthStencilState::None`, and
`rasterizerState ?? RasterizerState::CullCounterClockwise` through the **`GraphicsDevice` properties**
(so they route through the same `Apply*State` path every renderer uses); stores
effect/transform/sortMode; clears the queue; then forwards `SetCustomEffect`, `SetTransformMatrix`,
`SetSamplerFilter`/`SetSamplerAddressMode` from `samplerState ?? SamplerState::LinearClamp`,
`SetImmediateMode`, and `Begin()` to the renderer. Each resolved state is **always re-applied**, never
inherited from a previous `Begin` — matching FNA's `PrepRenderState`. — **VERIFIED**

**G4.** `Begin` is **exception-transactional**: if renderer setup throws (e.g. Skia rejecting a mip-only
sampler filter, or a renderer rejecting a custom effect), it clears `customEffect_`, clears the queue,
sets `begun = false`, and rethrows — so the same `SpriteBatch` stays reusable after the caller catches
(`SpriteBatch.cpp:196-213`). `begun = true` is published only after setup succeeds. — **VERIFIED**

**G5.** Three of the state parameters were historically *discarded*, and the fixes are documented
inline: `depthStencilState` was unused until Task 803, so sprite draws silently inherited whatever the
game's 3D rendering last set (`SpriteBatch.cpp:154-162`); `rasterizerState` was `/*rasterizerState*/`
until REMED-GFX-081, so a `ScissorTestEnable`/`CullMode`/`FillMode` passed to `Begin` never reached the
device (`:163-174`). — **VERIFIED**

**G6.** `End()` throws if not begun, flushes the queue for non-`Immediate` modes, calls
`renderer_->End()` and `SetCustomEffect(nullptr)`, then clears `begun`/`customEffect_`
(`SpriteBatch.cpp:216-229`). It does **not** restore the device state `Begin` overwrote — matching
XNA. — **VERIFIED**

**G7.** **`SpriteSortMode` handling**, `flushBatch()` at `SpriteBatch.cpp:275-306`:

- `Immediate` — `pushSprite` bypasses the queue and calls `flushSingle` directly (`:257-260`), and
  `SetImmediateMode(true)` is forwarded to the renderer.
- `Deferred` — no sort, submission order.
- `BackToFront` / `FrontToBack` — `std::stable_sort` on `layerDepth` descending / ascending.
- `Texture` — `std::stable_sort` on the raw **`const Texture2D*` pointer value**. Stable within a run,
  but the resulting group order is allocation-address-dependent, not deterministic across runs. — **VERIFIED**

**G8.** **★ Destination rectangles are integers; sub-pixel sprite positioning is lost.**
`SpriteInfo::destRect` and `srcRect` are `Rectangle` (int) (`SpriteBatch.hpp:47-48`).
`Draw(texture, Vector2 position, …)` runs `TruncateDestinationComponent` — plain
`static_cast<intcs>` after a finiteness/range check — on both components (`SpriteBatch.cpp:363-376`,
`:49-59`). Scaled overloads truncate `dw * scale` and `dh * scale` too (`:412-415`, `:437-440`). XNA
computes the destination in floats. `DrawString`, by contrast, **rounds** rather than truncates
(`RoundDestinationComponent`, `:61-78`, used at `:629-636`) — so text and sprites use different
rasterization-position rules. — **VERIFIED**

**G9.** Non-finite float arguments throw `ArgumentOutOfRangeException("SpriteBatch floating-point
arguments must be finite.")`, and an out-of-Int32-range computed destination throws `"The calculated
SpriteBatch destination component must be within Int32 range."` (`SpriteBatch.cpp:27-59`). Every
`Draw`/`DrawString` throws `std::runtime_error` if `Begin` was not called. `pushSprite` throws
`ObjectDisposedException` for a disposed texture — explicitly noted as hardening beyond FNA, which does
not guard this (`:240-246`, Task 717). — **VERIFIED**

**G10.** `SpriteEffects` is a real composable flags enum with `operator|`, `operator&`, `operator|=`,
`operator&=` defined (`SpriteEffects.hpp:25`, `:53`). `DrawString` masks to the low two bits
(`effects & 0x03`) exactly as FNA does and indexes **four-element** axis tables
`axisDirX/axisDirY/axisIsMirroredX/axisIsMirroredY` (`SpriteBatch.cpp:549-556`). REMED-GFX-003 records
that these were previously sized 3, an out-of-bounds stack read for the combined-flip case. — **VERIFIED**

**G11.** `DrawString` mirrors FNA's algorithm faithfully: when `effects != None` the whole string is
measured up front and `origin` shifted by the measured size on the mirrored axis, so the character
**sequence** mirrors rather than each glyph flipping in place — CNA's own prior bug, called out at
`SpriteBatch.cpp:544-548`. UTF-8 is decoded per code point (`DecodeUtf8CodePoint`, `:571`); `\r` is
skipped, `\n` advances by `lineSpacing`; the first glyph on a line uses `abs(kerning.X)` while later
glyphs use `spacing + kerning.X` (`:601-610`); a missing glyph falls back to `defaultCharacter` or
throws `std::invalid_argument`, with a `KeyNotFoundException` backstop (`:582-598`, REMED-GFX-002).
Rotation is applied per glyph around `position` (`:622-632`). — **VERIFIED**

**G12.** **`SpriteFont` is not a `GraphicsResource`** — it is a standalone class holding a `Texture2D`
**by value** plus `glyphData_`, `croppingData_`, `kerning_` (`Vector3` per glyph = left bearing / width
/ right bearing), `characterMap_`, an `unordered_map<charcs,int> characterIndexMap_`, an optional
`defaultCharacter_`, `lineSpacing_`, `spacing_` (`SpriteFont.hpp:23`, `:116-127`). Its only public
constructor takes all of that (in XNA it is `internal`, invoked only by the content pipeline), and it
validates that `defaultCharacter`, if set, is present in `characters` (`:43-45`). `SpriteBatch` is a
`friend` and reaches into the private members directly (`:127`). — **VERIFIED**

**G13.** `SpriteBatch::DrawMeshEXT` is a CNAEXT triangle-list 2D mesh draw, implemented **only** by the
Skia renderer; every other `ISpriteBatchRenderer` throws `std::runtime_error`. It requires
`SpriteSortMode::Immediate` — a declared, tested scope boundary, since a mesh draw does not participate
in the deferred queue (`SpriteBatch.hpp:447-479`, `SpriteBatch.cpp:674-689`). — **VERIFIED**

---

## H. `modules/graphics-ext` (CNAEXT graphics extensions)

**H1.** Everything in `modules/graphics-ext` is wrapped in `#ifdef CNA_CNAEXT` — the whole module
compiles away when the extension feature macro is off (every header opens with it, e.g.
`CRTEffect.hpp:4`, `RenderPipelineSettings.hpp:4`). The macro was renamed from `NOXNA` in the 2026-08
normalization (`modules/graphics-ext/CMakeLists.txt:3-5`). — **VERIFIED**

**H2.** **Post-process effects (3):**

- **`CRTEffect`** — a `ShaderEffect` subclass emulating a period CRT: darkened alternating scanlines,
  an RGB sub-pixel mask (`CRTMaskType::None|ApertureGrille|ShadowMask`), barrel-distortion curvature,
  corner vignette. Documented as requiring a **single full-screen source** — curvature/vignette index
  off `vTexCoord`, so binding it to a multi-draw-call scene curves each sprite individually; render to
  a `RenderTarget2D` first, then redraw full-screen (with `SpriteEffects::FlipVertically` to compensate
  for bottom-up RT storage). Scanlines and the RGB mask index off `gl_FragCoord` and do not have this
  restriction. GLSL / EasyGL. No XNA precedent (`CRTEffect.hpp:12-46`, `CRTMaskType.hpp:8-18`).
- **`DepthEffect`** — a `ShaderEffect` subclass doing colour-depth reduction: `Color16Bit` (RGB565),
  `Color8Bit` (RGB332), `Grayscale4Bit/2Bit/1Bit`, `Palette256` (216-colour web-safe, real
  nearest-colour search), `Palette16` (EGA/CGA), with optional ordered dithering
  `DitherMode::None|Bayer4x4|Bayer8x8`. `DitherMode.hpp:10-17` explains why error-diffusion
  (Floyd-Steinberg, Atkinson) is deliberately *not* offered: it is inherently sequential and does not
  parallelize onto a single-pass fragment shader without compute support (tracked as CNAEXT task N70)
  (`DepthEffect.hpp:14-33`, `DepthEffectMode.hpp:14-34`).
- **`AsciiPostProcessEffect`** — renderer-neutral ASCII/glyph-grid quantizer with
  `AsciiQuantizeMode::BlackWhite|Color`. Notably it is the **successor to a removed renderer identity**:
  `CNA_GRAPHICS_RENDERER=ASCII` used to quantize its own SDL_Renderer frame before presenting; as an
  effect it now applies to any renderer's output. Portable CPU v1: reads back via
  `Texture2D::GetData()`, quantizes on the CPU, re-uploads as tinted quads via `SpriteBatch` — a real
  GPU→CPU readback every call. Explicitly **not** a terminal/TTY renderer
  (`AsciiPostProcessEffect.hpp:16-48`, `AsciiQuantizeMode.hpp:10-21`). — **VERIFIED**

**H3.** **`PbrMaterial`** — a glTF 2.0 metallic-roughness material *settings bag only*, with
non-owning `Texture2D*` slots (albedo, normal, metallic-roughness with B=metallic/G=roughness, and
more) and scalar parameters. Its own doc says "Actual PBR rendering requires a matching `PbrEffect`
(Task N52)" — which now exists in `modules/graphics` (`PbrMaterial.hpp:12-45`). — **VERIFIED**

**H4.** **`RenderPipelineSettings`** — HDR enable/exposure/gamma, `TonemappingMode`, bloom
enable/intensity, SSAO enable, `RenderQuality`, `ShadowQuality`, shadows enable. Described as "a pure
settings bag — it does not perform any rendering itself. The active renderer reads these settings and
adjusts its render passes accordingly (**once renderer support is implemented for each feature**)"
(`RenderPipelineSettings.hpp:12-19`). See CONTRADICTIONS C3 — it is currently referenced by nothing
outside its own module. — **VERIFIED**

**H5.** Internal helpers `AsciiFontAtlas` and `AsciiQuantizer` live under
`include/CNA/Internal/Graphics/Ascii/`, migrated from the removed ASCII renderer
(`modules/graphics-ext/CMakeLists.txt:7-9`, `docs/ascii-post-process-effect.md`). Test coverage:
3 gtest files + 7 example/integration tests. — **VERIFIED**

**H6.** **graphics-ext contains no `GraphicsDevice` extension, no new resource type, and no new
renderer entry point.** Everything is built on the public `modules/graphics` API (`ShaderEffect`,
`SpriteBatch`, `Texture2D`, `RenderTarget2D`) — `AsciiPostProcessEffect.hpp:35-37` makes the point
explicitly ("the effect only ever reads finished pixels back via the public
`Texture2D::GetData()`/`SpriteBatch` APIs, never a renderer-internal type"). — **VERIFIED**

---

## I. Per-renderer divergence

**I1.** `IGraphicsRenderer.hpp` is **2079 lines** — by a wide margin the largest header in the graphics
module (next is `GraphicsDevice.hpp` at 1270). It is the whole renderer contract: device lifecycle,
clear/present, draws, buffers, textures, render targets, state application, sprite batch, effects,
queries, capabilities. — **VERIFIED**

**I2.** **`GraphicsCapability` has 12 values**, each documented as mapping to a real, already-observed
gap rather than being speculative (`modules/graphics/include/CNA/GraphicsCapability.hpp:16-116`):
`ThreeD`, `DepthStencilBuffer`, `MultiSampleAntiAliasing`, `MultipleRenderTargets`,
`AnisotropicFiltering`, `WireFrame`, `OcclusionQuery`, `CustomEffects`, `Texture3D`,
`MultiStreamVertexInput`, `Instancing`, `StencilBuffer`, `AdditiveBlending`. Several carry unusually
precise semantics — `Texture3D` "describes storage only and never promises shader sampling";
`StencilBuffer` is separate from `DepthStencilBuffer` so GDI can advertise a CPU stencil mask without
claiming a depth attachment or a 3D pipeline; `AdditiveBlending` exists because HTML_DOM silently
degrades to source-over on engines without CSS `plus-lighter`, with no exception and a different
picture. — **VERIFIED**

**I3.** **The base `SupportsCapability` default is `true` for everything except
`MultiStreamVertexInput` (false) and `StencilBuffer` (delegated to `SupportsStencilBuffer()`)**
(`IGraphicsRenderer.hpp:1823-1834`). This is an opt-*out* design: a new renderer that forgets to
override over-claims by default. The doc comment says every renderer with a narrower contract "must
override the applicable entries truthfully" — which F12 shows two renderers currently do not.
`MultiStreamVertexInput` is the deliberate exception, defaulting false "exactly like
`IVertexBufferRenderer::SetVertexDeclaration` being a required override"
(`GraphicsCapability.hpp:88-91`). — **VERIFIED**

**I4.** **The unsupported-3D-call policy is a runtime, device-scoped, two-value setting.**
`CNA::Unsupported3DGraphicsCallBehavior` = `{ Throw, WarnAndStub }`, default **`Throw`**
(`Unsupported3DGraphicsCallBehavior.hpp:16-34`; getter/setter `GraphicsDevice.hpp:1041-1046`). `Throw`
preserves each renderer's established behaviour (operations that throw keep throwing; factories that
return nullptr keep doing so). `WarnAndStub` logs **once per method name** and substitutes a safe
no-op or null-object resource. The implementation is `HandleUnsupported3DCall(rendererName,
methodName)`: it builds `"<renderer> does not support 3D: <method>"`, throws `std::runtime_error`
unless `WarnAndStub` is active, and otherwise dedupes through a
`mutable std::set<std::string> warnedUnsupported3DCalls_` before
`CNA::Logger::Warn(..., LogCategory::RENDER)` (`IGraphicsRenderer.hpp:1916-1936`). It is `const`
specifically so a renderer's `Ensure3DSupported()` override can call it as the earliest possible guard.
Changing the policy clears the warn-once history (`:1902-1907`). The policy **does not** suppress
argument errors, disposed-resource errors, driver failures, or unfinished work on an otherwise
3D-capable renderer, and does not change `SupportsCapability()` answers. There is no environment
variable for it. — **VERIFIED**

**I5.** `Ensure3DSupported(const char* operation)` has an **empty default body**
(`IGraphicsRenderer.hpp:1604`) — fully 3D-capable renderers keep it; a deliberately 2D-only renderer
overrides it with its stable unsupported-operation diagnostic. **Six renderers override it**: blend2d,
direct2d, html-dom, openvg, skia, svg-dom. — **VERIFIED**

**I6.** **Thirteen renderers have an explicit `case CNA::GraphicsCapability::ThreeD:` arm** in their
`SupportsCapability`: blend2d, diligent, direct2d, llgl, magnum, opengl1, opengl2, opengl4, opengles1,
portablegl, skia, sokol, wicked. Several of these — opengl2/opengl4/magnum/sokol/diligent/llgl —
clearly *do* draw 3D, so the arm in those files is almost certainly a conditional or partial answer
rather than a blanket `false`; the individual switch bodies were not read. Treat this as **"has an
explicit arm"** (**VERIFIED**), not as a 2D-only list (**PROBABLE** at best). Renderers with neither an
`Ensure3DSupported` override nor an explicit `ThreeD` arm inherit `true` from I3.

**I7.** **The graphics core's forwarding failure modes are three, and they differ sharply:**

- **Silent degradation to a lesser draw.** `DrawPrimitivesEx` and `DrawIndexedPrimitivesEx` have
  **default implementations that discard the entire `GpuDrawParams`** and fall back to
  `DrawColoredPrimitives`/`DrawIndexedColoredPrimitives` (`IGraphicsRenderer.hpp:1718-1727`,
  `:1732-1742`). A renderer that has not implemented the effect-aware path renders *something* —
  untextured, unlit, no fog, no skinning — with no error. This is by far the most consequential default
  in the file.
- **Hard throw.** `DrawInstancedPrimitivesEx`'s default throws
  `std::runtime_error("DrawInstancedPrimitives is not supported on this graphics renderer.")`, unless
  the renderer is non-3D *and* `WarnAndStub` is active, in which case it warns once and returns
  (`:1765-1799`). `ReadBackbuffer`'s default throws
  `std::runtime_error("ReadBackbuffer: not implemented in this renderer")` (`:1422`).
- **Silent no-op.** `ApplyRasterizerState`, `ApplySamplerState`, `ApplySamplerMipState`,
  `SetBlendFactor`, `SetContextRecoveryEnabled` all have empty `{}` defaults (`:1536-1556`, `:1907`).
  A renderer that ignores them simply ignores them. — **VERIFIED**

**I8.** Numeric capability defaults: `GetMaxVertexStreams()` returns `kMaxVertexStreams` (16)
(`IGraphicsRenderer.hpp:1847-1850`); `GetMaxTextureDimension()` returns **16384**, chosen as the
guaranteed ceiling on every native API CNA targets (D3D11/12 feature level 11_0's
`REQ_TEXTURE2D_U_OR_V_DIMENSION`), with D3D9's narrower Reach/HiDef 2048/4096 enforced separately in
`Texture2D.cpp` (`:1860-1863`). — **VERIFIED**

**I9.** `NotYetImplemented.hpp` provides a helper that "throws a `std::runtime_error` naming the
unimplemented capability and the renderer" (`:16`) — distinct from `HandleUnsupported3DCall`, which is
for *permanently* unsupported 2D-only cases. `NoOp3DResources.hpp` (176 lines) supplies the null-object
resources `WarnAndStub` substitutes. — **VERIFIED**

**I10.** Three `// TODO: SDL dependency should be abstracted later` markers survive in the renderer
interface (`IGraphicsRenderer.hpp:372`, `:1410`, `:2017`) — the interface is not yet fully
windowing-system-neutral. — **VERIFIED**

---

# API INVENTORY

Grouped by overload family; semantics noted, signatures not dumped verbatim.

### `GraphicsDevice` — `GraphicsDevice.hpp`

| Group | Members | Notes |
|---|---|---|
| Events | `Disposing`, `DeviceLost`, `DeviceReset`, `DeviceResetting`, `ResourceCreated`, `ResourceDestroyed` | `DeviceLost/Reset/Resetting` are D3D9-only in practice (B7) |
| Construction | default ctor; `(GraphicsAdapter&, GraphicsProfile, const PresentationParameters&)`; dtor | copy/move all deleted |
| Status | `getIsDisposedProperty`, `getGraphicsDeviceStatusProperty`, `getAdapterProperty`, `getGraphicsProfileProperty`, `getPresentationParametersProperty` ×2 (mutable/const), `getDisplayModeProperty` | |
| Sampler/texture slots | `getTexturesProperty`, `getVertexTexturesProperty`, `getSamplerStatesProperty`, `getVertexSamplerStatesProperty` | textures are bookkeeping only (B22); 16 slots each |
| State properties | `Blend/DepthStencil/Rasterizer` get(×2)+set; `ScissorRectangle`, `Viewport`, `BlendFactor`, `MultiSampleMask`, `ReferenceStencil` get/set | by-value storage (D2); `MultiSampleMask` is dead (B24) |
| Index binding | `getIndicesProperty`/`setIndicesProperty`; `SetIndexBuffer`/`GetIndexBuffer`; `Indices()`/`Indices(ib)` | three aliases for one thing |
| Clear | 4 overloads: `(Color)`, `(r,g,b,a)`, `(ClearOptions, Color, depth, stencil)`, `(Color, depth)` | no `Vector4` overload; masks unsupported aspects (B10–B11) |
| Frame | `Present()`, `Reset()` ×4 (none / pp / pp+adapter& / pp+adapter*), `Dispose()` | `Present` throws if a target is bound; `Reset` is not a real reset (B8) |
| Readback | `GetBackBufferData` ×3 (`(data,count)`, `(data,start,count)`, `(rect*,data,start,count)`) | `Color*` only; sizes from `PresentationParameters` (B13) |
| Render targets | `SetRenderTarget(RenderTarget2D*)`, `SetRenderTarget(RenderTargetCube*, CubeMapFace)`, `SetRenderTargets(vector<RenderTargetBinding>)`, `GetRenderTargets()` | max 4; resets viewport+scissor (B14–B15) |
| Vertex/index | `SetVertexBuffer` ×2, `SetVertexBuffers(vector)`, `GetVertexBuffers()`, `GetVertexBuffer()` | max 16 bindings |
| Draw — buffer | `DrawPrimitives`, `DrawIndexedPrimitives`, `DrawInstancedPrimitives` | all require a bound Effect (B17) |
| Draw — user, non-indexed | `DrawUserPrimitives` **×10**: raw `void*` (assumed VPC stride 16); raw `void*` + `VertexDeclaration`; 4 typed + `VertexDeclaration` (VPC / VPT / VPCT / VPNT); 4 typed without | typed+declaration overloads pack objects into the GPU stream (A5) |
| Draw — user, indexed | `DrawUserIndexedPrimitives` **×15**: raw `void*` untyped; 4 typed ×`uint16_t`; 4 typed ×`uint32_t`; raw+decl ×`uint16_t`/`uint32_t`; 4 typed+decl ×`uint16_t`; 4 typed+decl ×`uint32_t` | |
| CNAEXT | `PrimitiveVerts`, `OnResourceCreated/Destroyed`, `Add/RemoveResourceReference`, `GetTrackedResourceCount`, `SetDepthTest/Blend/DepthWriteEnabled`, `SetGraphicsProfileEXT`, `SetContextRecoveryEnabled`, `SetStringMarkerEXT`, `GetRenderer`, `GetGraphicsRendererType/Name` (constexpr), `SupportsCapability`, `GetMaxTextureDimension`, `Get/SetUnsupported3DGraphicsCallBehavior`, `SetCurrentEffect`, `SetPresentationParameters`, `RecreateRendererForMultiSampleCount`, `GetTypeName` | see B26 |

### `GraphicsResource` / `Texture` (bases)

`GraphicsResource`: `Disposing` event; `getGraphicsDeviceProperty`, `getIsDisposedProperty`,
`get/setNameProperty` (virtual), `get/setTagProperty`, `ToString`, `Dispose()`, protected
`Dispose(bool)`. Copy carries identity, resets lifecycle (C1–C2).

`Texture`: `getFormatProperty`, `getLevelCountProperty`; statics `GetBlockSizeSquaredEXT`,
`GetFormatSizeEXT`, `GetPixelStoreAlignment`, `ValidateGetDataFormat`, `ValidateFormat` (Color-only —
C8); protected `Dispose(bool)` unbinds from both texture collections.

### Texture types

| Type | Transfer | Extras |
|---|---|---|
| `Texture2D` | `SetData`/`GetData` in short and `(level, rect, …)` forms × 18 element types (Color, 12 PackedVector, float, Vector2, Vector4, uint8_t, uint16_t) + `nullptr_t` shims | `FromStream` ×2, `SaveAsPng`/`SaveAsJpeg` ×2 each, `SetDataRGBA`, `CreateFromPixels`, `CreateCpuOnlyForTests`, `CreateWithRendererForTests`, `ReconstructFromCache`, `GetRenderer`/`GetRendererWeak`/`GetCpuPixelsWeak`/`HasRenderer`, `getBoundsProperty` |
| `Texture3D` | `SetData`/`GetData(Color*, …)` only, short + `startIndex` forms | `getWidth/Height/DepthProperty`, `GetRenderer`; ctor throws if `Texture3D` capability false (C16) |
| `TextureCube` | `SetData`/`GetData(CubeMapFace, Color*, …)` | `getSizeProperty`, `DDSFromStreamEXT`, `GetRenderer`/`GetRendererRaw` |
| `RenderTarget2D` | inherits Texture2D's whole family | 2 ctors; `IRenderTarget` overrides (`Width/Height/LevelCount/RenderTargetUsage/DepthStencilFormat/MultiSampleCount`); `getIsContentLostProperty`→false; `ContentLost` event; `GetRenderTargetRenderer` |
| `RenderTargetCube` | inherits TextureCube's | same `IRenderTarget` set; `GetRenderTargetCubeRenderer` |

### Buffers

`VertexBuffer`: 2 ctors; `getBufferUsage/VertexDeclaration/VertexCountProperty`; `SetData`/`GetData`
× 7 vertex types × 2 forms; CNAEXT `SetDataRaw(void*, count, stride)`, `GetRenderer`, `HasRenderer`.
Copy deleted, move noexcept.

`IndexBuffer`: 2 ctors; `getBufferUsage/IndexElementSize/IndexCountProperty`; `SetData`/`GetData` ×
`uint16_t`/`uint32_t` × 2 forms; `GetRenderer`, `HasRenderer`.

`DynamicVertexBuffer` / `DynamicIndexBuffer`: add only `getIsContentLostProperty()`→false, a
`ContentLost` event, and `SetData(..., SetDataOptions)` — destination always starts at offset 0 (C22).

`VertexDeclaration`: 3 ctors; `getVertexStrideProperty`, `GetVertexElements`. `VertexElement`:
offset/format/usage/usageIndex get+set; `GetHashCode()`→0.

`VertexBufferBinding`: `getVertexBufferProperty`, `getVertexOffsetProperty`,
`getInstanceFrequencyProperty`.

`RenderTargetBinding`: 3 ctors; `getRenderTargetProperty`, `getArraySliceProperty`,
`getCubeMapFaceProperty`.

### State objects

All four: default ctor, `GetTypeName`, get/set per property, plus `const` static presets (D3).
`BlendState` 12 properties; `DepthStencilState` 16; `RasterizerState` 6; `SamplerState` 7. No freeze,
no device binding (D1).

### Effects

`Effect` (abstract): 2 ctors (device; device+bytecode→**throws**), `get/setCurrentTechniqueProperty`,
`getParametersProperty` ×2, `getTechniquesProperty` ×2, `Apply()` (CNAEXT), pure-virtual `Clone()`,
`GetTypeName`, `getGraphicsDeviceInternal`, virtual
`GetVertexSource`/`GetFragmentSource`/`GetEffectRendererPtr`/`IsExactStockSpriteEffectEXT`/`FillGpuDrawParams`;
protected pure-virtual `OnApply()`.

`EffectTechnique`: `getNameProperty`, `getPassesProperty` ×2, `getAnnotationsProperty` ×2,
`getIdInternal` (CNAEXT). `EffectPass`: `getNameProperty`, `getAnnotationsProperty` ×2, `Apply()`.

`EffectParameterCollection`: `getCountProperty`, `operator[]` (int ×2, name ×2 → `nullptr` on miss),
`Add`, `GetParameterBySemantic` ×2, iterators. Elements held behind `unique_ptr` so previously-obtained
pointers survive `Add` (`EffectParameterCollection.hpp:14-21`).

`EffectParameter`: name/semantic/rowCount/columnCount/parameterClass/parameterType;
`getElementsProperty`, `getStructureMembersProperty`, `getAnnotationsProperty`;
`GetValueBoolean/Int32/Single/String/Matrix/Vector2/3/4` + `*Array` variants; matching `SetValue`
overloads. CPU-only (E4).

Stock effects — `BasicEffect` (`IEffectMatrices+Fog+Lights`; public
`World`/`View`/`Projection`/`VertexColorEnabled` fields;
Diffuse/Emissive/Specular/SpecularPower/Alpha/Ambient/Lighting/PreferPerPixelLighting/Texture/TextureEnabled/Fog*;
`EnableDefaultLighting`; CNAEXT `SetOwnedTexture`), `AlphaTestEffect` (+`AlphaFunction`,
`ReferenceAlpha`), `DualTextureEffect` (+`Texture2`), `EnvironmentMapEffect` (+`EnvironmentMap`,
`EnvironmentMapAmount`, `EnvironmentMapSpecular`, `FresnelFactor`, `SetOwnedEnvironmentMap`),
`SkinnedEffect` (+`SetBoneTransforms`/`GetBoneTransforms`, `WeightsPerVertex`, `MaxBones=72`),
`SpriteEffect`.

`ShaderEffect` (CNAEXT): ctor(device, vertSrc, fragSrc); `IsEffectValid`, `HasRenderer`;
`SetUniformMat4/Vec4/Vec3/Vec2/Float/Int/FloatArray/Vec2Array`;
`SetTexture(unit, Texture2D&|TextureCube&|Texture3D&)`; `IEffectMatrices`; `get*SourceProperty`;
`Clone` (recompiles).

### SpriteBatch / SpriteFont

`SpriteBatch`: 3 ctors; `Begin` ×5; `End`; `Draw` ×10 (position/rect × optional source rect ×
rotation/origin/scale/effects/depth); `DrawString` ×6 (`std::string`/`StringBuilder` ×
none/uniform-scale/vector-scale); CNAEXT `DrawMeshEXT`.

`SpriteFont`: 1 ctor; `getCharactersProperty`, `get/setDefaultCharacterProperty`,
`get/setLineSpacingProperty`, `get/setSpacingProperty`, `MeasureString` ×2. Not a `GraphicsResource`.

### `graphics-ext` (`CNA::Graphics`)

`CRTEffect`, `DepthEffect`, `AsciiPostProcessEffect`, `PbrMaterial`, `RenderPipelineSettings`, and the
enums `CRTMaskType`, `DepthEffectMode`, `DitherMode`, `AsciiQuantizeMode`, `TonemappingMode`,
`RenderQuality`, `ShadowQuality`.

---

# CONTRADICTIONS

## C1. ★ `docs/fx-bytecode-support-plan.md` is superseded by the FNA3D lane

**Doc:** `:48-60` — "MojoShader's full C source is vendored and readable at
`/rv/data/library/github.com/u3d-community/U3D/…`" and "**No CMake target currently wires this source
into either `cna_graphics` or `sharp-runtime`** — it needs to be vendored properly (see Task 10200)".
`:74` calls MojoShader "a new vendored native dependency" among the things Phase 74 must add.

**Code:** `cmake/ThirdPartyFNA3D.cmake:20-100` fetches FNA3D at pinned tag `3240147` **with
submodules**, hard-fails without `MojoShader/mojoshader.h`, and exports the MojoShader include root plus
`MOJOSHADER_EFFECT_SUPPORT`. `modules/renderers/fna3d/CMakeLists.txt:50-53` links it `PUBLIC`.
`modules/renderers/fna3d/src/Fna3dStockEffects.cpp:9-42` calls `FNA3D_CreateEffect` on real committed
`.fxb` blobs and reads `MOJOSHADER_effectParam` metadata.

**Verdict:** The doc's central "MojoShader is not wired into the build" premise is **false at this SHA**
for the FNA3D configuration. Task 10200 is effectively satisfied for one renderer; the doc has no
awareness of the lane. It is also the one doc whose *conclusion* (the public bytecode constructor
throws) remains correct. — **VERIFIED**

## C2. `AUDIT.md` overclaims where every other doc underclaims

- `AUDIT.md:116/:134/:149/:188` — AlphaTest/DualTexture/EnvironmentMap/Skinned effects marked "API
  surface present (**stub behavior**)". Reality: all four are complete FNA-shaped implementations with
  real dirty-flag and parameter wiring (`AlphaTestEffect.cpp:186` `OnApply()` in a 405-line file;
  `DualTextureEffect.cpp:180`/300; `EnvironmentMapEffect.cpp:286`/492; `SkinnedEffect.cpp:425`/544).
  AUDIT.md contradicts itself at `:997-1063`, which describes `EnvironmentMapEffect` really sampling
  cube maps. — **VERIFIED**
- `AUDIT.md:137` — `| Effect | ✅ | API complete |` while the XNA-canonical content-pipeline constructor
  is an unconditional throw (`Effect.cpp:18-25`). — **VERIFIED**
- `AUDIT.md:974-976` — "`Texture3D`/`TextureCube` inherit `GraphicsResource`, not `Texture`, so neither
  can be bound at all". Reality: `Texture3D.hpp:18` `: public Texture`; `TextureCube.hpp:24`
  `: public Texture`. — **VERIFIED**
- `AUDIT.md:963-967` — "There is no `SetTexture`/`BindSampler` method anywhere in either type, for *any*
  texture type". Reality: `ShaderEffect.hpp:78,87,96`; `IGraphicsRenderer.hpp:701` `BindTexture3D`. — **VERIFIED**
- `AUDIT.md:300-302` — "`GetFormatSizeEXT`/`ValidateGetDataFormat` … have no CNA equivalent at all",
  self-contradicted at `:1182`/`:1228` and by `Texture.hpp:29,37,54`. — **VERIFIED**
- `AUDIT.md:1094,1101-1105,1130-1131` — "`Texture3D`/`TextureCube::GetData` is a total silent no-op on
  both Vulkan and Bgfx"; "Bgfx's lack of any readback API". Reality: `VulkanRenderer.cpp:10935` real
  `vkCmdCopyImageToBuffer`; `BgfxRenderer.cpp:670`/`:766` real `BGFX_TEXTURE_BLIT_DST|READ_BACK` +
  `bgfx::readTexture` (`:700`, `:793`). — **VERIFIED**
- `AUDIT.md:1122-1126` — Vulkan mip levels "hardcoded to 1, `mipMap` dropped". Reality:
  `VulkanRenderer.cpp:10749`. — **VERIFIED**
- `AUDIT.md:198,201` — SDL_Renderer `CreateTexture3D` "never overridden… silently no-ops". Reality:
  overridden at `sdl-renderer/src/SdlRenderer.cpp:885-892`, routing through `HandleUnsupported3DCall`
  (which throws by default). — **VERIFIED**
- `AUDIT.md:424-426,451-453` — Vulkan and Bgfx "still don't override
  `SetSamplerFilter`/`SetSamplerAddressMode`". Reality: `BgfxRenderer.cpp:1578,1583`; 16+ renderers
  implement them. — **VERIFIED**
- **Stale counts:** `:293` "1808/1808 unit tests", `:573` "1842/1842", `:1087`, `:1177`, plus "all 3
  backends" framing throughout. `modules/graphics/tests` alone now holds **85** gtest files and
  `modules/graphics/examples` **75** integration binaries. — **STRONG**
- **Missing from the 100-row inventory entirely:** `PbrEffect`, `SkinnedPbrEffect`, `ColorMatrixEffect`,
  `AnimationPlayer`, `MorphTargetEXT`, `VertexPositionNormalTangentTexture(Skinned)` — zero occurrences
  in AUDIT.md. — **VERIFIED**

## C3. `RenderPipelineSettings` documents a `GraphicsDevice` method that does not exist

**Doc/comment:** `modules/graphics-ext/include/CNA/Graphics/RenderPipelineSettings.hpp:19` — "Construct
via `GraphicsDevice::GetRenderPipelineSettings()` or standalone."

**Code:** `GetRenderPipelineSettings` does not appear anywhere in the repository; `GraphicsDevice.hpp`
has no such member. Grepping `RenderPipelineSettings` outside `modules/graphics-ext` returns nothing —
the class is referenced by no consumer, so the entire settings bag is currently inert. — **VERIFIED**

## C4. `SpriteFont`'s own header says CNA has no XNB pipeline

**Comment:** `SpriteFont.hpp:29-31` — "In XNA this constructor is internal and only invoked by the
content pipeline's SpriteFontReader. **CNA has no XNB pipeline**, so it is exposed for content
readers…"

**Code:** `modules/content/src/Xnb/` holds `XnbBuiltInReaders.cpp` and `XnbDecompression.cpp`;
`modules/content/include/CNA/Internal/Xnb/` holds `XnbHeader.hpp`, `XnbTypeReaderTable.hpp`,
`XnbTypeName.hpp`, `XnbReadLimits.hpp`, `XnbArithmetic.hpp`, plus per-type readers including
`SpriteFontContentTypeReader`; six XNB test suites exist. — **VERIFIED**

Same stale premise in `docs/coverage.md:29,40` ("the XNA binary `.xnb` format is entirely absent"; "A
game depending on `.xnb` content loading will break"), though that doc self-disclaims as a dated
snapshot at `:3-5`. — **VERIFIED**

## C5. `docs/graphicsdevice-fna-audit.md` — gaps still real, one deviation row stale, metadata wrong

- **Still accurate:** `Present(Rectangle?, Rectangle?, IntPtr)`, `Clear(ClearOptions, Vector4, float,
  int)`, and `GetRenderTargetsNoAllocEXT` are all genuinely absent (only `void Present()` at
  `GraphicsDevice.hpp:245`; four Clear overloads at `:220/:228/:236/:242`; zero repo-wide hits for
  `GetRenderTargetsNoAlloc`). Every "missing `CNAEXT` tag" item in its §10 is still untagged (`:228`,
  `:242`, `:265`, `:346`, `:351`, `:1060`, `:1065`). — **VERIFIED**
- **Stale:** `:229` (and `:171`, `:180`, `:182`) — "No `DrawUserPrimitives`/`DrawUserIndexedPrimitives`
  `VertexDeclaration` variants; use raw `void*` overload as substitute". Reality:
  `GraphicsDevice.hpp:445-508` (non-indexed) and `:687-883` (indexed, both index widths), added by the
  REMED work. — **VERIFIED**
- **Metadata wrong:** `:5` cites `include/Microsoft/…/GraphicsDevice.hpp` **(664 lines)**. The path is
  `modules/graphics/include/…` and the file is **1270** lines. Top-level `include/` and `src/` no longer
  exist. Doc's last substantive edit: 2026-06-26; `GraphicsDevice.cpp` last changed 2026-08-11. — **VERIFIED**

## C6. The four `*effect-support.md` docs end on stale "open work" lists

Each is internally reliable *within its phase narrative* but closes with follow-ups that are done:

- `docs/alphatesteffect-support.md:70-78,129,139-142` — Task 887 (`VertexColorEnabled` on Vulkan/Bgfx)
  marked ❌/"still open". Fixed by `6554ab9c2` (2026-07-07), **four days before the doc's own last
  edit**. Evidence: `vulkan/src/shaders/alpha_test_colored3d.vert.glsl:8,33`;
  `bgfx/src/shaders/vs_alpha_test_colored3d.sc:1,20-21`; live dispatch `BgfxRenderer.cpp:4255,4267`,
  `VulkanRenderer.cpp:4724`. — **VERIFIED**
- `docs/dualtextureeffect-support.md:103-106,119,133-137` — Task 889 marked ❌ on all three. Fixed
  `ceacce7a9` (2026-07-11); `plan_graphics.md:439` itself marks it ✅ CLOSED. Evidence:
  `EasyGLRenderer.cpp:5283,5294,5330`; `vulkan/src/shaders/dual_texture_colored3d.vert.glsl:8,36`;
  `bgfx/src/shaders/vs_dual_texture_colored3d.sc:1,20-21`. — **VERIFIED**
- `docs/environmentmapeffect-support.md:171-174` — Task 892 (Bgfx lit-textured normal transform) listed
  open. Fixed `93413f569` (2026-07-07): `bgfx/src/shaders/vs_lit_textured3d.sc:22-26` now uses the
  inverse-transpose normal matrix. — **VERIFIED**
- `docs/basiceffect-support.md:145-147` — asserts Tasks 890/891/893 "**remain genuinely open**", while
  `docs/environmentmapeffect-support.md:165-170` marks 890/891 fixed and the code confirms all three
  (`EnvironmentMapEffect.cpp:439-447`; `SkinnedEffect.cpp:340-360`; consumed at
  `vulkan/src/shaders/skinned3d.frag.glsl:45-49`, `bgfx/src/shaders/fs_skinned3d.sc:43`). **Inter-doc
  contradiction.** — **VERIFIED**
- **Still accurate, do not "fix":** `alphatesteffect-support.md:41-45` /
  `dualtextureeffect-support.md:46` — Bgfx's
  `SetDepthTestEnabled`/`SetBlendEnabled`/`SetDepthWriteEnabled` really are unconditional-throw stubs
  (`BgfxRenderer.cpp:3036-3038`, message at `:2987-2992`). — **VERIFIED**

## C7. `docs/depthstencilstate-support.md` — three of four "open" items closed

- `:152,167-168` — Task 871 (`Clear` ignores `ClearOptions::Stencil`) marked ❌ everywhere. Fixed:
  `GraphicsDevice.cpp:513-545` with a 7-way dispatch; renderer implementations at
  `EasyGLRenderer.cpp:6643`, `VulkanRenderer.cpp:9148`, `BgfxRenderer.cpp:3007`; interface
  `IGraphicsRenderer.hpp:1619,1641`. `plan_graphics.md:398` marks it ✅ CLOSED 2026-07-10 — *the day
  before* the doc's last edit. — **VERIFIED**
- `:161-162,30` — Task 866 (`RasterizerState` presets lack `Name`). Fixed `161bb7a7e` (2026-07-04):
  `RasterizerState.cpp:6-8` all three presets pass names. `docs/rasterizerstate-support.md:22` says
  "This closes Task 866 entirely" — yet `docs/sampler-state-support.md:28,162` **also** still lists it
  open. — **VERIFIED**
- `:125-131,151` — Task 872: "`IGraphicsRenderer` has **no** `SetReferenceStencil` method at all".
  Reality: `IGraphicsRenderer.hpp:1564` declares it; `GraphicsDevice.cpp:2770-2771` calls it; **Bgfx
  overrides it** (`BgfxRenderer.cpp:2579-2583`). **EasyGL genuinely still lacks an override**, so the
  EasyGL half of the row is correct. The same stale claim survives in `plan_graphics.md:407` and in a
  source comment at `easygl/examples/easygl_graphicsdevice_reference_stencil_test.cpp:27`.
  **PARTIALLY STALE.** — **VERIFIED**
- **Still accurate:** Task 869 (by-value state storage) — `GraphicsDevice.hpp:1137-1139`. — **VERIFIED**

## C8. `docs/graphics-renderer-feature-matrix.md` self-labels "Master, up-to-date" but carries dead rows

`:3` calls itself the master matrix, and `basiceffect-support.md:10-11` /
`graphics-compatibility-report.md:12-13` both redirect readers to it as the current source of truth. Yet
`:172` still marks `Clear`+`ClearOptions::Stencil` "❌ ignored, all 3 (Task 871, open)" and
`:171`/`:301` still marks `GraphicsDevice.ReferenceStencil` "❌ no renderer connection (Task 872, open)"
in the Bgfx column — both refuted above. It also has **zero mentions of FNA3D**, the renderer merged the
day of this SHA, and covers 4 renderers where there are 42 families. — **VERIFIED**

## C9. `plan_graphics.md` describes an architecture that no longer exists

- References `IGraphicsBackend` **18×** and `*Backend` class names **80×** (`VulkanGraphicsBackend`,
  `EasyGLSpriteBatchBackend`, …). `grep -rn "IGraphicsBackend" modules/` returns **zero hits** — the
  rename to `IGraphicsRenderer`/`*Renderer` landed in `57aee5f88` (2026-08-10).
- `:3-4` scopes itself to "the four established backends … and the experimental fifth WebGPU backend";
  `modules/renderers/` holds 42 families.
- `:45` still says "~44% done as of 2026-07-02".
- Four tasks still `⬜` that are fully implemented with dedicated per-renderer pixel tests: Task 890
  (`:440`, `EnvironmentMapEffect.cpp:439-447`), Task 893 (`:443`, `SkinnedEffect.cpp:340-360`), Task 894
  (`:444`, `vulkan/src/shaders/skinned3d.frag.glsl:53-54`), Task 895 (`:445`,
  `skinned3d.vert.glsl:42,51` + `VulkanRenderer.cpp:9845` + `EasyGLRenderer.cpp:6471`).
  `docs/skinnedeffect-support.md:151-171` already marks 893/894/895 fixed — another inter-doc
  contradiction.
- `:1021` Task 1113 is **half**-fixed: GDI-050 (`GraphicsDevice.cpp:450-455,497-504`) fixed the "silently
  deletes Stencil too" half; the "depth/stencil-only clear becomes a silent no-op" half remains real
  (B11). — **VERIFIED** (the ⬜ rows and the architecture drift); **STRONG** (the half-fix reading)

## C10. `known_bugs.md` — one live entry already fixed, one with an actively wrong instruction

- `:27-52` — "Multiple `SpriteBatch` `Begin`/`End` in one frame discards all but the last", with **no**
  `— FIXED` marker and not covered by the 2026-08-09 LLGL disposition at `:3-25`. Fixed by Task 664:
  `vulkan/examples/vulkan_spritebatch_multi_begin_end_test.cpp:2-17` documents the per-`Begin`/`End`
  `BatchSnapshot` fix; registered as a CTest at `vulkan/examples/CMakeLists.txt:618`; accumulating cursor
  at `VulkanRenderer.cpp:7544-7545`. — **VERIFIED**
- `:339,346-360,388` — LLGL-48 still headed "— OPEN" with "**do not register it again until the
  underlying issue is fixed**". Reality: the 16-bit key collision is fixed
  (`LlglRenderer.cpp:2882-2910`, tuple key with independent 64-bit budgets), the forbidden test **is**
  registered (`llgl/examples/CMakeLists.txt:293`), and the cited `cmake/Tests/LlglTests.cmake` no longer
  exists. The file's own `:8`/`:24-25` pre-excuse the stale headings, but the *instruction* is actively
  misleading. Same shape at `:1483` (LLGL-53) and `:1645` (LLGL-55). — **VERIFIED**

## C11. `docs/graphics-compatibility-report.md` — self-disclaimed stale, correctly

`:11-12` explicitly says "**Do not treat the percentages and bug counts in this report as current**".
All five of its "confirmed bugs" verify as fixed (Task 921 `IndexElementSize.hpp:10-12`; Task 868
`VulkanRenderer.cpp:3872,3893`; Task 918 `EasyGLRenderer.cpp:4048-4075`; Task 916 `Model.cpp:38`; Task
922 `SpriteBatch.hpp:228,245,264,286,302` all `std::optional<Rectangle>`), so §2's table (`:61-66`),
§4's `46.2%/42.3%/7.7%` (`:100-109`) and §6's "10 named items" (`:148-168`) are arithmetically dead.
**Disclosed**, not hidden. — **VERIFIED**

## C12. Unnamed support docs — the highest-yield offenders

- `docs/rendertarget-support.md:213-232` — **8 of 9** "open, tracked follow-up" tasks done (873/874 Bgfx
  handle casts → `BgfxRenderer.hpp:218,246`; 875 Vulkan clear-only RT →
  `VulkanRenderer.cpp:7419,8266,8980,9127`; 877 DepthStencilFormat; 878 RT mips →
  `VulkanRenderer.cpp:915,8542`; 879 RT MSAA; 880 Viewport "zero GPU wiring on all 3" → wired on all
  three; 881 MRT cap → `GraphicsDevice.cpp:83,2918`; 145 EasyGL MRT →
  `easygl/examples/easygl_mrt_test.cpp` registered). Its `:25-31` premise ("`RenderTargetCube` inherits
  `GraphicsResource` directly, not `Texture`", "the binding is never recorded") is false
  (`RenderTargetCube.hpp:20`, `RenderTargetCube.cpp:78-81`, `GraphicsDevice.cpp:2913`). Only Task 876 is
  **UNCLEAR**. — **VERIFIED**
- `docs/texture3d-texturecube-support.md` — all 5 future-work items done. Its `:142-145` claim that
  `TextureCube` DDS loading is "a confirmed non-functional stub… always returns a blank 1×1 `Color` cube
  map" is flatly wrong: `TextureCube.cpp:322-380+` is a real DDS parser mirroring FNA's
  `Texture.ParseDDS`, with magic/header/caps2 validation at `:336-340`. Its `:36-39` (`SurfaceFormat`
  still ignored) **is** accurate. — **VERIFIED**
- `docs/vertex-format-support.md:21-24` — its central premise, "all four renderers select their layout
  from the **byte stride** … `VertexDeclaration` is not forwarded to `DrawPrimitivesEx`", is obsolete:
  `IGraphicsRenderer.hpp:142` `virtual void SetVertexDeclaration(const VertexDeclaration&) = 0;` is
  **pure virtual and mandatory**. Its Vulkan "silently skipped" claim (`:46-47`) is now a hard refusal
  (`VulkanRenderer.cpp:9711-9714`), and Tangent/Binormal "❌ no shader slot" (`:101-102`) is refuted by
  `vulkan/src/shaders/pbr3d.vert.glsl:8`. — **VERIFIED**
- `docs/spritefont-support.md:98-104,120` — rests on two false statements: "`SpriteEffects` is a plain
  `enum class` with no bitwise operators" (they exist, `SpriteEffects.hpp:25,53`) and "the axis tables
  deliberately only have 3 entries… index 3 unreachable" (all four are `[4]`,
  `SpriteBatch.cpp:549-552`). Its `:130-134` "neither renderer has its own dedicated SpriteFont
  pixel-test pass" is also false. — **VERIFIED**
- `docs/graphicsresource-fna-audit.md:12,48-49` — "No resource list exists on `GraphicsDevice`.
  Resources are not notified on device reset or device disposal". Refuted by `GraphicsResource.cpp:12,97`
  and `GraphicsDevice.cpp:674-711`. Its Gap 2 (`GraphicsDeviceResetting()`) **is** still real — zero hits
  repo-wide. Oldest graphics doc in the tree (2026-06-26). — **VERIFIED**
- `docs/rasterizerstate-support.md:134-137` — "`DepthBias` still has no EasyGL pixel test registered".
  `easygl/examples/easygl_depth_bias_test.cpp` exists and is registered as `EasyGL_DepthBias`
  (`easygl/examples/CMakeLists.txt:1620-1622`). — **VERIFIED**
- `docs/shader-effect-vs-fx-bytecode.md:44-46` — claims the `ShaderEffect` path "is EasyGL/Vulkan only
  today". At this SHA D3D9/D3D11/D3D12, SDL_GPU, LLGL, sokol, magnum, opengl2 and opengl4 all have
  working paths (F8). Its Bgfx no-op-stub claim (`:43-44`) **is** still accurate. — **STRONG**

## C13. "Bgfx has no readback API" is a legend repeated across four docs

`docs/depthstencilstate-support.md:156-157`, `docs/rasterizerstate-support.md:124-126`,
`docs/sampler-state-support.md:157-158`, `docs/texture3d-texturecube-support.md:71-72`. Every
`🔍 not pixel-verified (no readback API)` Bgfx cell downstream is stale for that reason alone. Reality:
`BgfxRenderer.cpp:317` `ReadBackbuffer`, `:502` `ReadTextureRegionEXT`, `:564/:700/:793`
`bgfx::readTexture` with `BLIT_DST|READ_BACK` staging; **101 of 113** files in
`modules/renderers/bgfx/examples/` call `GetBackBufferData`. — **STRONG**

## C14. `plan_moderngraphics.md` does not exist

Not present, and `git log --diff-filter=D` finds no deletion — it never existed. — **VERIFIED**

---

# Doc freshness

Naive "last commit" dates mislead: `57aee5f88` / `2ecbca579` / `d588fd332` (all 2026-08-10) were bulk
terminology renames touching docs and code alike.

| Doc | Last commit | Last **substantive** edit | Governing code | Verdict |
|---|---|---|---|---|
| `docs/graphicsresource-fna-audit.md` | 2026-06-26 | **2026-06-26** | 2026-08-10 | **VERY STALE** |
| `docs/graphicsdevice-fna-audit.md` | 2026-08-10 | **2026-06-26** | **2026-08-11** | **VERY STALE** |
| `AUDIT.md` | 2026-07-18 | **2026-07-18** | 2026-08-10/11 | **VERY STALE + only doc that overclaims** |
| `plan_graphics.md` | 2026-08-04 | **2026-07-18** | 2026-08-10/11 | **STALE** — removed architecture, 4 ⬜ rows done |
| `docs/basiceffect-support.md` | 2026-08-10 | **2026-07-11** | 2026-08-10 | **STALE** (open-work list) |
| `docs/alphatesteffect-support.md` | 2026-08-10 | **2026-07-11** | 2026-08-10 | **STALE** |
| `docs/dualtextureeffect-support.md` | 2026-08-10 | **2026-07-11** | 2026-08-10 | **STALE** |
| `docs/environmentmapeffect-support.md` | 2026-08-10 | **2026-07-11** | 2026-08-10 | **STALE** |
| `docs/depthstencilstate-support.md` | 2026-08-10 | **2026-07-11** | **2026-08-11** | **STALE** (3 of 4) |
| `docs/rendertarget-support.md` | 2026-08-10 | 2026-07-11 | 2026-08-10 | **STALE** (8 of 9) |
| `docs/texture3d-texturecube-support.md` | 2026-08-10 | ~2026-07-18 | 2026-08-10 | **STALE** (5 of 5) |
| `docs/vertex-format-support.md` | 2026-08-10 | ~2026-07 | **2026-08-11** | **STALE** — core premise obsolete |
| `docs/spritefont-support.md` | 2026-08-10 | ~2026-07 | 2026-08-10 | **STALE** — §7 factually wrong |
| `docs/fx-bytecode-support-plan.md` | 2026-08-10 (rename) | pre-FNA3D lane | **2026-08-11** | **SUPERSEDED** on its build premise; correct on its conclusion |
| `docs/graphics-renderer-feature-matrix.md` | 2026-08-10 | **2026-08-03** | **2026-08-11** | **PARTIALLY STALE**, self-labels "Master, up-to-date" |
| `docs/sampler-state-support.md` | 2026-08-10 | ~2026-07-18 | 2026-08-10 | **PARTIALLY STALE** |
| `docs/rasterizerstate-support.md` | 2026-08-10 | ~2026-07-18 | 2026-08-10 | **PARTIALLY STALE** |
| `docs/graphics-compatibility-report.md` | 2026-08-10 | 2026-07-11 | — | **SELF-DISCLAIMED STALE** |
| `docs/coverage.md` | 2026-08-10 | 2026-07-17 | — | **SELF-DISCLAIMED STALE** |
| `known_bugs.md` | 2026-08-09 | **2026-08-09** | 2026-08-10 | **MOSTLY FRESH** (2 exceptions) |
| `docs/skinnedeffect-support.md` | 2026-08-10 | ~2026-07-18 | 2026-08-10 | **ACCURATE** |
| `docs/occlusionquery-support.md` | 2026-08-10 | ~2026-08-10 | 2026-08-10 | **ACCURATE** |
| `docs/surface-format-support.md` | 2026-08-10 | ~2026-08-10 | 2026-08-10 | **ACCURATE** (covers 4 of 42) |
| `docs/viewport-displaymode-adapter-support.md` | 2026-08-10 | ~2026-08-10 | 2026-08-10 | **ACCURATE** |
| `docs/metal-shader-effect-contract.md` | — | current | — | **ACCURATE** (normative) |
| `docs/skia-glsl-to-sksl-translator-contract.md` | — | current | — | **ACCURATE** (normative) |
| `NEXT.md` | 2026-08-11 | 2026-08-11 | — | **ACCURATE** — the only graphics status doc that survives verification intact |

**Rule of thumb for the book:** trust the *normative contract* docs (`metal-shader-effect-contract`,
`skia-*-contract`, `fna3d/effects/README.md`, `blend2d-renderer.md`) and `NEXT.md`. Treat `AUDIT.md`,
`plan_graphics.md`, and `docs/graphics-renderer-feature-matrix.md` as unreliable despite their
authoritative framing. The richest and most accurate documentation in this area is in the **source
comments**, which routinely carry the task number, the symptom, the FNA reference, and the measurement.

---

# BOOK IMPACT

## The headline: "Shaders and the .fx Bytecode Gap" (ch15, 379 lines) must be rewritten and retitled

The current chapter's structure — `What real XNA actually ships` → `Why Effect(GraphicsDevice&, byte[])
always throws in CNA` → `The measurable cost of the gap` → `What does exist today: ShaderEffect` →
`The honest summary` — rests on a premise that is **now only one-quarter true**.

**What is still exactly right (keep, with citations refreshed):**

- `Effect(GraphicsDevice&, std::vector<bytecs>)` throws `NotImplementedException` unconditionally
  (`Effect.cpp:18-26`). Unchanged.
- The general `EffectReader` is refused by name at the content layer
  (`KnownUnsupportedContentTypeReader.cpp:41-47`). Worth *adding* — it's a cleaner demonstration of the
  gap than the constructor.
- `ShaderEffect` is the user-facing alternative, and its worked examples remain valid.

**What is now wrong or badly incomplete:**

1. **CNA executes real Microsoft XNA effect bytecode at this SHA.** Six `.fxb` blobs from FNA are
   committed (`modules/renderers/fna3d/effects/`, 106 KB) and run through MojoShader via
   `FNA3D_CreateEffect` (`Fna3dStockEffects.cpp:9-42`). MojoShader is a pinned, fetched,
   submodule-recursed build dependency (`cmake/ThirdPartyFNA3D.cmake`). A chapter titled "the .fx
   bytecode gap" that does not mention this is now misleading.
2. **CNA also reproduces XNA's shaders from Microsoft's own `.fx` HLSL sources, and proves it
   byte-for-byte.** `modules/renderers/directx9/src/shaders/xna/` vendors the six stock-effect `.fx`
   files plus their `.fxh` includes; `compare_against_fxb.py:11-16` records **61 of 66 shaders matching
   Microsoft's shipped instruction stream exactly** after comment-token stripping, with the five misses
   attributed to `d3dcompiler_47` vs `D3DCompiler_43`. That is one of the strongest empirical results
   anywhere in this project and belongs in the book.
3. **The `ShaderEffect` path is far wider than "EasyGL/Vulkan"** — 22 renderers override
   `CreateEffectRenderer`, in at least six distinct dialects (raw GLSL, GLSL→SPIR-V via libshaderc, raw
   HLSL via `D3DCompile`, pre-compiled SPIR-V, marker-gated SkSL, and several deliberate rejections).
   And Vulkan's `CreateEffectRenderer` takes **SPIR-V bytes**, not GLSL — a trap worth a callout box.
4. **The real gap is `GpuDrawParams`, not the constructor.** The chapter frames the gap as a missing
   parser. The deeper architectural fact is that CNA has no shader-parameter plumbing at all: `Effect` →
   renderer communication is a single closed struct (`IGraphicsRenderer.hpp:846-990+`) that a renderer
   switch-cases into pre-built shader variants. Even a perfect MojoShader parser would need somewhere to
   *put* the reflected parameters. `docs/fx-bytecode-support-plan.md:70-84` says exactly this, and it is
   the chapter's strongest missing argument.

**Recommended shape.** Retitle to something like **"Shaders: Four Answers to XNA's `.fx`"**, and
restructure around the four strands the code actually implements: (1) *reimplement* — hand-authored
per-renderer shaders driven by `GpuDrawParams`, the default for ~20 renderers; (2) *recompile
Microsoft's sources* — D3D9's vendored `.fx` → SM2/SM3 with the 61/66 byte-comparison as evidence;
(3) *execute Microsoft's bytecode* — FNA3D + MojoShader, and why it costs you custom effects entirely
(`CustomEffects == false`); (4) *bypass `.fx`* — `ShaderEffect`, with the per-renderer dialect matrix.
Close on what remains genuinely absent: a user's own compiled `.fx`, and the parameter-plumbing
prerequisite.

**Split recommendation:** likely yes. The four-strand shader story and the `.fx`-bytecode gap are now
separable, and the per-renderer shader-delivery matrix (F8/F9) is substantial enough to anchor its own
chapter or a long Part IV section. If Part III stays at seven chapters, the shader-delivery matrix fits
better in Part IV (backends) with ch15 keeping the API-level `Effect`/`ShaderEffect`/`.fx` narrative.

## Other chapters needing work

**ch09 GraphicsDevice (1517 lines) — moderate revision.** Add: the Clear masking rule and its
silent-no-op edge (B11); the `Reset()`-is-not-a-reset finding with the
`RecreateRendererForMultiSampleCount` doc comment as the primary source (B8); the transactional rollback
(B9); `GetBackBufferData` sizing from `PresentationParameters` and the `CNA_BACKBUFFER_READ_TRACE` hook
(B13); the `SetRenderTarget` bypass fix landed *at this SHA* (B14 — a good "how this project finds its
own bugs" story); the multi-stream capability gate and the offset-fold (B19–B20); the
`Ensure3DSupported` / `HandleUnsupported3DCall` / `Unsupported3DGraphicsCallBehavior` policy (I4); and —
most importantly — that `Textures[]` never reaches the GPU (B22). Correct any claim that `DrawUser*` has
no `VertexDeclaration` overloads.

**ch10 SpriteBatch (530 lines) — substantial revision.** The integer-destination truncation (G8) is the
single most important omission: it is a real, user-visible fidelity divergence, and the
truncate-vs-round split between `Draw` and `DrawString` is a genuinely surprising detail. Add the
`Begin` state-transaction and the three parameters that were historically discarded (G3–G5); the
`SpriteSortMode::Texture` pointer sort (G7); the premultiplied-alpha mismatch (C25/G — CNA never
premultiplies, but `Begin()` defaults to the premultiplied `AlphaBlend` equation); and `DrawMeshEXT` as
a Skia-only CNAEXT (G13). The `SpriteEffect::OnApply` no-op (E6) belongs here as a sidebar — it is
harmless only because renderers own the transform.

**ch11 Textures and RenderTargets (572 lines) — substantial revision.** The `SurfaceFormat` finding (C8)
is the biggest correction in this area: the enum has 27 values and, on every renderer but Skia, exactly
**one** of them works. Any book text implying broad format support is wrong. Add: DXT/BC7 are
CPU-decompressed at load, never uploaded compressed (C9); the null-object convention for
`RenderTarget2D`/`Texture3D`/`TextureCube` and why `Texture3D` breaks it by throwing at construction
(C16, C18); `ClosestMSAAPower` rounding down with 1→0 (C18); viewport/scissor reset on every target
switch (B15); disposing a bound target throws (C20); `IsContentLost` is hardcoded false everywhere
(C21).

**ch13 Stock Effects (578 lines) — moderate revision.** Correct any "stub" framing (C2). Add the
`GpuDrawParams` architecture (E3) — arguably this chapter's spine. Add the inconsistent parameter
collections, especially that `BasicEffect` has none (E5); the
one-technique/one-pass-named-"P0" reality (E7); `EffectParameter`'s CPU-only nature (E4); `Clone()`
returning a raw owning pointer (E10); the CNAEXT effect family (PbrEffect, SkinnedPbrEffect,
ColorMatrixEffect) (E2); and the FNA-formula fidelity comments in `BasicEffect::FillGpuDrawParams`
(E12), which are excellent quotable material.

**ch14 State Objects (397 lines) — targeted revision.** The by-value storage and total absence of
freeze/binding semantics (D1–D2) is the chapter's central missing fact and a clean C++-vs-C# porting
lesson. Add the dead properties (`RasterizerState.MultiSampleAntiAlias`, `GraphicsDevice.MultiSampleMask`,
`SamplerState.AddressW` — B24); the commit-after-native-success pattern (B25); and the `BlendState`
static-initialization-order anecdote (D5).

**ch12 Models and Meshes** — verify against `SkinnedModelEXT`, `AnimationPlayer`, `MorphTargetEXT`, and
`EffectMaterial`, none of which appear in `AUDIT.md`'s inventory.

**Part IV (backends, ch16–ch25) — significant expansion needed.** The book covers 10 backends; the repo
has 42 renderer families under 46 CMake identities. New since the book's chapter list, at minimum:
**FNA3D** (which deserves its own treatment — it is the only renderer running XNA's own shader
programs), plus blend2d, diligent, llgl, magnum, metal, openvg, portablegl, skia, sokol, svg-dom,
wicked, glide, gdi, the full DirectX 1–12 legacy family, and opengl1/2/4/es1/es2. The renderer-selection
model (A1–A2 — one renderer per build; 46 identities over 42 families, easygl carrying five GL-profile
identities) should be stated once, prominently, in ch16.

**New material that has no home yet.** Two topics are strong enough to warrant new sections: (a) **the
vertex-stream layer** (A5–A6) — that `Color` and `IVertexType` are polymorphic in C++, so nothing is
blittable, so CNA needs a parallel `static_assert`ed stream-struct layer, and why `GetBackBufferData` has
to unpack bytes into `Color(r,g,b,a)`; this is one of the cleanest "what porting C# to C++ actually
costs" stories in the whole codebase. (b) **the capability/policy system** (I2–I4) —
`GraphicsCapability`'s 12 entries, the opt-out `true` default and the two renderers that over-claim
because of it (F12), and the `Throw`/`WarnAndStub` policy.

## Two defects worth reporting upstream regardless of the book

- `SpriteEffect::OnApply()` is unreachable past its first line, because `"MatrixTransform"` is never
  added to the parameter collection (E6). Currently harmless; would become a real bug the moment a
  renderer stopped supplying the transform itself.
- `webgpu` and `bgfx` report `GraphicsCapability::CustomEffects == true` by inheriting the base default
  while being unable to honour it (F12). Every other non-supporting renderer returns `false` explicitly.
  `SupportsCapability` is documented as the thing to query *instead of* catching an exception, which
  makes this specifically harmful.
- Minor: `scripts/verify_hlsl_shaders_native_msvc.py:30` points at a `src/` tree that no longer exists,
  so the script cannot run (F11).

## Coverage gap in this audit

The per-renderer **draw-path** divergence matrix — which renderers implement `DrawPrimitivesEx` vs.
silently fall back to `DrawColoredPrimitives`; which implement render targets, occlusion queries, MRT —
is the one part of the brief that could not be completed: the parallel lane assigned to it did not
return. The renderer *interface* semantics are fully covered (I1–I10) and the per-renderer *shader*
matrix is complete (F8–F9), but a draw-path matrix across all 42 families needs a dedicated follow-up
pass. Given fact I7 — that the effect-aware draw defaults **silently degrade** rather than fail — that
matrix is worth commissioning before writing Part IV, because a renderer that has not implemented
`DrawPrimitivesEx` will render an untextured, unlit approximation of any stock effect with no error at
all, and nothing in the current documentation identifies which renderers those are.
