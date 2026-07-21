# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Verification status: genuinely complete now — read this before trusting any earlier claim in this file's own git history

This session went through **three successive rounds of "verified clean"** before actually being
complete, each superseded by the next after a further pixel-level check found something the
prior round missed. If you're reading an old cached copy of this file or a mid-session commit
message, distrust any "PDF-verified clean" claim from this session that isn't the one below.

**Final, actually-complete state (confirmed by a full page-by-page render-and-read of every
single page touched this entire session, redone after every edit including the last one):**
`make book` (forced rebuild, `latexmk -g`) succeeds, **402 pages**, 0 undefined references, 0
duplicate labels, and every one of the ~24 chapters/appendices touched this session
(Ch.10/15/16/17/18/19/20/23/24/25/32/36/37/40/41/42/43/44/45, Appendices B/C/D/E/F, plus the
`tools/cna-screenshot-infra/` update) has been individually rendered to PNG and read directly at
least once after its own last edit. All corresponding `PLAN.md` rows say `PDF-verified clean`.

**Six real, log-invisible page-edge text overflows were found and fixed this session** —
treat this as a structural property of this defect class now, not a string of coincidences:
Appendix E (`SkinnedModelEXT` paragraph), Ch.45 (a `\cnans{}`-wrapped namespace token, a long
`.../Viewport.xml` path), Appendix B (a `TextureAddressMode::Wrap`/`Mirror` table-cell overlap),
Ch.37 (`easygl::detail::GenerationTracked`, two `test_resource_registry_*` test names), and
Ch.40 (`InstallEmscriptenContextLossCallbacks()`). **Not one of the six produced a logged
`Overfull \hbox` warning.** See "Reusable findings" below for the standing rule this proves.

## A real, extensive coordination pattern this project's use of parallel forks now needs standing awareness of

This session dispatched 10 parallel `Agent(subagent_type: "fork")` calls for a planned batch of
10 chapters/appendices, each explicitly told not to run `git`/`make book`. **Every one of them
did anyway** — matching this project's own standing `CLAUDE.md` instruction to commit/push per
chapter, which apparently overrides a narrower one-off instruction already in a fork's inherited
context. Several forks then kept going *well* past their assigned single chapter, unprompted:
fixing unrelated files, running their own build/verify passes, and — over the following roughly
two hours of this same session — autonomously working through nearly this entire file's own
"next candidates" list from an earlier draft (ten more chapters: Ch.10/19/20/23/32/37/40/41/43/
44, plus Appendix B), each as its own commit, entirely without further prompting from the
coordinating session. One fork became unreachable via `SendMessage` mid-session (`"No transcript
found"`) despite still visibly committing new work afterward. **Nothing was lost or corrupted**
— one shared working tree, ordinary linear git history throughout, every intermediate state
recoverable via `git reflog` — but coordinating multiple agents' access to one working tree and
one `make book`/verification pass required real, repeated, active effort this session, not a
one-time fix. Practical guidance for next time, now confirmed by direct experience:

1. **Expect forks to keep working past their assigned task and to commit/push on their own** —
   plan verification time accordingly. A fork's own final report is not evidence it has stopped.
2. **An immediate `"Fork is not available inside a forked worker"` error does not mean the
   dispatch failed** — the errored call can still complete in the true background; check `git
   log` for the expected commit before concluding otherwise. Separately, a fork call can also
   resolve into *synchronous inline execution in the parent's own turn* (framed as "you are a
   worker fork, execute this directive") rather than launching a background task at all — if
   this happens, just execute the directive directly rather than trying to re-dispatch it.
3. **Before trusting any consolidated `make book` + PNG-render pass as final, re-check `git
   status` is clean immediately before and after** — a mid-batch race from a still-active fork
   can make an otherwise-correct build transiently reflect uncommitted content from a different
   agent, which is exactly what happened once this session (caught by rebuilding a second time
   against a confirmed-clean tree and finding an identical page count/warning set either way —
   no actual harm, but only confirmed by re-checking, not assumed).
4. **Multiple agents editing the same `PLAN.md`/`NEXT.md` concurrently produces commits whose
   message names one chapter but whose diff includes another's** (`git add`/`git commit -a`
   scooping up a sibling agent's uncommitted work at the same moment) — cosmetically messy but
   not harmful; left as-is per this project's own never-rewrite-shared-history rule. Don't
   assume a commit's file list matches its message; check the actual diff if it matters.
5. **`latexmk` has repeatedly reported `"Nothing to do for 'main.tex'"` even immediately after a
   source file changed underneath it** (concurrent git operations don't always bump mtimes the
   way `latexmk`'s dependency tracking expects) — force a rebuild with `latexmk -pdf
   -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex` (`-g`) whenever you
   suspect staleness, rather than trusting the plain `make book` target.
6. If you genuinely need exclusive, uncontested access to the repo for a verification pass,
   message every still-active fork explicitly asking it to finish and stand down — but budget
   for that message not landing (a fork can become unreachable) and verify via `git log`/`git
   status` regardless of whether you get a reply.

## The book now has 49 chapters, not 48 — READ THIS BEFORE CITING A CHAPTER NUMBER

**2026-07-21:** Ch.22 (The SDL GPU Backend) was inserted into Part IV; every chapter from the
former Ch.22-48 was renumbered to Ch.23-49. If you cite a chapter number from memory or from an
old commit message, **it may be off by one** for anything that used to be 22 or higher — check
the real file list under `latex/book/chapters/` or grep `main.tex`'s `\input{}` order before
trusting a remembered number. `\label{ch:...}` values did **not** change (semantic, not
numeric), so every `\ref{}` in the book resolves correctly.

## Working-method change, still in effect — READ THIS

**2026-07-21, author decision, encoded in `CLAUDE.md`:** verification is batched, not
per-chapter. Write across roughly 8-10 chapters/appendices — committing and pushing each one
individually as always — without running `make book` or rendering PNG pages in between. Once
the batch is done, run one consolidated pass. Mark `PLAN.md` rows `pending batch verification`
while a batch is in flight; only relabel `PDF-verified clean` once that pass has actually run
**and every touched page has been individually pixel-checked** — this session proved, twice
over, that a partial render pass or a clean grep is not sufficient grounds for that label.

## Where things stand (end of session, 2026-07-21 into 2026-07-22)

This was an unusually long, eventful autonomous session (author unavailable for several hours,
explicit authorization to work independently, and — per the section above — an unusual amount
of unsupervised parallel-agent activity to coordinate around). Content landed in two overlapping
waves; treat them as one combined, now-fully-verified batch:

**Ch.15/24/25/36/42/45, Appendices C/D/E/F, plus Ch.16/17/18.** A real, historical `ShaderEffect`
3D-draw limitation and its fix (Ch.15); both Canvas/ASCII backends' 2D-only-by-design contract
(Ch.24); DX3's shadow-backbuffer `RenderTarget2D` reuse (Ch.25); `IDisposable`/exception-hierarchy
parity philosophy incl. `ReaderWriterLockSlim`'s own three-bug self-correction history (Ch.36);
the D3D9 oracle corpus traced fully end to end (Ch.42); a second full xna4-spec audit finding a
real, deliberate `Viewport::TitleSafeArea` divergence (Ch.45); 13 new glossary entries, two
newly-catalogued real repos, new NOXNA/quick-reference sections (App C/D/E/F); a stale Ch.16
SDL_GPU cross-reference fixed. **Plus a real, previously-untested capability confirmed: real
screenshots for Ch.17 (SDL_Renderer) and Ch.18 (EasyGL), captured under `Xvfb`** — this book's
own screenshot-feasibility notes had left this "plausible but not actually tried" since
2026-07-20; now confirmed and reproducible (see `tools/cna-screenshot-infra/README.md`,
`xvfb_screenshot_demo.cpp`, `xvfb-demo-cmake-registration.patch`). `cna`'s own working tree has
two reusable, ccache-enabled build directories now: `build-sdlrenderer/` and `build-easygl/`.

**Ch.10/19/20/23/32/37/40/41/43/44, Appendix B.** SpriteBatch's sort-deferred (not
draw-call-batched) flush timing (Ch.10); Vulkan's `CreateSwapchain()` UNORM-not-SRGB decision and
`PresentInterval` fallback chain (Ch.19); BGFX's free-list-backed render-target view-id pool
(Ch.20); D3D11's three-group (not two) resource-lifetime tracking, plus D3D12's off-screen-only
CTest coverage honestly stated (Ch.23); a worked `ComputeBoneTransformsEXT` example with three
real bugs (Ch.32); easy-gl's two-tier context-loss recovery, one tier real and used, one designed
but never adopted (Ch.37); a real WebGL context-loss code path plus a real unpinned-WebGL-version
link-flag gap in `cna_demo_2d`/`cna_demo_sound` (Ch.40); a real, currently-live NDK cross-compile
regression (`getrandom()` gated behind API 28, this project targets API 24) found by re-running a
command a prior pass had confirmed working (Ch.41); Migration Guide Step 7 build/runtime
troubleshooting tables (Ch.43); a full CNA-port feasibility analysis for Blupi, grounded in
`free-eggbert`'s own real `cna.md` line-count audit, incl. a real `CNetwork::Receive`
buffer-copy bug found by reading the reconstructed networking code (Ch.44); two real longtable
capability grids condensed from `docs/graphics-backend-feature-matrix.md`, including a
caught-and-flagged stale row in that source doc itself (Appendix B).

**Current build state**: forced rebuild (`latexmk -g`) succeeds, **402 pages**, both grep checks
clean, and — per the section at the top of this file — every single touched page across the
whole session has been individually PNG-rendered and read directly, not just log-checked.

## What is NOT yet done — the natural next body of work

1. Furthest-below-target as of this session's end (recompute from `PLAN.md`'s own table if this
   list and PLAN.md ever disagree): Ch.23 Direct3D (~13 of ~85, still the largest gap even after
   this session's addition), Ch.41 Android/NDK (~7 of ~40), Ch.31 Networking and Ch.35 Sharp
   Runtime Namespaces (~9 of ~70 each), Ch.20 BGFX (~10 of ~55), Ch.10 SpriteBatch (~9 of ~55).
2. Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
   sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
3. Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
   capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).
4. If dispatching parallel forks again: read the coordination-pattern section above first, and
   budget real time for verification/coordination overhead, not just writing time.

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering every touched page is the only reliable overflow check — full stop, no
  exceptions for what the log says, and no exception for "I already checked once."** Six
  separate real overflows this session produced zero logged `Overfull \hbox` warnings between
  them. A first render pass can also legitimately miss one (wrong page picked, resolution too
  low, or a fix that looked plausible but didn't actually change the render) — a defect found
  and reported as fixed still needs re-rendering after the fix, not just re-reading the log.
- **A suspected fix must be pixel-verified, not assumed from a clean build log or from a
  previous agent's commit message.** If a before/after PNG crop of the same region looks
  identical, the fix did not work — this happened at least twice this session.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **`\checkmark` and other amssymb/amsfonts-only commands are undefined in this project's
  preamble** (no `amssymb` package loaded) — use plain text (`OK`, `X`, etc.) for status symbols
  in tables; check `latex/common/preamble.tex`'s own `\usepackage` list before assuming an
  unfamiliar LaTeX command is available.
- **`\allowbreak{}` cannot go inside a `\cnans{}`/`\cnaclass{}` argument** (would corrupt the
  index). If a `\cnans{}`/`\cnaclass{}`-wrapped long identifier is the thing overflowing and the
  identical term is indexed elsewhere in the same chapter via another `\cnans{}`/`\cnaclass{}`
  instance, it's safe to switch just the overflowing instance to a plain, `\allowbreak{}`-able
  `\texttt{}` — the index entry survives via the other instance. Verify that precondition first.
- **Overflow-fix technique, in order of what actually worked this session:** (1) `\allowbreak{}`
  at camelCase/`::`/`_`/`.` boundaries — verify it actually changed the render, don't assume;
  (2) restructure the sentence into shorter independent clauses when `\allowbreak{}` alone
  doesn't move the needle (this was needed, not just the allowbreak, for at least three of the
  six overflows found this session); (3) split a combined `\description` `\item[...]` label into
  two items; (4) restructure code itself inside `lstlisting`; (5) `\section[short]{long}` for a
  running-header/folio collision; (6) for a wide multi-column `longtable`, narrowing one column's
  `p{}` width while widening another can resolve an overflow without touching any cell's text.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`.
- **Before asserting a specific API call in a worked example, grep the real header for it.**

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. If you suspect staleness, use
  `latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex` from
  inside `latex/book/` to force a full rebuild (see the coordination-pattern section above for
  why the plain target can silently skip a rebuild it shouldn't).
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed.
  `xvfb`/`libgl1-mesa-dri`/`ccache` are all installed too — confirmed working this session.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`,
  `sprite-utils`, `mobile-eggbert-libgdx`) live at
  `/rv/data/development/github.com/openeggbert/<name>` in this environment — not `/workspace`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman numerals)
  — search by content (`pdftotext`), never assume printed page N is physical page N.
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
