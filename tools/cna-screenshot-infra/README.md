# Screenshot evidence used by The CNA Bible

This directory preserves the small programs and historical CMake patches used to produce the
book's five raster figures. The figures are execution artifacts, not architectural diagrams.
Their captions and surrounding prose state which renderer, host route, and observation boundary
they establish.

The current edition is pinned to CNA `7a64362efef4119bf880459ef1704fb2c52199e2` and
sharp-runtime `f827a6c5349234d5ac938886788ed8eca8fe1c10`. Commands below use the current renderer
terminology and selector. The two patch files in this directory predate CNA's module and renderer
renames; they are retained as provenance and should not be applied to the pinned tree.

## Artifact inventory

| Source | Book use | Evidence boundary |
|---|---|---|
| `software_screenshot_demo.cpp` | CPU-rasterized triangle scene | SOFTWARE draw and PNG readback on the recorded Linux host |
| `math_rotation_demo.cpp` | Matrix-driven rotated triangle | SOFTWARE transform, draw, and readback |
| `quaternion_vs_matrix_demo.cpp` | Quaternion/matrix comparison | Numeric equality; its duplicate image was intentionally omitted |
| `rendertarget_roundtrip_demo.cpp` | Historical render-target defect | Reproduces the pre-fix blank-inset result; not current behavior |
| `xvfb_screenshot_demo.cpp` | SpriteBatch rotation | SDL Renderer and EasyGL implementation family under Xvfb/Mesa |

`HEADLESS` is not a screenshot renderer: it records the last clear color but does not rasterize
draw output. `SOFTWARE` rasterizes without SDL video, X11, or a GPU. SDL Renderer and EasyGL need
a window; Xvfb plus Mesa llvmpipe supplied that environment for the recorded Linux run.

## Current correction to the historical render-target finding

The July 2026 round-trip demo found that SOFTWARE could not sample a `RenderTarget2D` through
SpriteBatch. At the current pin this defect is fixed. `SoftwareTextureRenderer` and
`SoftwareRenderTargetRenderer` now expose the same read-only `SoftwareColorSurface` capability,
and the registered `rendertarget_sampling_orientation_test.cpp` exercises the route. The old PNG
remains useful as a dated example of a test discovering a defect; it must not be captioned as a
live SOFTWARE limitation.

The obsolete `contentreader-stopgap-and-demo-target.patch` also contains temporary
`ContentReader` methods. sharp-runtime now implements the relevant `BinaryReader` behavior. The
patch documents how the original capture was unblocked, not a dependency of a current build.

## Reproducing the windowed SpriteBatch figures

CNA already contains and registers `examples/xvfb_screenshot_demo.cpp` in the module-local SDL
Renderer and EasyGL example CMake files. Use a build directory outside the source checkout:

```bash
# SDL Renderer public identity -> SDL Renderer implementation family
cmake -S ../cna -B /tmp/cna-shot-sdl \
  -DCNA_GRAPHICS_RENDERER=SDL_RENDERER \
  -DCNA_BUILD_TESTS=ON
cmake --build /tmp/cna-shot-sdl --target cna_xvfb_screenshot_demo -j4
CNA_SCREENSHOT_OUT=/tmp/cna-sdl-renderer.png \
  xvfb-run -a --server-args="-screen 0 1024x768x24" \
  env -u WAYLAND_DISPLAY /tmp/cna-shot-sdl/cna_xvfb_screenshot_demo

# OPENGL33 public identity -> shared EasyGL implementation family -> desktop OpenGL API
cmake -S ../cna -B /tmp/cna-shot-open-gl \
  -DCNA_GRAPHICS_RENDERER=OPENGL33 \
  -DCNA_BUILD_TESTS=ON -DCNA_BUILD_EXAMPLES=ON
cmake --build /tmp/cna-shot-open-gl --target cna_xvfb_screenshot_demo_easygl -j4
CNA_SCREENSHOT_OUT=/tmp/cna-easygl.png \
  xvfb-run -a --server-args="-screen 0 1024x768x24" \
  env -u WAYLAND_DISPLAY /tmp/cna-shot-open-gl/cna_xvfb_screenshot_demo_easygl
```

The recorded environment used Xvfb and Mesa llvmpipe. A successful process and a PNG establish
execution and readback; renderer engagement should also be confirmed from CNA's startup trace.
Neither result transfers automatically to another GL profile, driver, OS, or native API.

## Reusing the SOFTWARE programs

The four SOFTWARE programs here are archival, book-local sources and are not registered in the
pinned CNA CMake graph. CNA's module split moved the relevant registration file to
`modules/renderers/software/examples/CMakeLists.txt`; the old patch targets the removed
`cmake/Tests/SoftwareTests.cmake` path and uses retired identifiers. If a figure must be
regenerated, port only the required `cna_software_test(...)` registration into a disposable CNA
worktree, copy the matching source there, configure with
`-DCNA_GRAPHICS_RENDERER=SOFTWARE -DCNA_BUILD_TESTS=ON`, and review the diff before building.
Do not apply the archived patch wholesale.

SOFTWARE requires neither `DISPLAY` nor `WAYLAND_DISPLAY`. A capture command should explicitly
unset both variables and should write to a disposable output path. Compare the result with a
named oracle before replacing a checked-in book image.

## Publishing rules

- Never present an AI-generated or mocked image as runtime output.
- Record the CNA revision, public renderer identity, implementation family, host, and native or
  translation API where applicable.
- Keep historical failure images labeled as historical after the defect is fixed.
- A screenshot is manual or pixel evidence for the shown scene; it is not blanket renderer
  support.
- Copy an accepted image into `latex/book/images/`, include it once, and let
  `tools/verify-book.sh` confirm source-to-PDF pixel identity.
