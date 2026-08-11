# Audit report — testing, verification, oracles and CI

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build, test or clone was run. Paths relative to the CNA repo root.

---

## FACTS

### A. Test infrastructure — how tests are registered

**F1. There is exactly one GoogleTest binary in the whole project: `CnaTests`.** It is created from a single `file(GLOB_RECURSE …)` over three roots — `modules/*/tests/*.cpp`, `modules/renderers/*/tests/*.cpp`, `tests/*.cpp` — at `cmake/UnitTests.cmake:26-30`, then `add_executable(CnaTests ${CNA_TEST_SOURCES})` at `:158-160`. There is no per-module test binary. **VERIFIED**

**F2. The glob is refined by nine `list(FILTER … EXCLUDE REGEX)` calls**, each with a documented cause (`cmake/UnitTests.cmake:37-156`): two Glide ABI programs that are standalone Win32/`main()` programs (`:37-38`); the minimal-link probes `tests/modules/*.cpp` (`:43`); five FFmpeg-dependent Video tests when `NOT CNA_FFMPEG_AVAILABLE` (`:52-58`); the whole `Net`/`GamerServices` test trees when `NOT CNA_ENABLE_NET` (`:76-93`, backed by a `FATAL_ERROR` self-check loop at `:87-91`); POSIX-`posix_spawn`-dependent tests on `WIN32 OR EMSCRIPTEN OR ANDROID` (`:95-126`); and the Wicked/Magnum/FNA3D renderer test directories unless that renderer is selected (`:136-156`). **VERIFIED**

**F3. `gtest_discover_tests(CnaTests DISCOVERY_MODE PRE_TEST WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")`** — `cmake/UnitTests.cmake:386`. `PRE_TEST` means the CnaTests case list is enumerated by *executing the binary* at `ctest` time, not at configure time. `WORKING_DIRECTORY` was added by REMED-BUILD-001 because CTest otherwise ran cases from the runtime output dir and they could not find `tests/assets/**` (`:381-385`). **VERIFIED**

**F4. Registration outside CnaTests goes through one helper, `cna_register_renderer_test()`** (`cmake/TestHelpers.cmake:21-58`), which collapses `add_test()` + `set_tests_properties()` into one call and `\;`-escapes semicolons inside `LABELS`/`ENVIRONMENT` values (`:31-37`). Its default `WORKING_DIRECTORY` is `${CMAKE_BINARY_DIR}` (`:49`), pinned after the Vulkan `demo_2d` Content-lookup abort caused by module-local registration (`:41-49`). **VERIFIED**

**F5. Exit code 77 is the project-wide "headless skip" convention.** Defined `inline constexpr int kSkipExitCode = 77;` in `modules/graphics/examples/common/PixelTestGame.hpp:278`; applied in bulk at root scope via `get_property(… DIRECTORY PROPERTY TESTS)` + `set_tests_properties(… SKIP_RETURN_CODE 77)` (`cmake/UnitTests.cmake:446-449`) and per-module-directory via `cna_apply_skip_convention()` (`cmake/TestHelpers.cmake:66-71`). **VERIFIED**

**F6. Exactly one renderer family is composed per configure.** `modules/renderers/CMakeLists.txt:78-80` enters only `${CNA_SELECTED_RENDERER}`; `metal` and `glide` are additionally entered unconditionally (`:63-64`) because their policy test suites deliberately compile under every renderer. `cmake/RendererSelection.cmake` ends in `message(FATAL_ERROR "CNA: Unknown graphics renderer: …")`. Consequence: **no single build can ever contain more than one renderer's CTest registrations.** **VERIFIED**

**F7. Examples were localized into owning modules and are a *separate corpus* from CnaTests.** 48 `examples/` directories hold 1233 `.cpp`, of which **1169 are named `*_test.cpp`** — but only **one** of those 1169 includes gtest. They are standalone programs with their own `main()`, built one-per-executable by a per-renderer macro (`cna_<renderer>_test(target src)`, e.g. `modules/renderers/headless/examples/CMakeLists.txt:19-31`) and registered individually as CTests. **They are not GoogleTest cases and never appear in `--gtest_list_tests`.** **VERIFIED**

**F8. Many example test sources are shared cross-renderer controls** pulled from `${CNA_GRAPHICS_EXAMPLES_DIR}` (= `modules/graphics/examples`, 77 `.cpp`), e.g. `cna_headless_test(cna_test_headless_colorspace_midtone ${CNA_GRAPHICS_EXAMPLES_DIR}/colorspace_midtone_contract_test.cpp)` (`modules/renderers/headless/examples/CMakeLists.txt:70-73`). Header comments there explicitly describe the design: the defect is renderer-local, the other renderers run the same public fixture as *controls*. **VERIFIED**

**F9. `tests/` at repo root now holds only fixtures and probes.** 136 asset files (30 XNB, 77 glTF, 29 media), 6 Direct2D debug-log fixtures + README in `tests/fixtures/direct2d/`, and 14 `tests/modules/probe_*.cpp` minimal-link probes with zero gtest macros. **VERIFIED**

**F10. Renderer-specific gating is three-layered:** (a) compile-time — the test source directory is excluded from the CnaTests glob unless its renderer is selected (`cmake/UnitTests.cmake:136-156`); (b) registration-time — every `modules/renderers/*/examples/CMakeLists.txt` opens with `if(CNA_BUILD_TESTS AND CNA_GRAPHICS_RENDERER STREQUAL "<R>")`; (c) run-time — `SKIP_RETURN_CODE 77` plus `ENVIRONMENT "SDL_VIDEODRIVER=x11;DISPLAY=${CNA_TEST_DISPLAY}"` (`CMakeLists.txt:72`). **VERIFIED**

**F11. Cross-compiled renderers get a Wine wrapper via `CROSSCOMPILING_EMULATOR`.** `cmake/UnitTests.cmake:317-378` sets it per renderer (D3D9/D3D11/D3D12/DX1/DX2/DX3/DX5/DX6/DX7/DX8/DX10/Direct2D), each with a `CNA_*_SKIP_*_GATE=1` because `gtest_discover_tests(PRE_TEST)`'s bare `--gtest_list_tests` never opens a device (`:303-316`). The same is done for `cna_strict_xna_api_check` at `cmake/Harnesses.cmake:202-213`. **VERIFIED**

**F12. Nine standalone process-isolation harnesses exist** (`cmake/Harnesses.cmake`): `cna_net_two_process_harness` (:9), `cna_net_gamerservices_dispatcher_harness` (:26), `cna_audio_no_hardware_harness` (:44), `cna_devices_shutdown_ordering_harness` (:65), `cna_audio_mixer_destroy_active_{static,dynamic}_voice_harness` (:92,:109), plus tools `cna_xnb_audio_metadata_dump` (:126), `cna_xwb_inspect` (:142), `cna_reference_dump` (:164), `cna_devices_microbenchmark` (:245). Each is spawned by a gtest case whose absolute built path is baked in as a `target_compile_definitions` string (`cmake/UnitTests.cmake:236-297`). The stated reason is always process-global state (`g_mixer`, `SDL_Quit()`, GamerServicesDispatcher). **VERIFIED**

**F13. A negative-compilation test exists.** `cna_strict_xna_api_leak_check` is `EXCLUDE_FROM_ALL`; its CTest command *is a build invocation*, marked `WILL_FAIL TRUE`, so the test passes only if the build fails — `cmake/Harnesses.cmake:220-235`. This is the only inverted-polarity CTest in the tree. **VERIFIED**

**F14. Fourteen minimal-link module probes plus link-closure gates** (`cmake/Tests/ModuleProbes.cmake:13-156`). Each `cna_add_module_probe(name module "<forbid-regex>")` builds a tiny consumer of one module alias, registers `ModuleProbe_<name>`, and registers `ModuleLinkClosure_<name>` which runs `scripts/check_module_link_closure.py` against the probe's generated `link.txt`. Example invariant: Math may link nothing but itself — `"libcna_(?!math)|libCNA_|libSDL3|libenet|libav|cna_renderer_"` (`:31`). **VERIFIED**

**F15. CTest labels in use** (derived from every `LABELS "…"` in `cmake/` + `modules/`): `Llgl, SdlGpu, WebGPU, Software, DIRECTX9, OpenGL2, Headless, DIRECTX11, Sokol, GraphicsSmoke, OpenGL4, FREEDIRECT, DIRECTX8, DIRECTX7, DIRECTX6, GDI, DIRECTX5, DIRECTX3, DIRECTX2, Skia, PortableGL, Fna3d, DIRECTX10, DIRECTX1, Display, Magnum, OpenVg, OpenGLES1, Audit, Wicked, Direct2D, Blend2D, Metal, Diligent, 2D, Unit, Raster, Lifetime, host-only, DIRECTX12, SVG_DOM, Stub, Soak, REMED-GFX-029, Portable, input, HTML_DOM, DiligentOpenGL, Correctness, Accelerated`. Naming is inconsistent (`DIRECTX9` upper vs `Llgl`/`Fna3d` mixed-case), and `GraphicsSmoke` is the only genuinely cross-renderer label (used by opengles1, wicked, magnum, llgl, sdl-renderer, easygl, webgpu, diligent, bgfx, vulkan). **VERIFIED**

**F16. Label discipline is not uniform — four renderers register almost everything unlabeled.** EasyGL: 293 registration statements, only 2 carry `LABELS` (`modules/renderers/easygl/examples/CMakeLists.txt:56, 1644`). Vulkan: 211 registrations, 1 `LABELS` (`:47`). bgfx: 179 / 1 (`:44`). sdl-renderer: 80 / 1. `ctest -L EasyGL` / `-L Vulkan` / `-L Bgfx` therefore select essentially nothing; `ctest -L GraphicsSmoke` selects one test each. **VERIFIED**

**F17. `ctest -L input` is a single CTest entry, not a label over many tests.** `cmake/UnitTests.cmake:402-413` defines `CNA_INPUT_TEST_FILTER` as the single source of truth (17 glob tokens) and registers one test, `CnaInputTests`, running `CnaTests --gtest_filter=${CNA_INPUT_TEST_FILTER} --gtest_shuffle --gtest_repeat=5` with `LABELS "input"` and `ENVIRONMENT "SDL_AUDIODRIVER=dummy"`. The `--gtest_repeat=5 --gtest_shuffle` is the documented order-independence gate for process-wide input singletons (`:404-411`). **VERIFIED**

### B. Oracle / differential testing

**F18. There is exactly one image-oracle corpus: `tools/xna-oracle/`** — 39 `.scene` declarative scene files and 39 matching 256×256 RGBA8 reference PNGs captured once by hand against the *real* XNA 4.0 runtime under Wine (`tools/xna-oracle/README.md:84-102`). The reference runner `tools/xna-oracle/Oracle.cs` (807 lines) **is** checked in; the compiled `Oracle.exe`, the XNA 4.0 runtime, and the `~/.wine-cna-xna40` WINEARCH=win32 prefix are **not** — the user must supply them, and only to *regenerate* references. **None of the checked-in gates need the XNA prefix** (`scripts/run-oracle-corpus-diff.sh:8-16`). **VERIFIED**

**F19. The CNA side is one renderer-agnostic source**, `tools/xna-oracle/CnaOracleRender.cpp` (905 lines), built five times as `cna_oracle_render{,_easygl,_opengles1,_fna3d,_skia}`. **VERIFIED**

**F20. The comparator is `scripts/xna-diff.py` — Pillow, absolute per-channel delta only.** `--tolerance` default **0** (`:51-52`); optional `--rgb-tolerance`/`--alpha-tolerance` (`:53-56`), `--max-raw-differing-pixels` budget (`:57-58`), `--allowed-raw-diff-rect X,Y,W,H` (`:59-60`). Pass criterion: `passed = (differing == 0) and raw_budget_passed and rect_passed` (`:133-137`). **There is no PSNR, SSIM, or perceptual metric anywhere in the repo** (`grep -rni "PSNR\|SSIM"` returns only false positives). Standing rule in the header (`:22-24`): raising tolerance without a documented per-scene reason "is exactly how an authenticity project quietly becomes a parity project." **VERIFIED**

**F21. Only three of five oracle scripts are registered as CTests.** `D3D9_XNA_Diff` — all 39 scenes at `--tolerance 0`, hard gate (`modules/renderers/directx9/examples/CMakeLists.txt:232`, script `scripts/run-oracle-corpus-diff.sh:59,70-74`). `Fna3d_XNA_Oracle` — all 39, but a *render-only* gate: exits 1 only if a scene fails to render (`modules/renderers/fna3d/examples/CMakeLists.txt:79-84`; `scripts/run-oracle-corpus-diff-fna3d.sh:101-104`). `Skia_XNA_2D_Oracle` — the 9 `spritebatchmode=true` scenes under a per-scene policy TSV, hard gate (`modules/renderers/skia/examples/CMakeLists.txt:172-179`). EasyGL and OpenGLES1 runners are deliberately unregistered one-time measurements. **VERIFIED**

**F22. Skia's per-scene tolerance policy is a checked-in TSV**, `tools/xna-oracle/skia-2d-policy.tsv`: 7 of 9 scenes pixel-exact (`0 0 0 -`); the two linear-filter scenes allow `rgb_tol 1, alpha_tol 0, max_raw_diff 1591, rect 88,88,80,80` / `48,48,80,80`. The runner additionally audits policy↔scene set equality in both directions and exits 2 on drift (`scripts/run-skia-2d-oracle-diff.sh:62-84`). **VERIFIED**

**F23. A second, non-image oracle chain compares numeric values against a live FNA.dll.** `tools/fna-reference/*.cs` (real FNA) vs `tools/cna-reference/CnaReferenceDump.cpp` (C++ mirror), diffed by `scripts/compare-fna-reference.py`: one-directional (FNA keys must exist in CNA; CNA-only `*EXT` keys tolerated, `:11-16`), numeric tolerance **default 1e-4 absolute** (`:51-52`), non-numerics exact (`:53-54`). Coverage: 21 enums, 16 state presets, 17 PackedVector types, 5 Viewport cases. **Not a CTest** — `cmake/Harnesses.cmake:157-160` documents it as a manual developer tool requiring mono/xbuild + a locally built FNA.dll. It found the real `IndexElementSize` divergence (16/32 vs 0/1). **VERIFIED**

**F24. `xna4-decomp` and `xna4-spec` are referenced *nowhere* in CNA.** `grep -rn 'xna4-decomp\|xna4-spec' --exclude-dir=.git .` → **0 hits**. Both sibling repos exist on disk but CNA's authoritative references are FNA's C# source at `/rv/data/library/github.com/FNA-XNA/FNA` and the real XNA runtime under Wine. `plan_net.md:1767-1769` explicitly disclaims decompilation for Avatar meshes. **VERIFIED (negative)**

**F25. Three kinds of in-corpus oracle exist in C++.** (i) Hand-derived golden value tables: `modules/graphics/tests/PackedVectorGolden.md:3-8` ("computed via Python using the same arithmetic as the FNA C# source") consumed at `modules/graphics/tests/Microsoft/Xna/Framework/Graphics/PackedVector/PackedVectorTests.cpp:83-88` with `EXPECT_NEAR(…, 1e-6f)`. (ii) Independent recomputation oracles compiled into the test binary: `modules/content/tests/CNA/Internal/GltfImport/GltfOracleEXT.hpp:4-17` — an "L2/L3/L4 numerical oracle ladder" that recomputes glTF node composition rather than asking CNA. (iii) Shared pixel oracles in headers: `modules/graphics/tests/Microsoft/Xna/Framework/Graphics/WireFrameTriangleOracle.hpp:4-9` ("two copies of a pixel oracle drift"). **VERIFIED**

**F26. A renderer-vs-renderer differential exists separately** (`docs/direct2d-easygl-differential.md`): one source `modules/graphics/examples/cross_renderer_2d_corpus.cpp` dumps a 64×64 RGBA8 framebuffer per renderer; `cross_renderer_diagnostic_compare.cpp:79-84` fails iff `maxDiff > tolerance`, **tolerance 4** in documented use but **default 40** when the argument is omitted. An explicit whitelist keeps linear filtering/mip/aniso/MSAA/non-right-angle rotation *out* of the corpus so no tolerance has to be widened (`docs/direct2d-easygl-differential.md:47-64`). **VERIFIED**

**F27. LZX decompression has a byte-exact differential against FNA's own `LzxDecoder.cs` run under Mono**, with reference bytes vendored at `tests/assets/xnb/monogame/windows/lzx/reference-decompressed/` (`plan_xnb.md:500`). It found and fixed a real heap-buffer-overflow. **STRONG** (implementation file present; the run-record is a plan claim).

### C. Pixel / golden testing

**F28. All C++ pixel comparison lives in one header**, `modules/graphics/examples/common/PixelTestGame.hpp`. `ExpectPixel(label, region, expected, tolerance=0)` (`:95-139`) compares **R/G/B only; alpha is deliberately ignored** (`:74-76, 109-111`). `CompareGoldenImage(label, region, path, tolerance=0)` (`:170-245`) fails on dimension mismatch (`:205-212`), then per-channel `|Δ| <= tolerance` on RGB only, bailing at the first mismatch (`:217-239`). `CNA_UPDATE_GOLDEN` set to any non-empty value rewrites the PNG from the live render (`:186-200`). **VERIFIED**

**F29. Golden images: 17 PNGs, all 8×8 RGBA8, all in `examples/golden/`, all named `easygl_*`.** There are **zero** golden images under `tests/`, `modules/*/tests/`, or `modules/*/examples/`. **VERIFIED**

**F30. Only two renderers do golden-image comparison: easygl produces, opengl2 consumes.** 27 files call `CompareGoldenImage` — 14 easygl, 13 opengl2, and opengl2's tests reuse the *same* `easygl_*.png` at the *same* tolerances (`modules/renderers/opengl2/examples/opengl2_basiceffect_golden_test.cpp:84-85`). **VERIFIED**

**F31. Golden tolerances range 0–60 on an 8-bit channel.** Exact: smoke 0; basiceffect 8; dualtexture 8; texture-filter-linear 10; blendstate-additive 10; environmentmap 20; alphatest 20; rasterizerstate-cullmode 30; skinnedeffect 40; spritebatch-rotation 60; depthstencil-write-enable 60; pbreffect 35/25/20/30. The header justifies this at `PixelTestGame.hpp:166-169` (Task 462's 98-file tolerance survey). A tolerance of 60 is ~24% of channel range — these goldens catch gross regressions, not shading drift. **VERIFIED**

**F32. Single-pixel testing is much broader than golden testing: 340 `ExpectPixel(` call sites across 70 files**, and 169 example `.cpp` files across 12 renderer families include `PixelTestGame` (opengl2 48, sdl-gpu 33, llgl 24, opengl4 20, easygl 17, fna3d 11, sokol 8, vulkan 3, openvg 2, metal 1, directx11 1, bgfx 1). **VERIFIED**

**F33. `RunPixelTest<TGame>()`** (`PixelTestGame.hpp:307-354`) does a headless pre-flight `SDL_InitSubSystem(SDL_INIT_VIDEO)`, returns 77 on failure (`:313-318`), releases the probe (`:319-322`), then runs. One narrow catch: `VK_ERROR_SURFACE_LOST_KHR` in `what()` → skip (`:343-352`); every other exception is rethrown, deliberately, so a genuine pipeline bug still crashes. `Draw()` runs the test exactly once via a `done_` latch (`:260-266`) — strictly single-frame. **VERIFIED**

**F34. Consequence of F5+F33: a headless CI with no display converts the entire pixel/golden layer to SKIPPED, not FAILED.** A green `ctest` is not, by itself, evidence any pixel was ever compared. **STRONG**

**F35. `scripts/run-all-renderer-smoke-tests.sh` iterates only 4 renderers** — OPENGLES3→`cmake-build-debug`, VULKAN→`cmake-build-vulkan`, BGFX→`cmake-build-bgfx`, SDL_RENDERER→`cmake-build-sdl` (`:24-30`) — configures only if the build dir is absent (`:39-43`), builds with `-j4 -- -k` **ignoring the build exit code** (`:47-51`), then runs `ctest -L GraphicsSmoke`. A configure failure is `SKIPPED`, not `FAIL` (`:41-43, 63-70`). **It is invoked from nowhere in the repo** (the only 5 hits are rename-map/hash rows under `modularization/`). Neither golden-image renderer (easygl per-name, opengl2) is in its list. **VERIFIED**

### D. Wine / Proton

**F36. Every `run-wine-*.sh` is the same nine-step program** (canonical: `scripts/run-wine-dxvk.sh`): `set -uo pipefail` (deliberately not `-e`, `:30`); argc → exit 2 (`:32-35`); `WINEPREFIX` from `CNA_<X>_WINEPREFIX` with a default (`:37`); `WINEDEBUG` default; log-level default; `unset WAYLAND_DISPLAY` on the DDraw family + dx8 + dx10; **prefix reuse only — `if [ ! -f "${WINEPREFIX}/system.reg" ]` prints the setup recipe and exits 1 (`:41-45`), no wrapper ever runs `wineboot`**; `wine "$@" 2>&1 | tee "$logFile"` capturing `PIPESTATUS[0]` (`:47-51`); then the gate. **VERIFIED**

**F37. The "gate" is a grep over the tee'd log, and `CNA_*_SKIP_*_GATE=1` short-circuits it.** Patterns: `DXVK: [0-9]+\.[0-9]+` for D3D9/D3D11/DX8/D3D10; `vkd3d-proton - applicationVersion: …` for D3D12; `:ddraw:` (via `WINEDEBUG=+ddraw`) for DX1/2/3/5/6/7. **Gate failure returns exit 3 unconditionally and discards the program's own exit code** (`run-wine-dxvk.sh:60`). The rationale (`:14-22`): a broken DXVK install silently degrades to WineD3D, and green CTest output alone never reveals it. **DXVK/vkd3d presence is never a filesystem probe.** **VERIFIED**

**F38. Wine prefix map:** `~/.wine-cna-d3d11` for **both** D3D11 and D3D9 (`run-wine-dxvk9.sh:54`); `~/.wine-cna-d3d12`; **one shared `~/.wine-cna-dx1` for DIRECTX1/2/3/5/6/7** (the five later scripts are byte-for-byte clones of dx1 with the var prefix renamed); dedicated `~/.wine-cna-dx8` and `~/.wine-cna-d3d10`; and — uniquely — **`$HOME/.wine` for Direct2D** (`run-wine-direct2d.sh:30`). `run-wine-directx10.sh:53` is the only wrapper that *forces* `DISPLAY=:0` (a DXVK `dxgi.dll` EDID bug crashes under Xvfb). `run-wine-directx8.sh:65` forces `DXVK_FILTER_DEVICE_NAME=llvmpipe` to dodge a RADV `VK_ERROR_SURFACE_LOST_KHR`. **VERIFIED**

**F39. Proton differs from Wine in six ways** (`scripts/run-proton-direct2d.sh`, `run-proton-vkd3d.sh`): it bootstraps its own prefix (`STEAM_COMPAT_DATA_PATH`, `:152/:60`) rather than refusing to create one; launches via `exec python3 "${PROTON_DIR}/proton" run`; sets Steam plumbing vars; **pins the runtime** from `scripts/direct2d-proton-pin.txt` (`Proton 9.0 (Beta)`, `Proton 8.0`) and *refuses* any `*Experimental*` directory unless `CNA_DIRECT2D_PROTON_ALLOW_EXPERIMENTAL=1`, then warns the evidence is "NOT reproducible" (`:86-98`); records runtime identity including the DXVK version mined out of the shipped `d3d11.dll` with `strings … | grep -oE 'dxvk-v?[0-9]+…'` (`:110-146`); and **has no log gate at all** — pass is the test's own exit code. Both Proton scripts hard-refuse a prefix under `~/.wine` (`:159-165`, `:82-89`), the latter documenting a real 2026-07-14 incident that half-upgraded the developer's personal prefix and hung for 9.5 h. **VERIFIED**

**F40. `run-direct2d-virtual-display.sh` is the single Xvfb decision point** — reentrant, geometry-validated against `^[1-9][0-9]*x[1-9][0-9]*x(8|15|16|24|30)$` (`:39-43`), private `mktemp -d` Xauthority removed on `EXIT INT TERM` (`:47-51`), `xvfb-run -a -f … -s "-screen 0 ${SCREEN} -nolisten tcp"` (`:58`). `run-direct2d-fresh-wine-suite.sh` proves developer-state independence: throwaway `mktemp -d` prefix, refusal if it resolves under `~/.wine` (`:47-52`), `wineboot --init` as the only declared dependency (`:13-17`), then `ctest --test-dir <build> -L Direct2D`. **VERIFIED**

### E. Browser testing

**F41. The stack is Playwright's bundled headless Chromium — not Puppeteer.** All three `.mjs` drivers resolve it through CommonJS because ESM ignores `NODE_PATH`: `const require = createRequire(import.meta.url); const { chromium } = require('playwright');` (`scripts/htmldom-browser-test.mjs:12-13`, `htmldom-host-integration-test.mjs:21-22`, `svgdom-browser-test.mjs:16-17`); the shells pass `NODE_PATH="$(npm root -g)"`. **VERIFIED**

**F42. Pages are served over HTTP, never `file://`** — `python3 -m http.server "${PORT}" --directory "${BUILD_DIR}" --bind 127.0.0.1` backgrounded with a `kill` trap and up to 50×0.1 s `curl` readiness polls (`scripts/run-htmldom-browser-test.sh:51-60`). `run-htmldom-test-suite.sh:33-34` assigns ports 8731–8736 so concurrent runs cannot collide. **VERIFIED**

**F43. The verdict channel is `window.*`, because the wasm process exit code is unobservable.** `await page.waitForFunction('window.__cnaSmokeDone === true', …)` with `CNA_HTMLDOM_TEST_TIMEOUT_MS` default 60000 (`htmldom-browser-test.mjs:21,162`), then reads `__cnaSmokeResult/__cnaSmokePassed/__cnaSmokeExpected`. Any console line containing `[FAIL]` or any `pageerror` sets `sawFailLine` (`:148-157`). **VERIFIED**

**F44. Real compositor pixel readback goes screenshot → base64 → in-page `<canvas>` → `getImageData`** (`htmldom-browser-test.mjs:32-79`), with coordinates offset by `#cna-dom-root`'s `getBoundingClientRect()`. Smoke: `(70,70)` ≈ `(255,0,0)` and `(90,90)` ≈ CornflowerBlue, **tolerance ±12** (`:59-66`). Pixel test: `(12,21)` and `(39,21)` both pure red, **tolerance ±25**, deliberately tight because the DOM path must not bleed (`:120-133`). Pass = `result.code === 0 && !sawFailLine && screenshotOk` (`:180`). **VERIFIED**

**F45. `htmldom-host-integration-test.mjs` rewrites HTML source text via `page.route()`** (`:39-44, 72-79`) because `addInitScript` was measurably not early enough to beat the module bootstrap (`:1-11`). It asserts host-owned-DOM refusal: host div still owned, no `#cna-dom-viewport`, `Module['cnaDomRoot']` null, and a console line containing `refusing to proceed` (`:86-93`). **VERIFIED**

**F46. `svgdom-browser-test.mjs` adds structural namespace assertions the htmldom driver has no analogue of** (`:48-69`): `#cna-svg-dom-root` must have `namespaceURI === 'http://www.w3.org/2000/svg'`, tag `svg`; `Module['canvas'].style.visibility === 'hidden'`; every flush-slot container and child must be an SVG-namespace node — proving no other renderer is masquerading behind the identity. Plus a 4-point scissor-order pixel check at **tolerance ±20** (`:92-109`). **VERIFIED**

**F47. No browser test is registered as a CTest** — `modules/renderers/html-dom/examples/CMakeLists.txt:19-24` states why (`SDL_Init(SDL_INIT_VIDEO)` throws under bare `node` before any renderer code runs). `run-svgdom-browser-test.sh` has no automated caller at all. **VERIFIED**

### F. Sanitizers, validation layers, fuzzing, property testing

**F48. One sanitizer knob exists in the main build: `CNA_SANITIZE`** — `CMakeLists.txt:88-93`, applied *after* the vendored SDL/ENet configure so those stay uninstrumented, as `add_compile_options(-fsanitize=${CNA_SANITIZE} -fno-omit-frame-pointer -g)` + matching link options. **VERIFIED**

**F49. Three sanitizer presets exist, all pinned to OPENGLES3 + `CNA_DEVICES=ON`** (`CMakePresets.json`): `devices-asan` (`-fsanitize=address … -O0`), `devices-tsan` (`-fsanitize=thread … -O1`), `devices-ubsan` (`-fsanitize=undefined … -O1`). They set raw `CMAKE_CXX_FLAGS`, **not** `CNA_SANITIZE` — two independent mechanisms. TSan's description records one known pre-existing race in sharp-runtime's `TimeSpan` copy constructor. There is **no** ASan/TSan/UBSan preset for any non-Devices configuration. **VERIFIED**

**F50. Sanitizers in CI: exactly two legs.** `input-ci.yml:42-46` (`-DCNA_SANITIZE=address,undefined`, `ASAN_OPTIONS=detect_leaks=0:halt_on_error=1`, `UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1`) and `devices-tests.yml:125` (`cmake --preset devices-ubsan`). **No TSan and no ASan-alone run in CI.** **VERIFIED**

**F51. Two Skia-specific UBSan carve-outs exist:** `-fno-sanitize=vptr` under `CNA_SANITIZE MATCHES "(^|,)undefined(,|$)"` — in `cna_skia_test()` (`modules/renderers/skia/examples/CMakeLists.txt:26-30`) and in `cmake/Harnesses.cmake:277-280`, both because the pinned no-RTTI Skia archives cannot provide `typeinfo for GrDirectContext`. **VERIFIED**

**F52. GPU validation layers are wired per renderer.** Vulkan: `VK_LAYER_KHRONOS_validation` (`modules/renderers/vulkan/src/VulkanRenderer.cpp:157`) plus sync validation chained via `VkValidationFeaturesEXT` (`:1870-1873`), and three Vulkan example tests *assert the layer is active* (`vulkan_swapchain_sync_test.cpp:490`, `vulkan_mrt_mip_finalization_test.cpp:561`, `vulkan_cube_face_readback_dependency_test.cpp:495`). D3D11/Direct2D: `D3D11_CREATE_DEVICE_DEBUG` with a `DXGI_ERROR_SDK_COMPONENT_MISSING` fallback (`DirectX11Renderer.cpp:132-157`). Metal: CI sets `MTL_SHADER_VALIDATION=1` + `MTL_DEBUG_LAYER=1` (`metal-macos-ci.yml:72-74`). WebGPU: `wgpuDevicePushErrorScope(device_, WGPUErrorFilter_Validation)` (`WebGPURenderer.cpp:6887`). **VERIFIED**

**F53. Fuzzing is four in-corpus GoogleTest files, 8 `*Fuzz*` macros — no libFuzzer, no AFL, no OSS-Fuzz.** `modules/audio/tests/CNA/Internal/Audio/XactParserFuzzTests.cpp`, `modules/content/tests/CNA/Internal/Xnb/LzxDecoderFuzzTests.cpp`, `.../XnbContainerFuzzTests.cpp`, `modules/input/tests/CNA/Internal/Input/SdlInputBridgeFuzzTests.cpp`. They are deterministic mutation fuzzers over real payloads, running inside CnaTests. **VERIFIED**

**F54. Property testing is one file, hand-rolled — no RapidCheck/QuickCheck dependency.** `modules/content/tests/CNA/Internal/Xnb/SoundEffectContentTypeReaderPropertyTests.cpp`. **VERIFIED**

**F55. Mutation testing exists for exactly one renderer.** `scripts/direct2d_mutation_check.py`: 7 mutations against `modules/renderers/direct2d/src/Direct2DRenderer.cpp` (`:46-123`), each pinned to an anchor string that must occur **exactly once** (`:130-136`). `--run` rebuilds and runs `ctest -R "^<test>$"` with **inverted polarity — a passing test means the mutation survived, which is a failure** (`:157-158`). It writes to tracked source and reverts in `finally` (`:196-197`). Premise (`:5-6`): "A green suite says nothing until you know it can go red." **VERIFIED**

**F56. `scripts/avatar_visual_regression_check.py` is a structural-metric floor, not an image comparison.** Runs the real `cna_demo_avatar` under `xvfb-run --smoke 30 --screenshot` for 3 pinned poses (`:56-74, 171-172`) and measures "speckle" — dark pixels having a bright 4-neighbour, `DARK_SUM=150`, `BRIGHT_SUM=420` on the 0..765 R+G+B scale (`:49-53`) — the signature of mesh interpenetration. Recorded floors with measured values in comments (`:82-93`): global avg brightness ≥ 330 (measured 348–364); per-region `(max_speckle, max_very_dark_pct)` groin `(20,1.0)`, each foot `(75,1.0)`, torso_shoulder `(150,1.0)`. Left and right feet tracked separately on purpose. It states twice (`:31-33`, `:214-216`) that passing does **not** mean the avatar looks correct. **VERIFIED**

### G. CI reality

**F57. Eight workflows exist; six trigger automatically, two are `workflow_dispatch`-only.** Auto: `general-tests-ci.yml`, `input-ci.yml`, `devices-tests.yml`, `htmldom-ci.yml`, `metal-macos-ci.yml`, `32bit-arithmetic-ci.yml`. Manual-only: `d3d-windows-ci.yml:31` and `gdi-windows-ci.yml:11`. The D3D workflow explicitly calls itself "a narrow, project-owner-approved exception to this project's general 'no CI automation' stance" (`:15-19`). **VERIFIED**

**F58. What each workflow actually runs:**

| Workflow | Trigger | Configure | Test command |
|---|---|---|---|
| `general-tests-ci` | push + PR + dispatch | `-DCNA_GRAPHICS_RENDERER=EASYGL`, Debug, tests+examples ON, `-DCNA_TEST_DISPLAY=:99`, full `all` build (`:131-144`) | `ctest --output-on-failure` **unfiltered** (`:153`), then a 4-name known-failure classifier (`:164-206`) |
| `input-ci` | push (feature/input, develop, master) + PR + dispatch | 5-leg matrix EASYGL / EASYGL+ASan+UBSan / SDL_RENDERER / VULKAN / BGFX; builds **only** target `CnaTests` (`:111`) | `xvfb-run -a ctest --test-dir build -L input --output-on-failure` (`:125`) |
| `devices-tests` | push + PR + dispatch | `cmake --preset devices-ubsan` (`:125`) | **runs the binary directly, not ctest**: `./cmake-build-devices-ubsan/CnaTests --gtest_filter="$DEVICES_GTEST_FILTER"` then `"$CNA_DEVICES_GTEST_FILTER"` (`:135, 142`), then builds+runs `cna_strict_xna_api_check` (`:154-157`) |
| `htmldom-ci` | push + PR + dispatch | emsdk + `emcmake … -DCNA_GRAPHICS_RENDERER=HTML_DOM`, Playwright+Chromium, Xvfb :99 | `scripts/run-htmldom-test-suite.sh cmake-build-htmldom` (`:127`) |
| `metal-macos-ci` | push + PR + dispatch, macos-14 | `-DCNA_GRAPHICS_RENDERER=METAL` | `ctest -R '^Metal' --parallel 3` with `MTL_SHADER_VALIDATION=1 MTL_DEBUG_LAYER=1`; plus `ctest -R '^GraphicsRendererCompileDefinitionsTest\.'` |
| `32bit-arithmetic-ci` | push + PR + dispatch | `cmake -S tools/media/arithmetic32bit -B … -DCMAKE_C_FLAGS=-m32` | runs 3 overflow-check binaries directly (`:81-83`) |
| `d3d-windows-ci` | **dispatch only** | MSVC/Ninja, matrix DIRECTX11/DIRECTX12/DIRECT2D, `CNA_BUILD_EXAMPLES=OFF CNA_ENABLE_NET=OFF` | `ctest -L <renderer>`; Direct2D leg runs `-L Direct2D --verbose` under `CNA_DIRECT2D_DEBUG_LAYER=1` + a forced-WARP `-R '^Direct2D_Lifetime$'` pass, gated by `verify-direct2d-debug-log.py`; DIRECTX11 leg runs `verify_hlsl_shaders_native_msvc.py` |
| `gdi-windows-ci` | **dispatch only** | MSVC native | builds 17 named executables then `ctest -L GDI` (`:98`) |

**VERIFIED**

**F59. CnaTests is never built on Windows CI.** `d3d-windows-ci.yml:21-26` states it explicitly: ~10 test files call POSIX-only `::setenv()`, which MSVC lacks; the job builds only the renderer's own self-contained executables. **VERIFIED**

**F60. Only seven scripts are wired into CI**, all in `d3d-windows-ci.yml` and `htmldom-ci.yml`: `direct2d_mutation_check.py` (`--dry-run` only), `validate_direct2d_plan.py`, `verify-direct2d-debug-log.py` (both `--self-test` and real), `verify-direct2d-parallel-jobs.sh`, `verify_hlsl_shaders_native_msvc.py`, `run-htmldom-test-suite.sh`, `run-htmldom-browser-test.sh`. **Every other script is either a CTest command or manual-only.** Since both D3D workflows are dispatch-only, five of those seven never run on a push. **VERIFIED**

**F61. 30 scripts are wired as CTest commands** (see SCRIPT CATALOG). Because of F6, at most one renderer family's set can be active in any configure — e.g. the eight `check-directx*` discipline gates are eight *different* builds. **VERIFIED**

### H. Coverage

**F62. There is no code-coverage tooling anywhere in the repo.** `grep -rniE '\-\-coverage|gcov|lcov|llvm-cov|gcovr|-fprofile'` over all `*.cmake`, `CMakeLists.txt`, `*.sh`, `*.py`, `*.yml`, `*.json` (excluding vendor/third_party/cmake-build-debug) → **zero hits**. **VERIFIED**

**F63. `docs/coverage.md` is not code coverage — it is an XNA-4.0 API-surface coverage snapshot**, dated 2026-06-21 at HEAD `04f0692`, method "static source inspection … Build was not run during analysis" (`:3-10`). It is explicitly self-labelled "a one-time dated snapshot, not continuously updated" (`:34-35`). Five sibling docs share the "coverage" name with different meanings: `devices-api-coverage.md`, `gdm-coverage.md`, `input-test-coverage.md`, `xna-4-api-coverage.md`. **VERIFIED**

---

## COUNTS

### Statically derivable

Where a command uses `$FILES`, it is:

```bash
FILES=$(find modules -path 'modules/*/tests/*' -name '*.cpp' -type f; find tests -name '*.cpp' -type f)
```

| # | Number | Exact definition | Derivation command | Conf. |
|---|---:|---|---|---|
| C1 | **433** | `.cpp` files matched by the CnaTests glob roots (union, deduped) | `{ find modules -path 'modules/*/tests/*' -name '*.cpp' -type f; find tests -name '*.cpp' -type f; } \| sort -u \| wc -l` | VERIFIED |
| C2 | **361** | test `.cpp` under `modules/<non-renderer>/tests/**` | `find modules -path 'modules/*/tests/*' -name '*.cpp' -type f \| grep -v '^modules/renderers/' \| wc -l` | VERIFIED |
| C3 | **58** | test `.cpp` under `modules/renderers/*/tests/**` | `find modules/renderers -path 'modules/renderers/*/tests/*' -name '*.cpp' -type f \| wc -l` | VERIFIED |
| C4 | **14** | `.cpp` under `tests/` — all `tests/modules/probe_*.cpp`, all **excluded** from CnaTests | `find tests -name '*.cpp' -type f \| wc -l` | VERIFIED |
| C5 | **20** | header files (`.hpp`/`.h`) in test directories (shared oracles/fixtures, not TUs) | `{ find modules -path 'modules/*/tests/*' \( -name '*.hpp' -o -name '*.h' \) -type f; find tests \( -name '*.hpp' -o -name '*.h' \) -type f; } \| wc -l` | VERIFIED |
| C6 | **6818** | GoogleTest macro instantiations across *all* test-dir `.cpp` (5218 `TEST` + 1593 `TEST_F` + 7 `TEST_P`) | `grep -hE '^[[:space:]]*(TEST\|TEST_F\|TEST_P)\(' $FILES \| wc -l` | VERIFIED |
| C7 | **6670** | GoogleTest macros **compiled into CnaTests in the default Linux configure** (OPENGLES3, NET=ON, FFmpeg available) = C6 − Wicked 36 − Magnum 71 − FNA3D 41 | C6 minus `grep -hE '^[[:space:]]*(TEST\|TEST_F\|TEST_P)\(' $(find modules/renderers/{wicked,magnum,fna3d}/tests -name '*.cpp') \| wc -l` per directory | VERIFIED |
| C8 | **6670** | fully-parsed `Suite.Name` pairs in that set — identical to C7, i.e. **no multi-line macro headers and no false positives** | python `re.finditer(r'^[ \t]*(TEST\|TEST_F\|TEST_P)\(\s*([A-Za-z_]\w*)\s*,\s*([A-Za-z_]\w*)\s*\)', src, re.M)` over the same file set | VERIFIED |
| C9 | **6** | `INSTANTIATE_TEST_SUITE_P` sites (0 `TYPED_TEST`, 0 `TYPED_TEST_P`) | `grep -hE '^[[:space:]]*INSTANTIATE_TEST_SUITE_P\(' $FILES \| wc -l` | VERIFIED |
| C10 | **628** | distinct GoogleTest suite names across all test dirs | `grep -hoE '^[[:space:]]*(TEST\|TEST_F\|TEST_P)\([[:space:]]*[A-Za-z_][A-Za-z0-9_]*' $FILES \| sed -E 's/.*\([[:space:]]*//' \| sort -u \| wc -l` | VERIFIED |
| C11 | **16784** | `EXPECT_*`/`ASSERT_*` assertion sites in test dirs | `grep -hoE '\b(EXPECT\|ASSERT)_[A-Z_]+\(' $FILES \| wc -l` | VERIFIED |
| C12 | **541** | GoogleTest cases selected by `CNA_INPUT_TEST_FILTER` in the default configure. `ctest -L input` executes these **5×** shuffled = **2705** case executions | python: `fnmatch.fnmatchcase` of the 17 `:`-separated tokens from `cmake/UnitTests.cmake:403` against C8's `Suite.Name` set | VERIFIED |
| C13 | **522 / 0** | macros in `modules/input/tests/**` / of those, ones the filter misses | same python script, restricted to `'/input/tests/' in path` | VERIFIED |
| C14 | **446 of 462** | cases selected by `DEVICES_GTEST_FILTER` out of all macros under `modules/devices/tests/Microsoft/Devices/` — **16 unselected** | same python script with the `devices-tests.yml:56` token list; denominator `grep -rhE '^[[:space:]]*(TEST\|TEST_F\|TEST_P)\(' modules/devices/tests/Microsoft/Devices/ \| wc -l` | VERIFIED |
| C15 | **50 of 50** | cases selected by `CNA_DEVICES_GTEST_FILTER` out of `modules/devices-ext/tests/**` | same, with the `devices-tests.yml:61` token list | VERIFIED |
| C16 | **1624** | `cna_register_renderer_test(` statements repo-wide (3 of which are wrapper-function *bodies* in skia) | `grep -rnE '^[[:space:]]*cna_register_renderer_test\(' cmake/ modules/ \| grep -vc TestHelpers` | VERIFIED |
| C17 | **164** | skia wrapper-function *calls* (131 `_display_`, 30 `_raster_`, 3 `_accelerated_`) | `grep -oE '^[[:space:]]*cna_register_skia_[a-z_]+\(' modules/renderers/skia/examples/CMakeLists.txt \| sed 's/[[:space:]]//g' \| sort \| uniq -c` | VERIFIED |
| C18 | **1785** | total distinct CTest registration statements via the helper = C16 − 3 + C17 | arithmetic on C16/C17 | VERIFIED |
| C19 | **31** | raw `add_test(` statements outside `cmake/TestHelpers.cmake` (excludes vendor/third_party) | `grep -rnE '^[[:space:]]*add_test\(' cmake/ modules/ tools/ CMakeLists.txt \| grep -vc TestHelpers` | VERIFIED |
| C20 | **30** | CTest registrations produced by `cmake/Tests/ModuleProbes.cmake` in the default Linux configure: 14 `ModuleProbe_*` + 13 `ModuleLinkClosure_*` + `_CnaExtComposition` + `_NetHasENet` + `RendererIdentityRegistry`. HEADLESS adds 5; VULKAN adds 1 | `grep -cE '^[[:space:]]*cna_add_module_probe\(' cmake/Tests/ModuleProbes.cmake` (=14) plus a read of `:13-156` for the conditional blocks | VERIFIED |
| C21 | see below | per-renderer registration statements (upper bound; nested `if()`s may suppress some) | `for d in modules/renderers/*/examples/CMakeLists.txt; do grep -cE '^[[:space:]]*(cna_register_renderer_test\|add_test)\(' $d; done` | VERIFIED |
| C22 | **1233 / 1169 / 64** | `.cpp` under `modules/*/examples/**` / named `*_test.cpp` / other | `find modules -path 'modules/*/examples/*' -name '*.cpp' \| wc -l`; same with `-name '*_test.cpp'`; same with `! -name '*_test.cpp'` | VERIFIED |
| C23 | **1** | of the 1169 `*_test.cpp` examples that reference gtest | `grep -l gtest $(find modules -path 'modules/*/examples/*' -name '*_test.cpp') \| wc -l` | VERIFIED |
| C24 | see below | test executables per renderer via the `cna_<r>_test(` macro | `for d in modules/renderers/*/examples/CMakeLists.txt; do m=$(grep -oE '^[[:space:]]*macro\(cna_[a-z0-9_]+_test' $d \| head -1 \| grep -oE 'cna_[a-z0-9_]+_test'); grep -cE "^[[:space:]]*${m}\(" $d; done` | VERIFIED |
| C25 | **46** | canonical public renderer identities (the script's own table) | `python3 -c "import re; s=open('scripts/check_renderer_identities.py').read(); m=re.search(r'IDENTITIES = \[(.*?)\n\]', s, re.S); print(len(re.findall(r'\(\"[A-Z0-9_]+\",\s*\"\w+\"\)', m.group(1))))"` | VERIFIED |
| C26 | **42** | renderer *family* directories under `modules/renderers/` (excluding `common/` and `CMakeLists.txt`) | `ls -1 modules/renderers/ \| grep -vx 'common\|CMakeLists.txt' \| wc -l` | VERIFIED |
| C27 | **39 / 39** | XNA oracle scenes / reference PNGs (256×256 RGBA8) | `ls tools/xna-oracle/scenes/*.scene \| wc -l`; `ls tools/xna-oracle/reference/*.png \| wc -l` | VERIFIED |
| C28 | **9** | oracle scenes in the SpriteBatch-only ("2D") subset used by Skia | `grep -l '^spritebatchmode=true$' tools/xna-oracle/scenes/*.scene \| wc -l` | VERIFIED |
| C29 | **17** | golden PNGs, all 8×8 RGBA8, all in `examples/golden/` | `ls examples/golden/*.png \| wc -l` | VERIFIED |
| C30 | **0** | golden images under `tests/`, `modules/*/tests/`, `modules/*/examples/` | `find tests modules \( -iname '*.png' -o -iname '*.ppm' -o -iname '*.bmp' \)` → 23 hits, all demo/content assets, none golden | VERIFIED |
| C31 | **340 / 70** | `ExpectPixel(` call sites / files containing them | `grep -rn 'ExpectPixel(' --include='*.cpp' modules/ \| wc -l`; `grep -rln 'ExpectPixel(' --include='*.cpp' modules/ \| wc -l` | VERIFIED |
| C32 | **27** | files calling `CompareGoldenImage` (14 easygl + 13 opengl2) | `grep -rln 'CompareGoldenImage' --include='*.cpp' modules/ \| wc -l` | VERIFIED |
| C33 | **169** | example `.cpp` under `modules/renderers/` including `PixelTestGame` (12 families) | `grep -rln 'PixelTestGame' --include='*.cpp' modules/renderers/ \| wc -l` | VERIFIED |
| C34 | **136 / 30 / 77 / 29** | fixture files under `tests/assets` / `.../xnb` / `.../gltf` / `.../media` | `find tests/assets -type f \| wc -l`; `find tests/assets/xnb -type f \| wc -l`; `find tests/assets/gltf -type f \| wc -l`; `find tests/assets/media -type f \| wc -l` | VERIFIED |
| C35 | **4 / 8** | fuzz test files / `*Fuzz*` TEST macros | `find modules tests tools -iname '*fuzz*' -type f \| wc -l`; `grep -rhoE '^[[:space:]]*(TEST\|TEST_F\|TEST_P)\([[:space:]]*[A-Za-z_]*[Ff]uzz[A-Za-z_]*' --include='*.cpp' modules/ \| wc -l` | VERIFIED |
| C36 | **56** | files in `scripts/` — 37 `.sh`, 15 `.py`, 3 `.mjs`, 1 `.txt` | `ls -1 scripts/ \| wc -l`; `ls -1 scripts/*.sh \| wc -l`; `ls -1 scripts/*.py \| wc -l`; `ls -1 scripts/*.mjs \| wc -l`; `ls -1 scripts/*.txt \| wc -l` | VERIFIED |
| C37 | **8 / 6 / 2** | CI workflows / auto-triggering / dispatch-only | `find .github -type f \| wc -l`; per-file `grep -nE '^on:' -A6 .github/workflows/*.yml` | VERIFIED |
| C38 | **7 / 30** | scripts invoked from `.github/workflows/` / from CMake as a real CTest `COMMAND` | `grep -rhoE 'scripts/[A-Za-z0-9_.-]+' .github/workflows/ \| sort -u \| wc -l`; `grep -rhoE 'scripts/[A-Za-z0-9_.-]+' --include='*.cmake' --include='CMakeLists.txt' cmake/ modules/ \| sort -u` minus the comment-only hits (`compare-fna-reference.py`, `run-htmldom-*`, `run-oracle-corpus-diff-opengles1.sh`) | VERIFIED |
| C39 | **1** | scripts in `scripts/` with no reference anywhere outside `scripts/` and the `modularization/` rename maps: `run-all-renderer-smoke-tests.sh` | `for s in scripts/*; do b=$(basename $s); n=$(grep -rl --exclude-dir=.git --exclude-dir=modularization --exclude-dir=scripts -F "$b" . \| wc -l); [ "$n" = 0 ] && echo "$b"; done` | VERIFIED |
| C40 | **0** | code-coverage tool references in the entire build system and scripts | `grep -rniE '\-\-coverage\|gcov\|lcov\|llvm-cov\|gcovr\|COVERAGE_FLAGS\|-fprofile' --include='*.cmake' --include='CMakeLists.txt' --include='*.sh' --include='*.py' --include='*.yml' --include='*.json' . \| grep -v '/vendor/\|/third_party/\|cmake-build-debug'` | VERIFIED |
| C41 | **0** | PSNR/SSIM/perceptual-metric references | `grep -rni "PSNR\|SSIM" --exclude-dir=.git --exclude-dir=vendor --exclude-dir=third_party .` (only `metallicRoughnessImage`/`NumDescriptors` false positives) | VERIFIED |
| C42 | **0** | references to `xna4-decomp` or `xna4-spec` anywhere in CNA | `grep -rn 'xna4-decomp\|xna4-spec' --exclude-dir=.git . \| wc -l` | VERIFIED |

**C21 — per-renderer registration statements** (`cna_register_renderer_test(` + raw `add_test(` in that renderer's `examples/CMakeLists.txt`; skia's figure additionally includes its 164 wrapper calls):

easygl 293 · vulkan 211 · bgfx 179 · skia 175 · llgl 97 · sdl-gpu 83 · webgpu 80 · sdl-renderer 80 · software 60 · directx9 51 · headless 48 · opengl2 48 · directx11 41 · opengl1 38 · sokol 37 · opengl4 25 · freedirect 21 · gdi 19 · directx6 20 · directx7 20 · directx8 20 · directx2 19 · directx3 19 · directx5 19 · directx1 10 · directx10 10 · magnum 8 · openvg 7 · opengles1 7 · wicked 5 (in `cmake/Tests/WickedTests.cmake`) · blend2d 4 · direct2d 4 · diligent 3 · metal 3 · glide 3 · directx12 2 · stub 1 · html-dom 1 · svg-dom 1 · canvas 0. Plus `modules/graphics-ext/examples/CMakeLists.txt` 5 and `cmake/UnitTests.cmake` 2 (`Direct2D_Unit`, `CnaInputTests`).

**C24 — test executables per renderer** (`cna_<renderer>_test(` macro invocations):

easygl 295 · vulkan 208 · bgfx 172 · skia 167 · sdl-gpu 84 · sdl-renderer 80 · webgpu 79 · llgl 70 · software 61 · directx9 51 · headless 48 · opengl2 48 · directx11 41 · opengl1 38 · sokol 37 · diligent 32 · opengl4 25 · freedirect 21 (macro literally named `cna_directx3_test`) · directx12 21 · directx6 19 · directx7 19 · directx8 19 · directx2 18 · directx3 18 (macro named `cna_dx30_test`) · directx5 18 · portablegl 12 · fna3d 12 · directx1 9 · directx10 9 · magnum 8 · opengles1 8 · openvg 7 · direct2d 5 · blend2d 4 · stub 1. canvas/gdi/glide/metal/html-dom/svg-dom use direct `add_executable`.

Note the mismatch between C24 and C21 for some renderers: diligent builds 32 test executables and registers 3; skia builds 167 and registers 175 (some registrations are Python audits, not executables); llgl builds 70 and registers 97. **Building a test executable and registering it with CTest are independent acts in this project.**

### NOT statically derivable — require a configure and/or a build

1. **The number of CTest tests in any given build.** `gtest_discover_tests(… DISCOVERY_MODE PRE_TEST)` (`cmake/UnitTests.cmake:386`) enumerates CnaTests by *running the binary* at `ctest` time. Nothing in the source tree contains that list.
2. **The number of GoogleTest cases that actually run.** 7 `TEST_P` templates × 6 `INSTANTIATE_TEST_SUITE_P` sites expand to a runtime-determined count; 69 test files contain `#if` preprocessor conditionals whose branches depend on platform/feature macros.
3. **The total CTest count across all renderers.** F6 makes this structurally impossible: one build = one renderer. C21's per-renderer numbers are upper bounds within each renderer, and cannot be summed into a meaningful total.
4. **The active registration count for any one renderer**, because nested `if()` blocks (e.g. `if(TARGET cna_demo_2d)`, `if(CNA_SKIA_MODE STREQUAL "GANESH")`, EasyGL's `CNA_BUILD_EXAMPLES` requirement at `modules/renderers/easygl/examples/CMakeLists.txt:24-25`) suppress a subset.
5. **Pass/fail counts, timings, skip counts.** Nothing in the tree records a current run.
6. **Whether a pixel/golden assertion executed at all** — F34: without a display, everything skips with exit 77 and CTest reports green.
7. **Line/branch/function code coverage** — no tooling exists (C40). Any coverage percentage in this project's docs is an *API-surface* estimate, never a measured code-coverage figure.
8. **The number of test executables actually built**, since `EXCLUDE_FROM_ALL` targets (`cna_strict_xna_api_leak_check`), unregistered diagnostic binaries (`cna_diag_easygl`, `cna_diag_software`, `cna_diag_compare`, `cna_xvfb_screenshot_demo_easygl`), and CI jobs that build only named targets all diverge from `all`.
9. **Oracle divergence counts** (e.g. "10/39 exact on EasyGL") — these require running the corpus; the tree contains only reference PNGs and the comparator.

---

## SCRIPT CATALOG (`scripts/`, 56 files)

**Wiring legend:** `[CI]` = invoked from `.github/workflows/`; `[CTEST]` = a real CTest `COMMAND`; `[SCRIPT]` = called by another script; `[MANUAL]` = referenced only in docs/comments.

### Wine / Proton (14)

| File | Purpose | Wiring |
|---|---|---|
| `run-wine-dxvk.sh` | Runs a MinGW `.exe` under `~/.wine-cna-d3d11`; gates on a `DXVK: <ver>` log line | `[CTEST]` `cmake/UnitTests.cmake:326`, `Harnesses.cmake:208`, directx11 examples:43 |
| `run-wine-dxvk9.sh` | Same for D3D9; `CNA_D3D9_WINEPREFIX` defaults to the **same** `~/.wine-cna-d3d11` | `[CTEST]` `UnitTests.cmake:323`, directx9 examples:36, `run-oracle-corpus-diff.sh:51` |
| `run-wine-vkd3d.sh` | D3D12 under `~/.wine-cna-d3d12`; `VKD3D_DEBUG=info`; gates on `vkd3d-proton - applicationVersion:` | `[CTEST]` `UnitTests.cmake:329`, directx12 examples:40,120 |
| `run-wine-directx1.sh` | DirectDraw v1 under `~/.wine-cna-dx1`, `WINEDEBUG=+ddraw`, gates on `:ddraw:`. Deliberately no DXVK | `[CTEST]` `UnitTests.cmake:338` |
| `run-wine-directx2.sh` | Clone of dx1 with `CNA_DX2_*` env prefix; reuses `~/.wine-cna-dx1` | `[CTEST]` `UnitTests.cmake:341` |
| `run-wine-directx3.sh` | Clone of dx1 with `CNA_DX3_*` env prefix; reuses `~/.wine-cna-dx1` | `[CTEST]` `UnitTests.cmake:346` |
| `run-wine-directx5.sh` | Clone of dx1 with `CNA_DX5_*` env prefix; reuses `~/.wine-cna-dx1` | `[CTEST]` `UnitTests.cmake:350` |
| `run-wine-directx6.sh` | Clone of dx1 with `CNA_DX6_*` env prefix; reuses `~/.wine-cna-dx1` | `[CTEST]` `UnitTests.cmake:354` |
| `run-wine-directx7.sh` | Clone of dx1 with `CNA_DX7_*` env prefix; reuses `~/.wine-cna-dx1` | `[CTEST]` `UnitTests.cmake:358` |
| `run-wine-directx8.sh` | D3D8-via-D8VK under dedicated `~/.wine-cna-dx8`; forces `DXVK_FILTER_DEVICE_NAME=llvmpipe` | `[CTEST]` `UnitTests.cmake:364` |
| `run-wine-directx10.sh` | D3D10 under `~/.wine-cna-d3d10`; **forces `DISPLAY=:0`** (DXVK dxgi EDID bug under Xvfb) | `[CTEST]` `UnitTests.cmake:370` |
| `run-wine-direct2d.sh` | 3-line shim: re-enters the Xvfb runner, sets `CNA_D3D11_WINEPREFIX` to **`$HOME/.wine`** by default, execs `run-wine-dxvk.sh` | `[CTEST]` `UnitTests.cmake:376`, direct2d examples:37,61,91,117 |
| `run-proton-direct2d.sh` | Resolves a **pinned** Proton from `direct2d-proton-pin.txt`, publishes runtime identity, refuses Experimental, `exec python3 <proton> run` | `[CTEST]` direct2d examples:41,65,95,121 |
| `run-proton-vkd3d.sh` | D3D12 through `proton run` with vkd3d-proton `d3d12`/`d3d12core` overlaid onto a Proton prefix; hard-refuses `~/.wine` | `[MANUAL]` (comments only) |
| `run-direct2d-virtual-display.sh` | Canonical reentrant Xvfb runner: private Xauthority, geometry validation, cleanup trap | `[SCRIPT]` from `run-wine-direct2d.sh:24`, `run-proton-direct2d.sh:36`, `run-direct2d-fresh-wine-suite.sh:79` |
| `run-direct2d-fresh-wine-suite.sh` | Builds a throwaway Wine prefix from `wineboot --init` only, runs `ctest -L Direct2D` against it | `[MANUAL]` |
| `direct2d-proton-pin.txt` | Data file: allowed Proton dir names in priority order (`Proton 9.0 (Beta)`, `Proton 8.0`) | `[SCRIPT]` `run-proton-direct2d.sh:39` |

### DirectX-era discipline gates (8) — all `[CTEST]`

Shared skeleton: `find` the renderer's `src/` + `include/.../<Renderer>`, strip comments, `grep -nE "$pattern"`; exit 0 clean / 1 on violation *or* missing directory. Two comment-stripping generations: `sed -E 's|//.*||'` (dx1/2/3/5/6) vs a line-count-preserving `perl -0777` that also removes block comments (dx7/8/10).

| File | Invariant enforced | Registration |
|---|---|---|
| `check-directx1-v1-only.sh` | v1 DirectDraw only; no `IDirectDraw[247]`, no `IDirect3D` of any version, no `d3d.h` include (`:18`) | directx1 examples:52 |
| `check-directx2-execute-buffer-discipline.sh` | No execute-buffer path (`IDirect3DExecuteBuffer`, `D3DOP_*`, `D3DINSTRUCTION`); `\b`-anchored bare names spare `IDirect3D2`/`IDirect3DDevice2`; 2D stays v1 (`:37`) | directx2 examples:53 |
| `check-directx3-execute-buffer-discipline.sh` | Same, minus one token: `IDirectDraw2` becomes legal (`:27`) | directx3 examples:55 |
| `check-directx5-execute-buffer-discipline.sh` | v4-only DirectDraw; **bare `IDirectDrawSurface` now forbidden**; `D3DVT_*` forbidden in favour of `D3DFVF_TLVERTEX` (`:37`) | directx5 examples:52 |
| `check-directx6-execute-buffer-discipline.sh` | Identical pattern string to dx5 — dx6 introduces no new COM interface (`:34`) | directx6 examples:52 |
| `check-directx7-execute-buffer-discipline.sh` | v7-only; **no viewport object at all**; no texture-handle indirection; `D3DRENDERSTATE_TEXTUREMAPBLEND` banned from an empirical Wine rejection (`:41`) | directx7 examples:52 |
| `check-directx8-legacy-interface-discipline.sh` | Zero DirectDraw of any kind; modern `D3DRS_*` naming only (`:24`) | directx8 examples:53 |
| `check-directx10-legacy-interface-discipline.sh` | No FVF model, **no `D3DRS_*` either** (state objects instead), and `SetVertexShader(` banned as a literal call shape (`:23`) | directx10 examples:44 |

### Link / identity / plan gates (3)

| File | Invariant enforced | Wiring |
|---|---|---|
| `check_module_link_closure.py` | Reads `<build>/CMakeFiles/<t>.dir/link.txt`, fails on any `--forbid` token or missing `--require` token. Exit 0/1, **77 (SKIP) when `link.txt` is absent**, i.e. non-Makefiles generator (`:33-35`) | `[CTEST]` ×6 registration sites in `cmake/Tests/ModuleProbes.cmake` (:19, :91, :107, :125, :133, :143) |
| `check_renderer_identities.py` | Order-sensitive comparison of the canonical 46-entry table vs the `GraphicsRendererType` enum; set-wise vs the cmake `STRINGS` list | `[CTEST]` `ModuleProbes.cmake:153` |
| `validate_direct2d_plan.py` | 8 plan/evidence invariants (status vocabulary, evidence required on ✅, every cited path must exist, every cited CTest name must appear in one of 13 registration sources, classification-section completeness, status-marker arithmetic) + a `--release-gate` mode | `[CI]` `d3d-windows-ci.yml:111` |

### Skia meta-validators (6) — all `[CTEST]` under a SKIA configure

| File | Invariant enforced | Registration |
|---|---|---|
| `validate_skia_parity_ledger.py` | Hand-written C++ brace-walker extracts `Class::method/arity` from 11 backend interfaces + `GraphicsCapability` + `GraphicsDevice`; ledger must have one row per entry, status ∈ {implemented,bounded,unsupported,internal} | skia examples:63 (`Skia_ParityLedger_Audit`) |
| `validate_skia_test_matrix.py` | Every CTest/tool/golden/oracle entry must be classified by kind and category; 38 keyword→feature rules map every `3d` entry to feature IDs | skia examples:70 (`Skia_TestMatrix_Audit`) |
| `validate_skia_3d_decision.py` | ADR must say `Status: Accepted` + `Decision: 2D-only`; exactly **37** 3D requirements, each decided once | skia examples:77 (`Skia_3DDecision_Audit`) |
| `validate_skia_release_gate.py` | Row contiguity, capability table must show only `Texture3D` true, `SupportsCapability` must have no `default:` arm, accelerated registrations must be preceded by a Ganesh guard | skia examples:84 (`Skia_ReleaseGate_Audit`) |
| `validate_skia_successor_contracts.py` | 24 fixed ids ∪ per-enum-member ids; route union must equal exactly `range(118,171)` | skia examples:91 (`Skia_SuccessorContracts_Audit`) |
| `validate_skia_surface_formats.py` | 27-row format table must match the live enum in order **and** the values returned by `GetBlockSizeSquaredEXT`/`GetFormatSizeEXT` | skia examples:98 (`Skia_SurfaceFormats_Audit`) |

### Direct2D / shader verification (6)

| File | Invariant enforced | Wiring |
|---|---|---|
| `verify-direct2d-debug-log.py` | Fails on: diagnostics never engaged, debug layer off, truncated live-object report, any `severity=ERROR\|CORRUPTION`, or a live object outside `{ID3D11Device, DeviceContext, Debug, InfoQueue}`. `--self-test` runs the 6 checked-in `tests/fixtures/direct2d/` fixtures | `[CI]` `d3d-windows-ci.yml:126` (self-test), `:253` (real logs) |
| `verify-direct2d-parallel-jobs.sh` | 10 named files must cap `--parallel`/`-j` at ≤ 2; a listed file that no longer exists is itself a violation | `[CI]` `d3d-windows-ci.yml:104` |
| `direct2d_mutation_check.py` | 7 mutations, each anchor must occur exactly once; `--run`: a still-passing test = a surviving mutation = failure | `[CI]` `d3d-windows-ci.yml:119` (`--dry-run` only) |
| `verify_hlsl_shaders_native_msvc.py` | Rebuilds the compiler tool with real `cl.exe` and recompiles all 20 shaders against real `D3DCOMPILER_47.dll`; **no byte-diff by design** | `[CI]` `d3d-windows-ci.yml:273` |
| `verify_d3d_shaders_reproducible.sh` | Regenerates D3DCommon + D3D9 shader bytecode under Wine and byte-compares against the committed headers | `[MANUAL]` |
| `verify-d3d9-stock-effects-vendored.sh` | `diff -u`s 10 vendored XNA Stock Effects HLSL files against an external FNA tree | `[MANUAL]` |

### Oracle / pixel diff (10)

| File | Purpose | Wiring |
|---|---|---|
| `xna-diff.py` | The PNG comparator: per-channel absolute tolerance (default 0), optional split RGB/alpha, raw-diff pixel budget, allowed-diff rectangle | `[SCRIPT]` from all 5 corpus runners |
| `run-oracle-corpus-diff.sh` | D3D9 vs 39 real-XNA references at tolerance 0; **hard gate** | `[CTEST]` `D3D9_XNA_Diff`, directx9 examples:232 |
| `run-oracle-corpus-diff-easygl.sh` | Same corpus through native EasyGL; tolerance 0; deliberately unregistered measurement | `[MANUAL]` |
| `run-oracle-corpus-diff-opengles1.sh` | OPENGLES1 measurement; exits 1 only on *render* failure | `[MANUAL]` (named in a comment at opengles1 examples:78) |
| `run-oracle-corpus-diff-fna3d.sh` | FNA3D; pins `FNA3D_FORCE_DRIVER=OpenGL`; exits 1 only on render failure | `[CTEST]` `Fna3d_XNA_Oracle`, fna3d examples:81 |
| `run-skia-2d-oracle-diff.sh` | 9 SpriteBatch scenes under `tools/xna-oracle/skia-2d-policy.tsv`; also audits policy↔scene set equality both ways (exit 2) | `[CTEST]` `Skia_XNA_2D_Oracle`, skia examples:174 |
| `compare-fna-reference.py` | One-directional JSON diff FNA→CNA reference values, numeric tolerance 1e-4 | `[MANUAL]` (documented at `cmake/Harnesses.cmake:157`) |
| `avatar_visual_regression_check.py` | Speckle/brightness regression floors on 3 pinned avatar poses under Xvfb | `[MANUAL]` |
| `run-all-renderer-smoke-tests.sh` | Configure/build/`ctest -L GraphicsSmoke` across 4 renderers | **unreferenced anywhere** (C39) |
| `opengles1-test-env.sh` | Env shim pointing `LD_LIBRARY_PATH`/EGL/GLX at a locally built ES1-capable Mesa, then `exec "$@"` | `[MANUAL]` |

### Browser (6)

| File | Purpose | Wiring |
|---|---|---|
| `run-htmldom-test-suite.sh` | Builds `cna_test_htmldom_all -j3`, runs all 6 pages on ports 8731–8736 | `[CI]` `htmldom-ci.yml:127` |
| `run-htmldom-browser-test.sh` | Serves one built page via `python3 -m http.server`, drives it with a node harness | `[CI]`/`[SCRIPT]` from the suite runner |
| `htmldom-browser-test.mjs` | Playwright/Chromium driver; `window.__cnaSmokeDone` verdict + 2 real compositor pixel checks | `[SCRIPT]` |
| `htmldom-host-integration-test.mjs` | Playwright driver using `page.route()` HTML rewriting to test pre-module DOM state | `[SCRIPT]` |
| `run-svgdom-browser-test.sh` | SVG_DOM twin (port 8741, serves from the svg-dom examples dir) | `[MANUAL]` |
| `svgdom-browser-test.mjs` | Playwright driver for 3 SVG_DOM pages + SVG-namespace structural proofs + a 4-point scissor pixel check | `[SCRIPT]` |

---

## CONTRADICTIONS

**X1 — `general-tests-ci.yml` and 2 of 5 `input-ci.yml` legs cannot configure at this SHA. *(Corroborated independently by two audit passes — this one and the architecture pass. This is a live CNA defect, not a book-side issue.)*** Both pass `-DCNA_GRAPHICS_RENDERER=EASYGL` (`general-tests-ci.yml:133`; `input-ci.yml:38,43`). `EASYGL` is **not** one of the 46 public identities — `plan_glbackends.md` demoted it to an internal family, publicly selected as OPENGLES2/OPENGLES3/OPENGL33/WEBGL1/WEBGL2 (`cmake/RendererSelection.cmake:1-15`), and the selection chain ends in `message(FATAL_ERROR "CNA: Unknown graphics renderer: ${CNA_GRAPHICS_RENDERER}")`. The workflow's own header calls EasyGL "the documented default renderer on Linux (cmake/RendererSelection.cmake)" (`:12-13`), but that file's Linux default is `OPENGLES3` (`:11`). Commit `ea31cabc1` (2026-08-11) edited `general-tests-ci.yml` for the ASCII-identity removal and left `EASYGL` untouched. **Severity: the single job that runs the full unfiltered suite is dead, and the only ASan+UBSan leg in CI is dead with it.** VERIFIED.

**X2 — `check_renderer_identities.py` says 42 in prose while its table holds 46; the settled numbers are 46 identities / 42 families.** Docstring `:6` "exactly 42 public renderer identities"; comment `:19` "42 entries"; the list at `:20-67` has 46 entries. `cmake/Tests/ModuleProbes.cmake:6` repeats "42"; `modules/renderers/CMakeLists.txt:5` says "46" (correct). Independently confirmed: the `set_property(CACHE CNA_GRAPHICS_RENDERER PROPERTY STRINGS …)` block has exactly 46 entries and the `GraphicsRendererType` enum has 46 enumerators. Meanwhile `modules/renderers/` holds exactly **42 family directories** (C26) — so the number 42 is *real*, it just names families, not identities. The gate itself uses `len(IDENTITIES)` and is therefore self-consistent; only the prose a reader would quote has drifted. **The correct statement is: 46 public renderer identities, 42 implementation families.** VERIFIED.

**X3 — Post-modularization path rot in four wired-in gates.** `validate_skia_release_gate.py:26` reads `cmake/Tests/SkiaTests.cmake`; `validate_skia_test_matrix.py:108` reads `cmake/Tests/EasyGLTests.cmake`; `validate_skia_surface_formats.py:97` reads `src/Graphics/Xna/Texture.cpp`; `verify_hlsl_shaders_native_msvc.py:30` reads `src/CNA/Internal/Renderers/D3DCommon/shaders`. **All four paths are gone** (verified by `test -e`). The first three are registered CTests (`modules/renderers/skia/examples/CMakeLists.txt:87,73,101`) — under a SKIA configure they would abort before doing any work. The fourth is a live CI step. The `cmake/Tests/` directory now contains only `ModuleProbes.cmake` and `WickedTests.cmake`. VERIFIED.

**X4 — All eight `check-directx*` script headers cite a registration path that no longer exists.** Each names `cmake/Tests/DirectX<N>Tests.cmake` (e.g. `check-directx1-v1-only.sh:5`, `check-directx10-legacy-interface-discipline.sh:10`); the real registration is `modules/renderers/directx<N>/examples/CMakeLists.txt`. VERIFIED.

**X5 — `devices-tests.yml`'s filter comment is false.** `:53-56` claims `DEVICES_GTEST_FILTER` covers "every `TEST(...)` under `modules/devices/tests/Microsoft/Devices/`, no more and no fewer." It selects **446 of 462** (C14). The 16 missed cases live in 4 suites: `DevicesShutdownCoordinatorTest` (4), `DevicesShutdownOrderingTest` (1), `IndependentReferenceCrossCheckTests` (2), `NativeDiagnosticSinkTest` (9). This is *exactly* the copy-pasted-filter drift that `INPUT-BUILD-003` created `CNA_INPUT_TEST_FILTER` + `ctest -L input` to eliminate (`cmake/UnitTests.cmake:396-401`) — and the devices workflow still uses hand-maintained `--gtest_filter` strings. VERIFIED.

**X6 — `input-ci.yml` says "shuffled x3", CMake says 5.** `input-ci.yml:118` "runs it shuffled x3 for order-independence"; `cmake/UnitTests.cmake:412` and `docs/input-build-and-test.md:60,66` both say `--gtest_repeat=5`. VERIFIED.

**X7 — The `tests` preset says running via `ctest` is *not* authoritative; `general-tests-ci.yml` does exactly that.** `CMakePresets.json` `tests` description: "running the CnaTests binary directly (not `ctest`) is the authoritative way to run the suite: `ctest` discovers and runs each gtest case as its own short-lived process, which both spuriously reports every unbuilt display-dependent graphics smoke-test executable as failed and races several tests that share hardcoded `/tmp` fixture paths across processes." `general-tests-ci.yml:153` runs `ctest --output-on-failure` unfiltered and absorbs the resulting failures via a 4-name allowlist. `devices-tests.yml:135,142` follows the preset advice and runs the binary directly. **The project holds two mutually exclusive positions on how its own suite should be run.** VERIFIED.

**X8 — Three different stale registration counts in three comments.** `cmake/TestHelpers.cmake:4` "~600 per-renderer CTest registrations"; `cmake/UnitTests.cmake:444` "~330 existing test registrations"; `general-tests-ci.yml:140` "~247 separately-registered renderer smoke-test executables". The derived static figure is 1785 registration statements (C18), and none of the three numbers corresponds to any single configure. VERIFIED.

**X9 — `docs/coverage.md` is stale on its headline claim.** It states "the XNA binary `.xnb` format is entirely absent" (`:28-29`), "Framework.Content … **no .xnb binary support**" (`:56`), and lists "**Content pipeline (.xnb) — 0 %**" as the top blocking gap (`:148`). The repo has a full XNB reader (`modules/content/include/CNA/Internal/Xnb/` — `XnbHeader.hpp`, `LzxDecoder.hpp`, `XnbTypeReaderTable.hpp`, `XnbBuiltInReaders.hpp`, per-type readers), 30 XNB fixtures under `tests/assets/xnb/`, and an FNA-differential LZX test. The doc self-labels as a dated snapshot but its title and filename do not. VERIFIED.

**X10 — "coverage" means five different things across `docs/`.** `coverage.md` = XNA API-surface estimate (never measured); `input-test-coverage.md` = source-file→test-suite mapping; `devices-api-coverage.md` / `xna-4-api-coverage.md` = API presence; `gdm-coverage.md` = GraphicsDeviceManager feature list. **None is code coverage, and no code-coverage tooling exists** (C40). Any reader who sees "~85% coverage" will assume line coverage. VERIFIED.

**X11 — `docs/d3d9-divergence-report.md` reports a 31-scene corpus; the corpus has been 39 since 2026-07-16.** `:3-4` "Corpus: 31 scenes … 0 measured pixel divergences at `--tolerance 0`"; `:29` "10/31" for EasyGL. Git shows 31 scenes added 2026-07-15 and 8 more 2026-07-16. The newer reports quote 39 (`docs/fna3d-parity-report.md:13-15`, `docs/opengles1-parity-report.md:10-11`); D3D9's was never restated. The *gate* (`D3D9_XNA_Diff`) does run all 39 at tolerance 0, so the gate is current even though its report is not. STRONG.

**X12 — `run-all-renderer-smoke-tests.sh` claims to be the cross-renderer smoke orchestrator but is invoked by nothing** (C39), covers only 4 of 46 identities, ignores build failures (`:47-51`), reports configure failures as SKIPPED rather than FAIL (`:41-43`), and excludes both golden-image renderers. It also uses `-j4`, above the workspace-wide 3-job ceiling. VERIFIED.

**X13 — `validate_direct2d_plan.py --release-gate` is permanently blocked by design.** It requires `docs/direct2d-native-evidence.md` and `docs/direct2d-physical-presentation-evidence.md` (`:68-74`); neither file exists. The comment at `:69` says that is deliberate ("their absence is what keeps the gate honest") — but CI only runs the script *without* `--release-gate` (`d3d-windows-ci.yml:111`), so the gate has never actually gated anything. VERIFIED.

**X14 — `run-wine-direct2d.sh` defaults `WINEPREFIX` to the developer's `$HOME/.wine`** (`:30`), in a repo where both Proton scripts hard-refuse that path after a documented 9.5-hour incident (`run-proton-vkd3d.sh:70-89`). VERIFIED.

**X15 — Label discipline is inconsistent enough to invalidate the obvious selection commands.** `ctest -L EasyGL`, `-L Vulkan`, `-L Bgfx`, `-L SdlRenderer` select ~1 test each despite those renderers registering 293/211/179/80 tests (F16). Only `DIRECTX*`, `Skia`, `Software`, `Headless`, `Llgl`, `SdlGpu`, `WebGPU`, `OpenGL2/4`, `Sokol`, `GDI`, `Direct2D` have per-test labels. VERIFIED.

---

## BOOK IMPACT

A Testing & Verification Part should be **one of the deepest in the book** — CNA's verification apparatus is genuinely unusual, and it is the part of the project most likely to be misdescribed by a casual reader.

### Suggested structure (6 chapters, ~70–90 pages)

**Ch. A — "One binary, 6670 assertions: the CnaTests architecture" (~14 pp).**
The single-executable design; the glob-and-filter contract at `cmake/UnitTests.cmake:26-156` with each of the nine exclusions as a small case study (each one is a real, dated bug); `gtest_discover_tests(PRE_TEST)` and its `WORKING_DIRECTORY` fix; the exit-77 skip convention and why it is applied in two places (root scope vs `cna_apply_skip_convention()`); and the nine process-isolation harnesses with their "why a separate process" rationales (`g_mixer`, `SDL_Quit()`, GamerServicesDispatcher). Include `cna_strict_xna_api_leak_check` as the book's showcase of a `WILL_FAIL` compile-must-fail test.

**Ch. B — "Counting discipline: what a test number can and cannot mean" (~10 pp).**
This chapter is the reason to be careful, and it is a genuinely original contribution. Lay out the four incommensurable quantities (test source files / GoogleTest macros / CTest registrations / test executables), show that they are 433 / 6670 / 1785 statements / ~1200 executables and that **none is a substitute for another**, then explain the two structural reasons no single total exists: one renderer per configure (F6) and `PRE_TEST` discovery (F3). Reproduce the derivation commands verbatim so readers can re-derive them. Close with X8 — three stale counts in three comments, on three different definitions — as the cautionary tale, and with X2's clean resolution (46 identities, 42 families) as the counter-example of a number that *can* be settled.

**Ch. C — "Oracles: what does 'correct' even mean?" (~18 pp, the flagship chapter).**
The two-tier tolerance discipline is the book's best single idea and must not be flattened. Tier 1: the XNA oracle — 39 scenes captured once against the real XNA 4.0 runtime under Wine, a checked-in `Oracle.cs` runner, one renderer-agnostic CNA side, tolerance **0** by default, and `xna-diff.py:22-24`'s standing rule quoted in full ("that is exactly how an authenticity project quietly becomes a parity project"). Tier 2: the CNA-self golden layer, tolerances 0–60, honestly self-described at `PixelTestGame.hpp:166-169`. Then the third leg: the FNA value oracle at 1e-4, one-directional by design, and the real `IndexElementSize` divergence it caught. Then the in-corpus oracle taxonomy (F25): golden tables, independent recomputation ladders, shared header oracles. Then the Skia per-scene policy TSV as an example of *documented* tolerance relaxation done right — including the `NonPremultiplied` alpha bug it found. State plainly that `xna4-decomp`/`xna4-spec` are unused (F24) — readers will assume otherwise.

**Ch. D — "Verification in hostile environments: Wine, Proton, browsers" (~16 pp).**
The nine-step Wine wrapper skeleton, and the single most transferable idea in the whole project: **the log-line gate**. Explain why `DXVK: <ver>` / `vkd3d-proton - applicationVersion:` / `:ddraw:` greps exist — a broken DXVK degrades silently to WineD3D and the test still passes — and why gate failure returns exit 3 and *discards* the program's own exit code. Then the `CNA_*_SKIP_*_GATE` counter-mechanism and why `--gtest_list_tests` needs it. The prefix map (including the shared `~/.wine-cna-dx1` across six DirectX eras) and Proton's opposite posture: pinned runtime, refusal of Experimental, runtime identity mined out of the shipped DLL. Then the browser half: why the wasm exit code is unobservable, the `window.__cnaSmokeDone` verdict channel, and the screenshot→canvas→`getImageData` readback that goes through the browser's *real compositor* — a technique no in-page API can reach. End with `htmldom-host-integration-test.mjs`'s `page.route()` HTML rewriting and *why* `addInitScript` was measurably not early enough.

**Ch. E — "Discipline as a test: the check_/validate_/verify_ family" (~14 pp).**
This is CNA's most distinctive practice and deserves its own chapter. The DirectX-era grep gates read as an architecture-history document: dx2→dx3 differs by exactly one legal token; dx5 forbids the *bare* `IDirectDrawSurface` to prove every surface was upgraded; dx7 bans `D3DRENDERSTATE_TEXTUREMAPBLEND` because Wine empirically rejected it; the comment-stripping engine was upgraded from `sed` to a line-preserving `perl -0777` the moment Doxygen prose started colliding with the forbidden list. Then the link-closure probes as executable architecture (`libcna_(?!math)|…`), the identity registry, the six Skia meta-validators that check *documents* against *code*, and mutation testing as the answer to "a green suite says nothing until you know it can go red." Be honest about X3: four of these gates currently read paths that no longer exist — the practice is real, its maintenance is not free.

**Ch. F — "What CI actually runs" (~10 pp).**
The precise table from F58. Emphasize the gap between apparatus and automation: 56 scripts exist, 30 are CTest commands, **7 are referenced by CI, and 5 of those 7 sit in dispatch-only workflows** — so a routine push exercises exactly two scripts. Then the sanitizer story (one `CNA_SANITIZE` knob, three Devices-only presets, exactly two sanitizer legs in CI, zero TSan runs), validation layers per renderer including the Vulkan tests that *assert the layer is loaded*, fuzzing as four in-corpus files with no libFuzzer, and one hand-rolled property-test file. Close with the coverage section: **no code-coverage tooling exists**, `docs/coverage.md` is an API-surface estimate dated 2026-06-21 whose headline `.xnb` claim is now false, and "coverage" means five different things across `docs/`.

### Cross-cutting themes worth naming explicitly

1. **The gate is the artifact.** Almost every CNA verification mechanism is designed around one insight: a green result that was never actually produced is worse than a red one. The Wine log gates, the `--dry-run` anchor check, the mutation-survival inversion, the `WILL_FAIL` compile check, the debug-layer "diagnostics never engaged" detector, and the `--self-test` fixtures are six independent expressions of the same idea.
2. **Skip is not pass — but it looks like it.** F34 is the most important caveat in the whole Part: without a display, the entire pixel and golden layer becomes SKIPPED and CTest goes green.
3. **Comments rot faster than code.** X2/X3/X4/X5/X6/X8/X11 are all prose that drifted while the mechanism stayed correct. This is worth stating as a finding about long-lived, incrementally-written projects, not as a list of defects.

### What NOT to do in the book

Do not quote any test count from a `docs/*.md` or `plan_*.md` file — those are dated run snapshots (4383, 5400, 5415, 524, 283…) taken at different SHAs on different renderers. Derive numbers from the tree with the commands in the COUNTS table, and **always state the definition alongside the number.**
