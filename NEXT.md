# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **484 physical PDF pages, 49 chapters, 6 appendices**.
- The local branch is ahead of `origin/develop` by seven coherent documentation commits:
  roadmap, ShaderEffect/D3D ABI, general capability matrix, MSAA/anisotropy, buffer
  contracts, volume/cube readback contracts, and RenderTargetCube upload/transition
  contracts.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

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

## Previous completed batch

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
- `makeindex`: 2,015 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.11 physical page 141, Ch.16 pages 185--188, Ch.23 pages
  254--257, and Appendix A page 449.
- No clipping, table collision, page-edge spill, malformed heading, running-header collision,
  or folio defect was found. The new Ch.16 matrix repeats its header cleanly across two pages.
  Newly written ranges emit no local overfull warning; older warnings remain elsewhere.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch11-textures-rendertargets.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch23-direct3d-backends.tex \
      latex/book/chapters/appendices/appendix-a-core-graphics-quick-reference.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 484 total pages and exact current line counts: Ch.11 485; Ch.16 614;
  Ch.23 731; Appendix A 353.
- Its durable session log records the upload fallback, public transition matrix,
  backend/test proof limits, and PDF inspection.
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

Continue Ch.16's backend-interface-default audit. Buffer defaults, volume/cube readback, and
RenderTargetCube upload/transition defaults are closed. Re-inventory the remaining permissive
defaults and choose the highest-value reachable contract whose public consequence is absent
or stale in the book. Trace the public caller, override matrix, state transitions, and actual
assertion layer before writing. Do not modify CNA itself; sibling repositories remain
read-only source authorities.
