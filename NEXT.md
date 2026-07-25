# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **505 physical PDF pages, 49 chapters, 6 appendices**.
- After the batch commit, the local branch is ahead of `origin/develop` by thirteen coherent
  documentation commits:
  roadmap, ShaderEffect/D3D ABI, general capability matrix, MSAA/anisotropy, buffer
  contracts, volume/cube readback contracts, and RenderTargetCube upload/transition
  contracts, followed by Texture2D update contracts, instancing/vertex binding, and input
  coordinate routing, public backbuffer readback, swap-interval contracts, and presentation
  format/fullscreen contracts.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

The `PresentationParameters.BackBufferFormat` / `DepthStencilFormat` / `IsFullScreen` and
`IGraphicsBackend::UpdatePresentationFormatEXT()` audit is complete:

- `GraphicsDevice::Reset()` first stores the whole requested object, applies fullscreen and
  non-Android size to the SDL window, reapplies virtual resolution/MSAA/interval, and calls
  the presentation-format hook last. SDL fullscreen failure is cleared and non-fatal; size
  failure throws. Stored state therefore cannot be used as an actual window query.
- Only D3D9 overrides the otherwise-empty hook. It maps color/depth enums into real D3D9
  presentation parameters, sets `Windowed = !IsFullScreen`, and immediately resets the
  device. The smoke suite observes a real D24S8 surface after manager-driven setup. An
  unsupported combination can nevertheless fail after public requested state changed.
- The other thirteen products do not provide per-field runtime format selection. Their
  native results range from no attachments (the 2D-only and Headless products), through
  fixed CPU/DirectX/WebGPU formats, to driver/platform-selected SDL, GL, bgfx, Vulkan,
  SDL_gpu, or Canvas targets. Several allocate real depth even for public `None`; WebGPU
  can select an sRGB surface while public state reports `Color`.
- Fullscreen remains a separate SDL-window route for windowed products, even with an empty
  backend hook. D3D11/12 may acquire a fullscreen-sized SDL window but never call DXGI
  `SetFullscreenState`; DX3 remains at `DDSCL_NORMAL`. Software and Headless have no window.
- Eager `Game` construction starts with bare `Color`/`None`/windowed parameters before the
  manager's `Color`/`Depth24`/windowed defaults are applied. D3D9's hook upgrades the native
  device; the remaining products keep their independent attachment policies.
- Existing EasyGL depth/fullscreen and SDL Renderer fullscreen tests explicitly prove stored
  round-trip/no-throw/continued rendering, not native format or display acceptance. D3D9 is
  the strong native exception. No dedicated test was found that requests two different
  backbuffer formats and queries the resulting native formats. FNA instead submits one
  complete native presentation structure to `FNA3D_ResetBackbuffer`.
- Ch.6 and Ch.9 now explain the caller-visible requested/actual split. Ch.16 contains the
  complete fourteen-product color/depth/window/evidence matrix. Ch.17--23 and Ch.25 record
  the applicable native policy, Ch.21's stale Vulkan render-target comparison is corrected,
  and Appendix A carries the concise warning.
- Final validation: a forced `latexmk` rebuild produces **505 pages**; targeted undefined-
  reference and duplicate-label checks are empty; makeindex accepts **2,069 entries** with
  zero rejected and zero warnings; `git diff --check` passes and the recorded chapter counts
  match `wc -l`.
  Rendered pages 64, 113, 190--192, 209, 216, 227, 233, 243, 252, 264, 287, and 470 have no
  clipping, cell collision, page-edge spill, malformed heading, running-header collision, or
  folio defect. The matrix header repeats correctly on both continuation pages.

## Recommended next starting point

Re-inventory the remaining live defaults in
`include/CNA/Internal/Backends/Common/IGraphicsBackend.hpp` against the now-large Ch.16
coverage. Prefer a contract with a real public caller and divergent native effects over an
already-covered factory/null/default. The state-application and dynamic-state families are
the first candidates to compare against Ch.14; avoid repeating its existing
`SetReferenceStencil` finding. Record any selected method and preliminary backend inventory
here before changing prose.

## Previous swap-interval batch

The `PresentationParameters.PresentationInterval` /
`IGraphicsBackend::SetSwapInterval()` audit is complete:

- The public conversion is exact (`Immediate` to 0, `Default`/`One` to 1, `Two` to 2).
  `GraphicsDeviceManager::SynchronizeWithVerticalRetrace` itself selects only `One` or
  `Immediate`; callers need explicit `PresentationParameters` or
  `PreparingDeviceSettings` to request `Two`.
- Both backend construction and the ordinary `GraphicsDevice::Reset()` path now receive the
  selected value. The latter forwarding was a real prior cross-backend repair, but the
  interface default is still a silent no-op.
- Nine products override the runtime hook: SDL_RENDERER, ASCII, EASYGL, BGFX, WEBGPU,
  SDL_GPU, and D3D9/11/12. VULKAN, CANVAS, DX3, SOFTWARE, and HEADLESS inherit the no-op.
  Vulkan uniquely consumes the initial construction value while ignoring later resets.
- The semantic split is wider than override/no-override: D3D9 maps interval 2 literally;
  SDL Renderer attempts it at runtime with a fallback to 1; EasyGL submits the exact value
  but ignores driver rejection. BGFX, WebGPU, SDL GPU, and D3D11/12 collapse every positive
  interval to ordinary VSync. SDL Renderer's constructor also collapses `Two`, even though
  its runtime handler no longer does. Vulkan's initial `Two` means FIFO_RELAXED, not
  half-refresh pacing.
- D3D9's exact mapping is incomplete and unsafe: it checks neither
  `D3DCAPS9::PresentationIntervals` nor the native rule that windowed mode supports only
  Default/Immediate/One. A rejected reset is logged and retried on every present while the
  public property remains `Two`. D3D11/12 could pass 2 directly because DXGI supports
  intervals 1--4; their Boolean collapse is CNA-imposed.
- Validation evidence is uneven. EasyGL proves real 0/positive context state for the public
  manager/reset path; SDL Renderer proves routing and stored parameters but has no public
  actual-state query. The SDL GPU suite's old roughly-one-second-per-frame virtual-display
  timeout demonstrates that public VSync selection affects real presentation, but no located
  test proves interval 2. Most other rows remain source-proven only.
- Ch.6 separates fixed timestep from presentation blocking; Ch.9 distinguishes requested
  from applied state; Ch.16 carries the complete fourteen-product construction/runtime/
  evidence matrix; Ch.17, Ch.19, Ch.23, and Appendix A now agree with it.

## Previous backbuffer-readback batch

The public `GraphicsDevice::GetBackBufferData()` /
`IGraphicsBackend::ReadBackbuffer()` audit is complete:

- Twelve of the fourteen backend products override the method. `SDL_GPU` and `D3D12` inherit
  the default `runtime_error`; neither public path has back-buffer readback.
- The name is not a uniform semantic contract. SDL_Renderer, ASCII, Software, EasyGL, DX3,
  and browser Canvas read the currently bound render target when one is active; Vulkan,
  BGFX, D3D11, WebGPU, and D3D9 always read the real swapchain/backbuffer; Headless returns
  only a synthetic image of the last global clear. FNA always routes to its actual
  backbuffer read API.
- The shared wrapper validates only `data != nullptr`, `elementCount >= width*height`, and
  the stored presentation format. It does not reject a negative `startIndex`, prove caller
  capacity through `startIndex + pixelCount`, validate the rectangle against the target,
  or guard `width*height` overflow. A null rectangle takes dimensions from
  `GetViewportSize()`, which several scaled/high-density backends do not express in the same
  coordinate space as their native readback.
- Exact-pixel proof is strongest where tests discriminate the source: Software and DX3 read
  bound target then restored backbuffer; Vulkan explicitly proves that it always reads the
  swapchain. ASCII returns its pre-quantized game target, not the displayed glyph grid.
  Canvas has no real browser/DOM proof; Headless has no dedicated public pixel assertion;
  D3D12's exact smoke readbacks call render-target helpers directly.
- Ch.9 now labels its worked bound-target probe as Software-specific and records all caller
  preconditions. Ch.16 carries the complete target/region/evidence matrix and FNA contrast;
  Ch.22 and Ch.23 distinguish resource readback from the missing SDL GPU/D3D12 public
  bridge; Appendix A has the concise warning.

## Previous input-coordinate batch

The logical/window input-coordinate audit is complete:

- `Mouse::SetPosition()` and `SdlInputBridge` first use an SDL renderer associated with the
  window, then the `IGraphicsBackend` registry, then raw pass-through. The two backend
  transform defaults return `false`.
- SDL_Renderer and ASCII use SDL's complete logical-presentation transform. DX3 unexpectedly
  uses the same route because `free-direct`'s supposedly private renderer remains discoverable
  through `SDL_GetRenderer(window)`; its dedicated test calls the backend methods directly and
  therefore does not prove public routing. Before DX3's first `Present()`, that renderer has
  not yet been assigned a logical presentation and public input is still pass-through.
- EasyGL and Canvas register height-only transforms that are exact for
  `FixedHeightDynamicWidth` but do not implement their other stored presentation modes.
  WebGPU and SDL GPU register the full five-mode viewport math in physical pixels, but SDL
  events and cursor warps use window coordinates. The two spaces differ on a high-pixel-density
  window, producing a density-factor error in both directions. They also return `false` for a
  point in a letterbox bar; the caller then substitutes raw window coordinates instead of the
  already-computed out-of-content logical coordinates.
- Vulkan inherits pass-through even though its SpriteBatch projection maps the virtual size
  across the physical swapchain, so resized/non-1:1 windows misalign absolute mouse/button/
  touch positions and `Mouse::SetPosition()`. BGFX and D3D9/11/12 also inherit pass-through,
  but currently ignore logical presentation and render in physical coordinates, making that
  fallback consistent with their separate presentation limitation. Software and Headless
  have no window.
- Existing proof is narrow: the SDL route has direct read/write tests, DX3 proves only its
  bypassed helper math, ASCII's immediate SetPosition/GetState check can pass from
  `InputManager`'s synchronous state assignment alone, and no dedicated transform test was
  found for EasyGL, Canvas, Vulkan, WebGPU, or SDL GPU.
- Ch.16 now carries the three-tier route and complete fourteen-product matrix; Ch.25
  distinguishes DX3's helper math from its real public path; Ch.26 explains the
  caller-visible consequences and evidence boundary; Appendix F has the quick-reference
  warning.

## Earlier completed batch

The draw-fallback, instancing, and vertex-binding audit is complete:

- The ordinary `DrawPrimitivesEx` / `DrawIndexedPrimitivesEx` fallbacks are dead today. All
  ten constructible 3D/diagnostic backends override them; the four 2D-only backends fail
  buffer construction first and their fallback target throws anyway.
- The shared throwing `DrawInstancedPrimitivesEx` default is live on SDL GPU and Software.
  Seven GPU backends override it; Headless records logical statistics; the four 2D-only
  backends cannot reach it through public buffer construction.
- `GraphicsDevice` forwards only the first binding with `InstanceFrequency > 0` as one raw
  instance-buffer pointer. `GpuDrawParams` carries neither the actual frequency nor binding
  offsets, so no backend can reproduce FNA's complete binding array. EasyGL's custom-effect
  path binds the caller's declaration with divisor one; the other real GPU paths use a fixed
  internal instancing shader and predominantly a 64-byte world-matrix record.
- Binding state itself is inconsistent: the offset-taking singular setter ignores its offset
  and leaves `currentVertexBuffers_` stale; an empty plural setter leaves
  `currentVertexBuffer_` stale. A later instanced draw can therefore combine a new mesh slot
  with an old instance slot. The existing `VertexBufferBindingTests` never constructs a
  `GraphicsDevice`, so its “GetVertexBuffers contract” comments do not exercise this state.
- Backend proof is strongest on public EasyGL/Vulkan multi-instance pixel tests; WebGPU and
  D3D9 have direct multi-instance pixel tests; D3D11/12 directly prove only one instance;
  BGFX, SDL GPU, Software, and Headless have no dedicated instancing pixel/contract test.
- Ch.9 now documents the public narrowing and the unsynchronized singular/plural binding
  state; Ch.16 carries the complete fallback/override/evidence matrix; Ch.20 removes a
  previous BGFX overclaim; Ch.22 expands its open-limit count from seven to nine; Appendix A
  carries the concise caller warning.

## Earlier completed Texture2D batch

The `Texture2D` interface-default audit is complete:

- `Texture2D::SetData(Color*, count)` replaces this object's backend resource, while the
  detailed level/rectangle overload alone reaches `ITextureBackend::UpdatePixels*`.
- Every current texture factory product overrides the empty level-0 default, so
  `UpdatePixels()` is unreachable dead fallback today. SDL GPU still inherits the empty
  `UpdatePixelsLevel()` default and allocates one physical level even when public
  `LevelCount` reports a full mip chain. Software explicitly discards higher levels;
  Headless records only a trace. SDL_Renderer/ASCII, Canvas, and DX3 throw instead.
- Ordinary `Texture2D::GetData()` reads the CPU shadow. Therefore the existing public
  SetData/GetData mip round trip does not prove GPU upload; separate sampled-pixel or native
  readback tests provide the real evidence on EasyGL/Vulkan/BGFX, WebGPU, and D3D11/12.
- WebGPU deliberately regenerates the complete ordinary-texture mip chain after every
  level-0 upload, unlike FNA and the other CNA implementations; a later level-0 write can
  overwrite authored higher levels.
- Ch.11 now explains both update paths and why its former public round-trip example was not
  GPU evidence. Ch.16 contains the full backend matrix and evidence limits. Ch.19 corrects
  its stale Vulkan no-op claim, and Appendix A carries the concise caller-facing warning.

## Earlier completed work

The remaining `RenderTargetCube` interface defaults were traced through the public API,
every factory/override, backend target state, FNA, and the relevant examples:

- `RenderTargetCube` inherits `TextureCube.SetData()` in both CNA and FNA. FNA forwards it to
  FNA3D even for a render-target texture. CNA redeclares it as an empty
  `IRenderTargetCubeBackend` default; only EasyGL overrides it. Every other constructed
  target validates and converts a public upload, then silently discards it. Null-factory
  backends discard it one layer earlier. No dedicated RT-cube upload test exists.
- `IGraphicsBackend::SetRenderTargetCubeFace()` binds a non-null cube but never calls the
  outgoing cube's `UnbindAsRenderTarget()`; its null case merely enters the 2D-null path.
  Vulkan, WebGPU, SDL GPU, and D3D9 remain sound through their own state models or override.
- D3D11/12 inherit that common route while tracking only `RenderTarget2D`.
  D3D11's later public null-target call neither finalizes the cube nor restores the
  backbuffer. D3D12 restores the backbuffer but skips cube MSAA resolve and mip generation.
  Their smoke tests call cube bind/unbind directly, so exact pixels prove the algorithms
  only when explicitly invoked; no public `GraphicsDevice` cube-transition test was found.
- EasyGL correctly finalizes cube-to-2D/backbuffer and transitions between different cube
  objects, but same-object face-to-face switching skips unbind. Its shared MSAA renderbuffer
  therefore resolves only the last face unless the caller unbinds between faces. No
  dedicated EasyGL cube-MSAA test exists.
- BGFX's ordinary 2D-null path restores view 0 and native attachment flags handle resolve/
  mip work. Its explicit cube-null overload simply returns, however, and the established
  single-view-ID-per-cube same-frame face boundary remains.
- Ch.11, Ch.16, Ch.23, and Appendix A now agree. Ch.16 contains the complete matrix; Ch.23
  explicitly distinguishes working D3D backend callbacks from the missing public routing.

## Additional earlier work

The preceding readback audit established real ordinary Texture3D/TextureCube GPU readback on
EasyGL, Vulkan, BGFX, WebGPU, SDL GPU, and D3D9/11/12, with the separate
RenderTargetCube/null/placeholder matrix recorded in Ch.16.

The earlier buffer-interface audit established that the public `dynamic` constructor flag is ignored,
but EasyGL, SDL GPU, D3D9, and D3D11 still map upload options distinctly. It also found that
the options-taking public wrappers fail to refresh `cpuShadow_`, so inherited `GetData()` sees
empty or stale bytes. Ch.16 contains the full backend matrix. The same batch corrected the
fixed vertex-stride family to 16/20/24/32/48/52/56/68 bytes and documented EasyGL's unique
arbitrary-`VertexDeclaration` path.

The earlier capability passes corrected confirmed `GraphicsCapability` false positives,
documented the real `IEffectBackend` setter boundary, and established the current
ShaderEffect/D3D ABI matrix. See `PLAN.md` for the durable detail.

## Validation

The final forced build succeeded:

```bash
cd latex/book
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex
```

Results:

- `main.pdf`: 502 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 2,056 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.6 physical page 64, Ch.9 pages 112--113, Ch.16 pages
  188--190, Ch.17 page 207, Ch.19 page 226, Ch.23 pages 261--262, and Appendix A page 467.
- No clipping, table collision, page-edge spill, malformed heading, running-header collision,
  or folio defect was found. The new Ch.16 matrix repeats its header cleanly after the page
  break. All overfull warnings introduced by this batch were removed before the final build;
  older warnings remain elsewhere.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part2-getting-started/ch06-game-loop.tex \
      latex/book/chapters/part3-graphics-core/ch09-graphicsdevice.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch17-sdl-renderer.tex \
      latex/book/chapters/part4-backends/ch19-vulkan-backend.tex \
      latex/book/chapters/part4-backends/ch23-direct3d-backends.tex \
      latex/book/chapters/appendices/appendix-a-core-graphics-quick-reference.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 502 total pages and exact current line counts: Ch.6 473; Ch.9 1,141;
  Ch.16 1,192; Ch.17 390; Ch.19 473; Ch.23 786; Appendix A 378.
- Its durable session log records the construction/runtime split, exact/collapsed/no-op
  interval semantics, D3D9 native-validity defect, Vulkan eager-construction trap, evidence
  strength, FNA contrast, and PDF inspection.
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

Continue Ch.16's backend-interface-default audit. Buffer defaults, volume/cube readback,
RenderTargetCube upload/transitions, Texture2D updates, draw/instancing fallbacks,
coordinate transforms, backbuffer readback, and swap intervals are closed. Re-inventory the
remaining defaults and choose the strongest public, non-duplicate gap by reachability and
documentation value. Trace the caller, override matrix, state transitions, and actual
assertion layer before writing. Do not modify CNA itself; sibling repositories remain
read-only source authorities.
