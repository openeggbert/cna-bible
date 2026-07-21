# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session (or the last checkpoint of an
in-progress autonomous one) — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, which is a permanent history, and which has the full
per-chapter detail this file only summarizes).

## Where things stand right now (mid-session, autonomous depth pass in progress, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last checkpoint: **347 pages, 0 undefined references, 0
duplicate-label warnings** (verify before quoting — re-run `make book` and grep the log
before trusting this number; and use PNG rendering, not `grep -i overfull`, to check for
overflow — see "Reusable findings" below, this was reconfirmed many times this session,
including on `grep -a` output that revealed hundreds of pre-existing "overfull" log lines
`grep -i` alone was silently missing).

**Tasks #24-40 are all complete** (all of Parts I-IV, chapters 1-24, plus Appendix A).
**Task #41 (Parts V-IX, chapters 25-48) is in progress: all of Part V (Ch.25-32) and Ch.33-34
of Part VI are done this session**, plus Ch.36 of Part VII. Ch.35 was checked and found
already thoroughly covered (no edit needed). Continue with **Ch.37 (free-direct in Depth)**
next. See "A new, high-value technique discovered this session" below before starting each
chapter — it found real, substantial material in every chapter it was tried on this session
except Ch.25/35 (already-thorough, checked-not-edited), including in sibling-repo chapters:
`sharp-runtime`'s own `NEXT.md`/`audit.md`, and `easy-gl`'s own `NEXT.md`, each had exactly the
same kind of not-yet-mined recent findings the `cna` plan docs did. For any remaining Part
VI/VII/VIII/IX chapter about a specific sibling repo, check that repo's own root for a
`NEXT.md`/`PLAN.md`/`plan_*.md`/`audit*.md` first, the same way.

**This is an autonomous, long-running session** (the user explicitly authorized "continue
autonomously for as long as there is useful, safe work within scope" and asked not to be
interrupted with further questions unless something genuinely architecture-affecting comes
up). If you are picking this up fresh, there is no reason to stop and ask what to work on —
just continue the depth-pass task list below in order, using the same proven per-chapter
loop this whole project has used throughout: read current chapter → find a real,
source-grounded gap → write it → rebuild → render the chapter's own physical pages to PNG and
read them back → commit → push → move to the next chapter.

**Branch: `develop`.** A prior session merged the old feature branch into it; there is no
separate branch to look for. Commit and push directly to `develop`, small commits, one per
chapter, exactly as this whole session has been doing (check `git log --oneline -20` to see
the pattern if in doubt).

## This session's work so far: depth pass on Part I–IV chapters (19 of ~24+ planned)

The prior session did a **breadth pass** (first-ever touch) on all 22 previously-untouched
Part I–IV chapters plus Appendix A. This session is doing the natural next step, a **depth
pass** (second, deeper touch, adding more real worked examples/findings per chapter) —
mirroring the exact pattern already validated multiple times on Parts V–IX in even earlier
sessions. Completed so far this session, each with a real new worked example or finding,
grounded in an actual source read, rebuilt and PNG-verified before commit:

- **Ch.1 What Is CNA** — "Design goals in the project's own words" + cross-backend
  verification-scale comparison table.
- **Ch.2 Ecosystem Map** — a real, previously-undocumented second-level sibling dependency
  (`free-direct` → `free-api`), confirmed via `BackendSelection.cmake`.
- **Ch.3 Design Philosophy** — `SkinnedEffect::WeightsPerVertex` validated-setter example +
  `sharp-runtime`'s `BinaryReader::ReadChar`/`ReadDecimal` missing-dependency lifecycle example.
- **Ch.4 Building CNA** — real Android/NDK and Web/Emscripten build walkthroughs, incl. a real
  `sharp-runtime` `FileSystemWatcher.hpp` bug found and fixed along the way.
- **Ch.5 First Game** — a third complete worked program (edge-bounce + `SoundEffect`).
- **Ch.6 Game Loop** — a full `DrawableGameComponent` worked example (`FpsCounterComponent`).
- **Ch.8 Content and Assets** — two real `.cnj` files quoted directly from `cnj.md`.
- **Ch.10 SpriteBatch** — `SpriteSortMode::Texture` pointer-sort non-determinism finding
  (Task~668/414) + a full section on `Begin()`'s lasting `GraphicsDevice.BlendState` side
  effect (Task~956 fix, still-open Task~933 caveat).
- **Ch.11 Textures/Render Targets** — `TextureCube` six-face worked example +
  `RenderTargetCube` render-into-face worked example (`SetRenderTarget(RenderTargetCube*,
  CubeMapFace)` — caught and corrected a wrong first-draft API guess against the real header).
- **Ch.12 Models and Meshes** — full `MorphTargetEXT` worked example adapted from
  `MorphTargetEXTTests.cpp`'s own two-target fixture.
- **Ch.13 Stock Effects** — worked examples for all 4 remaining stock effects (AlphaTest,
  DualTexture, EnvironmentMap, Skinned), each tied to that effect's own already-documented
  audit findings.
- **Ch.14 State Objects** — worked examples for DepthStencilState (stencil-masked mirror),
  RasterizerState (shadow-map depth bias + wireframe toggle), SamplerState (pixel-art vs.
  mipmapped-floor filter choice); found/fixed one new and one pre-existing overfull-hbox.
- **Ch.15 Shader/.fx Gap** — matching real D3D9 HLSL worked example alongside the existing
  GLSL one, incl. a real minor doc-comment inaccuracy noted in `ShaderEffect`'s own header.
- **Ch.16 Backend Architecture** — `IRenderTargetBackend` deep-dive tying its default methods
  directly to Ch.11's per-backend render-target findings, and an `IEffectBackend`/%
  `IOcclusionQueryBackend` deep-dive (real finding: every `SetUniform*` setter defaults to a
  silent no-op).
- **Ch.17 SDL_RENDERER Backend** — a concrete pixel-value worked example for the blocked
  Wrap/Mirror decision (2x1 red/blue texture, oversized source rect).
- **Ch.18 EasyGL Backend** — a **stale-claim correction**: the two "real, large" bugs from the
  D3D9-oracle cross-measurement (negative-`FogEnd` solid-black, Fresnel interpolation) were
  logged as open but are both fixed in the current source (Tasks 1111/1112) — verified by
  reading `EasyGLGraphicsBackend.cpp` directly and hand-checking the fog formula's arithmetic.
- **Ch.19 Vulkan Backend** — expanded Ch.11's one-sentence `RenderTargetCube` black-render
  preview into a full section naming both root causes (Task 875 clear-only-RT gap, Task 876
  still-unresolved between two named candidates).
- **Ch.20 BGFX Backend** — the matching wrong-handle-type-cast diagnosis for BGFX's own
  `RenderTargetCube` bug (Tasks 873/874 — both handle types share an identical
  `struct{uint16_t idx;}` ABI shape, which is why the cast compiles and doesn't crash).
- **Ch.21 WebGPU Backend** — first-ever worked example anywhere in the book for `PbrEffect`
  (NOXNA glTF-2.0 metallic-roughness material), incl. verifying the G=roughness/B=metallic
  channel packing directly against the real EasyGL GLSL shader source.
- **Ch.22 Direct3D Backends** — a worked example quoting a real oracle scene file in full
  (`colored3d.scene`, 11 lines), tying its declarative flags directly to `BasicEffect`.
- **Ch.23 Canvas/ASCII Backends** — a worked un-premultiply example in real numbers, adapted
  from the actual per-pixel formula in `CanvasSpriteBatchBackend.cpp`.
- **Ch.24 DX3/free-direct Backend** — a direct, parallel worked example to Ch.17's
  SDL_RENDERER Wrap/Mirror gap (same 2-texel red/green setup; this backend gets it right).
  **This completes all of Part IV.**
- **Appendix A** — new section on `VertexBuffer`/`IndexBuffer`, the `Effect` base class +
  `EffectParameter`'s full surface, and `OcclusionQuery` — three classes used throughout
  Parts III-IV with no quick-reference entry until now.
- **Ch.7 Math** — a genuinely fresh gap found via header/test diff: `Curve`'s real
  `.xnb`/`.cnj` content-pipeline support, previously undocumented anywhere in the chapter,
  quoting a real `CnjCurveTests.cpp` fixture in full.
- **Ch.9 GraphicsDevice** — another fresh gap: `ExtractMatrices`, the internal free function
  (not in the header) that pulls World/View/Projection from the applied `Effect` at every
  draw-dispatch call site — ties Ch.13/15/21's effect chapters to this chapter's own draw
  dispatch. Found and fixed 6 pre-existing overfull-hboxes in the same section while there.
- **Ch.25 Input System** — checked, found already thoroughly covered from a very recent prior
  session (the very last commit before this session's own work began); no edit made.
- **Ch.26 Audio System** — two fresh bugs mined from `plan_audio20260717.md` Phase 14 (dated
  2026-07-17, not previously used as a source): a `SoundBank::GetCue()` cue-lifetime gap (a
  held-but-unplayed `Cue` could outlive its bank) and a `DynamicSoundEffectInstance` byte-
  accounting bug (a whole chunk popped for one byte of real playback), both with the real
  audit's own numbers worked through.
- **Ch.27 Media** — one fresh bug mined from `plan_media.md` Phase 16 Group B: `Song`'s real
  `TrackNumber` tag was parsed correctly but silently discarded one call-layer above, caught
  by a mutation-verified fixture using 4 distinct non-identical track numbers.
- **Ch.28 Devices and Sensors** — a fourth concurrency finding mined from `plan_devices.md`'s
  LIFE-001 (dated 2026-07-17): a genuine TSan-only-detectable race discovered *inside* an
  already-CLOSED two-phase Start/Stop fix, causing real heap corruption under an 8-thread
  stress test — the same "closed isn't proof" methodology point as Ch.18's EasyGL finding,
  independently rediscovered in a completely different subsystem.
- **Ch.29 GamerServices** — no dedicated plan doc exists; found via `plan_net.md` Phase 4
  Task 4.5 instead. Added a worked example on exactly which `Achievement` fields
  `GetAchievements()` populates for real (`Key`/`IsEarned`/`EarnedDateTime`) versus which stay
  at fixed defaults (`Name`/`Description`/`GamerScore`) because real XNA's own
  `AwardAchievement` carries no catalog metadata at all.
- **Ch.30 Networking** — mined `ENetBackend.cpp` directly (source, not a plan doc, for this
  one) for the pre-handshake send queue's real bound (64, oldest-evicted-first) and its
  internal `GetDroppedAppDataCount()` diagnostic counter — the chapter already described the
  mechanism qualitatively but not with these specifics.
- **Ch.31 Avatar** — mined `plan_net.md`'s Phase 15 (2026-07-18, GamerServices/Avatar work is
  tracked there, not in a dedicated Avatar plan doc) for two real lighting bugs: `DrawRealEXT`
  calling `EnableDefaultLighting()` *after* a caller's custom ambient (silently discarding
  it — verified against the real, currently-fixed source and its own explanatory comment),
  and a project-wide EasyGL formula bug (`EmissiveColor` double-multiplied by `DiffuseColor`)
  found via 3 failed rounds of avatar-ambient tuning, with real before/after pixel percentages.
- **Ch.32 Storage** — no plan doc; found by reading `StorageContainer.cpp` directly. A real,
  currently undocumented gap: `ResolvePath()` never guards against a `..`-climbing relative
  path, only an empty-string check exists — confirmed against both the header docs and test
  suite, neither of which treat it as a scoped decision. **This completes all of Part V.**
- **Ch.33-34 Sharp Runtime** — mined `sharp-runtime`'s own `NEXT.md` (dated 2026-07-14):
  Ch.33 corrected/extended a 2-type version-counter finding to project-wide (10 types) plus
  `OrderedDictionary::EnsureCapacity`'s own follow-up fix; Ch.34 added a third worked example
  from `audit.md`'s A-01–A-07 remediation round (distinct from the already-covered
  post-stabilization audit) — `TaskCompletionSource::TrySetResult`'s claim-then-publish race.
  Ch.35 checked, found already thorough, no edit made. **This completes Part VI.**
- **Ch.36 EasyGL Deep Dive** — mined `easy-gl`'s own `NEXT.md` for two real RAII additions
  added after this chapter's original pass: `ScopedDebugGroup` and `UniformCache` (with the
  real, undocumented "a failed lookup is memoized too" behavior, verified against the .cpp).
  **Note for future reference:** grepping LaTeX source for an escaped identifier like
  `result_u64` will miss it if the source has `result\_u64` — account for the backslash
  before concluding something isn't already covered.

**Every chapter above also had at least one genuine overfull-hbox, header/folio collision, or
API-accuracy defect found and fixed while reading the whole page** (not just the new
content) — this remains the single most common defect class in this whole project; see
"Reusable findings" below for the patterns that actually worked to fix them this time.

## A new, high-value technique discovered this session — use it for every remaining chapter

Parts V-IX (chapters 25-48) map onto CNA subsystems that mostly have their own dedicated
`plan_<subsystem>.md` file at the `cna` repo root (`plan_audio20260717.md`/`plan_audio.md`,
`plan_media.md`, `plan_devices.md`, `plan_net.md`, and so on — `ls
/rv/data/development/github.com/openeggbert/cna/plan_*.md` to see what exists for a given
chapter's subsystem). These files accumulate phases over many real sessions, each dated, and
**the book's own prior coverage of a chapter was very often written from an earlier phase,
before the plan file's own later phases existed.** The technique that worked well for Ch.26-28
this session:

1. Find the newest/most-recently-touched plan doc for the chapter's subsystem
   (`grep -o "2026-[0-9-]*" plan_X.md | sort -u | tail -5`, or just check the tail of the
   phase/section outline — `grep -n "^#\|^##" plan_X.md | tail -20`).
2. Read its most recent phase(s) for concrete, real, dated findings (a specific bug, a
   specific fix, ideally with real before/after numbers or a named test).
3. Grep the book chapter for whether that specific finding (method name, bug description) is
   already mentioned. If not, it is very likely a genuinely fresh gap, not something already
   covered under different wording — this was true every single time it was tried this
   session (3 for 3: Ch.26's two audio findings, Ch.27's TrackNumber finding, Ch.28's TSan
   finding).
4. Write it up the same way as every other worked example/finding in this book: grounded,
   specific, with the real mechanism and (where the source has them) real numbers.

This is meaningfully faster than the alternative (re-reading the whole chapter and the whole
relevant header hunting for anything unmentioned) and found genuinely substantial material
every time — including one especially strong example worth knowing about before starting
Parts V-IX: **a bug found and fixed inside a fix that was already marked CLOSED**, only by a
later real ThreadSanitizer run (Ch.28's LIFE-001 amendment). Don't skip a chapter's plan file
just because the chapter already looks thorough — Ch.26-28 all looked reasonably thorough
before this technique still found real, substantial, uncovered material in each one.

## Remaining depth-pass work

**Only task #41 remains: Parts V-IX, chapters 25-48.** Every other task (#24-40, covering all
of Parts I-IV plus Appendix A) is complete. Ch.25-28 are done this session (see above); 20
chapters remain (29-48), each still roughly 3-15 of a 30-70 page target. Continue
sequentially starting with **Ch.29 (GamerServices)**, using the technique above plus the same
build/render/verify loop used throughout this whole session (rebuild, check for
undefined/multiply-defined refs, render the chapter's own physical pages to PNG and read them,
fix any overfull-hbox or header/folio collision found along the way — PNG rendering remains
the only reliable check, not `grep -i overfull`). Check `TaskList` for the live, authoritative
status — task #41 is the only one still open.

## Reusable findings from this session, worth knowing before continuing

- **A non-floating `tabularx`/plain `tabular` that overflows the page width just runs text off
  the margin silently** — this happened repeatedly this session (Ch.1's new verification-scale
  table needed `tabularx` instead of `tabular`; several chapters had pre-existing long
  identifiers/paths overflow). The fix that actually works reliably, in order of preference
  tried this session:
  1. First try `\allowbreak{}` at natural boundaries (underscores, `::`, `/`) inside the long
     token. Sometimes needs 2–3 rounds of adding more break points before it actually resolves
     — don't assume one round fixed it; **always re-render the exact page at 150dpi+ and look**.
  2. If that doesn't work after 2 rounds, **restructure the sentence** so the long
     identifier(s) are split into multiple shorter `\texttt{}` tokens with ordinary prose
     between them (e.g. "has three constructors: X; a second form additionally taking Y; and Z"
     instead of one comma-separated run of three full signatures). This was the *only* thing
     that worked for a couple of the worst cases this session (Ch.8's `ContentManager`
     constructor list, Ch.24's blend-factor list) — don't keep chasing `\allowbreak` placement
     past two failed attempts, switch to restructuring instead.
- **`grep -i overfull main.log` remains unreliable as a check** — it was empty in every single
  build this session, even immediately before rendering a page to PNG and finding a real,
  visible overflow. Treat it as worthless for this project specifically; PNG rendering at
  100–150dpi and actually reading the page is the only check that has ever caught anything,
  all session.
- **Verify every real API call in a worked example against the actual header before writing
  it down, every time, even for "obvious" things.** This session caught a real mistake this
  way: a first draft of the `FpsCounterComponent` example (Ch.6) used
  `TimeSpan::operator+=`, which `sharp-runtime`'s `TimeSpan.hpp` does not declare (only
  `operator+`) — caught by grepping the header before commit, not after. Two similar
  self-authored mistakes were also caught and fixed in the *prior* session (a math error in a
  blend-formula claim, a forward-reference ordering bug) — this is a real, recurring risk
  category for this specific kind of writing (plausible-sounding C++ that doesn't actually
  compile against the real headers), not a one-off.
- **`GameComponentCollection::Add(IGameComponent*)` takes a raw, non-owning pointer** — any
  worked example registering a component needs to keep it alive itself (a plain member field
  outliving the collection), not a temporary or a forgotten `new`.
- **Two-level (and deeper) sibling dependencies exist in this ecosystem beyond what the
  Ecosystem Map chapter's own table shows** — `free-direct` depends on `free-api`. Worth
  checking whether any other sibling repo has its own further `add_subdirectory(../something)`
  the same way, next time Ch.2 or the repo-map appendix gets touched again.
- **A single overly-long line inside an `lstlisting` block can silently wrap character-by-
  character down the right margin instead of breaking at a sensible point** — found in Ch.14's
  first draft of a ternary-expression example (`device.setRasterizerStateProperty(cond ? a :
  b);` on one long line). `\allowbreak{}` does not apply inside `lstlisting` the way it does in
  running prose; the fix that actually works is restructuring the statement itself (here, into
  a plain `if`/`else`) so no single line is too long, not trying to force a break within the
  listing. Check every code block that has one conspicuously long line, not just prose
  paragraphs, when PNG-rendering a chapter.
- **A prose paragraph can genuinely be pre-existing and still be overfull** even in a chapter
  you are only adding to, not rewriting — Ch.14's SamplerState section had a real, pre-existing
  overfull-hbox (a long chain of slash-joined `\texttt{}` overload names) that had nothing to do
  with anything added this session. Read the whole rendered page, not just the new paragraphs,
  every time — this has now happened often enough across this project that it should be treated
  as the default expectation, not a surprise.
- **Guessing a plausible-sounding overload from prose description alone is a real, repeatable
  risk — always grep the actual header before finalizing a worked example.** Ch.11's first
  draft assumed a `RenderTargetBinding`-taking `SetRenderTarget` overload existed for
  single-target cube-face binding; the real header only has
  `SetRenderTarget(RenderTargetCube*, CubeMapFace)` directly (the `RenderTargetBinding` form is
  for the plural `SetRenderTargets(vector<...>&)` overload instead). Caught before commit by
  grepping `GraphicsDevice.hpp` directly — this is the same risk category flagged in the prior
  session's `TimeSpan::operator+=` mistake, confirmed recurring rather than a one-off.
- **A long trailing `//` comment on a code line inside `lstlisting` overflows exactly the same
  way a long prose identifier does** — found and fixed three separate times this session (Ch.14
  RasterizerState ternary, Ch.19 an identifier in prose, Ch.21 twice in one chapter, both times
  a trailing comment explaining a line of real call-site code). The fix is the same restructuring
  principle every time: pull the comment onto its own line **above** the code it explains
  instead of trailing it, or shorten it — never try to wrap a trailing comment onto a second
  `//`-prefixed line hanging off the same statement, which is what actually produces the
  character-by-character cascade down the margin.
- **Always re-verify a source claim against the real header/source when writing a worked
  example, even when adapting content from this book's own earlier, already-fixed prose** —
  Ch.16's `IEffectBackend` deep-dive and Ch.20's BGFX wrong-handle-cast diagnosis both required
  a fresh grep pass (not just trusting the one-sentence preview an earlier chapter had already
  given) to get the full, precise mechanism right before writing it up in depth.
- **A "still logged as open" claim in an older project doc can go stale just like anything
  else — check the actual current source before reproducing it as fact.** Ch.18's EasyGL depth
  pass found the highest-value example of this yet: `docs/d3d9-divergence-report.md` explicitly
  says two real bugs were "logged here, not fixed," but the current `EasyGLGraphicsBackend.cpp`
  carries explicit, named fix comments (Task 1111/1112) for both, naming the exact failing
  oracle scene by name. Treat any doc's "still open"/"not fixed" framing as a claim to verify
  against the current source before reproducing it, not as ground truth by default — this is
  the same discipline CLAUDE.md's Vol. I Ch.8 `.xnb`-reader example already established as the
  project's standard, now with a second, independently-found instance.
- **A `\description` list `\item[...]` label that combines two full method signatures (e.g.
  `\item[\texttt{void A(...)} / \texttt{void B(...)}]`) is a frequent, easy-to-miss overfull-hbox
  source** — bold item labels are visually wider than the same characters in body text, so a
  combined two-signature label overflows well before a similar-length body sentence would.
  Ch.9's depth pass found six of these in one section alone. The reliable fix is always the
  same: split into two separate `\item` entries, one method each, rather than trying to
  `\allowbreak{}` a label into submission — this was faster and more reliable every single time
  it was tried this session. When revisiting any `\begin{description}` block with combined
  `A / B` method-signature labels, check it proactively rather than waiting to find it by
  accident.
- **A chapter revisited across many past sessions (Ch.7, Ch.9 — both flagged in PLAN.md as
  already depth-passed multiple times) can still have a substantial number of undiscovered
  pre-existing overfull-hboxes** — six were found in one ~150-line span of Ch.9 alone,
  despite that chapter's own PLAN.md history describing it as thoroughly gone-over. Don't
  assume a heavily-worked chapter is layout-clean; render and check it the same as any other.

## Housekeeping reminders (unchanged from before, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log for `undefined` and
  `multiply defined`/`multiply-defined` every time — these two checks *are* reliable, unlike
  the `overfull` grep (see above).
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed in this
  environment as of this session — verify with `command -v latexmk` if in doubt, but do not
  expect to need to reinstall.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`) live at
  `/rv/data/development/github.com/openeggbert/<name>` in this environment — not `/workspace`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`), never assume printed page N is
  physical page N. A blank padding page immediately before a new Part's or chapter's
  right-hand start is normal book layout, not a rendering defect.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway — grep for `Chapter~[0-9]` in any chapter
  you touch as routine, not just when you happen to notice one.
- No task is currently blocked/`needs_human` — everything found so far has been resolvable by
  reading more source. If a genuine architectural ambiguity comes up (not just "which chapter
  to do next," which is explicitly not one), mark it clearly in this file and in `PLAN.md`'s
  session log, and move on to another chapter rather than stalling the whole session.
