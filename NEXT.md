# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-22)

**432 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings —
independently re-verified via a forced rebuild (`latexmk -g`) against a clean `git status`
immediately before this file was written.** Re-verify before trusting this in a future session;
use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain
`grep -i undefined`.

This was an unusually long, multi-batch session (author unavailable for many hours, explicit
"continue autonomously" instruction given partway through, repeated more than once). Five full
batches landed in total (371 → 432 pages, +61), on top of the earlier SDL_GPU chapter insertion
and Ch.17/Ch.18 real-screenshot work:

- **Batch A** (10): Ch.10, 19, 20, 23, 32, 37, 40, 41, 43, 44, plus Appendix B.
- **Batch B** (8): Ch.8, 22, 30, 31, 35, 39, 46, 48.
- **Batch C** (6): Ch.2, 5, 12, 18, 20 (2nd pass), 23 (2nd pass).
- **Batch D** (6): Ch.11, 13, 33, 34, Appendix A, Appendix D.

Every touched file across all batches was individually rendered to PNG and read directly after
its own batch's consolidated `make book` pass — not just log-checked. **Twelve real page-edge/
box/running-header overflows were found and fixed across the first five of six batch-verification
passes, and not one of them produced a logged `Overfull \hbox` warning.** Batch D (the most
recent) was the first batch all session with **zero** overflow defects and **zero** stale
`PLAN.md` rows found — worth knowing as a positive data point, not just a list of failures.

Highlights from Batch D (Ch.11/13/33/34, Appendix A/D — the most recent work):

- **Ch.11 (Textures and Render Targets)**: found and fixed a real stale claim — the chapter's
  own headline claim that `Texture3D`/`TextureCube` don't inherit `Texture` (Task 863) is stale;
  both now do. Added a worked volume-texture (`Texture3D`) shader-sampling example grounded in
  a real EasyGL-only test.
- **Ch.13 (Stock Effects)**: `plan_graphics.md`'s Task 890 (`EnvironmentMapEffect`'s
  `DirectionalLight1`/`DirectionalLight2` forwarding) is marked open in the tracker but is
  actually already fixed on every backend — added a discriminating three-light worked example,
  since a single-light test can't tell "one light forwarded, two dropped" from the real fix.
- **Ch.33 (Storage)**: the real four-tier `EnsureStorageRoot()` platform-resolution chain
  (`SDL_GetPrefPath` → `XDG_DATA_HOME` → `HOME/.local/share` → cwd), plus a genuinely new,
  previously-undocumented gap: `OpenFile`'s `FileShare` parameter cannot be honored at all,
  structurally — `sharp-runtime`'s `FileStream` has no constructor overload that accepts one.
- **Ch.34 (Sharp Runtime Overview)**: the permanent scope-boundary taxonomy (Reflection is a
  deliberate stub with internally-inconsistent-by-design predicates; GC calls are real no-ops;
  Serialization/P-Invoke/Cryptography are explicitly out of scope, each with its own dated
  reason) and the real vendored-dependency/build-structure account.
- **Appendix A**: new `SpriteFont` and `Model`/`ModelMesh`/`ModelBone`/five-stock-effects
  quick-reference sections, closing two of the appendix's more glaring remaining gaps.
- **Appendix D**: an org-wide, `cloc`-measured line-count comparison across all 18 real
  repositories (`cna` itself is ~181.2k lines, ~40% of the whole ecosystem's ~444.6k total),
  sourced from the `openeggbert/openeggbert` index repo's own README — not previously used as a
  source anywhere in this book. Also corrected `mobile-eggbert-legacy`'s description (a genuine
  ILSpy-decompiled preservation archive, not a working reimplementation) and confirmed
  `youtube-frontend` as a real, unrelated repo in the same org.

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
cleanly across five consecutive batches — a proven, repeatable rhythm for this project, not a
one-off experiment.

## What is NOT yet done — the natural next body of work

Furthest-below-target as of this session's end (recompute from `PLAN.md`'s own table if this
list and PLAN.md ever disagree):

- Ch.23 Direct3D Backends — even after two passes this session, still the largest absolute page
  gap in the book (target 85, still well under half). Worth a dedicated multi-pass focus.
- Ch.19 Vulkan Backend, Ch.10 SpriteBatch, Ch.17 SDL_Renderer Backend, Ch.31 Networking,
  Ch.35 Sharp Runtime Namespaces (~10-16% of target each, none touched in Batch D)
- Ch.25 DX3/free-direct Backend, Ch.24 Canvas/ASCII Backends (~17-18% of target)
- Appendices C, E, F — untouched this session, all still comfortably under target
- Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
  sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
- Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
  capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering every touched page is the only reliable overflow check — full stop, no
  exceptions for what the log says.** Twelve separate real overflows across this session's
  first five verification passes produced zero logged `Overfull \hbox` warnings between them,
  across at least three distinct visual shapes: plain page-edge text, a `longtable` cell
  overlapping its neighbor column, and a `\section{}` title colliding with its own running
  header/folio. A sixth verification pass found zero — the check is still worth running every
  time regardless, since a clean result isn't knowable in advance.
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
  restructure the sentence into shorter independent clauses, or move the long token off the
  line-end position entirely, when `\allowbreak{}` alone doesn't move the needle (needed far
  more often than `\allowbreak{}` alone succeeding, this session); (3) split a combined
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
