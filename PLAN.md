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
| **D — chapter writing** | **Complete.** Seven verified batches rewrote Chapters 19–79 against the pinned source and sibling evidence. |
| **E — appendices** | **Complete.** Appendices A–H were rebuilt against pinned source and the completed chapter text, then verified as one bounded batch. |
| **F — whole-book consistency** | **In progress.** Ten verified corrective batches removed stale totals/terminology, filled five structurally present but unwritten chapters (8–11 and 18), and reconciled lifecycle, math, graphics, renderer, Content/XNB and Model/glTF/CNJ claims with pinned evidence. Continue the edition-wide factual, cross-reference, duplication, index and visual sweep. |
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
| 2026-08-12 | Phase D batch 4, Chapters 46–54 | **683 pages**, build clean; makeindex 2,395 / 0 / 0; Media, Devices, GamerServices, Storage, networking, Avatar and sharp-runtime integration rewritten against current source; physical pages 456–523 rendered and reviewed; one long-path overflow fixed and re-rendered cleanly |
| 2026-08-12 | Phase D batch 5, Chapters 55–63 | **691 pages**, build clean; makeindex 2,396 / 0 / 0; sharp-runtime object model and audit layers, sibling foundation libraries, platform contract, MinGW cross-build and Wine engagement completed; physical pages 523–573 rendered and reviewed; one table overlap fixed and re-rendered cleanly |
| 2026-08-12 | Phase D batch 6, Chapters 64–72 | **689 pages**, build clean; makeindex 2,369 / 0 / 0; Web build/main-loop/evidence split, Android/macOS evidence boundary, CnaTests architecture, reproducible counting, oracle taxonomy, hostile-host verification and discipline gates completed; physical pages 573–607 rendered and reviewed as 9 contact sheets, with tables and long literals inspected full-size; all automated and visual checks green |
| 2026-08-12 | Phase D batch 7, Chapters 73–79 | **685 pages**, build clean; makeindex 2,289 / 0 / 0; current CI execution boundary, migration procedure, Blupi case study, critical xna4-spec use, samples/examples catalogs, durable project practice and source-grounded roadmap completed; physical pages 607–640 rendered and reviewed as 4 contact sheets through the Appendix A boundary, with the performance table, long headings, lists and query literals inspected full-size; all automated and visual checks green |
| 2026-08-12 | Phase E, Appendices A–H | **685 pages**, build clean; makeindex 2,096 / 0 / 0; stale exhaustive catalogs replaced by source-oriented API, renderer, repository, CNAEXT, ecosystem, verification and glTF evidence references; physical pages 641–678 rendered and reviewed as 5 contact sheets, high-risk tables inspected full-size, five identifier/factor collisions corrected and re-rendered clean; final index page 685 also inspected |
| 2026-08-12 | Phase F corrective batch 1 | **699 pages**, build clean; makeindex 2,179 / 0 / 0; stale context-free 6,171-test claims removed, residual graphics uses of “backend” corrected, and previously title-only Chapters 8–11 and 18 written from pinned source evidence; physical pages 107–126 and 203–210 plus 13 isolated terminology/count pages rendered and read, with the Chapter 8 layout table and Chapter 18 interface names inspected full-size; all detected overflows corrected and re-rendered clean |
| 2026-08-12 | Phase F corrective batch 2 | **703 pages**, build clean; makeindex 2,176 / 0 / 0; early identity/build/graphics/effects and service-lifecycle drift reconciled, recorded test campaigns separated from universal totals, verifier manual terms made whole-word exact; 31 touched physical pages rendered and read as six contact sheets, all visually clean |
| 2026-08-12 | Phase F corrective batch 4 | **707 pages**, build clean; makeindex 2,176 / 0 / 0; Chapter 17 separated stock reimplementation, D3D9 source recompilation, FNA3D/MojoShader stock-bytecode execution and renderer-specific ShaderEffect, while Chapters 2/17 dropped the stale 23-of-86 current-sample claim; physical page 42 and Chapter 17 pages 200–208 rendered and read, all visually clean |
| 2026-08-12 | Phase F corrective batch 5 | **707 pages**, build clean; makeindex 2,178 / 0 / 0; Chapters 16/18 reconciled to BlendWriteState, sampler-mip hooks, live SpriteBatch rasterizer routing, declaration exceptions, stream semantic composition and current capability contradictions; physical pages 191–200 and 209–216 rendered and read; one full-size overflow fixed and re-rendered clean |
| 2026-08-12 | Phase F corrective batch 6 | **707 pages**, build clean; makeindex 2,183 / 0 / 0; Chapters 19/22 reconciled to the complete vertex-stream and instancing bridge, current capability/refusal classes, coherent singular/plural bindings, live SpriteBatch state and EasyGL's post-remediation MRT/wireframe/fog/colour-mask/mip/viewport contracts; physical pages 235–239, 248–250 and 262–270 rendered and read, high-risk table/listing pages inspected full-size, all visually clean |
| 2026-08-12 | Phase F corrective batch 7 | **707 pages**, build clean; makeindex 2,161 / 0 / 0; normalized 2D/cube target binding, shared usage, aspect-selective ordered clears and per-command viewport/scissor semantics reconciled across the shared device and Vulkan/BGFX/WebGPU/SDL_GPU; current renderer-specific closures and bounded gaps recorded; Chapters 26–27 audited without correction; 31 touched physical pages rendered and read, dense matrices and representative renderer pages inspected full-size, all visually clean |
| 2026-08-12 | Phase F corrective batch 8 | **707 pages**, build clean; makeindex 2,168 / 0 / 0; D3D11/12 public cube transitions, D3D12 viewport/clear semantics, GDI composition/stencil/MSAA, SDL_RENDERER capability/refusal boundaries, SVG_DOM additive evidence and Software/Headless scope reconciled; shared cube/volume readback and RT-cube upload matrices converted from obsolete silent-no-op behavior to the current complete-or-refuse contract; 49 touched physical pages rendered and read, dense matrices inspected full-size, all visually clean |
| 2026-08-12 | Phase F corrective batch 9 | **707 pages**, build clean; makeindex 2,176 / 0 / 0; Chapters 33–35/37 reconciled to integrated content-path containment, live XNB name/object limits, checked texture arithmetic, exact Texture2D/raw-cube bytes, Texture2D mip/device admission, Texture3D capability refusal and SpriteFont default-character validation while retaining genuine 3D/cube mip/compressed-byte gaps; physical pages 337–388 rendered and read, dense reader/limits pages inspected full-size, all visually clean |
| 2026-08-12 | Phase F corrective batch 10 | **707 pages**, build clean; makeindex 2,182 / 0 / 0; Chapters 38–42 reconciled to the three live model-hierarchy routes, checked collection indices, external glTF URI boundary, eight-layout stride oracle, typed-index-pointer and CNJ validation gaps, exact skeletal/morph cubic behavior and skin-gated animation scope; Chapter 43 re-audited without correction; physical pages 421–448 rendered and read, dense ABI/animation/toolchain pages inspected full-size, all visually clean |

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

### 2026-08-12 — Phase D batches 4–6: Chapters 46–72

- Completed the framework-services, foundation-layer and sibling-library sequence through the
  platform contract and both Windows chapters, preserving only evidence supported by the pinned
  CNA tree. Two visual defects found in batches 4–5 were corrected and independently re-rendered.
- Split the former Web chapter into translation, host-owned main-loop lifetime, and renderer-
  specific browser evidence. The 12 repaired stack-lifetime entry points, one benchmark survivor,
  five Web-loop semantic differences, volatile MEMFS storage and five-renderer evidence matrix
  are now separate claims rather than one broad support statement.
- Rebuilt Android/macOS coverage around the two recorded AVD runs, absent durable artifacts,
  never-attempted Android graphics, partial lifecycle state machine, unreachable TitleContainer
  fallback, historical pre-adaptation Metal run and explicit iOS/tvOS rejection.
- Replaced the Testing Part's placeholders and stale comparative prose with the one-binary glob/
  filter architecture, runtime discovery, skip semantics, standalone corpus, counting grammar,
  XNA/FNA/CNA oracle hierarchy, Wine/Proton/browser engagement channels, structural gates,
  mutation sensitivity and actual automation boundary.
- Ran `tools/verify-book.sh`: 689 pages, makeindex 2,369 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered physical pages 573–607 and reviewed all 35 as nine contact
  sheets; inspected both tables, long monospace literals and gate lists at full size. No clipping,
  overlap, unreadable table, broken heading or other visual defect remains in batch 6.

### 2026-08-12 — Phase D batch 7: Chapters 73–79

- Replaced the CI chapter's workflow inventory with an execution-path audit: six automatic and
  two dispatch-only workflows, three dead obsolete-selector legs, the narrow Windows corpus,
  targeted sanitizer/validation coverage, deterministic fuzz cases, dry-run mutation and the
  absence of code-coverage measurement are now stated separately.
- Rewrote the migration, xna4-spec, samples/examples, project-practice and roadmap chapters from
  current pinned evidence. Preserved the Blupi case study's source audit while correcting CNJ and
  renderer terminology. Recorded the xna4-spec 550/544 contradiction, the 153-sample and 249-demo
  catalogs, sharp-runtime's query-derived task/ticket counts, and the 54-finding static-audit
  boundary without converting historical prose into current claims.
- Ran `tools/verify-book.sh`: 685 pages, makeindex 2,289 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered physical pages 607–640 and reviewed all 34 as four contact
  sheets; inspected the performance table, long headings, lists and database query at full size.
  No clipping, overlap, unreadable table, broken heading or other visual defect remains.

### 2026-08-12 — Phase E: Appendices A–H

- Rebuilt Appendix A as a bounded source-oriented core API map and Appendix B as the canonical
  **46-identity / 42-family** renderer registry and capability/evidence matrix. Reconciled the
  glossary, then replaced Appendix D's speculative organization catalog with the pinned
  repository graph, fourteen physical CNA modules, and the renderer-family directory map.
- Reframed Appendix E around the three distinct CNAEXT mechanisms: declaration marker,
  project-owned `CNA::*` namespaces, and the `CNA_CNAEXT` option / `CNA::CnaExt` target pair.
  Rebuilt Appendix F as a concise ecosystem and platform API reference with explicit host and
  evidence boundaries instead of inferred support.
- Replaced the placeholder Appendices G and H with operational references: twelve evidence forms,
  oracle authority and claim-vector rules in G; importer/runtime/evidence axes, the L1–L7 glTF
  oracle ladder, and D1–D8 known defect matrix in H.
- Ran `tools/verify-book.sh`: 685 pages, makeindex 2,096 accepted / 0 rejected / 0 warnings, every
  automated check green. Rendered physical pages 641–678 and reviewed the whole appendix range as
  five contact sheets, then inspected the dense renderer, repository, CNAEXT, ecosystem,
  verification and glTF tables at full size. The zoomed pass found five tight identifier/factor
  collisions; each was corrected, the full build repeated, and the affected pages re-rendered
  clean. Physical page 685 was also rendered to close the previously unchecked index tail.

### 2026-08-12 — Phase F corrective batch 1: omitted structural chapters and stale totals

- The whole-book sweep found that Chapters 8–11 and 18 had survived the structural migration as
  labels and titles only. Wrote all five from the pinned framework/math, architecture/build and
  graphics evidence: C++ value-layout boundaries, the fourteen-module monorepo, cycle/umbrella
  enforcement, dependency and tooling semantics, and vertex-stream/capability failure modes.
- Removed two stale claims that treated 6,171 as a universal current test count. Chapters 46 and
  51 now distinguish local statically counted definitions from configuration, registration and
  runtime populations and defer the counting model to Chapter~69. Corrected the remaining clear
  graphics uses of “backend” to renderer/route and removed obsolete Phase C placeholder comments.
- Ran `tools/verify-book.sh`: 699 pages, makeindex 2,179 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 107–126 and 203–210 plus pages 46,
  309, 349, 432, 444, 473, 514, 562, 591–592, 617–618 and 628. Full-size inspection exposed
  overflowing table cells and long identifiers in Chapters 8 and 18; after correction, the
  rebuild, log-range check and affected-page render were clean.

### 2026-08-12 — Phase F corrective batch 2: early-edition factual drift

- Reframed Chapter 1 around CNA as a source-translation target, current SDL3-default FNA, the
  46/42 registry, implemented content/media breadth, and evidence vectors instead of stale type
  percentages or test leaderboards. The D3D9 oracle is now described as a 39-scene registered
  zero-tolerance gate whose pass count still requires an identified run.
- Corrected Chapter 4's four submodule commands, the six-automatic/two-manual CI boundary, and
  the distinction among the `CNAEXT` marker, `CNA_CNAEXT` graphics-ext gate, and `CNA::CnaExt`
  umbrella. Removed stale unit-suite totals from Chapters 2, 23 and 24.
- Reconciled Chapters 12–15 with pinned source: GraphicsDevice texture slots are bookkeeping;
  state objects copy; manager reset events are forwarded exactly once; disposal reaches
  `UnloadContent`; SpriteBatch positions truncate while glyphs round; Skia admits 26 of 27
  Texture2D formats and 14 render-target formats; previously open AlphaTest/DualTexture vertex-
  color and formula defects are closed campaign evidence rather than current gaps.
- Corrected Audio's two distinct unresolved crash signatures and Networking's now-fixed
  `NetworkSessionAction` leak. Changed the verifier's manual-term grep to whole-word matching so
  labels such as `sec:noxna` and prose substrings no longer create false notices.
- Ran `tools/verify-book.sh`: 703 pages, makeindex 2,176 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 31–35, 38, 49–51, 53, 128, 130,
  133–134, 157, 167, 169, 175, 177, 181–182, 186–188, 269, 271, 278, 298, 473, 513 and 669 as
  six contact sheets. Chapter openers, source-note boxes, listings, long identifiers and the
  glossary were visually clean.

### 2026-08-12 — Phase F corrective batch 3: executable game-loop and math contracts

- Repaired all four Chapter 5 game examples against the live loop: each calls base `Update` and
  `Draw`, while `GraphicsDeviceManager::EndDraw` performs the sole `Present`. The prose now makes
  component and dispatcher loss explicit instead of teaching the stale README double-present
  pattern.
- Reconciled Chapter 6 with the completed framework audit: explicit service disposal reaches
  `Game::UnloadContent`; repeated disposal coverage is stated narrowly; `RunOneFrame` remains
  inactive; fixed-step `Draw` sees aggregated elapsed time; the Emscripten callback's clock,
  clamp, draw, lifecycle and singleton differences are tabulated; manager reset forwarding,
  GameWindow failure policy, dispatcher locking and the split exception hierarchy are current.
- Corrected Chapter 7's convention layer: matrix multiplication applies the left operand first,
  quaternion multiplication the right; depth is `[0,1]`; `ToColumnMajor` copies rather than
  transposes; the former Plane inverse-transpose example is replaced by the live aliased-
  transpose defect; Color's exact 141/140/139 counts and 24-byte object boundary are explicit.
  Added MathHelper/vector semantic divergences, unchecked degeneracies, Ray/Curve epsilon splits,
  exception-family asymmetry, marker-free bounds gaps and the 818-case/no-numeric-oracle evidence
  boundary.
- Ran `tools/verify-book.sh`: 705 pages, makeindex 2,173 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read every physical page 55–108 (the complete Chapters
  5–7 range) in fifteen contact sheets. The Emscripten table, listings, long identifiers, source
  warnings and all chapter boundaries were visually clean.

### 2026-08-12 — Phase F corrective batch 4: four shader answers and the real `.fx` boundary

- Rebuilt Chapter 17's premise against the pinned renderer tree. CNA-owned stock shader variants,
  D3D9's recompilation of six Microsoft/FNA sources, FNA3D's execution of six committed stock
  `.fxb` blobs through MojoShader, and public renderer-specific `ShaderEffect` are now four
  separate mechanisms rather than one alleged absence of bytecode support.
- Named the actual general-effect gap: the throwing public bytecode constructor and known-
  unsupported XNB reader have neither arbitrary-program loading nor reflected parameter plumbing
  through the closed `GpuDrawParams` contract. Preserved FNA3D's `CustomEffects == false` boundary
  and D3D9's measured 61-of-66 instruction-stream comparison.
- Removed the stale “23 of 86 samples” current-cost claim from Chapters 2 and 17. The early
  ecosystem overview now agrees with the pinned catalog chapter's 153 entries and warns that
  historical placeholders require retesting before they become present-tense compatibility data.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,176 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical page 42 plus every Chapter 17 page 200–208;
  the new headings, long identifiers, renderer matrix, listings and summary were visually clean.

### 2026-08-12 — Phase F corrective batch 5: state submission and vertex capability contracts

- Reconciled Chapter 16's binding bridge to current source. `BlendWriteState` now carries all four
  per-MRT color masks and the state-object sample mask, while the separate device sample mask and
  `RasterizerState.MultiSampleAntiAlias` remain CPU shadows. Max mip level and LOD bias reach a
  separate hook whose real support is limited to four explicit renderer decisions; AddressW and
  the vertex texture/sampler collections remain unforwarded.
- Corrected the three real depth-stencil presets, bounded the named comparison test to five of the
  eight enum values, and replaced the stale claim that `SpriteBatch::Begin` discards rasterizer
  state with its current copied/defaulted device submission. Kept EasyGL's plain-filter mip rule
  renderer-specific rather than presenting it as a universal CNA contract.
- Refined Chapter 18 around the intentional empty/zero-stride default declaration, semantic-pair
  composition and partial-duplicate rejection across streams. Added the current WebGPU and BGFX
  custom-effect false positives and contrasted them with FNA3D's truthful `false` despite its
  closed stock-bytecode path.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,178 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 191–200 and 209–216. Full-size review
  found one overflowing run of `DepthBuffer*` identifiers on page 195; after a legal line-break
  rewrite, the full build and affected-page render were repeated cleanly.

### 2026-08-12 — Phase F corrective batch 6: renderer transport and programmable-GL truth

- Replaced Chapter 19's pre-remediation declaration and instancing model. `SetVertexDeclaration`
  is required, `GpuDrawParams::vertexStreams` carries complete slot/buffer/stride/offset/frequency
  tuples by value on all three public draw routes, semantic-pair composition and per-stream range
  validation are explicit, and `MultiStreamVertexInput` gates only multiple streams of one rate.
- Rebuilt the old seven-callback table around current mechanism classes: Magnum's native full
  multistream path; EasyGL native divisors; Vulkan/bgfx/WebGPU record replication; D3D11/12 native
  step rates; D3D9's measured boundary; further Diligent/OpenGL/Sokol/Wicked callbacks; explicit
  FNA3D/Software refusals; and Headless/SDL GPU's remaining inherited-true hazards. Corrected the
  formerly stale singular/plural binding-state and `SpriteBatch::Begin` rasterizer claims.
- Reconciled Chapter 22 against current EasyGL source. Removed the obsolete MRT leak, ignored
  wireframe, clip-space fog, absent colour-mask, ignored-mip-request, lost custom viewport and
  historical three-failure claims. Documented the reusable/finalized MRT FBO, GL_LINES wireframe,
  FNA fog vector, per-MRT masks plus clear restoration, allocated explicit mip chains, live
  SpriteBatch viewport, current `SetDataRaw` helper, and factory-argument loss. Preserved the real
  unchecked ES3 base-vertex termination risk, RGBA8/recovery limits, effect unbind no-op and
  public 16-bit SpriteBatch ceiling.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,183 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 235–239, 248–250 and 262–270; the
  two-page instancing table and pages 237–238, 264 and 269 were inspected full-size. No clipping,
  overlap, broken listing, overfull box or other visual defect was found.

### 2026-08-12 — Phase F corrective batch 7: deferred target, clear and viewport truth

- Reconciled the shared `GraphicsDevice` contract across Chapters 12, 14 and 19: singular 2D and
  cube binds normalize through slot-aligned render-target descriptors; cube faces remain tracked;
  compatibility, duplicate-subresource and disposal validation is centralized; only
  `DiscardContents` discards; and color, depth and stencil clear aspects are independently masked.
- Replaced stale last-value accounts in Chapters 19, 23 and 24 and the WebGPU/SDL_GPU fragments
  with the current ordered replay model. Vulkan, BGFX, WebGPU and SDL_GPU preserve clear issue
  order across draw boundaries and snapshot viewport/scissor state per command or segment. Usage
  behavior covers 2D, cube, multisampled, depth and stencil targets without treating
  `PlatformContents` as discard.
- Updated renderer-specific evidence: BGFX supports one per-vertex plus one per-instance stream,
  emulates instance frequency by expansion and retains a non-GLSL matrix-construction fault;
  SDL_GPU closes its former bias, anisotropy, MRT lifetime, authored-mip and lazy-backbuffer-
  readback gaps while retaining three precisely bounded limits; WebGPU closes the SpriteBatch
  target-size and single-attachment blend gaps but retains wireframe, stencil-pipeline and custom-
  effect limits; Sokol's Texture3D claim is bounded to exact CPU voxel transfer, not shader-visible
  native volume textures. Chapters 26–27 were checked against the pin and needed no edit.
- Ran `tools/verify-book.sh` twice after the manuscript changes: 707 pages, makeindex 2,161
  accepted / 0 rejected / 0 warnings, all automated checks green. Rendered and read physical pages
  140, 154–155, 177, 197, 243–248, 274–277, 286–290, 294–301, 307–309 and 312 as five contact
  sheets; pages 244, 246, 248, 286, 289, 295, 299 and 307 were inspected full-size. No clipping,
  overlap, malformed listing, broken heading or other visual defect was found.

### 2026-08-12 — Phase F corrective batch 8: remaining renderer and cube-resource truth

- Reconciled Modern Direct3D with the current public contract. D3D11 and D3D12 track and finalize
  the active cube before every cube/2D/MRT/backbuffer transition, forward preserve policy, and
  expose exact rendered-face/mip/MSAA readback. D3D12 snapshots effective viewport state for every
  ordinary, extended, instanced and SpriteBatch command; its scissor remains full-target only.
  Clear now distinguishes the required bound color resource from a requested depth/stencil aspect
  that legally becomes a no-op when no DSV exists, and the shared mask queries depth and stencil
  attachments independently.
- Corrected the remaining 2D and diagnostic families. GDI is an independent `IGraphicsRenderer`
  that privately composes a software 2D core, adds standalone 8-bit stencil and opt-in CPU 4x
  backbuffer MSAA, while target resources remain color/stencil without depth/MSAA. SDL_RENDERER
  claims only additive blending across the thirteen capabilities, refuses unsupported cube/volume
  storage, and leaves only Wrap/Mirror blocked. SVG_DOM exposes browser-dependent `plus-lighter`
  but lacks a workflow that drives its optional host/browser pages. SOFTWARE's real CPU triangle,
  depth/stencil, multistream, stock-effect packet, cube-storage and sampling surface is separated
  from absent Texture3D/instancing/RT-cube and inherited MRT/query overclaims; HEADLESS remains
  trace/state validation without pixels.
- Replaced Chapter 19's pre-remediation cube/volume account with the boolean completion contract:
  public wrappers convert only a complete read/store and otherwise throw without touching the
  caller. Exact/refusal rows now cover EasyGL, Vulkan, BGFX, D3D9/11/12, WebGPU, SDL_GPU, LLGL,
  Skia, Software, Headless and the historical 2D cohort. The transition matrix records EasyGL's
  same-cube face-finalization limit, LLGL's unflushed-frame preserve bound, and the public D3D
  closure rather than relying only on direct-object smoke tests.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,168 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 176, 238–245 and 327–366 as three
  contact sheets; pages 240–242, 327 and 348 were inspected full-size. No clipping, overlap,
  malformed table, broken heading or other visual defect was found.

### 2026-08-12 — Phase F corrective batch 9: Content/XNB remediation truth

- Reconciled the three distinct path policies. Public \texttt{ContentManager::Load<T>} still
  accepts explicit absolute names; logical \texttt{ReadExternalReference<T>()} rejects rooted and
  above-root spellings before re-entering the manager; Song/Video and filesystem-shaped sidecars
  use weak-canonical containment, revalidate selected extension candidates, and confine an
  explicitly external XNB to its own bundle directory. Updated the focused evidence boundary
  without projecting symlink canonicalization onto the logical-only helper.
- Replaced the pre-remediation limits account. \texttt{maxStringBytes} is a post-read bound on raw
  type-reader names rather than every String, and the shared depth limit is live in both the
  generic type-name parser and RAII-guarded object dispatch. The initial whole-file read remains
  outside \texttt{maxFileSize}, so the book preserves that partial-control warning.
- Reconciled all three texture readers. Texture2D now checks multiplication, device axes, exact
  raw/DXT level bytes, level-zero-or-complete mip topology and matching existing instances.
  Texture3D and TextureCube use checked products; raw cube bytes are exact; Texture3D refuses a
  renderer without its capability; null/refused cube or volume uploads throw rather than silently
  succeeding. Their remaining permissive DXT sizing and mip-topology boundaries stay explicit.
  SpriteFont construction/set/fallback now enforce and test the default-character invariant.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,176 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 337–388 across Chapters 33–37. Six
  contact sheets plus a regenerated sRGB sheet for pages 373–381 showed no clipping, overlap,
  malformed table, broken heading or other visual defect.

### 2026-08-12 — Phase F corrective batch 10: Model, glTF and CNJ contract truth

- Replaced the obsolete single-root description with the three actual hierarchy routes: direct
  glTF's synthetic identity root and parent-before-child selected-scene nodes, CNJ v2's complete
  serialized bone array, and the root-plus-mesh-child legacy fallback. Corrected the worked draw
  loop to use `ModelMesh*`, and recorded checked mesh-part/effect indices, shared graph ownership,
  hand-built lifetime obligations and the unsynchronised process-wide draw scratch vector.
- Tightened the import boundary to the actual parser behavior. A present `asset.version` must be
  `2.0`, but absence and `asset.minVersion` are not rejected by the front end; required extensions
  are not enforced; and percent-decoded external buffers/images are joined without canonical
  asset-tree containment. The importer therefore remains a loader, not an untrusted-file sandbox.
- Reconciled the byte and animation contracts. The glTF extractor emits seven layouts while the
  diagnostic declaration oracle covers all eight upload strides; a hand-written CNJ can still
  select an unknown positive stride without uploading bytes. Both live index handoffs form typed
  pointers from byte storage. Skeletal cubic channels are sampled with Hermite at union times but
  stored without tangents/modes and subsequently linearly/spherically approximated, whereas morph
  cubic tangents remain live. Negative-parent, negative-count and skin-gated D6 boundaries are
  explicit.
- Documented CNJ v2's remaining producer-versus-reader distinction: the root record is not fully
  honoured, later parents need not precede children, malformed transforms become identity, sidecar
  lengths truncate to element counts, and an incomplete optional skeleton-prefix block is ignored.
  Re-audited Chapter 43's corpus/task/defect counts and D6/D7 scope without finding stale prose.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,182 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 421–448 across Chapters 38–42 as seven
  contact sheets; pages 437–444 were also read from the original full-resolution renders. No
  clipping, overlap, malformed table/listing, broken heading or other visual defect was found.
