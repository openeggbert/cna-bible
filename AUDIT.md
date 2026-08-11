# The CNA Bible — New Edition Source Audit

This file is the **canonical audit matrix and contradiction log** for the new edition of
The CNA Bible. It is owned by the coordinating session; research subagents report into it
but never edit it directly. It supersedes, for new-edition purposes, any per-chapter
verification status recorded in `PLAN.md` before 2026-08-11.

Confidence vocabulary used throughout:

| Label | Meaning |
|---|---|
| **VERIFIED** | Current implementation read *and* corroborated by a test, a build-configuration gate, or recorded execution evidence. |
| **STRONG** | Clearly established by current implementation/configuration; consistent with tests, but not broadly executed. |
| **PROBABLE** | Several sources agree; one important leg could not be directly verified. |
| **UNCERTAIN** | Evidence conflicts, or actual behaviour cannot be safely established from this checkout. |

---

## 1. Pinned source baseline

| Item | Value |
|---|---|
| CNA repository | `/rv/data/development/github.com/openeggbert/cna` |
| Branch | `develop` |
| Pinned SHA | `7a64362efef4119bf880459ef1704fb2c52199e2` |
| Commit subject | `integration: reconcile parallel feature lanes` |
| Commit date | 2026-08-11 18:33:25 +0200 |
| `develop` vs `origin/develop` | **Identical** — both resolve to `7a64362e`; no divergence, no fetch required. |
| Working tree | Clean (`git status --short` empty) at audit start. |
| Access mode | **Read-only.** No CNA commit, checkout, reset, clean, merge, or build was performed for this audit. |

### 1.1 Recent integration history examined

`develop`'s first-parent history at the pin shows a ten-lane merge series into an
`11branches` integration branch, then a reconciliation commit:

| First-parent commit | Lane |
|---|---|
| `7a64362ef` | `integration: reconcile parallel feature lanes` (HEAD) |
| `b4cbb688a` | lane 10/10 `feature/portablegl` (`913d39e66`) |
| `43d589e0d` | lane 9/10 `feature/openvg` (`7de755c84`) |
| `fcc0df60e` | lane 8/10 `feature/svgdom` (`b39037f87`) |
| `0597cd7af` | lane 7/10 `feature/fna3d` (`a8cd3032a`) |
| `43966a13b` | lane 6/10 `feature/blend2d` (`9709d0336`) |
| `763795ef6` | lane 5/10 `feature/opengles2` (`9faa2c6e3`) |
| `0db2347b9` | lane 4/10 `feature/asciieffect` (`70be5f515`) |
| `6acadb24a` | lane 3/10 `feature/direct2dcomplete` (`53abe801d`) |
| `264be1270` | lane 2/10 `feature/gltf` (`e9336a107`) |
| `f8d9fd374` | lane 1/10 `feature/bigcommit` (`d61be1020`) |

Earlier campaign work visible below those merges, and directly relevant to the book's
structure:

- **Naming normalization** (`57aee5f88`, `8c61cea95`, `7d227dd7a`, `2ecbca579`, `5a6a83de0`,
  `5d612f170`, `a68bad741`, `b15a896ec`): graphics *backend* terminology renamed to
  *renderer*; DirectX renderer identities normalized; `OPENGLES` profile renamed
  `OPENGLES3`; the NOXNA feature macro renamed **`CNAEXT`**; the free-direct-backed renderer
  renamed `DIRECTX3` → `FREEDIRECT`, freeing `DIRECTX3` for the real DirectX 3 renderer.
- **Physical modularization** (`840ab9e5b`, `9c950ffdc`, `3c6ac9145`, `73501a6fc`,
  `33088cba6`, `568436091`, `b321ff435`, `2fbce86d5`): the source tree moved from a central
  `src/`+`include/` layout to `modules/<name>/{src,include,tests,CMakeLists.txt}` with
  enforced ownership and include isolation.
- **Example localization** (`b17a24e5f`, `8aa45074a`, `86872b81f`, `136711ab0`, `8af8e5d2a`,
  `41fa8b948`, `d588fd332`, `0310a7c42`, `39d5d1e0b`): examples moved into their owning
  modules, with enforced ownership tests.

`integration/INTEGRATION_BRANCH_INVENTORY.md` records **21 logical integration lanes** from
an earlier campaign (all integrated by 2026-08-09), which is a *different and earlier*
campaign from the ten-lane series above. Both matter to the book: the earlier one produced
identities up to Metal ("41st identity"), the later one added the remainder.

---

## 2. Headline structural findings (coordinator-verified)

### F-001 — CNA now has **46 public renderer identities**, not eleven or twelve
**Confidence: VERIFIED.**

Evidence: `modules/core/include/CNA/GraphicsRendererType.hpp` declares 46 enumerators and a
`getCurrentGraphicsRendererName()` switch returning 46 distinct `CNA_GRAPHICS_RENDERER`
strings. `modules/renderers/CMakeLists.txt:1-8` states the count explicitly ("The 46 public
renderer identities live in RendererSelection.cmake + GraphicsRendererType.hpp and are
pinned by `scripts/check_renderer_identities.py`").

The 46 identities:

```
SDL_RENDERER  OPENGLES2  OPENGLES3  OPENGL33   WEBGL1     WEBGL2
BGFX          VULKAN     WEBGPU     MAGNUM     HEADLESS   SOFTWARE
STUB          DIRECTX11  DIRECTX12  DIRECT2D   CANVAS     HTML_DOM
SKIA          BLEND2D    FREEDIRECT DIRECTX9   DIRECTX1   DIRECTX2
DIRECTX3      DIRECTX5   DIRECTX6   DIRECTX7   DIRECTX8   DIRECTX10
SDL_GPU       OPENGLES1  OPENGL4    OPENGL1    OPENGL2    WICKED
SOKOL         DILIGENT   GLIDE      GDI        LLGL       METAL
FNA3D         SVG_DOM    OPENVG     PORTABLEGL
```

The authoritative family list is `_cna_renderer_modules` at `modules/CMakeLists.txt:156-162`,
matching `docs/physical-modules.md:54`: **42 implementation families** carry the 46 identities,
plus a shared `common/d3d` helper consumed only by `directx11` and `directx12`. Several
identities share one family — notably the five EasyGL GL profiles, which all map to
`modules/renderers/easygl`, are distinguished by a `CNA_GL_PROFILE_*` compile definition, and
are decoded back to the public enum by a `constexpr` function at
`GraphicsRendererType.hpp:164-178`.

> **Book rule:** always print **"46 identities / 42 families"**, both labelled. Their proximity
> is exactly what makes the count confusion self-perpetuating — four different counts (46, 42,
> 41, and "41→42 with ASCII still listed") live in the CNA tree simultaneously. Never cite
> `scripts/check_renderer_identities.py`'s docstring, `cmake/Tests/ModuleProbes.cmake:6`,
> `docs/svg-dom-renderer.md:233`, `MODULARIZATION_PLAN.md`,
> `modularization/renderer-naming/VALIDATION.md`, or `docs/RendererNamingMigration.md` §5 for a
> count. `docs/renderer-registry.md` is the correct source.

**Book impact:** Part IV ("The Backends", 10 chapters covering ~12 backends) is structurally
obsolete. The preface's "a dozen different rendering backends" and "eleven implementations"
are both wrong. This is the single largest driver of the new edition's structure.

### F-001a — The renderer identity registry is mechanically pinned
**Confidence: VERIFIED.** `scripts/check_renderer_identities.py` parses two registries and
compares them to a hardcoded 46-entry table: the enum comparison is **order-sensitive**, the
CMake `STRINGS` comparison is a sorted-set comparison plus a length check (the STRINGS property
is a UI list whose ordering is cosmetic). Registered as ctest `RendererIdentityRegistry`; no CI
workflow invokes it directly. This gate is what makes 46 trustworthy, and it caught the
integration defect HEAD fixes — each merge lane carried its own count, so the cardinality
`static_assert` still read 42 because the last lane merged won the line.

### F-016 — Every build command in the book is uncompilable, on two counts each
**Confidence: VERIFIED.** Each `cmake` invocation uses `-DCNA_GRAPHICS_BACKEND=…` (the option is
now `CNA_GRAPHICS_RENDERER`) *and* a value that is no longer an accepted identity (`EASYGL`,
`DX3`, `D3D9`…). Affected: `ch04-building-cna.tex:37,47,147,162,216,242`,
`ch39-windows-wine.tex:25`, `ch40-web-emscripten.tex:69,71`. **No compatibility aliases exist** —
an old spelling does not merely look dated, it fails configure with
`FATAL_ERROR "CNA: Unknown graphics renderer: …"`.

Measured staleness across `latex/book/**/*.tex`: `modules/` **0** occurrences; "backend" 1,769;
`NOXNA` 198; `D3D9`/`D3D11`/`D3D12` 219/140/131; `ASCII` 89; `EASYGL` 68; `DX3` 57;
`IGraphicsBackend` 31; `GraphicsBackendType` 10; `CNA_GRAPHICS_BACKEND` 9 (seven inside
copy-pasteable command blocks); deleted CMake files cited 8 times.

### F-017 — CNA has no install, export or packaging step
**Confidence: VERIFIED.** Zero `install()`, `install(EXPORT)`, `export(EXPORT)` or
`include(CPack)` in the root, `cmake/`, or any module. CNA is consumed **only** by
`add_subdirectory` + `target_link_libraries(<app> CNA)`. A chapter describing `make install`
followed by `find_package(CNA)` would be inventing an API.

### F-018 — CNA is a translation target, not a compatibility layer
**Confidence: VERIFIED.** `docs/migration-guide.md:11-13`: CNA "cannot run your existing C#
assembly. Porting a game means **translating the C# source to C++**." It is not even
statement-level source-compatible, because C# properties have no C++ equivalent — every read
becomes `getXProperty()`, every write `setXProperty(v)`. Below that layer names are exact:
class, struct, enum, method, operator and constant names must match XNA/FNA verbatim.

### F-019 — "Renderer" and "backend" are now two *different live* concepts
**Confidence: VERIFIED.** A **renderer** is a CNA graphics implementation (46 identities, 42
families, `IGraphicsRenderer`). A **backend** is a platform-service implementation in the input,
devices, devices-ext or net subsystems — `SdlGamepadBackend`, `AndroidCompassBackend`,
`SdlTrayBackend`, `ENetBackend`. Word-boundary census over `modules/`: 401 lines containing
"backend", of which **graphics contributes zero**; devices 191, devices-ext 100, input 82,
audio 17 (prose only — there is no audio backend interface), net 2.

Third-party vocabulary is quoted as upstream spells it (`GrBackendRenderTarget`,
`sg_query_backend`, `bgfx::RendererType`), and native Microsoft vocabulary is retained inside the
D3D families (`D3D11Buffers`, `D3D12PipelineStateCache`, …) — only the renderer *identity* class
and the selection surface flipped to `DirectX<N>`. No lint enforces any of this: the identity
registry is gated, the vocabulary is not.

### F-020 — `DIRECTX3` and `FREEDIRECT` are now two different renderers
**Confidence: VERIFIED.** The free-direct-backed renderer was renamed `DIRECTX3` → `FREEDIRECT`,
freeing `DIRECTX3` for a genuine real-DirectX-3 renderer (DirectDraw v2 + Direct3D v2
DrawPrimitive). The book's single Ch.25 "The DX3 Backend and free-direct" must split.

### F-021 — C++23 is a toolchain floor, not a feature dependency
**Confidence: VERIFIED.** An exhaustive census returns **zero** occurrences of every headline
C++23 feature (`std::expected`, `std::print`, `std::format`, `import std`, `std::mdspan`,
`std::flat_map`, `std::generator`, `std::stacktrace`, `std::move_only_function`, deducing `this`,
`if consteval`, multidimensional `operator[]`, …) and **zero** C++20 concepts, `requires`-clauses,
`operator<=>`, ranges/views, coroutines or `char8_t`. The only genuine post-C++17 constructs are
`constinit` (4, all in `modules/math/src/Vector2.cpp:88-91`), `std::bit_cast` (19) and
`std::span` (14, all in Skia example/spike TUs). What *is* used is dense C++17: `constexpr` 5,474,
`[[nodiscard]]` 5,274, `std::optional` 400, `std::string_view` 106.

> **Book rule:** say "compiled as C++23; written in a disciplined C++17/20 idiom." Writing "CNA
> uses C++23 features such as `std::expected`" or "CNA uses concepts" would be false.

### F-022 — Five namespace roots, and "CNA" is never expanded
**Confidence: VERIFIED.** `Microsoft::Xna::Framework::*` (the XNA surface),
`Microsoft::Devices::*` (a *separate* root, the Windows Phone 7 sensor API), `CNA::` (own layer:
internals, extensions, renderers), `System::` (sharp-runtime's BCL subset), and `SharpRuntime::`
(sharp-runtime's C#-primitive alias layer, whose use `CLAUDE.md:90-107` mandates over raw C++
types across the XNA surface). A sixth, `Magnum::Platform`, is reopened by one renderer.
`Microsoft::Xna::Framework::Design` and `::Content::Pipeline` are **confirmed absent**.

Searches for "stands for" / "acronym" across all CNA markdown return nothing; `README.md:1` is
simply `# CNA`. **The book must not invent an expansion.**

### F-023 — The exception convention splits by layer, and it is load-bearing
**Confidence: VERIFIED.** `System::*` .NET-shaped exceptions are the **XNA-facing contract** — a
port target sees `ArgumentOutOfRangeException`/`ObjectDisposedException` exactly where the C#
original threw them. The ~42 renderer implementations, which have no XNA counterpart, throw plain
`std::runtime_error` for "this renderer cannot do that": 1,755 in `modules/renderers/` versus
**zero** `ObjectDisposedException` there, against 52 in the public layer (all of them).
`IGraphicsRenderer`'s default virtuals themselves throw, which makes "throw loudly rather than
silently approximate" architectural policy rather than an accident.

### F-002 — The project's canonical term is **renderer**, not **backend**
**Confidence: STRONG.**

Evidence: commit `57aee5f88` "refactor(graphics): rename graphics backend terminology to
renderer"; the enum is `GraphicsRendererType`; the CMake option is `CNA_GRAPHICS_RENDERER`;
the selection module is `cmake/RendererSelection.cmake`; modules live under
`modules/renderers/`. An internal `IGraphicsBackend`-style interface name may survive in
places — the renderer-catalog audit resolves the exact current interface name and whether
"backend" remains a distinct concept.

**Book impact:** a whole-book terminology pass is required. Part IV's directory name
(`part4-backends`), every chapter filename containing `backend`, and the running prose must
be normalized.

### F-003 — The `ASCII` renderer identity was **removed**; ASCII is now a post-process effect
**Confidence: VERIFIED.**

Evidence: `docs/ascii-post-process-effect.md:1-6` — "`CNA::Graphics::AsciiPostProcessEffect`
(`modules/graphics-ext/`) is CNA's renderer-neutral ASCII/glyph-grid image post-process
effect. It replaces the former public `ASCII` graphics-renderer identity
(`CNA_GRAPHICS_RENDERER=ASCII`, removed 2026-08 …)". `docs/ascii-renderer.md:1-11` is
explicitly relabelled a historical document. `ASCII` does not appear in
`GraphicsRendererType.hpp` nor as a `modules/renderers/` family. Landed via lane 4/10
`feature/asciieffect` (`0db2347b9`).

Rationale recorded in-repo: ASCII was never a terminal renderer, only a decorator around
`SdlRenderer` that read back its own frame and quantized it; as an effect the same
quantization applies to any renderer's output, including 3D scenes.

**Book impact:** Chapter 24 "Canvas and ASCII Backends" has a false premise. ASCII material
must move to an effects/post-processing context; Canvas needs its own home.

### F-004 — `NOXNA` is now `CNAEXT`
**Confidence: VERIFIED.**

Evidence: commit `2ecbca579` "refactor(extensions): rename NOXNA feature macro to CNAEXT";
root `CMakeLists.txt:60` — `option(CNA_CNAEXT "Enable CNA CNAEXT extended graphics layer
(beyond XNA 4.0)" OFF)`; `CNAEXT.md` exists at the CNA repo root.

**Book impact:** Appendix E is titled "NOXNA Catalog" and the term "NOXNA" is used
throughout the book. All occurrences need auditing: current-behaviour uses become `CNAEXT`,
genuinely historical uses may stay with a date.

### F-005 — Build options at the pin
**Confidence: VERIFIED** (read directly from the root `CMakeLists.txt`).

| Option | Default | Purpose |
|---|---|---|
| `CNA_USE_CCACHE` | `ON` | ccache for CNA and sharp-runtime builds when available |
| `CNA_BUILD_TESTS` | `ON` | Build CNA tests |
| `CNA_BUILD_EXAMPLES` | `ON` | Build example applications |
| `CNA_CNAEXT` | `OFF` | Extended graphics layer beyond XNA 4.0 |
| `CNA_DEVICES` | `OFF` | Device/sensor extensions beyond XNA 4.0 |
| `CNA_ENABLE_NET` | `ON` | Networking (GamerServices + Net, requires ENet) |

Renderer-local options exist as well (e.g. `CNA_BUILD_SVG_DOM_HOST_TESTS`, `OFF`, defined in
`modules/renderers/CMakeLists.txt`). The architecture/build audit enumerates the rest.

### F-006 — Module layout is physical, enforced, and 15 modules wide
**Confidence: STRONG.**

`modules/` contains: `audio`, `content`, `core`, `devices`, `devices-ext`, `gamer-services`,
`graphics`, `graphics-ext`, `input`, `math`, `media`, `net`, `renderers`, `runtime`,
`storage`. Ownership and include isolation are enforced by tests (`tests/modules`) and
`scripts/check_module_link_closure.py`.

Rough source weight by family (`.cpp`/`.hpp`/`.h` counts): `renderers` 1525 files dominates,
then `graphics` 377, `gamer-services` 150, `input` 146, `content` 129, `media` 100, `net` 90,
`devices` 85, `audio` 75, `math` 62, `runtime` 54, `devices-ext` 49, `graphics-ext` 31,
`core` 19, `storage` 7.

---

## 3. Book baseline being replaced

| Item | Value at baseline |
|---|---|
| cna-bible branch | `next` |
| cna-bible SHA at audit start | `afc5b1b` |
| Physical PDF pages (last verified checkpoint) | 575 |
| Parts / chapters / appendices | 9 / 49 / 6 |
| Chapter LaTeX lines | 25,878 |

Largest existing chapters: Ch.16 backend architecture (2,254 lines), Ch.08 content (2,247),
Ch.07 math (1,675), Ch.09 GraphicsDevice (1,517), Ch.23 Direct3D (888). Smallest:
Ch.38 free-direct (65 lines), Ch.49 roadmap (161), Appendix C glossary (162).

---

## 4. Subsystem audit matrix

Full per-area evidence lives in `audit/*.md`. This section carries the cross-cutting
conclusions that drive the new edition's structure.

| Area | Raw report | Status |
|---|---|---|
| Identity, architecture, modules, build | `audit/architecture-build.md` | Delivered |
| 3D model runtime, glTF, skinning, CNJ tooling | `audit/3d-gltf-cnj.md` | Delivered |
| Content pipeline, XNB, type readers, CNJ | `audit/content-xnb-cnj.md` | Delivered |
| Renderer catalog (46 identities) | `audit/renderer-catalog.md` | In progress |
| Graphics core, effects, shaders | `audit/graphics-core-effects.md` | In progress |
| Input, devices, audio, media, net, services, storage | `audit/input-audio-net-services.md` | In progress |
| Testing, verification, oracles, CI | `audit/testing-verification.md` | In progress |
| Platforms | `audit/platforms.md` | In progress |
| Sibling libraries | `audit/sibling-libraries.md` | In progress |
| Framework core and math | `audit/framework-core-math.md` | In progress |

### 4.1 Content pipeline — headline conclusions

**F-007 — The content module is four subsystems under one façade, not one chapter's worth.**
**Confidence: VERIFIED.** `modules/content/` is 130 files / ~33k lines, 41 test files, ~350
test cases. It contains: the XNA-faithful binary reader stack (`CNA::Internal::Xnb`, ~5k lines,
18 test files); the CNA-original JSON format (`CnjEnvelope`/`Json` + the loose-file readers,
~3k lines, 15 test files); the glTF import core (`GltfImportCore`, ~2.5k lines, 11 test files
with their own oracles); and `ContentManager` itself. The existing single 2,247-line chapter
has **zero** coverage of the third.

**F-008 — `.xnb` reading is real and substantial, and the book's earlier framing is obsolete.**
**Confidence: VERIFIED.** 50 canonical readers are registered when FFmpeg and native `__int128`
are available; LZX is a line-by-line port of FNA's decoder verified byte-for-byte against FNA
under Mono; 30 real externally-produced `.xnb` fixtures (568 KB) are committed with manifests.
Resolution order is `.xnb` → `.cnj` → native extension, pinned by test.

**F-009 — `Game` never registers the built-in XNB readers.** **Confidence: VERIFIED.** The only
non-test callers of `RegisterAllBuiltInXnbReaders()` are a tool and a doc snippet. A real CNA
game that does not call it itself cannot load any `.xnb`. This is the single most important
practical fact in the subsystem for a porting engineer, and no CNA document states it.

**F-010 — Two reader registries share a near-identical name and nothing else.**
**Confidence: VERIFIED.** `ContentTypeReader<T>` (process-wide, keyed by canonical string,
`Read(ContentReader&, optional<T>)`) versus `LooseFileContentTypeReader<T>` (per-manager, keyed
by `type_index`, `Read(path, ContentManager&)`). They were the same class until the 2026-07-16
rename. This is the subsystem's central confusion and needs chapter-level separation to be
legible.

**F-011 — The `.cnj` side is materially less hardened than the `.xnb` side.**
**Confidence: VERIFIED (code); STRONG (exploitability).** XNB bounds type-name nesting, object
nesting, string bytes, collection counts, shared-resource counts and decompressed size, and has
three deterministic fuzz harnesses. The CNJ JSON parser has **no recursion depth limit**, no
size limit, and no fuzz coverage — the same threat model that REMED-CONTENT-006 explicitly
closed on the XNB side.

### 4.2 3D and glTF — headline conclusions

**F-012 — A real in-tree glTF 2.0 importer exists, shared by an offline tool and the runtime.**
**Confidence: VERIFIED.** `modules/content/{include,src}/…/GltfImport/GltfImportCore` (~2.5k
lines) on vendored cgltf 1.15, consumed by both `tools/gltf_to_cnj` and `ContentManager`'s
`ReadGltfModel`. `Load<Model>("x.glb")` works with no sidecars.

**F-013 — The glTF conformance apparatus is the best worked example of method in the tree.**
**Confidence: VERIFIED.** A specification pinned by commit + SHA-256, a stdlib-only
deterministic fixture generator, a 16-asset digest-verified committed corpus, a five-of-seven
implemented oracle ladder, and an executable defect ledger with a three-state lifecycle and a
bidirectional completeness test. The book does not mention any of it.

**F-014 — "The importer parses it" and "the runtime plays it" must always be separate claims.**
**Confidence: VERIFIED.** Rigid (unskinned) node animation is imported by no path and dropped
silently by two independent mechanisms; `pbrUv2Mismatch` is computed and never surfaced at
runtime; morph targets on stride-48/68 PBR meshes silently skip normals; the runtime imports
only `groups.front()`.

**F-015 — `SupportsCapability` defaults to `true`, so renderers must opt *out* of 3D.**
**Confidence: VERIFIED.** `IGraphicsRenderer::SupportsCapability` returns true for everything
except `MultiStreamVertexInput`. Ten renderers explicitly declare `ThreeD = false`; five of
those also override `Ensure3DSupported` (itself a default no-op) to refuse early. The
default-true polarity is a genuine trap and deserves explicit book coverage.

---

## 5. Contradiction log

| # | Source A | Source B | Implementation shows | Conclusion | Confidence | CNA-side doc bug? |
|---|---|---|---|---|---|---|
| C-001 | Book preface: "a dozen different rendering backends"; "eleven implementations" | `modules/renderers/CMakeLists.txt`: "The 46 public renderer identities" | 46 enumerators in `GraphicsRendererType.hpp` | Book is stale by a factor of four | VERIFIED | No — book-side staleness |
| C-002 | Book Ch.24 "Canvas and ASCII Backends"; Appendix B lists ASCII as a backend | `docs/ascii-post-process-effect.md` | No `ASCII` enumerator; `AsciiPostProcessEffect` in `modules/graphics-ext` | ASCII is an effect, not a renderer | VERIFIED | No — `docs/ascii-renderer.md` correctly self-labels historical |
| C-003 | Book uses "NOXNA" throughout (incl. Appendix E title) | `CNAEXT.md`, `CNA_CNAEXT` option, commit `2ecbca579` | Macro/option are `CNAEXT` | Book term is stale | VERIFIED | No — book-side staleness |
| C-004 | Book Part IV/preface term: "backend" | Commit `57aee5f88`, `CNA_GRAPHICS_RENDERER`, `modules/renderers/` | Renderer is canonical | Book term is stale | STRONG | No — book-side staleness |
| C-005 | `xnb.md:36-39` "planning document only. Nothing described here is implemented yet" | Same file's 2026-07-16 banner: Phases 0/A/B/B2/B3/C/D/E complete | 50 registered readers, 30 real fixtures, ~350 tests | The un-retracted prose is stale | VERIFIED | **Yes** — flat self-contradiction inside one file |
| C-006 | `xnb.md` banner: "Phase D3/F onward … remain frozen/deferred … nothing there is started" | `plan_xnb.md:3-7`: Phases F, D3, G fully complete | `ModelContentTypeReaders.cpp`, Texture3D/TextureCube readers and the fuzz suite all exist | `plan_xnb.md` is right | VERIFIED | **Yes** |
| C-007 | Five docs assert CNA cannot read `.xnb` at all (`docs/migration-guide.md`, `docs/xna-4-api-coverage.md`, `docs/coverage.md` "Content pipeline (.xnb) — 0 %", `docs/README.md`, `AUDIT.md`) | The reader stack | Reader stack is real and tested | All five are stale | VERIFIED | **Yes** — five documents |
| C-008 | `docs/xnb-content-pipeline-support.md:56,166-173,213`: `SoundEffectReader` is "16-bit PCM only", other formats "explicitly rejected" | `SoundEffectContentTypeReader.cpp:289-301` | 8-bit PCM, IEEE float, MS-ADPCM and IMA-ADPCM all decode, with four real fixtures | Doc's audio matrix is one day stale (AUD-06) | VERIFIED | **Yes** — otherwise the best content doc |
| C-009 | `cnj.md:20-22,277`, `plan_cnj.md:369`: strict global `cnjVersion == 1` | `CnjEnvelope.hpp:130-141`, `ContentManager.cpp:2277` | Ceiling is **per type**; only `Model` accepts 2 | Docs inverted the actual design | VERIFIED | **Yes** — GLTF-455 still open |
| C-010 | `cnj.md:199-201`: the manifest cache services asset resolution | `ContentManager.hpp:97-103` says it is NOT consulted; three live `exists()` calls remain | Manifest is introspection only | Doc is wrong | VERIFIED | **Yes** |
| C-011 | `docs/graphics-resource-lifetime.md:10-12`: every GPU resource holds a `unique_ptr`, "ownership is exclusive" | `Texture2D.hpp:588`, `Texture3D.hpp:212`, `TextureCube.hpp:193` hold `shared_ptr` | Textures are shared because XNA-shaped code copies them; buffers/batcher are unique | Doc never mentions `shared_ptr` | VERIFIED | **Yes** |
| C-012 | `README.md:58`: the CNAEXT purity check is "a dedicated CMake build option" | `cmake/Harnesses.cmake:170-183,224` | `CNA_STRICT_XNA_API` is not an `option()`, is scoped to the `Microsoft::Devices` surface, and is skipped on MSVC | `CNAEXT.md:29` has the accurate wording | VERIFIED | **Yes** |
| C-013 | `CLAUDE.md:165` mandates `std::runtime_error` on use-after-dispose | 52 `System::ObjectDisposedException` throws in the public layer | Code is more XNA-faithful than the guideline | Guideline is stale | VERIFIED | **Yes** |
| C-014 | `plan_gltf.md:9-11` "THIS DOCUMENT IS A PLAN. NOTHING IN IT WAS IMPLEMENTED"; §29 prose "No D1–D8 production fix was implemented"; `FUTURE.md:27,43` "not started" / "glTF is not corrected" | Same file's task tables mark 21 GLTF tasks DONE; the ledger records D1–D4, D8 fixed | Implementation wins | Prose is a stale P0-B snapshot | VERIFIED | **Yes** — GLTF-449 exists to fix it |
| C-015 | `gltfissues.md` headline: "CNA discards glTF node transforms" | D1/D2/D3 fixed; its cited paths no longer exist post-modularization | Fixed; its other findings still hold verbatim | Partially superseded | VERIFIED | **Yes** |
| C-016 | `known_bugs.md` as the bug ledger | Grep: zero content entries; the real ledger is `remediation/REMED-CONTENT-001..011` and `NEXT.md` | `REMED-CONTENT-010` (cgltf misaligned load, LOW) still open | Book must cite `remediation/`, never `known_bugs.md`, for content | VERIFIED | Coverage gap |
| C-017 | Every design doc's source paths (`cnj.md`, `plan_cnj.md`, `xnb.md`, `plan_xnb.md`, `docs/model-content-pipeline-support.md`, `gltfissues.md`) and the whole `audit/` tree (2,297 `.audit.md` files) | The `modules/<name>/{include,src,tests}` layout promoted 2026-08-10 | `src/Microsoft/Xna/Framework/...` no longer exists | All citations stale; `audit/` also lists an already-fixed HIGH | VERIFIED | **Yes** — repo-wide |
| C-018 | `CNAEXT.md:110-120` PBR coverage table | Tree scan | Omits Metal, LLGL, Magnum, Diligent, OpenGL 1/2/4, Sokol, Wicked, D3D12 — all carry `PbrEffect` code | Derive the table from the tree, never reproduce it | VERIFIED | **Yes** |
| C-019 | `THIRD_PARTY_NOTICES.md` (8 sections) | `third_party/cgltf` (MIT) and `third_party/stb` compiled into `cna_content`; Draco when found | Neither is listed | Attribution gap | VERIFIED | **Yes** |

### 5.1 Defects surfaced by the audit that no CNA document records

These are book-worthy because they are mechanically derived from verified code, are covered by
no test, and appear in no CNA document. They are recorded here so the book can describe real
boundaries accurately; **they are not for the book session to fix — CNA is read-only here.**

| # | Defect | Evidence | Confidence |
|---|---|---|---|
| D-001 | `Load<Song>` / `Load<Video>` will return an asset pointing at a `.cnj` file. The resolver tries `.cnj` before native extensions for every type, but only `Texture2D`/`TextureCube`/`SoundEffect` branch on it in `Read()`; `Song`'s constructor only checks `exists()`. | `ContentManager.cpp:3004-3009, 3021-3024`; `modules/media/src/Xna/Song.cpp:14-29` | STRONG |
| D-002 | The `.cnj` JSON parser recurses with no depth bound, while the XNB side bounds both type-name and object-graph nesting after REMED-CONTENT-006 flagged exactly this as a stack-exhaustion vector. | `CNA/Internal/Json.hpp:195-211, 235, 261` (no depth counter); cf. `XnbTypeName.hpp:80-87`, `ContentReader.hpp:368-384` | VERIFIED (code) |
| D-003 | `XnbReadLimits::maxFileSize` (64 MiB) is never enforced on the whole-file read; `LoadXnbAsset` and `ScanXnbReaderNames` both slurp arbitrarily large files. Its only consumer is the compressed-payload check. | `XnbReadLimits.hpp:20`; `XnbDecompression.cpp:19`; `ContentManager.hpp:426-433` | VERIFIED |
| D-004 | No reader overrides `SupportsVersion`/`TypeVersion`, so every reader's version is 0 and **any `.xnb` declaring a nonzero reader version is rejected**. | `ContentTypeReader.hpp:51-64`; `ContentReader.cpp:227-232`; repo-wide grep finds no override | VERIFIED |
| D-005 | `CanDeserializeIntoExistingObject` is declared and overridden twice (`ListReader`, `DictionaryReader`) but **never consulted** by `ContentReader`. Inert metadata. | `ContentTypeReader.hpp:43`; `CollectionContentTypeReaders.hpp:143, 197`; zero reads in `ContentReader.{hpp,cpp}` | VERIFIED |
| D-006 | `ContentManager::Unload()` is two `.clear()` calls and disposes nothing; the disposal-tracking list does not exist. FNA disposes every tracked `IDisposable`. | `ContentManager.cpp:135-139`; `ContentReader.hpp:451-452` ("deferred to Phase B2") | VERIFIED |
| D-007 | `XnbBuiltInReaderRegistrationTests.cpp:105` asserts `DecimalReader` is registered unconditionally, but its registration is `#if SHARP_RUNTIME_HAS_NATIVE_INT128`. On a platform without native `__int128` the test fails. | `DecimalDateTimeContentTypeReaders.cpp:12-15` | PROBABLE (build not run) |
| D-008 | Graphics/Content exception types derive from `std::runtime_error` while Audio/GamerServices/Net/Sensors ones derive from `System::Exception`. In real XNA all four descend from `System.Exception`; not listed in `CHECKLIST.md`'s deliberate-deviations table. | `.../Graphics/*.hpp:10`; `Content/ContentLoadException.hpp:10` | STRONG |
| D-009 | `ExtractMesh`'s rejections throw plain `std::runtime_error` unwrapped, so `Load<Model>` on a TRIANGLE_STRIP `.glb` escapes a `catch (ContentLoadException&)`. | `GltfImportCore.cpp:1145-1155`; `ContentLoadException.hpp:10` | VERIFIED |
| D-010 | `Model::Draw` uses a `static` process-wide scratch buffer, so two `Model`s drawn concurrently from different threads share it. | `Model.cpp:13, 107-110` | VERIFIED |

---

## 6. Open questions for the project owner

*(Recorded, not blocking. Independent work continues around them.)*

None recorded yet.
