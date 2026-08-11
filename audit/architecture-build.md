# Audit report — CNA identity, architecture, module system, build system

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Cross-referenced sibling (read-only): sharp-runtime `f827a6c5349234d5ac938886788ed8eca8fe1c10`.
Read-only; no CNA build was run, no CNA file modified. Working trees untouched.

Confidence labels: **VERIFIED** = implementation seen *and* corroborated by a test/config/second
source · **STRONG** = implementation seen, single source · **PROBABLE** = inferred from consistent
evidence · **UNCERTAIN** = flagged, not settled.

---

# 1. FACTS

## 1.1 Project identity

**F1 — Self-description. VERIFIED.**
`README.md:5`: *"CNA is a C++ reimplementation of the XNA 4.0 programming model, built on SDL3 and a pluggable graphics renderer layer."*
`README.md:7`: *"It is a framework/runtime and abstraction layer—not a game—designed to preserve XNA-style APIs (`Microsoft::Xna::Framework`) while using modern C++ internals."*
`CLAUDE.md:5-7` is the same sentence with `C++23` made explicit.
`README.md:9`: *"CNA demonstrates engine-level C++ architecture, graphics abstraction design, and renderer-oriented systems engineering."*
Note both root docs now say **renderer**, never "backend" (see §5).

**F2 — The acronym "CNA" is never expanded anywhere in the repository. VERIFIED (negative).**
Searches for `stands for` / `acronym` across all `*.md` return nothing; `README.md:1` is simply
`# CNA`. The book must treat it as an opaque project name and **must not invent an expansion**.

**F3 — FNA, not the Microsoft assembly, is the behavioral authority. VERIFIED.**
`CLAUDE.md:11-17`: the reference is the local FNA tree at `/rv/data/library/github.com/FNA-XNA/FNA`;
*"Do not treat old CNA code or AI-generated stubs as authoritative if they conflict with the FNA
reference API."*
Genuine XNA 4.0 is the tie-breaker: `README.md:58` describes differential testing against a running
`FNA.dll` (`tools/fna-reference/`), with disputes settled against real XNA 4.0 on a Windows 7 VM.
One exception: `README.md:300-306` — `AvatarAnimation`/`AvatarDescription`/`AvatarRenderer` were
ported from a **decompiled real Microsoft XNA 4.0 assembly**, because FNA never implemented Avatar.

**F4 — Compatibility goal: source-*shaped*, not source-compatible, not drop-in. VERIFIED.**
*(This is the single most important framing fact for the book.)*
`docs/migration-guide.md:11-13`: *"CNA is a C++23 reimplementation of the XNA 4.0 programming model —
it preserves XNA's class names, method signatures, and namespaces (`Microsoft::Xna::Framework::*`),
but it is not a C#/.NET runtime and cannot run your existing C# assembly. Porting a game means
translating the C# source to C++, not recompiling or bridging it."*

It is not even statement-level source-compatible, because C# properties have no C++ equivalent.
`docs/migration-guide.md:17-35` calls this *"The single biggest mechanical difference"*: every
property read becomes `getXProperty()`, every write `setXProperty(v)`. Example at `:29-31`:

```cpp
spriteBatch->getGraphicsDeviceProperty()->setBlendStateProperty(BlendState::AlphaBlend);
```

Below the property layer, names are exact — `CLAUDE.md:55-58`: *"Class names, struct names, enum
names, method names, operator names, and constant/static member names must match the XNA/FNA API
exactly. Do not rename API members to make them more C++-like."*

> **Book formulation:** namespace-, type- and member-name-identical to XNA 4.0, but a
> hand-translation target rather than a compatibility layer — with a mandatory mechanical property
> rewrite.

**F5 — Stated coverage numbers. VERIFIED as dated project claims (not re-measured here).**
`README.md:26`: 227 of 245 public FNA types present = **92.7%** (computed 2026-07-11); 100% for
`Graphics`/`Audio`/`Input`(+`Touch`)/`Storage`.
`README.md:25`: `Graphics` milestone qualified at **~90%**, test-execution-verified.
`README.md:26` pre-empts the apparent conflict between the two figures (*"The two numbers measuring
different things is expected, not a typo"*) — raw presence count vs. bug-weighted quality gate.
`README.md:27` names the two biggest port-blocking gaps: the `.xnb` pipeline and compiled `.fx`
bytecode (`Effect(GraphicsDevice&, byte[])`), the latter blocking 23 of 86 official samples.
**The `.xnb` half of that claim is false — see X1.**

**F6 — C++ standard: C++23 declared and required, but it is a toolchain floor, not a feature
dependency. VERIFIED.**
`CMakeLists.txt:1-7`:

```cmake
cmake_minimum_required(VERSION 3.20)
project(CNA LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

This is the only project-wide setting; no module or renderer overrides it, and no CNA target calls
`target_compile_features(... cxx_std_NN)`. The only other occurrence is the standalone tool at
`tools/media/arithmetic32bit/CMakeLists.txt:25-26` (also 23). Toolchain floor stated at
`README.md:326` ("GCC 12+ or Clang 15+") and `programs.md:44`.

**Exhaustive census over `modules/**/*.{hpp,cpp}` — every headline C++23 feature returns ZERO:**
`std::expected`, `import std`, `std::print`/`std::println`, `std::format`, `std::to_underlying`,
`std::byteswap`, `std::unreachable`, `std::mdspan`, `std::flat_map`, `std::generator`,
`std::stacktrace`, `std::move_only_function`, `std::out_ptr`/`inout_ptr`, `std::forward_like`,
`std::ranges::to`, `zip_view`, deducing `this`, `if consteval`, `[[assume]]`, static `operator()`,
`#elifdef`, multidimensional `operator[]`. (3391 apparent `std::print` hits are all `std::printf`,
e.g. `modules/renderers/html-dom/examples/htmldom_memory_test.cpp:96`.)

**Nor does CNA use C++20's headline features.** An anchored-regex re-check established that all 77
`concept` and 443 `requires` hits are **English prose inside comments** — CNA uses **zero concepts
and zero `requires`-clauses**. Also zero `operator<=>`, `std::ranges`/`std::views`, coroutines,
`char8_t`. The only genuine post-C++17 constructs are `constinit` (4, all in
`modules/math/src/Vector2.cpp:88-91`), `std::bit_cast` (19), and `std::span` (14 — all in Skia
example/spike TUs; only 2 `#include <span>` exist tree-wide).

What *is* used is C++17-shaped and dense: `constexpr` 5474, `[[nodiscard]]` 5274, `std::optional`
400, `std::string_view` 106.

> **Book guidance:** say *"compiled as C++23; written in a disciplined C++17/20 idiom."* Writing
> "CNA uses C++23 features such as `std::expected`" or "CNA uses concepts" would be **false**.

**F7 — Namespace map: five roots. VERIFIED.**
Census of `namespace` declarations across `modules/*/include` + `modules/renderers/*/include` (81
distinct declarations, fully enumerated), plus the sibling for `SharpRuntime::`.

**Root 1 — `Microsoft::` (the XNA public surface, hand-preserved names):**

| Namespace | Decls | Representative `path:line` |
|---|---:|---|
| `Microsoft::Xna::Framework` | 48 | `modules/audio/include/Microsoft/Xna/Framework/FrameworkDispatcher.hpp:14` |
| `…::Graphics` | 118 | `modules/gamer-services/include/Microsoft/Xna/Framework/GamerServices/Guide.hpp:15` |
| `…::Graphics::PackedVector` | 20 | `modules/graphics/include/Microsoft/Xna/Framework/Graphics/PackedVector/Bgra4444.hpp:8` |
| `…::Audio` | 22 | `modules/audio/include/Microsoft/Xna/Framework/Audio/InstancePlayLimitException.hpp:9` |
| `…::Input` | 20 | `modules/input/include/Microsoft/Xna/Framework/Input/KeyboardState.hpp:13` |
| `…::Input::Touch` | 7 | `modules/input/include/Microsoft/Xna/Framework/Input/Touch/GestureType.hpp:6` |
| `…::Media` | 24 | `modules/media/include/Microsoft/Xna/Framework/Media/VisualizationData.hpp:11` |
| `…::Content` | 10 | `modules/content/include/Microsoft/Xna/Framework/Content/ContentLoadException.hpp:7` |
| `…::Storage` | 3 | `modules/storage/include/Microsoft/Xna/Framework/Storage/StorageDeviceNotConnectedException.hpp:7` |
| `…::GamerServices` | 57 | `modules/gamer-services/include/Microsoft/Xna/Framework/GamerServices/FriendGamer.hpp:7` |
| `…::Net` | 25 | `modules/net/include/Microsoft/Xna/Framework/Net/AvailableNetworkSession.hpp:10` |
| **`…::Design`** | **0 — ABSENT** | verified negative |
| **`…::Content::Pipeline`** | **0 — ABSENT** | verified negative |
| `Microsoft::Devices` | 1 | `modules/devices/include/Microsoft/Devices/VibrateController.hpp:13` |
| `Microsoft::Devices::Sensors` | 17 | `modules/devices/include/Microsoft/Devices/Sensors/CompassReading.hpp:13` |
| `Microsoft::Devices::Sensors::Detail` | 13 | — |
| `Microsoft::Devices::Detail` | 4 | — |

`Microsoft::Devices` is a **separate root from `Microsoft::Xna`**, exactly as in the real Windows
Phone 7 assemblies.

**Root 2 — `CNA::` (project-owned: extensions, internals, renderers):**

| Namespace | Decls | Representative `path:line` | Role |
|---|---:|---|---|
| `CNA` | 10 | `modules/core/include/CNA/DesktopOS.hpp:7` | helpers, logger, enums, `CNAException` |
| `CNA::Internal` | 5 | `modules/content/include/CNA/Internal/CnjEnvelope.hpp:9` | internal contracts |
| `CNA::Internal::Renderers` | 17 | `modules/graphics/include/CNA/Internal/Renderers/Common/NoOp3DResources.hpp:8` | renderer interface layer |
| `CNA::Internal::Renderers::<Family>` | 1–31 each | Skia 31, Metal 25, DirectX9 16, Glide 14, DirectX12 14, DirectX11 10, Magnum 9, Fna3d 6, SvgDom 5, OpenGL1 5, HtmlDom 5 … | one per renderer family |
| `CNA::Graphics` | 12 | `modules/graphics-ext/include/CNA/Graphics/PbrMaterial.hpp:10` | the `CNA_CNAEXT`-gated engine layer |
| `CNA::Devices` | 17 | `modules/devices-ext/include/CNA/Devices/Clipboard.hpp:8` | `CNA_DEVICES`-gated extensions |
| `CNA::Devices::Detail` | 8 | — | |
| `CNA::Input` | 27 | `modules/input/include/CNA/Input/HapticDevice.hpp:17` | raw joystick/sensors/power/haptics |
| `CNA::Internal::Xnb` | 22 | `modules/content/include/CNA/Internal/Xnb/SongContentTypeReader.hpp:12` | **the `.xnb` reader — see X1** |
| `CNA::Internal::Media` | 14 | `modules/media/include/CNA/Internal/Media/MediaLibraryPaths.hpp:6` | |
| `CNA::Internal::Input` | 11 | `modules/input/include/CNA/Internal/Input/SdlGamepadBackend.hpp:14` | |
| `CNA::Internal::Net` | 6 | `modules/net/include/CNA/Internal/Net/ENetHostHandle.hpp:22` | |
| `CNA::Internal::Graphics` | 6 | `modules/graphics/include/CNA/Internal/Graphics/ImageData.hpp:5` | |
| `CNA::Internal::Graphics::Ascii` | — | — | ASCII quantizer/font-atlas, ex-renderer |
| `CNA::Internal::Audio` | 5 | `modules/audio/include/CNA/Internal/Audio/WavWrapper.hpp:7` | |
| `CNA::Internal::GltfImport` | 1 | `modules/content/include/CNA/Internal/GltfImport/GltfImportCore.hpp:18` | |
| `CNA::Internal::GamerServices` | 1 | `modules/gamer-services/include/CNA/Internal/GamerServices/LocalGamerServicesStore.hpp:12` | |

**Root 3 — `System::`, owned entirely by sharp-runtime.** CNA declares `namespace System` in exactly
**four places, all forward declarations**:
`modules/graphics/include/Microsoft/Xna/Framework/Graphics/Texture2D.hpp:17`
(`namespace System::IO { class Stream; }`), `TextureCube.hpp:19` (same),
`ResourceCreatedEventArgs.hpp:6` and `ResourceDestroyedEventArgs.hpp:8`
(`namespace System { class Object; }`). Everything else arrives by include.
The sibling's tree: `System` 222 decls, `System::Xml` 67, `System::Threading` 57, `System::IO` 57,
`System::Globalization` 36, `System::Collections::Generic` 36, `System::Net` 28, `System::Text` 21,
`System::Runtime::CompilerServices` 19, `System::ComponentModel` 17, `System::Numerics` 14.
CNA's most-included: `System/NotSupportedException.hpp` 113×, `System/ArgumentOutOfRangeException.hpp`
101×, `System/TimeSpan.hpp` 63×, `System/Object.hpp` 58×, `System/EventArgs.hpp` 57×,
`System/InvalidOperationException.hpp` 52×, `System/ObjectDisposedException.hpp` 50×,
`System/IDisposable.hpp` 50×, `System/ArgumentException.hpp` 46×, `System/IO/MemoryStream.hpp` 43×,
`System/ArgumentNullException.hpp` 38×, `System/EventHandler.hpp` 32×, `System/Exception.hpp` 19×.

**Root 4 — `SharpRuntime::`, a *fifth, distinct* root.** Declared at
`sharp-runtime/modules/core/include/SharpRuntime/SharpRuntimeHelper.hpp:34`. It holds the
C#-primitive type aliases: `sbytecs`/`bytecs`/`intcs`/`uintcs` (`:40,:46,:69,:75`) and the
.NET-cased `SByte`/`Byte`/`Int32`/`UInt32` (`:192-202`). `CLAUDE.md:90-107` **mandates** their use
over raw C++ types across the XNA surface, with the mapping table at `:94-104`
(`byte`→`bytecs`, `float`→`Single`, `string`→`String`→`std::string`, `char`→`charcs`→`char16_t`, …).
Only two headers are ever included from it: `SharpRuntime/SharpRuntimeHelper.hpp` (66×) and
`SharpRuntime/Prop.hpp` (9×).

**Root 5 — one reopened third-party namespace:** `Magnum::Platform` (Magnum renderer only).

**Structural rule (VERIFIED, `CLAUDE.md:193-199`):** each module's `include/` root reproduces the
namespace path verbatim, so include spelling is stable public API and survived the physical move
unchanged:

```
modules/graphics/include/Microsoft/Xna/Framework/Graphics/Texture2D.hpp
modules/graphics/include/CNA/Internal/Renderers/Common/IGraphicsRenderer.hpp
```

Note `IGraphicsRenderer.hpp` lives under the **graphics** module — there is no `renderers/common`
module. `README.md:134-141`'s box diagram writes namespace-relative paths, not repo paths (see X8).

**F8 — `CNAEXT` marker macro, exact definition. VERIFIED.**
`modules/core/include/CNA/CNAHelper.hpp` is 28 lines total. `:22-26`:

```cpp
#ifdef CNA_STRICT_XNA_API
#define CNAEXT [[deprecated("CNAEXT: not part of the XNA 4.0 API surface")]]
#else
#define CNAEXT
#endif
```

The gating macro is **`CNA_STRICT_XNA_API`, not `CNA_CNAEXT`** — the two are unrelated (F10). Doc
comment `:9-20`: *"In a normal build the macro expands to nothing; its purpose is documentation
only."*
Mandate, `CLAUDE.md:30-33`: anything not in XNA 4.0 that lives inside `Microsoft::Xna` **MUST** be
wrapped with `CNAEXT`. `CLAUDE.md:48-49`: XNA types must never move into `CNA::`.
The include guard is `WINDOWSPHONESPEEDYBLUPI_CNAHELPER_HPP` (`:5-6`) with an authorship stamp
"Created by robertvokac on 5/24/26" (`:1-3`) — a concrete fossil of the project's Windows-Phone-game
origin, matching `Microsoft::Devices`'s WP7 lineage. Worth one footnote.

**F9 — `CNAEXT` usage and the `*EXT` suffix convention. VERIFIED.**
`grep -rn "CNAEXT" modules/` → **2119** lines; restricted to `.hpp`/`.cpp` → 2091. Token split: bare
`CNAEXT` **2029**, `CNA_CNAEXT` **59**. Lines where `CNAEXT` *begins* a declaration
(`^\s*CNAEXT\s`): **1102** — the real count of tagged declarations. Lines where it appears in a
comment: **909**.

By module: graphics 400, input 398, gamer-services 98, devices 92, media 87, graphics-ext 86,
renderers/sdl-gpu 82, renderers/sokol 72, renderers/wicked 66, content 65, renderers/directx9 64,
renderers/diligent 56, net 56, renderers/directx12 55, audio 50, renderers/fna3d 41, runtime 37,
renderers/directx11 33, math 23, storage 5, core 4, devices-ext 1. Distinct files touched: graphics
77, input 53, graphics-ext 29, renderers/directx9 28, gamer-services 27, devices 25, media 22.

The companion naming convention is named at `CNAEXT.md:28` ("the `CNAEXT` macro + `*EXT`
method/type suffix") and explained for porters at `docs/migration-guide.md:46-49`: *"anything with
that suffix is safe to ignore unless you specifically want a CNA extension your original XNA code
never used."* Top `*EXT` identifiers: `TextInputEXT` 245, `PointListEXT` 159, `SkinnedModelEXT` 158,
`GetDeviceEXT` 146, `SdlGpuFailurePointEXT` 123, `GetResourceStatsEXT` 107,
`RequireFaithfulDeclarationEXT` 73, `TryUploadPixelShaderConstantEXT` 69, `KeyModifiersEXT` 65,
`MipGenerationCountEXT` 64, `ColorSrgbEXT` 62, `HapticEffectTypeEXT` 56, `HapticFeatureEXT` 55,
`PowerStateEXT` 53, `Bc7EXT` 51, `ByteEXT` 48, `AnimationClipEXT` 44, `ColorBgraEXT` 43,
`AvatarAppearanceEXT` 43, `SensorTypeEXT` 37.

**Caveat (STRONG):** the suffix is **not universal**. `CNAEXT.md:32` lists always-compiled marker
examples carrying no suffix — `PbrEffect`, `SkinnedPbrEffect`, `ShaderEffect`,
`VertexPositionNormalTangentTexture`, `GraphicsDevice::DebugSimulateContextLoss()`. The reliable
signal is the macro; `docs/migration-guide.md:46` hedges precisely with "and/or". Two grep false
positives to avoid: `NEXT` (49) and `CNA_CNAEXT` (59).

Obligations are enumerated at `CHECKLIST.md:67-73` and include non-obvious ones: C++ iterator
support (`begin`/`end`/`size_type`) must be `CNAEXT` (`:69`); `GetTypeName()` on every concrete
`System::Object` subclass must be `CNAEXT` (`:70`,`:73`); `#include "CNA/CNAHelper.hpp"` must be
present wherever the macro is used (`:12`); C# `internal const` re-exposed as
`CNAEXT public static constexpr` (`:109`, e.g. `GamePad::LeftDeadZone`, `TouchPanel::MAX_TOUCHES`)
since C++ has no assembly-scoped visibility.

**F10 — `CNAEXT` (marker) vs `CNA_CNAEXT` (engine layer) are two different things, and the project
says so. VERIFIED.**
`CNAEXT.md:21-32` opens with *"## 1. Two meanings of 'CNAEXT' — read this first … There are **two
unrelated things** in this codebase that share the name."* Its table at `:26-32`:

| | **CNAEXT marker convention** | **`CNA_CNAEXT` engine layer** |
|---|---|---|
| What | `CNAEXT` macro + `*EXT` suffix | CMake option gating a whole `CNA::Graphics` namespace |
| Compiled? | **Always** — documentation/lint marker (optionally `[[deprecated]]` under the strict check) | **Opt-in** — everything `#ifdef CNA_CNAEXT` |
| Lives in | `Microsoft::Xna::Framework::Graphics` | `CNA::Graphics` |
| Granularity | Individual members / effects | Heavy self-contained subsystems |
| Shipped examples | `PbrEffect`, `SkinnedPbrEffect`, `MorphTargetDataEXT`, `SkinnedModelEXT`, `ShaderEffect`, `VertexPositionNormalTangentTexture`, `GraphicsDevice::DebugSimulateContextLoss()` | `RenderPipelineSettings`, `PbrMaterial`, `TonemappingMode`/`RenderQuality`/`ShadowQuality` |

The dividing rule (`CNAEXT.md:34-46`): per-draw/per-object shading that fits an XNA `Effect`, vertex
format or device member ships always-compiled; scene/frame-level orchestration (HDR chain,
post-process, shadows, IBL, skybox, compute) goes behind the option.

`CNA_CNAEXT` is a real CMake option, `CMakeLists.txt:60`, default **OFF**, propagated at
`modules/CMakeLists.txt:66` as `$<$<BOOL:${CNA_CNAEXT}>:CNA_CNAEXT>`. It wraps every file in
`modules/graphics-ext/` — e.g. `include/CNA/Graphics/RenderPipelineSettings.hpp:4`/`:102`,
`AsciiPostProcessEffect.hpp:4`/`:134`, `CRTEffect.hpp:4`/`:102`, `DepthEffect.hpp:4`/`:88`,
`src/PbrMaterial.cpp:5`/`:59`.

**F11 — The marker is mechanically enforced, positively and negatively. VERIFIED.**
`CNA_STRICT_XNA_API` is **not** a CMake `option()`; it is a `target_compile_definitions` on two
harness targets in `cmake/Harnesses.cmake` (not in `CMakeLists.txt`):

- `:179-186` — `cna_strict_xna_api_check` from `tools/devices/StrictXnaApiSurfaceCheck.cpp`, with
  `CNA_STRICT_XNA_API` (`:183`) + `-Werror=deprecated-declarations` (`:184`); ctest
  `StrictXnaApiSurfaceCheck_Compile_Run` (`:214`). **Must compile.**
- `:220-236` — `cna_strict_xna_api_leak_check` (`EXCLUDE_FROM_ALL`) from
  `StrictXnaApiSurfaceLeakCheck.cpp`, same defs; ctest
  `StrictXnaApiSurfaceLeakCheck_MustFailToCompile` with `WILL_FAIL TRUE` (`:235`). **Must fail to
  compile.** The deliberate-failure test guards against a future regression silently neutering the
  marker — a genuinely elegant construction worth describing.

Two scope bounds: the check is gated on `CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang"` (`:178`), so it
**does not run under MSVC**; and `:170-172` says it fails only if the checked file calls a
`CNAEXT`-tagged **`Microsoft::Devices`/`Sensors`** member — its practical reach is what the two
`tools/devices/*.cpp` files reference, not a whole-API sweep. CI runs it:
`.github/workflows/devices-tests.yml:156`.

**F12 — Exception model: a three-tier hierarchy rooted in sharp-runtime. VERIFIED.**

*Tier 1 — sharp-runtime `System::`.* `sharp-runtime/modules/core/include/System/Exception.hpp:32`:
`class Exception : public std::exception`. Carries `message_`, `innerException_`
(`std::exception_ptr`), `data_`, `source_`, `helpLink_`, `hResult_` defaulted to `0x80131500`
(`COR_E_EXCEPTION`) — a faithful `System.Exception` port. Documented omissions (`:24-30`):
`GetBaseException()` (would slice — no virtual clone), `ToString()`, `TargetSite`, `GetObjectData`,
all *"out of scope per the project's no-reflection deviation."* `ArgumentNullException` is at
`sharp-runtime/modules/core/include/System/ArgumentNullException.hpp:19`, deriving
`ArgumentException`.

*Tier 2 — XNA-native exceptions, defined in CNA, in their correct XNA namespaces:*

| Type | `path:line` | Base |
|---|---|---|
| `NoMicrophoneConnectedException` | `modules/audio/include/Microsoft/Xna/Framework/Audio/NoMicrophoneConnectedException.hpp:12` | `System::Exception` |
| `InstancePlayLimitException` | `…/Audio/InstancePlayLimitException.hpp:12` | `System::Exception` |
| `NoAudioHardwareException` | `…/Audio/NoAudioHardwareException.hpp:12` | `System::Exception` |
| `ContentLoadException` | `modules/content/include/Microsoft/Xna/Framework/Content/ContentLoadException.hpp:10` | **`std::runtime_error`** |
| `StorageDeviceNotConnectedException` | `modules/storage/include/…/Storage/StorageDeviceNotConnectedException.hpp:10` | — |
| `NoSuitableGraphicsDeviceException` | `modules/graphics/include/…/Graphics/NoSuitableGraphicsDeviceException.hpp:10` | **`std::runtime_error`** |
| `DeviceLostException` | `…/Graphics/DeviceLostException.hpp:10` | **`std::runtime_error`** |
| `DeviceNotResetException` | `…/Graphics/DeviceNotResetException.hpp:10` | **`std::runtime_error`** |
| `NetworkException` | `modules/gamer-services/include/…/GamerServices/NetworkException.hpp:15` | `System::Exception` |
| `NetworkNotAvailableException` | `…/GamerServices/NetworkNotAvailableException.hpp:15` | `NetworkException` |
| `NetworkSessionJoinException` | `modules/net/include/…/Net/NetworkSessionJoinException.hpp:15` | `GamerServices::NetworkException` |
| `GamerPrivilegeException`, `GamerServicesNotAvailableException`, `GameUpdateRequiredException`, `GuideAlreadyVisibleException` | `…/GamerServices/*.hpp:15` | `System::Exception` |
| `SensorFailedException` | `modules/devices/include/Microsoft/Devices/Sensors/SensorFailedException.hpp:14` | `System::Exception` |
| `AccelerometerFailedException` | `…/Sensors/AccelerometerFailedException.hpp:12` | `SensorFailedException` |

*Tier 3 — CNA's own root:* `modules/core/include/CNA/CNAException.hpp:15` —
`class CNAException : public System::Exception`. Barely used in practice. Internal-only:
`CNA::Internal::JsonParseException` (`modules/content/include/CNA/Internal/Json.hpp:113`,
`: public std::runtime_error`), `HeadlessValidationException`
(`modules/renderers/headless/include/CNA/Internal/Renderers/Headless/HeadlessRenderer.hpp:42`, same
base).

**F13 — What is actually thrown, and the layer split. VERIFIED.**
*(Best architecture insight of the audit.)*
Whole-tree throw census (`modules/`, incl. tests/examples): `std::runtime_error` **1972**,
`std::invalid_argument` 259, `System::ArgumentOutOfRangeException` 177,
`System::NotSupportedException` 172, `std::out_of_range` 171, `ContentLoadException` 150,
`System::InvalidOperationException` 75, `System::ObjectDisposedException` 52,
`System::ArgumentException` 45, `System::ArgumentNullException` 30, `std::logic_error` 23,
`JsonParseException` 22, `SensorFailedException` 21, `System::FormatException` 10,
`System::NotImplementedException` 6, `System::IO::FileNotFoundException` 5.

Split by layer, the convention becomes clear:

| | Renderer layer (`modules/renderers/`) | Public XNA API layer (all other modules) |
|---|---:|---:|
| `std::runtime_error` | 1755 | 217 |
| `std::invalid_argument` | 125 | 133 |
| `std::out_of_range` | 66 | 104 |
| `System::NotSupportedException` | 102 | 70 |
| `System::ArgumentOutOfRangeException` | 113 | 64 |
| `System::InvalidOperationException` | 15 | 60 |
| **`System::ObjectDisposedException`** | **0** | **52** |
| `System::ArgumentException` | — | 44 |
| `System::ArgumentNullException` | — | 27 |

> **Book formulation:** the `System::*` .NET-shaped exceptions are the **XNA-facing contract** — an
> FNA/XNA port target sees `ArgumentOutOfRangeException`/`ObjectDisposedException` exactly where the
> C# original threw them. The ~42 renderer implementations, which have no XNA counterpart, throw
> plain `std::runtime_error` for "this renderer cannot do that." Every one of the 52
> `ObjectDisposedException` throws is in the public API layer; none in a renderer.

`CHECKLIST.md:148` documents one acknowledged inconsistency: indexer out-of-range type is *"a
genuinely mixed precedent, not resolved consistently everywhere"* —
`BoundingBox.cpp`/`VertexBuffer.cpp`/`NetworkSessionProperties.cpp` throw
`System::ArgumentOutOfRangeException`, `Input::Touch::TouchCollection.cpp` throws
`std::out_of_range`.

**F14 — Exceptions cross the renderer boundary by design. VERIFIED.**
`IGraphicsRenderer`'s *default* virtuals throw. Sites in
`modules/graphics/include/CNA/Internal/Renderers/Common/IGraphicsRenderer.hpp`:
`:157` `throw std::runtime_error("SetData32 not supported by this renderer");`;
`:1422` `throw std::runtime_error("ReadBackbuffer: not implemented in this renderer");` (comment
`:1419`: *"Default implementation throws — override in renderers that support readback"*); same
shape at `:776`, `:1299`, `:1784`, `:1925`; `:1647` "renderers throw on first 3D usage";
`:1712`/`:1758` a renderer that cannot express a bound vertex/state combination *"must throw before
native submission rather than render from"* a wrong layout. `<stdexcept>` is included directly by
the interface header (`:22`). This makes **"throw loudly rather than silently approximate"**
load-bearing architectural policy — the mechanism behind every `README.md` phrase like *"refuse
loudly instead of approximating"* (`:35`, `:38`, `:246`) and behind `README.md:28`'s *"2D-only by
design (3D calls throw)"*.
`CMakeLists.txt:29-33` states the codebase *"relies on exceptions pervasively (System::Exception
hierarchy, EXPECT_THROW tests, etc.)"*.

**F15 — No `noexcept` policy. STRONG.**
574 `noexcept` occurrences in `modules/`, almost entirely move ctors/assignments
(`Texture2D.hpp:99-100`, `docs/graphics-resource-lifetime.md:125-126`,
`docs/input-public-api-frozen.md:258`). `IGraphicsRenderer.hpp` has **3** in ~2080 lines. No policy
statement exists in `CLAUDE.md`, `CHECKLIST.md` or `docs/*.md`. The one place the
implicit-`noexcept` rule *is* reasoned about is destructor safety — `CHECKLIST.md:144` explains that
replicating FNA's throw-on-second-`Dispose()` would mean throwing from a destructor, *"which is
undefined behavior in C++ (destructors are implicitly `noexcept`)"*, so `VideoPlayer::Dispose()` is
idempotent instead. `sharp-runtime/.../System/IDisposable.hpp:19` likewise requires that
"Dispose() does not generally throw exceptions."

**F16 — Emscripten uses the modern Wasm exception-handling proposal. VERIFIED.**
`CMakeLists.txt:50-53`: `add_compile_options(-fwasm-exceptions)` /
`add_link_options(-fwasm-exceptions)` under `EMSCRIPTEN`. Rationale at `:35-49`: the sibling
easy-gl→meta-gl chain sets `-fwasm-exceptions` in its own directory scope; CNA's old legacy
`-fexceptions` at top level produced `wasm-ld: undefined symbol: __cpp_exception`.
`-sNO_DISABLE_EXCEPTION_CATCHING` was dropped as having no Wasm-EH equivalent.

**F17 — Ownership: `unique_ptr`-dominant, with a principled `shared_ptr` exception for textures.
VERIFIED.** *(Second-best insight of the audit.)*
Raw counts over `modules/**/*.{hpp,cpp}`: `std::unique_ptr` **3490**, `std::make_unique` **3026**,
`std::shared_ptr` 541, `std::make_shared` 158, `std::weak_ptr` 42, `Dispose()` 974, `IDisposable`
127. `make_unique` outnumbers `make_shared` ~19:1.

But the split is **systematic, not incidental**:

| Class | Renderer handle | `path:line` |
|---|---|---|
| `VertexBuffer` | `std::unique_ptr<IVertexBufferRenderer>` | `modules/graphics/include/…/Graphics/VertexBuffer.hpp:454` |
| `IndexBuffer` | `std::unique_ptr<IIndexBufferRenderer>` | `…/Graphics/IndexBuffer.hpp:227` |
| `SpriteBatch` | `std::unique_ptr<ISpriteBatchRenderer>` | `…/Graphics/SpriteBatch.hpp:56` (+ `CNAEXT` ctor taking one, `:89`) |
| **`Texture2D`** | **`std::shared_ptr<ITextureRenderer>`** | `…/Graphics/Texture2D.hpp:588` |
| **`Texture3D`** | **`std::shared_ptr<ITexture3DRenderer>`** | `…/Graphics/Texture3D.hpp:212` |
| **`TextureCube`** | **`std::shared_ptr<ITextureCubeRenderer>`** | `…/Graphics/TextureCube.hpp:193` (+ 6 shared CPU face buffers, `:199`) |

The reason is visible at `Texture2D.hpp:96-100` — copy ctor, copy assign, move ctor and move assign
are all `= default`. **`Texture2D` is copyable by value**, because C# reference-type semantics mean
game code copies textures around freely; a `unique_ptr` member would forbid that. `Texture2D` also
holds `std::shared_ptr<std::vector<uint8_t>> cpuPixels_` (`:591`) and
`std::shared_ptr<std::vector<std::vector<uint8_t>>> extraMipLevels_` (`:592`), and exposes all three
views: `CNAEXT ITextureRenderer& GetRenderer() const` (`:475`),
`CNAEXT std::weak_ptr<ITextureRenderer> GetRendererWeak() const` (`:483`),
`[[nodiscard]] ITextureRenderer* GetRendererRaw() const` (`:574`).

> **Rule for the book:** buffers and the batcher are uniquely owned; textures are shared — because
> textures are what XNA code copies by value. The XNA API shape dictates the C++ ownership model,
> not the other way round.

The device→renderer seam is unique-owned: `IGraphicsRenderer.hpp:2078`
`std::unique_ptr<IGraphicsRenderer> CreateGraphicsRenderer(const GraphicsRendererCreateArgs& args);`,
called at `modules/graphics/src/Xna/GraphicsDevice.cpp:2419` (`renderer_ = CreateGraphicsRenderer(args);`),
stored at `GraphicsDevice.hpp:1107`.

**F18 — CNA mirrors XNA's `IDisposable` pattern on a sharp-runtime base. VERIFIED.**
`CLAUDE.md:152-165` mandates the shape (`Dispose()` override + `Dispose(bool disposing)`). Base:
`sharp-runtime/modules/core/include/System/IDisposable.hpp:23`, pure-virtual `Dispose()` with a
virtual destructor and an idempotency requirement (`:16-19`). CNA's graphics root implements it —
`modules/graphics/include/Microsoft/Xna/Framework/Graphics/GraphicsResource.hpp:18`:
`class GraphicsResource : public System::Object, public System::IDisposable`, with
`getIsDisposedProperty()` (`:31`), `void Dispose() override` (`:58`),
`virtual void Dispose(bool disposing)` (`:85`, doc: *"True when called from Dispose(); false when
called from the finalizer"*), `bool isDisposed_ = false` (`:90`). Chain:
`Texture2D : Texture : GraphicsResource` (`Texture2D.hpp:51`, `Texture.hpp:11`).

Documented lifetime model, `docs/graphics-resource-lifetime.md`: `:14-15` `GraphicsResource` itself
holds no renderer pointer — the derived class declares `renderer_`; `:21-31` GPU handles are
released on **`Dispose()`**, not destruction; `:33-35` the destructor calls `Dispose(false)`, so a
forgotten `Dispose()` still frees the renderer but does **not** fire `Disposing` or raise
`ResourceDestroyed`; `:50-56` `GraphicsDevice` keeps a **non-owning**
`std::vector<GraphicsResource*> resources_`, registered in the ctor via `AddResourceReference(this)`
and removed in `Dispose(bool)` via swap-and-pop; `:60-69` device disposal moves-and-clears the list
before iterating, then `destroyNativeResources()`.

**F19 — Events. VERIFIED.** `CLAUDE.md:111-129`: C# events map to sharp-runtime's
`System::EventHandler<TEventArgs>`, e.g. `System::EventHandler<ExitingEventArgs> Exiting;`,
subscribed with `operator+=`, fired with `Raise()`/`Invoke()`. *"This is the project-wide pattern; do
not invent a different event mechanism."* 32 includes of `System/EventHandler.hpp`.

**F20 — Visibility and interface mapping. VERIFIED.** `CLAUDE.md:169-179`: C# `internal` maps to
`private`/`protected`/a detail namespace/omission — explicitly **not** to public C++.
`CLAUDE.md:133-148`: C# interfaces become abstract base classes; deviations are documented *"in the
PR description or task report — **not in source comments**."*

## 1.2 Physical module architecture

**F21 — The repository is a module monorepo; the legacy global trees cannot return. VERIFIED.**
`modules/CMakeLists.txt:186-193` raises a configure-time `FATAL_ERROR` if
`${CMAKE_SOURCE_DIR}/src` or `/include` reappears. `git ls-tree -r --name-only HEAD | grep -E '^(src|include)/'`
returns nothing. `docs/physical-modules.md:3-14` is the authoritative current-state description:
*"Since the Phase-3 physical modularization (2026-08-10 … promoted to `develop` … as `3ecbbce72`),
the repository is a module-oriented monorepo … Consumer include spelling is unchanged."*

**F22 — 14 framework module targets + 42 renderer families. VERIFIED.**
Declared sets, `modules/CMakeLists.txt:153-162`:

```cmake
set(_cna_framework_modules
    core math runtime graphics input audio media content storage
    devices devices-ext graphics-ext gamer-services net)
set(_cna_renderer_modules
    bgfx blend2d canvas diligent direct2d directx1 directx2 directx3 directx5 directx6
    directx7 directx8 directx9 directx10 directx11 directx12
    easygl fna3d freedirect gdi glide headless html-dom llgl magnum metal opengl1
    opengl2 opengl4 opengles1 openvg portablegl sdl-gpu sdl-renderer skia software sokol
    stub svg-dom vulkan
    webgpu wicked common/d3d)
```

That is **42 renderer families plus the shared helper `common/d3d`**, carrying **46 public
identities** (EasyGL implements five). `docs/physical-modules.md:54-55` states the same: *"42
implementation families carry the 46 public renderer identities."*

> **Always print both numbers, labelled** — their proximity is what makes the count confusion in X2
> self-perpetuating. (An automated re-count of directory entries yields 44; the authoritative figure
> is the declared list at `modules/CMakeLists.txt:156-162`, which is what the source-partition
> validator actually enforces.)

**F23 — Module factory and the include boundary. VERIFIED.**
`modules/CMakeLists.txt:78-83`:

```cmake
function(cna_add_module target alias)
    add_library(${target} STATIC ${ARGN})
    add_library(CNA::${alias} ALIAS ${target})
    target_link_libraries(${target} PUBLIC cna_build_flags)
    target_include_directories(${target} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
endfunction()
```

Every module exports exactly **one** PUBLIC include root: its own `include/`. **No module's `src/` is
ever an include root** — verified: zero `target_include_directories` in any module `CMakeLists.txt`
names `src`. `modules/CMakeLists.txt:73-77` states the rule: every cross-module internal header lives
under some module's `include/CNA/Internal/`; the only `src/`-resident headers are renderer-local
shader headers, addressed includer-relative from inside their own renderer directory.

Two modules (`gamer-services`, `net`) bypass `cna_add_module()` and hand-roll `CNA_<Name>` targets
(`modules/gamer-services/CMakeLists.txt:2-5`, `modules/net/CMakeLists.txt:2-5`) — a naming
inconsistency against the 12 `cna_<name>` targets.

**F24 — `cna_build_flags` is definitions-only. VERIFIED.**
`modules/CMakeLists.txt:60-70`:

```cmake
add_library(cna_build_flags INTERFACE)
add_library(CNA::BuildFlags ALIAS cna_build_flags)
target_compile_definitions(cna_build_flags INTERFACE
        SOUND_ENABLED XNA5 ${CNA_RENDERER_DEFINE}
        $<$<BOOL:${CNA_CNAEXT}>:CNA_CNAEXT>
        $<$<BOOL:${CNA_DEVICES}>:CNA_DEVICES>
        $<$<BOOL:${CNA_DRACO_AVAILABLE}>:CNA_DRACO_AVAILABLE>
        $<$<BOOL:${CNA_FFMPEG_AVAILABLE}>:CNA_FFMPEG_AVAILABLE>)
```

`docs/physical-modules.md:43-44`: *"It no longer carries any include directory; the former global
`include/` root does not exist."* `SOUND_ENABLED` and `XNA5` are unconditional legacy defines worth
a footnote.

**F25 — Three umbrella targets. VERIFIED.**

- **`CNA`** (INTERFACE, `modules/CMakeLists.txt:124-141`) — the historical full-framework umbrella:
  all modules + `${RENDERER_TARGET}` + build flags. Existing `target_link_libraries(game CNA)`
  consumers keep working unchanged. The target name shadows `project(CNA …)`.
- **`cna_cnaext` / `CNA::CnaExt`** (INTERFACE, `:117-119`) — composes `cna_graphics_ext` +
  `cna_devices_ext`. Was `cna_noxna` / `CNA::NoXna` before the 2026-08 rename (comment `:111-116`).
- **`cna_build_flags` / `CNA::BuildFlags`**.

**F26 — Three declared, deliberate static-archive cycles. VERIFIED.**

1. **`graphics-core ↔ input`** — XNA semantics: `GraphicsDevice` updates `TouchPanel` display
   metrics and `Mouse`/`TextInputEXT` window binding, while `Input::MouseCursor` builds on
   `Texture2D`. `modules/graphics/CMakeLists.txt:11-14`, `modules/input/CMakeLists.txt:3`.
2. **`audio ↔ media`** — `FrameworkDispatcher::Update()` pumps `MediaPlayer`; `MediaPlayer` plays
   through the mixer. `modules/audio/CMakeLists.txt:9-13`, `modules/media/CMakeLists.txt:14-19`.
3. **`graphics-core ↔ selected renderer`** — forward: `GraphicsDevice.cpp` calls
   `CNA::Internal::Renderers::CreateGraphicsRenderer()`, declared at
   `modules/graphics/CMakeLists.txt:15-21`; reverse: every renderer PRIVATE-links
   `cna_graphics_core cna_core cna_math` (`modules/renderers/CMakeLists.txt:42`). The reverse edge
   is **structural for every renderer**, not just D3D — `modules/renderers/CMakeLists.txt:34-41`
   explains that `IGraphicsRenderer`'s header-inlined defaults
   (`HandleUnsupported3DCall → CNA::Logger::Warn`, the instanced-draw guard) give every renderer the
   same edge; it first surfaced for real on VULKAN's `cna_reference_dump` link.

Declared on both sides so CMake repeats the archives on the final link line. Summarized at
`docs/physical-modules.md:132-140`.

**F27 — Renderer composition machinery. VERIFIED.**
`modules/renderers/CMakeLists.txt`: `cna_renderer_common` INTERFACE (`:14-15`);
`cna_renderer_common_setup()` (`:20-43`) applies the common interface, the sharp-runtime default
closure, the family's own `include/` root, and the three reverse edges;
`cna_add_renderer([extra sources])` (`:49-54`) globs `${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp`
**non-recursively** and defines `${RENDERER_TARGET}` as STATIC.
Only the selected family's directory is entered (`:80-82`), with three exceptions: `metal` and
`glide` unconditionally (header-interface targets, because their policy suites compile into
`CnaTests` on *every* renderer — `:58-63`); `common/d3d` only for DIRECTX11/DIRECTX12 (`:68-70`);
`software` before `gdi` when GDI is selected (`:76-78`).
Family target naming: `cna_renderer_<family>`.

**F28 — The one documented ownership exception. VERIFIED.**
GDI compiles eight software-module 2D TUs published as `CNA_GDI_SOFTWARE_SOURCES`
(`modules/renderers/software/CMakeLists.txt:17-27`) plus `cna_renderer_software_headers` INTERFACE
(`:30-32`); consumed at `modules/renderers/gdi/CMakeLists.txt:4-5`, which also emits a
configure-time archive-size message (`:9-13`). Physical ownership stays with `software` — called out
at `modules/CMakeLists.txt:147-149` and `docs/physical-modules.md:74-77`.
Other deliberate helper targets: `cna_renderer_d3dcommon`
(`modules/renderers/common/d3d/CMakeLists.txt:10-16`, consumed by directx11/directx12 only — D3D9
and D3D10 are independent, `:4-8`); `cna_renderer_d3d9_effect` (isolated d3dcompiler path, inside
directx9); `cna_renderer_metal_headers` / `cna_renderer_glide_headers`.

**F29 — Physical source-partition validator: location IS ownership. VERIFIED.**
`modules/CMakeLists.txt:163-184`: a `GLOB_RECURSE` over `*.cpp`/`*.mm` under `modules/` fails
configure unless each TU matches `^<framework-module>/(src|tests|examples)/` or
`^renderers/<family>/(src|tests|examples)/`. `examples/` joined the owned areas in the
module-examples campaign (`:151-153`).

**F30 — Link-closure enforcement: 14 probes + hand-registered gates + the identity gate. VERIFIED.**
`cmake/Tests/ModuleProbes.cmake`, included from `CMakeLists.txt:156`, guarded by
`CNA_BUILD_TESTS AND NOT EMSCRIPTEN AND NOT ANDROID` (`:10`).
`cna_add_module_probe(name module [forbid])` (`:13-26`) creates two ctests per probe:
`ModuleProbe_<name>` (does it link and run) and `ModuleLinkClosure_<name>` (is the link line clean).
Probe sources live in `tests/modules/` and are explicitly excluded from `CnaTests`
(`cmake/UnitTests.cmake:43`).

The 14 probes and their forbid regexes:

| Probe | Module | Forbidden link inputs | Line |
|---|---|---|---|
| `probe_math` | `CNA::Math` | `libcna_(?!math)\|libCNA_\|libSDL3\|libenet\|libav\|cna_renderer_` | :30-31 |
| `probe_core` | `CNA::Core` | `libcna_(?!core\|math)\|libCNA_\|libenet\|libav\|cna_renderer_` | :35-36 |
| `probe_graphics` | `CNA::GraphicsCore` | `libcna_(content\|media\|audio\|runtime\|devices\|cnaext\|storage)\|libCNA_\|libenet\|libav` | :40-41 |
| `probe_content` | `CNA::Content` | `libcna_(runtime\|devices\|cnaext\|storage)\|libCNA_\|libenet` | :45-46 |
| `probe_runtime` | `CNA::Runtime` | `libcna_(devices\|cnaext\|storage)\|libCNA_\|libenet` | :49-50 |
| `probe_input` | `CNA::Input` | `libcna_(content\|media\|audio\|runtime\|devices\|storage\|graphics_ext)\|libCNA_\|libenet\|libav` | :54-55 |
| `probe_audio` | `CNA::Audio` | `libcna_(content\|runtime\|devices\|storage\|graphics_ext)\|libCNA_\|libenet` | :59-60 |
| `probe_media` | `CNA::Media` | same as audio | :63-64 |
| `probe_storage` | `CNA::Storage` | `libcna_(?!storage)\|libCNA_\|libenet\|libav\|cna_renderer_` | :69-70 |
| `probe_devices` | `CNA::Devices` | `libcna_(devices_ext\|graphics_ext)\|libCNA_\|libenet` | :74-75 |
| `probe_devices_ext` | `CNA::DevicesExt` | `libcna_devices\.\|libcna_graphics_ext\|libCNA_\|libenet` | :79-80 |
| `probe_graphics_ext` | `CNA::GraphicsExt` | `libcna_(content\|media\|audio\|runtime\|devices\|storage)\|libCNA_\|libenet` | :83-84 |
| `probe_cnaext` | `CNA::CnaExt` | (no forbid — composition gate registered separately) | :89 |
| `probe_net` | `CNA::Net` | `libcna_(devices\|graphics_ext)` | :104-105 |

Sharpest contracts worth quoting in the book: **storage** forbids `libcna_(?!storage)` — even
`libcna_core` must stay off the line, because the `PlayerIndex`/`CNAEXT` dependency is headers-only
via `cna_core_headers` (`:66-70`); **devices-ext** uses an escaped dot (`libcna_devices\.`) so
`libcna_devices_ext.a` is not self-matched, encoding "devices-ext must never depend on the XNA
device base" (`:77-80`).

Additional hand-registered gates: `ModuleLinkClosure_CnaExtComposition` requires **both**
`libcna_graphics_ext` and `libcna_devices_ext` (`:91-97`); `ModuleLinkClosure_NetHasENet` requires
`libenet` (`:107-113`); four HEADLESS-only `ModuleLinkClosure_NativeSdkFree_*` gates plus the
historical-name `ModuleLinkClosure_GraphicsNativeSdkFree`, forbidding
`vulkan|libGL|GLES|EGL|d3d|dxgi|ddraw|d2d1|bgfx|wgpu|webgpu|glide|gdi32|[Mm]agnum|[Dd]iligent|LLGL|skia|sokol|[Ww]icked|shaderc`
(`:121-138`); `ModuleLinkClosure_VulkanRendererClosure`, requiring `vulkan` and forbidding every
other family SDK (`:142-149`); `RendererIdentityRegistry` (`:153-155`).

**F31 — The closure gate silently degrades on non-Makefiles generators. VERIFIED — important and
book-worthy.**
`scripts/check_module_link_closure.py:32-35` reads `<build>/CMakeFiles/<target>.dir/link.txt` and
returns **77 (CTest SKIP)** when it is absent. The `tests` preset sets `"generator": "Ninja"`
(`CMakePresets.json:66`) and every CI job configures with `-G Ninja`. **Under the project's own
presets and CI, every `ModuleLinkClosure_*` gate skips rather than runs.** The gates are real and
correct, but currently exercised only in a Makefiles build.
Script contract: `--build-dir`, `--target`, `--forbid <regex>` (required), repeatable
`--require <regex>`; exit 0 ok, 1 violation, 77 skip (`:22-53`).

**F32 — Additional mechanical validators. VERIFIED / STRONG.**
`docs/physical-modules.md:142-154` lists three: the source-partition validator (F29);
`modularization/tools/check_include_reachability.py` — every `#include "CNA/…"`/`"Microsoft/…"` in
every module TU must resolve transitively through the declared module graph, with config-gated
renderer includes attributed to their renderer; and `cmake/Tests/ModuleProbes.cmake`.
`modularization/tools/` also carries `check_header_self_containment.py`, `gen_module_cmake.py`,
`physical_move_map.py`, `reconcile_phase3.py`, `reconcile_examples.py`, `capture_inventory.py`,
`example_inventory.py`, `example_move_map.py`, `apply_moves.sh`.

**F33 — Test layout. VERIFIED.**
**419 module-owned test TUs.** Framework: graphics 85, content 68, input 42, media 29, devices 24,
audio 23, math 22, runtime 19, net 18, gamer-services 14, devices-ext 10, core 3, graphics-ext 3,
storage 1. Renderers (only 14 of 42 families have tests at all): metal 26, glide 14, fna3d 5,
wicked 4, and 1 each for canvas, diligent, direct2d, easygl, html-dom, llgl, magnum, openvg, svg-dom.
Top-level `tests/` retains exactly three things: `tests/assets/` (gltf, media incl.
music/video/pictures/thumbnails, xnb/monogame), `tests/fixtures/direct2d/`, and `tests/modules/`
(the 14 probe TUs). 157 files total.
Every module test tree preserves its former `tests/`-relative mirror path
(`docs/physical-modules.md:46-48`), which is why the path-tail filters in `cmake/UnitTests.cmake`
still match unchanged.

**F34 — Modularization campaign shape. VERIFIED (via `git show --stat`).**
19 commits on `feature/physical-modules`, all 2026-08-10, in strict order: **7 pure-rename commits**
(`7a8f5806b`, `6be9ff494`, `3b959fec5`, `05a123277`, `5f601a8ef`, `72eb09a55`, `9b6c6c833`) touching
133+440+168+122+144+179+590 = **1776 files**, each reporting `0 insertions, 0 deletions`; then the
build rewrite, the gates, the docs.

- **`33088cba6`** (11:39:13) — the pivotal build commit: 66 files, +985/−839. **Deleted
  `cmake/BackendLibraries.cmake` (−398) and `cmake/CnaLibrary.cmake` (−379)**; **created
  `modules/CMakeLists.txt`** plus 14 framework and ~44 renderer `CMakeLists.txt`.
- **`73501a6fc`** (11:39:28) — grew the probe fleet 5 → 14; created 9 probe TUs.
- **`3c6ac9145`** (11:39:38) — created `docs/physical-modules.md`.
- **`9c950ffdc`** (12:21:34) — the no-loss evidence dump: 11 files, +22042
  (`modularization/RECONCILIATION.md`, `tools/reconcile_phase3.py`, `physical-modules/after/`
  inventories). Recorded: production TUs **1357 → 1357** (1287 byte-identical moves, 70
  directive-only edits, **zero lost**); ctest names HEADLESS 6120→6143, OPENGLES 6527→6546, **zero
  removals, zero renames**.
- **`840ab9e5b`** (13:18:36) — docs-only promotion marker (fast-forward `7cbf0a29b → a1bec3bc4`,
  tree unchanged).

**F35 — Two *later, separate* campaigns are routinely conflated with it. VERIFIED.**

- **Module-owned examples:** `86872b81f` (2026-08-10 16:41, "build(examples): localize example
  registration into the owning modules") deleted `cmake/Examples.cmake` **and 39 per-renderer
  `cmake/Tests/*Tests.cmake` manifests**. At HEAD, `cmake/Tests/` holds exactly two files:
  `ModuleProbes.cmake` and `WickedTests.cmake`. `FUTURE.md:22` records the endpoint as `675e04c7a`:
  *"All 1373 tracked example files now live with their owning module, registered by 44 module-local
  `examples/CMakeLists.txt` files; only the shared `examples/golden/` oracle corpus stays at
  repository level."*
- **Terminology normalization:** `57aee5f88` (14:20) renamed `cmake/BackendSelection.cmake` →
  `cmake/RendererSelection.cmake` (F45).

**F36 — Example ownership model. VERIFIED.**
`docs/physical-modules.md:85-130`: subsystem examples live with the framework module whose API they
demonstrate (`modules/graphics/examples/` owns demo_2d, house3d_demo, the renderer-agnostic
conformance fixtures and the shared `common/` support headers — PixelTestGame, ScreenshotEXT,
SimpleFontEXT, ViewSpaceFogRef; plus `modules/audio/examples/`, `modules/input/examples/`,
`modules/devices/examples/` incl. the Android Gradle/CMake subproject,
`modules/gamer-services/examples/`, `modules/net/examples/`). Renderer examples live with their
implementation family. Extension examples live in `modules/graphics-ext/examples/`.
`CNA_GRAPHICS_EXAMPLES_DIR` (`modules/CMakeLists.txt:89`) is how family registrations reach the
shared fixtures. **Top-level `examples/` holds exactly one thing:** `examples/golden/`, the
cross-renderer golden oracle corpus, loaded by CWD-relative `"examples/golden/*.png"` literals from
the repo-root test working directory. Executables still land at the build root
(`modules/graphics/examples/CMakeLists.txt:11` resets `CMAKE_RUNTIME_OUTPUT_DIRECTORY`).

---

# 2. MODULE TABLE

Every physical module target at HEAD, with what it owns and its declared edges. Sources: the 14
framework `CMakeLists.txt` files read in full; corroborated by `docs/physical-modules.md:18-33`.
**VERIFIED.**

| Module root | Target (alias) | Kind | Owns | PUBLIC CNA edges | PRIVATE edges | SharpRuntime components |
|---|---|---|---|---|---|---|
| `modules/core` | `cna_core` (`CNA::Core`) | base | `CNA/` root: `CNAHelper.hpp` (CNAEXT marker), `CNAException`, `Logger`, `DesktopOS`, `GraphicsRendererType.hpp`, framework-root leaf enums (`PlayerIndex`), header-only internals (`PathContainment`) | — | `SDL3::SDL3` (Logger.cpp only) | `Core.Base` |
| " | `cna_core_headers` (`CNA::CoreHeaders`) | INTERFACE | the same `include/` root, no symbols | — | — | — |
| `modules/math` | `cna_math` (`CNA::Math`) | base | `Microsoft::Xna::Framework` math: Vector*, Matrix, Quaternion, Bounding*, Ray, Plane, Curve, MathHelper, Color | `cna_core_headers` (headers-only: CNAEXT marker) | — | `Core.Base` |
| `modules/graphics` | `cna_graphics_core` (`CNA::GraphicsCore`) | base | `Microsoft::Xna::Framework::Graphics` (+ PackedVector) and **the renderer contract headers** `CNA/Internal/Renderers/Common/` (`IGraphicsRenderer.hpp` et al.); globs `src/Xna/*.cpp` + `src/Internal/*.cpp` | `cna_math`, `cna_core` | `SDL3::SDL3`, `SDL3_image::SDL3_image`, **`cna_input`** (cycle), **`${RENDERER_TARGET}`** (factory edge) | `Core.Base IO Collections.Core Text` |
| `modules/input` | `cna_input` (`CNA::Input`) | base | `Microsoft::Xna::Framework::Input` (+ `::Touch`), `CNA::Input` (haptics/joystick/power/sensors), `CNA::Internal::Input` (SDL backends), `src/CnaExt/` | `cna_graphics_core`, `cna_math`, `cna_core` | `SDL3::SDL3` | `Core.Base` |
| `modules/audio` | `cna_audio` (`CNA::Audio`) | base | `Microsoft::Xna::Framework::Audio`, `CNA::Internal::Audio`, **and `FrameworkDispatcher`** (`src/Xna/`; ownership follows dependency direction — assigning it to runtime would create a runtime↔audio cycle for nothing, `:1-3`) | `cna_core`, `cna_math` | `SDL3::SDL3`, `SDL3_mixer`, **`cna_media`** (cycle), **`cna_input`** (dispatcher pumps TouchPanel, as FNA does) | `Core.Base IO Runtime` |
| `modules/media` | `cna_media` (`CNA::Media`) | base | `Microsoft::Xna::Framework::Media`, `CNA::Internal::Media`; 3 TUs excluded when FFmpeg is unavailable | `cna_audio`, `cna_graphics_core` | `SDL3::SDL3`, `SDL3_mixer`, `cna_input`, and (when available) `PkgConfig::LIBAVCODEC/LIBAVFORMAT/LIBAVUTIL/LIBSWRESAMPLE` | `Core.Base IO` |
| `modules/content` | `cna_content` (`CNA::Content`) | base | `Microsoft::Xna::Framework::Content`, **`CNA::Internal::Xnb`** (the `.xnb` reader, 16 TUs incl. `LzxDecoder.cpp`), `CNA::Internal::GltfImport`; 1 TU excluded without FFmpeg | `cna_graphics_core`, `cna_audio`, `cna_media`, `cna_math`, `cna_core` | `SDL3::SDL3`, `SDL3_mixer`, `draco::draco` (optional); PRIVATE include dirs `third_party/cgltf`, `third_party/stb` | `Core.Base IO` |
| `modules/storage` | `cna_storage` (`CNA::Storage`) | base | `Microsoft::Xna::Framework::Storage` (StorageDevice/StorageContainer) | `cna_core_headers` **only** (headers-only: PlayerIndex + CNAEXT + PathContainment) | `SDL3::SDL3` | `Core.Base IO Runtime Threading` |
| `modules/runtime` | `cna_runtime` (`CNA::Runtime`) | base | `Game`, `GameWindow`, `GameTime`, `GameComponent`, service container, platform loop | `cna_graphics_core`, `cna_input`, `cna_content`, `cna_audio`, `cna_media`, `cna_core`, `cna_math` | `SDL3::SDL3`, `SDL3_mixer` | `Core.Base IO` |
| `modules/devices` | `cna_devices` (`CNA::Devices`) | base | `Microsoft::Devices` XNA-compatible base: Sensors (Accelerometer/Compass/Gyroscope/Motion) + `VibrateController` | `cna_runtime`, `cna_graphics_core`, `cna_core`, `cna_math`; **`android log`** PUBLIC on Android (NDK `ASensorManager_*`/`__android_log_print`) | `SDL3::SDL3` | `Core.Base` |
| `modules/devices-ext` | `cna_devices_ext` (`CNA::DevicesExt`) | extension | `CNA::Devices`: Camera, Clipboard, FileDialog, MessageBox, SystemTray, DisplayInfo, PowerInfo, SystemInfo, Locale, UrlLauncher | `cna_runtime`, `cna_graphics_core`, `cna_core`, `cna_math` — **deliberately never `cna_devices`, and never the reverse** | `SDL3::SDL3` | `Core.Base` |
| `modules/graphics-ext` | `cna_graphics_ext` (`CNA::GraphicsExt`) | extension | `CNA::Graphics` engine layer (`#ifdef CNA_CNAEXT`): PbrMaterial, CRTEffect, DepthEffect, **AsciiPostProcessEffect** (migrated from the removed ASCII renderer identity), RenderPipelineSettings; the complete implementation of the former `cna_noxna` STATIC library | `cna_graphics_core` | — | `Core.Base` |
| `modules/gamer-services` | `CNA_GamerServices` (`CNA::GamerServices`) | base, gated by `CNA_ENABLE_NET` | `Microsoft::Xna::Framework::GamerServices`: Guide, SignedInGamer, Avatar*, `CNA::Internal::GamerServices` | `cna_runtime`, `cna_storage` | `SDL3::SDL3` (Guide.cpp message box) | `Core.Base IO Collections.Core Globalization Runtime Threading` |
| `modules/net` | `CNA_Net` (`CNA::Net`) | base, gated by `CNA_ENABLE_NET` | `Microsoft::Xna::Framework::Net`, `CNA::Internal::Net` (ENet wrappers) | `CNA_GamerServices`, **`enet`** | — | `Core.Base IO Collections.Core Runtime Threading` |

**Umbrellas** (`modules/CMakeLists.txt`): `CNA` (INTERFACE, `:124-141`) =
`cna_runtime cna_devices cna_devices_ext cna_graphics_ext cna_cnaext cna_storage cna_content cna_media cna_audio cna_input cna_graphics_core cna_core cna_math cna_build_flags ${RENDERER_TARGET}`;
`cna_cnaext`/`CNA::CnaExt` (INTERFACE, `:117-119`) = `cna_graphics_ext` + `cna_devices_ext`;
`cna_build_flags`/`CNA::BuildFlags` (INTERFACE, `:60-70`).

**Renderer targets:** exactly one `cna_renderer_<family>` per configuration, plus the unconditional
`cna_renderer_metal_headers` and `cna_renderer_glide_headers`, the conditional
`cna_renderer_d3dcommon` (D3D11/D3D12 only) and `cna_renderer_software_headers` (GDI only), and
`cna_renderer_d3d9_effect` inside directx9.

---

# 3. BUILD REFERENCE

## 3.1 Requirements

| Requirement | Value | Evidence | Confidence |
|---|---|---|---|
| CMake | **≥ 3.20** | `CMakeLists.txt:1`; `CMakePresets.json:3` | VERIFIED |
| Presets schema | version 3 | `CMakePresets.json:2` | VERIFIED |
| C++ standard | **23, required, no GNU extensions** | `CMakeLists.txt:5-7` | VERIFIED |
| Compiler floor | GCC 12+ / Clang 15+ | `README.md:326`, `programs.md:44` | STRONG |
| Compilers exercised | GCC 14 (`general-tests-ci.yml:65`), Clang, AppleClang (`metal-macos-ci.yml`), MSVC (`d3d-windows-ci.yml`, `gdi-windows-ci.yml`), mingw-w64 GCC (cross), emcc (`htmldom-ci.yml`) | CI workflows | VERIFIED |
| Compiler-ID-gated feature | strict-XNA-API harness requires `GNU\|Clang` | `cmake/Harnesses.cmake:178` | VERIFIED |
| **Install / packaging** | **NONE — zero `install()`, `install(EXPORT)`, `export(EXPORT)`, `include(CPack)` in the root, `cmake/`, or any module** | exhaustive grep | VERIFIED |

**CNA is consumed only by `add_subdirectory` + `target_link_libraries(<app> CNA)`.** A chapter
describing `make install` then `find_package(CNA)` would be inventing an API.

## 3.2 Every `CNA_*` option with default and effect

**Root — `CMakeLists.txt`:**

| Option | Default | Effect | Line |
|---|---|---|---|
| `CNA_USE_CCACHE` | `ON` | `find_program(ccache)`; sets `CMAKE_C/CXX_COMPILER_LAUNCHER` **only if not already set**; configured *before* sharp-runtime is added so the cache covers it | :13-27 |
| `CNA_BUILD_TESTS` | `ON` | `enable_testing()`, googletest submodule, `CnaTests`, module probes, most harnesses | :55 |
| `CNA_BUILD_EXAMPLES` | `ON` | each module's `examples/CMakeLists.txt` bodies; `cna_reference_dump` | :59 |
| **`CNA_CNAEXT`** | **`OFF`** | defines `CNA_CNAEXT`, compiling in the entire `CNA::Graphics` engine layer (`modules/graphics-ext/`) | :60 |
| **`CNA_DEVICES`** | **`OFF`** | defines `CNA_DEVICES`; without it the whole `CNA::Devices` surface (FileDialog/MessageBox/Clipboard/SystemTray/…) compiles out **silently** | :61 |
| `CNA_ENABLE_NET` | `ON` | adds `modules/gamer-services` + `modules/net`; pulls vendored ENet | :62 |
| `CNA_DIRECT2D_TEST_RUNTIME` | `"WINE"` (STRINGS `WINE PROTON`) | cross-compiled Direct2D test runtime | :66-67 |
| `CNA_TEST_DISPLAY` | `":0"` | `DISPLAY` baked into every GPU/window-creating ctest's `ENVIRONMENT` (with `SDL_VIDEODRIVER=x11`); set `:99` for Xvfb | :72 |
| `CNA_SANITIZE` | `""` | comma list (e.g. `address,undefined`) → `-fsanitize=… -fno-omit-frame-pointer -g` compile + link, applied **after** vendored SDL/ENet so those stay uninstrumented | :88-93 |
| `CNA_SHARP_RUNTIME_ROOT` | `${CMAKE_CURRENT_SOURCE_DIR}/../sharp-runtime` | which sharp-runtime checkout to `add_subdirectory` | :103 |

**SDL — `cmake/ThirdPartySDL.cmake`:**

| Option | Default | Effect | Line |
|---|---|---|---|
| `CNA_USE_SYSTEM_SDL` | `OFF` | `ON` → `find_package(SDL3/SDL3_image/SDL3_mixer REQUIRED)` instead of the vendored build | :3 |
| `CNA_MAX_VENDORED_BUILD_JOBS` | `"2"` | parallelism ceiling for the configure-time vendored builds; validated as a positive integer or `FATAL_ERROR` | :8-13 |
| `CNA_SDL_PREBUILT_ROOT` | `.sdl-prebuilt-emscripten` or `.sdl-prebuilt-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}` | persistent SDL3 install root, keyed by target so a cross-build cannot overwrite the native cache | :21-29 |

**Renderer selection — `cmake/RendererSelection.cmake`:** `CNA_GRAPHICS_RENDERER` (platform default,
§4); **46 × `CNA_RENDERER_<NAME>`** all `OFF` (`:18-185`); `CNA_SOKOL_API` = `GLCORE` (`:509`);
`CNA_SKIA_MODE` = `RASTER` (`:672`); `CNA_BGFX_BUILD_SHADERC` = `OFF` (`:569`).

**Third-party pins, roots and toggles:**

| Option | Default |
|---|---|
| `CNA_BLEND2D_GIT_TAG` / `_GIT_REPOSITORY` / `CNA_BLEND2D_ROOT` | `def0d1238c3e5d0983bb848e5676049d829e435b` / `https://github.com/blend2d/blend2d.git` / `""` |
| `CNA_ASMJIT_GIT_TAG` / `_GIT_REPOSITORY` / `CNA_ASMJIT_ROOT` | `b56f4176cb9b0c0501da659ac54d4c5877862c7b` / `https://github.com/asmjit/asmjit.git` / `""` |
| `CNA_DILIGENT_VERSION` | `v2.5.6` |
| `CNA_FNA3D_GIT_TAG` / `_GIT_REPOSITORY` | `3240147` / `https://github.com/FNA-XNA/FNA3D.git` |
| `CNA_LLGL_GIT_TAG` / `_GIT_REPOSITORY` / `CNA_LLGL_ROOT` | `Release-v0.04b` / `https://github.com/LukasBanana/LLGL.git` / `""` |
| `CNA_LLGL_BUILD_RENDERER_OPENGL` / `_VULKAN` / `_NULL` | `ON` / computed from `find_package(Vulkan QUIET)` / `ON` |
| `CNA_CORRADE_GIT_TAG` / `CNA_MAGNUM_GIT_TAG` / `CNA_MAGNUM_ROOT` | `783e4e4807536ec52c352986fc9317db986ace96` / `5a7424643bfd4621fbcff8c361d37795502cf890` / `""` |
| `CNA_MAGNUM_USE_EGL` | `OFF` (Linux only; `ON` → EglContext instead of GlxContext) |
| `CNA_OPENVG_GIT_TAG` / `_GIT_REPOSITORY` | `6122ccb3c4b86f69a326f1a65b0f86bc79f69c50` / `https://github.com/ileben/ShivaVG.git` |
| `CNA_PORTABLEGL_GIT_TAG` / `_GIT_REPOSITORY` | `63a55db75ab07619797a93ff9bf3909355d27950` (tag 0.100.0) / `https://github.com/rswinkle/PortableGL.git` |
| `CNA_SKIA_ROOT` / `CNA_SKIA_BUILD_DIR` / `CNA_SKIA_GANESH_BUILD_DIR` | `""` / `""` / `""` (all required for SKIA) |
| `CNA_SOKOL_GIT_TAG` / `_GIT_REPOSITORY` | `27b49604b19be8cee0dcc6b2bbfe803dd9517585` / `https://github.com/floooh/sokol.git` |
| `CNA_WEBGPU_VERSION` / `CNA_WEBGPU_ROOT` / `CNA_WEBGPU_AUTO_DOWNLOAD` | `v29.0.1.1` / `""` / **`ON`** |
| `CNA_WICKED_COMMIT` / `CNA_WICKED_ROOT` / `CNA_WICKED_AUTO_FETCH` | `27c0df160d738925474a2181d3f88bfd59edaefe` / `""` / **`OFF`** |
| `CNA_WICKED_APPLY_SDL3_PATCH` / `_TEARDOWN_PATCH` / `_STAGING_FOOTPRINT_PATCH` | `ON` / `ON` / `ON` |

**Module-local:** `CNA_BUILD_SVG_DOM_HOST_TESTS` `OFF` (`modules/renderers/CMakeLists.txt:99`);
`CNA_BUILD_HTML_DOM_HOST_TESTS` `OFF` (`modules/renderers/html-dom/examples/CMakeLists.txt:104`);
`CNA_DX8_DXVK_LIB` `/usr/lib/dxvk/wine64/d3d8.dll.a`, `FATAL_ERROR` if absent
(`modules/renderers/directx8/CMakeLists.txt:6-12`).

**Internal cache (not user-facing):** `CNA_DILIGENT_SOURCE_DIR`, `CNA_DILIGENT_ENGINES`,
`CNA_MAGNUM_CONTEXT_COMPONENT`, `CNA_WEBGPU_RUNTIME_LIBRARY`, `CNA_WEBGPU_RESOLVED_ROOT`,
`CNA_WICKED_RESOLVED_ROOT`, `CNA_WICKED_DXCOMPILER`, `CNA_RENDERER_DEFINE`, `RENDERER_DIR`,
`RENDERER_TARGET`, `CNA_FFMPEG_AVAILABLE`, `CNA_DRACO_AVAILABLE`, `CNA_GRAPHICS_EXAMPLES_DIR`,
`CNA_SKIA_LINK_TARGET`, `CNA_SOKOL_API_DEFINE`, `CNA_BGFX_SHADER_INCLUDE_DIR`,
`CNA_GDI_SOFTWARE_SOURCES`.

## 3.3 Dependency acquisition, per library

**Mechanism 1 — git submodules (4, `.gitmodules`):** `vendor/googletest`, `third_party/SDL`,
`third_party/SDL_image`, `third_party/SDL_mixer`. Missing-submodule guards with actionable messages
at `cmake/ThirdPartySDL.cmake:44-62` and `cmake/UnitTests.cmake:9-15` (the latter notes a plain
ZIP/tarball export cannot contain submodule content at all).

**Mechanism 2 — vendored in-tree sources (not submodules):** `third_party/cgltf`, `third_party/stb`
(PRIVATE include dirs at `modules/content/CMakeLists.txt:20-23`), `third_party/enet`
(`cmake/ThirdPartyENet.cmake`, `cna_configure_vendored_enet()`), `vendor/wgpu-native`.

**Mechanism 3 — sibling repository checkouts** (§3.4).

**Mechanism 4 — FetchContent / configure-time download:**

| Library | When | How | Pin |
|---|---|---|---|
| bgfx.cmake | `BGFX` | inline `FetchContent` in `RendererSelection.cmake:568-593`, with `PATCH_COMMAND git apply cmake/patches/bgfx-max-render-target-msaa.patch`; `GIT_SUBMODULES_RECURSE TRUE` | `572868c0…` |
| Blend2D + AsmJit | `BLEND2D` | `cna_configure_blend2d()`; honours `CNA_BLEND2D_ROOT`/`CNA_ASMJIT_ROOT` | two SHAs |
| DiligentCore | `DILIGENT` | `cna_configure_diligent()`; disables tests/archiver/install, gates D3D11/12 off-Windows, WebGPU always off, probes for `GL/glx.h` | `v2.5.6` |
| FNA3D (+ MojoShader, + stock-effect blobs from a pinned FNA checkout) | `FNA3D` | `cna_configure_fna3d()`; forces `BUILD_SHARED_LIBS OFF` around the add and restores it | `3240147` |
| LLGL | `LLGL` | `cna_configure_llgl()`; static lib, `LLGL_ENABLE_EXCEPTIONS ON`, per-module renderer toggles | `Release-v0.04b` |
| Corrade + Magnum | `MAGNUM` | `cna_configure_magnum()`; tries `find_package(Magnum QUIET COMPONENTS GL <Ctx>)` first, else fetches both; static, almost every `MAGNUM_WITH_*` off | two SHAs |
| ShivaVG | `OPENVG` | `cna_configure_openvg()` + `cmake/patches/apply-shivavg-patch.cmake` (`shivavg-context-dtor-leak.patch`); also `find_package(OpenGL REQUIRED)` | `6122ccb3…` |
| PortableGL | `PORTABLEGL` | `cna_configure_portablegl()` (single header) | `63a55db7…` (0.100.0) |
| sokol | `SOKOL` | `cna_configure_sokol()`; `find_package(OpenGL REQUIRED)` for GL APIs | `27b49604…` |
| WickedEngine | `WICKED` | `cna_configure_wicked()`; **`CNA_WICKED_AUTO_FETCH` is OFF by default** — expects `CNA_WICKED_ROOT`; verifies and conditionally applies 3 patches (SDL3 platform, device teardown, staging footprint) | `27c0df16…` |
| wgpu-native (binary release) | `WEBGPU` | `cna_configure_webgpu()`; **auto-downloads by default**; `CNA_WEBGPU_ROOT` for offline/reproducible | `v29.0.1.1` |
| Skia | `SKIA` | **not fetched** — requires a pre-built external artifact via `CNA_SKIA_ROOT` + `CNA_SKIA_BUILD_DIR` (RASTER) or `CNA_SKIA_GANESH_BUILD_DIR` (GANESH); `FATAL_ERROR` otherwise | external |

**Mechanism 5 — system packages:** FFmpeg via
`pkg_check_modules(… REQUIRED IMPORTED_TARGET libavcodec/libavformat/libavutil/libswresample)`
(`modules/CMakeLists.txt:20-31` — `IMPORTED_TARGET` deliberately, so include dirs, `-L` dirs and
libraries all propagate as INTERFACE properties, which matters for Homebrew's `/opt/homebrew`
prefix); Draco via `find_package(draco CONFIG QUIET)` (`:40-47`, optional — absent means a
Draco-compressed glTF primitive throws a clear unsupported-format error at import time);
`find_package(Vulkan REQUIRED)`; `find_package(OpenGL REQUIRED)`; `libGLESv1_CM` + `GLES/gl.h` for
OPENGLES1; `find_package(Threads REQUIRED)` for Skia.

**FFmpeg availability is a computed platform gate that changes what compiles. VERIFIED.**
`modules/CMakeLists.txt:14-18`: `CNA_FFMPEG_AVAILABLE=OFF` on
`MINGW OR WIN32 OR EMSCRIPTEN OR ANDROID` (the comment at `:8-13` explains that on a MinGW
cross-build pkg-config would otherwise silently resolve the *host's* native FFmpeg and poison the
include path with native glibc headers). When OFF: `modules/media/CMakeLists.txt:4-8` drops
`src/Internal/VideoDecoder.cpp`, `src/Xna/Video/VideoPlayer.cpp`, `src/Xna/Video/Video.cpp`;
`modules/content/CMakeLists.txt:8-10` drops `src/Xnb/VideoContentTypeReader.cpp`;
`cmake/UnitTests.cmake:52-58` drops five test TUs. Both flags are pushed to `PARENT_SCOPE`
(`modules/CMakeLists.txt:52-53`).

**SDL is built at *configure* time into a persistent out-of-build-tree prefix. VERIFIED — unusual
and book-worthy.** `cmake/ThirdPartySDL.cmake:31-172`: `cna_configure_vendored_sdl()` early-outs if
the targets exist (`:32-34`) or `CNA_USE_SYSTEM_SDL=ON` (`:36-41`); otherwise `_cna_build_sdl_dep()`
runs `execute_process()` configure + build + install of SDL3, SDL3_image and SDL3_mixer **during
`cmake` configure**, into `${CNA_SDL_PREBUILT_ROOT}/install`, then
`find_package(… REQUIRED CONFIG)` (`:166-171`). The prefix lives outside every build tree so
`--clean-first` and build-dir deletion do not destroy it (`:15-20`). Every optional codec is
disabled: SDL_image AVIF/JXL/TIF/WebP/libpng OFF (`:133-137`), SDL_mixer
GME/MOD_XMP/MP3_MPG123/MIDI_FLUIDSYNTH/OPUS/VORBIS×2/WAVPACK/FLAC OFF (`:153-161`) — which is
precisely why `--recursive` is unnecessary (X4).

## 3.4 Sibling repositories

| Sibling | Required? | Located via | Failure mode |
|---|---|---|---|
| **sharp-runtime** | **Always** | `CNA_SHARP_RUNTIME_ROOT`, default `<repo>/../sharp-runtime`; `add_subdirectory(… SHARP_RUNTIME)` at `CMakeLists.txt:114` | `CMakeLists.txt:105-113` — `FATAL_ERROR` stating it is *not* a submodule (`git submodule update --init` will not fetch it) and giving the `git clone` line |
| **easy-gl** | Only OPENGLES2/OPENGLES3/OPENGL33/WEBGL1/WEBGL2 | hardcoded `<repo>/../easy-gl`; **no override variable exists** | `cmake/RendererSelection.cmake:453-461` — `FATAL_ERROR` naming branch `develop` and easy-gl's own required `../meta-gl` sibling |
| **meta-gl** | Transitively, via easy-gl | easy-gl's own sibling lookup | CNA references it only in that error text and `CMakeLists.txt:38-43` |
| **free-direct** | Only FREEDIRECT | hardcoded `<repo>/../free-direct`; no override | `cmake/RendererSelection.cmake:473-481` — `FATAL_ERROR` + `git clone` line |
| **free-api** | **Never consumed directly** | free-direct's own `add_subdirectory(../free-api …)`; the `free-direct` target PUBLIC-links `free-api::free-api` | — |

`cmake/RendererSelection.cmake:467-471` records that free-direct resolves
`SDL3::SDL3`/`SDL3_image`/`SDL3_mixer` from CNA's already-vendored targets (set up before renderer
selection runs), so no `-DFREE_API_USE_SYSTEM_SDL3` is needed.
`modules/renderers/freedirect/CMakeLists.txt:1-3`: free-direct's public target is the **literal
lowercase `free-direct`** — no namespaced alias exists, unlike easy-gl.

**sharp-runtime consumption seam. VERIFIED.** `cmake/SharpRuntimeConsumption.cmake`. Two shapes
(`:3-15`): **modular** (sharp-runtime `develop` since 2026-08-10, commit `81624983` — *"the
AUTHORITATIVE shape for the sibling-develop combination"*), exposing `SharpRuntime::<Component>`
targets plus a compatibility `SHARP_RUNTIME` INTERFACE that exists only under the default "All"
selection; and **monolithic** (pre-modularization), one `SHARP_RUNTIME` archive. Detection is
`if(TARGET SharpRuntime::Core.Base)` (`:34`).
`cna_link_sharp_runtime(<target> <PUBLIC|PRIVATE|INTERFACE> [Component…])` (`:45-59`) expands to
component targets or the single archive. The CNA-wide default closure when no components are named
(`:21-31`): `Core.Base IO Collections.Core Collections.ObjectModel Runtime Threading Text
Globalization Storage`. Each module names its own narrower set (see §2).

## 3.5 Toolchain files

`cmake/toolchains/mingw-w64.cmake` — `CMAKE_SYSTEM_NAME Windows`, `PROCESSOR x86_64`; prefers
`x86_64-w64-mingw32-*`, falls back to `i686-w64-mingw32-*` (`:16-26`);
`CMAKE_FIND_ROOT_PATH /usr/${triple}`, `PROGRAM NEVER`, `LIBRARY/INCLUDE/PACKAGE ONLY` (`:28-32`).
Usage documented in its own header (`:3-11`).
`cmake/toolchains/mingw-w64-i686.cmake` — 32-bit, `PROCESSOR x86`; its header (`:3-4`) states it is
*the required target ABI for GLIDE* (Glide 3.x carries the render-window handle in a 32-bit `FxU32`).
No Android or Emscripten toolchain file is vendored; Emscripten goes through `emcmake` or the EMSDK's
own toolchain (the path is spelled out in the error messages at `cmake/RendererSelection.cmake:390-391`).

## 3.6 Presets and CI

`CMakePresets.json` — 5 configure + 5 build presets:

| Preset | Binary dir | Key cache | Build target |
|---|---|---|---|
| `web` | `cmake-build-web` | Release, `WEBGL2`, `CNA_RENDERER_WEBGL2=ON`, tests OFF, examples ON, `EASYGL_BUILD_EXAMPLES/TESTS=OFF` | `cna_house3d_demo` |
| `devices-asan` | `cmake-build-devices-asan` | Debug, `OPENGLES3`, tests ON, **`CNA_DEVICES=ON`**, `-fsanitize=address … -O0` | `CnaTests` |
| `devices-tsan` | `cmake-build-devices-tsan` | same, `-fsanitize=thread … -O1` | `CnaTests` |
| `devices-ubsan` | `cmake-build-devices-ubsan` | same, `-fsanitize=undefined … -O1` | `CnaTests` |
| `tests` | `cmake-build-tests` | **Ninja**, Debug, `OPENGLES3`, tests + examples ON | `CnaTests` |

Two notes the book should carry: the three sanitizer presets pass raw flags in `CMAKE_CXX_FLAGS`/
`CMAKE_EXE_LINKER_FLAGS` rather than using `CNA_SANITIZE` — a redundancy, not a bug; and all three
explicitly require `CNA_DEVICES=ON` because without it the entire surface their own names promise
"compiles out silently" (`CMakePresets.json:23,37,51`).

`CMakePresets.json:65` states the authoritative test-running convention: **run the `CnaTests` binary
directly, not `ctest`** — `ctest` discovers and runs each gtest case as its own short-lived process,
which both spuriously reports every unbuilt display-dependent smoke-test executable as failed and
races tests sharing hardcoded `/tmp` fixture paths.

CI workflows (`.github/workflows/`): `general-tests-ci.yml` (ubuntu-24.04, GCC 14, Xvfb `:99`,
push-triggered, **broken — X3**), `input-ci.yml` (ASan+UBSan matrix via `CNA_SANITIZE`),
`devices-tests.yml` (`cmake --preset devices-ubsan`, plus the strict-XNA-API target),
`htmldom-ci.yml` (emcmake + headless Chromium), `d3d-windows-ci.yml` (windows-latest MSVC, matrix
`DIRECTX11 DIRECTX12 DIRECT2D`), `gdi-windows-ci.yml` (windows-latest MSVC, `GDI`),
`metal-macos-ci.yml` (`METAL`), `32bit-arithmetic-ci.yml`.

## 3.7 Verified build command lines

All checked against the CMake files, toolchains, presets and CI at this SHA. Nothing invented.

```bash
# Submodules — non-recursive is the project's own considered instruction
# (cmake/ThirdPartySDL.cmake:54-60; --recursive measured 6-7x slower for zero benefit)
git submodule update --init

# Linux default (OpenGL ES 3.0 via EasyGL)            README.md:365-366
cmake -S . -B build -DCNA_GRAPHICS_RENDERER=OPENGLES3
cmake --build build --target CNA CnaTests
ctest --test-dir build --output-on-failure

# SDL_Renderer (2D-only)                              README.md:373-374
cmake -S . -B build-sdlrenderer -DCNA_GRAPHICS_RENDERER=SDL_RENDERER
cmake --build build-sdlrenderer --target CNA CnaTests

# System SDL instead of the vendored submodules       README.md:408-409
cmake -S . -B build -DCNA_USE_SYSTEM_SDL=ON -DCNA_GRAPHICS_RENDERER=SDL_RENDERER

# Linux -> Windows cross-compile   README.md:396-399, cmake/toolchains/mingw-w64.cmake:4-7
sudo apt install mingw-w64
cmake -S . -B build-windows \
      -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64.cmake \
      -DCNA_GRAPHICS_RENDERER=SDL_RENDERER
cmake --build build-windows --target CNA CnaTests

# 32-bit Windows — the only ABI GLIDE accepts    cmake/RendererSelection.cmake:358-362
cmake -S . -B build-glide \
      -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64-i686.cmake \
      -DCNA_GRAPHICS_RENDERER=GLIDE

# Web (Emscripten)                                    CMakePresets.json:8
emcmake cmake --preset web
cmake --build --preset web                   # -> cna_house3d_demo

# Native test build (Ninja)                           CMakePresets.json:65
cmake --preset tests
cmake --build --preset tests --target CnaTests
SDL_AUDIODRIVER=dummy ./cmake-build-tests/CnaTests    # authoritative runner, not ctest

# Sanitizers — two supported routes
cmake -S . -B build -DCNA_SANITIZE=address,undefined -DCNA_GRAPHICS_RENDERER=OPENGLES3
cmake --preset devices-ubsan && cmake --build --preset devices-ubsan

# Extension layers (both OFF by default)
cmake -S . -B build -DCNA_CNAEXT=ON -DCNA_DEVICES=ON -DCNA_GRAPHICS_RENDERER=OPENGLES3

# Other renderers                                     README.md:419-420
cmake -S . -B build -DCNA_GRAPHICS_RENDERER=BGFX
cmake -S . -B build -DCNA_GRAPHICS_RENDERER=VULKAN

# Virtual display for the full GPU suite
cmake -S . -B build -DCNA_GRAPHICS_RENDERER=OPENGLES3 -DCNA_TEST_DISPLAY=:99

# Mechanical gates
python3 scripts/check_renderer_identities.py
ctest --test-dir build -R 'ModuleProbe_|ModuleLinkClosure_|RendererIdentityRegistry'
# NB: ModuleLinkClosure_* SKIP (exit 77) under Ninja — use a Makefiles build to exercise them
```

**Never print:** `-DCNA_GRAPHICS_RENDERER=EASYGL` (X3), `-DCNA_GRAPHICS_BACKEND=…`,
`-DCNA_NOXNA=…`, `-DCNA_GRAPHICS_RENDERER=ASCII`,
`DX1..DX8`/`D3D9`/`D3D10`/`D3D11`/`D3D12`/`OPENGLES`/`DX30` as selectors,
`-DCNA_STRICT_XNA_API=ON` (X6), or any `make install` / `find_package(CNA)` flow.

---

# 4. RENDERER SELECTION

`cmake/RendererSelection.cmake`, 870 lines, included from `CMakeLists.txt:123` — **after**
`cna_configure_vendored_sdl()` (so sibling repos can resolve SDL targets) and **before**
`add_subdirectory(modules)`.

**F37 — 46 public identities across three registries that must agree. VERIFIED.**
`cmake/RendererSelection.cmake:16` (the `STRINGS` property),
`modules/core/include/CNA/GraphicsRendererType.hpp:8-148` (46 enumerators),
`scripts/check_renderer_identities.py:20-67` (46-entry `IDENTITIES` table). Enum order
(historically accreted, not alphabetical; the gate pins the exact order):

`SdlRenderer, OpenGLES2, OpenGLES3, OpenGL33, WebGL1, WebGL2, Bgfx, Vulkan, WebGPU, Magnum,
Headless, Software, Stub, DirectX11, DirectX12, Direct2D, Canvas, HtmlDom, Skia, Blend2D,
FreeDirect, DirectX9, DirectX1, DirectX2, DirectX3, DirectX5, DirectX6, DirectX7, DirectX8,
DirectX10, SdlGpu, OpenGLES1, OpenGL4, OpenGL1, OpenGL2, Wicked, Sokol, Diligent, Glide, Gdi, Llgl,
Metal, Fna3d, SvgDom, OpenVg, PortableGL`

There is deliberately **no `DirectX4`** (`docs/RendererNamingMigration.md:74`). The full per-identity
table (enum / selector / compile definition / implementation factory / primary gate) is
`docs/renderer-registry.md:14-60` — the single best source for a book chapter.

**F38 — Two selection surfaces; the booleans win. VERIFIED.**
Primary: `-DCNA_GRAPHICS_RENDERER=<IDENTITY>` (`:15`, cache STRING with a 46-name doc string).
Alternative: 46 `option(CNA_RENDERER_<NAME> "…" OFF)` (`:18-185`). If **any** is ON (detected by the
46-term `if()` at `:188-190`), exactly one must be — otherwise
`FATAL_ERROR "CNA: Exactly one renderer option must be ON when using CNA_RENDERER_* options."`
(`:333-336`) — and its name **overwrites** `CNA_GRAPHICS_RENDERER` (`:338`).
Any unrecognized value falls through to `:867-870`:
`FATAL_ERROR "CNA: Unknown graphics renderer: ${CNA_GRAPHICS_RENDERER}"`.

**F39 — Platform-dependent defaults. VERIFIED.** `:8-14`:

```cmake
if(EMSCRIPTEN)                              set(_cna_default_renderer "WEBGL2")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")  set(_cna_default_renderer "OPENGLES3")
else()                                      set(_cna_default_renderer "SDL_RENDERER")
```

So Windows and macOS both default to `SDL_RENDERER` — matching `README.md:380-382`.

**F40 — Each identity sets exactly four things. VERIFIED.**
The `if/elseif` chain at `:534-870` sets, per identity:

1. `RENDERER_DIR` = `modules/renderers/<family>` (a **path string**, used by nothing but
   documentation and `get_filename_component` at `modules/renderers/CMakeLists.txt:56`),
2. `RENDERER_TARGET` = `cna_renderer_<family>` (the actual STATIC library name),
3. `add_compile_definitions(CNA_RENDERER_<X>)` (directory-scope, for TUs compiled under the root),
4. `CNA_RENDERER_DEFINE` = `"CNA_RENDERER_<X>"`, which `cna_build_flags` re-exports **PUBLIC** to
   every module and every consumer (`modules/CMakeLists.txt:65`).

Canonical example, `:534-539`:

```cmake
if(CNA_GRAPHICS_RENDERER STREQUAL "SDL_RENDERER")
    message(STATUS "CNA: Using SDL_RENDERER graphics renderer")
    set(RENDERER_DIR "modules/renderers/sdl-renderer")
    set(RENDERER_TARGET "cna_renderer_sdl_renderer")
    add_compile_definitions(CNA_RENDERER_SDL_RENDERER)
    set(CNA_RENDERER_DEFINE "CNA_RENDERER_SDL_RENDERER")
```

`modules/renderers/CMakeLists.txt:56` then derives the family directory name from `RENDERER_DIR` and
enters exactly that subdirectory (`:80-82`).

**F41 — The GL family is the one many-to-one case, and `CNA_GL_PROFILE_*` is how it stays honest.
VERIFIED.**
`:546-560`: OPENGLES2 / OPENGLES3 / OPENGL33 / WEBGL1 / WEBGL2 all resolve to
`RENDERER_DIR=modules/renderers/easygl`, `RENDERER_TARGET=cna_renderer_easygl`,
`CNA_RENDERER_DEFINE=CNA_RENDERER_EASYGL` — **plus**
`add_compile_definitions("CNA_GL_PROFILE_${CNA_GRAPHICS_RENDERER}")` (`:560`), yielding one of
`CNA_GL_PROFILE_OPENGLES2`, `_OPENGLES3`, `_OPENGL33`, `_WEBGL1`, `_WEBGL2`.
The comment at `:552-554` records why: existing `#ifdef CNA_RENDERER_EASYGL` guards keep working
unmodified regardless of which of the five public profiles was selected.
The pair is decoded back into the public enum at `GraphicsRendererType.hpp:164-178`, inside a
`constexpr` function:

```cpp
constexpr GraphicsRendererType getCurrentGraphicsRendererType()
#elif defined(CNA_RENDERER_EASYGL)
#if   defined(CNA_GL_PROFILE_OPENGL33)  return GraphicsRendererType::OpenGL33;
#elif defined(CNA_GL_PROFILE_WEBGL1)    return GraphicsRendererType::WebGL1;
#elif defined(CNA_GL_PROFILE_WEBGL2)    return GraphicsRendererType::WebGL2;
#elif defined(CNA_GL_PROFILE_OPENGLES2) return GraphicsRendererType::OpenGLES2;
#else  // CNA_GL_PROFILE_OPENGLES3 (default within CNA_RENDERER_EASYGL)
       return GraphicsRendererType::OpenGLES3;
```

Being `constexpr`, it is usable in a `static_assert` — the header says so at `:156-158`. `EASYGL`
itself is **not** a public identity and is **not** an accepted selector
(`docs/RendererNamingMigration.md:114-117`, `:153`).

**F42 — Platform gates, exhaustively. VERIFIED.**

| Gate | Identities | Kind | Line |
|---|---|---|---|
| `CMAKE_SYSTEM_NAME STREQUAL "Windows"` | DIRECTX1,2,3,5,6,7,8,9,10,11,12, DIRECT2D, GLIDE, GDI | FATAL (suggests the mingw toolchain) | :347-353 |
| `CMAKE_SIZEOF_VOID_P EQUAL 4` | GLIDE | FATAL (suggests mingw-w64-i686) | :358-362 |
| Darwin | METAL | FATAL ("iOS and tvOS remain unvalidated") | :366-369 |
| Linux **or** Windows | OPENGL1 | FATAL | :374-376 |
| Linux/Windows/Darwin | OPENVG | FATAL (ShivaVG needs a real fixed-function GL context) | :383-385 |
| `EMSCRIPTEN` required | CANVAS, HTML_DOM, SVG_DOM | FATAL (each spells out the EMSDK toolchain path) | :387-409 |
| `EMSCRIPTEN` required | WEBGL1, WEBGL2 | FATAL | :439-445 |
| `EMSCRIPTEN` forbidden | OPENGLES2, OPENGLES3, OPENGL33 | FATAL ("use WEBGL1 or WEBGL2 instead") | :433-438 |
| `EMSCRIPTEN` forbidden | MAGNUM | FATAL (no standalone WebGL loader) | :416-421 |
| `EMSCRIPTEN` forbidden | WICKED | FATAL (no WebGPU/WebGL device) | :493-497 |
| Linux-preferred | OPENGLES2/3 off-Linux | **WARNING** | :446-449 |
| Linux-preferred | BGFX off-Linux | **WARNING** | :485-487 |
| Linux/Windows preferred | WICKED elsewhere | **WARNING** | :498-500 |
| Side effect | METAL | `enable_language(OBJCXX)` | :770 |

**F43 — Sub-selectors that are *not* identities. VERIFIED.**

- **`CNA_SOKOL_API`** (`:509-510`, default `GLCORE`, STRINGS `GLCORE GLES3 DIRECTX11 METAL WGPU`) →
  `CNA_SOKOL_API_DEFINE` = `SOKOL_GLCORE` / `SOKOL_GLES3` / `SOKOL_D3D11` / `SOKOL_METAL` /
  `SOKOL_WGPU` (`:512-524`). Anything but `GLCORE` emits a WARNING that it is *"wired but
  unverified"* and that `SokolRenderer` creates its context through `SDL_GL_CreateContext`, which
  only serves GL APIs (`:525-531`). **Internal inconsistency — see X9.**
- **`CNA_SKIA_MODE`** (`:672-674`, default `RASTER`, STRINGS `RASTER GANESH`). `:666-671` states the
  doctrine plainly: *"CNA_SKIA_MODE is a sub-selector of CNA_GRAPHICS_RENDERER=SKIA, not a separate
  renderer identity"* — two mutually exclusive GN builds of the same pinned Skia checkout, never
  linked together. GANESH adds `CNA_SKIA_MODE_GANESH` and links `CNA::SkiaGanesh`; RASTER links
  `CNA::Skia` (`:681-692`).

**F44 — What `scripts/check_renderer_identities.py` pins. VERIFIED.**
It parses two registries and compares both to a hardcoded 46-entry `(cmake selector, enum name)`
table:

- `enum_identities()` (`:70-77`) reads `modules/core/include/CNA/GraphicsRendererType.hpp`,
  regex-matches `enum class GraphicsRendererType\s*\{(.*?)\n\s*\};`, strips `/* */` and `//`
  comments, and extracts identifiers.
- `cmake_identities()` (`:80-88`) reads `cmake/RendererSelection.cmake` and regex-matches the single
  `set_property(CACHE CNA_GRAPHICS_RENDERER PROPERTY STRINGS …)` block.

**The enum comparison is order-sensitive** (`:97` — `if actual_enum != expected_enum`). The CMake
comparison is a **sorted-set** comparison plus a length check (`:106`), because *"The STRINGS
property is a UI list — its member SET is the identity registry, its ordering is cosmetic (and has
historically differed from the enum's order)"* (`:103-104`).
Exit 0 / 1. Registered as ctest `RendererIdentityRegistry` (`cmake/Tests/ModuleProbes.cmake:153-155`);
**no CI workflow invokes it directly.**

Consequence: **any addition, removal or rename of a public identity fails this gate until the table —
and therefore the documented public count — is deliberately updated** (`:6-9`). That is the mechanism
that makes the 46 figure trustworthy, and it is exactly what caught the integration defect the HEAD
commit fixed (`GraphicsRendererTypeTests.cpp`'s cardinality `static_assert` still read 42 because
"each lane carried its own count, and the last one merged won the line").

---

# 5. TERMINOLOGY

**F45 — The migration chain, all on 2026-08-10. VERIFIED.**

| SHA | Time | Effect |
|---|---|---|
| `57aee5f88` | 14:20 | **graphics `backend` → `renderer`**: `GraphicsBackendType`→`GraphicsRendererType`, `IGraphicsBackend`→`IGraphicsRenderer`, `CNA/Internal/Backends`→`CNA/Internal/Renderers` (paths *and* namespaces), `CNA_GRAPHICS_BACKEND`→`CNA_GRAPHICS_RENDERER`, `CNA_BACKEND_*`→`CNA_RENDERER_*`, `cmake/BackendSelection.cmake`→`cmake/RendererSelection.cmake`, `docs/<x>-backend.md`→`docs/<x>-renderer.md` |
| `8c61cea95` | 14:30 | `DX1..DX8`→`DIRECTX1..DIRECTX8`; `D3D9/10/11/12`→`DIRECTX9/10/11/12`; module dirs likewise |
| `7d227dd7a` | 14:31 | `OPENGLES`→`OPENGLES3`, reserving the `OPENGLES2` name (since realized) |
| `2ecbca579` | 14:40 | `NOXNA`→`CNAEXT`; `CNA_NOXNA`→`CNA_CNAEXT`; `cna_noxna`/`CNA::NoXna`→`cna_cnaext`/`CNA::CnaExt`; `NOXNA.md`→`CNAEXT.md`; `modules/input/src/NoXna/`→`src/CnaExt/`; `probe_noxna`→`probe_cnaext`; `noxna_settings_example.cpp`→`cnaext_settings_example.cpp` |
| `5a6a83de0` | 14:53 | fixup: **restored history-describing sentences** the mechanical DX3 flip had wrongly rewritten — establishing the project rule that historical prose keeps old spellings |
| `5d612f170` | 15:34 | fixup: bare `D3D9::`/`D3D1x::` namespace qualifiers; `examples/dx<N>_*`→`examples/directx<N>_*` |
| `a68bad741` | 15:49 | added `docs/RendererNamingMigration.md` + `modularization/renderer-naming/VALIDATION.md` |

`docs/RendererNamingMigration.md` is the authoritative old→new mapping; §1 (`:24-38`) is the
terminology table, §2 (`:60-102`) the DirectX identity table, §3 (`:104-117`) OPENGLES→OPENGLES3,
§4 (`:119-137`) NOXNA→CNAEXT, §6 (`:156-165`) the consumer migration summary. **§5 is a frozen
snapshot and must not be cited as the registry (X7).**

**F46 — The current canonical rule, stated precisely. VERIFIED.**
`docs/RendererNamingMigration.md:21-22` defines the scope boundary exactly:

> *"CNA's own graphics subsystem now uses **renderer** wherever 'backend' used to mean a CNA graphics
> renderer implementation."*

**Graphics → always "renderer".** `IGraphicsBackend` has **zero** occurrences under `modules/`.
`modules/graphics/` has **zero** word-boundary `backend` lines (one test name aside). Current
contract names, all in `modules/graphics/include/CNA/Internal/Renderers/Common/IGraphicsRenderer.hpp`:
`IVertexBufferRenderer` (:94), `IIndexBufferRenderer` (:150), `IOcclusionQueryRenderer` (:183),
`ITextureCubeRenderer` (:201), `ITextureRenderer` (:366),
`IRenderTargetRenderer : public ITextureRenderer` (:430),
`IRenderTargetCubeRenderer : public ITextureCubeRenderer` (:482), `IEffectRenderer` (:652),
`ISpriteBatchRenderer` (:704), `IGraphicsRenderer` (:1322), `struct GraphicsRendererCreateArgs`
(:2015), `CreateGraphicsRenderer(...)` (:2078). Forward-declared at `GraphicsDevice.hpp:63`, stored
at `:1107`. XNA-facing accessors, all `CNAEXT`: `GetRenderer()` (:986), `GetGraphicsRendererType()`
(:989), `GetGraphicsRendererName()` (:1003).

**Input, devices, devices-ext, net → "backend" is the live, correct term**
(`docs/RendererNamingMigration.md:42-46` sanctions it explicitly). Word-boundary `backend` census
over `modules/` = **401 lines**: devices 191, devices-ext 100, input 82, audio 17, gamer-services 4,
media 3, net 2, runtime 1, renderers 1, **graphics 0**. Identifier-level (comments/strings stripped):
**1361 occurrences of 163 distinct identifiers** — devices 463/57, input 410/55, devices-ext 239/34,
net 166/2, renderers 80/12.
Live examples: `modules/input/include/CNA/Internal/Input/SdlGamepadBackend.hpp`
(`ISdlGamepadBackend`, `RealSdlGamepadBackend`), `SdlHapticBackend.hpp`, `SdlJoystickBackend.hpp`,
`SystemKeyboardBackend.hpp`, `SystemMouseBackend.hpp`, `SystemPowerBackend.hpp`,
`SystemSensorBackend.hpp`, `SystemDeviceBackend.hpp`;
`modules/devices/include/Microsoft/Devices/Sensors/Detail/AndroidMotionBackend.hpp:55`,
`AndroidCompassBackend.hpp:42`, `Microsoft/Devices/Detail/SdlHapticVibrateBackend.hpp:44`;
`modules/devices-ext/include/CNA/Devices/Detail/{SdlTrayBackend,SdlCameraBackend,SdlFileDialogBackend,SdlMessageBoxBackend}.hpp`;
`ENetBackend` (net).

**"Audio backend" is prose only — there is no audio backend interface.**
`modules/audio/include/Microsoft/Xna/Framework/Audio/AudioEngine.hpp:50`: *"CNA has a single backend
(SDL3_mixer), so …"*. The only `Backend` identifiers in `modules/audio` are two test names.

**Third-party vocabulary is retained verbatim** (`docs/RendererNamingMigration.md:47-50`): sokol
`sg_query_backend`/`SG_BACKEND_*`; Skia
`GrBackendRenderTarget`/`GrBackendSurface`/`SkSurfaces::WrapBackendRenderTarget`; bgfx
`bgfx::RendererType::*` including its `OpenGLES` value and name string. Similarly, native Microsoft
vocabulary is retained inside the D3D families (`:82-102`): `cna_renderer_d3dcommon` / namespace
`D3DCommon`; every class wrapping a real Direct3D object keeps its `D3D<N>` prefix (`D3D11Buffers`,
`D3D11SamplerCache`, `D3D12PipelineStateCache`, `D3D12ResourceStateTracker`, `D3D9EffectRenderer`,
…) — **only the renderer identity class and the selection surface flipped to `DirectX<N>`**. In
DX1..DX8 all `Dx<N>*` identifiers flipped, because `Dx<N>` never named a native API. Plan-ledger task
IDs (`DX2-46`, `D9-23`, …) are preserved verbatim.

**Historical prose keeps old spellings** (`docs/RendererNamingMigration.md:51-54`, and the reason
`5a6a83de0` exists): `audit/`, `modularization/` records, `plan_*.md`/`NEXT*.md` ledgers, spike
directories, and `BackendLibraries.cmake` references describing the pre-Phase-3 build are all
deliberately untouched.

**No compatibility aliases exist anywhere** (`docs/RendererNamingMigration.md:165`). Old spellings
are not merely dated — they are **uncompilable**.

**F47 — Two genuine leftovers in the graphics-renderer tree. VERIFIED.**
`modules/renderers/skia/include/CNA/Internal/Renderers/Skia/SkiaMeshEffectRenderer.hpp:160` —
`boundTextureBackends_` (element type is already `ITextureRenderer`);
`modules/renderers/headless/examples/headless_resource_renderers_test.cpp:54` —
`class HeadlessResourceBackendsTest`. Both private/example-local.
`modularization/renderer-naming/VALIDATION.md:44-46` correctly claims zero *compound* tokens
(`GraphicsBackend`, `CNA_BACKEND_`, `cna_backend_graphics`, `GRAPHICS_BACKEND`); an unqualified "zero
`Backend` identifiers remain in graphics" would overstate it by exactly two.

**F48 — No lint enforces the terminology. STRONG.** No script in `scripts/`, no test, and no CI
workflow greps for forbidden words. `modularization/renderer-naming/tools/` holds the one-shot
campaign engine and rename maps, not a standing gate. The renderer *identity* registry (F44) is
enforced; the *vocabulary* is not.

**F49 — The book's vocabulary, in one paragraph.**

> A **renderer** is a CNA graphics implementation — one of 46 public identities, implemented by one
> of 42 families under `modules/renderers/`, selected at configure time by `CNA_GRAPHICS_RENDERER`,
> and reached through `CNA::Internal::Renderers::IGraphicsRenderer`. A **backend** is a
> platform-service implementation in the input, devices, or net subsystems — `SdlGamepadBackend`,
> `AndroidCompassBackend`, `SdlTrayBackend`, `ENetBackend`. A renderer may itself dispatch onto
> several native APIs (Diligent, LLGL, sokol, bgfx, FNA3D, Wicked); CNA neither names nor counts
> those. Third-party vocabulary (`GrBackendRenderTarget`, `sg_query_backend`, `bgfx::RendererType`)
> is quoted as the upstream spells it. `ASCII`, `EASYGL`, `DX3`, `D3D11`, `NOXNA` and
> `CNA_GRAPHICS_BACKEND` appear in this book only when narrating history.

---

# 6. CONTRADICTIONS

**X1 — "No `.xnb` reader, by design" is FALSE. Highest severity — this is exactly the failure mode
the book already corrected once.**

*Docs side:* `README.md:26` — *"the real gap is `.Content` (4/12 — **no `.xnb` reader, by design**)"*;
`README.md:27` — *"**no `.xnb` content pipeline** (CNA loads raw assets + JSON descriptors
instead)"*; `README.md:628` — *"Consider a real `.xnb` content-pipeline reader (currently a
deliberate design choice, not a bug…)"*.

*Code side:* `modules/content/src/Xnb/` contains **16 TUs**: `LzxDecoder.cpp` (a real LZX
decompressor), `XnbDecompression.cpp`, `XnbBuiltInReaders.cpp`, and
`Texture2D`/`Texture3D`/`TextureCube`/`SpriteFont`/`SoundEffect`/`Song`/`Video`/`Model`/`StockEffect`/`Curve`/`Math`/`Primitive`/`DecimalDateTime`
`ContentTypeReader(s).cpp`. `modules/content/include/CNA/Internal/Xnb/` holds the matching 22-header
tree (`XnbHeader.hpp`, `XnbTypeName.hpp`, `XnbTypeReaderTable.hpp`, `XnbReadLimits.hpp`,
`XnbArithmetic.hpp`, `CollectionContentTypeReaders.hpp`, …). It is wired into `ContentManager`:
`modules/content/src/Xna/ContentManager.cpp:10`
(`#include "CNA/Internal/Xnb/XnbTypeReaderTable.hpp"`), `:145` `ScanXnbReaderNames()`, `:166`
`ParseXnbHeader()`, `:168` compression check, `:181` `ParseXnbTypeReaderTable()`, `:233-236`
`if (ext == ".xnb") { entry.hasXnb = true; … }`, `:266` `GetXnbReaderUsageSummary()`. Dedicated
tests:
`modules/content/tests/CNA/Internal/Xnb/{XnbHeader,XnbTypeReaderTable,XnbTypeName,XnbBuiltInReaderRegistration,XnbArithmetic,XnbContainerFuzz}Tests.cpp`
plus `ContentManagerSoundEffectXnbTests.cpp`. Fixtures at `tests/assets/xnb/monogame/`.

*Third source:* `xnb.md:1-33` — *"**Status: 🔄 PARTIALLY UN-FROZEN 2026-07-16 — MVP scope complete,
Phase D (LZX) fully complete, Phase E (`SpriteFont`, stock effects, `SoundEffect`/`Song`,
`ReadExternalReference<T>()`) fully complete**… `ContentManager`'s resolution order now ranks `.xnb`
**above** both the literal caller-given path and `.cnj`."* Out of scope per `:20-33`: `Model` reading
(Phase D3/F), the hardening pass, Lua-scripted custom readers (*"rejected outright, not merely
deferred"*), and **writing** `.xnb` (*"remains permanently out of scope"*). `xnb.md:36-37` *itself*
still carries a superseded *"planning document only. Nothing described here is implemented yet"* line
directly beneath the revision note.

> **Conclusion: CNA has a real, runtime `.xnb` reader — container parsing, LZX decompression, and
> readers for `Texture2D`/`SpriteFont`/`SoundEffect`/`Song`/`Video`/stock effects — ranked above
> `.cnj` in `ContentManager`'s resolution order. `Model` reading and `.xnb` writing are out of scope.
> `README.md` is stale in three places.** The book must not repeat the README's framing; re-derive
> any per-reader coverage count from `XnbBuiltInReaders.cpp` before printing it.

**X2 — Renderer-identity count: four different numbers live in the tree at HEAD.**

- **46 (correct):** `README.md:168`, `CLAUDE.md:459`, `docs/renderer-registry.md:4`,
  `docs/physical-modules.md:54`, `FUTURE.md:20`, `modules/renderers/CMakeLists.txt:5`, and all three
  registries.
- **42 (stale):** `scripts/check_renderer_identities.py:4` (*"CNA has exactly 42 public renderer
  identities"*) and `:19` (*"42 entries"*) — while the table beneath has 46 and `:113` prints
  `len(IDENTITIES)`; `cmake/Tests/ModuleProbes.cmake:6`; `docs/svg-dom-renderer.md:233`, which even
  quotes fabricated output: *"✅ `OK: 42 public renderer identities preserved in both registries`"*.
- **41 (stale):** `MODULARIZATION_PLAN.md:68,216,338,374,418,945`; `NEXT.md:481`;
  `plan_gltf.md:203`; `modularization/renderer-naming/VALIDATION.md:10`.
- **41→42 with `ASCII` still listed (stale):** `docs/RendererNamingMigration.md:141-149`.

> **Conclusion: 46 is correct; the gate is functionally right and only its prose is wrong. 42 is the
> number of implementation *families*, not identities — that proximity is what makes the confusion
> self-perpetuating. The book must always print "46 identities / 42 families", labelled, and must
> never cite the four stale sources for a count.**

**X3 — A push-triggered CI workflow cannot configure at HEAD. VERIFIED.**
`.github/workflows/general-tests-ci.yml:133` passes `-DCNA_GRAPHICS_RENDERER=EASYGL`. `EASYGL` is not
in the 46-name `STRINGS` list (`cmake/RendererSelection.cmake:16`) and has no `elseif` arm, so it
reaches `:869` — `FATAL_ERROR "CNA: Unknown graphics renderer: EASYGL"`. The workflow triggers on
every push (`:43-47`, `paths-ignore` only excludes `**.md` and `docs/**`). `57aee5f88` touched this
file but did not update the value; `docs/RendererNamingMigration.md:153` explicitly says the old
selectors *"are rejected as unknown"*.

> **Conclusion: a genuine, unfixed defect at the pinned SHA. Do not reproduce this command line.**

**X4 — README's submodule instruction contradicts the CMake error message it quotes.**
*README side:* `README.md:349,364,372,384,395,455,482,511` all say
`git submodule update --init --recursive`; `README.md:357-358` *quotes* the CMake error as ending
`Run: git submodule update --init --recursive`. `CMakePresets.json:65` also says `--recursive`.
*CMake side:* `cmake/ThirdPartySDL.cmake:54-60` actually says `Run: git submodule update --init` and
adds *"(non-recursive — this project's CMAKE_ARGS below disable every optional codec dependency under
SDL_image's/SDL_mixer's own nested submodules, so --recursive only adds a much slower, unnecessary
fetch)"*. `:46-53` records the measurement: `--recursive` also pulls ~19 nested codec submodules
(AVIF, JXL, WebP, libpng, GME, mod_xmp, mpg123, FluidSynth-MIDI, Opus, Vorbis, …), none of which the
project's own `SDLIMAGE_*`/`SDLMIXER_*` args enable, and cloning them measured **6–7× slower**.

> **Conclusion: the non-recursive form is the project's own considered instruction, and the README's
> quotation of the error text is now inaccurate. The book should print `git submodule update --init`.**

**X5 — `docs/graphics-resource-lifetime.md` mis-states the ownership model.**
*Doc side:* `:10-12` — *"Every GPU-backed resource holds a `std::unique_ptr<IXxxRenderer>` …
Ownership is **exclusive**: only one `GraphicsResource` object at a time owns the underlying GPU
handle."* The `:38-43` table describes `Texture2D` as `renderer_.reset()`. The word `shared_ptr`
appears **zero times** in the document.
*Code side:* `Texture2D.hpp:588`, `Texture3D.hpp:212`, `TextureCube.hpp:193` all use
`std::shared_ptr`, deliberately, because those classes keep copy construction/assignment `= default`
(`Texture2D.hpp:96-100`) to preserve C# reference-type semantics.

> **Conclusion: the doc is stale for the three texture classes and correct for buffers/SpriteBatch.
> `reset()` still compiles for a `shared_ptr`, but drops rather than destroys when copies exist — a
> materially different lifetime. The book should present the rule as buffers-unique / textures-shared
> and explain why (F17).**

**X6 — `README.md:58` mis-describes the CNAEXT purity check on three counts.**
*README side:* *"a compile-time `CNAEXT` purity check (**a dedicated CMake build option** that turns
every non-XNA-tagged declaration into a `[[deprecated]]` warning under `-Werror`) — see
`CHECKLIST.md`'s 'CNAEXT markers' section and **`CMakeLists.txt`**"*.
*Code side:* (1) `CNA_STRICT_XNA_API` is never declared via `option()` — a user cannot pass
`-DCNA_STRICT_XNA_API=ON` for a project-wide strict build; (2) it lives in
`cmake/Harnesses.cmake:183,224`, not `CMakeLists.txt`; (3) it tags every **CNAEXT-tagged** (i.e.
non-XNA) declaration, and its practical reach is the `Microsoft::Devices`/`Sensors` surface the two
`tools/devices/*.cpp` files exercise (`Harnesses.cmake:170-172`), not the whole API. It is also
skipped under MSVC (`:178`).

> **Conclusion: prefer `CNAEXT.md:29`'s accurate wording ("optionally `[[deprecated]]` under the
> strict-API check"). Describe the mechanism as a two-target compile gate, not a build option.**

**X7 — `docs/RendererNamingMigration.md` §5 is a frozen snapshot presented as a registry.**
`:141-149` lists 41 identities **including `ASCII`** and says *"bringing the live count to 42."*
`ASCII` was removed by `ea31cabc1` (2026-08-11, "refactor(renderers): remove ascii renderer identity"
— 39 files, −1308 lines, deleting `modules/renderers/ascii/` entirely, migrating the
quantizer/font-atlas logic to `CNA::Graphics::AsciiPostProcessEffect` in `modules/graphics-ext/`),
and five identities were added.

> **Conclusion: §1–§4 and §6 of that document are the best old→new mapping in the repo and should be
> cited freely. §5 must never be cited as the registry — use `docs/renderer-registry.md`.**

**X8 — `MODULARIZATION_PLAN.md` vs HEAD, on five points.**

- `:942-943` claims *"14 framework modules … 38 renderer families plus common/d3d"*. Framework count
  **matches exactly**; renderer count is now **42** (`modules/CMakeLists.txt:156-162`).
- `:180`, `:845-846`, `:964` name `cna_noxna`/`CNA::NoXna`, `probe_noxna`,
  `ModuleLinkClosure_NoXnaComposition` — none exist at HEAD (`cna_cnaext`/`CNA::CnaExt`,
  `probe_cnaext`, `ModuleLinkClosure_CnaExtComposition`). A `:961-966` "PROVEN" list reads as
  current-state evidence while naming tests that no longer exist under those names.
- `:819`, `:942` state the module contract as `{CMakeLists.txt, include/, src/, tests/}` —
  `examples/` has since joined (`modules/CMakeLists.txt:151-153,168,173`).
- `:442-447` says flatly *"No file was moved in this campaign"* — true only of Phase 1, and actively
  false as a description of the repository; §9/§11 supersede it 400 lines later.
- The whole document uses `BACKEND_TARGET`/`BACKEND_DIR`/`CNA_BACKEND_*` (`:172,205,219`),
  disclaimed by a naming note at `:3-9`.

Related: `README.md:134-141`'s architecture box shows `include/CNA/Internal/Renderers` and
`src/CNA/Internal/Renderers/{SdlRenderer,EasyGL,Vulkan,Skia}` — namespace-relative, not
repo-relative, paths.

> **Conclusion: `docs/physical-modules.md` is the accurate current-state architecture document;
> `MODULARIZATION_PLAN.md` is a campaign narrative. Cite the former for architecture, the latter only
> for history. Cite `CLAUDE.md:183-199` (not `README.md:134-141`) for the physical layer table.**

**X9 — `CNA_SOKOL_API` disagrees with itself inside one file.**
`cmake/RendererSelection.cmake:509` doc-string says `"(GLCORE, GLES3, D3D11, METAL, WGPU)"`; `:510`
`STRINGS` says `"GLCORE" "GLES3" "DIRECTX11" "METAL" "WGPU"`; `:516` compares against `"DIRECTX11"`;
`:523`'s error text says `"(expected GLCORE, GLES3, D3D11, METAL, or WGPU)"`.

> **Conclusion: the accepted value is `DIRECTX11`. Two of the three doc strings are wrong. This is
> the D3D→DIRECTX rename (`8c61cea95`) reaching the STRINGS list and the comparison but not the
> prose.**

**X10 — `CLAUDE.md:165` vs the code's actual disposal guard.**
*Guideline side:* *"Always check `isDisposed_` before acting; **throw `std::runtime_error`** if used
after disposal."*
*Code side:* `System::ObjectDisposedException` is thrown 52 times, all in the public XNA API layer,
zero in renderers (F13).

> **Conclusion: the code is the more XNA-faithful of the two; the guideline is stale. The book should
> document `ObjectDisposedException` as the use-after-dispose contract.**

**X11 — XNA-native exception base classes split across two roots, undocumented.**
`Audio`/`GamerServices`/`Net`/`Sensors` exceptions derive from `System::Exception`; `Graphics`'s
`DeviceLostException`/`DeviceNotResetException`/`NoSuitableGraphicsDeviceException` and `Content`'s
`ContentLoadException` derive from **`std::runtime_error`** (F12). In real XNA all four descend from
`System.Exception`. Not listed in `CHECKLIST.md`'s deliberate-deviations table.

> **Conclusion: reads as drift, not decision. VERIFIED for the code; UNCERTAIN whether intentional.
> Worth a footnote, not a chapter.**

**X12 — `docs/` document count: three different numbers.**
`README.md:20` says 93; `docs/README.md:3` says 99; `ls docs/*.md` = **152**. `docs/README.md:17`
also still describes the feature matrix as covering *"SDL_Renderer/EasyGL/Vulkan/Bgfx"* — four
renderers, with `EasyGL` presented as a public name.

> **Conclusion: 152. Neither index figure is current, and `docs/README.md`'s own "start here" list
> predates the renderer expansion.**

**X13 — `CNAHelper.hpp`'s doc comment cites a path that does not exist.**
`modules/core/include/CNA/CNAHelper.hpp:18` cites
`tests/Microsoft/Devices/StrictXnaApiSurfaceCheck.cpp`; the real file is
`tools/devices/StrictXnaApiSurfaceCheck.cpp` (`cmake/Harnesses.cmake:180`). Minor, but if the book
quotes the macro's doc comment verbatim, note the drift.

**X14 — `docs/physical-modules.md` ends with a duplicated paste.** Lines 155-159 repeat the 42-family
list verbatim from lines 63-67, dangling under the "Validators" section. Cosmetic, but a book quoting
the file wholesale would inherit it.

**X15 — `README.md:337` vs `README.md:326` on the required standard.** The Windows prerequisite reads
*"MSVC 2022 (v17.8+, with **C++20/23** support)"*, looser than the Linux *"C++23-capable compiler"*.
With `CMAKE_CXX_STANDARD_REQUIRED ON` (`CMakeLists.txt:6`), an MSVC that cannot do C++23 hard-fails
configure regardless.

> **Conclusion: PROBABLE prose imprecision, not a dual-standard policy.**

**X16 — CI parallelism vs the project's own rule.** CNA's `CLAUDE.md:410` says *"Cap build
parallelism at `-j4` in this sandbox"*; `.github/workflows/general-tests-ci.yml:144` uses
`--parallel 4`; the org-level rule in force at this workspace is `-j3`. Relevant only if the book
prints a recommended build line — it should not print a `-j` value at all.

---

# 7. BOOK IMPACT

## 7.1 The scale of the problem, measured

The current book was written against pre-2026-08 CNA and does not know that either the modularization
or the rename happened. Counts over `latex/book/**/*.tex`:

| Signal | Count |
|---|---:|
| `modules/` (any path) | **0** |
| literal "backend" | **1769** |
| `NOXNA` | 198 |
| `D3D9` / `D3D11` / `D3D12` | 219 / 140 / 131 |
| `ASCII` | 89 |
| `EASYGL` | 68 |
| `DX3` | 57 |
| `IGraphicsBackend` | 31 |
| `GraphicsBackendType` | 10 |
| `CNA_GRAPHICS_BACKEND` | 9 (7 inside copy-pasteable `cmake -S . -B …` blocks) |
| `BackendSelection` / `BackendLibraries` / `cmake/Examples.cmake` | 6 / 1 / 1 |
| `sharp-runtime` | 100 |

Structural fossils in filenames: Part IV is `chapters/part4-backends/` containing
`ch16-backend-architecture.tex`, `ch17-sdl-renderer.tex`, `ch18-easygl-backend.tex`,
`ch19-vulkan-backend.tex`, `ch20-bgfx-backend.tex`, `ch21-webgpu-backend.tex`,
`ch22-sdlgpu-backend.tex`, `ch23-direct3d-backends.tex`, `ch24-canvas-ascii-backends.tex`,
`ch25-dx3-freedirect-backend.tex`; plus `chapters/appendices/appendix-e-noxna-catalog.tex`.

**Every build command in the book is uncompilable, on two counts each.**
`chapters/part2-getting-started/ch04-building-cna.tex:37` reads
`cmake -S . -B build -DCNA_GRAPHICS_BACKEND=EASYGL` — the option name no longer exists *and* `EASYGL`
is no longer a value. Same defect at `:47`, `:147`, `:162`, `:216` (`=CANVAS`), `:242`;
`chapters/part8-crossplatform/ch39-windows-wine.tex:25`;
`chapters/part8-crossplatform/ch40-web-emscripten.tex:69,71`.
`chapters/part1-ecosystem/ch02-ecosystem-map.tex:40`,
`chapters/part4-backends/ch16-backend-architecture.tex:2201,2226` and
`chapters/appendices/appendix-c-glossary.tex:126` cite `cmake/BackendSelection.cmake` and
`cmake/BackendLibraries.cmake`, both deleted (`57aee5f88`, `33088cba6`).
`appendix-d-repo-map.tex:18` describes easy-gl as backing "the EASYGL backend" and free-direct as
backing "DX3" — both names are now wrong in both halves.

## 7.2 Recommended Part / chapter structure for this area

**Part I — What CNA is** (rewrite ch01–ch03)

1. **CNA and XNA 4.0.** The model; FNA as the behavioral authority with real XNA 4.0 as tie-breaker
   and Avatar as the one decompiled-assembly exception (F3); what "compatible" means — the F4
   formulation, with the `getXProperty()`/`setXProperty()` rewrite shown as the first code sample a
   porter will meet; honest coverage numbers with the two metrics distinguished (F5); the real gaps
   **re-derived, not copied from README** (X1). State up front that "CNA" is never expanded (F2).
2. **The vocabulary of this book.** A dedicated early section, not a glossary entry. State F49 once
   and hold it for 400 pages. Include the old→new table from `docs/RendererNamingMigration.md:24-38`
   explicitly labelled *historical*, and note that **no compatibility aliases exist** — old spellings
   do not merely look dated, they fail to compile.
3. **Language and conventions.** C++23 as dialect, C++17/20 as idiom, with the zero-features census
   (F6) stated plainly so no reader expects `std::expected` or concepts; the five-root namespace map
   (F7) including `SharpRuntime::` and the mandated type aliases; the exception model and its layer
   split (F12–F14); ownership (F17–F18); `CNAEXT` as a two-meaning marker (F8–F10) with its
   positive/negative enforcement harness (F11).

**Part II — The module system** (entirely new; the book has zero coverage)

4. **The module monorepo.** `modules/<name>/{CMakeLists.txt,include,src,tests,examples}`; the 14
   framework targets (§2's table); `cna_add_module()`; the one-PUBLIC-include-root rule; and the
   reassurance that consumer `#include` spelling did not change.
5. **Cycles, umbrellas and boundaries.** The three declared cycles and why each is XNA semantics
   rather than a design smell (F26); the three umbrellas (F25); `cna_core_headers` as the
   headers-only escape hatch that keeps math and storage closures exact.
6. **How the layout is enforced.** The source-partition validator and the legacy-root guard (F29);
   the 14 probes and their forbid regexes (F30), with the storage `(?!storage)` and devices-ext
   `libcna_devices\.` cases as the two worked examples; the honest caveat that these gates **skip
   under Ninja** (F31); the include-reachability and header-self-containment tools (F32).
7. **How it got this way.** The 1776-file seven-pure-rename campaign and its 1357→1357 no-loss
   reconciliation (F34); the two follow-on campaigns routinely conflated with it (F35); the one
   documented ownership exception (F28).

**Part III — The build system** (replaces ch04)

8. **Configuring CNA.** CMake ≥ 3.20, the compiler matrix (§3.1), the full option table with defaults
   and effects (§3.2), and the verified command lines from §3.7 verbatim.
9. **Where dependencies come from.** The five acquisition mechanisms (§3.3); the configure-time SDL
   build into a persistent prefix, which is genuinely unusual and deserves its own section; the
   FFmpeg gate that changes *which files compile*; the sibling-repo contract (§3.4); the
   sharp-runtime component seam. **State plainly that CNA has no install, export or package step**
   (§3.1) — an absence a reader will otherwise assume away.
10. **Tests and examples.** One `CnaTests` corpus with its glob and four mechanical exclusions;
    module-local registration; the gating flags; and the presets file's own warning that `ctest` is
    not the authoritative runner (§3.6).

**Part IV — Renderers** (rename the directory and every chapter file)

11. **The renderer selection mechanism.** `CNA_GRAPHICS_RENDERER` →
    `RENDERER_DIR`/`RENDERER_TARGET`/`CNA_RENDERER_*`/`CNA_RENDERER_DEFINE` (F40); the boolean
    alternative and its exactly-one rule (F38); the platform-gate table (F42); the identity registry
    gate and what makes it order-sensitive on one side and set-based on the other (F44).
12. **Identity vs implementation.** **46 identities, 42 families**; the EasyGL five-to-one case and
    `CNA_GL_PROFILE_*` with the `constexpr` decoder (F41); sub-selectors that are not identities
    (F43); and the doctrine that a renderer's *own* internal backends — Diligent, LLGL, FNA3D, sokol,
    bgfx, Wicked — are not CNA identities (`docs/renderer-registry.md:8-10`).
13. …then the per-family chapters. **`ch24-canvas-ascii-backends` must lose ASCII entirely**
    (migrated to `CNA::Graphics::AsciiPostProcessEffect` in `modules/graphics-ext/`; see
    `docs/ascii-post-process-effect.md`, and `docs/ascii-renderer.md:1-11` which is now explicitly
    marked historical). **`ch25-dx3-freedirect-backend` must split**: `FREEDIRECT` is the
    free-direct-backed identity, and `DIRECTX3` is now a *different, genuine* DirectX 3 renderer
    (DirectDraw v2 + Direct3D v2 DrawPrimitive). Six families have no chapter at all today:
    `BLEND2D`, `FNA3D`, `SVG_DOM`, `OPENVG`, `PORTABLEGL`, `OPENGLES2`.

`appendix-e-noxna-catalog.tex` → `appendix-e-cnaext-catalog.tex`, rebuilt from the two-meanings
framing (F10) rather than a flat list — the current appendix cannot be mechanically renamed, because
it conflates the marker with the engine layer.

## 7.3 Chapters likely stale beyond this area's scope

`appendix-d-repo-map.tex:18` (easy-gl "backs the EASYGL backend", free-direct "backs DX3"),
`appendix-b-feature-matrix.tex` (per-renderer matrix predating six identities),
`appendix-c-glossary.tex:126` (defines a term by reference to a deleted CMake file),
`ch02-ecosystem-map.tex` (reads sibling build config that has since moved),
`ch47-project-practice.tex` / `ch48-testing-philosophy.tex` (both describe the pre-module test
layout). Not audited here, but flagged by the same greps.

## 7.4 Research debts before the book prints numbers

1. **Re-derive the `.xnb` and `.fx` gap statements from code**, not from `README.md` (X1). The `.xnb`
   claim is demonstrably wrong; the `.fx` claim was not audited here and deserves the same treatment
   before reuse.
2. **Always print "46 identities / 42 families" together**, and never cite
   `scripts/check_renderer_identities.py`'s docstring, `cmake/Tests/ModuleProbes.cmake:6`,
   `docs/svg-dom-renderer.md:233`, `MODULARIZATION_PLAN.md`,
   `modularization/renderer-naming/VALIDATION.md`, or `docs/RendererNamingMigration.md` §5 for a
   count (X2, X7).
3. **Re-verify per-renderer capability claims against `docs/graphics-renderer-feature-matrix.md` and
   `NEXT.md` §5**, not against `README.md`'s bullet list or `docs/README.md`'s "start here" section —
   both of which still describe a four-renderer world (X12).
