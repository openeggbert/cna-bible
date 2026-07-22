# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-22)

**424 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings —
independently re-verified via a forced rebuild (`latexmk -g`) against a clean `git status`
immediately before this file was written.** Re-verify before trusting this in a future session;
use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain
`grep -i undefined`.

This was an unusually long, multi-batch session (author unavailable for many hours, explicit
"continue autonomously" instruction given partway through). Four batches landed in total, on
top of the earlier SDL_GPU chapter insertion and Ch.17/Ch.18 real-screenshot work:

- **Batch A** (10): Ch.10, 19, 20, 23, 32, 37, 40, 41, 43, 44, plus Appendix B.
- **Batch B** (8): Ch.8, 22, 30, 31, 35, 39, 46, 48.
- **Batch C/D** (6, dispatched together and landed as one verification wave): Ch.2, 5, 12, 18,
  20 (a second pass), 23 (a second pass).

Every touched file across all four batches was individually rendered to PNG and read directly
after its own batch's consolidated `make book` pass — not just log-checked. **Twelve real
page-edge/box/running-header overflows were found and fixed across the whole session, and not
one of them produced a logged `Overfull \hbox` warning.** This is now an extremely
well-established structural property of this defect class (12-for-12 silent), not a coincidence
— see "Reusable findings" below. Two NEW overflow sub-classes were found this session, beyond
plain page-edge text: a `longtable` cell overlapping its neighbor column (Appendix B), and a
`\section{...}` title long enough to collide with its own running header/folio (Ch.12, Ch.23) —
both fixed with `\section[short]{long}`.

Highlights from the last batch (Ch.2/5/12/18/20/23):

- **Ch.2 (Ecosystem Map)**: found a live instance of this book's own recurring "stale snapshot,
  live source disagrees" pattern in a *sibling repo* rather than in CNA itself — easy-gl's own
  `MIGRATION.md` frames nine already-shipped API changes as "planned for the next release."
- **Ch.5 (First Game)**: a fourth worked program (sprite-vs-sprite collision via
  `Rectangle::Intersects`), plus a real touching-is-not-overlapping edge case verified against
  `RectangleTests.cpp`.
- **Ch.12 (Models and Meshes)**: `Model`'s hand-build constructor gains a real, previously-
  undocumented `rootBoneIndex` parameter matching FNA's own `ModelReader` behavior (any bone can
  be the root, not just index 0), with a real sabotage-and-revert check confirming the new
  regression tests actually exercise what they claim to.
- **Ch.18 (EasyGL)**: a real self-correction — an earlier pass of this same chapter claimed
  two-sided stencil's shared mask was a bug; re-checking `xna4-spec`'s own `DepthStencilState.xml`
  shows real XNA never had a per-face stencil *mask* API to begin with, so reusing one mask for
  both faces is the only behavior consistent with the real spec, not a shortcut.
- **Ch.20 (BGFX), second pass**: `DrawInstancedPrimitivesEx` is a real, fully-wired ~70-line
  instancing implementation with **no dedicated test of its own**, unlike D3D9/EasyGL/Vulkan/
  WebGPU which each have one — plus two real silent-no-draw failure paths (missing
  `InstanceFrequency` binding; insufficient `bgfx::getAvailInstanceDataBuffer()` capacity), both
  indistinguishable from the caller's side.
- **Ch.23 (Direct3D), second pass**: `PresentationParameters::HeadlessEXT`, a real NOXNA
  property that let three previously-architecturally-stuck D3D12 tests join the routine
  (non-Proton) `ctest` suite, plus four real bugs (`SetSamplerFilter`/`SetSamplerAddressMode`
  ignored, render targets never binding a depth/stencil view, six `Clear*` combo variants
  throwing, `SetDepthTestEnabled`/`SetDepthWriteEnabled`/`SetBlendEnabled` crashing outright)
  that a genuinely new `GraphicsDevice`-driven caller immediately found.

## Fork dispatch in this environment — the fullest picture yet, read before dispatching more

Everything from prior sessions' notes still holds (forks keep working/committing past their
assigned task; commit messages can mismatch their actual diff; `latexmk` needs `-g` to force a
rebuild; always independently re-render before trusting any "clean" claim). **New this
session:** an `Agent(subagent_type: "fork")` call can resolve in three different ways, not two:

1. A genuine background task (the common case) — you get an async handle and a later
   `<task-notification>`.
2. An immediate `"Fork is not available inside a forked worker"` **error** — but the dispatch
   may still have launched in the true background regardless; check `git log` before assuming
   it failed.
3. **Synchronous inline execution in the current turn** — the tool result is a `<fork-boilerplate>`
   block telling you "you are a worker fork, execute this directive directly," and you (the
   calling session) must complete the task yourself, in-line, right now, using your own tools —
   no separate agent is spawned at all. Once this has happened once in a conversation, every
   subsequent `Agent(fork)` call in that same conversation reliably errors with "Fork is not
   available inside a forked worker" (mode 2 above) — i.e., a session that has been asked to
   act as a worker fork once seemingly cannot dispatch further nested forks of its own for the
   rest of that conversation. If you hit this, stop trying to dispatch and just execute the
   remaining batch items yourself, sequentially, in the current turn.

This session hit real, convergent multi-agent collisions on the exact same fixes multiple
times (independently discovering and fixing the identical Ch.2/Ch.20/Ch.12/Ch.18/Ch.23
overflows via different concrete edits that happened to converge) — always resolved cleanly by
re-checking `git diff`/`git show --stat` before committing rather than assuming your own
in-progress edit was the only one in flight.

## What is NOT yet done — the natural next body of work

Furthest-below-target as of this session's end (recompute from `PLAN.md`'s own table if this
list and PLAN.md ever disagree):

- Ch.23 Direct3D Backends — even after two passes this session, still the largest absolute page
  gap in the book (target 85, nowhere close yet). Worth a dedicated multi-pass focus.
- Ch.31 Networking, Ch.35 Sharp Runtime Namespaces (~11 of ~70 each)
- Appendices A/D/E/F — all still comfortably under target, none touched this session
- Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
  sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
- Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
  capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering every touched page is the only reliable overflow check — full stop, no
  exceptions for what the log says.** Twelve separate real overflows across this session
  produced zero logged `Overfull \hbox` warnings between them, across at least three distinct
  visual shapes: plain page-edge text, a `longtable` cell overlapping its neighbor column, and
  a `\section{}` title colliding with its own running header/folio.
- **A suspected fix must be pixel-verified, not assumed.** If a before/after PNG crop of the
  same region looks identical, the fix did not work. Bump `-r` to 250 and crop with PIL for a
  close look whenever a line looks like it might be touching a page or box edge.
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
  restructure the sentence into shorter independent clauses, or move the long token off the
  line-end position entirely, when `\allowbreak{}` alone doesn't move the needle (this was
  needed far more often than `\allowbreak{}` alone succeeding, this session); (3) split a
  combined `\description` `\item[...]` label into two items; (4) restructure code itself inside
  `lstlisting`, including moving a trailing inline comment to its own line above the code
  (an inline trailing comment on a long code line can wrap catastrophically, one word per line,
  cascading off the right edge of the box); (5) `\section[short]{long}` for a running-header/
  folio collision — confirmed needed twice this session (Ch.12, Ch.23), not just a theoretical
  case; (6) for a wide `longtable`, narrowing one column's `p{}` width while widening another,
  plus `\allowbreak{}` at `::`/`.` boundaries inside the widened column, can resolve a cell
  overlap without touching any cell's actual text content.
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
