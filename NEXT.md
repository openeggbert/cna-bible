# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history, and which has the full per-chapter detail this file only summarizes).

## Where things stand right now (end of session, 2026-07-20)

**The book is a single, unified book** (merged from two volumes earlier this same session).
Everything is under `latex/book/`, built via `make book` (→ `latex/book/main.pdf`). Chapters
1–24 = former Volume I (Parts I–IV). Chapters 25–48 = former Volume II (Parts V–IX, renumbered
+24). Appendices A–F. Full renumbering table is in `PLAN.md`'s merge session-log entry.

**Every Part from V through IX now has a first expansion pass on every chapter** — Part V
(25-32), Part VI (33-37, except Chapter 37/free-direct Deep Dive, which stays explicitly frozen
per the author's own 2026-07-20 confirmation — deliberately skipped, not incomplete), Part VII
(the same Ch.33-37 range), Part VIII (38-41), and now **Part IX (42-48) is fully swept too** —
the last chapter (48, Roadmap) finished this session. Full per-chapter detail (exact line
counts, sources read, every finding and example) lives in `PLAN.md`'s session log — this file
only summarizes the pattern and the state.

**None of chapters 25-48 are at their final page targets yet** (roughly 3-10 of a 30-70-page
target each) — every session so far has been a breadth pass (first pass on every chapter),
not a depth pass (bringing any one chapter to its full target). That is the natural next
phase of work once this file is read.

Volume currently compiles to **297 pages, 0 undefined references, 0 duplicate-label
warnings** (index count not re-checked this session — verify before quoting it).

## The reusable per-chapter pattern (validated across 24 chapters now, 25-48)

1. Read the chapter's actual current content and title (don't trust a PLAN.md row description
   at face value — it can be stale, e.g. Chapter 34's was).
2. Diagnose the chapter's "gap shape" before writing anything — it varies:
   - **API-reference-shaped** (most Ch.25-36): grep/read the real headers/`.cpp` for classes
     already named in the prose, add worked examples grounded in real signatures.
   - **Tooling/narrative-shaped** (Ch.38-40): the real source is shell scripts/CMake, not C++
     headers — worked examples are real command invocations, not code.
   - **Synthesis/comparison-shaped** (Ch.41, and partly 48): look for a genuine content gap or
     a stale cross-reference instead of "add worked examples" — Ch.41 found a missing table row
     and a leftover "Part~IV" reference from the merge; Ch.48 verified its own named gaps were
     still current by checking the live source, then expanded one gap into a real table.
   - **Methodology-described-only-in-the-abstract** (Ch.44, 46, 47): the chapter explains a
     process or convention but never actually shows one instance of it — the fix is picking one
     small real example and running the process against it end-to-end, or quoting one real
     instance almost verbatim. This turned out to be the single most common gap shape in Part
     IX — worth checking for on ANY still-abstract-only chapter in earlier Parts too.
   - **Chapter's own claim needs auditing, not just deepening** (Ch.45): when a chapter
     summarizes a body of real source material (call counts, failure counts, a percentage), it
     is worth checking that summary against the individual underlying files it was rounding up
     from — Ch.45 found the chapter's "all 23 failures share one cause" claim was measurably
     imprecise once every `missing.md` was actually read.
3. Ground every new sentence in an actual source read — clone a sibling repo fresh if it isn't
   already present in `/workspace` (check first; several ARE already cloned from earlier
   sessions: `cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
   `cna-extended`, `cna-template`, `libcna.com` — do NOT re-clone these).
4. Run the `/`-spacing proactive regex fix (below), then manually grep `}/%`.
5. Rebuild (`cd latex && make book`), grep the log for `undefined`/`multiply defined`.
6. Find the chapter's physical page range by content search (`pdftotext -f N -l N main.pdf -
   | grep <unique text>` — never trust printed folio numbers), render every page to PNG
   (`pdftoppm -png -f N -l N -r 100 main.pdf <path>`), and read each one back. Read the WHOLE
   page, not just your own new content — pre-existing defects turn up for free this way (this
   happened THREE times across Ch.44/47/48 this session alone).
7. Update PLAN.md's table row + append a session-log entry; update this file; commit; push.

## The `/`-spacing and long-identifier overfull-hbox defect classes — ALL proven fixes

This has now been the single most common defect class across every chapter touched this entire
project. Treat checking for it as routine on every batch, not optional:

1. **Chain variant**: `\texttt{A}/\texttt{B}` with no space is one unbreakable token. Fixed
   automatically by: `re.sub(r'\}/(\\texttt\{|\\cnaclass\{)', r'} / \1', text)` — run this over
   any file you touch before the first build of a batch.
2. **Newline-continuation variant**: `\texttt{A}/%` + a newline-continued `\texttt{B}` — the
   `%` suppresses the implicit space; the regex above does NOT catch it. Grep the literal
   pattern `}/%` by hand every time, separately from the regex pass.
3. **Single-long-identifier variant**: one very long `\texttt{}`/`\cnaclass{}` token can overflow
   badly even with correct spacing around it, if a full line's width would actually fit the
   token. **Fix**: restructure so the identifier becomes the first word of a fresh
   sentence/paragraph, maximizing the line width available to it.
4. **Long-URL-or-path variant** (a step further than #3 — new this session): a long
   `\texttt{}`-wrapped URL or file path (e.g. `learn.microsoft.com/.../xna/`,
   `docs/graphics-backend-feature-matrix.md`) can be so long that even a FULL fresh line won't
   fit it — restructuring the paragraph doesn't help here. **Fix**: insert `\allowbreak{}`
   after every `/`- or `-`-delimited segment inside the `\texttt{}`, giving LaTeX real break
   points inside the otherwise-atomic token. Used successfully 3 times this session (Ch.44's
   URL, Ch.48's own new content, and one incidental pre-existing instance in Ch.10 caught by
   the same filename appearing in an unrelated sentence there).

**Verification bar, unchanged and proven correct repeatedly**: `grep -i overfull main.log`
alone is NOT reliable evidence either way — both false positives (Ch.36's
`detect_common_features()`, ~25pt, confirmed rendering cleanly) and real severe defects
(Ch.44/47/48, 95-139pt) have been found this session, and the numeric magnitude alone doesn't
reliably separate them. The only real verification is rendering to PNG and reading it back.

**Do not add `\usepackage{amssymb}` or other new packages casually** — Chapter 46 hit a fatal
build error from `\checkmark` (needs `amssymb`, not loaded in this book's preamble) and fixed
it by using the plain word "done" instead. Prefer plain text over a symbol that needs a new
dependency unless there's a strong reason to add the package project-wide.

## What to do next

1. **No single obvious next target — this is a genuine decision point.** Every chapter in
   Parts V through IX has a first pass; none are at their final page target. Options, roughly
   in order of likely value:
   - **Depth pass on Parts V/VI/VIII**: these were touched earliest and are furthest from
     target (~3-10 of 30-70 pages). Don't re-run the "which classes exist" grep (done already)
     — look for narrower gaps: worked-example depth per topic, cross-checking against
     `docs/*.md`/`CHECKLIST.md`/`plan_*.md` files for anything a first pass would miss, or the
     "methodology described only in the abstract" pattern that worked so well in Part IX.
   - **Depth pass on Part IX** (just-finished, so the gap-shape diagnosis is fresh): same idea,
     applied to Chapters 42-48.
   - **Resume Parts I-IV**: Chapter 9 (GraphicsDevice) and Chapter 13 (Stock Effects) are both
     open targets untouched for several sessions; Chapter 7 (Math and Core Types) is at ~33 of
     a ~110-page target and needs fresh gap-discovery, not a ready-made list.
   - **Dedicated stale-reference sweep**: grep the whole book for other stale plain-text
     "Part~N" references left over from the two-volume merge (Chapter 41 found one; the merge
     session's own renumbering pass focused on `Chapter~N` citations and may have missed
     `Part~N` ones elsewhere) — flagged as worth doing "at some point" for several sessions now,
     never yet done as its own dedicated pass.
2. Ask the user which of the above to prioritize if it's not obvious from their own message —
   this file deliberately does not pick one, since the choice is a scope decision, not a
   technical one.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value.**

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- Build: `cd latex && make book` → `latex/book/main.pdf`. Check the log for `undefined`,
  `multiply defined`/`multiply-defined`, AND `overfull` every time.
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (and `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`) do not persist across sessions — check whether a
  clone already exists in the CURRENT session before re-cloning.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman numerals)
  — search by content (`pdftotext -f N -l N`), never assume printed page N is physical page N.
  A blank padding page immediately before a new Part's or chapter's right-hand start is normal
  book layout, not a rendering defect.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Verify hand-derived numeric/algebraic claims with an actual computation before writing them
  into the book. Double-check constructor/method/callback signatures against the real header
  (and the `.cpp`, not just the header) before writing a worked example that calls them.
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep/read the
  real source and diff against what the chapter's prose actually mentions — but once that pass
  is done once, a second pass on the same chapter needs a different angle, not the same grep.
