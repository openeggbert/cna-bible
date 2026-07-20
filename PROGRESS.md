# The CNA Bible — writing progress

Two-volume LaTeX technical book about the `openeggbert/cna` ecosystem. Source lives under
`latex/volume1/` and `latex/volume2/`. Build with:

```bash
cd latex && make volume1   # -> volume1/main.pdf  (106 pages, complete)
cd latex && make volume2   # -> volume2/main.pdf  (in progress)
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

Structure updated to add a dedicated Media chapter (was missing). Current chapter numbering:

### Part I — Input, Audio, Media, Devices, Networking and Services
- [ ] Ch.1 Input — placeholder; **full research notes gathered** (Keyboard/Mouse/GamePad/
      Touch/Gestures + CNA::Input NOXNA extensions Joysticks/Sensors/Power/Haptics,
      docs/input-*.md, real bugs found)
- [ ] Ch.2 Audio — placeholder; **full research notes gathered** (SoundEffect family,
      AudioEngine/SoundBank/WaveBank/Cue XACT model over SDL3_mixer, NEXTaudio.md findings)
- [ ] Ch.3 Media — placeholder; **full research notes gathered** (Song/Album/Playlist/
      MediaPlayer/VideoPlayer — note: README's "14 shells" claim is STALE, NEXTmedia.md
      shows 224/231 tasks done, real implementations)
- [ ] Ch.4 Devices/Sensors — placeholder (not yet researched)
- [ ] Ch.5 GamerServices — placeholder; **full research notes gathered** (Gamer/
      SignedInGamer/Leaderboards/Achievements real+local, Guide mostly stub w/ 2 real
      overlay UIs)
- [ ] Ch.6 Networking — placeholder; **full research notes gathered** (NetworkSession/ENet,
      SystemLink real, PlayerMatch/Ranked stub, real bugs found+fixed)
- [ ] Ch.7 Avatar — placeholder; **full research notes gathered** (base API faithfully
      inert per decompiled XNA assembly; SkinnedModelEXT is the separate real-rendering
      extension)

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
4. Input/Audio/Media/Net — gathered, not yet written (Vol.II Ch.1/2/3/6)
5. GamerServices/Avatar — gathered, not yet written (Vol.II Ch.5/7)

Still needed: Devices/Sensors research, sharp-runtime research, easy-gl/free-direct
research, cross-platform (Windows/Wine, Emscripten, Android, verification methodology)
research, and porting/practice/roadmap material.
