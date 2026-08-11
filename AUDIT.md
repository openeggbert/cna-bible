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

Implementation families under `modules/renderers/` number 43 directories (42 renderer
families plus `common/`), because several identities share one family — notably the five
EasyGL GL profiles (`OPENGLES2`, `OPENGLES3`, `OPENGL33`, `WEBGL1`, `WEBGL2`) all map to
`modules/renderers/easygl` and are distinguished by a `CNA_GL_PROFILE_*` compile definition.

**Book impact:** Part IV ("The Backends", 10 chapters covering ~12 backends) is structurally
obsolete. The preface's "a dozen different rendering backends" and "eleven implementations"
are both wrong. This is the single largest driver of the new edition's structure.

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

*(Populated from the research passes; one subsection per area. Each row: topic, current book
claim, current CNA doc claim, implementation finding, test evidence, sources, confidence,
affected chapters, action.)*

**Status: research in progress.**

---

## 5. Contradiction log

| # | Source A | Source B | Implementation shows | Conclusion | Confidence | CNA-side doc bug? |
|---|---|---|---|---|---|---|
| C-001 | Book preface: "a dozen different rendering backends"; "eleven implementations" | `modules/renderers/CMakeLists.txt`: "The 46 public renderer identities" | 46 enumerators in `GraphicsRendererType.hpp` | Book is stale by a factor of four | VERIFIED | No — book-side staleness |
| C-002 | Book Ch.24 "Canvas and ASCII Backends"; Appendix B lists ASCII as a backend | `docs/ascii-post-process-effect.md` | No `ASCII` enumerator; `AsciiPostProcessEffect` in `modules/graphics-ext` | ASCII is an effect, not a renderer | VERIFIED | No — `docs/ascii-renderer.md` correctly self-labels historical |
| C-003 | Book uses "NOXNA" throughout (incl. Appendix E title) | `CNAEXT.md`, `CNA_CNAEXT` option, commit `2ecbca579` | Macro/option are `CNAEXT` | Book term is stale | VERIFIED | No — book-side staleness |
| C-004 | Book Part IV/preface term: "backend" | Commit `57aee5f88`, `CNA_GRAPHICS_RENDERER`, `modules/renderers/` | Renderer is canonical | Book term is stale | STRONG | No — book-side staleness |

---

## 6. Open questions for the project owner

*(Recorded, not blocking. Independent work continues around them.)*

None recorded yet.
