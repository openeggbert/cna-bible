# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-22)

**416 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings —
independently re-verified via a forced rebuild (`latexmk -g`) against a clean `git status`
immediately before this file was written.** Re-verify before trusting this in a future session;
use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain
`grep -i undefined`.

Two full batches landed this session (18 chapters + Appendix B total), on top of the earlier
SDL_GPU chapter insertion and Ch.17/Ch.18 real-screenshot work from the same session's start:

- **Batch A** (10): Ch.10, 19, 20, 23, 32, 37, 40, 41, 43, 44, plus Appendix B.
- **Batch B** (8): Ch.8, 22, 30, 31, 35, 39, 46, 48.

Every one of these 18+1 files was individually rendered to PNG and read directly after its
batch's consolidated `make book` pass — not just log-checked. **Eight real page-edge text
overflows were found and fixed across the whole session, none of which produced a logged
`Overfull \hbox` warning** (Appendix E, Ch.45 x2, Appendix B, Ch.37, Ch.40, Ch.46, Ch.48). This
is a structural property of this defect class now, confirmed eight separate times — see
"Reusable findings" below.

Highlights from Batch B (the most recent work, in case Batch A's own detail has scrolled out of
this file by the time you read it — check `PLAN.md`'s session log for Batch A's own full
account):

- **Ch.8**: real `SoundEffect`/`Song`/`Video` `.xnb` content readers, closing the last major gap
  in the content-pipeline chapter (previously only graphics-side readers were covered).
- **Ch.22 (SDL GPU)**: `Texture3D`/`TextureCube`'s real `cycle=true` orphaned-write data
  corruption bug (SDLGPU-40), fixed via `cycle=false`; a third honest open item
  (SDLGPU-54's generated-mipmap depth-validation gap, whose own regression test may be
  structurally unable to catch it).
- **Ch.30 (GamerServices)**: a real cross-namespace hang between `GamerServicesDispatcher` and
  `NetworkSession` (found while porting a real sample, not via unit tests) and its real fix.
- **Ch.31 (Networking)**: `SendDataOptions`'s four enum values collapsing to three real
  `ENetBackend` delivery behaviors, verified against the real flag-mapping function and its own
  test suite; a `NetworkSession` status close-out (four independent post-completion audits).
- **Ch.35 (Sharp Runtime Namespaces)**: fail-fast enumeration landed in 10 of 11 generic
  collections (`PriorityQueue` is the one structural exception — no enumerable interface at
  all, not a missed fix); `List<T>`'s own honestly-documented remaining gap (`operator[]`-based
  writes don't trigger fail-fast).
- **Ch.39 (Windows/Wine)**: the full cross-compilation/DXVK-verification toolchain explained
  mechanically — three Wine prefixes for three distinct reasons, the self-verifying gate that
  refuses to silently fall back to WineD3D, the D3D9 oracle's real mechanics, and the one
  caveat every result in the chapter inherits (`D3DCAPS9` is DXVK-synthesized, not from an
  authentic period driver — real Windows hardware verification remains the one `needs_human`
  item, tracked and stated plainly).
- **Ch.46 (Samples and Examples)**: the largest single framework bug this project's
  sample-porting effort has ever found — a project-wide vertex-data-corruption defect in
  `ModelTypeReader::Read()` affecting every stride-32 `.model.json` model (the near-universal
  case), likely the true root cause of a multi-session "near-plane-clipping"/invisible-model
  symptom family chased across unrelated samples for months.
- **Ch.48 (Testing Philosophy)**: the golden-image regenerate/review/commit workflow quoted
  directly from its own header comment; a CI-design finding (`GTEST_SKIP()` self-skip instead
  of silent exclusion, so a hardware-only test stays visibly "SKIPPED" every run).

## The parallel-fork coordination pattern — READ THIS BEFORE DISPATCHING MORE FORKS

This is now a consistently observed property of this environment, confirmed across two full
sessions' worth of batches, not a one-off: **dispatched `Agent(subagent_type: "fork")` calls
routinely keep working, committing, and pushing well past their assigned single-chapter task**,
sometimes for several hours, regardless of an explicit "stop after one commit" instruction in
the dispatch prompt. This is not harmful by default — the extra work has consistently been
real, well-grounded, and valuable — but it means:

1. **Never trust a fork's own claim about which commit its content landed in.** Commit-message
   races are routine when multiple forks share one working tree (`git add`/`git commit`
   scooping up a sibling agent's staged-but-uncommitted work at the same moment) — a commit's
   message may name one chapter while its actual diff touches a completely different one, or
   several. Always verify with `git show --stat <hash> -- <path>` against the real file, not
   the commit message.
2. **After any batch, directly diff PLAN.md's claimed line count against each touched file's
   real line count** (`wc -l`) before trusting a "PDF-verified clean" label a fork wrote for
   its own row — this session found *seven* rows across two batches that were left at
   pre-session snapshot values despite real content landing and being verified, because the
   fork that wrote the "clean" label didn't actually go back and update its own row's numbers
   afterward. This is now a standing check to run every batch, not a one-time fix.
3. **A "PDF-verified clean" claim from a fork is a claim, not a fact** — this session hit two
   instances where a fork's own \allowbreak{}-only fix provably changed nothing about the
   rendered page (before/after PNG crops were pixel-identical), and one instance where a
   fork's own git-race investigation produced a false "this fix never actually landed"
   correction that itself needed correcting by a third party. Always independently re-render
   and look yourself before writing "PDF-verified clean" into `PLAN.md`.
4. `latexmk` routinely reports `"Nothing to do for 'main.tex'"` even when a source file changed
   underneath it moments ago (concurrent git operations don't reliably bump mtimes the way its
   dependency tracking expects). Always force with `latexmk -pdf -interaction=nonstopmode
   -halt-on-error -file-line-error -g main.tex` (the `-g` flag) when verifying, never trust the
   plain `make book` target's silence.
5. Dispatching 8-10 forks per batch and waiting for them to settle (checking `git log`/`git
   status` periodically, not fighting the extra work) has worked fine as a rhythm across two
   full sessions now — just budget real wall-clock time (each batch this session took roughly
   1-4 hours of forks running before they all genuinely stopped) and always finish with your
   own independent `make book` + PNG-render pass, regardless of what any fork already claimed.

## What is NOT yet done — the natural next body of work

Furthest-below-target as of this session's end (recompute from `PLAN.md`'s own table if this
list and PLAN.md ever disagree):

- Ch.23 Direct3D Backends (~13-19 of ~85) — still the largest absolute page gap in the book by
  a wide margin, worth a dedicated multi-pass focus rather than one more incremental addition.
- Ch.18 EasyGL Backend, Ch.20 BGFX Backend (~9-11 of ~55-65 each)
- Ch.12 Models and Meshes, Ch.5 First Game (untouched this session, still low: ~9/60, ~6/40)
- Ch.2 Ecosystem Map (~4/25)
- Appendices A/D/E/F — all still comfortably under target, none touched this session
- Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four-plus prior
  sessions' worth of depth passes) — read its own `PLAN.md` row before adding more.
- Screenshot infrastructure: `ASCII` and `CANVAS` backends remain untried for real screenshot
  capture (`CANVAS` is Emscripten/browser-only, a materially different path than `Xvfb`).

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable last
it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering every touched page is the only reliable overflow check — full stop, no
  exceptions for what the log says.** Eight separate real overflows across this session
  produced zero logged `Overfull \hbox` warnings between them.
- **A suspected fix must be pixel-verified, not assumed.** If a before/after PNG crop of the
  same region looks identical, the fix did not work. Bump `-r` to 250 and crop with PIL for a
  close look whenever a line looks like it might be touching the page edge.
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
  line-end position entirely, when `\allowbreak{}` alone doesn't move the needle; (3) split a
  combined `\description` `\item[...]` label into two items; (4) restructure code itself inside
  `lstlisting`; (5) `\section[short]{long}` for a running-header/folio collision; (6) for a wide
  `longtable`, narrowing one column's `p{}` width while widening another can resolve an
  overflow without touching any cell's text.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`.
- **`\checkmark` and other amssymb/amsfonts-only commands are undefined** in this project's
  preamble — use plain text (`OK`, `X`, etc.) for status symbols.
- **Before asserting a specific API call in a worked example, grep the real header for it.**

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. If you suspect staleness (see the
  coordination-pattern section above), force with `latexmk -pdf -interaction=nonstopmode
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
