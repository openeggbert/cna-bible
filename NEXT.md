# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **478 physical PDF pages, 49 chapters, 6 appendices**.
- The book repository started this autonomous session clean. The local branch is now ahead of
  `origin/develop` by five coherent documentation commits: the roadmap correction, the
  ShaderEffect/D3D ABI correction, the general capability/feature-matrix correction, the
  MSAA/anisotropy capability audit, and the buffer-contract correction.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch

The buffer-interface audit corrected two broad stale claims and exposed one shared public bug:

- `DynamicVertexBuffer`/`DynamicIndexBuffer` still do not select different storage merely
  because their ignored constructor flag is `dynamic=true`, but upload options are not
  universally ignored. EasyGL, SDL GPU, D3D9, and D3D11 have real, distinct mappings;
  Vulkan/BGFX inherit the ignoring default; WebGPU/D3D12/Software/Headless explicitly ignore
  it; the four 2D-only backends reject buffer construction first.
- D3D9 forces `Discard` for a fresh or grown native buffer. EasyGL's index-buffer
  `NoOverwrite` path unexpectedly falls back to reallocation when context recovery is off,
  because its eligibility check is coupled to the absent backend CPU shadow.
- The public options-taking wrappers upload successfully but never refresh the shared
  `cpuShadow_`. Inherited `GetData()` on a non-`WriteOnly` dynamic buffer therefore sees
  empty or stale data; a fresh instance throws `ArgumentOutOfRangeException`. This is shared
  code above every backend, not an EasyGL readback limitation.
- The old “all hardware layouts are selected only by one of five strides” rule is also stale.
  The fixed family is now 16/20/24/32/48/52/56/68 bytes, and EasyGL alone consumes arbitrary
  `VertexDeclaration` data sent through `SetDataRaw()`. Its 48-byte custom-layout pixel test
  remains discriminating because that record differs structurally from the fixed 48-byte PBR
  record.
- Ch.11, Ch.15, Ch.16, Ch.18, and Appendix A now agree on those boundaries. Ch.16 contains
  the full backend matrix; test claims distinguish source-proven native mappings from
  pixel-proven data correctness.

## Previous completed batch

The two device-dependent `GraphicsCapability` entries were audited across every live backend:

- `MultiSampleAntiAliasing` is definitely false-positive on ASCII and Software; Vulkan,
  WebGPU, SDL GPU, D3D9, and some BGFX paths can also negotiate or behave below the inherited
  `true` answer.
- `AnisotropicFiltering` is definitely false-positive on ASCII, SDL GPU, and Software.
  D3D9 does not consult its live maximum, and BGFX implements only an on/off flag.
- Ch.16 contains the complete 11-row comparison and directs callers to inspect the applied
  sample count after negotiation.

## Earlier completed batch

The broader capability audit corrected confirmed false positives, documented the real
`IEffectBackend` setter boundary, fixed Appendix B's stale BGFX/SDL_Renderer cells, and removed
the obsolete BGFX `RenderTargetCube` wrong-cast claim. The preceding ShaderEffect audit also
established the real per-backend source/ABI matrix and the fixed D3D11/D3D12 SpriteBatch
contract. See `PLAN.md`'s dated log for the durable detail.

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
- `makeindex`: 1,983 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.11 physical pages 143--144, Ch.15 pages 175--176, Ch.16 pages
  181--183, Ch.18 pages 199--200, and Appendix A page 446.
- No clipping, column collision, page-edge spill, malformed table, running-header collision,
  or folio defect was found. The new Ch.16 longtable repeats its header correctly. Newly
  written ranges emit no overfull warning; older warnings remain outside this batch's new
  paragraphs.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part3-graphics-core/ch11-textures-rendertargets.tex \
      latex/book/chapters/part3-graphics-core/ch15-shader-fx-gap.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch18-easygl-backend.tex \
      latex/book/chapters/appendices/appendix-a-core-graphics-quick-reference.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 478 total pages and exact current line counts: Ch.11 445; Ch.15 333;
  Ch.16 442; Ch.18 338; Appendix A 337.
- The durable session log records the buffer audit, proof limits, shared readback defect, and
  final PDF validation.
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

Continue Ch.16's backend-interface-default audit. The buffer defaults are now closed; inventory
the remaining unreviewed defaults, then choose the highest-value reachable contract whose
current book text is absent or stale. Trace public caller, override matrix, and tests before
writing. Do not attempt to fix CNA itself from this book repository; sibling repositories
remain read-only source authorities.
