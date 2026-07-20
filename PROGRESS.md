# The CNA Bible — writing progress

Two-volume LaTeX technical book about the `openeggbert/cna` ecosystem. Source lives under
`latex/volume1/` and `latex/volume2/`. Build with:

```bash
cd latex && make volume1   # -> volume1/main.pdf
cd latex && make volume2   # -> volume2/main.pdf
```

## Scope note

The original ask was for a much larger multi-volume work (2 volumes x ~2000 pages). That
target is not reachable as genuinely unique, source-grounded content in one sitting — this
file tracks real progress honestly rather than padding chapters to hit a page count. Chapters
marked "placeholder" below contain only a title and a pending-content note; they are not
counted as done.

**free-direct scope (per author instruction 2026-07-20): capped at ~5-10 pages total across
both volumes.** It is a marginal/peripheral dependency for CNA (backs only the DX3 backend),
not a deep dive on par with sharp-runtime or easy-gl. Vol.I Ch.24 (DX3 backend) and Vol.II
Ch.11 (free-direct in depth) should stay concise and combined should not exceed that budget.

## Volume I — The Core Framework and the Graphics Machine

### Part I — The CNA Ecosystem
- [x] Ch.1 What Is CNA? — written, source-grounded (README, CLAUDE.md)
- [x] Ch.2 The Ecosystem Map — written (all 6 sibling repo READMEs read directly)
- [x] Ch.3 Design Philosophy and House Style — written (full CLAUDE.md porting-rules pass)

### Part II — Getting Started
- [x] Ch.4 Building CNA — written (full README build-instructions pass)
- [x] Ch.5 Your First CNA Game — written (README usage example, annotated)
- [x] Ch.6 The Game Loop — written (Game/GameTime/GameComponent/GameWindow/GraphicsDeviceManager, source-grounded)
- [x] Ch.7 Math and Core Geometry Types — written (Vector/Matrix/Quaternion/Color/bounding volumes/Curve, source-grounded)
- [ ] Ch.8 Content and Assets — placeholder

### Part III — The Graphics Machine
- [x] Ch.9 GraphicsDevice — written, source-grounded
- [x] Ch.10 SpriteBatch — written, source-grounded
- [x] Ch.11 Textures, Render Targets and Surfaces — written, source-grounded
- [ ] Ch.12-15 — placeholders (models/meshes, stock effects, state objects, shader/.fx gap)

### Part IV — The Backends
- [ ] Ch.16–24 — placeholders (backend architecture + 9 individual backend chapters).
      Extensive research notes already gathered for all of these (interface layer, CMake
      backend selection, and per-backend docs for SDL_Renderer/EasyGL/Vulkan/BGFX/WebGPU/
      D3D9/D3D11/D3D12/Canvas/ASCII/DX3) — writing pass pending.
      **Ch.24 (DX3/free-direct) must stay short per the free-direct scope note above.**

## Volume II — The Ecosystem, the Platforms, and the Practice

All chapters currently placeholders (Parts I–V + 3 appendices).
**Ch.11 (free-direct in depth) must stay short per the free-direct scope note above.**

## Research notes gathered (not yet all turned into chapters)

Three research passes completed, covering:
1. Core framework types (Game/GameTime/math/curves) — used for Vol.I Ch.6–7 (done)
2. Graphics core API (GraphicsDevice/SpriteBatch/textures/models/effects/state) — partially
   used (Ch.9-11 done); still needed for Ch.12-15 (models, stock effects, state objects,
   shader/.fx gap)
3. Backend architecture + all per-backend docs — still needed for Ch.16-24
