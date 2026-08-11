# The CNA Bible — New Edition Plan

**This is the current, authoritative plan.** The previous expansion plan and handoff are
preserved verbatim as `PLAN-ARCHIVE-2026-07-26.md` and `NEXT-ARCHIVE-2026-07-26.md`. They remain
valuable as history — methodology, prior source findings, the two-volume merge record — but their
per-chapter page targets, chapter-count assumptions and "PDF-verified" labels are **not binding**
on this edition.

Evidence for everything below is in `AUDIT.md` (curated matrix + contradiction log) and `audit/`
(raw per-area research reports).

---

## 1. Why there is a new edition

The book was last deeply synchronised against CNA before two campaigns and an eleven-branch
integration landed. At the pinned baseline the manuscript is wrong in ways that no amount of
in-place editing fixes:

| Manuscript | Reality at the pin |
|---|---|
| "a dozen rendering backends"; eleven implementations | **46 renderer identities / 42 implementation families** |
| "backend" (1,769 occurrences) | `renderer` is canonical; "backend" now names a *different* live concept (input/devices/net platform services) |
| Ch.24 "Canvas and ASCII Backends" | The `ASCII` identity was **removed**; it is now `AsciiPostProcessEffect` in `modules/graphics-ext` |
| Ch.25 "The DX3 Backend and free-direct" | `DIRECTX3` and `FREEDIRECT` are now **two different renderers** |
| Ch.18 "The EASYGL Backend" | `EASYGL` is an internal family name and **not an accepted selector** |
| `NOXNA` (204 occurrences, incl. Appendix E's title) | renamed `CNAEXT`, and it denotes **two unrelated things** sharing a name |
| Ch.15 "Shaders and the .fx Bytecode Gap" | The premise is now roughly one-quarter true — CNA has **four** distinct answers to `.fx` |
| every `cmake` command in the book | uncompilable twice over: option renamed *and* no old identity spelling accepted |
| zero mention of glTF | a real in-tree glTF 2.0 importer with the project's best verification apparatus |
| zero mention of `modules/` | the whole tree is a physical module monorepo |

---

## 2. Pinned source baseline

| Item | Value |
|---|---|
| CNA repository | `/rv/data/development/github.com/openeggbert/cna` |
| Branch / SHA | `develop` @ `7a64362efef4119bf880459ef1704fb2c52199e2` |
| Commit | `integration: reconcile parallel feature lanes`, 2026-08-11 18:33:25 +0200 |
| `develop` vs `origin/develop` | identical; no divergence, no fetch needed |
| Access | **read-only** — no CNA build, checkout, reset, commit or fix at any point |

Sibling repositories, recorded for citation:

| Repo | Branch | HEAD | Date |
|---|---|---|---|
| `sharp-runtime` | develop | `f827a6c5` | 2026-08-10 |
| `easy-gl` | develop | `0b46d35` | 2026-08-07 |
| `meta-gl` | develop | `571d3a6` | 2026-08-07 |
| `free-direct` | develop | `934f72f` | 2026-07-18 |
| `free-api` | develop | `53d7a31` | 2026-07-18 |
| `xna4-spec` | develop | `8f61207` | 2026-07-04 |
| `cna-samples` | develop | `149a19f` | 2026-07-11 |
| `cna-examples` | develop | `fa0b49a` | 2026-07-28 |
| `cna-template` | next | `1d86681` | 2026-08-11 |
| `cna-craft` | develop | `7d7f186` | 2026-07-11 |
| `cna-extended` | develop | `2ff3cff` | 2026-07-27 |

`easy-gl` and `meta-gl` HEADs match the SHAs CNA's `integration/INTEGRATION_BRANCH_INVENTORY.md`
names as current public authority after the authorised history rewrite — so that record is
current, not stale.

---

## 3. Phase status

| Phase | State |
|---|---|
| **A — source audit** | **Complete. 10 of 10 areas delivered and on disk in `audit/`.** |
| **B — new Table of Contents** | **Complete.** The 12-Part / 79-chapter structure, appendices and old-to-new disposition map are settled in §4. |
| **C — structural migration** | **Complete.** The 12-Part / 79-chapter / 8-appendix migration, context-sensitive terminology pass, current selector/identifier migration, and module-owned source-path sweep are complete and PDF-verified clean at 645 pages. |
| **D — chapter writing** | **In progress.** Four verified batches complete: Chapters 19–54. Continue in verified 8–10 chapter batches. |
| **E — appendices** | Not started. |
| **F — whole-book consistency** | Not started. |
| **G — final verification** | Not started. |

### 3.1 Phase A research areas — all delivered

| Area | Report |
|---|---|
| Identity, architecture, modules, build | `audit/architecture-build.md` |
| Renderer catalog (46 identities) | `audit/renderer-catalog.md` |
| Graphics core, resources, effects, shaders | `audit/graphics-core-effects.md` |
| Content pipeline, XNB, type readers, CNJ | `audit/content-xnb-cnj.md` |
| 3D models, glTF, skinning, CNJ toolchain | `audit/3d-gltf-cnj.md` |
| Testing, verification, oracles, CI | `audit/testing-verification.md` |
| Input, devices, audio, media, net, services, storage | `audit/input-audio-net-services.md` |
| Platforms | `audit/platforms.md` |
| Sibling libraries | `audit/sibling-libraries.md` |
| Framework core and math | `audit/framework-core-math.md` |

Each report ends with its own "BOOK IMPACT" section proposing chapter-level changes for its area.
`AUDIT.md` §4 carries a curated cross-report summary; the full detail (with `path:line` citations)
is only in the individual reports — read the relevant one before writing any chapter.

### 3.2 Renderer draw-path matrix — complete

`audit/renderer-draw-path-matrix.md` exhaustively covers all **42 implementation families / 46
public identities** at the pin: both ordinary effect-aware draw routes, RenderTarget2D, MRT and
occlusion queries. The principal results are:

- 31 families override both `DrawPrimitivesEx` and `DrawIndexedPrimitivesEx`; 11 inherit both.
- Of the 11 inheritance families, nine ultimately reject 3D, STUB no-ops, and **DIRECTX10 alone
  performs a real colored draw after silently discarding `GpuDrawParams`**.
- Four overrides are hybrid rather than purely effect-owned: OPENGLES1, SDL_GPU, OPENGL4 and
  WEBGPU conditionally call their colored route for unmatched combinations.
- The matrix exposed further default-true capability defects: HEADLESS, SOFTWARE and WEBGPU claim
  MRT while rejecting multi-target binds; HEADLESS/SOFTWARE also overclaim real occlusion queries,
  joining the already-recorded SDL_GPU/WEBGPU query mismatch. See `AUDIT.md` F-031a/F-031b and
  `cnabugs.md` CNA-BUG-054.

This prerequisite is closed. Chapters 19, 23, 25, 27 and 32 plus Appendix B must consume the
matrix rather than infer support from override presence or `SupportsCapability()` alone.

---

## 4. Settled new structure

Phase B is complete. The new edition has **12 Parts, 79 chapters and 8 appendices**. This is a
content architecture, not a promise that every chapter receives equal length: page bands below
are planning ranges, and evidence density takes precedence over symmetry.

Four decisions prevent duplication:

1. Part II gives build and module architecture once; later Parts cross-reference it rather than
   repeating option tables and dependency acquisition.
2. Part III owns the renderer-independent graphics API. Part IV owns renderer selection,
   capabilities and implementation families. Shader API semantics stay in Part III; shader
   delivery differences stay in Part IV.
3. Part V owns containers, readers and content security. Part VI owns the `Model` runtime, glTF,
   skinning, the model-flavoured CNJ toolchain and its conformance campaign.
4. Part X explains platform mechanisms. Part XI explains verification mechanisms. Wine and
   browser chapters in Part X describe runtime constraints; Part XI compares their gates and
   oracles without re-teaching the platform build.

### 4.1 Parts I–III — identity, onboarding and renderer-independent graphics

| Ch. | Title | Planned depth | Principal source / disposition |
|---:|---|---:|---|
| 1 | **CNA and XNA 4.0** | 18–22 pp | Rewrite old Ch.01: identity, authority order, translation model, honest coverage and non-goals. |
| 2 | **Ecosystem and vocabulary** | 16–20 pp | Rebuild old Ch.02; introduce renderer/backend distinction and the sibling graph. |
| 3 | **Language, conventions, and CNAEXT** | 18–22 pp | Rebuild old Ch.03 around C++23-as-floor, namespaces, exceptions, ownership and CNAEXT's two meanings. |
| 4 | **Configuring and building CNA** | 18–22 pp | Replace old Ch.04 commands with the verified option/compiler/toolchain matrix; state that CNA has no install/export/package step. |
| 5 | **Your first CNA game** | 18–22 pp | Preserve the tutorial spine of old Ch.05; use only current renderer selectors and build commands. |
| 6 | **The game lifecycle** | 24–30 pp | Correct and expand old Ch.06 with exact lifecycle order, dispatcher pump, disposal, timing and Emscripten divergence. |
| 7 | **Vectors, matrices, quaternions, and conventions** | 32–40 pp | First half of old Ch.07: row vectors, handedness, depth range, multiply order, degeneracy and numeric evidence. |
| 8 | **Geometry, color, curves, and C++ value layout** | 32–40 pp | Second half of old Ch.07: bounds, plane/ray, `Color`, polymorphic layout, exception splits and the live `Plane::Transform` bug. |
| 9 | **The module monorepo** | 16–20 pp | New: physical modules, targets, `cna_add_module()`, public include roots and consumer include stability. |
| 10 | **Cycles, umbrellas, boundaries, and enforcement** | 18–22 pp | New: declared cycles, umbrellas, link closures, ownership probes, Ninja skips and migration history. |
| 11 | **Dependencies, tests, examples, and developer tools** | 14–18 pp | New build-system close: acquisition mechanisms, sharp-runtime seam, registration overview and tool targets; deep testing moves to Part XI. |
| 12 | **GraphicsDevice and the rendering pipeline** | 28–34 pp | Revise old Ch.09: forwarding policies, reset semantics, texture-slot bookkeeping, streams and rollback. |
| 13 | **SpriteBatch and 2D rendering** | 22–28 pp | Revise old Ch.10: integer truncation, text rounding, sort/state transactions and premultiplication. |
| 14 | **Textures and render targets** | 24–30 pp | Revise old Ch.11: real format limits, CPU decompression, null objects, MSAA and target-switch invariants. |
| 15 | **Stock effects and draw parameters** | 22–28 pp | Revise old Ch.13 around `GpuDrawParams`, parameter collections, cloning and CNAEXT effects. |
| 16 | **State objects and value semantics** | 16–20 pp | Revise old Ch.14: by-value storage, no freeze/binding semantics, dead properties and commit-after-success. |
| 17 | **Shaders: four answers to XNA's `.fx`** | 26–32 pp | Replace old Ch.15: reimplement, recompile Microsoft sources, execute `.fxb`, bypass with `ShaderEffect`; close on the real parameter-plumbing gap. |
| 18 | **Vertex streams and capabilities** | 18–22 pp | New bridge into Part IV: non-blittable public vertices, packed stream ABI, default-true capabilities and throw/no-op/silent-degrade modes. |

### 4.2 Part IV — the renderers

The cluster axis remains *what the renderer talks to and how it obtains shaders*. The chapter
allocation below partitions all **46 public identities / 42 implementation families** exactly:
10+4+7+9+6+4+3+3 identities. §3.2's completed draw-path divergence matrix is mandatory evidence
for Chapters 19 and 32 as well as the family chapters.

| Ch. | Title | Identities | Planned depth |
|---:|---|---|---:|
| 19 | **The renderer contract** | — | 22–28 pp |
| 20 | **Renderer selection and identity** | all 46 / 42 families | 18–22 pp |
| 21 | **OpenGL I: fixed-function profiles** | `OPENGL1` `OPENGL2` `OPENGLES1` plus EasyGL profile mechanism | 14–18 pp |
| 22 | **OpenGL II: programmable, web, and portable profiles** | `OPENGLES2` `OPENGLES3` `OPENGL33` `OPENGL4` `WEBGL1` `WEBGL2` `PORTABLEGL` | 16–20 pp |
| 23 | **Native modern GPU APIs** | `VULKAN` `SDL_GPU` `WEBGPU` `METAL` | 22–28 pp |
| 24 | **BGFX, Magnum, LLGL, and Diligent** | `BGFX` `MAGNUM` `LLGL` `DILIGENT` | 16–20 pp |
| 25 | **Abstraction layers II: Sokol, Wicked, and FNA3D** | `SOKOL` `WICKED` `FNA3D` | 16–20 pp |
| 26 | **The DirectX time machine: DirectX 1–3 and free-direct** | `DIRECTX1` `DIRECTX2` `DIRECTX3` `FREEDIRECT` | 16–20 pp |
| 27 | **The retro ladder: DirectX 5–8 and Glide** | `DIRECTX5` `DIRECTX6` `DIRECTX7` `DIRECTX8` `GLIDE` | 16–20 pp |
| 28 | **Modern Direct3D** | `DIRECTX9` `DIRECTX10` `DIRECTX11` `DIRECTX12` | 18–22 pp |
| 29 | **Windows 2D: Direct2D and GDI** | `DIRECT2D` `GDI` | 10–14 pp |
| 30 | **2D and vector rasterizers** | `SKIA` `BLEND2D` `OPENVG` `SDL_RENDERER` | 14–18 pp |
| 31 | **Web and DOM renderers** | `CANVAS` `HTML_DOM` `SVG_DOM` | 10–14 pp |
| 32 | **Non-GPU and diagnostic renderers** | `HEADLESS` `SOFTWARE` `STUB` | 10–14 pp |

Chapters 19–32 replace old Ch.16–25 by subject, not one-for-one. `ASCII` is not a renderer and
moves to the CNAEXT material; `DIRECTX3` and `FREEDIRECT` remain explicitly separate. The legacy
ladder is the edition's most distinctive renderer material: a modern API projected onto
1995–2000 APIs, guarded by eight mechanically enforced era-discipline gates.

### 4.3 Parts V–XII — content, 3D, framework services, foundations, platforms and practice

| Ch. | Title | Planned depth | Principal source / disposition |
|---:|---|---:|---|
| 33 | **Loading an asset: ContentManager and resolution** | 24–30 pp | Split from old Ch.08: façade, caches, resolution, manifest, unload and reader registration. |
| 34 | **The XNB container** | 20–25 pp | Split from old Ch.08: headers, compression, LZX/LZ4, limits and external fixtures. |
| 35 | **XNB type readers and object graphs** | 28–34 pp | Split from old Ch.08: registries, `std::any`, shared resources, full reader table and real gaps. |
| 36 | **CNJ: CNA's own content format** | 24–30 pp | Split from old Ch.08: envelopes, per-type versions, loaders, sidecars and hybrid parser. |
| 37 | **Robust content and asset boundaries** | 14–18 pp | New: limits/enforcement table, containment, fuzzing, differential oracles and remaining asymmetries. |
| 38 | **Models, meshes, and drawing** | 20–24 pp | Preserve and correct old Ch.12 as the XNA-surface runtime chapter. |
| 39 | **From glTF file to Model: the import core** | 16–18 pp | New: cgltf, scene graph, transforms, instances and runtime/offline split. |
| 40 | **GPU packing and the stride ABI** | 14–16 pp | New: seven layouts, vtable inflation, indices, topology and hard caps. |
| 41 | **Skinning and animation across two systems** | 16–18 pp | New: two runtimes, joint ordering, prefix transforms, morphs and D8. |
| 42 | **The CNJ model toolchain** | 12–14 pp | New: `gltf_to_cnj`, v2 schema, sidecars, offline/runtime parity and material approximations. |
| 43 | **glTF conformance and oracles** | 18–20 pp | New flagship: spec pin, generator, digests, five-of-seven layers and executable defect ledger. |
| 44 | **The input system** | 22–28 pp | Update/expand old Ch.26; retain its event-driven architecture and add coordinate transforms and exact constants. |
| 45 | **The audio system** | 22–28 pp | Expand old Ch.27: SDL3_mixer object/lifetime model, decode matrix, formulas, XNB audio and offline rendering. |
| 46 | **The media system** | 14–18 pp | Light revision of old Ch.28; correct counts, codec claims, platform guard and audio cycle. |
| 47 | **Sensors and Microsoft.Devices** | 18–22 pp | First half of old Ch.29 rewrite: Android/desktop split, delivery, concurrency, math and evidence limits. |
| 48 | **Host integration through CNA.Devices** | 16–20 pp | Second half of old Ch.29 rewrite: off-by-default gate, clipboard/power/camera/haptics and shutdown coordination. |
| 49 | **GamerServices and local identity** | 18–22 pp | Expand old Ch.30: exact persistence, silent Guide calls, dispatcher hang family and synthetic gamers. |
| 50 | **Storage and persistence boundaries** | 16–20 pp | Rewrite old Ch.33 adjacent to Ch.49: shared root, selectors, containment asymmetry and live traversal defect. |
| 51 | **Networking and session semantics** | 22–28 pp | Correct/expand old Ch.31: Local non-delivery, protocol, topology, ENet mapping, hostile input and web divergence. |
| 52 | **Avatar: faithful absence and CNAEXT rendering** | 18–22 pp | Correct/expand old Ch.32: inert XNA surface, real EXT path, evidence tiers and remaining visual defect. |
| 53 | **Why sharp-runtime exists** | 14–18 pp | Rebuild old Ch.34: role, history, scope and CNA co-evolution. |
| 54 | **Components and CNA integration** | 16–20 pp | New: 44 components, registries, umbrellas, dual-shape adapter and 18 closures. |
| 55 | **The object model, honestly** | 16–20 pp | New: `Object`, non-instantiable `String`, exception ancestry, delegates, reflection limits and ownership. |
| 56 | **Namespaces, types, and include paths** | 18–22 pp | Re-derive old Ch.35 against the component graph. |
| 57 | **Parity and permanent deviations** | 16–20 pp | Expand old Ch.36 with complete deviation taxonomy and frozen naming conventions. |
| 58 | **Verification and audit in sharp-runtime** | 14–18 pp | New: per-component isolation, negative consumers, meta-tests and frozen audit numbering. |
| 59 | **easy-gl and meta-gl: profile, loader, and dispatch** | 18–22 pp | Rebuild old Ch.37 around the current split and public-history rewrite. |
| 60 | **free-direct and free-api** | 18–22 pp | Merge old Ch.25's library material with old Ch.38: three APIs, status census, pimpl/macro hazard and consumers. |
| 61 | **The cross-platform contract** | 14–18 pp | New: CMake target selection over preprocessor branching, SDL3 as platform layer and admissibility vs proof. |
| 62 | **Windows I: cross-compiling from Linux** | 12–16 pp | Split old Ch.39: toolchain, SDL cache, staging and the i686 wall. |
| 63 | **Windows II: Wine and engagement gates** | 16–20 pp | Split old Ch.39: six prefixes, translation runtimes, log gates, workarounds and honest gaps. |
| 64 | **Web I: C++23 to WebAssembly** | 12–16 pp | Split old Ch.40: flags, ABI, assets, single-threading, MEMFS and network topology. |
| 65 | **Web II: the main-loop problem** | 12–16 pp | Split old Ch.40: exception unwinding failure, diagnosis, fix and lifecycle divergence. |
| 66 | **Web III: five renderers, four kinds of evidence** | 12–16 pp | Split old Ch.40: DOM/SVG/Canvas/WebGL harnesses and compositor-level checking. |
| 67 | **Android, macOS, and platforms not yet reached** | 16–20 pp | Rewrite old Ch.41; include TitleContainer gap, NDK sensors, Metal evidence and explicit iOS refusal. |
| 68 | **The CnaTests architecture** | 12–16 pp | Replace old Ch.42/48 opening: glob/filter contract, discovery, skips, isolation and compile-must-fail tests. |
| 69 | **Counting discipline** | 10–14 pp | New: distinguish sources, macros, registrations and executables; reproducible derivations only. |
| 70 | **Oracles: what does “correct” mean?** | 16–20 pp | New flagship: XNA pixels, CNA goldens, FNA values, tolerances and oracle taxonomy. |
| 71 | **Verification in hostile environments** | 14–18 pp | New: compare Wine/Proton/browser verdict channels and prove that the intended runtime engaged. |
| 72 | **Discipline as a test** | 12–16 pp | New: era gates, link closures, identity checks, meta-validation, mutation and gate self-tests. |
| 73 | **What CI actually runs** | 10–14 pp | New: workflow reality, sanitizers, validation, fuzzing, property tests and the absence of code coverage. |
| 74 | **Migrating an XNA or FNA game to CNA** | 18–22 pp | Correct old Ch.43 against current content, renderer, build and platform reality. |
| 75 | **Case study: Speedy Blupi and Planet Blupi** | 18–22 pp | Preserve old Ch.44; refresh renderer names and cross-links. |
| 76 | **Auditing compatibility with xna4-spec** | 14–18 pp | Preserve old Ch.45; clarify where executable oracles, not API inventories, decide behaviour. |
| 77 | **cna-samples and cna-examples** | 14–18 pp | Refresh old Ch.46 against the pin and Part XI's evidence vocabulary. |
| 78 | **Project practice and durable task tracking** | 14–18 pp | Refresh old Ch.47; fold in lessons from source-partition and glTF defect ledgers. |
| 79 | **Roadmap, open gaps, and how to re-audit this book** | 12–16 pp | Rewrite old Ch.49 from code; no stale `.xnb`/`.fx` headline and no unqualified counts. |

Part titles are fixed as follows: I **CNA and Its Ecosystem**; II **Architecture, Building, and
the Framework**; III **The Graphics Machine**; IV **The Renderers**; V **The Content Pipeline**;
VI **3D Content: Models, glTF, and Conformance**; VII **Input, Audio, Media, Devices, Networking,
and Services**; VIII **sharp-runtime: The Foundation Layer**; IX **Sibling Foundation
Libraries**; X **Cross-Platform Engineering**; XI **Testing and Verification**; XII **Porting,
Practice, and the Road Ahead**.

### 4.4 Old-to-new chapter disposition

This map is the migration checklist. “Rebuild” means preserve sourced material selectively, not
blindly move stale prose.

| Old chapter(s) | New chapter(s) | Action |
|---|---|---|
| 01 | 1 | Rewrite. |
| 02 | 2, 53, 59, 60 | Rebuild the map; move library depth to its owning Part. |
| 03 | 3 and Appendix E | Rebuild conventions; move the catalog out. |
| 04 | 4, 9–11 | Split build, architecture and tooling. |
| 05 | 5 | Update in place after renumbering. |
| 06 | 6 | Correct and expand. |
| 07 | 7–8 | Split at the math/geometry seam. |
| 08 | 33–37 | Split by façade, XNB container, reader architecture, CNJ and security. |
| 09–11, 13–15 | 12–17 | Rebuild renderer-independent graphics chapters; Ch.17 replaces the old `.fx gap` premise. |
| 12 | 38 | Move to the 3D Part and correct four asset routes. |
| 16–24 | 19–32 | Recluster; no renderer chapter is migrated one-for-one. ASCII moves to Appendix E. |
| 25 and 38 | 26 and 60 | Separate the `DIRECTX3`/`FREEDIRECT` renderers; merge the free-direct library prose. |
| 26–28 | 44–46 | Update/expand. |
| 29 | 47–48 | Split faithful Sensors from off-by-default CNA.Devices. |
| 30, 33 | 49–50 | Keep adjacent because both use the same storage root; rewrite Storage's central narrative. |
| 31–32 | 51–52 | Correct and expand. |
| 34–36 | 53–58 | Expand three chapters to six around modules, object model and verification. |
| 37 | 59 | Rebuild as the easy-gl/meta-gl split. |
| 39 | 62–63 | Split cross-compilation from runtime verification. |
| 40 | 64–66 | Split compiler/ABI, lifecycle, and renderer evidence. |
| 41 | 67 | Expand to the platforms-not-reached matrix. |
| 42 and 48 | 68–73 | Replace both with the dedicated verification Part; eliminate duplicate methodology prose. |
| 43–47 | 74–78 | Refresh and retain their practical roles. |
| 49 | 79 | Rewrite from the pinned source and the new evidence vocabulary. |

### 4.5 Appendices

| Appendix | Settled title and source |
|---|---|
| A | **Core Framework and Graphics API Reference** — rebuild after chapter writing. |
| B | **Renderer Registry, Capabilities, and Evidence** — derive the registry from `docs/renderer-registry.md` plus code; never copy `docs/graphics-renderer-feature-matrix.md`. |
| C | **Glossary of XNA and CNA Terms** — terminology authority; old spellings historical only. |
| D | **Repository and Module Map** — sibling repositories plus the physical `modules/` tree. |
| E | **CNAEXT: Marker and Engine-Layer Catalog** — replace the NOXNA appendix using the two-meanings framing; include `AsciiPostProcessEffect`. |
| F | **Ecosystem and Platform Quick Reference** — refresh after Parts VIII–X. |
| G | **Verification Tiers and Oracles** — state what each renderer/platform is actually proven to do. |
| H | **glTF Importer / Runtime / Test-Evidence Matrix** — preserve the three columns; never flatten “parsed” and “played” into one support bit. |

---

## 5. Standing rules for this edition

1. **Print "46 identities / 42 families", both labelled, every time.** Four conflicting counts
   coexist in the CNA tree. Cite `docs/renderer-registry.md`; never
   `scripts/check_renderer_identities.py`'s docstring, `cmake/Tests/ModuleProbes.cmake:6`,
   `docs/svg-dom-renderer.md:233`, `MODULARIZATION_PLAN.md`,
   `modularization/renderer-naming/VALIDATION.md`, or `docs/RendererNamingMigration.md` §5.
2. **"The importer parses it" and "the runtime plays it" are separate claims.** Never collapse
   them. Same for "a test exists" versus "a test passes" versus "a pixel was compared".
3. **Skip is not pass.** Without a display, CNA's entire pixel and golden layer becomes
   `SKIPPED` (exit 77) and CTest reports green.
4. **Never quote a test count from any `docs/*.md` or `plan_*.md`.** Those are dated run
   snapshots from different SHAs on different renderers. Derive numbers with the commands
   recorded in `audit/testing-verification.md`, and always state the definition beside the number.
5. **Never source a content claim from `xnb.md`, `docs/migration-guide.md`,
   `docs/xna-4-api-coverage.md`, `docs/coverage.md`, `docs/README.md` or CNA's `AUDIT.md`.** All
   six still assert CNA cannot read `.xnb`. It can.
6. **Never cite `gltfissues.md`, `FUTURE.md`, CNA's `audit/**` tree, or `plan_gltf.md` §29 prose
   as current state.** Each is stale in a way that would put a wrong claim in print.
7. **C++23 is a toolchain floor.** CNA uses zero C++23 headline features and zero C++20 concepts.
   Say "compiled as C++23; written in a disciplined C++17/20 idiom."
8. **"CNA" is never expanded anywhere in the ecosystem.** Do not invent an expansion.
9. **CNA is read-only.** Defects found belong in `AUDIT.md` §5.1 and an upstream issue tracker,
   never in a patch from this repository.
10. **A log-clean build is not a verified build.** Only rendering the page and reading it counts.
    Proven again on 2026-08-11: a doubled-backslash `\ref` produced no error, no warning and no
    undefined reference, and rendered as a line break plus literal text.

---

## 6. Verification checkpoints

`tools/verify-book.sh` runs the build plus reference, duplicate-label, index, stale-term and
whitespace checks in one pass. `tools/render-pages.sh FIRST LAST` drives the visual pass that no
log grep replaces.

| Date | Event | Result |
|---|---|---|
| 2026-08-11 | Baseline at session start | 575 pages, latexmk reports all targets up to date |
| 2026-08-11 | After migrating 112 chapter references to `\ref{}` | **575 pages**, build clean; makeindex 2,367 entries / 0 rejected / 0 warnings; no undefined references, no duplicate labels, no doubled-backslash refs, no hard-coded chapter numbers; `git diff --check` clean; Appendix E pages 559–560 rendered and visually verified |
| 2026-08-11 | Phase C structural migration | **645 pages**, build clean; makeindex 2,367 / 0 / 0; 12 Parts, 79 chapter inputs/files, 8 appendix inputs/files; all old labels preserved, no missing/duplicate labels or inputs, exact Ch.01–79 order; all 645 pages reviewed as 26 contact sheets, affected title pages inspected at full size, one real Ch.18 title overflow and fifteen poor mid-word title breaks fixed and re-rendered clean |
| 2026-08-11 | Phase C terminology/path completion | **645 pages**, build clean; makeindex 2,365 / 0 / 0; current renderer/CNAEXT identifiers and selectors; graphics “backend” removed from live prose while service backends remain; CNA citations migrated to `modules/<owner>/…` and existence-checked against the pin; all 645 pages re-rendered and reviewed as 26 contact sheets, with registry, Storage, preface, and long-path pages inspected full-size |
| 2026-08-11 | Renderer draw-path matrix | **42/42 families, 46/46 identities**; 31 dual overrides / 11 dual inheritances; four hybrid colored tails; RT2D/MRT/occlusion paths mapped; capability contradictions recorded as CNA-BUG-054; row and partition counts mechanically checked; `git diff --check` clean |
| 2026-08-11 | Phase D batch 1, Chapters 19–27 | **661 pages**, build clean; makeindex 2,378 / 0 / 0; renderer contract and selection corrected; OpenGL material separated into compatibility and programmable families; native-modern, wrapper, and retro clusters cover all assigned identities; physical PDF pages 194–303 rendered and reviewed as 11 contact sheets; no clipping, overlap, broken page, undefined reference, duplicate label, stale selector, or whitespace error |
| 2026-08-11 | Phase D batch 2, Chapters 28–36 | **661 pages**, build clean; makeindex 2,345 / 0 / 0; Part IV completed across all 46 identities / 42 families; old combined Content chapter split without losing its reader material; XNB container, object graph, and CNJ each have a separate source-grounded chapter; physical pages 304–391 rendered and reviewed as 9 contact sheets; all automated and visual checks green |
| 2026-08-12 | Phase D batch 3, Chapters 37–45 | **675 pages**, build clean; makeindex 2,392 / 0 / 0; content failure boundaries completed; four model routes corrected; glTF import, stride ABI, dual skeletal systems, CNJ toolchain and five-of-seven oracle ladder written; Input and Audio reconciled to current source; physical pages 392–455 rendered and reviewed as 8 contact sheets with high-risk tables/equations inspected full-size; all automated and visual checks green |

---

## 7. Unresolved questions for the project owner

None blocking. One environment note: TeX Live was absent at session start and was installed
mid-session at the owner's direction, so the build and visual passes are available again.

---

## 8. Session log

### 2026-08-11 — new edition opened

- Pinned CNA `7a64362e`; confirmed `develop` == `origin/develop`; recorded all eleven sibling
  repository HEADs.
- Established `AUDIT.md` as the canonical audit matrix and contradiction log, and `audit/` as raw
  per-area evidence.
- Added `tools/verify-book.sh` and `tools/render-pages.sh`.
- Ran ten parallel read-only research passes; six delivered.
- Recorded 19+ contradictions between CNA's own documentation and its implementation, and 10
  undocumented CNA defects, each with `path:line` provenance.
- Migrated all 112 hard-coded chapter-number references (two distinct styles, `Chapter~N` and
  `Ch.N`) to `\ref{}`; caught and fixed a doubled-backslash regression that only the visual pass
  could detect, and added a check for that exact shape.
- Archived the previous `PLAN.md`/`NEXT.md` and opened this plan.

### 2026-08-11 — Phase B: new Table of Contents settled

- Synthesised all ten audit reports into one non-overlapping content architecture: **12 Parts,
  79 chapters and 8 appendices** (§4).
- Kept Part IV's already-settled renderer taxonomy and allocated its eight clusters across 14
  chapters while preserving the exact **46 identities / 42 implementation families** partition.
- Promoted Content, 3D/glTF, and Testing/Verification to dedicated Parts; split Math and Devices;
  expanded sharp-runtime from three to six chapters; merged the two undersized free-direct
  treatments into one library chapter separate from CNA's `FREEDIRECT` renderer coverage.
- Added a complete old-Ch.01–49 disposition map so Phase C has an explicit migration checklist;
  no existing chapter is silently discarded.
- Settled all appendix roles, including a two-meaning CNAEXT catalog, verification tiers, and a
  three-column glTF importer/runtime/evidence matrix.

### 2026-08-11 — Phase C structural migration checkpoint

- Replaced the nine-Part / 49-chapter / six-appendix filesystem and `main.tex` structure with
  the settled **12 Parts / 79 chapters / 8 appendices**. All 49 old chapter sources remain in
  the new tree; 32 new chapters and Appendices G/H are explicit Phase C placeholders, not
  invented prose.
- Preserved every old semantic label and added labels for every new chapter. Verified 79
  sequential chapter inputs and files, eight appendix inputs and files, zero missing inputs,
  zero lost old labels and zero duplicate labels.
- Reclustered the three existing native-modern renderer chapters without discarding prose:
  Vulkan remains the Chapter 23 base and the old WebGPU/SDL GPU chapters compile as labelled
  legacy sections until Part IV's source-grounded rewrite.
- Updated `README.md` and `CLAUDE.md` to the 12-Part / 79-chapter structure and renderer
  terminology at the repository-summary level.
- Ran `tools/verify-book.sh`: **645 pages**, makeindex 2,367 accepted / 0 rejected / 0 warnings,
  all reference/label/stale-number/whitespace checks green.
- Applied the PDF skill's complete visual workflow: rendered all 645 pages into 26 contact
  sheets, inspected every sheet, opened suspicious pages at 100–120 dpi, fixed one real Ch.18
  title overflow plus fifteen ugly mid-word chapter-title breaks, rebuilt, and re-rendered the
  affected pages clean.

### 2026-08-11 — Phase C terminology and path migration complete

- Migrated the compiled manuscript to the pinned renderer vocabulary and identifiers:
  `IGraphicsRenderer`, `GraphicsRendererType`, `CNA_GRAPHICS_RENDERER`, `CNA_RENDERER_*`, and
  `CNAEXT`. Kept “backend” only for the still-live input, devices, media, network, and platform
  concepts; preserved old graphics spellings only where they are explicitly historical.
- Replaced removed selectors with the current public identities, distinguished `FREEDIRECT`
  from the genuine `DIRECTX3`, documented the five EasyGL profiles, and made the current
  **46 identities / 42 implementation families** registry the leading Appendix B table.
- Migrated CNA-owned test, example, header, and source citations into their physical
  `modules/<owner>/…` trees and existence-checked every explicit module file against the pinned
  CNA checkout. Corrected the Storage test boundary uncovered by that sweep: five
  `StorageDevice` cases exist, while `StorageContainer` remains untested.
- Extended `tools/verify-book.sh` to reject removed identifiers, selector assignments, and
  legacy renderer macros.
- Ran the consolidated build and complete PDF workflow again: 645 pages; makeindex 2,365
  accepted / 0 rejected / 0 warnings; all automated checks green; all 645 pages rendered into
  26 contact sheets and inspected, with registry, Storage, preface, and long-path pages read at
  full size. Phase C closed here; the §3.2 matrix was the next task and is closed in the entry
  below.

### 2026-08-11 — renderer draw-path research prerequisite closed

- Audited all 42 renderer-family implementations for both ordinary effect-aware draw routes,
  RenderTarget2D, MRT and occlusion-query behavior; recorded the source-grounded matrix in
  `audit/renderer-draw-path-matrix.md`.
- Distinguished 31 dual overrides from 11 dual inheritances, then inspected the terminal behavior
  rather than trusting declarations: DIRECTX10 is the sole unconditional inherited colored
  downgrade, while OPENGLES1/SDL_GPU/OPENGL4/WEBGPU retain conditional colored tails.
- Found and recorded the additional default-true capability contradictions in CNA-BUG-054;
  corrected `AUDIT.md` F-031's formerly over-broad statement that every inherited fallback
  necessarily renders a wrong picture.
- Phase D is now unblocked.

### 2026-08-11 — Phase D batch 1: Chapters 19–27

- Corrected the renderer contract and selection chapters against the complete 42-family matrix,
  including all 13 capability flags, default-true polarity, the DIRECTX10 unconditional
  downgrade, four hybrid draw tails, and the MRT/query capability contradictions.
- Reassigned the old EasyGL prose from Chapter 21 to Chapter 22 without losing its compatibility
  label; rebuilt Chapter 21 around OPENGL1, OPENGL2, and OPENGLES1, then added OPENGL4 and
  PORTABLEGL to Chapter 22.
- Extended the native-modern chapter across VULKAN, SDL_GPU, WEBGPU, and METAL; completed both
  abstraction-layer chapters across BGFX, MAGNUM, LLGL, DILIGENT, SOKOL, WICKED, and FNA3D.
- Added the full historical renderer ladder: DIRECTX1/2/3 and FREEDIRECT in Chapter 26,
  DIRECTX5/6/7/8 and GLIDE in Chapter 27, with API ceilings and evidence tiers kept separate.
- Ran the consolidated verification pass: 661 pages, makeindex 2,378 accepted / 0 rejected /
  0 warnings, every automated check green. Rendered physical pages 194–303 and inspected all
  110 pages in 11 contact sheets; the new chapter openers, tables, notes, listings, and
  transitions are visually clean.

### 2026-08-11 — Phase D batch 2: Chapters 28–36

- Completed Part IV: added DIRECTX10's silent extended-draw downgrade to Chapter 28, wrote the
  Direct2D/GDI and diagnostic chapters, expanded the 2D/vector cluster across SDL Renderer,
  Skia, Blend2D and OpenVG, and replaced the removed ASCII renderer with the current Canvas,
  HTML DOM and SVG DOM cluster plus a historical pointer to the post-process effect.
- Mechanically split the old 2,248-line combined Content chapter at the audited subsystem seams.
  Chapter 33 retains resolution, caches, lifetime, manifest and media dispatch; Chapter 35
  preserves the detailed ContentReader/ContentTypeReader and concrete-reader material.
- Wrote a separate XNB container chapter around the ten-byte header, four-valued compression,
  stateful LZX, canonical reader names, enforcement limits and the uncapped initial read.
- Wrote the CNJ chapter around its JSON envelope, per-type version ceilings, enforced
  sourceFile matrix, hybrid parser split, custom loader contract and binary sidecars.
- Verified the consolidated 661-page PDF with 2,345 accepted index entries and no rejected or
  warned entries. Rendered physical pages 304–391 and reviewed all 88 as nine contact sheets;
  every touched page and the Part IV-to-V transition are visually clean.

### 2026-08-12 — Phase D batch 3: Chapters 37–45

- Replaced the content-robustness placeholder with the real enforcement matrix: decompression,
  depth/count limits, contained internal references, fuzz entry points, the independent FNA LZX
  oracle, exception asymmetries and the remaining uncapped edges.
- Corrected the Model chapter from three routes to four and wrote the complete five-chapter 3D
  sequence: one import core/two consumers, seven glTF stride layouts versus the eight-case upload
  switch, two independent skeleton runtimes and the D8 root prefix, CNJ Model v2/tool output, and
  the seven-layer conformance ladder with L1--L5 implemented and D5--D7 kept honest.
- Reconciled Input to 522 cases, four pad slots, exact dead zones, 160 keys/125-versus-126 maps,
  all ten gestures, unconditional CNA::Input extensions, default-build Clipboard/Power overlap,
  and the latent missing `SDL_INIT_SENSOR` initialization.
- Reconciled Audio to the `MIX_Mixer`/`MIX_Audio`/`MIX_Track` lifetime model, real codec matrix,
  exact attenuation/pan/pitch/Doppler formulas, five XNB formats, uncapped fire-and-forget tracks,
  non-operational `InstancePlayLimitException`, partial `REPLACE_QUIETEST`, mixer pinning and the
  device-free `OfflineAudioRenderer`; retained the three unchecked release blockers explicitly.
- Ran `tools/verify-book.sh`: 675 pages, makeindex 2,392 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered physical pages 392–455 and reviewed all 64 as eight contact
  sheets; inspected the stride table, defect ledger and audio equations at full size. No clipping,
  overlap, broken float, unreadable table, stale reference or visual defect remains in the batch.
