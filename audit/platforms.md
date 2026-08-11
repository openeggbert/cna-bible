# Audit report — platform support and cross-platform engineering

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root.

Confidence labels: **VERIFIED** = the exact line was read · **STRONG** = several independent
reads agree · **PROBABLE** · **UNCERTAIN**.

---

## The one-paragraph truth

CNA targets seven platforms. **Exactly one — Linux x86_64 — is a first-class, self-hosting
target.** Everything else is reached by cross-compiling *from* Linux and then executing under a
translation layer (Wine/DXVK for Windows, headless Chromium for Web, an AVD for Android) or not
executing at all (macOS, iOS). **No CNA binary has ever been shown to run on genuine Windows,
genuine macOS, genuine iOS, or genuine Android hardware at this SHA.** The project's own lane
cards and plan rows say this plainly and repeatedly; `README.md` does not.

The second structural finding is that CNA has **no platform abstraction layer at all, by explicit
policy** — platform variation is expressed as CMake target selection, not preprocessor branching.
That is stated in the project's own planning documents and confirmed by measurement (§3, FACTS
41 and 47).

---

## 1. PLATFORM MATRIX

States: **(a)** source path exists · **(b)** configures · **(c)** cross-compiles · **(d)** builds
(links a real artifact) · **(e)** runs · **(f)** runs under emulation/translation · **(g)** runs on
real hardware · **(h)** covered by CI · **(i)** manually verified with recorded evidence ·
**(j)** pixel-verified.

`✔` evidenced · `◐` partial/qualified · `✖` no evidence · `CI-only` = code path exists, its only
claimed exercise is a workflow never shown to have run · `—` not applicable.

| Platform | a | b | c | d | e | f | g | h | i | j |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **Linux x86_64** (host) | ✔ | ✔ | — | ✔ | ✔ | — | ✔ | ◐ **broken** | ✔ | ✔ |
| **Linux i686 / ARM** | ◐ | ✖ | ✖ | ◐ | ◐ | — | ◐ | ◐ | ◐ | ✖ |
| **Windows x86_64 — MinGW cross** | ✔ | ✔ | ✔ | ✔ | — | ✔ | ✖ | ✖ | ✔ | ✔ |
| **Windows x86_64 — MSVC native** | ✔ | CI-only | — | CI-only | CI-only | — | ✖ | CI-only | ✖ | ✖ |
| **Windows i686 (GLIDE)** | ✔ | ✔ | ◐ | ✖ | ✖ | ◐ | ✖ | ✖ | ◐ | ✖ |
| **Wine / DXVK / vkd3d** | ✔ | ✔ | ✔ | ✔ | — | ✔ | ✔ (real GPU) | ✖ | ✔ | ✔ |
| **Proton** | ✔ | ✔ | ✔ | ✔ | — | ◐ | ✖ | ✖ | ◐ | ✖ |
| **Web / Emscripten** | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ (headless Chromium) | ✖ | ◐ (1 of 5 renderers) | ✔ | ◐ (2 of 5) |
| **Android (NDK)** | ✔ | ✔ | ◐ | ◐ | ✔ | ✔ (AVD) | ✖ | ✖ | ◐ narrative only | ✖ |
| **macOS (Darwin)** | ✔ | ✔ (rejection only, from Linux) | ✖ | ✖ *(adapted tree)* | ✖ | — | ✖ | CI defined, path filters stale | ◐ historical pre-adaptation only | ✖ |
| **iOS / tvOS** | ◐ enum only | ✖ hard reject | ✖ | ✖ | ✖ | ✖ | ✖ | ✖ | ✖ | ✖ |

### Per-row evidence

**Linux x86_64** — the only self-hosting target. Default renderer `OPENGLES3`
(`cmake/RendererSelection.cmake:10-11`). Real pixel goldens at `examples/golden/*.png`. **(h) is
qualified**: see FACT 21 — the two most important automatic Linux workflows fail at CMake
configure at this SHA.

**Linux i686 / ARM** — no CNA target. The only i686 artifact is a *standalone* three-binary
project, `tools/media/arithmetic32bit/`, built with `-m32` on `ubuntu-latest`
(`.github/workflows/32bit-arithmetic-ci.yml:71-84`), whose own header says the main build's
SDL3/FFmpeg dependencies "are not available for a 32-bit target" (`:16-19`). No ARM Linux
anywhere; the only `aarch64` string in CNA's own CMake is a wgpu-native package name
(`cmake/ThirdPartyWebGPU.cmake:33-34`).

**Windows MinGW cross** — genuinely proven. `.sdl-prebuilt-Windows-x86_64/SDL/build/CMakeCache.txt`
records `CMAKE_TOOLCHAIN_FILE=…/cmake/toolchains/mingw-w64.cmake`; `install/lib/` holds
`libSDL3.dll.a` (GNU import libs), no `.lib`, no `.pdb`. Directory created 2026-08-10.

**Windows MSVC native** — zero MSVC code in CNA (FACTS 12–13). Two `workflow_dispatch`-only
workflows. `plan_dx.md:1065` (DX-90, still open): *"the workflow itself has not yet been validated
against an actual GitHub Actions run — this environment has no `gh` authentication configured."*

**Wine** — where every positive Windows result actually lives. Twelve `run-wine-*.sh` launchers,
six distinct WINEPREFIXes, each with a **runtime-engagement gate** that greps the run log and
exits 3 if the intended translation layer did not engage. DX1–DX12 and GDI are pixel-verified *in
that environment, on a real GPU*.

**Proton** — the D3D12 lane reached a real `CreateSwapChainForHwnd` S_OK on 2026-07-14
(`scripts/run-proton-vkd3d.sh:25-29`), and `~/.wine-cna-d3d12-protonrun` still exists from that
date. The Direct2D Proton lane was **verified only against a fabricated Steam tree**
(`plan_direct2d.md:275`) and `~/.wine-cna-direct2d-protonrun` does not exist. No Steam/Proton is
installed on this machine now.

**Web / Emscripten** — five renderers at four different evidence levels; see FACTS 26–32.
`HTML_DOM` is the strongest cross-platform evidence in the whole project.

**Android** — three separate efforts (2026-07-04 emulator test run, 2026-07-05 APK, 2026-07-09
regression). All evidence is narrative prose; **no APK, screenshot, logcat, or log is committed**
anywhere in the repo.

**macOS** — the honest boundary is stated by the project itself at `integration/lanes/metal.md:26-27`:
*"This host is Debian and has neither Apple's framework headers nor a Metal device."*

**iOS** — `CNA::Platform::iOS` exists as an enum value and is switched on in three files, but
`cmake/RendererSelection.cmake:366-369` rejects METAL on anything but `Darwin`, with the message
*"iOS and tvOS remain unvalidated."* No `.xcodeproj`, no `Info.plist`, no `CMAKE_OSX_SYSROOT`
anywhere.

---

## 2. RENDERER-PER-PLATFORM TABLE

CNA has **46 public renderer identities** (`cmake/RendererSelection.cmake:16`,
`docs/renderer-registry.md:3`). The sets below are derived strictly from the `FATAL_ERROR` gates
in `cmake/RendererSelection.cmake`; `CMAKE_SYSTEM_NAME` is `Linux` / `Windows` / `Darwin` /
`Android` / `iOS` / `Emscripten` respectively.

### The gates (VERIFIED, exhaustive)

| Line | Condition | Renderers affected |
|---|---|---|
| `:347-353` | not `Windows` → FATAL | **14**: DIRECTX1/2/3/5/6/7/8/9/10/11/12, DIRECT2D, GLIDE, GDI |
| `:358-362` | GLIDE and `sizeof(void*) != 4` → FATAL | GLIDE ⇒ 32-bit Windows only |
| `:366-369` | METAL and not `Darwin` → FATAL | METAL |
| `:374-376` | OPENGL1 and not (`Linux`\|`Windows`) → FATAL | OPENGL1 |
| `:383-385` | OPENVG and not (`Linux`\|`Windows`\|`Darwin`) → FATAL | OPENVG |
| `:387`, `:395`, `:404` | not `EMSCRIPTEN` → FATAL | CANVAS, HTML_DOM, SVG_DOM |
| `:416-421` | MAGNUM and `EMSCRIPTEN` → FATAL | MAGNUM |
| `:433-438` | OPENGLES2\|OPENGLES3\|OPENGL33 and `EMSCRIPTEN` → FATAL | 3 GL profiles |
| `:439-445` | WEBGL1\|WEBGL2 and not `EMSCRIPTEN` → FATAL | WEBGL1, WEBGL2 |
| `:492-497` | WICKED and `EMSCRIPTEN` → FATAL | WICKED |
| `:446-449`, `:485-487`, `:498-500` | **WARNING only, not exclusion** | OPENGLES2/3 off-Linux; BGFX off-Linux; WICKED off-Linux/Windows |

### Admissible sets

| Platform | Default renderer | # admitted | Excluded, and why |
|---|---|---:|---|
| **Linux** | `OPENGLES3` | **26** | −14 Windows, −5 Emscripten-only, −METAL |
| **Windows x86_64** | `SDL_RENDERER` | **39** | −5 Emscripten-only, −METAL, −GLIDE (needs 32-bit) |
| **Windows i686** | `SDL_RENDERER` | **40** | −5 Emscripten-only, −METAL. *(GLIDE admitted here and only here — but see FACT 16: nothing actually links.)* |
| **macOS (Darwin)** | `SDL_RENDERER` | **26** | −14 Windows, −5 Emscripten-only, −OPENGL1 |
| **Android** | `SDL_RENDERER` | **24** | −14 Windows, −5 Emscripten-only, −METAL, −OPENGL1, −OPENVG |
| **iOS / tvOS** | `SDL_RENDERER` | **24** | identical set to Android — **and none of it is claimed** |
| **Emscripten** | `WEBGL2` | **24** | −14 Windows, −METAL, −OPENGLES2/3/OPENGL33, −MAGNUM, −WICKED, −OPENGL1, −OPENVG |

Membership, spelled out:

- **Linux (26):** SDL_RENDERER, OPENGLES2, OPENGLES3, OPENGL33, BGFX, VULKAN, WEBGPU, MAGNUM,
  HEADLESS, SOFTWARE, STUB, SKIA, BLEND2D, FREEDIRECT, SDL_GPU, OPENGLES1, OPENGL4, OPENGL1,
  OPENGL2, WICKED, SOKOL, DILIGENT, LLGL, FNA3D, OPENVG, PORTABLEGL
- **macOS (26):** the Linux set with **OPENGL1 → METAL**
- **Android / iOS (24):** the Linux set minus OPENGL1, OPENVG
- **Emscripten (24):** SDL_RENDERER, WEBGL1, WEBGL2, BGFX, VULKAN, WEBGPU, HEADLESS, SOFTWARE,
  STUB, CANVAS, HTML_DOM, SKIA, BLEND2D, FREEDIRECT, SDL_GPU, OPENGLES1, OPENGL4, OPENGL2, SOKOL,
  DILIGENT, LLGL, FNA3D, SVG_DOM, PORTABLEGL
- **Windows (39/40):** everything except the 5 Emscripten-only, METAL, and (on x86_64) GLIDE

> **Critical framing for the book:** these numbers are **configure-gate admissibility only**. They
> say the platform check does not hard-error — nothing more. Many admitted entries certainly fail
> later on dependency grounds: `OPENGL4` calls `find_package(OpenGL REQUIRED)` (`:794`);
> `OPENGLES1` hard-errors without system `libGLESv1_CM`
> (`modules/renderers/opengles1/CMakeLists.txt:8-15`); the five GL profiles need a sibling
> `../easy-gl` checkout (`:453-461`); `FREEDIRECT` needs sibling `../free-direct` (`:473-481`);
> `SKIA` needs a pre-built artifact; `DIRECTX8` needs DXVK's `d3d8.dll.a` at link time. **The
> honest per-platform "actually builds" set is far smaller than the admissible set, and no
> artifact in the repo enumerates it.**

### Per-renderer Windows runtime dependency

| Renderer | Runtime component under Wine | Evidence |
|---|---|---|
| DIRECTX1/2/3/5/6/7 | **Wine builtin `ddraw.dll`** (DXVK does not translate DirectDraw) | `scripts/run-wine-directx1.sh:7-10` and siblings |
| DIRECTX8 | **DXVK D8VK** `d3d8` native; `dxgi` deliberately **builtin** | `scripts/run-wine-directx8.sh:20-30`; `modules/renderers/directx8/CMakeLists.txt:6-13` |
| DIRECTX9 | **DXVK `d3d9`** | `scripts/run-wine-dxvk9.sh:12-19` |
| DIRECTX10 | **Wine builtin `d3d10.dll`/`d3d10_1.dll` → DXVK `d3d10core` + `dxgi`** | `scripts/run-wine-directx10.sh:12-16` |
| DIRECTX11 | **DXVK** `d3d11` + `dxgi` | `scripts/run-wine-dxvk.sh:2-12` |
| DIRECTX12 | **vkd3d-proton** `d3d12`/`d3d12core` | `scripts/run-wine-vkd3d.sh:2-14` |
| DIRECT2D | **Wine builtin `d2d1` on WineD3D** (Wine lane) / on DXVK (Proton lane) | `docs/direct2d-runtime-support-matrix.md:14-16` |
| GDI | Wine's own `gdi32` — **no wrapper script exists** | `docs/gdi-renderer.md:327-332` |
| GLIDE | external, separately-licensed `glide3x.dll` via `LoadLibraryA` | `modules/renderers/glide/src/GlideRenderer.cpp:319-331` |

---

## 3. FACTS

### Build system and toolchains

**1.** Two toolchain files exist, both MinGW, both ~20 lines: `cmake/toolchains/mingw-w64.cmake:13-32`
(x86_64, with an i686 fallback at `:17-22`) and `cmake/toolchains/mingw-w64-i686.cmake:6-17`
(exists specifically for GLIDE's 32-bit Glide ABI). **There is no Android, Emscripten, or Apple
toolchain file in CNA** — the NDK's own and emsdk's own are referenced by absolute path in
docs/CI only. **VERIFIED.**

**2.** SDL3 is auto-built at CMake-configure time, per target triple. `cna_configure_vendored_sdl()`
(`cmake/ThirdPartySDL.cmake:31-172`) is called unconditionally from `CMakeLists.txt:74-75` *before*
renderer selection. `_cna_build_sdl_dep()` (`:177-235`) runs configure→build→install via
`execute_process`, forwarding the parent's `CMAKE_TOOLCHAIN_FILE` (`:186-188`) and, on Android,
`ANDROID_ABI`/`ANDROID_PLATFORM`/`ANDROID_STL` (`:189-201`). Cache root is
`.sdl-prebuilt-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}` (`:26`), or
`.sdl-prebuilt-emscripten` (`:21-22`). **VERIFIED.**

**3.** Only two prebuilt SDL trees exist on this machine: `.sdl-prebuilt-Linux-x86_64/` and
`.sdl-prebuilt-Windows-x86_64/`. **No `.sdl-prebuilt-emscripten/`, no
`.sdl-prebuilt-Android-aarch64/`** — yet
`modules/devices/examples/demo_devices/android/…/app/jni/CMakeLists.txt:6` depends on the latter
and `plan_sdlgpu.md:538` asserts it "already exists". The checked-in Android Gradle project cannot
build without regenerating it. **VERIFIED.**

**4.** Emscripten uses `-fwasm-exceptions` project-wide, set before `sharp-runtime` is added
(`CMakeLists.txt:50-53`). The 21-line comment at `:29-49` records the real cause: legacy
`-fexceptions` produced `wasm-ld: undefined symbol: __cpp_exception` because sibling `easy-gl`
sets `-fwasm-exceptions` in its own directory scope, which does not propagate to CNA's link steps.
`-sNO_DISABLE_EXCEPTION_CATCHING` was **dropped, not replaced.** **VERIFIED.**

**5.** Windows tests run under Wine transparently via `CROSSCOMPILING_EMULATOR`. Exactly two sites
set it: `cmake/UnitTests.cmake:317-378` (on `CnaTests`, one branch per DirectX renderer) and
`cmake/Harnesses.cmake:202-213` (on `cna_strict_xna_api_check`). Per-renderer *example* tests
instead build the wrapper into `COMMAND` inside `if(CMAKE_CROSSCOMPILING)`. Rationale at
`cmake/UnitTests.cmake:303-316`: without it, `gtest_discover_tests(… PRE_TEST)` execs a PE32+
binary natively and dies. **VERIFIED.**

**6.** Six distinct WINEPREFIXes, not three: `~/.wine` (Direct2D,
`scripts/run-wine-direct2d.sh:30`), `~/.wine-cna-dx1` (shared by DX1/2/3/5/6/7), `~/.wine-cna-dx8`,
`~/.wine-cna-d3d10`, `~/.wine-cna-d3d11` (shared by D3D9+D3D11), `~/.wine-cna-d3d12` — plus
throwaway `mktemp` prefixes from `scripts/run-direct2d-fresh-wine-suite.sh:42-44`. All six named
prefixes exist on this machine dated 2026-08-04. **VERIFIED.**

**7.** Each Wine launcher enforces a runtime-engagement gate, **except Direct2D**. DX1–DX7 grep for
a `:ddraw:` trace; DX8/9/10/11 grep for `DXVK:`; DX12 greps for
`vkd3d-proton - applicationVersion:`; each exits 3 on failure. Direct2D has no `d2d1`-engagement
equivalent, and every Direct2D CTest registration disables the inherited DXVK gate
(`modules/renderers/direct2d/examples/CMakeLists.txt:39,63,93,119`; `cmake/UnitTests.cmake:376`).
A silently mis-provisioned Direct2D prefix would not be detected. **VERIFIED.**

**8.** `cmake/patches/` contains five patches; none is Windows-related. One bgfx MSAA-caps patch,
one ShivaVG context-destructor leak fix (OPENVG/desktop GL), three Wicked Engine patches (SDL3
platform branch, Vulkan device teardown, Vulkan staging-buffer footprint). Plus
`apply-shivavg-patch.cmake`, an idempotent reverse-checking `git apply` wrapper. **VERIFIED.**

**9.** `CNA_DIRECT2D_TEST_RUNTIME` (`CMakeLists.txt:66-67`) is consumed in exactly one file —
`modules/renderers/direct2d/examples/CMakeLists.txt`, four times (`:33/40/45`, `:60/64/69`,
`:90/94/99`, `:116/120/125`) — and only when `CMAKE_CROSSCOMPILING`. `CnaTests` under `DIRECT2D` is
**hardwired to Wine regardless** (`cmake/UnitTests.cmake:375-376`), so `PROTON` produces a split
configuration. Undocumented. **VERIFIED.**

**10.** `scripts/direct2d-proton-pin.txt:13-14` pins Proton 9.0(Beta) then 8.0, refusing
`Proton - Experimental` unless explicitly allowed (`scripts/run-proton-direct2d.sh:86-98`).
**`scripts/run-proton-vkd3d.sh:46` still hardcodes `Proton - Experimental` as its default** — the
exact moving target the pin file exists to forbid. **VERIFIED.**

**11.** Both Proton scripts hard-refuse `~/.wine` (`run-proton-direct2d.sh:159-165`,
`run-proton-vkd3d.sh:82-89`). The guard documents a real 2026-07-14 incident where Proton's
wine-11.0 half-upgraded the developer's personal `~/.wine` (wine 10.0) and hung 9.5 h on
`install_mono`. Bootstrap is now `timeout`-wrapped (`:111-122`). **VERIFIED.**

### MSVC and native Windows

**12.** CNA's own CMake contains exactly three `MSVC` occurrences, none configuring CNA:
`cmake/ThirdPartyOpenVG.cmake:115` (vendored ShivaVG `/FI` vs `-include`),
`cmake/ThirdPartyENet.cmake:21-22` (vendored ENet), `cmake/RendererSelection.cmake:342` (a
comment). **VERIFIED.**

**13.** `_MSC_VER` appears in one file under `modules/` —
`modules/renderers/sokol/src/shaders/sokol_shaders.hpp` (8 sites), machine-generated sokol-shdc
output (`SOKOL_SHDC_ALIGN` → `__declspec(align)` vs `__attribute__((aligned))`). **There is zero
hand-written MSVC conditional compilation in CNA**; excluding the generated file drops production
`_MSC_VER` usage to zero. **VERIFIED.**

**14.** Both Windows workflows are `workflow_dispatch`-only (`d3d-windows-ci.yml:30-31`,
`gdi-windows-ci.yml:10-11`), `windows-latest` + `ilammy/msvc-dev-cmd@v1` + Ninja. They *do* run
tests, not just build (`d3d-windows-ci.yml:216-255`). **VERIFIED.**

**15.** The only real GitHub Actions run ID cited anywhere in the repo is `29814126178`,
`macos-14`, Xcode 15.4 (`integration/lanes/metal.md:38`, `plan_metal.md:25`,
`docs/metal-renderer.md:23`). **No Actions run ID is cited for either Windows workflow.**
**VERIFIED.**

**16.** 32-bit Windows is structurally blocked and will stay blocked. `NEXT_glide.md:30`: sibling
`sharp-runtime`'s `System::Int128`/`Decimal` require the GCC/Clang `__int128` extension, and
`i686-w64-mingw32-g++ 14` genuinely does not support it for a 32-bit target — verified with a
standalone repro, and sharp-runtime's own CLAUDE.md records this as *"an explicit, permanent,
accepted 2026-07-11 decision"*. `integration/lanes/glide.md:71,207-209`: the whole GLIDE renderer
passes `-fsyntax-only` and its 39-export fake-DLL ABI client exits 0 under Wine, but **the full
i686 CNA executable cannot link.** GLIDE is therefore at (a)+(b)+partial(c), never (d).
**VERIFIED.**

### macOS / Metal

**17.** The Metal renderer is 3,842 lines of Objective-C++ in one file
(`modules/renderers/metal/src/MetalRenderer.mm`) behind a pure-C++ PIMPL header
(`…/MetalRenderer.hpp`, 563 lines, **zero** `MTL`/`Metal.h`/`__OBJC__` tokens).
`enable_language(OBJCXX)` fires only inside the `METAL` branch
(`cmake/RendererSelection.cmake:770`); the `.mm` glob and Metal/QuartzCore/Foundation framework
links are gated on `CNA_GRAPHICS_RENDERER STREQUAL "METAL"`
(`modules/renderers/metal/CMakeLists.txt:8-14`). **VERIFIED.**

**18.** `ctest -R '^Metal'` matches three different things, and on Linux it matches only the
portable one. `Metal_PortableHelpers` is registered **unconditionally** whenever `CNA_BUILD_TESTS`
is on (`modules/renderers/metal/examples/CMakeLists.txt:35-36`); `Metal_Smoke` and
`Metal_Capabilities` require `CNA_GRAPHICS_RENDERER=METAL` (`:39-69`).
`modules/renderers/metal/CMakeLists.txt:1-3` states the policy suites are *"deliberately
host-portable and compile into the CnaTests corpus on every renderer"*. Corroborated by
`integration/lanes/metal.md:281`, which records `ctest -R '^Metal'` = **207/207 on a Linux HEADLESS
build**. **This is the single most important distinction in the Apple story: a green `^Metal` run
proves nothing about Apple hardware unless the build was `METAL`.** **VERIFIED.**

**19.** No adapted Apple execution is evidenced at this SHA. `integration/lanes/metal.md:26-27`:
*"This host is Debian and has neither Apple's framework headers nor a Metal device."* `:49-53`:
*"There is no fresh adapted Objective-C++ compile, native static link, MSL compile, Metal
validation, pixel, Retina, frame-pacing, physical-display, Intel/Apple-Silicon comparison, or
iOS/tvOS result. The current workflow is the route to that evidence; **no integrating session
pushed or ran it**."* `:290` (validation matrix): *"Adapted macOS/physical Apple run | **not run** |
Explicit external boundary; no pass claimed."* **VERIFIED.**

**20.** The *historical* macOS evidence is real but pre-adaptation.
`integration/lanes/metal.md:38-47`: GitHub Actions run `29814126178`, `macos-14`, Xcode 15.4, Metal
API/GPU validation on; native build passed; **CTest 143 total / 136 passed / 7 failed**. Six
failures returned only the most recent clear colour. That was the *original* `feature/metal` tree;
the adaptation changed interfaces, lifetime, transfer policy, registration and supported behaviour,
so `:49` classifies it as *"historical original-tree evidence only."* Commit `4a8f216c1`
(2026-07-20, *"first fully green metal-macos-ci.yml run"*) belongs to that same pre-adaptation era.
**VERIFIED.**

### CI reality

**21.** 🔴 **Two automatic Linux workflows fail at CMake configure at this SHA.**
`.github/workflows/general-tests-ci.yml:133` and `.github/workflows/input-ci.yml:106` (matrix legs
`EasyGL` and `ASan+UBSan`, `:38,43`) pass `-DCNA_GRAPHICS_RENDERER=EASYGL`. **`EASYGL` has not been
an accepted selector since 2026-07-19** (commit `b0f31a7dc`, *"make EasyGL an internal
implementation, add 4 public GL backends"*); `docs/renderer-registry.md:67` states *"`EASYGL` and
the temporary `DX30` are not accepted selectors or compatibility aliases"*, and
`cmake/RendererSelection.cmake:867-869` `FATAL_ERROR`s on anything unknown. Both workflows were
touched 2026-08-10/11 for the `CNA_GRAPHICS_BACKEND`→`CNA_GRAPHICS_RENDERER` key rename **without
updating the value**. `general-tests-ci.yml` triggers on **every push, any branch**. **VERIFIED.**

**22.** 🔴 **The D3D11 CI leg's final step cannot run.**
`scripts/verify_hlsl_shaders_native_msvc.py:30` computes
`REPO_ROOT / "src" / "CNA" / "Internal" / "Renderers" / "D3DCommon" / "shaders"` and then imports
from it (`:31-32`). **`src/` does not exist** at this SHA; the real location is
`modules/renderers/common/d3d/src/shaders/compile_shaders_hlsl.py`. `ModuleNotFoundError` before
anything compiles. **VERIFIED.**

**23.** 🟡 `metal-macos-ci.yml`'s push path filters name three files that no longer exist:
`cmake/BackendLibraries.cmake` (`:8`), `cmake/Examples.cmake` (`:11`),
`cmake/Tests/MetalTests.cmake` (`:12`). All were dissolved by `33088cba6` (2026-08-10, *"localize
module CMake ownership"*). The workflow's `pull_request:`/`workflow_dispatch:` triggers are
unfiltered, so it is not fully dead — but its push trigger no longer watches the real Metal build
files. **VERIFIED.**

**24.** CI trigger reality on `develop`: `general-tests-ci` and `htmldom-ci` fire on every push (any
branch); `input-ci` on `feature/input`/`develop`/`master`; `devices-tests` and
`32bit-arithmetic-ci` **only on `master`/`main` pushes** — so they never gate `develop`;
`metal-macos-ci` on push (path-filtered, partly stale) + PR; `d3d-windows-ci` and `gdi-windows-ci`
**manual only**. **VERIFIED.**

**25.** `htmldom-ci.yml` is a genuine, complete Emscripten CI job — the only one. `ubuntu-24.04`,
pinned emsdk `6.0.3` (cached), sibling `sharp-runtime` clone, cached `.sdl-prebuilt-emscripten`,
`npx playwright install --with-deps chromium`, `emcmake cmake … -DCNA_GRAPHICS_RENDERER=HTML_DOM`
(`:118`), then `scripts/run-htmldom-test-suite.sh` running **six** browser pages (`:127`). Created
2026-08-10 (`7972f77d4`). **VERIFIED.**

### Web / Emscripten

**26.** The five Emscripten renderers sit at four distinct evidence levels:

| Renderer | Browser run | Pixel-checked | In CI | Evidence |
|---|---|---|---|---|
| `HTML_DOM` | ✔ headless Chromium/Playwright | ✔ 4 screenshot point-samples | ✔ every push | `htmldom-ci.yml`; `scripts/htmldom-browser-test.mjs:145` |
| `SVG_DOM` | ✔ headless Chromium/Playwright | ✔ 4 point-samples + structural anti-spoofing | ✖ **no workflow** | `docs/svg-dom-renderer.md:236-241` (34 checks); `scripts/svgdom-browser-test.mjs:51-65,126` |
| `WEBGL2` | ✖ never | ✖ | ✖ | `docs/webgl2-renderer.md:30-45` — `node` reaches `ReferenceError: window is not defined` |
| `WEBGL1` | ✖ never | ✖ | ✖ | `docs/webgl1-renderer.md:82-88` — *"no real WebGL 1 implementation has ever actually compiled the generated GLSL text"* |
| `CANVAS` | ✖ never | ✖ | ✖ | `docs/canvas-renderer.md:13-21,131` — `SDL_Init(SDL_INIT_VIDEO)` throws under `node`; a 12-item manual checklist, **all unchecked** |

**VERIFIED.** Pixel checks are tolerance-based 1×1 samples off `page.screenshot()`, **not** full
golden-image diffs — neither DOM nor SVG backbuffers can be read back in-page.

**27.** The `emscripten_set_main_loop` unwind bug is the freshest and most instructive platform work
in the repo. `emscripten_set_main_loop(fn, fps, simulateInfiniteLoop=1)` is implemented as a raw JS
`throw 'unwind'`; under `-fwasm-exceptions` the `catch_all` cleanup landing pad genuinely catches
that foreign JS throw, so a stack-local `Game` is **destroyed at the call site, before frame 1** —
deleting the owning `GraphicsDeviceManager` and dangling `Game::graphicsDeviceManager_`. Proven in
isolation by `emscripten-mainloop-stack-spike/repro.cpp` and fixed by heap-allocating in 12 example
`main()`s (commit `b6686bfba`, 2026-08-11; `docs/emscripten-mainloop-game-lifetime.md`). A
`GameServiceContainer` multiple-inheritance hypothesis was investigated and **ruled out** under
native ASan+UBSan+vptr and Emscripten `-sSAFE_HEAP` first. **VERIFIED.**

**28.** 🔴 That audit missed one target, and it is Emscripten-*only*.
`docs/emscripten-mainloop-game-lifetime.md:71-72` claims every Emscripten-reachable example was
audited. `modules/graphics/examples/graphics_renderer_benchmark.cpp:274` still reads
`GraphicsRendererBenchmark game;` on the stack, and
`modules/graphics/examples/CMakeLists.txt:164` gates that target on
`if(CNA_BUILD_TESTS AND EMSCRIPTEN)`. Its numbers are quoted at `plan_html_dom.md:300`.
**VERIFIED.**

**29.** The Emscripten game loop diverges from the native one in five undocumented ways
(`modules/runtime/src/Game.cpp:789-831` vs `:337-450`): `SuppressDraw()` is ignored;
`IsFixedTimeStep=false` is ignored (always fixed-step); `IsRunningSlowly` is hardcoded `false`
(`:814`); `EndRun()`/`AfterLoop()` never run (`RunLoop()` unwinds and never returns); and the
frame-delta clamp is a hardcoded `250.0 ms` (`:798-801`) instead of `MaxElapsedTime`. **The clock
also differs**: native uses `SDL_GetPerformanceCounter` + `SDL_Delay(1)` (`:330,350,365,862`), web
uses millisecond `SDL_GetTicks()` (`:789`). **VERIFIED.** Sharpened by FACT 58.

**30.** Emscripten builds are single-threaded by default configuration. Repo-wide grep for
`USE_PTHREADS`, `-sPTHREAD`, `PROXY_TO_PTHREAD`, `SharedArrayBuffer` over CNA's own files returns
**zero** hits. The single concurrency accommodation is `-sASYNCIFY=1` on `CnaTests` only
(`cmake/UnitTests.cmake:186`), for the WebSocket/ENet suite. Practical consequence: no COOP/COEP
cross-origin-isolation requirement, which is why both harnesses serve over plain
`python3 -m http.server`. **VERIFIED.**

**31.** 🔴 Web save data is volatile and nothing says so. `StorageDevice.cpp:75` calls
`SDL_GetPrefPath(nullptr, app)` with no Emscripten branch. SDL's Emscripten backend
(`third_party/SDL/src/filesystem/emscripten/SDL_sysfilesystem.c:40-52`) prefixes
`SDL_EMSCRIPTEN_PERSISTENT_PATH_STRING` **if defined at SDL build time**, else the hardcoded
`"/libsdl"`. **CNA never sets `SDL_EMSCRIPTEN_PERSISTENT_PATH`** (verified: zero hits outside
`third_party/`). No IDBFS mount, no `FS.syncfs`, no localStorage bridge anywhere. Every
`StorageDevice`/gamer-services write on web lands in MEMFS and is lost on page reload.
**VERIFIED, and documented nowhere.**

**32.** Asset delivery on web is exactly two `--preload-file` sites:
`modules/graphics/examples/CMakeLists.txt:32` (demo_2d Content) and
`modules/audio/examples/CMakeLists.txt:26` (demo_sound Content). `--embed-file` and `--shell-file`
are used **nowhere** — every target relies on Emscripten's default shell page for the `<canvas>`
SDL3 binds to. **VERIFIED.**

### Android

**33.** A complete, real Android Gradle+NDK application exists at
`modules/devices/examples/demo_devices/android/com.openeggbert.cna.demodevices/` (39 files:
`gradlew`, wrapper jar, `AndroidManifest.xml`, `DemodevicesActivity extends SDLActivity`, 11
vendored `org/libsdl/app/*.java`, launcher icons, `app/jni/`). `app/jni/CMakeLists.txt:12` does
`add_subdirectory(<cna-root>)` — **the APK build compiles the entire CNA library for Android.**
Config: `compileSdk 35`, `ndkVersion 30.0.14904198`, `minSdk 24`, `abiFilters 'arm64-v8a'` only.
**VERIFIED.**

**34.** `modules/devices/` contains ~2,090 lines of genuine NDK sensor code
(`AndroidSensorBridge.cpp` 1180 L, `AndroidMotionBackend.cpp` 413 L, `AndroidCompassBackend.cpp`
228 L + headers) making the full `ASensorManager_getInstance` / `ALooper_prepare` /
`createEventQueue` / `enableSensor` / `pollOnce` / `getEvents` sequence with rollback and a
dedicated thread. **No JNI anywhere in CNA.** The *math* headers are deliberately **not**
`__ANDROID__`-gated so they unit-test on the Linux CI host; the I/O files are fully gated.
**VERIFIED.**

**35.** The only Android-specific link in all of CNA is
`target_link_libraries(cna_devices PUBLIC android log)` at `modules/devices/CMakeLists.txt:21` (for
`libandroid.so`'s sensor API and `liblog.so`'s `__android_log_print`). The root `CMakeLists.txt`
contains **zero** `ANDROID` references. **VERIFIED.**

**36.** Android execution happened twice, both on an emulator, neither leaving an artifact. Commit
`25973bdfd` (2026-07-04): `CnaTests` cross-built with the NDK toolchain and run on a
`Medium_Phone` AVD as a bare pushed executable, **230/230** Net/Gamer/ENet/Packet tests passing plus
1831 others — corroborated by two surviving code fixes (`cmake/ThirdPartySDL.cmake:189-201` ABI
forwarding; `cmake/UnitTests.cmake:95-96` exclusion). Commit `73455c634` (2026-07-05): first APK,
`BUILD SUCCESSFUL in 1m 39s`, 7.3 MB, `adb install` + `am start` + `adb shell screencap`, sensor
injection via the emulator console (`docs/devices-build.md:329-375`). **A repo-wide `find` for
`*.apk`, `*.aab`, `*logcat*`, `*android*.png`, `*android*.log` returns nothing.** **STRONG** (that
it happened) / **WEAK** (as durable artifact).

**37.** Android graphics has never been attempted. `docs/android-graphics-limitations.md:84`: *"Real
device/emulator graphics execution — **Never attempted in this project's history**"*; `:56-61`:
whether `SdlRenderer.cpp` "compiles cleanly for arm64-v8a/Android at all" is *"NOT verified,
currently unknown."* The only renderer with real `__ANDROID__` code is WEBGPU
(`WGPUSurfaceSourceAndroidNativeWindow`, `modules/renderers/webgpu/src/WebGPURenderer.cpp:2376-2382`).
**VERIFIED.**

**38.** 🟡 Mobile lifecycle handling is 2 of 4+. `modules/runtime/src/Game.cpp:933-939` handles
`SDL_EVENT_WILL_ENTER_BACKGROUND` / `DID_ENTER_FOREGROUND` only. **No handler anywhere for
`DID_ENTER_BACKGROUND`, `WILL_ENTER_FOREGROUND`, `TERMINATING`, or `LOW_MEMORY`** — they fall to
`default: break` (`:954-955`). No GPU-resource teardown on backgrounding, no save hook on
terminate, no cache eviction on low memory. **VERIFIED.**

**39.** Android asset access goes through `SDL_LoadFile`, never `AAssetManager`.
`modules/runtime/src/TitleContainer.cpp:36-58` and `:97-125`: try `std::filesystem` first, and
**only under `#if defined(__ANDROID__)`** fall back to `SDL_LoadFile` wrapped in a `MemoryStream`.
🔴 Commit `25973bdfd`'s body records that this exact fallback *segfaults* when run without a real
JNI/Activity context, and says it was "Documented in NEXT.md's known-bugs table." It is not:
`known_bugs.md` (127 KB) contains zero "android" occurrences, and the code is unchanged in
substance. **VERIFIED.** See FACT 52 — the fallback is in fact unreachable from `ContentManager` at
all.

### Platform abstraction inside CNA

**40.** CNA has a two-level compile-time platform taxonomy, and it is live, not decorative.
`modules/core/include/CNA/Platform.hpp:13-48` defines
`enum class Platform { Desktop, Android, iOS, Web }` and a `constexpr getCurrentPlatform()`
switching on `__EMSCRIPTEN__` / `__ANDROID__` / `__APPLE__`+`TARGET_OS_IPHONE`
(`TargetConditionals.h` included at `:6-8`). `modules/core/src/DesktopOS.cpp:12-27` adds
`DesktopOS { Windows, Linux, MacOSX, Other }`, throwing if the platform is not `Desktop`
(`:14-17`). Real consumers: `modules/devices/src/Sensors/Accelerometer.cpp:66-70`,
`Gyroscope.cpp:44-48`, `modules/devices-ext/src/SystemTray.cpp:13-19`, `FileDialog.cpp:44-51`,
`modules/renderers/easygl/src/EasyGLRenderer.cpp:9`. `modules/core/src/Platform.cpp` is an empty
TU — the "platform module" carries no implementation. **VERIFIED.**

**41.** **Platform variation in CNA is expressed as CMake target selection, not preprocessor
branching — and platform handling is concentrated, not scattered.** Production-code measurement
(files under `modules/`, excluding `tests/` and `examples/`):

| Metric | Value |
|---|---|
| Production files in `modules/` | **1,195** |
| Production files containing **any** OS platform `#if` directive | **56 (4.7%)** |
| Total such directives in production code | **159** |
| …in `modules/renderers/` (third-party-SDK native-handle glue) | **104 (65%)** |
| …in the framework proper (runtime/graphics/input/content/net/devices/core) | **55 (35%)** |
| `SDL_*`/`MIX_*`/`IMG_*`/`TTF_*` symbol occurrences, production | **5,983** across **125 files** |
| **Ratio SDL-API references : OS `#ifdef` directives** | **≈ 38 : 1** |
| `#if…CNA_RENDERER_*` directives (the *real* variation axis) | **109** |

Seven whole modules contain **zero** OS conditionals: **storage (0 of 7 files), media (0/100),
audio (0/75), math (0/62), gamer-services (0/150), devices-ext (0/49), graphics-ext (0/31)**.
`modules/graphics/` has 2 of 377. Per-macro production token counts: `__EMSCRIPTEN__` 79,
`__ANDROID__` 53, `_WIN32` 21, `__APPLE__` 12, `__linux__` 9, `_MSC_VER` 8, `__clang__` 4,
`__MINGW32__` 3, `_WIN64` 2, `__GNUC__` 2; `__unix__` **0 in production** (all 13 sites are
POSIX-only test/example scaffolding); bare `WIN32`, `__CYGWIN__`, `__FreeBSD__`, `__HAIKU__` **0**.

The project states this as explicit policy. `MODULARIZATION_PLAN.md:311-314`, quoted exactly:

> **`cna-platform-*` targets**: no platform abstraction layer exists in current code; SDL use is
> embedded per subsystem (each module links SDL3 PRIVATE). Creating platform targets now would
> require semantic extraction. The SDL-touching TU inventory per module is documented instead; a
> real platform split is future work.

Restated at `plan_cna_devices.md:17-21`: *"No pluggable `IDevicesBackend`-per-platform layer —
SDL3 itself is already the cross-platform abstraction for every capability in this plan."*
**VERIFIED.**

> *Correction note:* an earlier pass of this audit reported "255 macro sites — scattered, not
> centralized." That figure was a **token count including comments, tests and examples**, and was
> the wrong metric; it does not support a "scattered" conclusion. The directive-level production
> measurement above supersedes it, and reverses the characterization.

**42.** SDL3 absorbs the platform-varying primitives, and CNA leans on it hard. Non-test call-site
counts in `modules/`: `SDL_getenv` 11 (`modules/storage/src/StorageDevice.cpp:91,97`;
`modules/graphics/src/Xna/GraphicsDevice.cpp:211,226`; bgfx/llgl/skia), `SDL_IOStream` 10,
`SDL_GetPowerInfo` 8 (`modules/input/src/Internal/SystemPowerBackend.cpp:12`;
`modules/devices-ext/src/PowerInfo.cpp:30,36,43`), `SDL_Delay` 7
(`modules/runtime/src/Game.cpp:365`), `SDL_GetPrefPath` 4
(`modules/storage/src/StorageDevice.cpp:75`), `SDL_GetPerformanceCounter` 4
(`Game.cpp:330,350,862`), `SDL_OpenURL` 3 (`modules/devices-ext/src/UrlLauncher.cpp:12`),
`SDL_GetUserFolder` 3 (`modules/media/src/Internal/MediaLibraryPaths.cpp:24`), `SDL_GetTicks` 3
(`Game.cpp:789`), `SDL_GetPlatform` 1
(`modules/runtime/src/GraphicsDeviceManager.cpp:25`), `SDL_GetBasePath` 1
(`modules/runtime/src/TitleLocation.cpp:42`). **`SDL_LoadObject`, `SDL_LoadFunction`,
`SDL_CreateThread`, `SDL_CreateMutex`, `SDL_IOFromFile`, `SDL_CreateDirectory`,
`SDL_EnumerateDirectory`, `SDL_setenv`: 0 uses each.** **VERIFIED.**

**43.** **CNA constructs exactly ONE thread in all of production code, and it is Android-only:**
`modules/devices/src/Sensors/Detail/AndroidSensorBridge.cpp:888`
(`impl_->worker_ = std::thread(…)`; member declared at `:189`), inside the file-wide
`#ifdef __ANDROID__` opened at `:23`. Every other `std::thread` hit in production is
`std::thread::id` or a comment. Primitives are `std::*`, never SDL: `std::mutex` 224 occurrences,
`std::atomic` 50, `std::condition_variable` 11; `SDL_Thread`/`SDL_CreateThread`/`SDL_CreateMutex`/
`pthread_`/`std::jthread`/`std::async` all **0**. Corollaries: **no audio mixing thread** — CNA
registers callbacks *into* SDL3_mixer's thread
(`modules/audio/src/Xna/SoundEffectInstance.cpp:29`, callbacks installed at `:716,739,762,940`;
`modules/audio/src/Internal/AudioMixer.cpp:16-39` holds `g_mixerMutex` + an atomic live-track
handle to make that safe); **no content-loading thread** (a threading grep over
`modules/content/` production code returns nothing — loading is fully synchronous); and the net
module is **single-threaded by written contract** —
`modules/net/include/CNA/Internal/Net/ENetBackend.hpp:36-45`: *"Task 6.4: single-threaded only, by
design and by contract… There is no internal synchronization (no `std::mutex`/`std::atomic`
anywhere in this module)… this is an explicit, intentional constraint, not an oversight, and
matches XNA's own single-threaded design."* Input is main-thread only on all platforms
(`docs/platform-input-notes.md:152-153`). **VERIFIED.**

> *Correction note:* an earlier pass listed four files as evidence of threading. Those were files
> *containing the token* `std::thread`, not thread constructions.

**44.** Runtime dynamic loading exists in exactly two places, both Windows-only, both raw Win32 —
`SDL_LoadObject`/`dlopen` are **0 uses**:
(i) `modules/renderers/glide/src/GlideRenderer.cpp:314-338` — honours `CNA_GLIDE3X_DLL` (`:316`,
`LoadLibraryA` at `:319`), else `LoadLibraryA("glide3x.dll")` at `:327`; error text at `:330-334`
names dgVoodoo2 as the supported emulated runtime; module handle held at `:341`. Symbol resolution
handles x86 stdcall decoration —
`modules/renderers/glide/include/CNA/Internal/Renderers/Glide/GlideAbiLoader.hpp:11-35` tries plain
`GetProcAddress` (`:14`), then under `#if !defined(_WIN64)` `_Name@N` (`:18-19`) and `Name@N`
(`:23-24`).
(ii) `modules/renderers/gdi/src/GdiRenderer.cpp:206-215` — lazy `LoadLibraryW(L"dwmapi.dll")` +
`GetProcAddress("DwmFlush")` in a function-local static lambda, with a silent null fallback when
the compositor is absent or disabled (`:214-215`).
All GL entry-point loading is `SDL_GL_GetProcAddress` (53 occurrences; the design is documented at
`modules/renderers/opengl4/include/CNA/Internal/Renderers/OpenGL4/GL4Loader.hpp:4-13` — a
hand-rolled loader, no glad/GLEW vendored). FNA3D does **not** dynamically load; driver choice is
`FNA3D_FORCE_DRIVER`, read by FNA3D itself (`modules/renderers/fna3d/src/Fna3dRenderer.cpp:134-135`
only surfaces the failure). **VERIFIED.**

> *Correction note:* an earlier pass listed only the GLIDE site and missed the `dwmapi.dll` lazy
> load.

**45.** The entry point is abstracted behind `modules/core/include/CNA/Entrypoint.hpp` (25 lines) so
game code never includes `<SDL3/SDL_main.h>` directly — needed on Android so
`SDLActivity.nativeRunMain` can find the exported `SDL_main`; its doc comment (`:6-17`) states
*"Without this rename the app exits immediately because the `SDL_main` symbol is never exported
from the shared library"* and *"Game code must include this header instead of
`<SDL3/SDL_main.h>` directly so that the SDL dependency stays hidden behind the CNA platform
layer."* `WinMain`, `SDL_MAIN_HANDLED`, `SDL_MAIN_USE_CALLBACKS`: **0 occurrences** — CNA owns a
classic `main()` + blocking `Game::Run()`. `SDL3::SDL3main` is linked defensively
(`if(TARGET SDL3::SDL3main) … endif()`, ~140 sites). 🟡 Latent staleness: `:22` reads
`#elif defined(CNA_RENDERER_SDL) || defined(SDL_h_)`, and **`CNA_RENDERER_SDL` is defined nowhere**
(the real macro is `CNA_RENDERER_SDL_RENDERER`); that branch only ever fires via the incidental
`SDL_h_` include guard. **VERIFIED.**

**46.** `RAM.md` (last touched 2026-06-08) is stale in vocabulary but its fixes are real. It
predates the backend→renderer rename and refers to `EasyGLTextureBackend::image_data_`. Claimed
Fix 1 and Fix 3 both survive: `cpuPixels_` is `std::shared_ptr<std::vector<uint8_t>>`
(`modules/graphics/include/…/Texture2D.hpp:591`), and `ShareCpuPixels` is a real `ITextureRenderer`
hook (`modules/renderers/easygl/include/…/EasyGLRenderer.hpp:98`, implemented at
`EasyGLRenderer.cpp:1541`). Its subject, "mobile-eggbert", is a consumer app; **the document
contains no Android-specific measurement despite the name.** Fix 5 (sprite ring buffer sizing) is
still open. **VERIFIED.**

**47.** **The structural reason the `#ifdef` count is so low: platform exclusion is expressed as
target selection, so excluded code never needs a guard.**
`modules/renderers/glide/src/GlideRenderer.cpp:21` can `#include <windows.h>` completely unguarded
because `modules/renderers/glide/CMakeLists.txt:7-12` only compiles the family when
`CNA_GRAPHICS_RENDERER STREQUAL "GLIDE"`, and `cmake/RendererSelection.cmake:347-353` already
rejected that selector off Windows. There are 104 platform conditionals across
`CMakeLists.txt`/`*.cmake` under `modules/` + `cmake/` + root doing this work.
**This is the architectural thesis of the whole platform story.** **STRONG.**

**48.** The one *runtime* platform test in the framework —
`modules/runtime/src/GraphicsDeviceManager.cpp:23-32`, `platformSupportsOrientations()` returns
`SDL_GetPlatform() == "iOS" || == "Android"`. Deliberately a string compare, not an `#ifdef`,
citing FNA's `SDL3_FNAPlatform.SupportsOrientations` (`:19-22`). **VERIFIED.**

**49.** The most conventionally OS-specific code in CNA is command-line retrieval —
`modules/runtime/src/LaunchParameters.cpp:43-101`: Win32 `CommandLineToArgvW` +
`WideCharToMultiByte`; `__linux__ || __ANDROID__` reads `/proc/self/cmdline`; `#else` returns `{}`
with a comment (`:96-101`) that portable C++ exposes no global argv. **VERIFIED.**

**50.** The only direct kernel-interface read — `modules/graphics/src/Xna/GraphicsAdapter.cpp:110-132`
(`queryPciIds()`) walks `/sys/class/drm/card{0..3}/device/{vendor,device}` for PCI IDs. On every
non-Linux platform vendor/device stay `0`. **VERIFIED.**

**51.** Web networking is a genuinely different topology, not a shim.
`modules/net/src/Internal/ENetBackend.cpp:46-53` hardcodes `kEmscriptenHostPort = 61191` because
Emscripten's SOCKFS `bind()`/`getsockname()` never reports a real ephemeral port; `:1082-1090` binds
it instead of `ENET_PORT_ANY`; `:1246-1255` rebuilds the "client" role as an outbound-only host
because a browser tab cannot listen; and
`modules/net/src/Internal/ENetDiscoveryService.cpp:24` (`#ifndef __EMSCRIPTEN__`) excludes the
entire UDP-broadcast LAN-discovery implementation from Web builds. **This is a real capability
difference that the README's "verified real networking across four platforms" flattens.**
**VERIFIED.**

**52.** `TitleContainer` has no in-tree consumer, which makes the Android asset fallback
unreachable. A grep for `TitleContainer::`/`TitleLocation::` outside their own sources and tests
returns nothing; `modules/audio/src/Xna/WaveBank.cpp:119,124` and `SoundBank.cpp:51` mention it
only in comments explaining CNA deliberately does *not* route through it. **So the `SDL_LoadFile`
Android-asset fallback at `TitleContainer.cpp:36-58,97-125` — the one FACT 39 showed segfaults
without a JNI context — is not even reachable from `ContentManager`.** **STRONG** (grep-negative).

**53.** Content root is CWD-relative with no base-path prefix —
`modules/content/include/Microsoft/Xna/Framework/Content/ContentManager.hpp:50`
(`rootDirectory_ = "Content"`), `modules/content/src/Xna/ContentManager.cpp:296-308`
(`BuildAssetPath()` = `fs::path(rootDirectory_) / assetName`).
`modules/runtime/src/TitleLocation.cpp:40-53` wraps `SDL_GetBasePath()` with a
`std::filesystem::current_path()` fallback, but nothing in the content path calls it. A latent
portability problem on Android and macOS bundles. **VERIFIED.**

**54.** Platform-difference handling done in portable C++ rather than by `#ifdef` —
`modules/core/include/CNA/Internal/PathContainment.hpp:24-36` (`IsDisallowedAbsolutePath()`)
rejects drive-letter (`C:`) and UNC (`//server`) paths **even when compiled on POSIX**, because
(`:16-20`) *"`std::filesystem::path::is_absolute()` alone only recognizes a leading `/`, so a
Windows-style path… would slip through unrecognized when compiled/run on POSIX."* Separator policy
is "normalize `\` → `/` everywhere, never emit `\`":
`modules/runtime/src/TitleContainer.cpp:135-146`, `modules/content/src/Xna/ContentManager.cpp:313`,
`ContentReader.cpp:32`, `modules/media/src/Internal/SavedPictureStore.cpp:41`,
`PathContainment.hpp:134`. `std::filesystem` is used directly (134 occurrences, 28 production
files) and **no production `#include <filesystem>` is platform-guarded**. **VERIFIED.**

**55.** CNA is little-endian-only, deliberately and with exactly one assertion.
`modules/renderers/blend2d/include/CNA/Internal/Renderers/Blend2D/Blend2DPixelConvert.hpp:13-19`:
a comment recording that no CNA source has a big-endian path, then
`static_assert(std::endian::native == std::endian::little, …)` chosen so the build *"fail[s] with a
truthful diagnostic on a host where it would silently produce channel-swapped pixels."*
`SDL_Swap*`, `__BYTE_ORDER__`, `byteswap`, `bswap`, `BIG_ENDIAN`: **0 uses**. Likewise **no**
`sizeof(void*)` / `__LP64__` / `_LP64` / `__SIZEOF_POINTER__` assumptions anywhere in `modules/`.
**VERIFIED.**

**56.** `_WIN64` appears exactly twice, both in GLIDE, both about the 32-bit Glide ABI —
`GlideAbiLoader.hpp:11-35` searches for `_Name@N`/`Name@N` stdcall decoration only on x86;
`GlideAbi.hpp:59-67` applies `static_assert(sizeof(GlideTexInfo)==20 / GlideResolution==16 /
GlideVertex==48)` only on x86 (offset asserts are unconditional). A word-size branch, not an OS
branch. **VERIFIED.**

**57.** The 32-bit CI guards `std::size_t` multiplication overflow in allocation-size arithmetic at
a genuine 32-bit width. `.github/workflows/32bit-arithmetic-ci.yml:3-11` names REMED-MEDIA-001 /
GDI-067 / GDI-076 and states it *"compiles and RUNS AudioTagParser, SoftwareFramebuffer, and
SoftwareTexture width-dependent `std::size_t` bounds checks at a genuine 32-bit width… not a
`uint32_t`-arithmetic simulation on a 64-bit host."* It is standalone because
`tools/media/arithmetic32bit/CMakeLists.txt:7-14` records that SDL3/SDL3_image/SDL3_mixer/FFmpeg are
unavailable for a 32-bit target. The harness proves it is 32-bit before asserting anything else —
`tools/graphics/framebuffer_allocation_32bit_check.cpp:22-24` opens with
`sizeof(std::size_t) == 4`, then verifies a 4K 4×MSAA layout computes exactly (`:26-33`), that a
16384² 4×MSAA request is caught as `ArithmeticOverflow` *before wraparound* (`:35-40`), and that an
11000² request is distinguished as `ByteBudgetExceeded` (`:42-44`). The guarded code itself
(`modules/renderers/software/include/…/SoftwareFramebufferAllocation.hpp:14-28`) has **no
`#ifdef`** — it is width-portable by construction, with a documented 512 MiB ceiling *"keeps one
surface practical on a 32-bit process."* **VERIFIED.**

**58.** Timing detail sharpening FACT 29. Native `Game::Tick` (`modules/runtime/src/Game.cpp:357-425`):
sleep-until-target using `SDL_Delay(1)` gated by an adaptive `worstCaseSleepPrecision_` (`:363-368`,
adapted in `UpdateEstimatedSleepPrecision` `:882-903`, 4 ms cap at `:884`), then a
`std::this_thread::yield()` spin (`:371-375`, commented at `:370` as the C++ equivalent of FNA's
`Thread.SpinWait(1)`), `PollEvents()` at `:378`, accumulator clamped to `MaxElapsedTime = 500 ms`
(`:89`, `:380-383`), catch-up `Update()` loop at `:390-398`, lag/`IsRunningSlowly` at `:400-409`.
Clock is `SDL_GetPerformanceCounter`/`Frequency` (`:862`, `:870`) with the comment at `:861`: *"FNA
uses System.Diagnostics.Stopwatch; CNA uses SDL_GetPerformanceCounter for equivalent
high-resolution timing."* **The Emscripten fork clamps at a hardcoded 250 ms instead**
(`:798-801`), uses millisecond `SDL_GetTicks()` (`:789`) and its own `accumulatorMs` (`:803`), and
never sleeps or spins. `std::chrono` is used elsewhere (92 production occurrences — audio cue
fades, `MediaPlayer` position, gesture detection, the net module's injectable time source) but
never for the game loop. **VERIFIED.**

**59.** `docs/platform-input-notes.md` is the richest platform document in the repo and is almost
entirely a catalogue of *SDL's* differences, not CNA's — `:5-8` *"CNA's input runs on SDL3, so most
platform differences are SDL's, surfaced through the XNA-style API"*; `:26-31` Wayland returns
`(0,0)` from `SDL_GetGlobalMouseState`, *"a Wayland platform restriction, not a CNA bug"*; `:40-42`
Windows XInput reports GUID `"xinput"` vs Linux's 8-hex vendor+product; `:56-60` Android's touch
device only appears after the first `SDL_EVENT_FINGER_DOWN`; `:64-66` the Android `SdlInputBridge`
`#ifdef` is log-only; `:80-82` **"no browser-specific input code exists in CNA"**; `:178-186` SDL's
bundled `gamecontrollerdb` is the mapping authority, *"CNA does not ship or parse its own mapping
DB"*; `:163-174` a 5-row platform matrix for cursor warp/global position where **only the X11 row
is CI-verified**. **VERIFIED.**

**60.** `docs/physical-modules.md` describes the 2026-08-10 physical modularization (15 framework
modules + renderer families under `modules/renderers/`, each owning
`{CMakeLists,include,src,tests,examples}`) and **contains no platform-layer concept at all** —
platform variation appears there only as build-time renderer identity selection. Corroborating the
same policy, `modules/devices/examples/demo_devices/src/Main.cpp:1-19` includes
`<SDL3/SDL_main.h>` **directly**, violating `Entrypoint.hpp:16-17`'s own stated policy that game
code must go through the CNA header — a small but real inconsistency. **VERIFIED.**

---

## 4. CONTRADICTIONS

Ordered by how badly each would mislead a book reader.

**C1 — `README.md:550` claims verified Android *graphics*; the graphics doc says it never
happened.** README: `| Android (NDK) | Clang (NDK 29/30) | OPENGLES3 | ✅ verified building +
running on a real x86_64 emulator |`. Versus `docs/android-graphics-limitations.md:84`: *"Real
device/emulator graphics execution — Never attempted."* The README row was added by `b2c7dbe92` on
**2026-07-04** — the same day `47c33b886` recorded the emulator could not start at all (`/dev/kvm`
absent), and one day *before* the first APK existed. Also `OPENGLES3` is not Android's default
(`SDL_RENDERER` is) and requires a sibling `../easy-gl` checkout. **The row is unsubstantiated.**

**C2 — `README.md:29` claims `WEBGL2` has "full 2D+3D pixel-verified coverage."**
`docs/webgl2-renderer.md:30-45` records no browser run at all — `node` reaches
`ReferenceError: window is not defined`. The graphics pixel suites cannot even build under
Emscripten (excluded at ~14 module-local sites). `README.md:549` is the honest version of the same
claim.

**C3 — `docs/web-emscripten-graphics-limitations.md` has four false load-bearing claims.** `:32`
*"No workflow configures or builds an Emscripten target at all"* → `htmldom-ci.yml:118` does,
created the same day this doc was last edited. `:59` *"`-fexceptions
-sNO_DISABLE_EXCEPTION_CATCHING=1`"* → it is `-fwasm-exceptions` and the flag was dropped
(`CMakeLists.txt:48-52`); the same stale claim survives at `docs/platform-input-notes.md:87` and
`plan_graphics.md:629`. `:55-58` *"EasyGL is the default on Emscripten; no other renderer has
Emscripten wiring"* → the default is `WEBGL2` and three renderers are Emscripten-*only*. `:63-65`
*"house3d_demo is the only target pinning a WebGL version"* → now conditional, and the benchmark
pins too.

**C4 — `README.md:59`'s CI paragraph is wrong three ways.** It says Linux workflows run "the
`Input` and `Devices`/`Sensors` gtest suites, not the full ~4,370-test unit suite," and never
mentions Emscripten CI. In fact `general-tests-ci.yml` exists precisely to run the full unfiltered
suite; `htmldom-ci.yml` is a real Emscripten + headless-Chromium gate on every push; and
`devices-tests.yml` only triggers on `master`/`main` pushes, so it does not gate `develop` at all.
(Its *"no automatic Windows or Android gate"* clause is correct.)

**C5 — `.github/workflows/d3d-windows-ci.yml:21-26` justifies excluding `CnaTests` with a blocker
that was closed 2026-07-15.** The `::setenv()` gap was resolved (62 call sites across 13 files →
`System::Environment::SetEnvironmentVariable`; `docs/cnatests-mingw-setenv-proposal.md:3-12`), and
the only surviving `setenv(` calls are three files under `modules/*/examples/`, none in the
`CnaTests` glob. The D3D legs therefore skip a suite that would now build.

**C6 — `FUTURE.md:102` says SVG_DOM's "real-browser validation remains an external Emscripten-SDK
gate."** `docs/svg-dom-renderer.md:236-241` records 34 checks across three pages actually executed
in headless Chromium (smoke 13/13, pixel 20/20, scissor-order 1/1 with a real screenshot), and
`bd2ddc4c0`/`b6686bfba` (2026-08-11) exist *because* that browser run happened. The FUTURE.md row
predates the unblocking.

**C7 — `scripts/check_renderer_identities.py` says 42 in prose and enforces 46 in data.** Docstring
`:4` *"CNA has exactly 42 public renderer identities"* and comment `:19` *"42 entries"*, but the
`IDENTITIES` list holds **46**, and the script prints `len(IDENTITIES)` — so it reports "OK: 46"
while its own documentation says 42. `README.md:167`, `docs/renderer-registry.md:3` and
`modules/renderers/CMakeLists.txt:5` all correctly say 46. (`integration/lanes/metal.md:19,128` says
METAL is the "41st" and "40→41" — correct *at that lane's integration date*, not now.)

**C8 — Task 920 is still open but its stated cause is gone.**
`docs/android-graphics-limitations.md:82`, `plan_graphics.md:631` and `NEXT.md:2344` all assert the
Android cross-compile is blocked by two `sharp-runtime` bugs (`FileStream.hpp`'s unused `mode_`;
`FileSystemInfo.cpp`'s `std::chrono::clock_cast`). Neither exists in sibling `sharp-runtime` @
`f827a6c5` (2026-08-10) — both greps return zero. Whether the build now *succeeds* is
**UNCERTAIN** (no build was run, and both repos were modularized since).

**C9 — Docs still cite the pre-modularization file layout.** `docs/devices-build.md:305-309` and
`docs/devices-android.md:112-114` say the root `CMakeLists.txt` carries the `PUBLIC android` link
(it is at `modules/devices/CMakeLists.txt:21`). `integration/lanes/metal.md:83-88,121-129` speaks of
`MetalGraphicsBackend.mm`, `cmake/BackendLibraries.cmake`, `GraphicsBackendType`.
`audit/cmake/Tests/D3D11Tests.cmake.audit.md` reviews a file that no longer exists.

**C10 — `README.md:101-102,337-339` advertise MSVC 2022 and clang-cl as supported Windows
compilers.** There is no MSVC-specific line of code in CNA and no evidenced MSVC build
(FACTS 12–15). Only MinGW-w64 + Wine is evidenced.

**C11 — Numeric drift in the HTML_DOM record.** `docs/html-dom-renderer.md:16` says smoke 68/68;
`integration/BATCH_5_STABILIZATION.md:70` says 69/69; `docs/svg-dom-renderer.md:241` totals the
suite at 137/137 while the two per-page sets sum to 138/139. Also `htmldom-ci.yml:5` and
`docs/html-dom-renderer.md:43` say "four pages"; the script runs six.

---

## 5. BOOK IMPACT

### 5.1 The size of the drift

The existing Part VIII is **906 lines across four chapters** (ch39 Windows/Wine 253, ch40
Web/Emscripten 247, ch41 Android/NDK 219, ch42 verification methodology 187). Measured against this
SHA:

- **1,762 occurrences of "backend"** across `latex/book/chapters/` + `latex/common/` (51 in Part
  VIII alone). CNA renamed backend→renderer on 2026-08-10 (`57aee5f88`). Part IV's title, eight
  chapter *filenames*, and 21 identifier references (`GraphicsBackendType` ×8,
  `CNA_GRAPHICS_BACKEND` ×9, `cmake/BackendSelection` ×3, `cmake/BackendLibraries` ×1) are all now
  wrong. **This is an edition-wide migration, not a Part VIII fix.**
- **"45 public"** appears in four chapters (`ch01:73`, `ch02:182`, `ch45:4`, `ch49:14`); the number
  is **46**.
- **`ch39:4` says "12 backends"**; the Windows-only gate now covers **14** (adds GLIDE and GDI).
- **`ch24-canvas-ascii-backends.tex`** documents `ASCII` as a renderer identity; **`ASCII` was
  removed 2026-08-11** (`ea31cabc1`) in favour of `CNA::Graphics::AsciiPostProcessEffect` in
  `modules/graphics-ext/`.
- **`ch40:8-9`** says "Two adjustments apply project-wide" — the old
  `-fexceptions -sNO_DISABLE_EXCEPTION_CATCHING` pair, now a single `-fwasm-exceptions`.
- **`ch40:121`** *"Why even a successful build cannot be pixel-verified here"* — **now false.** Two
  Emscripten renderers are browser-run and pixel-checked, one of them in CI on every push.
- **`ch39:29`** *"Three Wine prefixes, never one"* — now **six** named prefixes plus throwaway ones.
- The book's own figure-regeneration kit has drifted: `tools/cna-screenshot-infra/README.md` cites
  `docs/software-backend.md`, `cmake/Tests/SoftwareTests.cmake`, `examples/common/PixelTestGame.hpp`
  — all moved (now `docs/software-renderer.md`,
  `modules/renderers/software/examples/CMakeLists.txt`,
  `modules/graphics/examples/common/PixelTestGame.hpp`). Only `examples/golden/` is still where the
  README says.

### 5.2 Proposed structure: Part VIII grows from 4 chapters to 7

The current shape has one chapter per *destination platform* plus a methodology chapter. That shape
cannot hold the material any more: the Windows chapter now has to carry fourteen renderers across
six Wine prefixes and three distinct translation runtimes, while Web has to carry five renderers at
four different evidence levels. Split by **mechanism**, not destination.

**Ch. A — The Cross-Platform Contract (new, ~14 pp).**
The chapter the book lacks and needs first, and it now has a real thesis rather than a survey:
**platform variation in CNA is expressed as CMake target selection, not preprocessor branching.**
Open with FACT 47 (GLIDE's unguarded `#include <windows.h>`, safe because the family is only
compiled when selected) and prove it with the hard numbers of FACT 41 — **4.7% of production files
carry any OS `#if`, a 38:1 ratio of SDL references to OS directives, 65% of the residual
directives confined to renderer native-handle glue** — plus the `MODULARIZATION_PLAN.md:311-314`
quote in which the project states outright that no platform layer exists and that SDL3 *is* the
abstraction. That is a far stronger and more transferable chapter than "here is a list of
`#ifdef`s," and it makes the residual 56 files genuinely interesting: they are exactly the places
where delegation is impossible — the browser main loop, Android NDK sensors, Emscripten socket
topology, native window handles for non-SDL GPU SDKs, `/proc/self/cmdline` (FACT 49), sysfs PCI IDs
(FACT 50). Then CNA's platform taxonomy (`CNA::Platform` × `CNA::DesktopOS`), the entry-point
abstraction and why Android forces it (FACT 45), the one runtime string-compare (FACT 48), and the
per-platform renderer-admissibility table from §2 with the explicit warning that admissible ≠
buildable.

*Addition 1 — a "seven modules with zero platform code" section.* Storage, media, audio, math,
gamer-services, devices-ext, graphics-ext. The storage case is the cleanest worked example in the
book: the entire per-platform save-location decision is one `SDL_GetPrefPath` call
(`StorageDevice.cpp:75`) with three unguarded POSIX-shaped fallbacks that simply never fire on
Windows, and `LocalGamerServicesStore.cpp:27-33` deliberately reuses that same root — **one SDL
call determines every writable location in CNA.** Pair it with FACT 54 (Windows-path rejection
implemented in portable C++ on POSIX) and FACT 55 (little-endian-only, one `static_assert`, zero
byteswaps) as the positive model.

**Ch. B — Windows I: Cross-Compiling from Linux (~14 pp).**
`mingw-w64.cmake`, the configure-time vendored-SDL auto-build keyed by target triple, the
`.sdl-prebuilt-<System>-<Proc>` cache, the MinGW static-runtime and DLL-staging helpers. Ends with
the **i686 wall** (FACT 16): `__int128` in sharp-runtime's `Int128`/`Decimal` is not available to
`i686-w64-mingw32-g++`, and the upstream decision not to hand-roll 128-bit arithmetic is permanent
— so GLIDE syntax-checks and its 39-export ABI probe runs under Wine, but the full 32-bit
executable will never link. A genuinely instructive "a platform you cannot reach, and why" section
that the current book has no equivalent of.

**Ch. C — Windows II: Wine, DXVK, and Proving a Translation Layer Engaged (~18 pp).**
The heart of the Windows story and the best engineering in the repo. Six prefixes and why each
exists; `CROSSCOMPILING_EMULATOR` making `ctest` transparently launch PE32+ binaries; the
**runtime-engagement gate** as a design pattern (grep the log for `DXVK:` / `:ddraw:` /
`vkd3d-proton - applicationVersion:`, exit 3 otherwise) — the single most transferable idea in the
whole cross-platform story. Then the per-renderer runtime table from §2. Then the
environment-specific workarounds that are *not* CNA bugs: DX8's `DXVK_FILTER_DEVICE_NAME=llvmpipe`
(RADV `VK_ERROR_SURFACE_LOST_KHR` on the second `Present()`), DX10 forced onto real `DISPLAY=:0`
because DXVK's `dxgi` EDID path crashes under Xvfb, Direct2D's canonical isolated-Xvfb runner and
fresh-prefix suite. Close with the two honest gaps: **Direct2D has no engagement gate at all**
(FACT 7), and MSVC/native Windows is two `workflow_dispatch` workflows the project itself records
as never validated — one of which (FACT 22) cannot even start at this SHA.

**Ch. D — Web I: Compiling C++23 to WebAssembly (~12 pp).**
`-fwasm-exceptions` and the `__cpp_exception` link failure that forced it (a real cross-repo
ABI-scope lesson worth the pages); `-sEXIT_RUNTIME` / `-sASYNCIFY` / `-sALLOW_MEMORY_GROWTH` /
`-sFORCE_FILESYSTEM` and where each is set; asset delivery via the two `--preload-file` sites;
single-threadedness by default and what it buys (no COOP/COEP); **and the undocumented fact that
web save data is volatile MEMFS** (FACT 31).

**Ch. E — Web II: The Main-Loop Problem (~12 pp, mostly new).**
The centrepiece of the new edition's web material and the strongest debugging narrative in the
repo. `emscripten_set_main_loop(…, simulateInfiniteLoop=1)` is a JS `throw 'unwind'`; under
`-fwasm-exceptions` the cleanup landing pad catches it; every stack-local `Game` was destructed
before frame 1, dangling `graphicsDeviceManager_`. Cover the false hypothesis first
(`GameServiceContainer` non-primary-base pointer adjustment), how it was ruled out with
ASan+UBSan+vptr and `-sSAFE_HEAP`, then the isolating spike, then the fix. Then the five
native-vs-web loop divergences (FACTS 29 and 58) — **all currently undocumented in CNA itself,
which makes the book their first record.**

**Ch. F — Web III: Five Renderers, Four Kinds of Evidence (~12 pp).**
`HTML_DOM` (Playwright + headless Chromium, six pages, pixel-checked, in CI on every push) /
`SVG_DOM` (same quality harness plus structural anti-spoofing, **no CI**) / `CANVAS` (`node` only,
`SDL_Init(SDL_INIT_VIDEO)` throws, 12-item manual checklist all unchecked) / `WEBGL1`+`WEBGL2`
(link cleanly, never entered a browser). Explain *why* the pixel check is 1×1 screenshot samples
rather than golden diffs — neither a DOM nor an SVG subtree can be read back in-page.

*Addition 2 — the Web networking topology belongs here (or at the end of Ch. D).* FACT 51: the web
port is not a recompile — fixed port 61191, no LAN discovery at all, clients rebuilt as
outbound-only hosts. Paired with FACT 31 (volatile MEMFS saves) and FACTS 29/58 (a different
accumulator, clock, and frame clamp), the honest chapter thesis is *"the same source, a materially
different runtime contract"* — which the README's "implemented and verified" framing currently
hides.

**Ch. G — Android and the Platforms Not Yet Reached (~14 pp).**
Android: the two build paths (`add_subdirectory(<cna-root>)` from the Gradle project's
`jni/CMakeLists.txt`; the standalone `--target CNA` compile-only verification), the pure-NDK sensor
bridge with **no JNI at all**, the deliberate testability split that lets the Android *math* compile
and unit-test on Linux, and the honest ceiling: emulator only, never a physical device, graphics
never attempted, no CI.

*Addition 3 — the `TitleContainer` gap.* FACT 52: the Android asset path is not merely fragile, it
is **unreachable from `ContentManager`**, which loads CWD-relative with no base-path prefix
(FACT 53). That is the concrete reason "Android graphics was never attempted" is more than a
scheduling accident, and it is the sharpest single finding in the Android chapter.

Then macOS: 3,842 lines of Objective-C++ behind a pure-C++ PIMPL, the `macos-14` workflow, and the
pivotal distinction (FACT 18) that `ctest -R '^Metal'` passes 207/207 **on Linux** because the
policy suites are deliberately host-portable — so a green run proves nothing about Apple hardware
unless the build was `METAL`. Then iOS: an enum value and a `FATAL_ERROR` that names it. Quote
`integration/lanes/metal.md:290` verbatim — *"Adapted macOS/physical Apple run | not run | no pass
claimed"* — as the model for how a project should write down what it has not done.

**Ch. H — Verification Methodology, Compared (rewrite of ch42, ~14 pp).**
Keep the comparative-gradient framing; replace the data. The (a)–(j) ladder from §1 as the book's
own vocabulary, applied to all seven platforms. Then the CI chapter the book does not currently
have: which workflow gates which platform on which branch, and — because the new edition should be
as honest as CNA's lane cards are — **that at this SHA `general-tests-ci.yml` and two of
`input-ci.yml`'s five legs fail at CMake configure because they still pass the retired `EASYGL`
selector (FACT 21), and the D3D11 leg cannot start because a script points at a pre-modularization
`src/` path (FACT 22).** A book that quotes CI as evidence has to check that the CI runs.

### 5.3 Two things to fix before writing

1. **Refresh `tools/cna-screenshot-infra/README.md`** — three of its five referenced CNA paths
   moved on 2026-08-10. Any figure regenerated from it will fail first.
2. **Decide the terminology migration up front.** 1,762 "backend" occurrences, eight chapter
   filenames, one Part title. Doing it as a mechanical pass *before* writing new Part VIII prose is
   far cheaper than doing it after, and Part VIII is the smallest fraction of it (51 of 1,762) —
   the cost lives in Part IV.

---

## Scope caveats

- No CNA build was run; every "builds"/"does not build" claim rests on committed evidence, gate
  logic, or recorded run output, never on observation.
- Renderer findings rest on an exhaustive directive grep plus detailed reads of the densest files,
  not a read of all 1,525 renderer files.
- The 5,983 SDL-symbol figure counts token occurrences (including enum constants, types and
  `SDL_PROP_*` keys), not distinct call sites — a magnitude indicator, not an API-call census.
- `modules/renderers/sokol/src/shaders/sokol_shaders.hpp` is machine-generated; its 8 `_MSC_VER`
  directives inflate the raw macro count without representing authored platform logic.
- FACT 52 (`TitleContainer` has no consumers) is a grep-negative over production code; a consumer
  reaching it through a name not grepped is conceivable but unlikely. **STRONG**, not
  VERIFIED-absolute.
