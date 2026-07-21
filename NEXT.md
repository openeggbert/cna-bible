# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last commit: **347 pages, 0 undefined references, 0
duplicate-label warnings** (re-verify — run `make book` and grep the log — before trusting
this number in a future session; grep the log with `grep -i undefined` and
`grep -i "multiply defined"`, both of which *are* reliable, unlike `grep -i overfull`, which
is not — see "Reusable findings" below).

**Milestone reached this session: every task on the active list (#24–#41) is now complete.**
This was one long, continuous autonomous session (explicitly authorized start-to-finish by
the project owner, no further questions asked per that authorization) that ran a **depth
pass** — a second, deeper touch adding real worked examples and findings — across every
single chapter in the book that had not already received one: all of Parts I–IV (chapters
1–24, plus Appendix A) and all of Parts V–IX (chapters 25–48). Two chapters were checked and
found already thoroughly covered from very recent prior work, with no edit needed (Ch.25, 35,
39, 44); one chapter was checked and found **explicitly frozen by author decision** and
correctly left alone (Ch.37 — "stays marginal, do not expand," confirmed 2026-07-20, see its
own PLAN.md row). Every other chapter got at least one genuine, source-grounded addition, and
every single edit was rebuilt, checked for undefined/duplicate-label errors, and
PNG-rendered/visually verified before committing. 47 commits went to `develop` this session,
each pushed immediately after verification (`git log --oneline -50` on `develop` shows the
whole session in order if you want the detailed trail).

## What is NOT yet done — the natural next body of work

**No task is currently active or blocked.** The most natural next steps, in rough priority
order:

1. **Appendices B–F** (Feature Matrix, Glossary, Repo Map, NOXNA Catalog, API Quick Reference:
   Ecosystem/Platforms) have never had a depth pass at all this expansion cycle — see
   `PLAN.md`'s own appendix table, all five rows say "Not started." Each has a modest
   15–25-page target and is already a reasonable size (58–155 lines), so this is a
   moderate, well-scoped body of work, not a large one. No `TaskCreate` entries exist for
   these yet — create them if picking this up, following the same one-task-per-chapter
   pattern tasks #24–41 used.
2. **Every chapter in the book is still meaningfully below its own page target** — depth
   passes so far have added real, valuable content, but the per-chapter session log in
   `PLAN.md` shows most chapters are still at roughly 10–30% of their stated target (e.g.
   Ch.7 Math ~34/110 pages, Ch.26 Audio ~10/60, Ch.30 Networking ~8/70). A **third pass**
   across the whole book, using the exact same "find one more real, grounded gap per
   chapter" methodology, remains available as an essentially unbounded source of further
   legitimate work — this is not a sign anything was done wrong; the original page targets
   were always aspirational multi-session goals, not a single-pass expectation.
3. If resuming the depth-pass style of work on any already-once-or-twice-touched chapter,
   the "newest plan doc" technique below is the fastest way to find genuinely fresh material
   rather than re-deriving already-covered ground.

## The single highest-value technique discovered this session

**For any chapter about a specific CNA subsystem or sibling repo, check that repo's own most
recently dated planning/audit document before assuming a chapter is already exhaustively
covered.** This found real, substantial, previously-uncovered material in nearly every
chapter it was tried on (Ch.26–32, 36, 38, 40, 42, 43, 45, 46, 47, 48 — over a dozen
instances), even in chapters that already looked thorough. The recipe:

1. Find the newest plan/audit doc for the chapter's subsystem:
   `ls /rv/data/development/github.com/openeggbert/cna/plan_*.md` (or `NEXT.md`/`AUDIT.md` at
   the root of `cna` or the relevant sibling repo — `sharp-runtime`, `easy-gl`, `free-direct`,
   `cna-samples` each have their own).
2. Check dates: `grep -o "2026-[0-9-]*" plan_X.md | sort -u | tail -5`, or just read the tail
   of the phase/section outline (`grep -n "^#\|^##" plan_X.md | tail -20`) — the newest phase
   is usually the least likely to have been mined yet.
3. Read that newest phase/section for a concrete, real, dated finding — ideally with real
   before/after numbers or a named test, not just a description.
4. Grep the book chapter for whether that specific finding is already mentioned. **Watch
   out: LaTeX escapes underscores as `\_`, so grepping for `result_u64` will silently miss
   `result\_u64` in the source — search for the term with the escape accounted for, or use a
   looser pattern.** If genuinely absent, it is very likely a fresh, addable gap.
5. Before asserting a "still open" claim from an older doc as current fact, **grep the actual,
   current source directly** — three separate times this session an external doc's "still
   broken" framing turned out to already be fixed in the live source (Ch.18 EasyGL's two
   oracle bugs, Ch.45's `GraphicsDevice::Clear(Color)` depth-buffer bug), and once a `CLOSED`
   status hid a second, deeper bug only a fresh sanitizer run had caught (Ch.28's Android
   TSan finding, structurally the same lesson from the opposite direction). Ch.46 and Ch.48
   both now cite this recurring pattern explicitly as a closing methodological observation —
   worth reading if you want the full write-up rather than just this summary.
6. **Always check `PLAN.md`'s own row for a chapter before editing it.** Ch.37 is a real,
   live example of an explicit author scope cap ("do not expand") that must be honored, not
   treated as just another under-target chapter — this is not hypothetical, it happened this
   session.

## Reusable technical/mechanical findings from this session

- **PNG-rendering the affected pages remains the only reliable overflow check.**
  `grep -i overfull main.log` is proven unreliable in both directions this project — it
  missed real, visible overflows repeatedly, and separately, `grep -a "verfull"` (accounting
  for binary-detection false negatives in a plain `grep -i`) revealed hundreds of pre-existing
  "overfull" log lines that plain `grep -i` was silently missing entirely. Always rebuild,
  locate the chapter's physical page range via `pdftotext -f N -l N`, render to PNG via
  `pdftoppm -png -f N -l N -r 120`, and actually read the rendered pages.
- **Overflow-fix technique, in order of what actually worked this session:** (1) For a long
  identifier in prose, try `\allowbreak{}` at camelCase/`::`/`_` boundaries, 1–2 rounds max.
  (2) If that doesn't resolve it, restructure the sentence into shorter independent clauses —
  this was the more reliable fix nearly every time it was tried. (3) For a `\description`
  list `\item[...]` label combining two full method signatures (e.g. `A(...)  / B(...)`),
  split into two separate `\item` entries rather than fighting the label width — bold item
  labels are wider than equivalent body text and overflow sooner. (4) For a too-long single
  line *inside* an `lstlisting` code block (a long ternary, a long trailing `//` comment),
  restructure the code itself (ternary → if/else; trailing comment → its own comment line
  above the code) — `\allowbreak{}` does not apply inside `lstlisting`. (5) For a running-header
  vs. page-number folio collision on a long `\section{}` title, use
  `\section[short title]{long title}` — the short form goes in the header, the long form
  stays in the body and TOC.
- **A heavily-worked chapter can still hide undiscovered pre-existing overfull-hboxes** —
  six were found in one ~150-line span of Ch.9 alone, despite that chapter's own PLAN.md
  history describing multiple prior dedicated sessions. Don't assume a well-covered chapter
  is layout-clean; render and check it the same as any other.
- **Always verify a specific method/property name against the real header before finalizing
  a worked example, even for "obvious" names** — this session caught and fixed several
  plausible-but-wrong guesses before commit: `TimeSpan::operator+=` (doesn't exist, only
  `operator+`), a `RenderTargetBinding`-taking `SetRenderTarget` overload (doesn't exist; the
  real overload takes `RenderTargetCube*, CubeMapFace` directly), `Device::set_uniform_1f`
  (doesn't exist on `easy-gl`'s `Device`; the real method is `Program::set_uniform`,
  overloaded not suffix-named), `AvatarRenderer::setAmbientColorEXTProperty` (doesn't exist;
  the real name is `setAmbientLightColorProperty`). This is a real, recurring risk category
  for this kind of writing, not a one-off — grep the header every time.
- **A numerical discrepancy between two sources doesn't always mean one is wrong** — Ch.43
  found two audits of the same two-game codebase reporting very different `BltFast` call
  counts (6/5 vs. 18/17); independently re-grepping the real source confirmed *both* numbers
  were correct, just scoped to different questions (real DirectDraw-interface calls vs. every
  raw occurrence including each game's own wrapper method). Resolve an apparent contradiction
  by re-deriving both numbers yourself before assuming either source is stale.

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log for `undefined` and
  `multiply defined`/`multiply-defined` every time — these two checks are reliable.
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed in this
  environment.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`)
  live at `/rv/data/development/github.com/openeggbert/<name>` in this environment — not
  `/workspace`. `free-eggbert`/`planetblupi` (the two real target games `free-direct` was
  built against) are also mirrored read-only under `/rv/data/library/github.com/openeggbert/`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`), never assume printed page N is
  physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Run the project's spacing-fix regex on every touched file before rebuilding:
  `python3 -c "import re; p='PATH'; t=open(p).read(); n=re.sub(r'\}/(\\\\texttt\{|\\\\cnaclass\{)', r'} / \1', t); open(p,'w').write(n) if n!=t else None"`
  — then manually grep for the `}/%` newline-continuation variant, which the regex doesn't
  catch (that variant is usually intentional and correct as-is; only fix it if it's actually
  producing a visible overflow).
- No task is currently blocked/`needs_human`. If a genuine architectural ambiguity comes up in
  future work (not "which chapter to do next," which is not one), mark it clearly here and in
  `PLAN.md`'s session log, and continue with other independent work rather than stalling.
