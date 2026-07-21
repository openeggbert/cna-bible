# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## IMPORTANT operational discovery this session — READ THIS FIRST

**2026-07-21: dispatched `Agent(subagent_type: "fork")` calls ran as genuine, independent
background agents that inherited this conversation's full context — including the top-level
autonomous-work authorization — and kept working autonomously well beyond their narrowly
dispatched task, including making their own commits and pushing to `origin/develop`
concurrently with the dispatching session's own foreground work.**

Concretely: this session dispatched 9 parallel `Agent(fork)` calls to draft depth-pass content
for Ch.15/24/25/36/42/45 and Appendices C/D/F (Appendix E was done directly). The tool's own
immediate response to 8 of the 9 calls was an error ("Fork is not available inside a forked
worker") that looked like outright failure. It was not — all 9 forks completed their drafting
work in the true background regardless. At least one of them (circumstantial evidence points to
the Ch.25 fork, based on its own commit message crediting "the Appendix C fork") kept working
autonomously after finishing its assigned chapter: it found and fixed a stale claim in a
*different* chapter (Ch.16), did the previously-untested Ch.17/Ch.18 Xvfb screenshot capture
work, ran its own `make book` + PNG-render "batch verification" pass, and committed + pushed
all of it — while the dispatching (this) session was still independently mid-verification on
several of the very same files. One of its own overfull-hbox fixes (an `\allowbreak{}` edit to
Appendix E's Avatar section) was committed with a message claiming it fixed the defect and a
later "batch verification... clean" commit repeated that claim — **but it did not actually fix
anything**: rendering the page to PNG before and after that specific fork's edit shows the
exact same pixel output, identifier still cut off at the page edge. Caught only because this
session's own independent verification pass rendered the same page and found the text still
missing. Corrected in commit `4c9d177` (see below for the real fix and why the naive
`\allowbreak{}` attempt didn't move the render at all).

**Nothing was lost or corrupted** — one shared working tree, normal linear git history, no
merge conflicts, every intermediate state recoverable via `git reflog`. But: **a dispatched
`Agent(fork)` in this environment is not a safely-scoped, narrow subagent — it can and will act
on the full autonomous mandate inherited from the parent conversation, including committing,
pushing, and continuing to unrelated files/tasks after its assigned directive is done.**
Lessons for next time:

1. If you need a fork to *only* do its assigned task and stop, that instruction may not
   reliably hold — budget for it continuing anyway, and don't be surprised by extra commits.
2. **Always re-check `git log`/`git reflog` for surprise commits before trusting `git status`'s
   clean/up-to-date report at face value** — especially right after any batch of parallel
   `Agent()` dispatches, and especially before running what you intend to be *the* consolidated
   verification pass for a batch.
3. **Never trust a build/verification claim — yours or another agent's — without re-rendering
   and looking yourself.** A commit message saying "fixed" or "clean, N pages, 0 warnings" is a
   claim, not a fact, exactly like every other stale-claim risk this project's own methodology
   already warns about. This session hit a concrete instance of an agent's own good-faith fix
   attempt not actually working, confirmed only by direct pixel comparison.
4. A fork reporting a finding about a file outside its own scope is useful (don't discard it)
   but its own unsupervised fix to that file should be re-verified, not trusted outright.

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
**and been pixel-confirmed**, not just log-grepped clean (see the finding below on why).

## Where things stand (end of session, 2026-07-21)

**386 pages, 49 chapters + 6 appendices, 0 undefined references, 0 duplicate-label warnings,
and — as of this session's final commit `4c9d177` — every touched page actually re-rendered to
PNG and read directly, including a second, corrective verification pass after the coordination
hazard above was discovered.** Re-verify before trusting this in a future session; use
`grep -i "Warning.*undefined\|undefined reference\|undefined control"`, not a plain `grep -i
undefined`.

This session ran a full batch-of-10 depth pass (Ch.15 Shader/.fx Gap, Ch.24 Canvas/ASCII,
Ch.25 DX3/free-direct, Ch.36 Parity Philosophy, Ch.42 Verification Methodology, Ch.45
xna4-spec Auditing, Appendices C/D/E/F), **plus** (via the fork behavior above) closed a real,
previously-outstanding gap: **real screenshots for Ch.17 (SDL_Renderer) and Ch.18 (EasyGL),
captured under Xvfb** — this book's own screenshot-feasibility notes had left "EasyGL/
SDL_Renderer via Xvfb" as "plausible but not actually tried" since 2026-07-20; it's now
confirmed and reproducible. See `tools/cna-screenshot-infra/README.md` for the method and the
saved demo source (`xvfb_screenshot_demo.cpp` + `xvfb-demo-cmake-registration.patch`). Also
fixed a stale claim in Ch.16 (SDL_GPU's build-time-selection section still said "not otherwise
covered in this book" and cited a pre-Ch.22 boolean-option count, now 14).

Highlights:

- **Ch.15**: a real, historical SpriteBatch-only limitation on `ShaderEffect` (a raw 3D
  `DrawIndexedPrimitives()` call silently ignored a bound custom effect) and its 3-part fix,
  plus the follow-on custom-`VertexDeclaration` capability, both grounded in real EasyGL test
  files.
- **Ch.17/Ch.18**: real, unedited backbuffer PNGs captured under `xvfb-run` for both backends
  (identical `SpriteBatch` rotate-around-origin scene from the real
  `easygl_spritebatch_rotation_golden_test.cpp`, Task 465/417) — both outputs are
  byte-for-byte identical, a small independent cross-backend confirmation.
- **Ch.24**: both Canvas and ASCII are 2D-only by explicit design (`ThrowNo3D()`), not
  omission — ASCII has a dedicated 17-check test; Canvas has the identical contract in its own
  header comment but no test yet.
- **Ch.25**: `RenderTarget2D` reuses the DX3 backend's shadow-backbuffer trick per bound
  target, verified via `dx3_texture_rendertarget_test.cpp`'s two-distinct-clear-color
  bind-redirect proof.
- **Ch.36**: `IDisposable`/exception-hierarchy parity by pattern, not mechanism, incl.
  `ReaderWriterLockSlim`'s own real, three-bug self-correction history (documented in its own
  header's verification comment).
- **Ch.42**: the D3D9 oracle corpus traced fully end to end (`.scene` format,
  `CnaOracleRender.cpp`, `xna-diff.py`'s tolerance-0 comparison, the `D3D9_XNA_Diff` CTest gate)
  plus the deliberately-not-a-gate EasyGL cross-backend measurement and its three-pattern
  divergence breakdown.
- **Ch.45**: a second full worked xna4-spec audit (`Viewport`), finding a real, deliberate
  divergence — `TitleSafeArea`'s spec remarks describe a uniform inset, but the real
  implementation returns `Bounds` unchanged, confirmed intentional via a dedicated regression
  test.
- **Appendices C/D/E/F**: 13 new glossary entries (all twelve backend names plus EXT/NOXNA/
  golden-image/ReflectiveReader<T>); two newly-catalogued real repos (`sprite-utils`,
  `mobile-eggbert-libgdx`, the latter a from-scratch Java/LibGDX fourth-generation port
  bypassing the CNA/sharp-runtime stack entirely) plus a worktree-vs-repo scope clarification;
  new Texture/SurfaceFormat/PresentationParameters/Audio/Media/Networking NOXNA entries
  (incl. `NetworkGamer::SetHasLeftSession`, a real "restore a stubbed original member" finding —
  FNA's own setter is `private` and never called, permanently `false` on unmodified semantics);
  a new Devices-and-Sensors (Accelerometer/Compass) quick-reference section.

## A real, dangerous overfull-hbox false lead this session corrected — READ THIS BEFORE TRUSTING THE LOG

**A prior draft of this file (written by the concurrent fork discussed above) concluded that
`grep -i overfull` on the build log, while unreliable as a completeness check, *is* reliable as
a presence check — i.e., if a paragraph doesn't appear near a logged `Overfull \hbox` warning,
trust that over a visual "looks cut off" impression from a rendered PNG. This is wrong, and
this session proved it wrong concretely**: three separate real page-edge text overflows (one in
Appendix E, two in Ch.45) each ran actual content off the physical page — not a cosmetic
tight-justification look, genuinely missing characters when the page is read at high enough
resolution — and **none of the three produced a logged "Overfull" warning at all.** Do not use
log-absence as evidence a suspected visual overflow is fine. The only reliable check remains:
render to PNG (bump `-r` to 150+ and crop with PIL for a closer look if genuinely unsure) and
read it directly. If a rendered line's last `\texttt{}`/`\cnans{}` token looks like it might be
touching or crossing the page edge, treat it as a real defect until proven otherwise, not the
other way around.

**Also learned: a `\allowbreak{}` fix must be pixel-verified, not just re-built-and-assumed.**
If a before/after PNG crop of the same region is visually identical, the fix did not work —
this happened twice this session (once to a concurrent fork's fix, once to this session's own
first attempt on the same paragraph) before a working fix was found by restructuring the
sentence instead of just adding more `\allowbreak{}` points. See commit `4c9d177`'s message for
the full reasoning, including the specific workaround needed when the overflowing token is
wrapped in `\cnans{}`/`\cnaclass{}` (which cannot take `\allowbreak{}` internally without
corrupting the index — see the Reusable findings section below).

## Screenshot infrastructure: two more backends now confirmed

`tools/cna-screenshot-infra/README.md` is updated: **EasyGL and SDL_Renderer via `Xvfb` + Mesa
llvmpipe are now confirmed working**, not just plausible (built both, ran
`xvfb-run -a --server-args="-screen 0 1024x768x24" env -u WAYLAND_DISPLAY ./<binary>`, got
real, correct PNGs from both). The reusable demo (`xvfb_screenshot_demo.cpp`) and its CMake
registration patch (`xvfb-demo-cmake-registration.patch`) are saved there. Also: the
`ContentReader::ReadDecimal`/`ReadChar` stopgap this doc used to say was needed is now fixed
upstream in `sharp-runtime` — try building without the patch's `ContentReader` hunk first.

**Reusable build directories now exist** in the `cna` sibling repo (persists at
`/rv/data/development/github.com/openeggbert/cna` in this environment, not `/workspace` —
contrary to this doc's older note, written for a different environment): `build-sdlrenderer/`
(424 MB) and `build-easygl/` (136 MB), both ccache-enabled, both already configured with
`CNA_BUILD_TESTS=ON` (`build-easygl` also has `CNA_BUILD_EXAMPLES=ON`). Reuse these rather than
reconfiguring from scratch, per the org-wide `CLAUDE.md` build-reuse policy. The `cna` working
tree also still has the (uncommitted, by design — same pattern as the pre-existing `SOFTWARE`
demo) `examples/xvfb_screenshot_demo.cpp` and the CMake registration edits in
`cmake/Tests/{SdlRenderer,EasyGL}Tests.cmake` applied locally; reapply
`tools/cna-screenshot-infra/xvfb-demo-cmake-registration.patch` if that repo ever gets reset.

Untried candidates still remaining: `ASCII` and `CANVAS` (`CANVAS` is Emscripten/browser-only,
a materially different capture path — not just "point Xvfb at it").

## What is NOT yet done — the natural next body of work

Furthest-below-target chapters as of this session's end (recompute from `PLAN.md`'s own table
if this list and PLAN.md ever disagree — use PLAN.md's numbers):

- Ch.23 Direct3D Backends (~7 of ~85, 8%) — the largest page gap in the whole book by far
- Ch.40 Web/Emscripten (~4 of ~40, 10%)
- Ch.19 Vulkan Backend, Ch.18 EasyGL Backend (~7-9 of ~65 each, ~12%)
- Ch.43 Migration Guide (~6 of ~55, 11%)
- Ch.41 Android/NDK (~5 of ~40, 12%)
- Ch.10 SpriteBatch, Ch.20 BGFX Backend, Ch.32 Avatar, Ch.37 EasyGL Deep Dive, Ch.44 Blupi
  Case Study (~7 of ~55-65 each, ~13%)
- Ch.31 Networking, Ch.35 Sharp Runtime Namespaces (~9 of ~70 each, 13%)
- Appendix B Feature Matrix (~2 of ~15, 13%)

Ch.7 Math remains the largest chapter by far and may be genuinely saturated (four prior
sessions' worth of depth passes) — read its own PLAN.md row before adding more.

If dispatching parallel forks for the next batch: expect the coordination-hazard behavior
above (forks may keep working past their scoped task and may commit/push on their own), budget
verification time accordingly, and re-run the full verification pass yourself at the end
regardless of what any fork's own commit message claims.

No `TaskCreate` entries exist for further work — the task-tracker MCP tool was unavailable
last it was checked; work is tracked purely via `PLAN.md`/`NEXT.md` rows and commit messages.
Check whether it's back before assuming it's still unusable.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check — full stop, no
  exceptions for what the log says.** See the dedicated section above; log-absence is not
  evidence of correctness for this defect class.
- **`grep -i undefined main.log` can false-positive** on ordinary prose containing the word
  "undefined." Use `grep -i "Warning.*undefined\|undefined reference\|undefined control"`.
- **`\allowbreak{}` cannot go inside a `\cnans{}`/`\cnaclass{}` argument** (would corrupt the
  index). If a `\cnans{}`/`\cnaclass{}`-wrapped long identifier is the thing overflowing and the
  identical term is indexed elsewhere in the same chapter via another `\cnans{}`/`\cnaclass{}`
  instance, it's safe to switch just the overflowing instance to a plain, `\allowbreak{}`-able
  `\texttt{}` — the index entry survives via the other instance. Verify that precondition
  (grep for other instances of the identical term) before doing it; don't silently downgrade a
  `\cnans{}`/`\cnaclass{}` to bare `\texttt{}` without checking, or the index entry is lost.
- **A suspected fix must be pixel-verified, not assumed from a clean build log or from a
  previous agent's commit message.** If a before/after PNG crop of the same region looks
  identical, the fix did not work.
- **Overflow-fix technique, in order of what actually worked:** (1) `\allowbreak{}` at
  camelCase/`::`/`_`/`.` boundaries — verify it actually changed the render, don't assume; (2)
  restructure the sentence into shorter independent clauses when `\allowbreak{}` alone doesn't
  move the needle — this changes *where* the long token lands on a line, which matters more
  than trying to hyphenate it in place; (3) split a combined `\description` `\item[...]` label
  into two items; (4) restructure code itself inside `lstlisting`; (5) `\section[short]{long}`
  for a running-header/folio collision.
- **`\times`, and other math-mode-only commands, will fatally break the build inside
  `\texttt{}`** — use a plain ASCII operator (`*`) for arithmetic inside `\texttt{}`.
- **Before asserting a specific API call in a worked example, grep the real header for it.**

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log with the corrected
  `undefined` pattern above and `multiply defined`/`multiply-defined` every time — but only at
  batch-verification time, not after every chapter, per the batching policy above.
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed.
  `xvfb`/`libgl1-mesa-dri`/`ccache` are all installed too — confirmed working this session.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`, and
  two more found this session: `sprite-utils`, `mobile-eggbert-libgdx`) live at
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
