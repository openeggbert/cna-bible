# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history, and which has the full per-chapter detail this file only summarizes). If you're
reading this mid-session rather than at the start of one, it may already be stale relative to
what's happened since — trust the conversation over this file in that case.

## Where things stand right now (end of session, 2026-07-20)

**The book is a single, unified book** (merged from two volumes earlier this same session).
`latex/volume1`/`latex/volume2` no longer exist; everything is under `latex/book/`, built via
`make book` (→ `latex/book/main.pdf`). Chapters 1–24 = former Volume I (Parts I–IV, unchanged
numbering). Chapters 25–48 = former Volume II (Parts V–IX, renumbered +24). Appendices A–F.
Full renumbering table is in `PLAN.md`'s merge session-log entry.

**Part V (Ch.25-32) and Part VI (Ch.33-37) are both fully swept** — every chapter in both
parts has a first expansion pass now, except Chapter 37 (free-direct Deep Dive), which stays
explicitly frozen per the author's own 2026-07-20 confirmation ("stays marginal") — not left
incomplete, deliberately skipped. **Part VIII (Chapters 38-41) is now fully swept too** —
every chapter got a first pass this session. Full per-chapter detail (exact line counts,
headers/scripts read, every finding and example) lives in `PLAN.md`'s session log — this file
only summarizes.

The pattern nearly every chapter this session followed: read the real headers/`.cpp`/scripts
for classes or tools already named in the chapter's prose, add worked examples grounded in
real signatures, and surface at least one genuinely new verified finding per chapter — most
chapters had dense, accurate prose already and needed "add worked examples," not "add missing
coverage." Two exceptions worth remembering: Chapter 38 is tooling/verification narrative, not
a C++ API, so its worked examples are real shell invocations from the actual scripts, not code;
and Chapter 34 had a **stale PLAN.md table-row description** (said "TimeSpan/EventHandler/
Stream" but the chapter's real content is String/StringBuilder/Stream/audit-history) — check a
chapter's actual `\chapter{}` title/content against PLAN.md's own row before trusting the row.

None of the 16 chapters touched this session (25-36, 38-41) are at their final page targets
yet (roughly 3-10 of a 30-70-page target each) — this was a breadth pass, not a depth pass.
**Chapter 41 is a synthesis/comparison chapter across 38-40**, not API- or tooling-shaped, so
its pass looked different: found and closed a genuine content gap (its own comparative table
omitted macOS, a real platform confirmed in the project's own docs) rather than adding worked
examples, and fixed one genuine stale cross-reference left over from the two-volume merge
(a plain-text "Part~IV" that should have said "Part~VIII" after renumbering — a good reminder
that stale merge-era references can still be lurking anywhere, not just in the chapters
touched during the merge itself).

Volume currently compiles to **289 pages, 0 undefined references, 0 duplicate-label
warnings** (index count not re-checked this session — verify before quoting it).

### The `/`-spacing overfull-hbox defect class — three known variants, all with proven fixes

Every API/tooling-shaped chapter touched this session (25 through 36, and 38-40) has needed at
least one of these; Chapter 41 (a synthesis chapter) had none of its own to fix this pass.
Treat this as a **routine check on every batch**, not a one-off — run the Python regex pass
(`re.sub(r'\}/(\\texttt\{|\\cnaclass\{)', r'} / \1', text)`) over any file you touch before the
first build of a batch, then manually grep for `}/%` afterward (the regex doesn't catch it):

1. **Chain variant**: `\texttt{A}/\texttt{B}` (or `\cnaclass{}`) with no space around the slash
   is one unbreakable LaTeX token; long enough, it overflows the line. The regex pass fixes
   this automatically.
2. **Newline-continuation variant**: `\texttt{A}/%` followed by a newline-continued
   `\texttt{B}` — the `%` suppresses the newline's implicit space, and this does NOT match the
   regex above. Only caught by reading the actual source around any overfull warning's line
   range, or by grepping for the literal `}/%` pattern directly.
3. **Single-long-identifier variant**: even ONE very long `\texttt{}`/`\cnaclass{}`-wrapped
   identifier can cause severe, visibly-confirmed cutoff if it lands with too little remaining
   space on its line — REGARDLESS of spacing fixes around it. **The fix that works**:
   restructure so the sentence/clause containing the long identifier starts fresh (its own
   sentence, paragraph, or list-item continuation), maximizing its available line width from
   its very first character. **This variant can be lurking in PRE-EXISTING content, not just
   what you just added** — Chapter 36 this session had one in a paragraph nobody had touched
   in this expansion pass at all. When you PNG-render a chapter's pages to check your own new
   additions, read the WHOLE page, not just the part you added — you may catch an old bug for
   free.

**Verification bar, unchanged**: `grep -i overfull main.log` alone is not reliable evidence
either way. The only real verification is `pdftoppm -png -f N -l N -r 100 main.pdf
/tmp/.../pageN` (find N by content search: `pdftotext -f N -l N main.pdf - | grep <text>`,
never by printed folio number) then reading the PNG back with the Read tool.

## What to do next

1. **Move to Part IX** (Chapters 42-48): Porting/practice/roadmap — none touched yet this
   session. Same approach: read the real source before assuming whether each chapter is
   API-reference-shaped, tooling/narrative-shaped, or synthesis-shaped like Chapter 41 turned
   out to be. When a chapter doesn't fit the "add worked examples" mold, look instead for a
   genuine content gap or a stale cross-reference (Chapter 41's own pass found both: a missing
   macOS row and a leftover "Part~IV" reference from the merge).
2. **Alternatively, return to Part V, VI, or VIII for real depth**: every chapter in those
   three parts has a first pass now, but all are still well short of their page targets. Don't
   re-run the "which classes/tools exist" grep again (already done at least once per chapter)
   — look for narrower gaps instead: worked-example depth per topic, cross-checking against
   `docs/*.md`/`CHECKLIST.md`/`plan_*.md` files in the real repo for anything a first pass
   would miss.
3. **Worth a dedicated pass at some point**: grep the whole book for other stale plain-text
   "Part~N" references left over from the two-volume merge, the same class of bug Chapter 41's
   "Part~IV" turned out to be — the merge session's own renumbering pass focused on
   `Chapter~N` citations and may have missed `Part~N` ones in chapters that weren't otherwise
   touched until now.
4. **Deepen Chapter 9 (GraphicsDevice)** further, or start Chapter 13 (Stock Effects) — both
   still open Part I–IV targets, untouched for several sessions now.
5. Chapter 7 (Math and Core Types) is at ~33 of a ~110-page target after three sessions — a
   legitimate target but needs fresh gap-discovery, not a ready-made list.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value.**

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- Build: `cd latex && make book` → `latex/book/main.pdf`. Check the log for `undefined`,
  `multiply defined`/`multiply-defined`, AND `overfull` every time (see above).
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (and `/workspace/sharp-runtime`, `/workspace/easy-gl`, etc.) do not persist
  across sessions — check whether a clone already exists in the current session before
  re-cloning (this session found several already present from earlier work). If nothing
  exists and a screenshot needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`.
- After embedding any new screenshot OR any dense full-method-reference section, verify it
  actually rendered correctly by converting the relevant compiled PDF page to an image and
  reading it back (`pdftoppm` + the `Read` tool).
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`) rather than assuming printed page N
  is physical page N. A blank padding page immediately before a new Part's title page is
  normal book layout, not a rendering defect — don't mistake it for one.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Verify hand-derived numeric/algebraic claims with an actual computation before writing them
  into the book. Also double-check constructor/method/callback signatures against the real
  header before writing a worked example that calls them — reading the actual `.cpp`
  implementation (not just the header) is often where the best verified findings come from.
- Not every chapter's gap is "missing API surface," and not every chapter is even API-shaped —
  Chapter 38 is build/verification tooling narrative, where the real source is shell scripts
  and CMake files, not C++ headers; its worked examples are real command-line invocations.
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep/read the
  real source for everything it covers and diff against what the chapter's prose actually
  mentions — but once that pass is done once, a second pass on the same chapter needs a
  different angle, not the same grep repeated.
