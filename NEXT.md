# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last commit: **365 pages, 0 undefined references, 0
duplicate-label warnings** (re-verify — run `make book` and grep the log — before trusting
this number in a future session; use `grep -i "Warning.*undefined\|undefined reference\|undefined
control"`, not a plain `grep -i undefined`, which can false-positive on ordinary prose).

**This session ran three consecutive fifth-pass-and-later batches** (tasks #47–57, #58–63,
#64–69), all under the same standing autonomous authorization, for **twenty-seven total
chapter/appendix touches**. The third batch (#64–69) covered Ch.8, 36, 43, 38, 45, 47, plus a
four-location propagation (Ch.1, Ch.22, Appendix B) found while working Ch.47. The
"re-verify a tracked claim against live source" technique from the prior two batches kept
paying off, joined this batch by a close cousin: **directly recounting a number the book
itself cites** (file counts, sample totals) rather than trusting a prior pass's own snapshot.

Highlights from the third batch (#64–69):

- **Ch.8 (Content and Assets)**: the chapter's own "\texttt{.xnb} reader still growing" framing
  was itself stale — every phase through the reader's own closing phase is now complete. Added
  a real hardening pass (3 more heap-buffer-overflows found by deterministic fuzzing, not code
  review) and the custom-reader extension point verified against a real third-party reader
  (prime31/Nez).
- **Ch.36 (EasyGL Deep Dive)**: two more real RAII additions (`ScopedBind`, `%
  ResourceRegistration`) mined from easy-gl's own tracking docs — caught and fixed an invented
  API call (`Texture::unbind()` doesn't exist) in an early draft before committing.
- **Ch.43 (Blupi Case Study)**: two more "confirm, don't assume" findings from free-direct's own
  newest tracking doc (`GetCurrentPosition` has zero real call sites in either target game; a
  mixed 8-bit/32-bit blit audit found the same).
- **Ch.38 (Windows/Wine)**: gave the project-wide DXVK-authenticity caveat (`D3DCAPS9` is
  synthesized by DXVK, not an authentic period driver) its own full section — previously only
  ever mentioned in passing elsewhere, despite this being the chapter that owns the
  verification machinery it qualifies.
- **Ch.45 (Samples and Examples)**: broke down the chapter's own "153 samples" figure precisely
  for the first time — the 67 beyond the official 86-sample XNA 4.0 collection each carry a
  named, permanent, structural exclusion reason, not an unattempted backlog.
- **Ch.47 (Testing Philosophy) + Ch.1 + Ch.22 + Appendix B**: found the D3D9 oracle corpus's own
  scene count was stale in **four separate locations at once** (31, then 36, cited at different
  snapshots as the corpus grew) — directly recounted the real `.scene` files on disk (39) and
  corrected all four together in one commit.

Every edit was rebuilt, checked for undefined/duplicate-label errors, and
PNG-rendered/visually verified before committing; 6 commits went to `develop` this batch, each
pushed immediately.

## The two techniques that keep paying off — READ THIS FIRST if continuing

1. **Re-verify a chapter's own tracked-doc claim against live source**, rather than hunting a
   plan-doc's newest phase for brand-new material. This project's "stale status" meta-pattern
   (a doc/chapter says X is still broken/unimplemented; the live source shows it was fixed,
   superseded by a later task the doc was never updated to reflect) has now been hit well over
   two dozen times across three sessions' worth of batches. It is a structural property of this
   codebase, not a coincidence — keep mining for it.
2. **New this batch: directly recount a number the book cites**, rather than trusting a prior
   pass's own snapshot value. File counts (`find ... | wc -l`), sample totals, task counts, and
   similar recur across chapters written at different points in this project's history, each
   capturing a true-at-the-time value that later drifted as the underlying artifact grew. When a
   chapter states a specific count for something directly countable in the live repo (test
   files, oracle scenes, samples, tasks), recount it directly rather than assuming the cited
   figure is still current — and check every other chapter/appendix that cites the same number,
   since a real one (like this session's oracle-scene count) is often propagated by hand across
   several locations that all go stale together.
3. **A correction to one claim often needs propagating to 2–4 places.** This session's biggest
   finds were multi-location: the `ClearOptions::Stencil` fix touched 3 chapters in one batch;
   the oracle-scene-count fix touched 4 locations in this batch. Grep sibling chapters and
   appendices for the same task number, doc name, or specific figure before considering a
   correction complete.

## What is NOT yet done — the natural next body of work

**No task is currently active or blocked.** Good next candidates for a further pass, still
meaningfully below their page targets (rough `wc -l`-based line counts — see `PLAN.md`'s own
per-chapter table for the precise `~N of ~M pages` estimate after every edit): Ch.7 Math (still
the largest chapter by far — four+ sessions of prior work, read its own PLAN.md row before
adding more, it may be genuinely saturated), Ch.15 Shader/.fx Gap, Ch.16 Backend Architecture,
Ch.21 WebGPU, Ch.23 Canvas/ASCII Backends, Ch.24 DX3/free-direct Backend, Ch.27 Media, Ch.28
Devices and Sensors, Ch.32 Storage, Ch.33 Sharp Runtime Overview, Ch.35 Parity Philosophy, Ch.39
Web/Emscripten, Ch.41 Verification Methodology, Ch.44 xna4-spec Auditing, Ch.46 Project Practice,
Ch.48 Roadmap, and any appendix (C–F still well under their modest 15–25-page targets; B is now
slightly ahead of the others after this session's corrections).

No `TaskCreate` entries exist yet for a further batch — create them following the same
one-task-per-chapter pattern used across every batch so far if picking this up.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check.** Always
  rebuild, locate the chapter's physical page range via `pdftotext -f N -l N`, render to PNG via
  `pdftoppm -png -f N -l N -r 120`, and actually read the rendered pages. Note: `pdftoppm` zero-
  pads output filenames to a consistent width once the page range spans enough digits (e.g.
  `ch08-093.png`, not `ch08-93.png`) — check the actual generated filename with `ls` if a
  `Read` on the expected name fails.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_` boundaries, 1–2 rounds max. (2) Restructure the sentence into shorter
  independent clauses — the most reliable fix nearly every time. (3) Split a combined
  `\description` `\item[...]` label into two items. (4) Restructure code itself inside
  `lstlisting` (`\allowbreak{}` doesn't apply there). (5) `\section[short]{long}` for a
  running-header/folio collision.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`.
- **Before asserting a specific API call in a worked example, grep the real header for it** —
  this session caught an invented `Texture::unbind()` (doesn't exist on that class; used
  `VertexArray::bind()`/`unbind()` instead, which does) before it reached a commit.
- **A heavily-worked chapter can still hide undiscovered pre-existing overfull-hboxes** — don't
  assume a well-covered chapter is layout-clean; render and check it the same as any other.
- `\cnaclass{}`/`\cnans{}` both wrap in `\texttt{}` *and* emit `\index{}` — never put
  `\allowbreak{}` inside their arguments (would corrupt the index).

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log with the corrected
  `undefined` pattern above and `multiply defined`/`multiply-defined` every time.
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed in this
  environment.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`)
  live at `/rv/data/development/github.com/openeggbert/<name>` in this environment — not
  `/workspace`. `free-eggbert`/`planetblupi` are also mirrored read-only under
  `/rv/data/library/github.com/openeggbert/`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`), never assume printed page N is
  physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway. Forward-referencing a `\label{}` defined
  later in the same document is fine (LaTeX's two-pass compile resolves it), but add the
  `\label{}` at its own definition site if one doesn't already exist there.
- Run the project's spacing-fix regex on every touched file before rebuilding:
  `python3 -c "import re; p='PATH'; t=open(p).read(); n=re.sub(r'\}/(\\\\texttt\{|\\\\cnaclass\{)', r'} / \1', t); open(p,'w').write(n) if n!=t else None"`
  — then manually grep for the `}/%` newline-continuation variant, which the regex doesn't
  catch (usually intentional and correct as-is; only fix it if actually producing a visible
  overflow).
- No task is currently blocked/`needs_human`. If a genuine architectural ambiguity comes up in
  future work, mark it clearly here and in `PLAN.md`'s session log, and continue with other
  independent work rather than stalling.
