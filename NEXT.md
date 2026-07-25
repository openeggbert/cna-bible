# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **482 physical PDF pages, 49 chapters, 6 appendices**.
- The book repository started this autonomous session clean. After the pending readback
  commit, the local branch is ahead of `origin/develop` by six coherent documentation
  commits: roadmap, ShaderEffect/D3D ABI, general capability matrix, MSAA/anisotropy,
  buffer contracts, and volume/cube readback contracts.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

The remaining texture-interface readback defaults were traced through every public caller,
factory, backend implementation, and relevant test:

- EasyGL, Vulkan, BGFX, WebGPU, SDL GPU, and D3D9/11/12 all have real ordinary
  `Texture3D` and `TextureCube` GPU readback. Software has real level-0 CPU cube storage but
  no volume factory. Headless returns deliberate zero placeholders. SDL_Renderer, ASCII,
  Canvas, and DX3 return null for both factories.
- The public fallback has two different observable results. With an existing backend whose
  `GetData()` is a no-op, the zero-initialized RGBA staging vector overwrites the requested
  destination range with transparent black. With a null factory, the wrapper returns before
  staging and leaves the caller's range untouched.
- `RenderTargetCube` is a separate, narrower result: only WebGPU and SDL GPU implement its
  CPU readback. EasyGL, Vulkan, BGFX, and D3D9/11/12 create and sample real cube targets but
  inherit the readback no-op; Headless does likewise. This does not invalidate their
  render-then-sample paths.
- BGFX's ordinary readback is conditional on the selected renderer's blit/readback
  capabilities. It copies into a temporary transfer texture and waits up to four frames;
  failure is logged and the public result becomes transparent black.
- Exact public tests prove the ordinary paths on EasyGL/Vulkan/BGFX/WebGPU/SDL GPU; the
  Direct3D smoke tests compare exact subregions. Software cube `GetData()` is source-proven
  but lacks a dedicated exact public assertion. Headless's test header calls its checks
  round trips, while the assertion body only proves that placeholder calls do not throw.
- Ch.11, Ch.14, Ch.16, Ch.21, and Appendix A now agree. Ch.11 also corrects an adjacent
  stale explanation: `RenderTargetCube` already inherits `TextureCube`/`Texture`; its
  bound-disposal guard remains absent because the singular setter retains only a boolean,
  not the cube pointer.

## Previous completed batch

The buffer-interface audit established that the public `dynamic` constructor flag is ignored,
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

- `main.pdf`: 482 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 2,003 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.11 physical pages 139--142, Ch.14 page 169, Ch.16 pages
  184--187, Ch.21 page 228, and Appendix A page 447.
- No clipping, table collision, page-edge spill, malformed heading, running-header collision,
  or folio defect was found. The new Ch.16 four-column matrix fits on one page. Newly written
  ranges emit no local overfull warning; older warnings remain elsewhere.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch11-textures-rendertargets.tex \
      latex/book/chapters/part3-graphics-core/ch14-state-objects.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch21-webgpu-backend.tex \
      latex/book/chapters/appendices/appendix-a-core-graphics-quick-reference.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 482 total pages and exact current line counts: Ch.11 463; Ch.14 342;
  Ch.16 528; Ch.21 326; Appendix A 348.
- Its durable session log records the public fallback semantics, backend/test proof limits,
  RenderTargetCube split, and PDF inspection.
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

Continue Ch.16's backend-interface-default audit. Volume/cube readback and buffer defaults are
closed. Inventory the remaining unreviewed defaults, then choose the highest-value reachable
contract whose book text is absent or stale. Trace the public caller, override matrix, and
tests before writing. Do not modify CNA itself; sibling repositories remain read-only source
authorities.
