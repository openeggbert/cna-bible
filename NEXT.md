# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **484 physical PDF pages, 49 chapters, 6 appendices**.
- The local branch is ahead of `origin/develop` by eight coherent documentation commits:
  roadmap, ShaderEffect/D3D ABI, general capability matrix, MSAA/anisotropy, buffer
  contracts, volume/cube readback contracts, and RenderTargetCube upload/transition
  contracts, followed by Texture2D update contracts.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

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

## Previous completed batch

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

## Earlier completed work

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

- `main.pdf`: 484 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 2,018 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.11 physical pages 139--140, Ch.16 pages 184--187, Ch.19 page
  212, and Appendix A page 449.
- No clipping, table collision, page-edge spill, malformed heading, running-header collision,
  or folio defect was found. The new Ch.16 matrix is clean. The one local Ch.19 overfull
  warning found on the first build was removed before the final build; older warnings remain
  elsewhere.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch11-textures-rendertargets.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch19-vulkan-backend.tex \
      latex/book/chapters/appendices/appendix-a-core-graphics-quick-reference.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 484 total pages and exact current line counts: Ch.11 521; Ch.16 710;
  Ch.19 457; Appendix A 358.
- Its durable session log records the two public update paths, backend/default matrix,
  CPU-shadow evidence boundary, WebGPU divergence, and PDF inspection.
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
RenderTargetCube upload/transitions, and Texture2D updates are closed. Re-inventory the
remaining permissive defaults; draw-parameter fallbacks and coordinate transforms are
promising next candidates, but choose by public reachability and documentation gap after
rechecking the live source. Trace the caller, override matrix, state transitions, and actual
assertion layer before writing. Do not modify CNA itself; sibling repositories remain
read-only source authorities.
