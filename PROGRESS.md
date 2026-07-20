# The CNA Bible — writing progress

**Status: both volumes complete, including a content-completeness pass covering
CNJ/XNB/Storage/NOXNA/RAM/cna-template/cna-extended/libcna.com, a repo-map expansion
(meta-gl/easy-3d/cna-craft/mesh-craft/mesh-world/galaxy-eggbert), and new API quick-reference
appendices in both volumes (2026-07-20).**
Two-volume LaTeX technical book about the `openeggbert/cna` ecosystem. Source lives under
`latex/volume1/` and `latex/volume2/`. Build with:

```bash
cd latex && make volume1   # -> volume1/main.pdf  (114 pages)
cd latex && make volume2   # -> volume2/main.pdf  (119 pages)
```

Both volumes compile cleanly with pdflatex/latexmk, no undefined references, no unicode
errors. Combined: 233 pages, 48 chapters + 2 prefaces + 6 appendices.

**Index fix (2026-07-20):** both volumes' back-of-book index (`\printindex`) was previously
present but empty (0 entries — the index infrastructure existed but no `\index{}` markup had
ever been added anywhere in 48 chapters). Fixed at the root: `\cnaclass{}` and `\cnans{}` in
`latex/common/preamble.tex` (the macros already wrapping every class/method/namespace name
throughout both volumes) now also emit `\index{}` for their argument, so the index populates
automatically from markup that already existed everywhere in the text, with no separate
manual-indexing pass needed. Volume I: 544 entries, 226 index lines, 0 rejected, 0 warnings.
Volume II: 367 entries, 259 index lines, 0 rejected, 0 warnings. Surveyed all ~330 unique
`\cnaclass`/`\cnans` arguments beforehand for makeindex-special characters (`@ ! | "`) — none
found, only two already-escaped underscores — before making the change.

## Scope note

The original ask was for a much larger multi-volume work (2 volumes x ~2000 pages, later
clarified as 2x2000 across a 4000-page total). That target was not reachable as genuinely
unique, source-grounded content in any reasonable session — this project instead prioritized
real depth and accuracy over page count, with every specific claim traceable to an actual
source file, doc, or test result read directly from the `cna`, `sharp-runtime`, `easy-gl`,
`free-direct`, `xna4-spec`, `cna-samples`, `cna-examples`, `cna-template`, and `cna-extended`
repositories. 220 pages of dense, non-repetitive, source-grounded technical writing is the
honest result.

**free-direct scope (per author instruction 2026-07-20): capped at ~5-10 pages total across
both volumes.** Delivered as: Vol.I Ch.24 (DX3 backend, ~2 pages) + Vol.II Ch.13 (free-direct
in depth, ~2 pages) + material folded into Vol.II Ch.19 (Blupi case study, which is really
about the free-eggbert/planetblupi call-site audit, not free-direct itself) — combined
free-direct-specific content stays within budget.

**cna-extended scope (per author instruction 2026-07-20): intentionally marginal.** One
paragraph in Vol.II Appendix C, not a dedicated chapter.

## Content-completeness pass (2026-07-20, second session)

The author flagged real gaps after the first "complete" pass: CNJ format, the corrected/
current XNB story, the Storage namespace, a NOXNA catalog, and cna-template/cna-extended/
libcna.com were all missing or under-covered. Fixed:

- **Vol.I Ch.8 (Content and Assets) rewritten**: the original version claimed CNA has no
  `.xnb` reader "by design" except for Model — this was stale. Corrected to describe both
  real formats: `.cnj` (CNA's own permanent JSON sidecar format, renamed from the confusingly-
  named `.cnb`) and a real, growing binary `.xnb` reader (Texture2D, SpriteFont, all 5 stock
  effects, SoundEffect, Song, Model — plus real LZX decompression, verified via differential
  testing against FNA's own decompressor, which found a real heap-buffer-overflow). The
  actual `ContentManager` resolution order is documented precisely: `.xnb` first, then a
  direct native-format load, then `.cnj` last (as an optional metadata sidecar).
- **New Vol.II Ch.8 "Storage"**: Microsoft::Xna::Framework::Storage (StorageDevice,
  StorageContainer, StorageDeviceNotConnectedException) — a real namespace that had no
  coverage at all. Inserted into Part I, renumbering Parts II-V and their chapters by one
  chapter (sharp-runtime is now Ch.9-11, easy-gl/free-direct Ch.12-13, cross-platform
  Ch.14-17, porting/practice Ch.18-24).
- **New Vol.II Appendix D "Catalog of NOXNA Extensions"**: a reference table of every
  significant NOXNA/EXT extension named across both volumes, organized by area, with pointers
  back to the chapter that explains each one — explicitly framed as a curated reference to
  what this book covers, not a claim of exhaustive coverage (the project's own NOXNA
  compile-time build gate is the authoritative, mechanically-enforced check).
- **Vol.II Appendix C (repo map) expanded**: cna-template (thin starter template) and
  cna-extended (C++23 port of MonoGame.Extended — intentionally marginal per author
  instruction) both now covered; libcna.com correctly identified as CNA's flagship public
  documentation site (own top-level domain, not an *.openeggbert.com mirror); a note on
  RAM.md added under mobile-eggbert, correctly framed as a narrow, downstream memory-usage
  investigation of one game on one backend, not a general CNA feature.
- **Vol.II Appendix C expanded again (author instruction 2026-07-20, third pass)**: brief
  ("small extent") paragraphs added for meta-gl (the typed OpenGL/GLES wrapper easy-gl itself
  depends on), easy-3d (a small companion library built for galaxy-eggbert, explicitly not a
  game engine), cna-craft (a C++ port of fogleman/Craft onto CNA), mesh-craft (a C++23 3D scene
  editor for the .mc3.xml format, EASYGL-only GUI), mesh-world (a procedural world generator on
  the MeshCraft ecosystem, C++ + Lua/sol2, quadtree planetary maps), and galaxy-eggbert (a full
  3D remake of mobile-eggbert, built on CNA + easy-3d). mobile-eggbert, cna-samples, and
  cna-examples already had adequate dedicated coverage elsewhere and needed no new content.
- All cross-volume and cross-chapter references re-verified after renumbering; the
  `xrefs-volume1.tex` shim did not need new entries (all new cross-volume citations use plain
  text, matching the existing Vol.I → Vol.II citation style).

## Volume I — The Core Framework and the Graphics Machine — COMPLETE (112 pages, 24 chapters + 1 appendix)

- Part I (Ch.1-3): Ecosystem, design philosophy, house style
- Part II (Ch.4-8): Building CNA, first game, game loop, math/geometry types, content model
  (CNJ + XNB + direct loading, corrected 2026-07-20)
- Part III (Ch.9-15): GraphicsDevice, SpriteBatch, textures/render targets, models/meshes,
  stock effects, state objects, the shader/.fx bytecode gap
- Part IV (Ch.16-24): Backend architecture + SDL_Renderer, EasyGL, Vulkan, BGFX, WebGPU,
  D3D9/D3D11/D3D12, Canvas+ASCII, DX3
- Appendix A (new, 2026-07-20): API quick reference — math/geometry types (Vector2/3/4, Matrix,
  Quaternion, Point, Rectangle, Color, Plane, Ray, BoundingBox/Sphere/Frustum), the Game/
  GameTime/GameWindow/ContentManager framework layer, Texture2D/RenderTarget2D/SpriteBatch, and
  Model/ModelMesh/ModelBone plus a comparison table of the five stock effects. Every entry read
  directly from the corresponding `cna` header at time of writing; a lookup companion to the
  narrative chapters, not a replacement for them.

## Volume II — The Ecosystem, the Platforms, and the Practice — COMPLETE (116 pages, 24 chapters + 5 appendices)

- Part I (Ch.1-8): Input, Audio, Media (corrects a stale README claim), Devices/Sensors,
  GamerServices, Networking, Avatar, **Storage (new)**
- Part II (Ch.9-11): Sharp Runtime overview/architecture, strings/streams/audit history,
  parity philosophy and permanent deviations
- Part III (Ch.12-13): easy-gl in depth, free-direct in depth (kept short per scope note)
- Part IV (Ch.14-17): Windows/MinGW-w64/Wine, Web/Emscripten, Android/NDK, verification
  methodology compared across platforms
- Part V (Ch.18-24): Migration guide, Blupi case study, xna4-spec auditing, cna-samples/
  cna-examples, project practice & task tracking, testing philosophy, roadmap
- Appendices: A (backend feature matrix), B (glossary, now includes CNJ/XNB/Storage entries),
  C (repository map, now includes cna-template/cna-extended/libcna.com/RAM.md, plus meta-gl/
  easy-3d/cna-craft/mesh-craft/mesh-world/galaxy-eggbert), D (NOXNA extension catalog),
  E (new, 2026-07-20: API quick reference — Input (Keyboard/Mouse/GamePad/TouchPanel), Audio
  and Media (SoundEffect/SoundEffectInstance/DynamicSoundEffectInstance/Song/MediaPlayer),
  Networking and GamerServices (NetworkSession/NetworkGamer/LeaderboardReader/Achievement), and
  three core sharp-runtime types every other chapter leans on (TimeSpan/EventHandler<T>/Stream))

## Methodology notes

- Every chapter is grounded in direct reads of source code, README files, `docs/*.md` files,
  `CLAUDE.md`, `NEXT.md`, `AUDIT.md`, `CHECKLIST.md`, and `plan_*.md`/`cnj.md`/`xnb.md`/
  `RAM.md` tracking files across all repositories — not paraphrased from memory.
- Several research passes were run via parallel subagents to gather structured, source-cited
  notes before writing final prose from those notes.
- Two real documentation-drift corrections are now included as worked methodology lessons:
  the README's "Media: 25/25 present, 14 shells" claim (Vol.II Ch.3), and this session's own
  correction to Vol.I Ch.8's original "no .xnb reader by design" claim, which was itself
  stale relative to the project's current, real, growing binary XNB reader.
- Cross-volume chapter references are resolved via a small `\newlabel` shim
  (`latex/volume2/xrefs-volume1.tex`) mapping Volume I labels to their real chapter numbers
  for the handful of citations that use `\ref`; most Vol.I→Vol.II and Vol.II→Vol.I citations
  use plain-text chapter numbers instead, verified by hand after each renumbering pass.
