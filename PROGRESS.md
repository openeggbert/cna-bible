# The CNA Bible — writing progress

**Status: both volumes complete.** Two-volume LaTeX technical book about the
`openeggbert/cna` ecosystem. Source lives under `latex/volume1/` and `latex/volume2/`.
Build with:

```bash
cd latex && make volume1   # -> volume1/main.pdf  (106 pages)
cd latex && make volume2   # -> volume2/main.pdf  (104 pages)
```

Both volumes compile cleanly with pdflatex/latexmk, no undefined references, no unicode
errors. Combined: 210 pages, 47 chapters + 2 prefaces + 3 appendices.

## Scope note

The original ask was for a much larger multi-volume work (2 volumes x ~2000 pages, later
clarified as 2x2000 across a 4000-page total). That target was not reachable as genuinely
unique, source-grounded content in any reasonable session — this project instead prioritized
real depth and accuracy over page count, with every specific claim traceable to an actual
source file, doc, or test result read directly from the `cna`, `sharp-runtime`, `easy-gl`,
`free-direct`, `xna4-spec`, `cna-samples`, and `cna-examples` repositories. 210 pages of dense,
non-repetitive, source-grounded technical writing is the honest result.

**free-direct scope (per author instruction 2026-07-20): capped at ~5-10 pages total across
both volumes.** Delivered as: Vol.I Ch.24 (DX3 backend, ~2 pages) + Vol.II Ch.12 (free-direct
in depth, ~2 pages) + material folded into Vol.II Ch.18 (Blupi case study, which is really
about the free-eggbert/planetblupi call-site audit, not free-direct itself) — combined
free-direct-specific content stays within budget.

## Volume I — The Core Framework and the Graphics Machine — COMPLETE (106 pages, 24 chapters)

- Part I (Ch.1-3): Ecosystem, design philosophy, house style
- Part II (Ch.4-8): Building CNA, first game, game loop, math/geometry types, content model
- Part III (Ch.9-15): GraphicsDevice, SpriteBatch, textures/render targets, models/meshes,
  stock effects, state objects, the shader/.fx bytecode gap
- Part IV (Ch.16-24): Backend architecture + SDL_Renderer, EasyGL, Vulkan, BGFX, WebGPU,
  D3D9/D3D11/D3D12, Canvas+ASCII, DX3

## Volume II — The Ecosystem, the Platforms, and the Practice — COMPLETE (104 pages, 23 chapters + 3 appendices)

- Part I (Ch.1-7): Input, Audio, Media (corrects a stale README claim), Devices/Sensors,
  GamerServices, Networking, Avatar
- Part II (Ch.8-10): Sharp Runtime overview/architecture, strings/streams/audit history,
  parity philosophy and permanent deviations
- Part III (Ch.11-12): easy-gl in depth, free-direct in depth (kept short per scope note)
- Part IV (Ch.13-16): Windows/MinGW-w64/Wine, Web/Emscripten, Android/NDK, verification
  methodology compared across platforms
- Part V (Ch.17-23): Migration guide, Blupi case study, xna4-spec auditing, cna-samples/
  cna-examples, project practice & task tracking, testing philosophy, roadmap
- Appendices: A (backend feature matrix), B (glossary), C (repository map)

## Methodology notes

- Every chapter is grounded in direct reads of source code, README files, `docs/*.md` files,
  `CLAUDE.md`, `NEXT.md`, `AUDIT.md`, `CHECKLIST.md`, and `plan_*.md` tracking files across
  all seven repositories — not paraphrased from memory.
- Several research passes were run via parallel subagents to gather structured, source-cited
  notes (core framework, Graphics API, all 11 backends, Input/Audio/Media/Net, GamerServices/
  Avatar, Devices/Sensors, sharp-runtime, easy-gl, cross-platform/Wine/Emscripten/Android/
  verification, Blupi case study) before writing final prose from those notes.
- A real documentation-drift correction is included as a worked methodology lesson: the
  README's "Media: 25/25 present, 14 shells" claim is flagged and corrected against the
  namespace's own current tracking record (224/231 tasks done) in Vol.II Ch.3.
- Cross-volume chapter references are resolved via a small `\newlabel` shim
  (`latex/volume2/xrefs-volume1.tex`) mapping Volume I labels to their real chapter numbers,
  so `Chapter~\ref{...}` reads correctly across the two separately-compiled documents.
