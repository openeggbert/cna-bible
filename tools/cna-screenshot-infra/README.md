# Reproducing real CNA screenshots for this book

This directory preserves what a feasibility check (2026-07-20) found when trying to build
`cna` and capture a real, actually-rendered screenshot in this project's remote container
environment (headless: no `DISPLAY`, no GPU passthrough), plus a follow-up session's (2026-07-21)
confirmation that the `Xvfb`-based path (left untested by the first check) actually works.
Whether `cna` persists across sessions is environment-dependent — check
`/rv/data/development/github.com/openeggbert/cna` (this book's own sibling-repo convention, see
this repo's own `NEXT.md`) before assuming a fresh clone is needed; `/workspace/cna`, referenced
below, is this document's original, more conservative assumption (a scratch clone local to one
session's container, not persisted) and is still the right fallback in an environment where the
fixed sibling-repo path doesn't exist. Either way, if a fresh clone is genuinely needed, reapply
the CMake-registration patch below to it first.

## Findings

- CNA's checked-out HEAD at the time of the original 2026-07-20 check did **not** compile for
  any backend: the content-pipeline's `ContentReader::ReadDecimal()`/`ReadChar()` are called by
  `DecimalDateTimeContentTypeReaders.hpp`/`PrimitiveContentTypeReaders.hpp` but were never
  implemented on `sharp-runtime`'s `BinaryReader` base class at the time.
  `contentreader-stopgap-and-demo-target.patch` (kept here for the historical record) added
  minimal, clearly-marked stopgap implementations for that gap. **Update, 2026-07-21: this is
  fixed upstream now** — `sharp-runtime/include/System/IO/BinaryReader.hpp`/`.cpp` both
  implement `ReadChar()`/`ReadDecimal()` for real (matching .NET's actual documented decimal-bits
  and single-UTF-16-code-unit semantics; also covered from the book's own side in Ch.3, Design
  Philosophy). The stopgap patch's `ContentReader` hunk is very likely unnecessary against a
  current checkout — try building without it first, exactly as this document already advised;
  only its `cmake/Tests/SoftwareTests.cmake` demo-registration hunk is still needed.
- CNA has a real, dedicated **`SOFTWARE` graphics backend** (`docs/software-backend.md`): a
  CPU triangle rasterizer (edge functions, perspective-correct interpolation, per-pixel depth
  test) that never touches SDL video/X11/a GPU at all. This is the realistic path to a genuine
  screenshot in a headless container — confirmed via `cna_test_software_smoke`
  (`SDL_WasInit(SDL_INIT_VIDEO) == 0`) and `cna_test_software_rasterizer`, both passing with
  `DISPLAY`/`WAYLAND_DISPLAY` unset.
- CNA already has golden-image test infrastructure to build on:
  `examples/common/PixelTestGame.hpp` (`CompareGoldenImage`/`CNA_UPDATE_GOLDEN`),
  `examples/common/ScreenshotEXT.hpp` (`SaveBackBufferScreenshotEXT`), ~17 checked-in reference
  PNGs under `examples/golden/`, all built on `Texture2D::SaveAsPng`.
- `software_screenshot_demo.cpp` (saved alongside this README) is a small `Game` subclass that
  draws a real depth-tested, color-interpolated two-triangle scene through the `SOFTWARE`
  backend and calls `SaveBackBufferScreenshotEXT`. Run with no `DISPLAY` set, it produced a
  genuine 256×256 RGBA PNG — visually confirmed correct (background triangle correctly
  occluded where the foreground triangle overlaps; correct barycentric color interpolation).
  Used for Vol.I Ch.9 (GraphicsDevice).
- `math_rotation_demo.cpp` (same directory) is a second worked example for Vol.I Ch.7 (Math and
  Core Types): a real `Matrix::CreateRotationZ`/`CreateTranslation`/`CreateLookAt`/
  `CreatePerspectiveFieldOfView` world/view/projection chain rotating a triangle 30 degrees —
  screenshotted and visually confirmed as genuinely rotated (not the unrotated upright
  triangle a stubbed-out transform would have produced).
- `rendertarget_roundtrip_demo.cpp` (same directory) is a third worked example, for Vol.I Ch.9
  (GraphicsDevice), that **found a real bug** rather than producing a clean success: it draws
  into an offscreen `RenderTarget2D`, verifies via `GetBackBufferData` that the render target's
  own pixels are correct while still bound (numerically confirmed: `R=255 G=144 B=0`, matching
  the triangle drawn), restores the back buffer, then tries to draw the render target's content
  back into the main scene via `SpriteBatch::Draw`. The inset renders as blank white instead of
  the verified-correct offscreen content. Root cause (read directly from
  `SoftwareGraphicsBackend.cpp`): `SoftwareSpriteBatchBackend::Draw` recognizes its texture
  argument via `dynamic_cast<const SoftwareTextureBackend*>(&texture)`, but a `RenderTarget2D`'s
  backend is a `SoftwareRenderTargetBackend` — a sibling class (both separately implement
  `ITextureBackend`, one directly and one via `IRenderTargetBackend`), not a subclass of
  `SoftwareTextureBackend`. The cast fails silently and the rasterizer falls back to
  "untextured" instead of throwing — unlike the raw `DrawPrimitivesEx`/`DrawIndexedPrimitivesEx`
  paths, which explicitly throw `std::runtime_error` for the analogous null-texture case. This
  is a real, specific, live-discovered gap in the `SOFTWARE` backend specifically (not verified
  on any other backend) — write it up honestly in the book as a finding, per this project's own
  "screenshots real or not at all" rule; do not silently work around it or hide the broken inset.
- `quaternion_vs_matrix_demo.cpp` (same directory) is a fourth worked example, for Vol.I Ch.7
  (Math and Core Types): numerically and visually confirms that `Matrix::CreateRotationZ(30°)`
  and the equivalent `Quaternion::CreateFromAxisAngle(Vector3::Backward, 30°) ->
  Matrix::CreateFromQuaternion` path produce identical results (max absolute difference across
  all 16 matrix components: exactly `0`; a transformed test point matched to 6 decimal places
  via both paths). The rendered screenshot is pixel-identical to `math_rotation_demo.cpp`'s own
  output, so the book cites the numeric proof and the existing figure rather than embedding a
  redundant duplicate image — a deliberate choice, not an oversight.
- **Other backends**: `HEADLESS` exists but is logic-only (never rasterizes a real pixel, just
  reports the last `Clear()` color) — not useful for a screenshot. `CANVAS` is
  Emscripten/browser-only. `ASCII` decorates `SDL_RENDERER` and still needs a real X11 window.
  D3D9/D3D11/D3D12/BGFX are Windows/GPU-only and unrealistic to screenshot in this container at
  all.
- **`EASYGL`/`SDL_RENDERER` via `Xvfb` + Mesa llvmpipe: CONFIRMED, 2026-07-21.** A prior session
  left this "plausible but not actually tried." This session tried it and it works cleanly for
  both backends, no caveats found. `xvfb_screenshot_demo.cpp` (saved alongside this README)
  reuses the real `examples/easygl_spritebatch_rotation_golden_test.cpp` scene (Task 465/417) —
  a rotate-around-origin `SpriteBatch` draw — since both backends are 2D-capable but
  `SDL_RENDERER` specifically throws (`"SDL_Renderer does not support 3D"`) on the raw
  `VertexBuffer` 3D scene `software_screenshot_demo.cpp` uses, so a 2D `SpriteBatch` scene is the
  one that actually works on both. Built via `cmake -DCNA_GRAPHICS_BACKEND=SDL_RENDERER` /
  `-DCNA_GRAPHICS_BACKEND=EASYGL -DCNA_BUILD_EXAMPLES=ON`, run via
  `xvfb-run -a --server-args="-screen 0 1024x768x24" env -u WAYLAND_DISPLAY ./<binary>` — no
  `DISPLAY` needs to be pre-set, `xvfb-run` handles that. Both backends' output PNGs are
  byte-for-byte identical for this scene (visually confirmed correct independently: the red
  marker lands in the destination rectangle's top-right corner, matching the rotation's own
  geometric derivation). Used for Ch.17 (SDL\_Renderer Backend) and Ch.18 (EasyGL Backend).

## Reproducing from a fresh clone

```bash
# 1. Clone cna as a sibling of sharp-runtime and easy-gl (its build expects them there)
cd /workspace   # or wherever the session's scratch root is
git clone --depth 1 https://github.com/openeggbert/cna.git   # if not already present

# 2. Fetch the vendored SDL3/SDL3_image/SDL3_mixer/googletest submodules (non-recursive)
cd cna
git submodule update --init

# 3. Install dev headers the vendored SDL3 build needs, plus ffmpeg dev libs CNA itself
#    requires unconditionally on Linux
apt-get install -y libxcursor-dev libxi-dev libxinerama-dev libxrandr-dev libxss-dev \
  libxext-dev libx11-dev libxtst-dev libxkbcommon-dev libwayland-dev wayland-protocols \
  libdecor-0-dev libdbus-1-dev libudev-dev libgbm-dev \
  libavcodec-dev libavformat-dev libavutil-dev libswresample-dev

# 4. Apply this stopgap patch (only needed if HEAD still doesn't compile without it --
#    try building first, and skip this step if it already succeeds). This patch also
#    registers both existing demo targets (cna_software_screenshot_demo,
#    cna_math_rotation_demo) in cmake/Tests/SoftwareTests.cmake.
git apply /home/user/cna-bible/tools/cna-screenshot-infra/contentreader-stopgap-and-demo-target.patch
cp /home/user/cna-bible/tools/cna-screenshot-infra/software_screenshot_demo.cpp examples/
cp /home/user/cna-bible/tools/cna-screenshot-infra/math_rotation_demo.cpp examples/

# 5. Configure with Unix Makefiles (or Ninja, if installed) and the SOFTWARE backend
cmake -B cmake-build-software -DCNA_GRAPHICS_BACKEND=SOFTWARE
cmake --build cmake-build-software --target cna_software_screenshot_demo cna_math_rotation_demo -j4

# 6. Run a demo headlessly -- produces a real PNG, no DISPLAY needed
env -u DISPLAY -u WAYLAND_DISPLAY ./cmake-build-software/cna_software_screenshot_demo
env -u DISPLAY -u WAYLAND_DISPLAY ./cmake-build-software/cna_math_rotation_demo
```

## Reproducing an SDL\_RENDERER / EASYGL screenshot via Xvfb (confirmed 2026-07-21)

These two backends open a real SDL3 window, so they need a real (if virtual) display, unlike
`SOFTWARE` above. `xvfb` and Mesa's software `llvmpipe` GL implementation must be installed
(`apt-get install -y xvfb libgl1-mesa-dri` if not already present — both were already present in
the container this was verified in).

```bash
cd cna   # same clone as above

# Apply the CMake-registration patch (adds the demo target to both backends' test files) and
# copy the demo source in, unless already present from a prior session in this same clone.
git apply /home/user/cna-bible/tools/cna-screenshot-infra/xvfb-demo-cmake-registration.patch
cp /home/user/cna-bible/tools/cna-screenshot-infra/xvfb_screenshot_demo.cpp examples/

# SDL_Renderer
cmake -S . -B build-sdlrenderer -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCNA_GRAPHICS_BACKEND=SDL_RENDERER -DCNA_BACKEND_SDL_RENDERER=ON -DCNA_BUILD_TESTS=ON
cmake --build build-sdlrenderer --target cna_xvfb_screenshot_demo -j"$(nproc)"
CNA_SCREENSHOT_OUT=/path/to/out.png xvfb-run -a --server-args="-screen 0 1024x768x24" \
  env -u WAYLAND_DISPLAY ./build-sdlrenderer/cna_xvfb_screenshot_demo

# EasyGL (needs CNA_BUILD_EXAMPLES=ON -- this backend's test block has always required it)
cmake -S . -B build-easygl -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCNA_GRAPHICS_BACKEND=EASYGL -DCNA_BACKEND_EASY_GL=ON -DCNA_BUILD_TESTS=ON -DCNA_BUILD_EXAMPLES=ON
cmake --build build-easygl --target cna_xvfb_screenshot_demo_easygl -j"$(nproc)"
CNA_SCREENSHOT_OUT=/path/to/out.png xvfb-run -a --server-args="-screen 0 1024x768x24" \
  env -u WAYLAND_DISPLAY ./build-easygl/cna_xvfb_screenshot_demo_easygl
```

`CNA_SCREENSHOT_OUT` selects the output path (defaults to `/tmp/cna_xvfb_screenshot.png` if
unset) — per this project's own org-wide build rules, use a real path, not one under a
per-session scratchpad that won't exist next time this is reproduced. `xvfb_screenshot_demo.cpp`
draws the same rotate-around-origin `SpriteBatch` scene as
`examples/easygl_spritebatch_rotation_golden_test.cpp` (Task 465/417) rather than
`software_screenshot_demo.cpp`'s raw-`VertexBuffer` 3D scene, since `SDL_RENDERER` throws on any
3D draw call by design (Chapter~17) — a 2D `SpriteBatch` scene is the one shape of demo that
actually runs on every backend, `SOFTWARE` included. Build only the one demo target shown, not
the full test suite, to keep build time down (the full CNA static library still has to build
once per backend, but nothing beyond it).

To add a **new** worked-example demo for a future chapter: write a new `examples/<name>.cpp`
following the demo pattern that fits the target backend (subclass `Game`, draw through
`SpriteBatch` for 2D-only backends or `BasicEffect`/raw vertex buffers for 3D-capable ones, call
`SaveBackBufferScreenshotEXT`), register it via the matching backend's own test macro
(`cna_software_test`/`cna_sdl_test`/`cna_easygl_test`/etc., defined near the top of that
backend's own `cmake/Tests/<Backend>Tests.cmake`), reconfigure and build. Copy the new source
file into this directory and regenerate the relevant patch file (`git diff -- <touched
cmake/Tests file(s)> > .../<name>.patch` from inside `cna/`) so a future session picks up the new
target too. Copy the resulting PNG into the book's own `latex/book/images/` (the whole book
merged into one directory tree on 2026-07-20 — there is no more separate `latex/volumeN/`) and
`\includegraphics` it from the chapter `.tex` file.
