# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-22)

**438 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings —
independently re-verified via a forced rebuild (`latexmk -g`) against a clean `git status`
immediately before this file was written.** Re-verify before trusting this in a future session;
use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain
`grep -i undefined`.

This was an unusually long, multi-batch session (author unavailable for many hours, explicit
"continue autonomously" instruction given partway through, repeated several times). Six full
batches landed in total (371 → 438 pages, +67), on top of the earlier SDL_GPU chapter insertion
and Ch.17/Ch.18 real-screenshot work:

- **Batch A** (10): Ch.10, 19, 20, 23, 32, 37, 40, 41, 43, 44, plus Appendix B.
- **Batch B** (8): Ch.8, 22, 30, 31, 35, 39, 46, 48.
- **Batch C** (6): Ch.2, 5, 12, 18, 20 (2nd pass), 23 (2nd pass).
- **Batch D** (6): Ch.11, 13, 33, 34, Appendix A, Appendix D.
- **Batch E** (6, most recent): Ch.6, 21, 24 (3rd pass), 25 (3rd pass), 28, 47.

Every touched file across all six batches was individually rendered to PNG and read directly
after its own batch's consolidated `make book` pass — not just log-checked. **Thirteen real
page-edge/box/running-header overflows were found and fixed across six batch-verification
passes, and not one of them produced a logged `Overfull \hbox` warning.**

Highlights from Batch E (the most recent work — chosen for breadth, favoring chapters not yet
touched this session over further passes on already-touched ones):

- **Ch.6 (Game Loop)**: the real five-tick `IsRunningSlowly` hysteresis in `Game::Tick()` (a
  single 50ms stutter never sets it — several consecutive lagging ticks are required, and it
  takes several good frames to clear), with **zero dedicated test coverage for the mechanism
  itself** (`GameTimeTests.cpp` only tests `GameTime`'s plain getters/setters). Also:
  `ResetElapsedTime()` is a silent no-op whenever `IsFixedTimeStep` is left at its default
  `true` — matches real XNA's documented behavior, but easy to call defensively and assume it
  did something.
- **Ch.21 (WebGPU)**: `IWebGPUCubeSamplable`, a real shared-interface fix for a bug where
  `EnvironmentMapEffect` silently fell back to a 1×1 white default whenever a `RenderTargetCube`
  (rather than an upload-only `TextureCube`) was bound as its environment map, because the old
  code cast to one hardcoded concrete type.
- **Ch.24 (Canvas/ASCII)**: the "separate backend, not a toggle" architectural decision,
  reproduced honestly including `plan_ascii.md`'s own hedged framing — the plan document itself
  flags the simpler toggle-on-`SDL_RENDERER` alternative as "worth revisiting," not a settled
  choice with the benefit of hindsight.
- **Ch.25 (DX3/free-direct)**: design-decision-4 (32bpp-only, no 8-bit palette path) shown to
  structurally sidestep two real, independently-documented `free-direct` gaps — the discarded
  `dwBPP` parameter and `BlitFrom`'s mixed-depth silent no-op — because a backend faithfully
  targeting XNA's own `SurfaceFormat` enum (which has no 8-bit indexed member) never triggers
  either one.
- **Ch.28 (Media)**: `MediaPlayer::Volume`/`IsMuted` are genuinely independent state (muting
  never overwrites the stored volume), and `MediaStateChanged`/`ActiveSongChanged` don't fire
  immediately — both are dispatched later, from `FrameworkDispatcher::Update()`, matching real
  XNA's own documented per-frame dispatch API.
- **Ch.47 (Project Practice)**: queried `sharp-runtime`'s real `plan.sqlite3` task-tracking
  database directly for the first time in this book — its two-table schema (`task`/`ticket`), a
  full real ticket quoted verbatim (including its `validation_command` field), and a genuinely
  new statistic: of 16,201 classified .NET BCL types/members, only 1,041 (6.4%) are actually
  `ported` — the honest denominator behind every "sharp-runtime implements X" claim this book
  makes.

## Fork dispatch in this environment — the fullest picture yet, read before dispatching more

Everything from prior notes still holds (forks keep working/committing past their assigned
task; commit messages can mismatch their actual diff; `latexmk` needs `-g` to force a rebuild;
always independently re-render before trusting any "clean" claim; after every batch, diff
`PLAN.md`'s claimed line count against `wc -l` on the real file). **Confirmed this session:** an
`Agent(subagent_type: "fork")` call can resolve three different ways, not two:

1. A genuine background task (the common case) — an async handle and a later `<task-notification>`.
2. An immediate `"Fork is not available inside a forked worker"` **error** — the dispatch may
   still launch in the true background regardless; check `git log` before assuming it failed.
3. **Synchronous inline execution in the current turn** — the calling session itself must
   complete the task directly, in-line, using its own tools; no separate agent is spawned. Once
   this happens once in a conversation, subsequent `Agent(fork)` calls reliably error with mode
   2 for the rest of that conversation.

Multiple agents independently discovering and fixing the *identical* overflow/stale-claim issue
via different concrete edits (that then converge, collide, or get bundled together by a git
race) happened repeatedly this session — always resolved cleanly by re-checking `git diff`/
`git show --stat` before committing rather than assuming your own in-progress edit is the only
one in flight. Dispatching 6-10 forks per batch and waiting for them to settle (1-5 hours of
real wall-clock time per batch, not fighting the extra unsupervised work) has now worked
cleanly across six consecutive batches — a proven, repeatable rhythm for this project.

## What is NOT yet done — the natural next body of work

Furthest-below-target as of this session's end (recompute from `PLAN.md`'s own table if this
list and PLAN.md ever disagree):

- Ch.23 Direct3D Backends — even after two passes this session, still the largest absolute page
  gap in the book (target 85, still well under half). Worth a dedicated multi-pass focus.
- Ch.18 EasyGL Backend, Ch.19 Vulkan Backend, Ch.10 SpriteBatch, Ch.17 SDL_Renderer Backend
  (all ~14-16% of target, none touched in Batch E specifically, though several got passes
  earlier in the session)
- Appendices C, E, F — untouched all session, all still comfortably under target
- Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
  sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
- Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
  capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering every touched page is the only reliable overflow check — full stop, no
  exceptions for what the log says.** Thirteen separate real overflows across this session's six
  verification passes produced zero logged `Overfull \hbox` warnings between them, across at
  least three distinct visual shapes: plain page-edge text (most common — often two long
  identifiers/class names landing consecutively at a line-end position), a `longtable` cell
  overlapping its neighbor column, and a `\section{}` title colliding with its own running
  header/folio.
- **A suspected fix must be pixel-verified, not assumed.** If a before/after PNG crop of the
  same region looks identical, the fix did not work. Bump `-r` to 250 and crop with PIL for a
  close look whenever a line looks like it might be touching a page/box edge.
- **After any batch, diff `PLAN.md`'s claimed line count against the real file's line count**
  (`wc -l`) for every touched chapter before trusting any "PDF-verified clean" label.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **`\allowbreak{}` cannot go inside a `\cnans{}`/`\cnaclass{}` argument** (would corrupt the
  index). If the identical term is indexed elsewhere in the same chapter via another
  `\cnans{}`/`\cnaclass{}` instance, it's safe to switch just the overflowing instance to a
  plain, `\allowbreak{}`-able `\texttt{}` — verify that precondition first.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_`/`.` boundaries — verify it actually changed the render, don't assume; (2)
  restructure the sentence into shorter independent clauses, or move the long token(s) off the
  line-end position entirely, when `\allowbreak{}` alone doesn't move the needle (needed far
  more often than `\allowbreak{}` alone succeeding, all session); (3) split a combined
  `\description` `\item[...]` label into two items; (4) restructure code itself inside
  `lstlisting`, including moving a trailing inline comment to its own line above the code (an
  inline trailing comment on a long code line can wrap catastrophically, one word per line,
  cascading off the right edge of the box); (5) `\section[short]{long}` for a running-header/
  folio collision — confirmed needed twice this session (Ch.12, Ch.23); (6) for a wide
  `longtable`, narrowing one column's `p{}` width while widening another, plus `\allowbreak{}`
  at `::`/`.` boundaries inside the widened column, can resolve a cell overlap without touching
  any cell's actual text content.
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
