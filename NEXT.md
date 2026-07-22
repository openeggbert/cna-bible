# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-22)

**452 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings —
independently re-verified via a forced rebuild (`latexmk -g`) against a clean `git status`
immediately before this file was written.** Re-verify before trusting this in a future session;
use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain
`grep -i undefined`.

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

- Ch.23 Direct3D Backends — even after two passes this session, still the largest absolute page
  gap in the book (target 85, still well under half). Worth a dedicated multi-pass focus.
- Ch.17 SDL_Renderer Backend, Ch.35 Sharp Runtime Namespaces (both touched only incidentally
  this batch — a header fix and a fatal-error fix respectively, not a real depth pass)
- Appendices C, E, F — untouched all session, all still comfortably under target
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
