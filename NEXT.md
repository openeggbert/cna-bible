# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last commit: **359 pages, 0 undefined references, 0
duplicate-label warnings** (re-verify — run `make book` and grep the log — before trusting
this number in a future session; use `grep -i "Warning.*undefined\|undefined reference\|undefined
control"`, not a plain `grep -i undefined`, which can false-positive on ordinary prose — see
"Reusable findings" below).

**This session ran two consecutive third/fourth-pass batches** (tasks #47–57, then #58–63),
continuing the standing autonomous authorization from prior sessions, for **eighteen total
chapter touches** across the two batches. The second batch (#58–63) covered Ch.34, 9+14+17
(a connected three-chapter fix), 31, 10, 29, 42. The single highest-value technique remained
the same across both batches: **re-verifying a chapter's own already-cited tracked-doc claim
against live source**, rather than hunting a fresh plan-doc phase for brand-new material.

Highlights from the second batch (#58–63):

- **Ch.34 (Sharp Runtime Namespaces)**: added `MemoryStream`'s real, deliberately-left
  writable-default divergence from real .NET (found incidentally during an unrelated audit
  ticket's regression tests).
- **Chapters 9, 14, and 17 — a connected three-chapter correction**: all three cited
  `ClearOptions::Stencil` (Task 871) as a confirmed no-op on EasyGL/Vulkan/BGFX. It is fixed on
  all three hardware backends, with a real independent Vulkan bug found and closed in the same
  fix (every render-pass-creation site had `stencilLoadOp` hardcoded to discard the clear
  value) and a genuine methodology finding about same-frame vs. cross-frame testing under this
  project's per-frame-batched rendering architecture. Found while depth-passing Ch.17
  (SDL_Renderer), then propagated back into Ch.9 and Ch.14 in the same session.
- **Ch.31 (Avatar)**: added a full, honest treatment of the one real, currently-open Avatar
  visual defect (ragged garment fragments during the `Wave` animation) — a genuinely
  interesting seven-round investigation that reframed the bug as rest-pose garment/body
  capsule-shell interpenetration, traced by hand to a specific, calculable collar overlap, with
  four disproven structural fixes documented alongside it.
- **Ch.10 (SpriteBatch)**: added the real D3D9-only half-pixel offset compensation (baked into
  the D3D9 backend's own projection matrix, correctly absent from shared code), with a reusable
  mutation-testing lesson: two independent test designs were both structurally incapable of
  detecting the offset's absence at all.
- **Ch.29 (GamerServices)**: added a worked example for `Guide`'s keyboard-input overlay,
  paired with a real self-correcting-audit story — an earlier "complete" phase's own sign-off
  had understated four genuine gaps, found and fixed the same day by an independent
  post-completion audit.
- **Ch.42 (Migration Guide)**: cross-referenced the `maxGamers`=69 finding (from the first
  batch) as a second concrete porting gotcha.

Every edit was rebuilt, checked for undefined/duplicate-label errors, and
PNG-rendered/visually verified before committing; 6 commits went to `develop` this batch, each
pushed immediately (`git log --oneline -20` on `develop` shows the whole run in order).

## The single most valuable technique across both batches — READ THIS FIRST if continuing

**Re-verifying an already-cited tracked-doc claim against live source finds real, valuable
corrections far more reliably than hunting a chapter's newest plan-doc phase for brand-new
material.** Across both batches this session, the large majority of additions were this shape:
a chapter already correctly cited a doc/task number describing something as broken/%
unimplemented/still-open — re-reading the actual current `.cpp`/`.hpp` directly (never the doc
a second time) found the underlying code had since been fixed, superseded by a later task
number the tracking doc or the chapter's own prior pass was never updated to reflect. This
project has now hit this exact meta-pattern well over a dozen times across totally separate
subsystems and sessions — treat it as a structural property of this codebase's pace of change
outrunning its own docs, not a coincidence, and mine for it deliberately:

1. Find a chapter's own "confirmed broken" / "not yet fixed" / "still open" claim that cites a
   specific task number or doc (`docs/rendertarget-support.md`, `docs/easygl_bugs.md`,
   `plan_net.md`'s own phase write-ups, etc.).
2. Grep the relevant backend/class's own live `.cpp`/`.hpp` for that exact task number or the
   method/feature name directly.
3. If the task number appears in a comment that also names a *later* task number (e.g.
   `"Task 871 ... CLOSED"`, `"(closes Task 873)"`), that is very strong evidence the original
   claim is now stale — read the surrounding code to confirm the fix is real and get the
   precise mechanism.
4. **Check every backend/class named in the original claim, not just one** — this session
   found splits where some were fixed and others weren't (Ch.14's `ReferenceStencil`: BGFX
   fixed, EasyGL not), and cases where all were fixed at once (Ch.9/14/17's `ClearOptions::%
   Stencil`, all three hardware backends). Getting the exact split right, not rounding to
   "mostly fixed," is the whole point.
5. **A correction to one chapter's claim often needs propagating to 2–4 places**: the
   chapter's main prose statement, any worked-example reasoning built on top of it, and
   sometimes other chapters that cite the identical claim (this session: Ch.9→Ch.14→Ch.17 for
   the Stencil fix; Ch.11→Ch.20 the session before). Grep sibling chapters for the same task
   number or claim before considering a correction complete.
6. A chapter can also be self-correcting in its own history: this session found a case
   (Ch.29/`Guide` keyboard input) where a project doc explicitly recorded that an *earlier
   phase's own* "complete" sign-off had understated real gaps, later caught by an independent
   post-completion audit of the same feature. That is a genuinely different, also-valuable
   shape worth watching for — not "the chapter is stale," but "the project's own history has an
   honest correction story worth retelling."
7. Watch your own arithmetic while writing a correction: verify any specific number (an enum's
   member count, a percentage, a task count) by counting/reading it directly rather than
   estimating, even inside a correction you are otherwise confident about — this session
   corrected its own draft mid-edit on exactly this point more than once.

## What is NOT yet done — the natural next body of work

**No task is currently active or blocked.** Good next candidates for a further pass, still
meaningfully below their page targets (rough `wc -l`-based line counts, see `PLAN.md`'s own
per-chapter table for the precise `~N of ~M pages` estimate after every edit): Ch.7 Math
(still the largest chapter by far — four+ sessions of prior work, read its own PLAN.md row
before adding more, it may be genuinely saturated), Ch.21 WebGPU, Ch.36 EasyGL Deep Dive,
Ch.43 Blupi Case Study, Ch.8 Content and Assets, Ch.27 Media, Ch.28 Devices and Sensors,
Ch.33 Sharp Runtime Overview, Ch.46 Project Practice, Ch.47 Testing Philosophy, Ch.48 Roadmap,
and any appendix (B–F all still well under their modest 15–25-page targets).

No `TaskCreate` entries exist yet for a further batch — create them following the same
one-task-per-chapter pattern used across every batch so far if picking this up.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check.** Always
  rebuild, locate the chapter's physical page range via `pdftotext -f N -l N`, render to PNG via
  `pdftoppm -png -f N -l N -r 120`, and actually read the rendered pages.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_` boundaries, 1–2 rounds max. (2) Restructure the sentence into shorter
  independent clauses — the most reliable fix nearly every time. (3) Split a combined
  `\description` `\item[...]` label into two items. (4) Restructure code itself inside
  `lstlisting` (`\allowbreak{}` doesn't apply there). (5) `\section[short]{long}` for a
  running-header/folio collision (hit again this session on Ch.42's Step 4 title).
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`; reserve
  real `\times` for actual math-mode content (inside `$...$`).
- **A heavily-worked chapter can still hide undiscovered pre-existing overfull-hboxes** — don't
  assume a well-covered chapter is layout-clean; render and check it the same as any other.
- **Always verify a specific method/property name, enum member count, or task-status claim
  against the real header/source before finalizing new text.**
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
