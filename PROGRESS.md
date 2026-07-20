# The CNA Bible — writing progress

Two-volume LaTeX technical book about the `openeggbert/cna` ecosystem. Source lives under
`latex/volume1/` and `latex/volume2/`. Build with:

```bash
cd latex && make volume1   # -> volume1/main.pdf  (106 pages, COMPLETE)
cd latex && make volume2   # -> volume2/main.pdf  (84 pages, Part I complete, rest in progress)
```

## Scope note

The original ask was for a much larger multi-volume work (2 volumes x ~2000 pages). That
target is not reachable as genuinely unique, source-grounded content in one sitting — this
file tracks real progress honestly rather than padding chapters to hit a page count. Chapters
marked "placeholder" below contain only a title and a pending-content note; they are not
counted as done.

**free-direct scope (per author instruction 2026-07-20): capped at ~5-10 pages total across
both volumes.** It is a marginal/peripheral dependency for CNA (backs only the DX3 backend),
not a deep dive on par with sharp-runtime or easy-gl. Vol.I Ch.24 (DX3 backend, ~2 pages) and
Vol.II Ch.12 (free-direct in depth) together must stay within that budget.

## Volume I — The Core Framework and the Graphics Machine — **COMPLETE (106 pages)**

All 24 chapters across all 4 parts are written, source-grounded, and compile cleanly:
- Part I: Ecosystem & design philosophy (Ch.1-3)
- Part II: Getting started, game loop, math types, content model (Ch.4-8)
- Part III: Graphics core — GraphicsDevice, SpriteBatch, textures/RTs, models, stock
  effects, state objects, shader/.fx gap (Ch.9-15)
- Part IV: All 9 backend chapters — architecture, SDL_Renderer, EasyGL, Vulkan, BGFX,
  WebGPU, D3D9/11/12, Canvas+ASCII, DX3 (Ch.16-24)

## Volume II — The Ecosystem, the Platforms, and the Practice

### Part I — Input, Audio, Media, Devices, Networking and Services — **COMPLETE**
- [x] Ch.1 Input — written, source-grounded (event pipeline, Keyboard/Mouse/GamePad/Touch,
      CNA::Input NOXNA extensions, real bugs found+fixed, platform notes)
- [x] Ch.2 Audio — written, source-grounded (SDL3_mixer-backed XACT model, real user-bug-
      triggered audit findings, accepted deviations)
- [x] Ch.3 Media — written, source-grounded (corrects README's stale "14 shells" claim —
      224/231 tasks actually done; Song/Album/Playlist/MediaPlayer/VideoPlayer; the FNA-vs-
      real-XNA Song.Album/Artist/Genre gap as a methodology lesson)
- [x] Ch.4 Devices/Sensors — written, source-grounded (SensorBase concurrency engineering,
      real Accelerometer/Gyroscope, Android-only Compass/Motion, VibrateController, plus the
      wholly-NOXNA CNA::Devices desktop layer: Camera/SystemTray/DisplayInfo/etc.)
- [x] Ch.5 GamerServices — written, source-grounded (real+locally-persisted vs. documented
      stub split, Guide's two real overlay UIs vs. its mostly-stub Show* family)
- [x] Ch.6 Networking — written, source-grounded (NetworkSession/ENet, real vs. stub by
      NetworkSessionType, real bugs found+fixed, one still-open leak named honestly)
- [x] Ch.7 Avatar — written, source-grounded (faithful-inert base API vs. SkinnedModelEXT
      real-rendering extension, contrast table)

### Part II — Sharp Runtime (Ch.8-10) — placeholders, not yet researched
### Part III — easy-gl and free-direct (Ch.11-12) — placeholders, not yet researched.
      **Ch.12 free-direct must stay short — see scope note above.**
### Part IV — Cross-platform engineering (Ch.13-16) — placeholders, not yet researched
### Part V — Porting, practice, roadmap (Ch.17-23) + 3 appendices — placeholders, not yet researched

## Research notes gathered so far (raw material banked, ready to turn into chapters)

1. Core framework types (Game/GameTime/math/curves) — used, Vol.I Ch.6-7 done
2. Graphics core API (GraphicsDevice/SpriteBatch/textures/models/effects/state) — used,
   Vol.I Ch.9-15 done
3. Backend architecture + all 11 backend docs — used, Vol.I Ch.16-24 done
4. Input/Audio/Media/Net — used, Vol.II Ch.1/2/3/6 done
5. GamerServices/Avatar — used, Vol.II Ch.5/7 done
6. Devices/Sensors — read directly from source (SensorBase, Accelerometer, Compass,
   VibrateController headers + devices-api-coverage.md), Vol.II Ch.4 done

Still needed: sharp-runtime research, easy-gl/free-direct research, cross-platform
(Windows/Wine, Emscripten, Android, verification methodology) research, and
porting/practice/roadmap material (migration guide, Blupi case study, xna4-spec auditing,
samples/examples, project practice, testing philosophy, roadmap, 3 appendices).
