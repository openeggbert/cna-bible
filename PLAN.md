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
| `develop` vs `origin/develop` at pin time | identical; no divergence, no fetch needed |
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

Later branch movement does not silently advance this edition's evidence baseline. A read-only
postflight on 2026-08-12 observed these descendants after the audit had closed:

| Repo | Pinned commit | Later observed HEAD | Relationship and disposition |
|---|---|---|---|
| `cna` | `7a64362e` | `d316653a` | one direct descendant adding only root-level proposal document `cnaplatform.md`; no audited code or tests changed; pin retained |
| `cna-template` | `1d86681` | `4d0a2c8` | three descendants with a material renderer/build/demo rewrite; intentionally outside this edition; pin retained pending a future bounded re-audit |

All other locally available sibling HEADs in the table still matched their recorded pins at that
postflight. A moving branch name is never evidence for silently replacing a recorded commit.

---

## 3. Phase status

| Phase | State |
|---|---|
| **A — source audit** | **Complete. 10 of 10 areas delivered and on disk in `audit/`.** |
| **B — new Table of Contents** | **Complete.** The 12-Part / 79-chapter structure, appendices and old-to-new disposition map are settled in §4. |
| **C — structural migration** | **Complete.** The 12-Part / 79-chapter / 8-appendix migration, context-sensitive terminology pass, current selector/identifier migration, and module-owned source-path sweep are complete and PDF-verified clean at 645 pages. |
| **D — chapter writing** | **Complete.** Seven verified batches rewrote Chapters 19–79 against the pinned source and sibling evidence. |
| **E — appendices** | **Complete.** Appendices A–H were rebuilt against pinned source and the completed chapter text, then verified as one bounded batch. |
| **F — whole-book consistency** | **Complete.** Twenty-one verified corrective batches removed stale totals/terminology, filled five structurally present but unwritten chapters (8–11 and 18), reconciled every subject area with pinned evidence, made structural references durable, expanded the index into a whole-book navigation surface, and completed two edition-wide visual passes. |
| **G — final verification** | **Complete.** The 709-page release artifact is readable, unencrypted A4; all 27 fonts are embedded, subsetted and Unicode-mapped; its outline contains 12 Parts, 79 chapters and 8 appendices; its full text layer stays inside every physical page; and the complete automated and visual suites are green. |

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
| 2026-08-12 | Phase F corrective batch 11 | **707 pages**, build clean; makeindex 2,184 / 0 / 0; Chapters 44–48 reconciled to live input state/drain semantics, dynamic-audio and microphone gaps, Media ownership/codec truth, sensor dispatch/lifecycle distinctions and optional host-device callback boundaries; physical pages 455–498 rendered and read as six contact sheets, RAII and concurrency pages inspected full-size, all visually clean |
| 2026-08-12 | Phase F corrective batch 12 | **707 pages**, build clean; makeindex 2,188 / 0 / 0; Chapters 49–52 reconciled to GamerServices persistence/replay, Storage path/disposal, networking migration/receive/stub and Avatar content/rig/rendering contracts; physical pages 499–530 rendered and read as eight contact sheets, dense examples and repaired closing pages inspected full-size, all visually clean |
| 2026-08-12 | Phase F corrective batch 13 | **707 pages**, build clean; makeindex 2,185 / 0 / 0; Chapters 53–58 reconciled to sharp-runtime's current public-header/component graph, tracked CI, task/stream/UTF-8 behavior, GC/delegate/crypto/platform boundaries and audit metadata; physical pages 533–568 rendered and read as five contact sheets; two prose overflows on printed pages 522–523 corrected, full verification repeated and physical pages 552–554 re-rendered clean |
| 2026-08-12 | Phase F corrective batch 14 | **707 pages**, build clean; makeindex 2,184 / 0 / 0; Chapters 59–63 reconciled to current easy-gl/meta-gl layering and context-loss adoption, free-direct/free-api annotation/test/audio boundaries, platform taxonomy, MinGW fallback and Wine engagement evidence; physical pages 569–594 rendered and read as five contact sheets plus full-size risk pages; one target-name overflow on printed page 545 corrected, full verification repeated and physical page 575 re-rendered clean |
| 2026-08-12 | Phase F corrective batch 15 | **709 pages**, build clean; makeindex 2,184 / 0 / 0; Chapters 61 and 64–67 reconciled to source-site versus worker concurrency, five focused versus 24 admitted Web identities, Emscripten network topology, primary Android emulator/APK evidence, portable-versus-native Metal tests, workflow trigger drift and iOS/tvOS configuration non-claims; physical pages 583–610 rendered and read as five contact sheets plus full-size risk pages, all visually clean |
| 2026-08-12 | Phase F corrective batch 16 | **709 pages**, build clean; makeindex 2,184 / 0 / 0; Chapters 71–73 reconciled to pinned-versus-moving Proton evidence, actual Windows default/explicit build targets, filtered Direct2D CnaTests execution and the Input label's 541-by-five command despite a stale x3 comment; physical pages 611–636 rendered and read as five contact sheets plus full-size risk pages, all visually clean |
| 2026-08-12 | Phase F corrective batch 17 | **709 pages**, build clean; makeindex 2,183 / 0 / 0; Chapters 74–79 and cross-chapter ecosystem/sharp-runtime claims reconciled to free-direct's remediated blit path and follow-up benchmark, actual inaudible pan boundary, retained Timidity decoder, exact tracked SQLite blob and bounded Android evidence; physical pages 39–42, 563–568 and 637–668 rendered and read as eight contact sheets plus full-size risk pages, all visually clean |
| 2026-08-12 | Phase F corrective batch 18 | **709 pages**, build clean; makeindex 2,183 / 0 / 0; Appendices A–H mechanically re-audited, edition pins separated from later branch movement, CNAEXT token/header inventory made exact, MIDI decoder/public-route and Android install/frame evidence boundaries corrected; physical pages 665–702 rendered and read as seven contact sheets plus full-size risk pages; one malformed monospace paragraph on printed page 649 corrected and re-rendered clean |
| 2026-08-12 | Phase F corrective batch 19 | **709 pages**, build clean; makeindex 2,183 / 0 / 0; four stale numeric listing references corrected, twelve Parts labelled, and all live Part/appendix/section citations migrated to stable references; verifier expanded to all source refs, singular/plural structural-number forms and literal tab/CR defects; a whole-PDF pixel comparison against batch 18 identified 53 visibly changed physical pages, all rendered and read clean |
| 2026-08-12 | Phase F corrective batch 20 | **709 pages**, build clean; makeindex 2,387 / 0 / 0; 43 glossary terms, all 46 renderer selectors and the platform/testing/porting chapter topics gained canonical index destinations; malformed pointer/reference keys removed and verifier hardened against recurrence; 684 unique keys versus 517 before the batch; only index pages 703–709 changed visibly, all rendered and read clean at full size |
| 2026-08-12 | Phase F corrective batch 21 | **709 pages**, build clean; makeindex 2,387 / 0 / 0; a whole-artifact coordinate audit found 44 words crossing the physical right edge despite successful builds, bounded emergency stretch plus targeted semantic breakpoints reduced 544 internal overfull boxes to 153 and eliminated every physical-edge crossing; header allocation corrected without changing the text block; all 709 pages re-rendered and read clean |
| 2026-08-12 | Phase G final verification | **709 pages**, complete verifier green; readable unencrypted PDF 1.7 on A4, 27/27 fonts embedded/subsetted/Unicode-mapped, 12/79/8 Part/chapter/appendix outline, 302,443-word searchable text layer wholly inside the MediaBoxes, clean round-trip parse, no forms or JavaScript, and no pending visual page review |
| 2026-08-12 | Post-G release hardening | **709 pages**, independent clean-tree build and complete verifier green; two duplicated function words and two awkward constructions corrected, with all four affected pages rendered and read clean; all 89 compiled content sources, 709 page boxes/rotations, page-label transition, 1,076 unique internal targets, 1,802 link rectangles, three reviewed HTTPS links and 1,065 numbered TOC landings validated; all pages independently interpreted by Ghostscript; fixed-date clean builds byte-identical; negative tests proved repeated-word, displaced-TOC and unreviewed-URI failure paths |
| 2026-08-12 | Post-G licensing/outline clarification | **709 pages**, CNA's Ms-PL software-license section distinguished from the book's undecided publication license; D3D9 vendored Stock Effects corrected from bytecode to the six `.fx` sources plus four `.fxh` includes present at the pin; all 1,066 outline entries checked for non-empty titles and unique destinations; complete verifier green; physical pages 5 and 37 rendered and read clean |
| 2026-08-12 | Post-G preface reconciliation | **709 pages**, Part III overview corrected from 3D models to draw geometry/vertex streams, preserving Part VI's model-runtime remit; edition-wide audit dated to the recorded 2026-08-11 pins rather than conflated with July-dated source snapshots; new stable Appendix D link brings the current artifact to 1,803 valid link annotations; complete verifier green; physical pages 3–4 rendered and read clean |
| 2026-08-12 | Post-G Task-citation audit | **709 pages**, all 92 compiled Task-bearing lines checked against their owning pinned plans, including 46 distinct numeric CNA IDs plus range/slash endpoints, decimal/avatar IDs, easy-gl U2 and three WEBGPU IDs; corrected Phase 70's off-by-one wording to 65 technical Tasks 666–730 plus closing document Task 731; verifier guard added; complete verifier green; physical page 349 rendered and read clean |
| 2026-08-12 | Post-G interactive-index repair | **709 pages**, corrected `imakeidx`/`hyperref` load order so 1,848 index numbers are clickable; independent text/rectangle/name-tree/page-object audit proves every number, including range endpoints, lands on printed page + 30; artifact totals 3,651 valid link annotations / 1,541 unique targets; pre-fix PDF fails at 0 index links; text layer byte-identical; all seven recoloured index pages rendered and read clean |
| 2026-08-12 | Post-G outline/TOC bijection | **709 pages unchanged**, all 1,066 visible Part-through-subsection TOC destinations proven identical to the PDF outline set; 27 deeper internal paragraph/subsubsection records correctly excluded by standard `tocdepth=2`; one-destination negative fixture triggered the new set comparison and existing landing audit; verifier-only change, no visual delta |
| 2026-08-12 | Post-G print-geometry/blank-page audit | **709 pages unchanged**, all Media/Crop/Bleed/Trim/Art boxes resolve to identical A4 rectangles on every page; Ghostscript ink coverage identifies exactly twelve even open-right versos, with expected positions derived from the twelve Part entries in `main.toc`; verifier-only change, no visual delta |
| 2026-08-12 | Post-G interactive-index reproducibility | Two clean builds of commit `4b217a1` in different paths under the same fixed source date are byte-identical, SHA-256 `b62f0644740a28fc05c8a5cb76320c563c49a55461e6503c5b48054ed13fd010`; one clean output passed the complete current verifier, superseding the retained pre-hyperindex artifact hash |
| 2026-08-12 | Post-G Git-citation provenance audit | Sixteen compiled commit-like spellings representing fourteen distinct objects checked across CNA and all eleven sibling repositories; every prefix is unique in its owner and resolves to a commit; Emscripten repair, sharp-runtime database, rewritten easy-gl/meta-gl heads and cna-template pin/drift roles confirmed; numeric hex-like literals excluded; no correction or PDF delta |
| 2026-08-12 | Post-G filename-citation provenance audit | 295 filename-like occurrences / 194 distinct spellings classified against pinned trees and explicit external, negative, wildcard or historical cases; two stale pre-normalization `dx3_*` test basenames corrected to their registered `freedirect_*` files; untracked supplemental `free-eggbert/cna.md` distinguished from immutable Git pins by size and SHA-256; verifier guard added; complete build green with 3,652 links; whole-PDF comparison isolated physical pages 318, 319 and 645, all visually clean |
| 2026-08-12 | Post-G outline-title integrity | All 1,066 UTF-16 source bookmark records decoded from `main.out` and matched exactly by `(destination, title)` to MuPDF's PDF outline; a title-only `Preface` → `PrefacX` fixture failed with two differing pairs while destination checks remained green; verifier-only change, no PDF delta |
| 2026-08-12 | Post-G outline-hierarchy integrity | MuPDF indentation converted to all 1,066 `(destination, parent)` pairs and matched to each explicit `main.out` parent; a `chapter.1` parent-only mutation from `part.1` to `part.2` left destination/title checks green and triggered exactly two hierarchy differences; verifier-only change, no PDF delta |
| 2026-08-12 | Post-G TOC clickable coverage | All 1,066 visible TOC destinations proven covered by 1,129 Link rectangles on physical pages 5–29; 63 wrapped rows have two rectangles; a PDF fixture changing only `Preface` from Link to Text left other navigation checks green and triggered 1,128 rectangles / 1,065 targets / missing `chapter*.1`; verifier-only change, no release-PDF delta |
| 2026-08-12 | Post-G TOC link/text identity | MuPDF text geometry matched every TOC link to its own printed Part/chapter/section/subsection/appendix identity or `Preface`/`Index`; a PDF fixture swapping only `chapter.1` and `chapter.2` destinations preserved target coverage, landings and prior checks, while the new guard alone reported both crossed identities; verifier-only change, no release-PDF delta |
| 2026-08-12 | Post-G all-link visible-text overlap | One MuPDF structured-text pass over all 709 pages proved positive-area visible-text overlap for all 3,652 Link rectangles; a PDF fixture moved only preface object 4302 to in-bounds blank rectangle `[10 10 20 20]`, leaving target/geometry checks green while the new guard alone found one empty hotspot on physical page 3; verifier-only change, no PDF delta |
| 2026-08-12 | Post-G complete named-destination geometry | All 5,054 names map one-to-one to 5,054 destination objects on the 709 actual page objects, with in-A4 numeric XYZ positions and inherited zoom; a PDF fixture changed only `part.1` Y from 558.81 to 900, leaving link/landing/outline checks green while the new guard alone found the invalid target on page object 5587; verifier-only change, no PDF delta |
| 2026-08-12 | Post-G Graphics-header inventory correction | Stale “106 headers” corrected to the pinned tree's 125 `.hpp` files: 107 directly in the Graphics namespace directory plus 18 in its PackedVector child; nested namespace preserved; two intentional semantic index entries bring makeindex to 2,389, index links to 1,850 and artifact links/targets to 3,653/1,542; stale-count guard added; whole-PDF diff isolated physical pages 47 and 706–709, all read clean |
| 2026-08-12 | Post-G physical-module inventory terminology | Directly recounted 1,776 records across the seven cited pure-rename commits, all `R100`; confirmed the pinned 1,357 → 1,357 reconciliation and its 1,287 byte-identical / 70 directive-only split; corrected “production translation units” to the evidence's “production files,” because the inventory includes headers; regression guard added; complete build green and physical page 117 read full-size, clean |
| 2026-08-12 | Post-G platform-count reproducibility | Defined the 1,195-file production population exactly as 720 `.hpp` + 474 `.cpp` + one `.mm`, excluding tests/examples; direct line audit gives 55 files / 152 OS-macro directive lines, split 97 renderer / 55 framework; compiler-only generated branches excluded; `CNA_RENDERER_*` directives corrected 109 → 110; SDL-family count qualified as roughly 6,000 lexical tokens; stale-count guard added; complete build green and physical pages 584–585 read full-size, clean |
| 2026-08-12 | Post-G easy-gl/meta-gl consumer recount | Exact include-directive scan at easy-gl pin `0b46d35` finds 18 direct meta-gl consumers, not 19: three public headers plus fifteen implementation files; Chapter 59 corrected and stale-count guard added; complete build green and physical page 569 read full-size, clean |
| 2026-08-12 | Post-G free-direct status-census definition | Reproduced all 95 explicit `Status:` annotation lines exactly: ddraw 24/12/7, dplay 12/7/7, dsound 20/4/2; clarified that dsound's opening twelve bare status words are an untagged summary and must not be counted a second time; no numeric table change; complete build green and physical page 577 read full-size, clean |
| 2026-08-12 | Post-G broad numeric-claim closure | Direct recounts confirmed CNA test/source/example/registration, Color, renderer, oracle and CNAEXT inventories; xna4-spec 544/19, cna-samples 63+23+67=153, cna-examples 13/79/249, easy-gl/meta-gl line/API counts, free-direct/free-api registrations, and sharp-runtime 41 modules / 44 components / 92 edges plus exact SQLite populations; no further correction or PDF delta |
| 2026-08-12 | Post-G final-release reproducibility | Two clean archives of corrected checkpoint `3db9edc`, built concurrently in separate paths with `SOURCE_DATE_EPOCH=1786529214`, produced byte-identical 709-page / 3,314,744-byte PDFs, SHA-256 `7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af`; one clean output passed the complete current verifier, superseding `b62f064...` as the current release fingerprint while retaining the earlier hash historically |
| 2026-08-12 | Post-G complete page-label tree | Replaced the transition-only predicate with exact equality on the complete PDF label number tree plus the fixed 709-page extent, proving labels `i`--`xxx` followed by `1`--`679`; a simulated 710-page artifact retaining the same transition passed the old label predicate and fails the combined invariant; current corrected text layer recounted at 302,448 `pdftotext -layout` words versus the historical Phase-G 302,443 |
| 2026-08-12 | Post-G release-cardinality guards | Bound makeindex to exactly 2,389 accepted / 0 rejected / 0 warning entries and the PDF to exactly 3,653 targeted in-A4 link rectangles; added full Poppler layout-mode text extraction requiring 302,448 words and zero NUL or U+FFFD corruption; reduced-population predicates fail and the fixed-date release PDF passes the complete expanded verifier |
| 2026-08-12 | Post-G annotation/action allowlist | Complete object census proves all 3,653 annotations are Link actions: 3,650 internal GoTo plus exactly three reviewed HTTPS URI actions, with no direct-destination or unclassified annotation; verifier now requires this positive distribution as well as the existing unsafe-action blacklist and exact URI allowlist, preventing unknown media/widget/attachment action types from passing by omission; no PDF delta |
| 2026-08-12 | Post-G PDF catalog allowlist | Normalized volatile object numbers and bound the catalog to only Pages, Outlines, destination Names, UseOutlines mode, en-US language, exact PageLabels and OpenAction; Names contains only Dests and OpenAction is internal GoTo/Fit to the actual first page object; synthetic `/AA` root addition fails exact comparison, closing root-level script/name-tree expansion independently of action census; no PDF delta |
| 2026-08-12 | Post-G sealed release command | Added `tools/build-release.sh`: forces full latexmk rebuild under `SOURCE_DATE_EPOCH=1786529214`, requires 3,314,744 bytes and SHA-256 `7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af`, then runs the complete verifier; README documents the command and makes fingerprint changes contingent on a new independent reproducibility and visual-review checkpoint |
| 2026-08-12 | Post-G font/image population closure | Bound font portability to exactly 27 complete rows; extracted PDF images as five RGB + five soft-mask planes and compared decoded Netpbm pixels to the five source RGBA PNGs in compilation order, all RGB/alpha pairs byte-identical after decoding; verifier now enforces exact source/embedded populations and README records `pdfimages`/`pngtopnm` dependencies; no PDF delta |
| 2026-08-12 | Post-G automated parse/rewrite round trip | Restored the Phase-G round trip as an automated release check: MuPDF rewrites to a disposable PDF, Poppler requires all 709 pages and byte-identical layout-mode text versus the release, and Ghostscript independently interprets the rewritten artifact; current release passes all stages, with no modification to sealed bytes |
| 2026-08-12 | Post-G explicit PDF profile | Bound the semantic artifact profile to PDF 1.7, exactly 709 pages, unencrypted, untagged, unsuspect and without user properties, in addition to all per-page A4/rotation/box checks; requiring the consciously untagged state prevents an accidental partial tag tree from being presented as a PDF/UA edition, while tagged accessibility remains an owner-selected future release decision |
| 2026-08-12 | Post-G Claude workflow reconciliation | Updated `CLAUDE.md` to make `tools/verify-book.sh` the authoritative once-per-batch automated pass, retain rendered touched-page reading as a separate requirement, and distinguish the sealed `tools/build-release.sh` from ordinary manuscript work, without changing batched-writing, source-grounding or push policy |
| 2026-08-12 | Post-G complete source-input closure | Expanded the exact-once input graph from 89 chapter/appendix/fragment files to all 91 compiled sources: 89 content plus title page and preface; verifier now requires all present, case-correct and input once with zero orphan/duplicate/missing targets, while retaining the 89-content count as a separate invariant; no PDF delta |
| 2026-08-12 | Post-G TeX recorder provenance | Compared `main.fls` with a filesystem-derived exact set of 98 project inputs: main.tex, shared preamble, 91 front/content TeX sources and five PNGs; explicit path/type filtering excludes TeX-distribution and generated auxiliary inputs; current recorder has zero missing/unexpected project files, independently confirming what TeX actually opened; no PDF delta |
| 2026-08-12 | Post-G external-link text identity | Extended the all-link MuPDF text/geometry pass to require each of three URI action targets to equal the URL visibly printed under its rectangle after terminal sentence punctuation removal; SDL Init and both Microsoft Present URLs match byte-for-byte; swapping two approved target values preserves the exact URI allowlist/cardinality but produces two identity failures, closing a semantic gap without PDF delta |
| 2026-08-12 | Post-G outline order integrity | Added byte-for-byte comparison of the unsorted 1,066-destination MuPDF outline sequence with source `main.out`; destination/title/parent set checks alone could not detect two otherwise-valid subtrees trading positions, while the sequence guard does; current order matches exactly, with no PDF delta |
| 2026-08-12 | Post-G visible-TOC order integrity | Filtered physical TOC annotations to the first occurrence of each expected destination, excluding six legitimate duplicate surrounding-navigation links; the resulting 1,066-destination sequence matches `main.toc` byte-for-byte, closing row-order swaps that coverage/identity/landing set checks could miss; no PDF delta |
| 2026-08-12 | Post-G internal-target/landing cardinalities | Replaced non-empty predicates with exact release populations for 1,542 unique internal link targets and 1,065 numbered TOC landings, complementing already-fixed link/name/TOC/index counts and preventing silent deletion of an internally consistent subgroup; complete verifier remains green, no PDF delta |
| 2026-08-12 | Post-G concurrent verifier hygiene | Replaced eleven predictable `/tmp/cna-bible-*.txt` diagnostic paths with a private per-run `mktemp` directory and EXIT/HUP/INT/TERM cleanup, preventing concurrent verifier runs from overwriting stale-fact/whitespace evidence and eliminating newly leaked named scratch files; verification semantics and PDF unchanged |
| 2026-08-12 | Post-G current clean-archive release run | Extracted tracked commit `d551a3f` via `git archive` into a new path, created a local baseline solely for `git diff --check`, and ran the sealed command without workspace-only inputs; reproduced 3,314,744-byte SHA-256 `7c877ef...` and passed the complete expanded verifier including recorder/image/catalog/action/order/round-trip checks; documentation-only record, no typesetting delta |
| 2026-08-12 | Post-G sealed-input preflight | Added a Git preflight to `tools/build-release.sh`: requires exact reviewed `HEAD:latex` tree `406104d29871dab11757fdd72ded5d9fbc7fc9f1` and no tracked or non-ignored untracked status under `latex/` before invoking TeX; documentation/verifier-only commits remain compatible, while committed/staged/unstaged/untracked release-input drift fails early with diagnostics |
| 2026-08-12 | Post-G sealed PDF-date check | Sealed build now reads the PDF Info object with MuPDF and requires CreationDate and ModDate `D:20260812100654Z`, the UTC representation of `SOURCE_DATE_EPOCH=1786529214`, in addition to exact tree/size/SHA-256; provides direct timestamp diagnostics without constraining ordinary working builds |
| 2026-08-12 | Post-G verifier CLI hardening | Replaced silent unknown-argument fallback with an exact interface: no argument builds/checks, `--no-build` checks, `--help` prints usage, and every unknown/multiple-argument form exits 2 before make; negative fixtures confirm no build log or temporary diagnostic directory is created |
| 2026-08-12 | Post-G release CLI hardening | Restricted `tools/build-release.sh` to its argument-free workflow plus `--help`; every unknown or multiple-argument invocation exits 2 before repository/dependency inspection or release-log writes, preventing typo-triggered sealed rebuilds |
| 2026-08-12 | Post-G generated-index structure | Parsed all 2,389 `main.idx` records rather than trusting only makeindex's transcript: every key is non-empty, every encapsulator is `hyperpage`, every printed reference is 1–670, and 681 case-folded logical keys map exactly to 676 `main.ind` items plus five subitems; no PDF delta |
| 2026-08-12 | Post-G complete verifier scratch lifecycle | Routed every per-run text, JSON, PDF and decoded-image intermediate into the existing private diagnostic directory and made its EXIT cleanup recursive; normal, failed and HUP/INT/TERM exits now share one cleanup path, closing more than forty individually removed scratch files without changing verification semantics |
| 2026-08-12 | Post-G PDF Info closure | Extended semantic metadata verification to require `Creator: LaTeX with hyperref` and `/Trapped /False` alongside the established title/author/subject/keywords; dates remain an explicit sealed-build check and producer/version drift remains covered by the exact release fingerprint |
| 2026-08-12 | Post-G visual-render CLI hardening | Made `tools/render-pages.sh` reject missing/extra/non-numeric/zero/reversed/out-of-book ranges, preflight its dependencies, render each request in a fresh child directory and require exactly `LAST-FIRST+1` PNGs; reused parents can no longer leak stale images into the reported review set |
| 2026-08-12 | Post-G PDF parse fail-fast | Consolidated the verifier's initial Poppler inspection into one `pdfinfo` result and require a numeric page count before any geometry, metadata, extraction or navigation audit; unreadable containers now stop with one primary diagnostic rather than propagating empty arithmetic into secondary failures |
| 2026-08-12 | Post-G scratch bootstrap preflight | Resolve `mktemp` before the verifier's first scratch allocation and diagnose both a missing command and directory-creation failure explicitly; bootstrap failure can no longer precede and undermine the normal dependency report |
| 2026-08-12 | Post-G source-image graph closure | Parsed every compiled `includegraphics` target and compared it case-sensitively with the five source PNG paths: exactly five includes map one-to-one with no orphan, duplicate or missing/non-PNG target, complementing the recorder set and embedded RGB/alpha pixel audit |
| 2026-08-12 | Post-G visual-render fail-fast | Require successful `pdfinfo` parsing and a numeric page total before visual-range arithmetic, and diagnose private render-directory allocation failure separately; damaged artifacts and invalid output parents now stop before `pdftoppm` with one primary error |
| 2026-08-12 | Post-G sealed-pipeline dependency closure | Preflight the union of release-build/fingerprint commands and every complete-verifier dependency before invoking TeX, reporting all missing tools together; an absent late-stage Poppler/Netpbm/MuPDF/Ghostscript command no longer wastes a full sealed rebuild |
| 2026-08-12 | Post-G transactional release artifact | Snapshot an existing reviewed `main.pdf` before TeX and restore it on build/fingerprint/verifier failure or HUP/INT/TERM; when no prior artifact exists, remove partial output; only a fully green sealed pipeline commits the rebuilt PDF while preserving logs/auxiliaries for diagnosis |
| 2026-08-12 | Post-G serialized release transaction | Acquire a non-blocking kernel `flock` keyed by the absolute repository path before Git/source preflight and PDF snapshot; a concurrent sealed invocation now fails immediately rather than racing on shared auxiliaries, release log, output PDF or restore state |
| 2026-08-12 | Post-G rollback snapshot retention | Hardened the exceptional rollback path: if restoring the prior PDF itself fails, retain the only snapshot and print its exact recovery path instead of deleting it during cleanup; normal success and successful rollback still remove their temporary snapshot |
| 2026-08-12 | Post-G private release-lock path | Moved the predictable repository-keyed lock below a per-effective-user `/tmp` directory that must be a real owner-matching mode-0700 directory; cross-invocation serialization remains stable without allowing a public-`/tmp` symlink to redirect the lock-file open |
| 2026-08-12 | Post-G workflow dependency/transaction docs | Updated README to name Poppler `pdftoppm` for the visual-page driver and util-linux `flock` for sealed serialization, and documented prior-PDF restoration/partial removal on sealed failure; documentation only, no typesetting delta |
| 2026-08-12 | Post-G unified artifact lock protocol | Added shared `tools/book-lock.sh`: default verifier and sealed release take an exclusive per-repository lock; `--no-build` verifier and isolated page rendering take shared locks; concurrent readers remain allowed while every reader is excluded from mid-build aux/PDF state; sealed release passes its inherited descriptor through the nested verifier, which accepts it only when device/inode identity matches the correct repository lock |
| 2026-08-12 | Post-G artifact-lock contributor contract | Listed `tools/book-lock.sh` in README and made CLAUDE require shared locks for future artifact readers and exclusive locks for aux/log/PDF writers, so new entry points do not bypass the reconciled concurrency boundary; documentation only |

---

## 7. Unresolved questions for the project owner

None blocking. Before public distribution, the owner still needs to choose and record the book's
license/copyright terms; the repository currently contains no `LICENSE`, `COPYING`, or equivalent
declaration, so this session did not invent one. The PDF is also not tagged and makes no PDF/UA
claim (`pdfinfo` reports `Tagged: no`); decide whether an accessible tagged edition is a release
requirement rather than inferring one from the searchable text layer. One environment note: TeX
Live was absent at session start and was installed mid-session at the owner's direction, so the
build and visual passes are available again.

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

### 2026-08-12 — Phase F corrective batch 11: Input, audio and device-service contract truth

- Reconciled Input with its event accumulator rather than describing every `GetState()` as a pure
  read: relative mouse state drains its delta, SDL motion is ignored outside relative mode, and
  the event queue is drained once per frame. F9/F10 still reach keyboard state before their debug
  side effects. Keyboard layout mapping, touch capability/connectivity and the UTF-16 text-input
  subscription example now match the live API and its ownership rules.
- Reframed dynamic-audio completion around the fixed 44.1-kHz stereo regression while preserving
  the open resampling-domain and channel-frame-alignment tasks. Corrected raw `SoundEffect`
  constructor signatures and non-const playback. The microphone example now guards a missing
  default device and removes its process-wide event token before captured playback state dies;
  the component-based buffer-duration check and open backend/permission/device gaps are explicit.
- Corrected Media's extension boundary: Opus is supported and indexed, while loose-file AAC/WMA
  remain advertised but undecodable. The standalone `Song::FromUri` result now has an explicit
  `unique_ptr` owner because `MediaPlayer` clones rather than adopts it. The Windows FFmpeg guard
  defect remains documented. Sensor prose distinguishes SDL callback threads from Android worker
  threads, and correctly assigns dispatch-token self-disposal tracking to Accelerometer and
  Gyroscope. Host devices now counts 25 installed headers and names the uncaught file-dialog/tray
  exception boundary across SDL's C callbacks.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,184 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 455–498 across Chapters 44–48 in six
  contact sheets; the RAII media example (482) and dense sensor lifecycle page (491) were also
  inspected full-size. No clipping, overlap, malformed listing, broken heading or other visual
  defect was found.

### 2026-08-12 — Phase F corrective batch 12: local services and Avatar contract truth

- Reconciled GamerServices persistence and event behavior. Every JSON number is a `double`, so
  achievement ticks, leaderboard ratings and 64-bit date/time columns all lose low bits beyond
  binary64's exact-integer range. A leaderboard reader mutates only its in-memory entry; the exact
  inert Guide calls, UTF-16 password masking and dispatcher/component lifecycle are now stated
  without overclaim.
- Separated Storage's unchecked `BeginOpenContainer` display-name traversal from the equally
  unchecked container file/directory resolution seam. The chapter now records direct-write
  fallback, post-dispose operations, runtime-dependent `FileShare` behavior, non-owning device
  lifetime and the narrow filesystem-exception translation. Its read example handles partial and
  early-EOF reads.
- Corrected networking's promoted-host and three-retry migration behavior, all five
  `SendDataOptions`, synchronous replay of current gamers when a joined-gamer handler is added,
  and the packet example: the vector overload returns the received byte count,
  while `ReceiveData(PacketReader&)` always reports zero and `Write(Color)` emits four bytes that
  `ReadColor()` misreads as four floats. Synthetic discovery/join, voice, invite, event and
  `NetworkMachine` stubs remain explicitly bounded.
- Rebased Avatar examples on the actual CNAEXT surface: both bundled procedural rigs have 19
  bones; content loads `SkinnedModelEXT` through `ContentManager`; `Stand0` is a real clip; explicit
  lighting supersedes the historical default-light ordering; tint routing uses exact Hair/Shirt/
  Pants/Shoes substrings. The fixed 71-bone inert compatibility API is distinguished from the
  content-defined renderer limit, and EasyGL/Vulkan evidence from BGFX's missing registered test.
- Ran `tools/verify-book.sh`: 707 pages, makeindex 2,188 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 499–530 across Chapters 49–52 in eight
  contact sheets; pages 509, 514, 523 and 528–530 were inspected full-size. Full-size review found
  one overflowing Task 13.2 condition and one over-wide closing table; both were rewritten,
  rebuilt and re-rendered cleanly. No visual defect remains.

### 2026-08-12 — Phase F corrective batch 13: sharp-runtime contract truth

- Recounted the pinned modular tree rather than repeating historical prose: 1,032 public headers
  and five private implementation headers, 41 physical modules, 44 component names and 92 direct
  production dependency edges. Replaced the obsolete claim that no hosted workflow exists with
  the tracked nine-entry selective Ubuntu matrix, full compatibility build and Doxygen job while
  preserving the distinction between workflow presence and observed execution.
- Reconciled concurrency and representative namespaces. `TimeSpan` diagnostics are relaxed
  atomics; `WhenAny` registers continuations without watcher threads; `WhenAll` and the external-
  future bridge distinguish terminal state from exception type. `TaskT<TResult>` has both action
  and result continuations but no generic `WhenAll`/`WhenAny`. Malformed UTF-8 has two direct test
  surfaces. The buffer-copy `MemoryStream` is writable by default, validates its inputs, preserves
  extraction after close and retains .NET's deliberately asymmetric closed `CanWrite` result.
- Corrected the permanent-deviation and audit accounts. GC queries return fixed sentinels rather
  than every operation being a no-op; only `Delegate` exposes throwing `DynamicInvoke`; HMAC and
  PBKDF2 do carry sensitive input material; platform support is split across Windows/POSIX/Linux/
  Emscripten cases; and 128-bit support follows the compiler probe rather than operating-system
  name. The pinned `plan.sqlite3` blob is 7,471,104 bytes; although its name also matches a current
  ignore rule, it was already tracked and is present in commit `f827a6c5`.
- Ran `tools/verify-book.sh` twice after the prose and layout repairs: 707 pages, makeindex 2,185
  accepted / 0 rejected / 0 warnings, all automated checks green. Rendered and read physical pages
  533–568 across Chapters 53–58 as five contact sheets and full-size pages. Visual review found
  two prose overflows on printed pages 522–523; both were rephrased, and physical pages 552–554
  were rebuilt, re-rendered and read cleanly.

### 2026-08-12 — Phase F corrective batch 14: sibling and Windows-platform truth

- Reconciled easy-gl/meta-gl layering to exact source scope: 19 production meta-gl includes are
  three public headers plus sixteen implementation files; `Device::require()` throws only under
  its enabled configuration policy; eleven integer-named resources use generation tracking while
  pointer-shaped `Sync` does not. ResourceRegistry/ResourceRegistration implement recovery
  infrastructure, but no concrete resource adopts `RecoverableResource`. Emscripten omits rather
  than skips two desktop-shaped test binaries, and CNA's nested test/example defaults depend on
  configure entry point.
- Corrected free-direct/free-api evidence. The 95 status tags are public-header documentation
  annotations, not 95 methods; CNA now has 21 registered FREEDIRECT renderer/shared test binaries.
  DirectSound volume is audible, but `SetPan()` only stores a clamped value: its constant-power
  helper's gains are discarded because SDL's channel map cannot apply them, and tests assert
  success/no-crash rather than output samples.
- Made the cross-platform taxonomy two-level rather than claiming seven flat identities, recorded
  that the generic MinGW fallback retains an x86_64 processor declaration after selecting i686,
  and rechecked workflow, emulator and engagement-gate claims against current CMake/scripts. The
  DirectDraw, DXVK and vkd3d wrappers fail closed with status 3 outside explicitly named discovery
  or diagnostic bypasses.
- Ran `tools/verify-book.sh` after prose edits and again after the visual repair: 707 pages,
  makeindex 2,184 accepted / 0 rejected / 0 warnings, all automated checks green. Rendered and
  read physical pages 569–594 across Chapters 59–63 as five contact sheets plus full-size risk
  pages. One long test-target name overflowed printed page 545; the paragraph was made both
  shorter and more accurate, and physical page 575 was rebuilt, re-rendered and read cleanly.

### 2026-08-12 — Phase F corrective batch 15: Web and mobile evidence truth

- Distinguished a single Android `std::thread` construction site from runtime multiplicity:
  every sensor bridge can own a worker and Motion aggregates six bridges. Separated the five
  web-focused renderer identities from the 24 identities admitted by the Emscripten gate, while
  retaining the exact four-rung evidence matrix for HTML_DOM, SVG_DOM, WEBGL1/2 and CANVAS.
- Added the missing Web network topology contract. Emscripten hosts request fixed port 61191;
  browser clients rebuild themselves as outbound-only; UDP-broadcast discovery is compiled out;
  and CnaTests-only Asyncify permits event-loop yields without changing those capability limits.
- Reconciled Android against primary commit records rather than contradictory later prose. The NDK
  run passed all 230 network cases plus 1,831 other tests before a no-Activity TitleContainer crash.
  The July APK built the then-current default SDL_RENDERER and screenshot-confirmed its UI/sensor
  flash, but no artifact survives, the CNA-owned Compass/Motion bridge was not driven, and the
  adapted pin was never rebuilt. This is historical AVD presentation, not a current pixel oracle.
- Corrected Apple boundaries: a Linux HEADLESS `^Metal` run can report 207/207 portable cases;
  only Metal_Smoke and Metal_Capabilities require METAL. The tracked workflow retains three stale
  push paths but usable PR/manual triggers. iOS/tvOS have an enum and 24 admitted identities, not
  a host/signing/runtime port; native METAL remains macOS-only and calls them unvalidated.
- Ran `tools/verify-book.sh`: 709 pages, makeindex 2,184 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 583–610 across the updated Chapter 61
  context and Chapters 64–67 as five contact sheets plus full-size web/Android/Metal pages. No
  clipping, overlap, malformed table, broken heading or other visual defect was found.

### 2026-08-12 — Phase F corrective batch 16: Testing and CI execution truth

- Distinguished the two Proton evidence lanes. Direct2D selects a checked-in pinned runtime and
  emits its identity; D3D12 defaults to moving Proton Experimental, overlays vkd3d-proton DLLs and
  forwards the child exit status without the Wine wrappers' engagement-token gate.
- Reconciled Windows CI prose to executable workflow commands rather than stale headers. The D3D
  workflow's unrestricted default build includes `CnaTests`; DirectX 11/12 label selectors omit
  its general discovered corpus, while Direct2D runs the filtered `Direct2D_Unit` entry through
  it. GDI's explicit 17-target list does not build the binary, and the POSIX-setenv rationale in
  the D3D header no longer matches platform source filtering.
- Made the Input execution count auditable: one 541-case CTest entry repeats five times, yielding
  2,705 case executions when complete. The nearby workflow comment still says x3, but the CMake
  command and current Input documentation both require five.
- Re-audited Chapters 68–70 without factual correction. Ran `tools/verify-book.sh`: 709 pages,
  makeindex 2,184 accepted / 0 rejected / 0 warnings, all automated checks green. Rendered and
  read physical pages 611–636 across Chapters 68–73 as five contact sheets plus full-size
  hostile-host, discipline and CI pages. No clipping, overlap, malformed table, broken heading or
  other visual defect was found.

### 2026-08-12 — Phase F corrective batch 17: Porting-practice and roadmap truth

- Reframed the Blupi performance audit as a before/after record. The historical 0.715-ms Release
  and 4.704-ms unoptimized measurements remain discovery evidence; the current pin defaults an
  otherwise-unspecified top-level single-configuration build to Release, detects equal source and
  destination extents at runtime, uses a per-row `memcpy` fast path with opaque-alpha fixup, and
  records a 0.466-ms / 14.8-times follow-up result.
- Corrected two audio boundaries. Both games call `SetPan()` only for mono effects, but the current
  implementation discards its computed left/right gains and tests only success/no-crash behavior.
  CNA's vendored SDL3_mixer retains Timidity even though FluidSynth is disabled; the missing CNA
  feature is a public Song/Content `.mid` mapping plus an instrument/asset policy and retained test,
  not the absence of every underlying MIDI decoder.
- Proved that sharp-runtime's 7,471,104-byte `plan.sqlite3` is the exact tracked blob at commit
  `f827a6c5`: `ls-tree`, `git show` and matching worktree/commit blob hashes agree. Its ignore-rule
  match does not untrack the existing file. Bounded the Android roadmap wording to require a fresh
  adapted-pin frame before a current renderer claim while preserving the historical pre-adaptation
  SDL_RENDERER AVD presentation.
- Mechanically re-audited Chapters 74 and 76–78, including xna4-spec's 544 entries, the samples
  63/23/67 partition, examples' 249 registered demos, 52 CNA root plans and sharp-runtime's
  16,201-row task table / 2,183-ticket inventory, without further prose correction. Ran
  `tools/verify-book.sh`: 709 pages, makeindex 2,183 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read physical pages 39–42, 563–568 and 637–668 as eight
  contact sheets plus full-size risk pages. The two blank chapter-end verso pages are intentional;
  no clipping, overlap, malformed table, broken heading or other visual defect was found.

### 2026-08-12 — Phase F corrective batch 18: Appendix reference truth

- Re-audited Appendices A–H as bounded lookup surfaces rather than trusting Phase E's earlier
  snapshot. Mechanically reconfirmed 46 public renderer identities / 42 implementation families,
  fourteen framework/extension modules, all twelve repository pins, 544 xna4-spec entries, the
  63/23/67 samples partition, 249 examples, sharp-runtime's 16,201 task rows / 2,183 tickets, CI's
  eight-workflow trigger split and the glTF D1–D8/layer matrices.
- Distinguished immutable edition pins from mutable sibling branch heads. Eleven local sibling
  HEADs still match their recorded pins; `cna-template` advanced after the audit from retained pin
  `1d86681` to `4d0a2c8a`, so Appendix D now states explicitly that its table remains revision-
  scoped evidence rather than a live-HEAD promise.
- Replaced Appendix E's rounded marker count with the reproducible whole-token result: 1,876
  occurrences across 302 headers. Added Appendix F's missing distinction between vendored
  SDL3_mixer's retained Timidity decoder and CNA's absent public `.mid` Song/Content mapping, and
  made Appendix G require both Android APK installation and a frame from the selected renderer.
- Ran `tools/verify-book.sh`: 709 pages, makeindex 2,183 accepted / 0 rejected / 0 warnings, all
  automated checks green. Rendered and read every appendix page, physical pages 665–702, as seven
  contact sheets plus full-size pin/CNAEXT/MIDI/evidence/glTF pages. Visual inspection caught an
  accidental tab-expanded `texttt` paragraph on physical page 679 (printed 649); it was repaired,
  the full verifier repeated, and physical pages 679–680 re-rendered clean. Physical page 702 is
  the intentional blank verso before the index.

### 2026-08-12 — Phase F corrective batch 19: durable structural references

- Found four stale chapter-number references inside code listings that the original verifier's
  tied-space-only pattern could not see. Replaced the inaccurate chapter claims with direct
  behavioral wording in the math, stock-effect, ContentManager and Model examples.
- Added stable labels to all twelve `\part` declarations and migrated every live hard-coded Part,
  Appendix and local Section citation in compiled prose. Cross-reference ranges retain their
  printed Roman numerals while now following future structural edits automatically.
- Hardened `tools/verify-book.sh` to validate every source `\ref` against `main.tex`, chapters and
  front matter; reject singular and plural hard-coded chapter/Part/appendix/section forms with
  either spaces or TeX ties; and reject literal tabs and carriage returns in compiled TeX. The
  tab invariant encodes the real malformed-Appendix-D defect caught during batch 18.
- Ran the complete verifier: 709 pages, makeindex 2,183 accepted / 0 rejected / 0 warnings, all
  checks green. A rendered-pixel comparison of all 709 pages against the batch-18 checkpoint
  isolated 53 changed physical pages. Every changed page was rendered at review resolution and
  read in contact sheets, with the four multi-page reflow spans inspected separately; no clipping,
  overlap, malformed listing, broken heading or unintended blank page was found.

### 2026-08-12 — Phase F corrective batch 20: whole-book index coverage

- Audited the generated index rather than counting only explicit `\index` commands: the existing
  `\cnaclass`/`\cnans` macros supplied most of its 2,183 entries, but 25 process-oriented chapters
  had no index destination and the 517 unique keys were overwhelmingly API symbols.
- Added one canonical destination for all 46 accepted renderer selectors, all 43 glossary terms,
  and the principal concepts of the module, content, glTF, platform, verification, sibling-library
  and porting chapters. The resulting 684 unique keys make CMake, Wine, Emscripten, CTest, CI,
  differential testing, Android, migration and re-audit material discoverable without indexing
  every incidental prose occurrence.
- Removed polluted keys such as `Album*`, `Gamer*`, `NetworkSession*`, `IAsyncResult*`, namespace
  wildcards and `Game& game` by keeping declarators outside semantic index macros. Added a verifier
  invariant that rejects pointer/reference declarators inside `\cnaclass` or `\cnans`. Four long
  index identifiers now use explicit display-only breakpoints.
- Set only the back-of-book index in `\footnotesize`, retaining the main manuscript typography.
  This fits the enlarged index in seven readable pages without overfull boxes or a near-empty tail.
  The complete verifier reports 709 pages and makeindex 2,387 accepted / 0 rejected / 0 warnings.
  A checkpoint-PDF pixel comparison isolated only physical pages 703–709; all seven were rendered
  and read at full size, with first, middle and final pages inspected separately and clean.

### 2026-08-12 — Phase F corrective batch 21: physical-edge typography

- Rendered and read all 709 physical pages as 30 contact sheets for the edition-wide final visual
  sweep. The twelve blank pages were checked with their neighbours and are intentional versos
  between Part title pages and the following chapters.
- Supplemented visual review with Poppler word-coordinate extraction. This exposed 44 long
  monospace words beyond the physical A4 right edge, a release defect not reliably visible at
  contact-sheet scale and not distinguished by LaTeX's general overfull-box warning.
- Tested bounded emergency-stretch values against both page count and physical coordinates. A
  2.5em last-resort stretch preserved all 709 pages; targeted semantic breakpoints in twelve
  chapters and Appendix B removed the remaining crossings. Internal overfull diagnostics fell
  from 544 to 153, while the release criterion is now exactly zero extracted words outside a
  page MediaBox.
- Reallocated the existing 40pt running-head space as 26pt head height plus 14pt separation. This
  removed all five `fancyhdr` height warnings without moving the body text or shortening the
  table of contents. Rebuilt, re-extracted and re-rendered the final 709-page artifact; a second
  full review of all 30 contact sheets found no clipping, collision, malformed table, damaged
  index or unintended blank page.

### 2026-08-12 — Phase G: final artifact verification

- Extended `tools/verify-book.sh` from source/build checks into release-artifact checks: it now
  rejects undersized running heads, unreadable/encrypted/non-A4 output, physical text-edge
  crossings, incomplete font embedding/Unicode maps, and a damaged PDF outline.
- Confirmed a readable unencrypted PDF 1.7 artifact on A4, with 27 of 27 fonts embedded and
  subsetted with ToUnicode maps. The PDF outline exposes all 12 Parts, 79 chapters and 8
  appendices; `pdftotext -layout` recovered a 302,443-word searchable text layer, and a MuPDF
  clean/rewrite round trip parsed successfully. No forms or JavaScript are present.
- Re-ran the complete verifier after the final typography changes: 709 pages, makeindex 2,387
  accepted / 0 rejected / 0 warnings, all source, structure, index, whitespace, container, font,
  outline and physical-boundary invariants green. A mechanical editorial-placeholder and tiny-
  chapter audit found no unfinished manuscript content. Phases A–G are complete.

### 2026-08-12 — post-G release hardening

- Proofread the extracted manuscript mechanically for adjacent repeated function words and
  high-similarity duplicated sentences. Corrected two real repetitions plus two awkward
  constructions; rendered and read the four affected physical pages clean.
- Extended the artifact verifier from aggregate PDF metadata to all 709 page boxes and rotations,
  the front-matter page-label transition, internal named-destination existence, link annotation
  geometry and targeting, and the physical landing page of every numbered TOC entry. The final
  artifact has 1,076 unique internal link targets, 1,802 valid link annotations and 1,065 numbered
  TOC entries that agree with their printed page numbers.
- Made Poppler, MuPDF and Ghostscript tooling explicit release-verifier prerequisites, and added
  independent all-page Ghostscript processing. Negative fixtures confirmed that the verifier
  rejects both a multiline repeated word and a deliberately displaced TOC page.
- Built the book independently from a clean temporary copy containing only tracked and intentional
  untracked sources. It produced the same 709-page A4 structure with a clean log, proving that the
  release does not depend on repository-local auxiliary files.
- Repeated that clean build from two different temporary paths under the same
  `SOURCE_DATE_EPOCH`; the PDFs were byte-identical with SHA-256
  `c61e4121d5afd7524cc0c1a8143489279409abc2600b45b01ca409c5388aab32`.
- Closed the source graph mechanically: all 89 chapter, appendix and nested renderer-fragment
  files exist and are compiled exactly once. Audited active PDF content as well: the release has
  exactly three reviewed HTTPS API-reference links and no form, JavaScript, remote-navigation,
  launch, submission, import or embedded-file action. A 709-page negative fixture with one URI
  substituted proved that the allowlist reports both the unexpected and missing destination.
- Rechecked all twelve repository pins read-only. Ten locally available HEADs still matched
  exactly; CNA's one-commit documentation-only drift and `cna-template`'s three-commit material
  drift both retain the book's pin as an ancestor and are recorded in §2 without rebasing claims.
- Added standard PDF language (`en-US`), subject and keyword metadata. A before/after comparison
  found byte-identical extracted text and identical low-resolution rasters for all 709 pages, so
  the change affected only the PDF catalog. The verifier now rejects a missing/wrong language.
- Audited all image assets: five source PNGs map to five PDF image objects; each is opaque,
  non-empty and cited. The SDL Renderer and EasyGL oracle screenshots are byte-identical by
  design; commit history and `tools/cna-screenshot-infra/README.md` preserve their independent
  build/run provenance and reproduction commands.
- Audited the generated index semantically rather than relying on makeindex's zero-warning status.
  Every parsed numeric reference/range remains within printed pages 1–670 and no empty key exists.
  Consolidated six aliases of `ContentManager::Load<Song>`, `ContentManager::Load<T>`,
  `System::GC`, `System::Type` and `System::SystemException`; kept intentional conceptual pairs
  such as XNB/`.xnb` and free-direct/`FREEDIRECT`. Added a verifier guard for the known aliases.
  A whole-PDF pixel comparison isolated physical index pages 704–709; all six final pages were
  rendered and read individually at full size with no clipping, collision or sparse-tail defect.
- Reconciled visible and embedded authorship: the custom title page and formerly unused
  `main.tex` author field now name Robert Vokac, matching the PDF metadata set since the original
  scaffold. A 709-page raster comparison found only physical page 1 changed; the final title page
  was inspected full-size and is balanced and collision-free. The verifier now fixes title,
  author, subject and keywords as release invariants. Recorded the missing license declaration and
  untagged-PDF state as owner decisions in §7 instead of inventing publication policy.
- Disambiguated CNA's pinned Ms-PL software license from the repository's still-unselected book
  license, and corrected the D3D9 derivation example to describe the six vendored `.fx` sources
  plus four `.fxh` includes rather than nonexistent vendored bytecode. Extended the artifact
  verifier to require 1,066 non-empty outline entries with unique destinations. The complete
  verifier is green; physical pages 5 and 37 were rendered and read full-size without defect.
- Reconciled the preface with the final Part structure: Part III now describes draw geometry and
  vertex streams while 3D models remain in Part VI. Distinguished July-dated facts quoted from
  CNA documentation from the edition-wide audit at the 2026-08-11 repository pins and linked the
  recorded map in Appendix D. The added internal reference produces 1,803 valid link annotations;
  the complete verifier is green and physical pages 3–4 were read full-size without defect.
- Re-audited every compiled Task citation against its owning pinned evidence: 92 source lines,
  46 distinct numeric CNA identifiers plus all range/slash endpoints, four decimal/avatar IDs,
  easy-gl U2 and three WEBGPU-prefixed IDs. Corrected the one real mismatch: Phase 70's technical
  work is Tasks 666–730 (65 tasks), with Task 731 as its closing document. Added a regression guard;
  the complete verifier is green and physical page 349 was read full-size without defect.
- Found that `imakeidx` loaded after `hyperref`, replacing its index hook and leaving all seven
  index pages non-interactive. Reordered the packages to activate standard `hyperpage` links and
  added an independent MuPDF extraction/rectangle/name-tree audit for all 1,848 printed index
  numbers. Every target lands on printed page + 30; the pre-fix artifact fails with zero links.
  Extracted text is byte-identical, and all seven recoloured index pages were visually read clean.
- Strengthened outline validation from aggregate counts to exact destination-set equality with
  every visible Part-through-subsection TOC entry. The 27 deeper `.toc` records are intentionally
  outside standard `tocdepth=2`. A mutated destination fails both the new set and existing landing
  checks; this verifier-only hardening leaves the PDF unchanged.
- Checked all five standard PDF page boxes across all 709 pages and found identical A4 geometry.
  Replaced the visual-only blank-page assertion with Ghostscript ink coverage whose twelve expected
  even versos are derived from the Part entries in `main.toc`, not a fixed list. The verifier-only
  change leaves the PDF unchanged.
- Re-established reproducibility after activating index links: two clean archives built in
  different paths under the same `SOURCE_DATE_EPOCH` produced byte-identical PDFs with SHA-256
  `b62f0644740a28fc05c8a5cb76320c563c49a55461e6503c5b48054ed13fd010`. One clean artifact passed
  the complete expanded verifier; this supersedes the earlier pre-hyperindex release hash.
- Extracted every hex-like token from compiled prose and separated constants from Git citations.
  All sixteen commit-like spellings (fourteen distinct objects) resolve uniquely in their owning
  CNA/sibling repository, and targeted content checks confirm the Emscripten repair, tracked
  sharp-runtime database, rewritten easy-gl/meta-gl heads and cna-template drift account. No text
  or PDF correction was needed.
- Classified 295 filename-like manuscript occurrences representing 194 distinct spellings against
  the pinned trees and their context. Corrected Chapter 26's two obsolete `dx3_*` test basenames to
  the current, CTest-registered `freedirect_*` sources. Clarified that Chapter 75's 2026-07-16
  `free-eggbert/cna.md` feasibility analysis is an untracked supplemental working-tree document,
  not part of an immutable Git pin; recorded its 30,145-byte size and exact SHA-256. The verifier
  rejects both stale test names, the complete build is green with 3,652 valid link annotations,
  and a whole-PDF pixel comparison isolated only physical pages 318, 319 and 645; all three were
  rendered and read full-size, clean.
- Closed the remaining outline-content gap by decoding all 1,066 UTF-16 bookmark records in
  `main.out` and comparing exact `(destination, title)` pairs with MuPDF's artifact outline.
  A title-only negative fixture changed `Preface` to `PrefacX` without moving `chapter*.1`; the
  prior destination checks stayed green and the new guard alone reported the expected two set
  differences. The current artifact has zero mismatch; this verifier-only hardening has no PDF
  or visual delta.
- Closed the independent outline-structure gap by deriving all 1,066 `(destination, parent)` pairs
  from MuPDF indentation and comparing them with each bookmark's explicit `main.out` parent. A
  fixture moved `chapter.1` from `part.1` to `part.2` without changing its title or destination;
  the prior guards remained green and the new hierarchy check alone reported the expected two
  set differences. The current artifact has zero mismatch; this verifier-only change has no PDF
  or visual delta.
- Proved that every one of the 1,066 visible TOC rows is clickable, not merely that its destination
  exists: physical pages 5--29 contain 1,129 Link rectangles, with the extra 63 belonging to
  wrapped titles. In a decompressed PDF fixture, changing only the `Preface` annotation subtype
  from Link to Text preserved the destination, title, parent, page-landing and other geometry
  checks; the new guard alone reported 1,128 rectangles, 1,065 targets and missing `chapter*.1`.
  This verifier-only hardening has no release-PDF or visual delta.
- Bound every TOC rectangle to the structural identity visibly printed beneath it by matching
  MuPDF text geometry to the Part roman numeral, chapter/section/subsection number, appendix
  letter, `Preface`, or `Index`. A decompressed-PDF fixture swapped only the `chapter.1` and
  `chapter.2` TOC destinations; target coverage, landing pages and all prior navigation checks
  remained green, while the new guard alone reported the two crossed identities. This verifier-
  only hardening has no release-PDF or visual delta.
- Audited all 3,652 Link rectangles against a single MuPDF structured-text extraction of all 709
  pages and proved that each has positive-area overlap with visible text. A decompressed-PDF
  fixture moved only preface link object 4302 to the still-in-bounds blank rectangle
  `[10 10 20 20]`; target and geometry checks remained green, while the new guard alone reported
  one empty hotspot on physical page 3. This verifier-only hardening has no PDF or visual delta.
- Closed the entire named-destination tree rather than only currently linked names: all 5,054
  names map one-to-one to 5,054 destination objects, each using an actual one of 709 page objects,
  an in-A4 numeric XYZ coordinate and inherited zoom. A decompressed-PDF fixture changed only
  `part.1`'s Y coordinate from 558.81 to 900; all link, landing, outline and page checks remained
  green, while the new guard alone identified the invalid target on page object 5587. This
  verifier-only hardening has no PDF or visual delta.
- Recounted the pinned Graphics public include subtree after a broad numeric-claim sweep and found
  a real stale statement: it contains 125 `.hpp` files, not 106. Of these, 107 are directly under
  `Microsoft/Xna/Framework/Graphics/` and 18 belong to its `PackedVector/` child, so the old prose
  also flattened a real nested namespace. Chapter 3 now states both counts. Its two semantic
  namespace index entries intentionally update makeindex to 2,389, index links to 1,850 and total
  link annotations / unique targets to 3,653 / 1,542; the verifier rejects the stale wording. A
  whole-PDF pixel comparison isolated only physical page 47 and index pages 706--709; all five
  were rendered and read full-size, clean.
- Recounted the seven physical-module move commits directly: all 1,776 changed records are `R100`.
  The pinned no-loss evidence also confirms 1,357 production files before and after, split into
  1,287 byte-identical moves and 70 directive-only edits. Corrected Chapter 9's misleading
  “translation units” label because the inventory includes headers; added a verifier guard. The
  complete build is green and physical page 117 was rendered and read full-size, clean.
- Reproduced Chapter 61's platform population from the pin: exactly 720 `.hpp`, 474 `.cpp` and
  one `.mm` production file after excluding tests/examples. A line-oriented OS-macro audit gives
  55 files / 152 directive lines, 97 in renderers and 55 elsewhere; compiler-only generated
  branches had made the prior boundary ambiguous. Updated the independent `CNA_RENDERER_*`
  directive count from 109 to 110 and qualified roughly 6,000 SDL-family tokens as lexical
  magnitude rather than API call sites; added a stale-count guard. The complete build is green;
  physical pages 584–585 were rendered and read full-size, clean.
- Scanned every include directive in easy-gl's pinned public headers and implementations. Exactly
  18 production files directly include meta-gl: three headers and fifteen `.cpp` files. Corrected
  Chapter 59's 19 / three-plus-sixteen off-by-one and added a verifier guard. The complete build
  is green; physical page 569 was rendered and read full-size, clean.
- Reproduced free-direct's status table by its actual annotation token. The three pinned headers
  contain exactly 95 `Status:` lines (56 implemented, 23 partial, 16 stub); `dsound.h` also has an
  opening twelve-item untagged recap that a broad word grep double-counts. Clarified the census
  rule in Chapter 60 without changing the already-correct table. The complete build is green;
  physical page 577 was rendered and read full-size, clean.
- Closed the broad numeric-claim sweep with direct pin-level recounts. Confirmed CNA's 433 / 6,818
  CnaTests source/definition populations, 1,233 / 1,169 example-source populations, derived 1,785
  renderer registrations, 141 / 139 Color counts, 46 / 42 renderer identities/families, 39/39
  oracle corpus and 1,876 CNAEXT tokens across 302 module headers. Confirmed sibling catalogues
  (xna4-spec 544 types / 19 namespaces; cna-samples 63+23+67=153; cna-examples 13/79/249),
  easy-gl/meta-gl code/API counts, free-direct/free-api registration counts, and sharp-runtime's
  41-module / 44-component / 92-edge graph plus exact 16,201-task / 2,183-ticket SQLite totals.
  No additional manuscript correction was warranted and this checkpoint has no PDF delta.
- Rebuilt corrected checkpoint `3db9edc` from two independent clean archives in different paths
  under `SOURCE_DATE_EPOCH=1786529214`. Both 709-page, 3,314,744-byte outputs have SHA-256
  `7c877ef20bdb20042bdd32483b2e79cb07e81dec7a8d86dc24f6d29d4a04b2af`; one passed the complete
  current verifier. This is the current release fingerprint; the earlier `b62f064...` result is
  retained as the historical interactive-index checkpoint.
- Tightened the page-label audit from a transition-only predicate to exact equality on the entire
  number tree plus the 709-page extent. The artifact therefore labels physical pages 1--30 as
  `i`--`xxx` and 31--709 as `1`--`679`. A simulated 710-page artifact retaining the same transition
  passed the old label predicate and fails the combined invariant. Recounted the searchable layer at 302,448
  `pdftotext -layout` words; 302,443 remains the historical Phase-G count.
- Bound release populations that had previously been checked only for cleanliness or internal
  consistency: makeindex must accept exactly 2,389 entries with no rejection/warning, and the PDF
  must contain exactly 3,653 targeted in-A4 Link rectangles. Added a complete Poppler layout-mode
  extraction requiring 302,448 words and no NUL or U+FFFD bytes. Reduced-count predicates fail;
  the fixed-date release artifact passes the expanded verifier without a PDF delta.
- Converted annotation safety from blacklist-only to a positive full-object census. Every one of
  3,653 annotations must be `/Link`; 3,650 must carry an internal `/GoTo` action and exactly three
  must carry the reviewed `/URI` actions, with no direct-destination or unknown remainder. The
  pre-existing blacklist and exact HTTPS allowlist remain defense in depth; no PDF delta.
- Positively allowlisted the normalized PDF catalog: Pages, Outlines, destination Names,
  UseOutlines, en-US, exact PageLabels and OpenAction only. Names may contain only Dests, and the
  opening action must be an internal GoTo/Fit to the first actual page object. A synthetic `/AA`
  branch fails exact comparison; this verifier-only hardening has no PDF delta.
- Added a sealed release entry point, `tools/build-release.sh`. It forces a complete fixed-date
  rebuild, requires the reviewed 3,314,744-byte / `7c877ef...` fingerprint and then runs the full
  verifier. README records the workflow and explicitly requires a new independent reproduction
  and visual checkpoint before changing fingerprint constants.
- Closed font/image cardinalities: font portability now means exactly 27 complete font rows.
  `pdfimages` plus Netpbm decode the five embedded RGB/soft-mask pairs and their five RGBA sources;
  all corresponding RGB and alpha planes compare byte-identically. The verifier enforces exact
  populations and README records the added tools; no PDF delta.
- Automated the previously historical parse/rewrite check. MuPDF rewrites the release into a
  disposable PDF, Poppler requires the same 709 pages and byte-identical layout text, and
  Ghostscript independently interprets the rewritten object graph. The release passes all three
  stages and its sealed bytes remain untouched.
- Made the PDF profile explicit: version 1.7, 709 pages, unencrypted, `Tagged: no`, `Suspects: no`
  and no user properties, alongside the existing geometry checks. This prevents a partial tag tree
  from masquerading as an accessible edition; any genuinely tagged/PDF-UA release remains an
  explicit owner decision and separate audit.
- Reconciled the durable Claude Code guide with the completed tooling: the authoritative batch
  check is now `tools/verify-book.sh`, visual inspection of touched pages remains mandatory, and
  the sealed fixed-hash command is reserved for release reproduction. No methodology or PDF delta.
- Expanded source closure to include the title page and preface. The verifier now requires 89
  content sources plus two front-matter sources, all 91 case-correct and input exactly once, with
  no orphan, duplicate or missing target. The artifact already satisfied the stronger graph.
- Bound TeX's `main.fls` recorder to a filesystem-derived 98-input project set: main source,
  preamble, 91 front/content TeX files and five PNGs. There are zero missing or unexpected inputs;
  distribution and generated files are deliberately outside the path/type boundary.
- Bound each of the three approved external actions to its own visibly printed URL using the
  existing MuPDF all-link geometry pass. All three match byte-for-byte. Swapping two approved
  target values still satisfies the allowlist but now triggers two semantic identity failures.
- Bound outline order, not only its sorted destination/title/parent sets: all 1,066 MuPDF outline
  destinations must occur in the exact `main.out` sequence. The current release is byte-identical;
  swapping two otherwise-valid records fails the new guard without relying on aggregate counts.
- Bound visible TOC order using the first occurrence of each expected destination, which excludes
  six legitimate duplicate navigation links while retaining all 1,066 structural rows. The PDF
  sequence matches `main.toc` byte-for-byte; row swaps now fail even if set checks remain green.
- Fixed the remaining navigation cardinalities that had only non-empty predicates: exactly 1,542
  unique internal link targets and 1,065 numbered TOC landings. Silent removal of a still-valid
  subgroup now fails alongside the existing exact link/name/TOC/index populations.
- Isolated named verifier diagnostics in a private per-run temporary directory with cleanup on
  normal exit and common termination signals. Concurrent runs can no longer overwrite eleven
  stale-fact/whitespace outputs, and successful runs leave no new named scratch files.
- Ran the sealed workflow from a fresh `git archive` of tracked commit `d551a3f`, with a local
  baseline only for whitespace status. It reproduced the exact 3,314,744-byte / `7c877ef...` PDF
  and passed every expanded verifier check without any workspace-only input.
- Added an early sealed-input preflight: `HEAD:latex` must equal reviewed tree `406104d...`, and
  `git status -- latex` must be empty including non-ignored untracked files. Typesetting drift now
  fails before the expensive rebuild while documentation/verifier-only commits remain valid.
- Bound the sealed PDF Info dates to `D:20260812100654Z`, matching epoch 1786529214, via MuPDF.
  CreationDate/ModDate drift now has a direct diagnostic in addition to the byte hash; ordinary
  working builds remain timestamp-agnostic.
- Made verifier arguments fail closed: only default build/check, `--no-build`, and `--help` are
  accepted. Unknown or multiple arguments now return 2 with usage before make or scratch setup,
  preventing an accidental expensive build under a mistyped option.
- Made the sealed release entry point fail closed as well: its only executable mode takes no
  arguments, while `--help` exits cleanly and every other argument vector returns 2 before any
  repository/dependency check or release-log write.
- Closed the generated-index source/output census: all 2,389 records have a non-empty key,
  `hyperpage` encapsulator and printed page 1–670, while 681 case-folded logical keys map without
  loss to 676 top-level items plus five subitems.
- Completed verifier scratch lifecycle management: every temporary text, JSON, PDF and image now
  lives below one private run directory whose recursive EXIT trap covers ordinary completion,
  failed checks and signal exits; index key folding is also fixed to the C locale.
- Extended PDF Info semantics with exact creator and non-trapped state checks, producing direct
  diagnostics for fields that were previously protected only indirectly by the sealed hash.
- Hardened the mandatory visual-pass driver: exact CLI/range validation, dependency preflight,
  isolated per-run output and exact PNG cardinality prevent typo and stale-file review gaps.
- Made unreadable PDF containers fail at the first Poppler parse with a required numeric page
  count, before any dependent geometry or navigation logic can generate secondary diagnostics.
- Made verifier scratch bootstrap self-checking: `mktemp` resolution and the initial private
  directory allocation now fail once, explicitly, before any temporary path is consumed.
- Closed the declared image graph independently of TeX's set-like recorder: all five case-correct
  PNG paths must be included exactly once, with no duplicate, orphan or missing/non-PNG target.
- Made visual rendering fail fast on Poppler parse/page-count and private-directory allocation
  errors, before bound arithmetic or `pdftoppm` can produce secondary/partial output.
- Closed sealed-pipeline dependency preflight over the build and full verifier, reporting every
  missing tool before TeX rather than discovering a late parser absence after a costly rebuild.
- Made the sealed PDF transactional: failed/interrupted build, fingerprint or verification paths
  restore the prior artifact byte-for-byte (or remove a new partial), while retaining diagnostics.
- Serialized the whole sealed transaction with a per-repository non-blocking kernel lock, so
  concurrent invocations cannot interleave build output or cross each other's restore boundary.
- Preserved the only prior-PDF snapshot when rollback copying itself fails and report its path,
  preferring recoverability over cleanup in that exceptional storage/permission failure.
- Moved the stable release lock beneath a validated owner-only (`0700`) per-user directory,
  removing the predictable public-`/tmp` symlink/open redirection surface.
- Reconciled README with the hardened workflow's real dependencies and transactional PDF behavior
  (`pdftoppm`, `flock`, restore/remove semantics); documentation only, no release delta.
- Unified all three artifact tools on one private per-repository shared/exclusive lock protocol:
  builds serialize, read-only verifier/render runs may coexist, no reader sees a mid-build PDF,
  and inherited descriptor identity is bound to the correct repository lock inode.
- Recorded the shared/exclusive artifact-lock rule in README and CLAUDE so future PDF consumers or
  writers inherit the same concurrency boundary instead of bypassing it.
