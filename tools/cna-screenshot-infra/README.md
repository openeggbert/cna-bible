# Reproducing real CNA screenshots for this book

This directory preserves what a feasibility check (2026-07-20) found when trying to build
`cna` and capture a real, actually-rendered screenshot in this project's remote container
environment (headless: no `DISPLAY`, no GPU passthrough). `/workspace/cna` is a scratch clone
local to one session's container and is **not** persisted across sessions — reapply this patch
to a fresh clone at the start of any future session that needs to build CNA or capture a
screenshot.

## Findings

- CNA's checked-out HEAD at the time of this check did **not** compile for any backend: the
  content-pipeline's `ContentReader::ReadDecimal()`/`ReadChar()` are called by
  `DecimalDateTimeContentTypeReaders.hpp`/`PrimitiveContentTypeReaders.hpp` but were never
  implemented. `contentreader-stopgap-and-demo-target.patch` adds minimal, clearly-marked
  stopgap implementations (raw-byte-widening `ReadChar`, standard 4×int32 decimal-bits
  `ReadDecimal`) — **diagnostic-quality, not verified against real FNA encoding semantics**.
  Treat this as a real, current gap worth naming honestly in the book (Chapter 4, "Building
  CNA") if this is still reproducible when a chapter actually gets written, not as a permanent
  claim about the project — it may already be fixed upstream by the time any given session
  reads this.
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
- **Other backends**: `HEADLESS` exists but is logic-only (never rasterizes a real pixel, just
  reports the last `Clear()` color) — not useful for a screenshot. `CANVAS` is
  Emscripten/browser-only. `ASCII` decorates `SDL_RENDERER` and still needs a real X11 window.
  `EASYGL`/`SDL_RENDERER` screenshots are plausible via `Xvfb` + Mesa llvmpipe software GL
  (`xvfb`, `libgl1-mesa-dri` were already installed in the container checked) but this was
  **not actually tried** — treat as untested, not confirmed. D3D9/D3D11/D3D12/BGFX are
  Windows/GPU-only and unrealistic to screenshot in this container at all.

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

To add a **new** worked-example demo for a future chapter: write a new `examples/<name>.cpp`
following either existing demo's pattern (subclass `Game`, draw through
`BasicEffect`/`SpriteBatch`/raw vertex buffers as needed, call `SaveBackBufferScreenshotEXT`),
add one more `cna_software_test(cna_<name> examples/<name>.cpp)` line to
`cmake/Tests/SoftwareTests.cmake` (right where the existing two are registered), reconfigure
(`cmake .` from inside `cmake-build-software/`) and build. Copy the new source file into this
directory and regenerate `contentreader-stopgap-and-demo-target.patch`
(`git diff -- cmake/Tests/SoftwareTests.cmake include/.../ContentReader.hpp
src/.../ContentReader.cpp > .../contentreader-stopgap-and-demo-target.patch` from inside
`cna/`) so the next session's fresh clone picks up the new target too. Copy the resulting PNG
into the book's own `latex/volumeN/images/` and `\includegraphics` it from the chapter `.tex`
file.
