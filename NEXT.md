# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last commit: **355 pages, 0 undefined references, 0
duplicate-label warnings** (re-verify — run `make book` and grep the log — before trusting
this number in a future session; grep the log with `grep -i "Warning.*undefined\|undefined
reference\|undefined control"` and `grep -i "multiply defined\|multiply-defined"`, both of
which *are* reliable — see "Reusable findings" below for why a plain `grep -i undefined` can
false-positive on ordinary prose containing the word).

**Milestone this session: Appendices B–F finished (tasks #42–46), then a third depth pass
started and ran through twelve chapters (tasks #47–57)**, continuing the same standing
autonomous authorization from prior sessions. The third pass targeted the chapters furthest
below their page targets in absolute terms. Twelve chapters/appendix-pairs got a real,
source-grounded addition each:

- **Ch.22 (Direct3D Backends)**: `RenderTargetCube` MSAA + a real D3D11-vs-D3D12 mip-chain
  generation architecture divergence (native GPU call vs. explicit CPU box-filter round trip).
- **Ch.13 (Stock Effects)**: corrected a stale claim — `preferPerPixelLighting`/%
  `specularEnabled` are no longer "ignored by every backend except D3D9"; 7 of 9 backends now
  honor the real per-vertex-lit default (`plan_graphics.md` Phase 80).
- **Ch.30 (Networking)**: found the chapter's *own opening worked example* was misleading —
  `NetworkSession::Create(..., maxGamers=8)`'s `maxGamers` is silently never honored (real,
  FNA-faithful hardcoded `69`).
- **Ch.9 (GraphicsDevice)**: `Clear(ClearOptions::DepthBuffer, ...)` silently no-ops instead of
  throwing on a backend with no depth buffer; `GraphicsCapability::DepthStencilBuffer` is a
  third "declared but never wired" capability (same shape as the already-documented
  `MultipleRenderTargets` gap).
- **Ch.25 (Input System)**: `Game::IsActive` never toggled on desktop Alt-Tab focus changes for
  a real stretch of this project's history (only mobile background/foreground was handled) —
  now fixed; paired with the input-state-retention policy question the fix resolved.
- **Ch.19 (Vulkan Backend)** and **Ch.18 (EasyGL Backend)**: `docs/rendertarget-support.md`
  claims mip generation/MSAA/`Viewport` GPU wiring were unimplemented on Vulkan and BGFX (and
  `Viewport` on EasyGL) — all confirmed already fixed by reading each backend's live `.cpp`.
- **Ch.11 (Textures/Render Targets) + Ch.20 (BGFX Backend)**: the biggest correction this
  session — four of `docs/rendertarget-support.md`'s original five per-backend divergences
  (Tasks 877–881: depth/stencil fidelity, mip generation, MSAA, Viewport wiring, the MRT
  4-target cap) are fixed, plus BGFX's own wrong-handle-cast `RenderTargetCube` bug (Ch.20 had
  a whole section saying "Not yet fixed" for a bug closed by Task 907). Rewrote Ch.11's central
  render-target section and Ch.20's dedicated diagnosis section.
- **Ch.12 (Models and Meshes)**: the chapter's *own headline "two loaders" claim* was stale —
  the `.model.json` loader no longer welds every mesh onto one synthetic root bone (Task 937:
  real per-mesh `ModelBone` via `AddChild()`), `Model.Tag` now carries real skeleton/animation
  data, and "zero test coverage" is no longer true.
- **Ch.26 (Audio System)**: added a third real numeric audio bug — `Pitch`'s conversion to a
  playback-rate ratio was linear, not FNA's real exponential `2^pitch` curve, for a real
  stretch of history (agreed with the correct formula only at pitch ∈ {-1,0,1}, which is
  exactly why no existing test caught it).
- **Ch.14 (State Objects)**: BGFX now has a real `SetReferenceStencil` override (Task 764) —
  the chapter said this was broken on both EasyGL and BGFX; only EasyGL still is.

Every edit was rebuilt, checked for undefined/duplicate-label errors, and
PNG-rendered/visually verified before committing; 12 commits went to `develop`, each pushed
immediately (`git log --oneline -20` on `develop` shows the whole batch in order).

## The single most valuable technique this session — READ THIS FIRST if continuing the third pass

**A third-pass mining attempt is much more likely to strike gold by re-verifying an already-cited
tracked-doc claim against live source than by hunting a chapter's newest plan-doc phase for
brand-new material.** Nearly every finding above (10 of 12) was this shape: the chapter already
correctly cited a doc/task number describing something as broken/unimplemented — re-reading the
actual current `.cpp`/`.hpp` directly (not the doc, not the chapter's own prior claim) found the
underlying code had since been fixed, superseded by a later task number the tracking doc was
never updated to reflect. This is the same "stale status" meta-pattern this book has now hit
independently *at least a dozen times* across totally separate subsystems and sessions — it is
clearly a structural property of this codebase's own pace of change outrunning its docs, not a
coincidence. The recipe that worked repeatedly this session:

1. Find a chapter's own "confirmed broken" / "not yet fixed" / "still open" claim that cites a
   specific task number or doc (`docs/rendertarget-support.md`, `docs/easygl_bugs.md`, etc.).
2. Grep the relevant backend's own live `.cpp`/`.hpp` for that exact task number or the
   method/feature name directly — do not re-read the doc a second time and trust it again.
3. If the task number appears in a comment that also names a *later* task number
   (`"Task 878/879 (closes Task 873)"`, `"Task 903"`, `"Task 907"`, `"depthFormat (Task 877) now
   gets true per-instance fidelity (Task 911)"`), that is very strong evidence the original claim
   is now stale — read the surrounding code to confirm the fix is real and get the precise
   mechanism, not just that *a* later task touched the area.
4. **Check every backend named in the original claim, not just one** — this session found cases
   where two of three backends were fixed and one wasn't (Ch.14's `ReferenceStencil`), and cases
   where all three were fixed (Ch.11's Task 878/879/880/881). Getting the per-backend split
   precisely right is exactly the kind of specific, checkable claim this book's own methodology
   promises over rounding off to "mostly fixed."
5. **A finding that corrects one chapter's own claim often needs fixing in 2–3 places**: the
   chapter's main prose statement, any worked-example caveat built on top of it, and sometimes a
   *different* chapter that cross-references or duplicates the same claim (Ch.11 → Ch.20 this
   session; Ch.19 → Ch.18 the session before). Grep sibling chapters for the same task number or
   claim before considering a correction complete.
6. Watch for a corollary risk while writing the correction itself: don't overclaim scope. This
   session caught its own draft asserting "an eight-entry enum" without having counted it (it was
   right, but only after actually counting) and initially miscounted a "five-entry enum" that was
   actually eight — always verify a specific number (an enum's member count, a percentage, a task
   count) by counting/reading it directly rather than estimating, even inside a correction you are
   confident about.

## What is NOT yet done — the natural next body of work

**No task is currently active or blocked.** The third pass (tasks #47–57) covered the highest
absolute-gap chapters identified last session; **most chapters in the book, including several
just touched this session, remain well below their page targets still** (page counts below are
from `wc -l` on each `.tex` file, a rough proxy — see `PLAN.md`'s own per-chapter table for the
precise "~N of ~M pages" estimate after every edit). Continuing the third pass is exactly the
same recipe as tasks #24–46 used, now sharpened by the "re-verify a tracked claim against live
source" technique above. Good next candidates, still meaningfully below target after this
session: Ch.7 Math (still the largest chapter by far, ~34/110 pages, four+ sessions of prior
work — read its own PLAN.md row before adding more, it may be genuinely saturated), Ch.21
WebGPU, Ch.10 SpriteBatch, Ch.17 SDL_Renderer, Ch.29 GamerServices, Ch.31 Avatar, Ch.46 Project
Practice, Ch.47 Testing Philosophy, Ch.48 Roadmap, and any appendix (B–F all still well under
their modest 15–25-page targets even after this session's first pass).

No `TaskCreate` entries exist yet for a further batch — create them following the same
one-task-per-chapter pattern tasks #24–57 used if picking this up.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check.** Always
  rebuild, locate the chapter's physical page range via `pdftotext -f N -l N`, render to PNG via
  `pdftoppm -png -f N -l N -r 120`, and actually read the rendered pages.
- **`grep -i undefined main.log` can itself false-positive** — this session hit a real instance:
  ordinary running prose containing the word "undefined" (e.g. "...address, undefined
  behavior...") matched the naive grep. Use `grep -i "Warning.*undefined\|undefined
  reference\|undefined control"` instead, which only matches LaTeX's own real warning/error
  phrasing.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_` boundaries, 1–2 rounds max. (2) Restructure the sentence into shorter
  independent clauses — the most reliable fix nearly every time. (3) Split a combined
  `\description` `\item[...]` label into two items. (4) Restructure code itself inside
  `lstlisting` (`\allowbreak{}` doesn't apply there). (5) `\section[short]{long}` for a
  running-header/folio collision.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — this session hit a real compile failure from `\texttt{...pitch{\times}0.5...}`.
  Use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`; reserve real `\times` for
  actual math-mode content (inside `$...$`).
- **A heavily-worked chapter can still hide undiscovered pre-existing overfull-hboxes** — don't
  assume a well-covered chapter is layout-clean; render and check it the same as any other.
- **Always verify a specific method/property name, enum member count, or task-status claim
  against the real header/source before finalizing new text** — this project has repeatedly
  caught plausible-but-wrong guesses and stale counts before commit. Grep the header every time.
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
  later in the same document is fine — LaTeX's two-pass compile resolves it — but you must add
  the `\label{}` at its own definition site if one doesn't already exist there.
- Run the project's spacing-fix regex on every touched file before rebuilding:
  `python3 -c "import re; p='PATH'; t=open(p).read(); n=re.sub(r'\}/(\\\\texttt\{|\\\\cnaclass\{)', r'} / \1', t); open(p,'w').write(n) if n!=t else None"`
  — then manually grep for the `}/%` newline-continuation variant, which the regex doesn't
  catch (that variant is usually intentional and correct as-is; only fix it if it's actually
  producing a visible overflow).
- No task is currently blocked/`needs_human`. If a genuine architectural ambiguity comes up in
  future work, mark it clearly here and in `PLAN.md`'s session log, and continue with other
  independent work rather than stalling.
