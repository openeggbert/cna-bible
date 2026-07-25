# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (updated 2026-07-25)

**454 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings —
independently re-verified via a forced rebuild (`latexmk -g`) after the latest documentation
batch.** Re-verify before trusting this in a future session;
use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain
`grep -i undefined`.

The 2026-07-24 continuation completed and pixel-verified a focused four-file batch:

- **Ch.23 (Direct3D)** now distinguishes the real two-slot fence/allocator reuse contract from
  a claim that every path is non-blocking: its ordinary clear/draw and present-transition
  helpers deliberately wait synchronously. It also records the fixed no-reclamation descriptor
  heaps as per-device CNA engineering budgets, not Direct3D 12 resource limits.
- **Ch.17 (SDL_Renderer)** documents the precise 2D/3D execution boundary: vertex declarations,
  stock-effect construction/application and state assignment work as data operations, while a
  3D draw (and buffer construction) is the intentional runtime boundary.
- **Ch.35 (Sharp Runtime)** documents `MemoryStream`'s post-close split: normal stream
  operations reject use, while `ToArray()` and `GetBuffer()` retain deliberate extraction
  access, including independent-copy versus live-buffer lifetime.
- **Appendix C** gained four alphabetized source-grounded glossary entries for the above
  D3D12, MemoryStream and vertex-declaration terms.

Validation for this batch: forced `latexmk -g` succeeded; the targeted undefined-reference and
duplicate-label greps were empty; all affected physical PDF pages were rendered to PNG and read
directly (Ch.17: 179--186; Ch.23: 225--234; Ch.35: 326--334; Appendix C: 429--432). All four
PLAN rows are now honestly marked **PDF-verified clean**. The four content commits are already
pushed to `develop`; the continuity update is also committed and pushed as `87fb144`.

**New in-progress work, not yet verified:** Appendix E has a source-verified fourth pass on
`SkinnedPbrEffect` and its `AnimationPlayer`/`SkinningData` relation; Appendix F has a matching
source-verified `MemoryStream` quick-reference entry. Both compile and render cleanly in a
minimal 11-page document that includes the two real appendix sources; that check exposed and
then confirmed the fix for a long-type right-edge overflow in Appendix E. A full-book rebuild is
still pending because this environment terminated each fresh full-document compiler process
before it reached the end of the 454-page document after generated auxiliaries were cleared. Do
not claim a new full-book page count or clean-reference state until that rebuild finishes. The
last fully verified full-book baseline remains commit `87fb144` (454 pages).

**Later continuation, also isolated-verified:** Ch.23 gained a ninth, source-grounded D3D11
verification-ladder subsection. Its minimal document compiled successfully and the affected page
was rendered and read after a right-edge audit; it is therefore marked isolated LaTeX/PDF clean,
not full-book clean, until the complete rebuild can run to completion.

Ch.35 then gained an eighth pass documenting the real, deliberate `TaskT<TResult>::ContinueWith`
gap: non-generic `Task` continuation machinery is live and tested, but generic tasks have only
the synchronization needed by `WhenAny` and no callback list or public continuation method. Its
minimal chapter document compiles cleanly; the full-book rebuild remains the outstanding check.

**Latest isolated continuation:** Ch.21 (WebGPU) was audited against the live WebGPU plan,
backend code, CMake test registration, and its focused test sources. The chapter now corrects
three stale limitations: arbitrary plain-texture backend readback is real and has a three-case
discriminating test; 3D culling is pixel-verified; and scissor/viewport are actual dynamic
render-pass state (including the necessary logical-to-physical viewport clamp). It retains the
real open limits: MRT, stencil operations, complete blend mapping, wireframe, custom effects,
compressed upload, browser scope, and the `RenderTargetCube` mip/MSAA cuts. The minimal Ch.21
document compiled and its changed physical pages were rendered and inspected cleanly. Its PLAN
row is therefore **isolated LaTeX/PDF-verified clean; full-book rebuild pending**, not full-book
clean.

**Then Ch.20 (BGFX) received a source-grounded seventh pass.** It now covers Task 914's real
`Texture3D`/`TextureCube` GPU readback design: copy the requested region into a short-lived
blit/readback texture, wait for bgfx's asynchronous returned frame, then destroy that transfer
resource. The same work made true 3D/cube mip allocation testable and is covered by four shared
round-trip/mip tests. The new page compiled and rendered cleanly. The isolated whole chapter
still reports pre-existing layout warnings in unchanged material, so its PLAN row says exactly
that; full-book validation remains pending.

**Latest continuation: Ch.34 (Sharp Runtime Overview) now distinguishes a real local quality
gate from absent hosted CI.** It documents `scripts/local_ci_check.sh`'s strict configure/build/
full-test behavior, explains why no GitHub Actions configuration was added (an explicitly
declined external-resource decision), and records a source conflict: README describes earlier
MinGW/Emscripten library builds while the newer continuation note calls both platforms
unverified. The book therefore treats the former as historical evidence, not a current full-suite
claim. The new page compiled and rendered cleanly; existing isolated warnings in unchanged Ch.34
material remain recorded in the PLAN row. Full-book rebuild is still pending.

**Latest continuation: Ch.22 (SDL_GPU) now has a source-grounded lifetime proof, not just a
description of the fix.** The live CMake list contains 21 real `SdlGpu` CTest registrations
(not the chapter's stale 20). Its new `RenderTargetLifetime` regression creates an 8x8 local
render target, clears it red, queues a SpriteBatch copy into a persistent 16x16 target, and
destroys the local wrapper before `Present()`. The first frame reads the destination centre back
as red; a further 119 frames repeat the lifecycle to ensure deferred releases drain. The chapter
now explains both state ownership (`shared_ptr` survives queued work) and raw-handle release only
after a successful command-buffer submit. A minimal Ch.22 document was compiled twice and its
new physical pages 3--4 were rendered and inspected cleanly. The isolated document retains five
pre-existing overfull warnings elsewhere in Ch.22; none comes from the new subsection. Full-book
regeneration remains pending regardless.

**Ch.22 then gained its present-timing lifecycle rule.** `GraphicsDeviceManager` defaults VSync
on, but all 22 local SDL_GPU examples/diagnostics set its public property false before
`Game::DoInitialize()` to prevent roughly one-second virtual-display frames. A formerly direct
private `SetSwapInterval(0)` workaround was correctly overwritten by `GraphicsDevice::Reset`
once its missing public-interval forwarding was fixed. The chapter now documents this ordering,
SDL_GPU's Immediate-then-Mailbox fallback for interval zero, and the fact that positive intervals
(including XNA's `PresentInterval::Two`) select VSync. Its isolated document compiled and
rendered pages 3--4 cleanly. A following layout pass resolved all five formerly pre-existing
Ch.22 overfull boxes; the entire six-page isolated chapter compiled without an overfull warning
and was rendered as a contact sheet for inspection. Full-book regeneration is still pending.

**Newest Ch.22 addition:** the chapter now distinguishes a null acquired swapchain texture
(documented non-error, skip the minimized-window frame) from a false hard-acquisition result
(submit the required command buffer, throw, and retain `framePending_`). The real recovery test
unclaims its SDL window on frame 10, observes the throw, reclaims it, presents the original queued
frame, then renders 30 further frames. The new section was isolated-compiled with zero overfull
warnings and its page 5 was rendered and inspected. The later PLAN matrix updates record the
then-current line count; full-book regeneration remains pending.

**Newest validation continuity pass in Ch.22:** the debug-build SDL_GPU validation toggle now
documents two concrete fixes it exposed: MSAA cannot use a six-layer 2D-array attachment, and
generated mipmaps require `SAMPLER | COLOR_TARGET` usage. It also points back to the still-open
Texture3D depth-mipmap issue rather than treating validation as a completed binary state. The
isolated chapter still compiles with zero overfull warnings; the added material on physical page
4 was rendered and inspected. The later PLAN matrix updates record the then-current line count.

**Newest Ch.22 correction:** the former wording called swapchain readback an unresolved segfault.
The live SDL_GPU contract proves instead that acquired swapchain textures are write-only. The
chapter now identifies the only viable `GetBackBufferData` design (always render into and read a
self-owned proxy, then blit to the swapchain) and records why it remains deliberately unchosen:
its extra texture and blit would cost every frame. The corrected page 6 was rendered and inspected
after a zero-overfull isolated compile. The chapter is 354 lines, and the PLAN matrix records
that current count.

**Latest Ch.22 audit:** custom ShaderEffect support is real but narrower than generic GLSL
portability. The live CnjEffect fixture uses GLSL ES 3.00 with loose uniforms and unqualified
stage I/O, which fails under SDL_GPU; the passing dedicated regression instead uses version 450,
explicit locations, fixed set/binding spaces, and named uniform blocks. It pixel-verifies an
effect-specific tint and a no-effect white control. The initial 389-line chapter compiled twice as an
eight-page isolated PDF with zero overfull boxes; the new material was rendered and inspected.
The fixture remains an intentional, separately-scoped compatibility gap rather than a claim
that custom effects are unsupported, and is now named consistently as the fourth item in the
chapter's closing open-limits list.

**Ch.22 cache follow-up:** queued draws snapshot their blend/cull/fill/stencil/depth state, and
pipeline lookup conditionally hashes only state dimensions which actually affect descriptors.
Stencil reference is correctly dynamic per draw; scissor is deliberately live once per render
pass. The source audit also confirmed the remaining RasterizerState depth-bias gap: its float
values are captured but not applied, because SDL_GPU has no dynamic depth-bias call and CNA does
not yet put them in a pipeline key. The chapter now names this as its fifth open limitation. The
422-line, eight-page isolated PDF compiled twice with zero overfull boxes; the cache section was
rendered and inspected.

**Ch.22 sampler follow-up:** the sampler audit confirms that point/linear, mipmap mode,
Wrap/Clamp/Mirror, and dual-texture slots have pixel proofs, while MaxAnisotropy only reaches an
internal slot field. Queued commands and sampler cache creation omit it, so no SDL_GPU sampler
actually enables anisotropy. It is now the chapter's sixth open limitation. The 432-line
nine-page isolated PDF compiled twice with zero overfull boxes; the changed page was rendered
and inspected.

**Latest continuation: Ch.25 (DX3/free-direct) received a source-grounded fifth pass.** Its
fixed-output letterbox limitation does not make input mapping ambiguous: the backend's real
`TransformWindowToLogical()` and inverse query the live SDL window, recompute
`min(physical/logical)` scale plus centered offsets, and correctly map through the bars without
reaching into free-direct's private renderer. The dedicated `Dx3_LogicalTransform` test checks
round trips, geometric centering, equal horizontal/vertical scale, and the fit-largest formula
against whatever physical size the environment actually provides. The 251-line version of the chapter
compiled twice as a minimal five-page PDF; its new page was rendered and inspected, and all seven
pre-existing isolated-Ch.25 `Overfull \hbox` warnings were resolved. This is isolated
LaTeX/PDF verification only; a fresh full-book rebuild remains pending for the same environment
constraint recorded above.

**Ch.25 follow-up:** the same source audit then documented the still-open virtual-resolution
resize defect. After the first present, a resolution change rebuilds CNA's primary/shadow
surfaces but free-direct retains its already-configured logical-presentation rectangle. Output
can therefore use the old scale while CNA's bidirectional input transform recomputes against the
new logical size. The 264-line chapter again compiled twice with zero overfull boxes; pages 3--4
were rendered and inspected. This is a free-direct-side fix, not a safe unilateral CNA change.

This was an unusually long, multi-batch session (author unavailable for many hours, explicit
"continue autonomously" instruction given partway through, repeated several times). Seven full
batches landed in total (371 → 452 pages, +81), on top of the earlier SDL_GPU chapter insertion
and Ch.17/Ch.18 real-screenshot work:

- **Batch A** (10): Ch.10, 19, 20, 23, 32, 37, 40, 41, 43, 44, plus Appendix B.
- **Batch B** (8): Ch.8, 22, 30, 31, 35, 39, 46, 48.
- **Batch C** (6): Ch.2, 5, 12, 18, 20 (2nd pass), 23 (2nd pass).
- **Batch D** (6): Ch.11, 13, 33, 34, Appendix A, Appendix D.
- **Batch E** (6): Ch.6, 21, 24 (3rd pass), 25 (3rd pass), 28, 47.
- **Batch F** (4, executed directly by the coordinating session — see below): Ch.18 (2nd pass),
  19 (2nd pass), 31 (2nd pass), 10 (2nd pass).

Every touched file across all batches was individually rendered to PNG and read directly after
its own batch's consolidated `make book` pass. **This session found and fixed fourteen real
defects across seven verification passes: thirteen page-edge/box/running-header overflows, none
of which produced a logged `Overfull \hbox` warning, plus one genuinely fatal build break** (raw
multi-byte UTF-8 bytes embedded directly inside an `lstlisting` block in Ch.35 aborted `pdflatex`
outright — see the dedicated section below, a new defect class for this session).

Highlights from Batch F (the most recent work — all four items executed directly rather than via
background fork, see "Fork dispatch" section below):

- **Ch.18 (EasyGL)**: corrected an earlier pass's own overstated claim — `VertexBuffer`/
  `IndexBuffer::GetData` are not "unimplemented"; both work via a real CPU-shadow cache (Task
  930), faithful to real XNA's own no-GPU-writeback contract for these types. The genuine
  surviving gap is narrower: the `NOXNA` `SetDataRaw()` custom-vertex-layout path doesn't
  populate the shadow, and `GetData` has no untyped counterpart to read one back with.
- **Ch.19 (Vulkan)**: a real, hittable resource ceiling — `Texture2D` and `RenderTarget2D`
  share one 512-descriptor-set pool (`MaxDescriptorSets`), throwing `std::runtime_error` on a
  513th simultaneously-live instance. A real budget of concurrently-undisposed resources
  (`Dispose()` frees the slot), not a lifetime total, and not shared with EasyGL/BGFX.
- **Ch.31 (Networking)**: expanded the flagged-but-unresolved `NetworkSession::BeginCreate`
  leak into a fuller, honestly-scoped account. Found a genuine design surprise while tracing
  it: `activeAction_` is a class-`static` member, not per-instance — only one `Begin*`/`End*`
  action may be in flight *process-wide*, across every `NetworkSession`. The leak itself is
  left honestly unresolved (this project's own audit trail has two not-fully-reconciled
  accounts of it), not over-claimed with a root cause this pass didn't actually verify.
- **Ch.10 (SpriteBatch)**: a real, previously-undocumented exception-type gap — nested
  `Begin()`/premature `End()` throws plain `std::runtime_error`, not real XNA's
  `InvalidOperationException`, even though `System::InvalidOperationException` exists in this
  codebase and is used faithfully elsewhere. A typed catch clause around `SpriteBatch` usage
  never fires; a generic `catch (const std::exception&)` still does.

## A genuinely fatal build break this session — a new defect class, read this first

Every prior defect class this session (thirteen of them) was a page-layout overflow — the build
still succeeded, just with corrupted-looking pages. This one was different: **raw multi-byte
UTF-8 characters (a Euro sign, two replacement-character glyphs) embedded directly inside code
comments inside an `lstlisting` block caused `pdflatex` to abort outright with "Invalid UTF-8
byte sequence" — no PDF produced at all.** The failure signature was actively misleading:
`latexmk`'s own output showed what looked like ordinary "undefined reference" warnings, because
the build never got far enough to resolve any labels at all. Caught only by actually running the
consolidated verification pass and noticing the build itself had failed, not by trusting any
fork's own "committed and pushed" report. **Lesson: never embed a literal non-ASCII byte sequence
inside an `lstlisting` block, even inside a comment** — describe the character in plain ASCII
(e.g. "EURO SIGN", "U+FFFD") instead. `\texttt{}` and ordinary prose handle UTF-8 fine via the
document's font encoding; `lstlisting`'s own listings-package font handling does not.

## Fork dispatch in this environment — the fullest picture yet, read before dispatching more

Everything from prior notes still holds (forks keep working/committing past their assigned
task; commit messages can mismatch their actual diff; `latexmk` needs `-g` to force a rebuild;
always independently re-render before trusting any "clean" claim; after every batch, diff
`PLAN.md`'s claimed line count against `wc -l` on the real file). **Confirmed and reinforced
this session:** an `Agent(subagent_type: "fork")` call can resolve three different ways:

1. A genuine background task (the common case) — an async handle and a later `<task-notification>`.
2. An immediate `"Fork is not available inside a forked worker"` **error** — the dispatch may
   still launch in the true background regardless; check `git log` before assuming it failed.
3. **Synchronous inline execution in the current turn** — the calling session itself must
   complete the task directly, in-line, using its own tools; no separate agent is spawned.
   **Once this happens once in a conversation, it reliably happens for every subsequent
   `Agent(fork)` call too** — confirmed this session across four consecutive dispatch attempts,
   not just the originally-observed single instance. Don't keep re-attempting dispatch after
   the first synchronous-execution response; just execute the remaining batch items yourself,
   sequentially, in the same turn, exactly as this session did for Batch F.

Multiple agents independently discovering and fixing the *identical* overflow/stale-claim issue
via different concrete edits happened repeatedly across all seven batches — always resolved
cleanly by re-checking `git diff`/`git show --stat` before committing rather than assuming your
own in-progress edit is the only one in flight.

## What is NOT yet done — the natural next body of work

Furthest-below-target as of this session's end (recompute from `PLAN.md`'s own table if this
list and PLAN.md ever disagree):

- Ch.23 Direct3D Backends remains the largest absolute page gap (about 17 of 85 pages), despite
  a now-completed eighth source-driven pass. Continue there if selecting a body chapter.
- Ch.17 SDL_Renderer (about 13 of 55) and Ch.35 Sharp Runtime Namespaces (about 17 of 70) have
  each received a seventh real depth pass and are verified clean, but remain substantially below
  their targets.
- Appendices E and F remain at about 5 of 20 and 5 of 25 pages. Appendix C is now about 6 of
  15 and was just verified; these appendices are good independent next tasks.
- Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
  sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
- Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
  capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering every touched page is the only reliable overflow check — full stop, no
  exceptions for what the log says.** Thirteen separate real overflows across this session
  produced zero logged `Overfull \hbox` warnings between them.
- **A `make book` that succeeds is not the only failure mode to check for — a fatal build
  break can also silently masquerade as unrelated "undefined reference" warnings** if the
  build aborted before resolving labels. If the warning set looks wrong or the page count looks
  suspiciously low/absent, check the log for an actual `pdflatex` abort, not just the two
  standard grep patterns.
- **A suspected fix must be pixel-verified, not assumed.** If a before/after PNG crop of the
  same region looks identical, the fix did not work. Bump `-r` to 250 and crop with PIL for a
  close look whenever a line looks like it might be touching a page/box edge.
- **After any batch, diff `PLAN.md`'s claimed line count against the real file's line count**
  (`wc -l`) for every touched chapter before trusting any "PDF-verified clean" label.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **Never embed a literal non-ASCII byte sequence inside an `lstlisting` block, even inside a
  comment** — it can abort the entire build. Describe the character in plain ASCII instead.
- **`\allowbreak{}` cannot go inside a `\cnans{}`/`\cnaclass{}` argument** (would corrupt the
  index). If the identical term is indexed elsewhere in the same chapter via another
  `\cnans{}`/`\cnaclass{}` instance, it's safe to switch just the overflowing instance to a
  plain, `\allowbreak{}`-able `\texttt{}` — verify that precondition first.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_`/`.` boundaries — verify it actually changed the render, don't assume; (2)
  restructure the sentence into shorter independent clauses, or move the long token(s) off the
  line-end position entirely, when `\allowbreak{}` alone doesn't move the needle; (3) split a
  combined `\description` `\item[...]` label into two items; (4) restructure code itself inside
  `lstlisting`, including moving a trailing inline comment to its own line above the code; (5)
  `\section[short]{long}` for a running-header/folio collision — confirmed needed four times
  this session (Ch.12, Ch.17, Ch.19, Ch.23); (6) for a wide `longtable`, narrowing one column's
  `p{}` width while widening another can resolve a cell overlap without touching cell text.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`.
- **`\checkmark` and other amssymb/amsfonts-only commands are undefined** in this project's
  preamble — use plain text (`OK`, `X`, etc.) for status symbols.
- **Before asserting a specific API call in a worked example, grep the real header for it.**

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. If you suspect staleness (very likely
  after any multi-agent batch — see above), force with `latexmk -pdf -interaction=nonstopmode
  -halt-on-error -file-line-error -g main.tex` from inside `latex/book/`.
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended`/`xvfb`/
  `libgl1-mesa-dri`/`ccache` are all installed and confirmed working.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`,
  `sprite-utils`, `mobile-eggbert-libgdx`) live at
  `/rv/data/development/github.com/openeggbert/<name>` in this environment — not `/workspace`.
  `cna`'s own working tree has two reusable, ccache-enabled build directories:
  `build-sdlrenderer/` and `build-easygl/` (see `tools/cna-screenshot-infra/README.md`).
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext`), never assume printed page N is physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Run the project's spacing-fix regex on every touched file, even during the writing phase of a
  batch (cheap, local, no build needed):
  `python3 -c "import re; p='PATH'; t=open(p).read(); n=re.sub(r'\}/(\\\\texttt\{|\\\\cnaclass\{)', r'} / \1', t); open(p,'w').write(n) if n!=t else None"`
- No task is currently blocked/`needs_human`, aside from the long-standing DXVK/`D3DCAPS9`
  authenticity item (Ch.39/45) which genuinely needs real Windows hardware to close and is
  already tracked as such. If a genuine new architectural ambiguity comes up, mark it clearly
  here and in `PLAN.md`'s session log, and continue with other independent work rather than
  stalling.
