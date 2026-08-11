# Audit report — CNA identity, architecture, modules, build system

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run. This file is raw research evidence; the curated matrix
lives in `../AUDIT.md`.

---

## Part 1 — corrections and high-value findings (first delivery)

These were delivered as an addendum after a parallel identity/conventions pass, and they
correct or extend the main body that follows.

### A-01 — "CNA" is never expanded anywhere in the ecosystem
**Confidence: STRONG.** Searches for `stands for` / `acronym` across all `*.md` return
nothing; `README.md:1` is simply `# CNA`. **The book must treat it as an opaque project
name and must not invent an expansion.** (The existing book does not expand it either —
this confirms that choice rather than changing it.)

### A-02 — C++23 is a toolchain floor, not a feature dependency
**Confidence: VERIFIED.** An anchored-regex re-check established that CNA uses **zero**
C++20 concepts and zero `requires`-clauses — every apparent hit is English prose inside a
comment. Also zero `operator<=>`, zero `std::ranges`/`views`, zero coroutines, zero
`char8_t`. The only genuine post-C++17 constructs are `constinit` (4 occurrences, all in
`modules/math/src/Vector2.cpp:88-91`), `std::bit_cast` (19), and `std::span` (14, all in
Skia example/spike translation units; only 2 `#include <span>` in the whole tree).

`CMAKE_CXX_STANDARD 23` with `CMAKE_CXX_STANDARD_REQUIRED ON` sets a compiler floor.

> **Book rule:** a sentence like "CNA uses C++23 features such as `std::expected`" would be
> false, and so would "CNA uses concepts". Say: CNA *requires* a C++23-capable compiler but
> is written in a conservative, largely C++17-shaped dialect.

### A-03 — Five namespace roots, not four
**Confidence: VERIFIED.**

| Root | Role |
|---|---|
| `Microsoft::Xna::Framework::*` | The XNA 4.0 API surface CNA reimplements |
| `Microsoft::Devices::*` (incl. `::Sensors`) | The Windows Phone 7 sensor API surface |
| `CNA::` | CNA's own layer: renderer identity, internals (`CNA::Internal::*`), extensions (`CNA::Graphics`, `CNA::Devices`, `CNA::Input`) |
| `System::` | sharp-runtime's .NET BCL subset |
| `SharpRuntime::` | sharp-runtime's C#-primitive alias layer, declared at `sharp-runtime/modules/core/include/SharpRuntime/SharpRuntimeHelper.hpp:34` |

`SharpRuntime::` is distinct from `System::` and holds the C#-primitive aliases —
`sbytecs`/`bytecs`/`intcs`/`uintcs` (`:40,:46,:69,:75`) and `SByte`/`Byte`/`Int32`/`UInt32`
(`:192-202`). `CLAUDE.md:90-107` **mandates** their use over raw C++ types anywhere in the
XNA surface, with a full mapping table (`float`→`Single`, `string`→`String`,
`char`→`charcs`→`char16_t`). Only two sharp-runtime headers are ever included from CNA:
`SharpRuntimeHelper.hpp` (66×) and `Prop.hpp` (9×).

A sixth root, `Magnum::Platform`, is reopened by the Magnum renderer.

### A-04 — 46 renderer identities, 42 implementation families
**Confidence: VERIFIED.** The authoritative family list is the `_cna_renderer_modules`
list at `modules/CMakeLists.txt:156-162`, matching `docs/physical-modules.md:54`. The book
should say **46 public identities implemented by 42 families** (plus the shared
`common/d3d` core consumed only by `directx11` and `directx12`), and cite that line.

### A-05 — The compatibility goal is a *translation* target, not a compatibility layer
**Confidence: VERIFIED.** `docs/migration-guide.md:11-13`: "it is not a C#/.NET runtime and
cannot run your existing C# assembly. Porting a game means **translating the C# source to
C++**, not recompiling or bridging it."

It is not even statement-level source-compatible, because C# properties have no C++
equivalent. `docs/migration-guide.md:17-35` calls this "The single biggest mechanical
difference": every property read becomes `getXProperty()` and every write
`setXProperty(v)` — e.g.
`spriteBatch->getGraphicsDeviceProperty()->setBlendStateProperty(BlendState::AlphaBlend);`

> **Book formulation:** namespace-, type- and member-name-identical to XNA 4.0, but a
> hand-translation target rather than a compatibility layer.

### A-06 — One namespace does not come from FNA
**Confidence: STRONG.** `README.md:300-306`: `AvatarAnimation`, `AvatarDescription` and
`AvatarRenderer` were ported from a **decompiled real Microsoft XNA 4.0 assembly** — FNA
never implemented Avatar. Everything else is FNA-referenced.

### A-07 — `Microsoft::Xna::Framework::Design` and `::Content::Pipeline` are absent
**Confidence: VERIFIED.** Zero `namespace` declarations for either. Both exist in real XNA;
the book should state their absence explicitly rather than leaving it implied.

### A-08 — The exception convention splits by layer (architecturally load-bearing)
**Confidence: VERIFIED.**

| Layer | Convention | Counts |
|---|---|---|
| Renderers (`modules/renderers/`) | Plain `std::runtime_error` / `std::invalid_argument` | 1755 / 125; `System::ObjectDisposedException` **0** |
| Public XNA API layer | `System::*` exception types | `ObjectDisposedException` 52 (all of them), `ArgumentNullException` 27, `ArgumentException` 44 |

So `System::*` is the XNA-facing contract, while a renderer saying "I cannot do that"
throws a plain `std::runtime_error`. This also explains the throwing `IGraphicsRenderer`
defaults: "throw loudly rather than silently approximate" is deliberate policy, with
`<stdexcept>` included directly by the interface header (`IGraphicsRenderer.hpp:22`).

### A-09 — Textures are `shared_ptr`, buffers are `unique_ptr`, and the API shape is why
**Confidence: VERIFIED.**

`Texture2D.hpp:588` holds `std::shared_ptr<ITextureRenderer> renderer_` (same at
`Texture3D.hpp:212` and `TextureCube.hpp:193`), because `Texture2D.hpp:96-100` keeps copy
construction and copy assignment `= default`. C# reference-type semantics mean game code
copies textures by value, which a `unique_ptr` member would forbid. Meanwhile
`VertexBuffer.hpp:454`, `IndexBuffer.hpp:227` and `SpriteBatch.hpp:56` all use
`unique_ptr`.

> **Rule for the book:** buffers and the batcher are uniquely owned; textures are shared,
> because textures are what XNA-shaped code copies. This is the API shape dictating the C++
> ownership model — a good chapter beat, and it directly qualifies the resource-tracking
> hazard the previous edition documented.

### A-10 — Exception hierarchy is inconsistent across namespaces (undocumented drift)
**Confidence: STRONG.** XNA-native exception types split across two roots:
`Audio`/`GamerServices`/`Net`/`Sensors` exceptions derive from `System::Exception`, but
`Graphics`'s `DeviceLostException`, `DeviceNotResetException` and
`NoSuitableGraphicsDeviceException` (`.../Graphics/*.hpp:10`) and `Content`'s
`ContentLoadException` (`.../Content/ContentLoadException.hpp:10`) derive from
**`std::runtime_error`**. In real XNA all four descend from `System.Exception`. This is not
listed in `CHECKLIST.md`'s deliberate-deviations table, so it reads as drift rather than a
decision.

### A-11 — `.xnb` status, from the authoritative source
**Confidence: STRONG.** `xnb.md:1-33` records "PARTIALLY UN-FROZEN 2026-07-16 — MVP scope
complete, Phase D (LZX) fully complete, Phase E (`SpriteFont`, stock effects,
`SoundEffect`/`Song`, `ReadExternalReference<T>()`) fully complete", and `ContentManager`'s
resolution order now ranks `.xnb` **above** both the literal caller-given path and `.cnj`.
Declared out of scope: `Model` reading, the hardening pass, Lua-scripted custom readers
(rejected outright), and `.xnb` **writing** (permanent).

> **Accurate book sentence:** CNA has a real runtime `.xnb` reader — container parsing, LZX
> decompression, `Texture2D`/`SpriteFont`/`SoundEffect`/`Song`/`Video`/stock-effect readers
> — ranked above `.cnj` in `ContentManager`; `Model` reading and `.xnb` writing are out of
> scope.

*(Cross-check pending against the dedicated content/XNB research pass, which reads the
readers themselves rather than the status document.)*

---

## Part 2 — contradictions found in this pass

| # | Document claim | Implementation | Conclusion |
|---|---|---|---|
| A-C1 | `docs/graphics-resource-lifetime.md:10-12`: "Every GPU-backed resource holds a `std::unique_ptr<IXxxRenderer>` … Ownership is exclusive." | All three texture classes hold `shared_ptr` (A-09). The word `shared_ptr` appears **zero** times in that document. | **CNA-side documentation bug.** The book must describe the real split. |
| A-C2 | `README.md:58`: the CNAEXT purity check is "a dedicated CMake build option … see `CMakeLists.txt`" | `CNA_STRICT_XNA_API` is never an `option()`; it lives in `cmake/Harnesses.cmake:183,224` and cannot be passed as `-DCNA_STRICT_XNA_API=ON` for a whole-project strict build. Its practical scope is the `Microsoft::Devices`/`Sensors` surface that the two `tools/devices/*.cpp` files reference (`cmake/Harnesses.cmake:170-172`), and it is skipped on MSVC (`Harnesses.cmake:178` gates on `GNU\|Clang`). | **CNA-side documentation bug.** `CNAEXT.md:29` has the accurate wording. The book must not describe a whole-API strict build that does not exist. |
| A-C3 | `CLAUDE.md:165` mandates `std::runtime_error` on use-after-dispose | Code throws `System::ObjectDisposedException` 52 times | **Guideline is stale; the code is the more XNA-faithful of the two.** |
| A-C4 | `README.md:337` lists the Windows prerequisite as MSVC 2022 with "C++20/23 support" | `README.md:326` says "C++23-capable compiler"; `CMAKE_CXX_STANDARD_REQUIRED ON` hard-fails configure on a non-C++23 MSVC | Prose imprecision, not a dual-standard policy. |
| A-C5 | `xnb.md:36-37` still carries "planning document only. Nothing described here is implemented yet" | Directly beneath the 2026-07-16 revision note that supersedes it | **CNA-side documentation bug** — a stale line inside an otherwise current document. Exactly the failure mode the book must not inherit. |

---

## Part 3 — consolidated report

*(Pending re-delivery from the research pass.)*
