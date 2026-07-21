# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## The book now has 49 chapters, not 48 — READ THIS BEFORE CITING A CHAPTER NUMBER

**2026-07-21, later the same session:** a new chapter, **Ch.22 (The SDL GPU Backend)**, was
inserted into Part IV, and every chapter from the former Ch.22-48 renumbered to Ch.23-49. This
happened because researching Ch.15 turned up `SDL_GPU` — a real, mature, 20-CTest-verified
`CNA_GRAPHICS_BACKEND` value with zero dedicated coverage anywhere in this book. The author was
asked and explicitly chose to add the chapter now rather than leave it flagged. If you cite a
chapter number from memory or from an old commit message, **it may now be off by one** for
anything that used to be 22 or higher — check the real file list under `latex/book/chapters/`
or grep `main.tex`'s `\input{}` order before trusting a remembered number. `\label{ch:...}`
values did **not** change (they're semantic), so every `\ref{}` in the book is still correct —
only plain-text `Chapter~N`/`Ch.N` citations were at risk, and a full project-wide sweep already
fixed every one found (confirmed via `make book` + PNG-render afterward, see below).

## Working-method change, effective now — READ THIS FIRST

**2026-07-21, author decision, encoded in `CLAUDE.md`:** verification is now batched, not
per-chapter. Write across roughly 8-10 chapters/appendices — committing and pushing each one
individually as always — without running `make book` or rendering any PNG pages in between.
Only once the batch is done, run one consolidated pass: `make book`, both grep checks (see
below), locate every touched chapter's physical page range, render every touched page to PNG,
read each one, and fix everything found together. While a batch is in flight, mark its PLAN.md
rows `**In progress (~N of ~M pages, pending batch verification)**` — not "PDF-verified
clean" — and only relabel them once the batch's own verification pass has actually run. This
is a deliberate, explicit trade of per-chapter safety for writing throughput; a batch can sit
broken or overflowing for its own duration, and that is the accepted cost, not an oversight.

Source-grounding is **not** relaxed by this policy — every claim still requires a real header/
`.cpp`/test/doc read before writing a sentence about it, exactly as before.

## Where things stand (end of session, 2026-07-21)

**The book is a single, unified book, now 49 chapters + 6 appendices**, built via `make book`
(→ `latex/book/main.pdf`). Compiles clean as of the last commit: **371 pages, 0 undefined
references, 0 duplicate-label warnings** (re-verify — run `make book` and grep the log — before
trusting this number in a future session; use `grep -i "Warning.*undefined\|undefined
reference\|undefined control"`, not a plain `grep -i undefined`, which can false-positive on
ordinary prose).

**This session ran the first batch under the new batched-verification policy** — nine
chapter/appendix touches, committed and pushed individually as they were written, with one
consolidated `make book` + PNG-render pass run at the end (clean). **Immediately afterward, in
the same session**, researching the next candidate (old Ch.15) surfaced the `SDL_GPU` finding
above, leading to the new Ch.22 insertion and the Ch.22-49 renumbering — so every chapter
number below is given in **current, post-renumbering** form, not the number it had while the
work was actually happening.

Highlights from this batch:

- **New Ch.22 (The SDL GPU Backend)**: the headline event of the session. A real, mature,
  20-CTest-binary-verified backend inserted into Part IV with a full first-pass chapter —
  the zero-new-dependency rationale, the fixed HLSL-style resource-binding order, the Y-flip
  bug a real screenshot caught, `SkinnedEffect`'s real ~4096-byte push-uniform cap worked
  around via a storage buffer, and the runtime `libshaderc` compile built without
  `libshaderc-dev` installed in this dev environment. See the dedicated section above for the
  full renumbering mechanics.
- **Ch.21 (WebGPU Backend)**: the real investigation behind the "no backend does
  block-compressed texture upload" gap — the dev machine's real GPU genuinely supports
  DXT1/3/5 (`wgpuAdapterHasFeature` confirmed true), so the actual blocker is a shared,
  project-wide `ImageData`/`Texture2D.cpp` design gap (always-CPU-decompress, no
  compressed-bytes field), not a WebGPU-specific one. A hand-crafted single-backend workaround
  was deliberately rejected as unreachable by any real game.
- **Ch.28 (Media)**: `VideoPlayer`'s real disposed-state guard (`CheckDisposed()`, 8 call
  sites), with one deliberate C++-specific exception — `Dispose()` itself stays idempotent
  rather than replicating FNA's own double-`Dispose()` throw, since a C++ destructor is
  implicitly `noexcept` and `~VideoPlayer()` unconditionally calls `Dispose()`.
- **Ch.29 (Devices and Sensors)**: a fourth concurrency finding — native failures (including an
  exception thrown from inside a game's own `CurrentValueChanged` handler mid-callback) were
  silently swallowed by a bare `catch (...) {}`; fixed with a shared, deliberately `noexcept`
  diagnostic channel safe to call from a C callback boundary. The pre-existing LIFE-001 finding
  was renumbered to fifth to keep physical document order correct after the insertion.
- **Ch.40 (Web/Emscripten)**: traced the already-documented CANVAS build's own byproduct — a
  real, still-present SDL3-for-Emscripten prebuilt cache (`.sdl-prebuilt-emscripten/`, real
  `.a` file sizes inspected directly) — and confirmed it is backend-agnostic, so a future
  EASYGL Emscripten attempt would reuse it rather than rebuild SDL3 from scratch.
- **Ch.34 (Sharp Runtime Overview)**: added `Task::WhenAll`/`WhenAny`, including the real
  exception-type-sniffing cancellation bug (`catch (const TaskCanceledException&)` used to
  detect cancellation, unable to tell a real cancellation from a caller-supplied
  `TaskCanceledException`) found independently in two places, fixed with an out-of-band flag.
- **Ch.47 (Project Practice) + Ch.1**: found a fifth, *self-referential* instance of this
  project's own "stale claim, live source disagrees" pattern — the earlier four-location
  oracle-scene-count fix (Ch.1/23/48/Appendix B) had itself missed a fifth location: two more
  stale "31"s sitting further down Ch.1's own file (its verification-scale table and its own
  illustrative completion-count example). Found while mining Ch.47 for material, fixed in Ch.1.
- **Ch.16 (Backend Architecture)**: `IIndexBufferBackend::SetData32`'s throwing default (the
  opposite failure mode from every other default this chapter covers) traced through all 14
  backend implementations — the 4 that don't override it are exactly the 2D-only backends that
  already refuse any index-buffer construction at all, so the throw is real but unreachable.
- **Ch.33 (Storage)**: a compounding second finding alongside the already-documented `..`
  path-traversal gap — Storage is the one ported XNA namespace with zero automated test
  coverage anywhere (no test directory, no flat test file, confirmed against the real test tree
  and CMake registration), so the traversal gap was never something a test suite could have
  caught. Also documented the namespace's own untested hand-rolled backtracking glob matcher.

## The two techniques that keep paying off — READ THIS FIRST if continuing

1. **Re-verify a chapter's own tracked-doc claim against live source**, rather than hunting a
   plan-doc's newest phase for brand-new material. This project's "stale status" meta-pattern
   has now been hit well over two dozen times across four sessions' worth of batches — a
   structural property of this codebase, not a coincidence.
2. **Directly recount a number the book cites**, rather than trusting a prior pass's own
   snapshot value. This session's own oracle-scene-count fix needed a *second* pass to actually
   finish (see Ch.1/Ch.46 above) — a reminder that even a deliberate, targeted re-check sweep
   can itself miss a location; grep thoroughly, and don't assume one correction pass was
   exhaustive just because it succeeded at fixing what it found.
3. **A correction to one claim often needs propagating to more places than expected.** The
   oracle-scene-count fix now stands at five locations across two separate sessions. Grep
   sibling chapters and appendices for the same task number, doc name, or specific figure
   before considering a correction complete — and consider re-grepping even after a previous
   session already did a propagation pass.

## What is NOT yet done — the natural next body of work

**No task is currently active or blocked.** Good next candidates for a further batch, still
meaningfully below their page targets (see `PLAN.md`'s own per-chapter table for the precise
`~N of ~M pages` estimate after every edit — **use PLAN.md's own numbers, not this list's,
if the two ever disagree**, since chapter numbers shifted mid-session): Ch.15 Shader/.fx Gap
(the chapter that led to the SDL_GPU discovery — worth returning to for its own sake too),
Ch.24 Canvas/ASCII Backends, Ch.25 DX3/free-direct Backend, Ch.36 Parity Philosophy, Ch.42
Verification Methodology, Ch.45 xna4-spec Auditing, and Appendices C-F (still well under their
modest 15-25-page targets). Ch.49 (Roadmap) and Ch.22 (SDL GPU Backend, brand new) were both
just touched this session — fine to revisit in a later depth pass, but not first-priority.
Ch.7 Math remains the largest chapter by far — read its own PLAN.md row before adding more, it
may be genuinely saturated.

No `TaskCreate` entries exist for a further batch — the task-tracker MCP tool was unavailable
for this entire session (disconnected partway through a prior session); work has been tracked
purely via PLAN.md/NEXT.md rows and commit messages instead. Check whether it's back before
assuming it's still unusable.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check.** Always
  rebuild, locate the chapter's physical page range via `pdftotext` (split the extracted text on
  the `\f` form-feed character to get one string per physical page, then search for a unique
  phrase from the new addition — much faster than guessing ranges by hand), render to PNG via
  `pdftoppm -png -f N -l N -r 120`, and actually read the rendered pages. `pdftoppm` zero-pads
  output filenames to a consistent width once the page range spans enough digits (e.g.
  `ch08-093.png`, not `ch08-93.png`) — check the actual generated filename with `ls` if a `Read`
  on the expected name fails.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **`grep -i overfull` on the build log is proven unreliable as a completeness check** — the
  log had 413 raw "Overfull" hits project-wide this session, the overwhelming majority
  pre-existing and unrelated to any current batch. PNG-rendering the specific touched pages is
  the only way to know whether a *new* edit introduced a *new* overflow.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_` boundaries, 1-2 rounds max. (2) Restructure the sentence into shorter
  independent clauses — the most reliable fix nearly every time. (3) Split a combined
  `\description` `\item[...]` label into two items. (4) Restructure code itself inside
  `lstlisting` (`\allowbreak{}` doesn't apply there). (5) `\section[short]{long}` for a
  running-header/folio collision. Don't add `\allowbreak{}` speculatively during the writing
  phase of a batch (no build to check it against yet) — wait for the verification pass.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`.
- **Before asserting a specific API call in a worked example, grep the real header for it.**
- `\cnaclass{}`/`\cnans{}` both wrap in `\texttt{}` *and* emit `\index{}` — never put
  `\allowbreak{}` inside their arguments (would corrupt the index).

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log with the corrected
  `undefined` pattern above and `multiply defined`/`multiply-defined` every time — but only at
  batch-verification time, not after every chapter, per the new policy above.
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed in this
  environment.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`)
  live at `/rv/data/development/github.com/openeggbert/<name>` in this environment — not
  `/workspace`. `free-eggbert`/`planetblupi` are also mirrored read-only under
  `/rv/data/library/github.com/openeggbert/`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext`), never assume printed page N is physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Run the project's spacing-fix regex on every touched file, even during the writing phase of a
  batch (this is cheap, local, and doesn't need a build):
  `python3 -c "import re; p='PATH'; t=open(p).read(); n=re.sub(r'\}/(\\\\texttt\{|\\\\cnaclass\{)', r'} / \1', t); open(p,'w').write(n) if n!=t else None"`
  — then manually grep for the `}/%` newline-continuation variant, which the regex doesn't
  catch (usually intentional and correct as-is; only fix it if actually producing a visible
  overflow, checkable only at verification time).
- No task is currently blocked/`needs_human`. If a genuine architectural ambiguity comes up in
  future work, mark it clearly here and in `PLAN.md`'s session log, and continue with other
  independent work rather than stalling.
