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
| **B — new Table of Contents** | Part IV/renderers settled (§4 below). Parts I–III, V–IX not yet drafted — all research is in, this is a synthesis pass over `AUDIT.md` + `audit/*.md`, no further research needed. |
| **C — structural migration** | Started: all 112 hard-coded chapter references migrated to `\ref{}`. Remaining: create/move/split chapter files once Phase B lands, rename `part4-backends/`, run the terminology sweep. |
| **D — chapter writing** | Not started. No chapter prose has been rewritten yet. |
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

### 3.2 Commissioned but not yet run

- **The per-renderer draw-path divergence matrix.** Which of the 42 families implement
  `DrawPrimitivesEx`/`DrawIndexedPrimitivesEx` versus silently falling back to the
  colored-primitive path, which implement render targets, occlusion queries and MRT. Flagged as a
  gap by the graphics-core pass. This matters because the effect-aware draw defaults **silently
  degrade rather than fail** (`AUDIT.md` F-031), so a renderer that has not implemented them
  renders an untextured, unlit picture with no error. **Commission this before writing Part IV.**

---

## 4. Proposed new structure

Settled where marked; provisional elsewhere pending the four in-flight areas.

### Part IV — the renderers (**settled**)

Cluster by *what the renderer talks to and how it obtains shaders*, which is the axis on which
CNA's own code actually differs — not by age or vendor. The clusters partition all 46 identities
exactly (10+4+7+9+6+4+3+3 = 46, arithmetic independently checked).

| # | Cluster | Identities | Count | Depth |
|---|---|---|---|---|
| 0 | **The renderer contract** | — | — | 22–28 pp |
| 1 | **The OpenGL family** | `OPENGLES2` `OPENGLES3` `OPENGL33` `WEBGL1` `WEBGL2` `OPENGL1` `OPENGL2` `OPENGL4` `OPENGLES1` `PORTABLEGL` | 10 | 30 pp, 2 ch |
| 2 | **Native modern GPU** | `VULKAN` `SDL_GPU` `WEBGPU` `METAL` | 4 | 24 pp, 1–2 ch |
| 3 | **Abstraction-layer wrappers** | `BGFX` `MAGNUM` `LLGL` `DILIGENT` `SOKOL` `WICKED` `FNA3D` | 7 | 26 pp, 1–2 ch |
| 4 | **The legacy DirectX / retro ladder** | `DIRECTX1` `DIRECTX2` `DIRECTX3` `DIRECTX5` `DIRECTX6` `DIRECTX7` `DIRECTX8` `FREEDIRECT` `GLIDE` | 9 | 30 pp, 2 ch |
| 5 | **Modern Direct3D + Windows 2D** | `DIRECTX9` `DIRECTX10` `DIRECTX11` `DIRECTX12` `DIRECT2D` `GDI` | 6 | 24 pp, 1–2 ch |
| 6 | **2D / vector rasterizers** | `SKIA` `BLEND2D` `OPENVG` `SDL_RENDERER` | 4 | 16 pp, 1 ch |
| 7 | **Web / DOM** | `CANVAS` `HTML_DOM` `SVG_DOM` | 3 | 12 pp, 1 ch |
| 8 | **Non-GPU / diagnostic** | `HEADLESS` `SOFTWARE` `STUB` | 3 | 12 pp, 1 ch |

Cluster 0 is the highest-value new chapter in the book: 70 virtuals / 25 pure across ten
sub-interfaces; 13 capability flags with a **default-true polarity** that makes a forgetful
renderer over-claim; three *non-equivalent* 3D opt-out idioms; the `WarnAndStub` policy only six
renderers honour; identity-vs-family; and the checked-in-generated-shader-header pattern with
MAGNUM as its single exception. None of it is in the book today.

Cluster 4 has **zero coverage today** and is the book's most distinctive material: one modern API
projected onto 1995–2000 hardware APIs, with a measured port lineage and eight mechanically
enforced era-discipline gates.

### Parts likely to change (provisional)

- **Content becomes its own Part** (~5 chapters). The single 2,247-line chapter now spans four
  separable subsystems and has zero glTF coverage.
- **A 3D/glTF Part** (~5 chapters), justified less by feature surface than by the conformance
  apparatus: a pinned specification, a generated digest-verified corpus, a five-of-seven oracle
  ladder, and an executable defect ledger with a three-state lifecycle.
- **A Testing/Verification Part** (~6 chapters, 70–90 pp), including a chapter on *counting
  discipline* — what a test number can and cannot mean — which is original and load-bearing.
- **Effects/shaders retitled and restructured** around CNA's four real answers to `.fx`, not
  around a gap.
- **Math splits**; the game-loop chapter gains the lifecycle ordering it currently lacks.
- **Appendix E** (`NOXNA Catalog`) rebuilt as a CNAEXT catalog around the two-meanings framing.
- **Appendix B** rebuilt from `docs/renderer-registry.md`, which is current and dated to the pin —
  *not* from `docs/graphics-renderer-feature-matrix.md`, which self-labels "master, up-to-date"
  while carrying refuted rows and covering 4 of 46 renderers.
- **A new verification-tiers appendix**: which renderers are actually proven and by what evidence.
  Only 5 of 46 build an oracle-render binary; only 1 of those is a hard gate.

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
