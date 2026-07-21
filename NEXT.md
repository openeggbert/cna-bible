# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## FIRST THING TO DO: check whether a concurrent background pass finished

As this long autonomous session wound down (2026-07-21 into 2026-07-22), a second,
independently-active background agent was mid-way through its own overflow-fixing pass on at
least two files — `latex/book/chapters/appendices/appendix-b-feature-matrix.tex` and
`latex/book/chapters/part7-easygl-freedirect/ch37-easygl-deep-dive.tex` — adding `\allowbreak{}`
at `::`/camelCase boundaries inside long `\texttt{}` identifiers, the same defect class covered
below. That work was **still uncommitted, in progress, in the shared working tree** when this
session ended; it may have committed on its own since (check `git log` — look for commit
messages mentioning overfull-hbox/allowbreak fixes to `appendix-b-feature-matrix.tex` or
`ch37-easygl-deep-dive.tex` dated after `b199a92`), or it may still be sitting uncommitted in
the working tree (check `git status` and `git diff` on those two files specifically before
doing anything else). If it's still uncommitted: read the diff, decide whether it looks like a
real, well-motivated fix (the pattern above is a good sign) or something to discard, and either
commit it or `git checkout --` it before starting new work — don't let it sit in limbo.

## A real coordination pattern this project's use of parallel forks now needs standing awareness of

This is the **second session in a row** where dispatched `Agent(subagent_type: "fork")` calls
turned out to be genuine, independent background agents that inherit the full conversation
context — including the top-level autonomous-work authorization — and can keep working well
beyond their narrowly dispatched task: committing and pushing on their own, picking up
unrelated adjacent work, and in this session's case, apparently still running a careful
verification/fix pass on files from an earlier batch even after the dispatching session moved
on to new work. Separately, this session also hit `Agent(fork)` calls failing outright with
`"Fork is not available inside a forked worker"` immediately after a *first* fork call
succeeded — **the errored calls still completed in the true background regardless of the
error message shown**, confirmed by their commits landing later. Practical guidance, now
confirmed twice:

1. Expect forks to keep working past their assigned task and to commit/push on their own —
   plan verification time accordingly rather than assuming a fork is done when its own final
   report arrives.
2. An immediate `"Fork is not available..."` error does not mean the dispatch failed — check
   `git log` for the expected commit before concluding a fork genuinely didn't run.
3. Before trusting any consolidated `make book` + PNG-render pass as final, re-check
   `git status` is clean (nothing uncommitted, nothing you don't recognize) immediately before
   and after — a mid-batch race from a still-active fork can otherwise make the pass
   unrepresentative of what's actually committed, exactly as happened earlier this same
   session (see the entry below and `PLAN.md`'s own session log for the full, resolved
   account).
4. `latexmk` has repeatedly reported `"Nothing to do for 'main.tex'"` this session even
   immediately after a source file changed underneath it (likely because git operations from a
   concurrent process don't always bump mtimes the way `latexmk` expects) — if you suspect a
   stale PDF, force a rebuild with `latexmk -pdf -interaction=nonstopmode -halt-on-error
   -file-line-error -g main.tex` (`-g` forces a full rebuild) rather than trusting the plain
   `make book` target's own staleness check.

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
**and been pixel-confirmed**, not just log-grepped clean (a real instance of exactly this
distinction mattering is documented below and in `PLAN.md`'s session log).

## Where things stand (end of session, 2026-07-21 into 2026-07-22)

This was an unusually long, eventful autonomous session (author unavailable for several hours,
explicit authorization to work independently). Two full batches landed:

**Batch 1 (fully verified, PDF-confirmed clean): Ch.15/24/25/36/42/45, Appendices C/D/E/F, plus
Ch.16/17/18.** Highlights: a real, historical `ShaderEffect` 3D-draw limitation and its fix
(Ch.15); both Canvas/ASCII backends' 2D-only-by-design contract (Ch.24); DX3's shadow-backbuffer
`RenderTarget2D` reuse (Ch.25); `IDisposable`/exception-hierarchy parity philosophy incl.
`ReaderWriterLockSlim`'s own three-bug self-correction history (Ch.36); the D3D9 oracle corpus
traced fully end to end (Ch.42); a second full xna4-spec audit finding a real, deliberate
`Viewport::TitleSafeArea` divergence (Ch.45); 13 new glossary entries, two newly-catalogued real
repos, new NOXNA/quick-reference sections (App C/D/E/F). **Plus a real, previously-untested
capability confirmed: real screenshots for Ch.17 (SDL_Renderer) and Ch.18 (EasyGL), captured
under `Xvfb`** — this book's own screenshot-feasibility notes had left this "plausible but not
actually tried" since 2026-07-20; now confirmed and reproducible (see
`tools/cna-screenshot-infra/README.md`, `xvfb_screenshot_demo.cpp`,
`xvfb-demo-cmake-registration.patch`). `cna`'s own working tree has two reusable, ccache-enabled
build directories now: `build-sdlrenderer/` and `build-easygl/`.

**A real coordination hazard hit mid-batch-1 and was fully resolved — read `PLAN.md`'s own
session log for the complete account** (search for "batch-10 depth pass" and the "Correction"
entry right after it): a background fork kept working past its assigned task, raced the
coordinating session's own `make book` run, and one of its `\allowbreak{}`-only overflow fixes
was later found (by a *different* concurrent agent, via careful before/after pixel comparison)
to have changed nothing about the actual render — three real page-edge text overflows (Appendix
E, Ch.45 ×2) were still live despite a "fixed" commit message and despite **no logged
Overfull-hbox warning for any of the three**. Fixed for real in commit `4c9d177` by
restructuring the sentences instead. **The standing lesson: PNG-rendering is the only reliable
check for this defect class — absence of a logged warning is not evidence of correctness**, and
a fix must be pixel-verified (before/after crop comparison), not assumed from a clean rebuild or
another agent's commit message.

**Batch 2 (content landed and build-verified clean at the log level; PNG-level pixel
verification of the *new* content is incomplete as of session end — see the section above about
a concurrent pass possibly still finishing this): Ch.10/19/20/23/32/37/40/41/43/44, Appendix B.**
Highlights: SpriteBatch's sort-deferred (not draw-call-batched) flush timing (Ch.10); Vulkan's
`CreateSwapchain()` UNORM-not-SRGB decision and `PresentInterval` fallback chain (Ch.19); BGFX's
free-list-backed render-target view-id pool (Ch.20); D3D11's three-group (not two)
resource-lifetime tracking (Ch.23); a worked `ComputeBoneTransformsEXT` example with three real
bugs (Ch.32); easy-gl's two-tier context-loss recovery, one tier real and used, one designed but
never adopted (Ch.37); a real WebGL context-loss code path plus a link-flag gap (Ch.40); a real,
currently-live NDK cross-compile regression (`getrandom()` gated behind API 28, this project
targets API 24) found by re-running the exact same command a prior pass had confirmed working
(Ch.41); Migration Guide Step 7 build/runtime troubleshooting tables (Ch.43); a full CNA-port
feasibility analysis for Blupi, grounded in `free-eggbert`'s own real `cna.md` line-count audit
(Ch.44); two real longtable capability grids condensed from
`docs/graphics-backend-feature-matrix.md`, including a caught-and-flagged stale row in that
source doc itself (Appendix B).

**Current build state**: forced rebuild (`latexmk -g`) succeeds, **402 pages**, both grep
checks clean (`grep -i "Warning.*undefined\|undefined reference\|undefined control"` and
`grep -i "multiply defined\|multiply-defined"` both empty). This confirms batch 2 compiles and
has no cross-reference regressions, but per the lesson above, a clean grep is necessary, **not
sufficient** — batch 2's own newly-added pages have not all been individually PNG-rendered and
read yet (a first pass sampled one page per chapter and found everything clean, but that was
not the full systematic sweep batch 1 got). **Do that full sweep before marking batch 2's
`PLAN.md` rows `PDF-verified clean`** — they are currently correctly marked `pending batch
verification`.

## What is NOT yet done — the natural next body of work

1. **Finish batch 2's verification**: resolve the possibly-still-in-progress concurrent edit
   (see top of this file), rebuild with `latexmk -g`, re-run both grep checks, locate every
   batch-2 chapter's physical page range via `pdftotext`, render every touched page to PNG at
   120dpi (bump to 150+ and crop with PIL if a specific line looks borderline), read each one
   directly, fix anything found, then relabel all eleven `PLAN.md` rows (Ch.10/19/20/23/32/37/
   40/41/43/44, App B) `PDF-verified clean`.
2. Continue with further chapters once batch 2 is verified. Furthest-below-target as of this
   session's end (recompute from `PLAN.md`'s own table if this list and PLAN.md ever disagree):
   Ch.23 Direct3D (~13 of ~85, still the largest gap even after this session's addition), Ch.41
   Android/NDK (~7 of ~40), Ch.31 Networking and Ch.35 Sharp Runtime Namespaces (~9 of ~70
   each), Ch.20 BGFX (~10 of ~55), Ch.10 SpriteBatch (~9 of ~55).
3. Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
   sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
4. Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
   capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check — full stop, no
  exceptions for what the log says.** Absence of a logged `Overfull \hbox` warning is not
  evidence of correctness for this defect class (proven concretely this session, see above).
- **A suspected fix must be pixel-verified, not assumed from a clean build log or from a
  previous agent's commit message.** If a before/after PNG crop of the same region looks
  identical, the fix did not work.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **`\checkmark` and other amssymb/amsfonts-only commands are undefined in this project's
  preamble** (no `amssymb` package loaded) — use plain text (`OK`, `X`, etc.) for status
  symbols in tables rather than assuming a common LaTeX symbol command is available; check
  `latex/common/preamble.tex`'s own `\usepackage` list before using an unfamiliar command.
- **`\allowbreak{}` cannot go inside a `\cnans{}`/`\cnaclass{}` argument** (would corrupt the
  index). If a `\cnans{}`/`\cnaclass{}`-wrapped long identifier is the thing overflowing and the
  identical term is indexed elsewhere in the same chapter via another `\cnans{}`/`\cnaclass{}`
  instance, it's safe to switch just the overflowing instance to a plain, `\allowbreak{}`-able
  `\texttt{}` — the index entry survives via the other instance. Verify that precondition first;
  don't silently downgrade without checking.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_`/`.` boundaries — verify it actually changed the render, don't assume; (2)
  restructure the sentence into shorter independent clauses when `\allowbreak{}` alone doesn't
  move the needle; (3) split a combined `\description` `\item[...]` label into two items; (4)
  restructure code itself inside `lstlisting`; (5) `\section[short]{long}` for a running-header/
  folio collision; (6) for a wide multi-column `longtable`, narrowing one column's `p{}` width
  while widening another can resolve an overflow without touching any cell's own text.
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
