# The CNA Bible — editorial and technical quality audit

**Audit date:** 2026-08-12  
**Editorial baseline:** `next` @ `b236bb65fdccaa7c1c9d62096be4fc8e05477f80`  
**Baseline artifact:** `latex/book/main.pdf`, 709 A4 pages, 3,314,744 bytes  
**Purpose:** internal working document for the professional editorial pass requested on
2026-08-12. It is not a source of CNA behavior. The pinned repositories and retained evidence
remain authoritative.

## Alpha.1 edition addendum (2026-08-20)

This file remains the history and closure record of the 2026-08-12 editorial pass; its baseline
pin, counts, contradiction map, page renders, and sealed-artifact facts are not rewritten as if
they had occurred at alpha.1. The new technical edition is bounded instead by
[`audit/alpha1-delta.md`](audit/alpha1-delta.md), with CNA
`v0.1.0-alpha.1` @ `1bb2145d99ed572dd4eb15009c34e2e5f410fcf0` as authority.

The alpha.1 pass preserves the prose and layout standards closed below while superseding dated
technical conclusions: 50 identities / 46 families, runtime multi-renderer selection, independent
platform/audio axes, bounded compiled Effect bytecode, the experimental native C API, and the
current glTF L1--L7 evidence. The C API treatment now records that its broad source/header surface
is nevertheless compile-blocked in the exact tag by a stale renderer map; editorial preservation
does not soften that negative build evidence. The resulting candidate is 584 A4 pages, with 79
chapters, nine appendices, 179,457 prose tokens, 192 listings, 25 figures and 109 tables. The full
semantic/PDF verifier passes. All 264 materially changed pages were rendered and read; full-size
review found a Chapter 21 mid-word title break and a platform-table collision, both corrected and
re-rendered cleanly; a tight platform-diagram label was widened and rechecked. Two clean builds
of the committed LaTeX tree at `SOURCE_DATE_EPOCH=1787253313` then produced the same 2,602,878-byte
PDF with SHA-256 `f4916143649d3e5e64bf6c4a5e2e0027ef136b8510ba338f58450c33a984870e`.
The alpha.1 sealed profile therefore supersedes the prior release fingerprint without rewriting
the historical record below.

## 1. Repository and evidence baseline

### 1.1 Instructions, handoffs, and validation inspected

The audit began before manuscript editing. The following were inspected:

- `CLAUDE.md`, `README.md`, `NEXT.md`, `PLAN.md`, `PROGRESS.md`, and the two 2026-07-26 archive
  handoffs;
- `AUDIT.md`, `cnabugs.md`, and all ten reports under `audit/`, including the renderer draw-path
  matrix;
- `latex/Makefile`, `latex/book/main.tex`, the common preamble, front matter, every chapter and
  appendix source, the five retained screenshots, generated index files, and the current PDF;
- `tools/verify-book.sh`, `tools/build-release.sh`, `tools/book-lock.sh`,
  `tools/render-pages.sh`, and the screenshot-infrastructure README.

The book has no BibTeX or biblatex database. References are revision-bounded repository paths,
named documents, inline source locations, cross-references, and three reviewed HTTPS links. This
is appropriate for a source-audit monograph, but the production-method section must explain the
reference model so readers do not mistake the absence of a bibliography for an absence of
sources.

### 1.2 Edition pins and observed checkouts

The edition remains pinned to these revisions:

| Repository | Edition pin | Observed checkout on 2026-08-12 | Local state relevant to this pass |
|---|---|---|---|
| CNA | `7a64362efef4119bf880459ef1704fb2c52199e2` | `9918353b82256000dd1356d547d874fce2afd9d2`, `develop` | clean three-commit descendant; all edition checks read the pinned Git object |
| sharp-runtime | `f827a6c5349234d5ac938886788ed8eca8fe1c10` | same, `develop` | clean |
| easy-gl | `0b46d35c394a9fb6aea6a85c6587894b5013da33` | same, `develop` | unrelated untracked `VERSION` |
| meta-gl | `571d3a62fe166b9781ac6193d137b12ff3757620` | same, `develop` | unrelated staged/modified `VERSION` |
| free-direct | `934f72ff0c52902631fceeb52c006f3ed2767485` | same, `develop` | clean |
| free-api | `53d7a3124110fb30eea370a42c86ccff0c39aef3` | same, `develop` | clean |
| xna4-spec | `8f61207d5e766565bdde0aacf8aaa7285fcba71e` | same, `develop` | clean |
| cna-samples | `149a19f467b8444bc16f4335419449488cb64ba6` | same, `develop` | unrelated modified tank model asset |
| cna-examples | `fa0b49a890426b63c280c60bd4b799c840012afc` | same, `develop` | clean |
| cna-template | `1d86681fdb08b4324959fe0cd69fd687e65ee28e` | `4d0a2c8a790a2606d0e9a330fe7439f6b691722f`, `next` | clean descendant; prose stays at the edition pin |
| cna-craft | `7d7f186a9f583ca596484431a21a7e6a1a2e9f56` | same, `develop` | clean |
| cna-extended | `2ff3cff1ae79f33aac0ecf2f50fafe87414d1840` | same, `develop` | clean |

No sibling checkout will be modified. In particular, the three unrelated dirty states above
must survive this pass unchanged. A newer checkout is not evidence for the pinned edition unless
the edition is deliberately repinned, which this pass does not do.

### 1.3 Baseline validation result

`tools/verify-book.sh` passed from the clean editorial baseline before any edit. It established:

- clean LaTeX references, labels, citations, index input, source graph, and stale-identifier
  scans;
- 709 readable, unencrypted, untagged A4 pages with a selectable text layer;
- embedded, subsetted, Unicode-mapped fonts and pixel-identical inclusion of all five source
  screenshots;
- 12 parts, 79 numbered chapters, 8 appendices, 1,066 outline entries, valid page labels,
  internal destinations, TOC links, index links, and the three reviewed external links;
- 153 internal overfull-box warnings but no extracted text outside the physical page bounds;
- 12 intentional blank open-right versos and a successful Ghostscript/MuPDF parse.

This is a strong artifact baseline. It is also overfitted to the sealed edition: the verifier
hard-codes page, word, input, link, bookmark, image, index, and byte counts. Editorial changes
must preserve the semantic checks while moving release fingerprints into one explicit release
profile. A manuscript should not fail merely because a useful paragraph was removed.

## 2. Measured manuscript baseline

| Measure | Baseline |
|---|---:|
| Compiled chapter/appendix source files | 89 |
| Front-matter source files | 2 |
| Parts / numbered chapters / appendices | 12 / 79 / 8 |
| Book-source lines, including front matter and `main.tex` | 30,295 |
| Chapter/appendix lines reported by verifier | 30,046 |
| Whitespace-delimited words in all book TeX | 243,174 |
| Stable token count after removing listings and comments | 246,787 |
| PDF text-layer words | 302,448 |
| Sections / subsections | 683 / 274 |
| Code listings | 250 |
| Tables (`table`, `longtable`, and standalone tabular forms) | 96 |
| Raster figures | 5 |
| Index input records / normalized keys | 2,389 / 681 |
| Visible PDF outline entries | 1,066 |

The source and PDF counts measure different things: TeX commands, repeated running material,
the contents list, and the index make them non-comparable. The prose-reduction target will use
one stable source metric that excludes listings and comments. A 15–25% reduction therefore means
roughly 37,000–62,000 tokens on that metric, not a target page count.

### 2.1 Prose-pattern inventory

Counts below exclude code listings. They identify editorial review queues, not forbidden words.

| Construction | Occurrences |
|---|---:|
| `real` | 1,421 |
| `genuine` / `genuinely` | 133 / 172 |
| `actually` | 294 |
| `precisely` | 86 |
| `worth knowing` / `worth noting` | 34 / 3 |
| `rather than` | 639 |
| `not merely` / `not just` | 74 / 45 |
| `this is not` | 34 |
| `read directly` | 20 |
| `a worked example` | 67 |
| `does not prove` | 18 |

The problem is cumulative cadence. Individual occurrences may be exact and necessary. The
highest-density chapters are GamerServices, Media, Avatar, Networking, the Blupi case study,
Storage, SpriteBatch, native-modern-GPU renderers, stock effects, and Modern Direct3D. Those
chapters receive sentence-level review rather than a global substitution.

Recurring AI-like patterns to remove or vary:

- adjective-as-proof (`real test`, `genuine renderer`, `actual implementation`) where the next
  clause already names the evidence;
- repeated contrast frames (`not merely X but Y`, `not just X`, `rather than`) where a direct
  declarative sentence is shorter;
- repeated metacommentary (`worth knowing`, `worth remembering`, `the honest summary`);
- title-level rhetorical drama (`time machine`, `never forgets`, `one real constructor`) where it
  obscures lookup value;
- audit chronology told as a sequence of tasks, failed first attempts, and fixes when only the
  current contract and one compact historical lesson are needed;
- restating a table or listing in the paragraph immediately after it.

No exact long-paragraph duplicates were found. Repetition is conceptual: the evidence philosophy,
the meaning of a skipped test, renderer engagement, source-versus-runtime limits, and stale-doc
warnings are repeatedly re-explained in new wording.

### 2.2 Absolute-language inventory

The source contains 621 `all`, 818 `every`, 159 `complete`, 64 `fully`, 274 `exact`, 120
`identical`, 150 `always`, 337 `never`, 14 `guaranteed`, 65 `supported`, 32 `works`, 132
`correct`, and 47 `parity` occurrences. Many describe exhaustive enum branches, unconditional
throws, or measured corpus results and should remain. Each universal claim nevertheless needs
one of these scopes:

1. language/API semantics (`always throws` in a named pinned function);
2. repository population (`all 42 implementation families`, derived mechanically at the pin);
3. measured corpus (`all 39 named scenes on a named configuration`);
4. historical campaign result (dated and explicitly historical);
5. portable user claim (rare; must name platform/renderer exclusions).

The title-page phrase `A complete technical account of CNA` fails this test. It will become
`A comprehensive, revision-bounded technical account of CNA`; the title *The CNA Bible* remains.

## 3. Structural audit

### 3.1 Navigation

The current contents list exposes subsections, producing roughly 25 contents pages and making
the hierarchy difficult to scan. Keep subsection bookmarks in the PDF outline, but show only
parts, chapters, and sections in the printed contents. Add a short Reading Paths section before
Part I for:

- a new CNA user;
- an XNA/FNA porter;
- a renderer implementer;
- a framework contributor;
- a content/glTF contributor;
- a verification/audit contributor.

The opening must answer the practical beginner questions without duplicating later chapters:
what CNA is, why one might choose it, the minimum program, build route, asset route, renderer
choice, portable-surface rule, CNAEXT boundary, renderer-failure triage, and known incompleteness.

### 3.2 Chapter heat map

Five chapters account for an excessive share of the manuscript and mix too many content modes:

| Chapter | Approx. prose tokens | Sections / subsections | Main editorial problem |
|---|---:|---:|---|
| 19 Renderer Contract | 18,292 | 8 / 20 | interface reference, 14-family audit, task history, resource rules, capabilities, and build factory interleaved |
| 12 GraphicsDevice | 12,798 | 14 / 26 | public API, renderer forwarding, lifetime, resource defects, examples, and renderer matrices overlap Chapters 14, 18, 19, and Appendix B |
| 7 Math Conventions | 12,251 | 11 / 23 | narrative conventions and near-complete type reference duplicate Appendix A |
| 35 XNB Type Readers | 10,735 | 5 / 13 | registry mechanics, per-reader reference, object graph, and evidence are insufficiently layered |
| 33 ContentManager | 9,650 | 7 / 13 | resolution contract is buried under per-type narratives repeated in Chapters 35 and 46 |

Additional high-risk chapters are 28 (Modern Direct3D), 6 (Game Lifecycle), 44–52 (services),
13–17 (graphics), and 75 (Blupi case study). Their content is valuable; the needed work is
hierarchy, historical compression, calmer prose, and cross-reference discipline.

### 3.3 Target chapter architecture

Use this hierarchy when it fits, without forcing identical headings everywhere:

1. purpose and mental model;
2. current public contract;
3. pinned implementation;
4. short practical example;
5. renderer/platform differences;
6. limitations and deviations;
7. evidence status;
8. compact historical note, only when it teaches a transferable lesson;
9. user implications or summary.

At present many headings encode rhetoric or audit chronology instead of search terms. Examples
include `One header, not several`, `already covered, worth remembering here`, `a real ...`, and
`what this buys a porting engineer`. Replace them with contract-oriented headings that remain
useful in the TOC and index.

### 3.4 Canonical homes for repeated material

| Topic | Canonical home | Elsewhere |
|---|---|---|
| Full evidence vocabulary and oracle model | Appendix G | one compact table near the front; short cross-references only |
| Counting methodology and unstable totals | Chapter 69 | cite the noun/configuration rule; do not repeat static inventories |
| Renderer identity versus implementation family | Chapter 20 and Appendix B | use centralized count macros and cross-reference |
| GraphicsDevice-to-renderer forwarding contract | Chapters 12 and 19 | Chapter 12 owns public behavior; Chapter 19 owns interface defaults and family divergence |
| Resource lifetime and disposal | Chapters 12 and 14 | service/content chapters state only their special ownership rule |
| Stock effect semantics | Chapter 15 | renderer chapters state only deviations and evidence |
| Arbitrary/custom shader routes | Chapter 17 | renderer chapters link to the relevant route |
| Content resolution | Chapter 33 | type-reader chapters assume the resolved stream/path |
| XNB object-graph machinery | Chapters 34–35 | service/media chapters state only type-specific payload details |
| glTF evidence matrix | Appendix H | Chapters 39–43 explain mechanisms and notable limits, not repeat the whole matrix |
| Platform evidence vector | Appendix G and Chapter 61 | per-platform chapters give the observed leg only |
| Bug/audit methodology | Chapters 68–73 | feature chapters retain only historically instructive cases |

## 4. Technical consistency audit

### 4.1 Required evidence vocabulary

Appendix G remains authoritative. The front matter will introduce these labels and the manuscript
will use them consistently:

- **source-proven** — reachable behavior or absence established by pinned source inspection;
- **compile-proven** — names, signatures, includes, templates, and link closure exercised;
- **runtime-observed** — a named path executed and yielded the recorded state/result;
- **renderer-engaged** — the intended renderer implementation and native/translation route were
  shown to run;
- **oracle-compared** — the observation was compared with an identified independent or
  project-owned oracle under a stated policy;
- **pixel-verified** — the relevant readback/frame pixels were compared, with scope/tolerance;
- **manually observed** — a human inspected the result without a retained discriminating oracle;
- **historically recorded** — a dated artifact reports the result, but it was not rerun for this
  edition;
- **blocked**, **unsupported**, and **not attempted** — distinct outcomes, never aliases for skip
  or failure.

`supported` may still describe a documented public capability, but evidence claims must name the
state above. `API present`, `compiles`, `runs`, `renderer engaged`, `behavior matched`, and `pixels
matched` are not interchangeable.

### 4.2 Renderer terminology

The canonical nouns are:

- **renderer identity** — one public selector accepted by the CNA build;
- **implementation family** — one source implementation under `modules/renderers`;
- **renderer interface** — `IGraphicsRenderer` and its public-to-private forwarding contract;
- **native API** — Vulkan, D3D11, Metal, WebGPU, SDL Renderer, and similar downstream APIs;
- **factory** — the construction function for an implementation family;
- **profile** — a mode within a family, notably the five EasyGL identities.

`renderer`, `identity`, `family`, `native API`, `factory`, and `profile` must not become synonyms.
The phrase `graphics backend` is retired except in quotations or explicit discussion of historical
names. The mechanically derived edition fact is 46 public identities and 42 implementation
families; it will be defined once in source macros rather than copied as independent literals.

### 4.3 Adversarial contradiction map

The final pass must test every occurrence of these topics against the following canonical
boundaries:

| Topic | Canonical current statement at the pin |
|---|---|
| XNB | CNA has a binary XNB container/object-graph reader with per-reader coverage and bounded gaps; existence is not full XNA content-pipeline equivalence. |
| CNJ | CNJ is CNA's JSON-envelope sidecar family with per-type version ceilings; parsers are hybrid and not uniformly hardened. |
| ContentManager | Resolution order and reader behavior are type-sensitive; a resolved file does not imply successful decode/playback. Song/Video can incorrectly select a same-name CNJ file. |
| glTF | Parsing, runtime object construction, effect binding, animation playback, renderer draw, and pixel verification are separate claims. The runtime direct route takes only the first mesh group and does not surface every importer warning. |
| Stock effects | The five XNA-shaped stock effects contain substantial implementations; individual fields and renderer routes still differ. |
| arbitrary Effect bytecode | The public byte-buffer `Effect` constructor throws. FNA3D can execute retained stock bytecode internally; `ShaderEffect` and renderer-specific extension paths are different APIs, not one portable replacement. |
| custom shaders | Availability and language are renderer-specific. Capability reporting alone is insufficient because permissive defaults and null/false factories exist. |
| renderer support | A selector compiling is weaker than renderer engagement; engagement is weaker than correct draw semantics; draw completion is weaker than an oracle or pixel match. |
| MSAA | Requested sample count, applied/clamped count, resource allocation, resolve, readback, and pixel evidence must be distinguished. |
| MRT | A capability answer is not proof that a multi-target bind succeeds. HEADLESS, SOFTWARE, and WEBGPU report more than their reachable implementation provides at the pin. |
| occlusion queries | Object/factory presence, a trace object, and real sample counts differ. HEADLESS, SOFTWARE, SDL_GPU, and WEBGPU have capability-reporting contradictions. |
| render targets | Factory creation, binding, outgoing-target finalization, resolve, sampling, readback, and backbuffer restoration are separate behaviors. |
| Android/Web/macOS/Windows | Build-admitted, compile-proven, installed/launched, renderer-engaged, and pixel-verified are separate platform states. Historical CI is dated, not current execution. |
| Media/audio | Public API shape, decoder/mixer handoff, device engagement, playback timing, and audible output require different evidence. |
| networking | CNA's local/LAN implementation is not the historical Xbox service; session type and transport route constrain claims. |
| disposal/lifetime | XNA-shaped value syntax does not imply CLR ownership. Raw device tracking, shared texture handles, move/copy behavior, and explicit disposal have distinct hazards. |
| CNAEXT | `CNAEXT` marks non-XNA declarations; `CNA_CNAEXT` is an optional extension module. Neither is a synonym for arbitrary implementation detail. |
| sharp-runtime | It supplies selected .NET-shaped facilities, not a CLR. Component count, module-directory count, header count, and test count name different populations. |
| free-direct/free-api | They are bounded compatibility layers and indirect dependencies, not general Windows/DirectX implementations. |

Chronology must resolve apparent contradictions: a historical result stays only when dated and
visually separated from the current contract. If two live chapters disagree, the pinned source
and evidence decide; both versions are not retained for narrative symmetry.

### 4.4 Stale-number policy

Numbers fall into four classes:

1. **structural facts derived during the build** — chapter/input/image/outline/index counts;
2. **edition facts derived from pinned source** — renderer identities/families, source/header
   inventories, fixtures, workflows, scenes, task rows;
3. **configured or executed results** — discovered tests, pass/fail/skip totals, renderer/device
   results;
4. **historical facts** — dated campaign counts and earlier corpus sizes.

Class 1 should be validated dynamically. Repeated class-2 values should be generated or defined
once and accompanied by the pin. Class 3 must name configuration, host, date, and outcome. Class
4 must say `historical` and must not be silently compared with current totals.

Immediate duplication to remove:

- renderer counts repeated throughout front matter, Chapters 1, 4, 9, 13, 20, 61, 69, 74, 79,
  and Appendices A–D;
- sharp-runtime header/line/test inventories repeated in Chapters 53 and 58;
- the 39-scene oracle count repeated in several chapters without one central source macro;
- source/header/renderer-platform counts used without an adjacent derivation or pin;
- task/phase totals narrated as if they were product capabilities.

### 4.5 Examples

There are 250 listings. They currently mix complete examples, excerpts, shell transcripts,
pseudocode-like sketches, and deliberately failing snippets without a consistent label. Each
touched listing must be classified as one of:

- **compiled example** — exact build target/configuration recorded;
- **adapted from a compiled CNA test/example** — source path and omitted scaffolding identified;
- **illustrative excerpt** — intentionally incomplete and never described as compilable;
- **negative example** — expected failure/exception stated;
- **command transcript** — revision and host assumptions stated.

Names, headers, namespaces, overloads, CNAEXT status, and ownership must be rechecked against the
pinned headers. Shorten examples that duplicate the prose or contain speculative setup. Do not
patch CNA to make a listing true.

## 5. Diagram plan

The current book has five screenshots and no architecture diagrams. Add a modest set of
reproducible TikZ figures, using shape and line style as well as color so they remain legible in
grayscale. Every figure needs a caption, a source-level description, a pin/evidence note where
the topology is revision-sensitive, and readable type at normal print size.

Planned high-information figures:

1. CNA ecosystem and sibling dependency graph (Chapter 2).
2. Build-time route from selector to identity, family, and native API (Chapter 20).
3. CNA module graph and the sharp-runtime foundation (Chapter 9).
4. `Game::Run()` desktop lifecycle and Emscripten divergence (Chapter 6).
5. `GraphicsDevice` → renderer interface → native API flow (Chapter 12).
6. Graphics resource ownership, tracking, disposal, and handle lifetime (Chapter 14).
7. SpriteBatch queue/sort/flush/submission flow (Chapter 13).
8. Stock effect, bytecode, `ShaderEffect`, and renderer-owned shader strategy map (Chapter 17).
9. ContentManager resolution and type-reader dispatch (Chapter 33).
10. XNB container → reader table → shared-resource object graph (Chapters 34–35).
11. CNJ envelope, sidecars, runtime readers, and `gltf_to_cnj` flow (Chapters 36/42).
12. glTF/GLB → shared import core → runtime Model/offline CNJ routes (Chapter 39).
13. Scene-node, `ModelBone`, joint, and skin-palette index spaces (Chapter 41).
14. Renderer capability/evidence ladder (Chapter 18 or Appendix G).
15. Verification/oracle vector, explicitly non-linear (Chapter 70/Appendix G).
16. Cross-platform build and execution routes (Chapter 61).
17. MinGW → Wine → DXVK/vkd3d → native API engagement path (Chapter 63).
18. Browser/WebAssembly compile, callback loop, renderer, and browser-observation path
    (Chapters 64–66).
19. sharp-runtime component dependency shape as consumed by CNA (Chapter 54).
20. XNA/FNA-to-CNA porting workflow with strict-surface and renderer-diagnosis branches
    (Chapter 74).

The target is 15–25 figures; any figure that becomes a decorative list will be removed. Diagrams
must not imply runtime evidence merely because an architectural edge exists in source.

## 6. Index, glossary, and reference usability

The automatic `\cnaclass`/`\cnans` indexing produces broad coverage but also 2,389 raw records.
During the pass:

- retain canonical class entries and useful subentries, but avoid indexing every incidental
  repetition as if it were a new concept;
- add or verify focused entries for GraphicsDevice, SpriteBatch, Texture2D, RenderTarget2D,
  VertexBuffer, IndexBuffer, BasicEffect, ShaderEffect, XNB, CNJ, glTF, skinning, morph targets,
  ContentManager, Game lifecycle, disposal, renderer identity, capability, Vulkan, D3D9/11/12,
  EasyGL, SDL Renderer, WebGPU, BGFX, FNA3D, HEADLESS, SOFTWARE, Android, WebAssembly, Wine,
  sharp-runtime, free-direct, oracle, pixel testing, and CNAEXT;
- use subentries for broad concepts (`renderer identity!selection`, `XNB!object graph`) rather
  than giant undifferentiated page lists;
- align glossary definitions with the canonical evidence and renderer terminology;
- keep Appendix G authoritative and Appendix B mechanically checkable.

## 7. Publishing and accessibility audit

Strengths already present: embedded fonts, Unicode mappings, selectable text, language metadata,
document metadata, bookmarks, internal links, page labels, and verified link geometry.

The PDF is not tagged. Full tagging under the present pdfLaTeX pipeline would require a toolchain
change with substantial risk to a 700-page artifact. This pass will investigate low-risk source
descriptions and metadata, keep heading hierarchy consistent, and document the untagged-PDF
limitation. It will not claim accessibility conformance without a tagged-structure audit.

Visual review priorities:

- the revised title, preface, reading paths, production note, and contents pages;
- every new diagram at actual reading size and in grayscale;
- all reflowed long tables and code listings;
- chapter openings and pages adjacent to floats;
- overfull warnings, page-edge geometry, headers, folios, open-right blanks, hyperlinks, and
  index/TOC destinations.

## 8. Production-method disclosure

Add a short factual section stating that extensive AI-agent assistance was used to assemble and
revise the book against pinned repositories, source, tests, project documents, and generated
artifacts. It must also state:

- AI output is not an authority;
- repository source and identified external oracles determine claims;
- claims are revision-bounded;
- automated and adversarial reviews were used;
- future editions should correct stale claims as the project changes;
- responsibility for the published edition remains with the named human author/editor.

This is production information, not an apology or promotional copy.

## 9. Companion-guide decision

A shorter beginner-oriented companion could eventually help readers who need build/install,
first game, input, audio, sprites, 3D basics, content, renderer selection, porting, and deployment
without the audit history. Writing it now would divert this pass. Record a future proposal for
**Programming with CNA** in planning material; do not split this repository or create a second
book during the present campaign.

## 10. Rewrite order and acceptance measures

### Phase A — audit and infrastructure

- preserve the clean baseline and sibling dirty states;
- add this audit;
- centralize release facts and editorial metrics;
- add diagram/callout vocabulary and front-matter navigation.

### Phase B — global structure

- centralize evidence terminology and renderer counts;
- replace historical task narratives with current-contract/evidence/history hierarchy;
- reduce printed TOC depth while preserving useful bookmarks;
- perform the first absolute-language and AI-cadence pass.

### Phase C — Parts I–IV

- prioritize Chapters 6, 7, 12, 13–19, 20, 28, and renderer comparison chapters;
- remove GraphicsDevice/renderer/resource/effect duplication;
- add architecture diagrams and scoped evidence summaries.

### Phase D — Parts V–VII

- make ContentManager resolution canonical;
- separate XNB container, readers, and object graph;
- preserve the detailed glTF evidence matrix while shortening repeated caveats;
- calm the high-density service chapters and retain their defects/limits.

### Phase E — Parts VIII–XII

- de-duplicate sharp-runtime inventories;
- scope sibling and platform claims;
- consolidate verification philosophy into Appendix G;
- convert the porting chapter into a navigable workflow.

### Phase F — appendices, index, and final adversarial review

- regenerate/check renderer and evidence tables;
- verify index destinations and glossary vocabulary;
- challenge every major chapter for overclaim, stale count, uncompiled example, lost renderer
  qualification, historical/current confusion, duplicated method, weak oracle, and AI cadence;
- fix findings or record a bounded residual limitation here.

The pass is successful when the semantic verifier passes, the PDF has been visually inspected,
major contradictions are resolved, the required terminology is consistent, the high-value
diagrams survive print-size review, and the prose-only metric falls meaningfully—preferably
15–25%—without losing limitations, evidence boundaries, or practical examples.

## 11. Findings closure log

An item is closed only after source build, semantic validation, and applicable visual
inspection. The final candidate is 574 A4 pages and 2,536,383 bytes, with SHA-256
`4d5a42926e6b5116bd52849ee998800efc09e39ca2876399aa07799c748c20d0`. Its stable prose metric
is 174,766 tokens, a 29.18% reduction from the 246,787-token baseline. The build contains 190
listings, 106 tables, and 25 figures (20 reproducible diagrams plus five retained screenshots).

| Area | State | Closure evidence |
|---|---|---|
| Baseline repository/pins/status | closed | recorded above; baseline verifier passed |
| Editorial metrics and release-profile centralization | closed | `editorial-metrics.sh`, pin-derived facts, and the old sealed fingerprint are centralized; a new seal awaits a commit |
| Front matter, reading paths, title claim, production disclosure | closed | final pages 1–8 rendered and inspected; title now says “comprehensive, revision-bounded” |
| Evidence vocabulary consolidation | closed | Appendix G is canonical; front-matter table and callouts use the same states |
| Renderer terminology/count centralization | closed | pin-derived verifier confirms 46 identities, 42 families, and 39 named oracle scenes |
| Parts I–IV structural/prose pass | closed | contract/history hierarchy, repetition, renderer scoping, and high-risk reflow pages reviewed |
| Parts V–VII structural/prose pass | closed | Content/XNB/CNJ/glTF and service boundaries reconciled and reviewed |
| Parts VIII–XII structural/prose pass | closed | sharp-runtime, sibling, platform, verification, and porting duplication/scoping reconciled |
| Diagrams | closed | 20 TikZ diagrams; all 25 total figures have descriptions and passed colour/grayscale print-size review |
| Examples/API signature audit | closed | all 13 cited headers exist at the pin; the complete first-game TU syntax-checks; its dummy-driver frame exactly matches the retained SDL screenshot |
| Index/glossary/navigation | closed | 1,661 accepted index records, 608 normalized keys, 994 outline entries, valid TOC/index destinations and required search terms |
| Absolute/stale-number/contradiction audit | closed | global queues reviewed; repeated counts centralized; canonical contradiction map reconciled against the pin |
| Clean build and semantic validation | closed | clean fixed-date build; complete verifier green; MuPDF/Ghostscript, fonts, links, page boxes, sources, images, references, and citations pass |
| Full rendered-PDF visual review | closed | whole-book contact review during editing plus all figures, changed high-risk batches, final front matter, Appendix G, index tail, and open-right blank checks |
| Final adversarial pass | closed | overclaim, stale count, chronology, renderer qualification, example, duplicate-method, diagram, and prose-cadence challenges resolved or bounded here |

## 12. Final bounded limitations and release administration

- The PDF is untagged. It has language/document metadata, bookmarks, selectable Unicode text,
  consistent headings, and source-level figure descriptions, but this edition makes no PDF
  accessibility-conformance claim. Retrofitting full tags safely requires a separately tested
  toolchain migration.
- The 116 internal overfull diagnostics do not correspond to physical clipping: coordinate-based
  validation found zero words outside any A4 MediaBox, and the affected high-risk pages were
  visually inspected. They remain diagnostic noise from intentionally dense technical material.
- Runtime execution in this editorial pass was deliberately bounded. The first-game example was
  compile-proven against the pinned CNA headers. The retained SDL screenshot was reproduced under
  SDL's dummy video driver and matched byte-for-byte and pixel-for-pixel; an Xvfb attempt was
  blocked because the installed SDL build lacks the required X11 video route. These results do
  not broaden the platform/renderer claims elsewhere in the book.
- At final postflight, CNA had advanced from the pin by three commits: `cnaplatform.md`, an ENet
  CMake-minimum adjustment, and graphics maturity/category enums. The edition was not repinned.
  `tools/verify-edition-facts.sh` reads the pin directly and remained green.
- The current filesystem permits reading but not writing `.git`. An attempted `git add
  EDITORIAL-AUDIT.md` failed while creating `.git/index.lock`; it changed neither the index nor
  the worktree. Therefore the reviewed candidate cannot yet receive a checkpoint commit or a new
  independently sealed release profile. `tools/release-profile.sh` intentionally continues to
  describe the preceding 709-page release until an authorized writable-Git session commits and
  reseals this candidate.
