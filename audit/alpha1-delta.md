# CNA `v0.1.0-alpha.1` bounded delta audit

This is the canonical audit layer for the CNA 0.1.0-alpha.1 edition of *The CNA Bible*.  It does
not replace the 2026-08-11 reports in this directory.  Those reports document the book's previous
technical source; this file records the owner-specified interval and the final tag state.

## Boundary and method

| Item | Immutable value |
|---|---|
| Owner BASE | `ae0be4b5211957efaef60f2f23627ae5a9ddda23` |
| Tag | `v0.1.0-alpha.1` |
| Resolved tag commit | `1bb2145d99ed572dd4eb15009c34e2e5f410fcf0` |
| Annotated tag date | 2026-08-20 19:06:23 +0200 |
| Target commit date | 2026-08-20 19:04:19 +0200 |
| CNA checkout observed during audit | `develop` @ target; clean; HEAD equals tag |
| Immutable source tree | detached worktree `/tmp/cna-v0.1.0-alpha.1` |

`git merge-base --is-ancestor BASE TAG` returned success.  With rename detection raised high
enough for this unusually large interval, `BASE..TAG` contains **1,445 commits** (**215** on the
first-parent chain) and **6,303 changed paths**: 986,325 insertions and 96,348 deletions.  The
previous book pin, `7a64362efef4119bf880459ef1704fb2c52199e2`, is itself a descendant of BASE
and an ancestor of the tag.  Its already-audited portion of the owner interval is therefore not
mislabelled as new alpha.1 work.  The manuscript-sensitive `7a64362e..TAG` discovery window has
1,101 commits, 136 first-parent commits and 3,129 changed paths.

The diff answers what moved; the tag answers what the edition says.  Implementation, CMake,
public headers, generated registries, tests and locally reproduced configuration outrank CNA's
Markdown.  No CNA or sibling tree was edited.

## Material delta matrix

| ID | Area | BASE / previous book state | `v0.1.0-alpha.1` truth | Evidence | Book impact | Confidence |
|---|---|---|---|---|---|---|
| A1-001 | Product release | No tagged version was part of the previous edition's authority. | First tagged release: SemVer `0.1.0-alpha.1`, tag `v0.1.0-alpha.1`; pre-1.0 API may change. Phase/task tracking continues as engineering history. | root `CMakeLists.txt`; `CHANGELOG.md`; `docs/releasing.md`; `Doxyfile`; tag object | Front matter, Preface, Ch.1, Ch.4, Ch.79, Appendix D and records rewritten. | **Source-proven** |
| A1-002 | Version API | No public product-version header. | Configure generates `<CNA/Version.hpp>` with `CNA_VERSION_*`, `CNA::getVersionString()` and prerelease accessors. | `cmake/Version.cmake`; `cmake/templates/Version.hpp.in`; exact-tag configure and C++23 smoke | Verified example added to Ch.4. | **Compile-proven** |
| A1-003 | Renderer registry | Previous edition: 46 identities / 42 families. | **50 identities / 46 implementation families**. New identities/families: IGL, NANOVG, PIXIJS and TINYGL. | `RendererSelection.cmake`; `GraphicsRendererType.hpp`; renderer directories; registry scripts | Preface, Chs.1/4/9/20/21/23/30/31, figures and Appendix B updated. | **Source-proven** |
| A1-004 | Multi-renderer | Previous architecture selected one compiled identity. | Empty `CNA_GRAPHICS_RENDERERS` preserves singular mode; a non-empty compatible set compiles several families, while `CNA_GRAPHICS_RENDERER` remains a required in-set default. Runtime resolution supports explicit request, environment request, default and opt-in fallback. A device latches its resolved renderer. | `RendererDefaultSelection.cmake`; `RendererRegistry.cmake`; `GraphicsRendererSelection.*`; `GraphicsDevice.*`; two CI workflows | Renderer-selection architecture and testing language rewritten; diagram regenerated. | **Source-proven** |
| A1-005 | Platform axis | SDL was described as the common platform layer. | `CNA::Platform::IPlatform` is a separate axis. Implemented selectors are SDL3, SDL2, HEADLESS and POSIX-only TERMINAL. SDL12, WIN32 and EMSCRIPTEN are reserved, not implemented. | `PlatformSelection.cmake`; `modules/platform`; platform tests and workflow | Chs.1/9/61, module/platform figures and Appendix D rewritten. | **Source-proven** |
| A1-006 | Audio axis | SDL3 mixer ownership was treated as inseparable from the host layer. | `CNA_AUDIO_PLATFORM` independently selects SDL3, SDL2 or NULL. The high-level XACT/mixer surface remains available only where its implementation exists. | `AudioPlatformSelection.cmake`; `modules/audio/.../Platform`; tuple gates/tests | Chs.4/45/61 and platform figure updated. | **Source-proven** |
| A1-007 | Compiled effects | Previous book said the bytecode constructor refused arbitrary compiled effects. | The constructor accepts bounded XNA/FNA D3D9 Effect Framework bytecode, with reflection, parameters, techniques, passes, render/sampler state and cloning. FNA3D is the normal route; SDL_GPU, EasyGL and Vulkan are explicit experimental opt-ins. It does **not** compile `.fx`/HLSL source or accept DXBC/MGFX. | `Effect.*`; `EffectReader.*`; common MojoShader/FNA3D effect code; renderer options/tests | Chs.15/17/35/74/79, shader diagram and Appendix A corrected. | **Source-proven** |
| A1-008 | Native C API | Absent from previous edition. | Optional C17 adapter source `cna_c_api` / `CNA::CApi`; 59 public C headers, 2,861 recorded exports, 74 pure-C test sources and 82 CTest registrations. Generated inventory partitions 6,712 canonical declarations as 6,317 implemented, 15 partial, 0 planned and 380 not applicable. The alpha.1 final library does not compile; see A1-016. | `modules/c-api`; `tools/c-api`; CMake; five workflows; local exact-tag build | New Appendix I and reading path; Chs.4/9/73 cross-reference it and label the artifact build-blocked. | **Source-proven / compile-blocked** |
| A1-009 | C ABI version | No native ABI. | Experimental C ABI is version **0.7.0**, independently versioned from product 0.1.0-alpha.1. | `CNA/C/abi.h`; `docs/c-api/ABI_VERSIONING.md`; ABI baseline | Explicit separation throughout build/release/C API prose. | **Source-proven** |
| A1-010 | Physical modules | Fourteen framework/extension modules plus one renderer family. | The new platform module makes 15 framework/extension modules when Net is enabled; C API is an optional separate adapter; renderer aggregate may contain a compatible family set. | `modules/CMakeLists.txt`; ownership validator | Ch.9, module figure and Appendix D updated. | **Source-proven** |
| A1-011 | Public C++ surface | Compile-time renderer/device identity and SDL-facing internals; no general platform contract. | Device identity accessors are runtime answers; renderer selection/category/maturity and fallback records are public CNAEXT surfaces; `Game` exposes platform/capability seams; platform interfaces replace SDL types; effects and glTF/PBR extensions grow. | public-header diff plus implementations/tests | Architecture, effects, platform, content and migration chapters re-audited. | **Source-proven** |
| A1-012 | Tests and CI | 433 candidate sources, older static counts, eight workflows, exclusive single renderer. | 568 candidate C++ test sources; 8,263 lexical GoogleTest definitions; 1,720 renderer registration call sites; 21 workflow files, 19 with push/PR triggers and two dispatch-only. Multi-renderer, platform and C API gates exist. These are definitions, not executed totals. | tag tree counts; `.github/workflows`; `UnitTests.cmake` | Chs.68/69/73 updated without a universal test total. | **Source-proven** |
| A1-013 | Release dependency evidence | Previous technical sharp-runtime audit pin `f827a6c5`. | Release records sharp-runtime `625476d5b5fff5fa89f392c3c9af8638ff237692`; CNA's build does not enforce it and accepts `CNA_SHARP_RUNTIME_ROOT`. | tag annotation; changelog; root CMake | Appendix D keeps technical sibling pin and separately records release evidence. | **Source-proven** |
| A1-014 | Content/glTF | Previous edition described 16 assets, L1--L5, first-group runtime import and open D5--D7. | Runtime retains every represented group in one Model with skin mappings, cameras, variants and structured loss reports; all D1--D8 are fixed. The generated corpus is 148 assets / 744 files; L1--L6 are implemented and four recorded L7 campaigns each classify 140 PNGs + eight safe rejections. Draco 1.5.7 is a pinned default gitlink. | public headers; importer; corpus; conformance CMake/tests; four L7 reports | Chs.38--43, import diagram and Appendix H substantially rewritten; claims remain evidence-layered. | **Source-proven / Historically recorded L7** |
| A1-015 | Version/release verification | No conventional release checklist. | `docs/releasing.md` defines tag/changelog/CMake/Doxygen consistency and states that product version and C ABI version move independently. | release docs and implementation | Project-practice/roadmap language updated; sealed book artifact policy remains separate. | **Source-proven** |
| A1-016 | C API build closure | No native C adapter existed. | With Net enabled, GNU 14.2 compilation stops in `CnaCApiCoreExt.cpp`: 49 C renderer identities versus 50 canonical identities; NanoVG has no C constant/table row. With Net disabled, configure succeeds but compilation stops earlier because the adapter unconditionally includes/links GamerServices and Net targets that were not created. | two local exact-tag HEADLESS/HEADLESS/NULL build probes; CMake target graph; `graphics.h`; `CnaCApiCoreExt.cpp` | Appendix I, Chs.4/9/11/73/79 and defect ledger record the blocked artifact and missing combination gate. | **Compile-proven failure** |

## Public-header delta

The owner interval crosses the physical-module migration.  Restricted to current
`modules/*/include/**` and renderer includes, it therefore presents **823 added header paths**;
**507** remain after excluding paths containing `Internal` or `Detail`.  Path status in that
interval is not a semantic API classification because the pre-migration files lived elsewhere.

For manuscript impact, the semantically useful previous-pin window contains **344** changed
include paths (139 added, 22 deleted, 183 modified).  Excluding `Internal`/`Detail` leaves **183
consumer-facing paths**: 97 added, two deleted and 84 modified.  The two deletions,
`CNA/Entrypoint.hpp` and `CNA/Platform.hpp`, are superseded by the platform module's
`CNA/Platform/Entrypoint.hpp` and platform contract, rather than silently disappearing.

Every consumer-facing path was assigned to one of these declaration-level dispositions:

| Surface group | Path disposition | Declaration / semantic disposition |
|---|---|---|
| Native C API (59 headers) | added | New C17 handles, POD values, result/error model and exported operations; no claim of complete canonical coverage. |
| Platform (27 headers, plus two moved core headers) | added/moved | New interface hierarchy, events, native handle description, capabilities and factory; SDL implementation types leave the framework contract. |
| Runtime renderer selection/core (eight relevant headers) | added/modified | Runtime request/default/fallback records and identity parsing; `GraphicsDevice::GetGraphicsRenderer*` changes from `constexpr` build answer to device answer; shader dialect query added. |
| Audio platform (two new interfaces; public audio comments/signatures reviewed) | added/modified | Playback/recording implementation boundary introduced; XNA-shaped public ownership remains. |
| Game/runtime (four headers) | modified | `Game` owns/exposes platform and cached capabilities; window/device settings use platform handles rather than SDL ownership. |
| Effects (Effect, parameter, pass, technique, ShaderEffect) | modified | Bytecode constructor becomes functional for the bounded compiled-effect format; reflection/state/clone contracts expand; MGFX refusal remains explicit. |
| Graphics/glTF/PBR/model | added/modified | Alpha mode, texture transforms, import report, cameras/lights/material variants and PBR texture/colour-space state added as CNAEXT; existing XNA names were not presented as stock XNA additions. |
| Content | added/modified | Foreign object extension and single-key reader-factory removal added; EffectReader route changed semantically. |
| Input/devices/media | modified | Platform event snapshots and subsystem acquisition replace direct SDL coupling; touched declarations are mostly semantic/lifetime changes, not XNA renames. |
| Renderer public headers | added/modified | New IGL/NanoVG/PixiJS/TinyGL descriptors and targets; existing renderer declarations adjusted to platform and runtime registry contracts. |

No changed public declaration was treated as user-visible solely because its header changed: the
implementation and tests were read for each group.  The high-risk signature changes are the
device renderer identity accessors losing `constexpr`, the new explicit platform-owning `Game`
seam, the moved entrypoint include, and the compiled `Effect` constructor becoming operational.

## Reproduced tag evidence

An exact-tag configure used the release-recorded sharp-runtime commit, graphics HEADLESS,
platform HEADLESS and audio NULL, with tests/examples/Net/C API disabled.  CMake completed under
GNU 14.2, emitted `CNA: version 0.1.0-alpha.1`, and derived 46 renderer families.  A C++23 program
including generated `<CNA/Version.hpp>` compiled, ran and printed `0.1.0-alpha.1`.  This promotes
the version example to **Compile-proven**; it does not promote renderer or CI claims to runtime
evidence.

Two C API builds then exercised the optional target. The detached-tag tree used system SDL and
`CNA_ENABLE_NET=OFF`; configuration completed, but compilation stopped at the adapter's
`GameUpdateRequiredException.hpp` include because GamerServices was never added. A second build
used the ordinary clean checkout after re-verifying that its HEAD exactly equalled the tag, its
initialized submodules, `CNA_ENABLE_NET=ON`, and the same release sharp-runtime. It compiled the
framework and Net closure, then failed the adapter's deliberate static assertion with `(49 ==
50)`: `NANOVG` exists in `GraphicsRendererType` but not the public C constants or mapping table.
These are **Compile-proven failures**. No CNA source was changed to continue past them.

## CNA documentation contradictions at the tag

1. `CHANGELOG.md` says 49 renderer identities; CMake/header registries contain 50.
2. `docs/runtime-renderer-selection.md` refers to 45 factories; the tag has 46 family
   directories excluding common infrastructure.
3. The compiled-effect documentation table omits Vulkan's explicit opt-in route, while CMake and
   implementation contain it.
4. `XnbBuiltInReaders` retains an always-throwing EffectReader comment after the reader became a
   bounded compiled-effect route.
5. C API limitations prose says 6,415 canonical declarations; the generated inventory contains
   6,712.
6. The C API release-gate label still names ABI 0.1.0, while `abi.h` and the ABI baseline name
   0.7.0.
7. The general and two Input workflow legs still select `EASYGL`, which is a family name rather
   than an accepted public renderer identity, so those configurations fail before compilation.
8. `CHANGELOG.md` reduces Content to the absence of a general `.xnb` pipeline route, while the
   implementation contains a substantial XNB container/object graph and registered reader set;
   the narrower missing-pipeline statement must not be read as ``CNA cannot load XNB.''
9. The release summary's XNA surface and Media-shell counts are historical/methodology-limited
   snapshots, not generated tag invariants. The tag contains implemented Media paths and
   host-gated FFmpeg composition that a single ``shell count'' does not describe.
10. `docs/gltf-conformance.md` has current numeric fields but the EasyGL L7 report's justification
    still says 137 renderable assets; the same report's machine fields and disposition array say
    140 captures plus eight rejections.
11. `docs/c-api/RELEASE_GATE.md` reports the experimental ABI ``Ready'' because its aggregate
    checker recognizes gate definitions rather than executing the final library/installed
    consumer. The exact tag's `cna_c_api` target fails its 49-versus-50 renderer invariant.
12. The C API build option and documentation do not state that Net must remain enabled. CMake
    accepts `CNA_BUILD_C_API=ON` with `CNA_ENABLE_NET=OFF`, then fails during compilation on absent
    GamerServices headers/targets instead of rejecting the tuple at configure time.

These contradictions are discovery evidence, not authority.  Book wording follows the tag's
implementation and generated records and narrows any unexecuted claim.

## Post-tag contamination sweep

At audit time the ordinary CNA checkout's HEAD equalled the tag commit.  Both
`git log v0.1.0-alpha.1..HEAD` and `git diff --name-status v0.1.0-alpha.1..HEAD` were empty.
Consequently there was no post-tag implementation to exclude.  The detached tag worktree remained
the source for all manuscript facts anyway.
