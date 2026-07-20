# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history). If you're reading this mid-session rather than at the start of one, it may already
be stale relative to what's happened since — trust the conversation over this file in that case.

## Where things stand right now (end of session, 2026-07-20)

**The book was merged from two volumes into one single book this session**, per explicit
author instruction ("sluč svazky 1 a 2, bude to jenom jedna kniha"). This is a structural
change, not a content pass — every chapter's actual text is unchanged except for
renumbering and cross-reference fixes. Full details of the merge (directory moves, chapter
renumbering table, cross-reference-fixing categories, verification steps) are in `PLAN.md`'s
2026-07-20 session log entry — read that if you need the old Volume II chapter numbers or
anything else about how the merge was done.

**Concretely, what changed**:
- `latex/volume1/` + `latex/volume2/` → `latex/book/` (one directory, one `main.tex`).
- Chapters 1–24 (was Volume I) keep their numbers. Chapters 1–24 of the old Volume II are now
  chapters **25–48**. Parts: I–IV unchanged; the old Volume II's Parts I–V are now **Parts
  V–IX**.
- Appendices: Volume I's one appendix stays **Appendix A**. Volume II's five appendices
  (A–E) are now **Appendices B–F**. Both books' "API Quick Reference" appendices survive as
  two separate appendices (A and F) with disambiguated titles, since they cover disjoint
  class sets (core framework/graphics vs. ecosystem/platforms).
- `make volume1`/`make volume2` → **`make book`** (`latex/book/main.pdf`).
- `CLAUDE.md` updated for the new layout. `PLAN.md`'s two chapter tables kept but renumbered
  and re-headed ("Parts I–IV" / "Parts V–IX" instead of "Volume I" / "Volume II"), with a new
  combined target line (~2,468 pages total, current real total 266).

**Verified clean**: 266 pages, 0 undefined references, 0 duplicate-label warnings, 1111
combined index entries. Visually spot-checked the title page and the Part V transition page
(rendered to PNG, read back) — both correct. Also fixed, in passing (found via the merge's
full rebuild, unrelated to the merge itself): 13 `\textdegree`-in-math-mode LaTeX warnings in
Chapter 7, left over from a prior session's own Quaternion `Lerp`/`Slerp` and
`CreateConstrainedBillboard` additions (`$150°$` → `$150$°`).

**If a PDF is requested, it's now at `latex/book/main.pdf`, built via `make book` from
`latex/`** — not `volume1/main.pdf`/`volume2/main.pdf`, which no longer exist.

## What NOT to do

- Don't re-litigate the one-book decision — it was an explicit author instruction, executed,
  and verified. If asked to touch chapter cross-references, remember the book is now one
  document: a `\ref{ch:label}` written anywhere resolves correctly everywhere, so preferring
  real `\ref{}` over a plain-text `Chapter~N` citation (when a label already exists) is now
  strictly better and safe, whereas it used to require the `xrefs-volume1.tex` shim trick or
  a hand-computed plain number.
- Don't assume `PROGRESS.md`'s old volume1/volume2 build instructions are current — that file
  is an intentionally-preserved historical record of the pre-merge, pre-expansion state; it is
  not touched by this merge and is not meant to be "corrected." `CLAUDE.md` and `PLAN.md` are
  the current, accurate sources for repository layout.

## What to do next

The user's follow-up instruction after the merge was **"pokracuj na nejake dalsi kapitole
pote"** (continue on some other chapter after that) — i.e., after the merge, move to a
*different* chapter than Chapter 7, which has now had three consecutive sessions of
deepening work (see the chapter's own status below) and whose easy, list-able gaps are
largely exhausted.

Strongest candidates, in rough priority order:

1. **Start the former Volume II material (Parts V–IX, chapters 25–48)** — this is 0% into its
   own Phase 1 expansion and is the single highest-value target in the whole book. Chapter 25
   (Input System, ~70-page target, currently 170 lines) is a reasonable opening chapter.
2. **Deepen Chapter 9 (GraphicsDevice)** further — 171 → 872 lines (~23 of a ~90-page target),
   last touched two sessions ago.
3. **Start a new Part I–IV chapter** — Chapter 13 (Stock Effects, ~80-page target) is the
   next largest untouched target in that half of the book.
4. Chapter 7 (Math and Core Types) is at 1632 lines (~33 of a ~110-page target) after three
   sessions — still a legitimate target, but its easy remaining-gaps list is mostly used up;
   a fourth pass needs the same grep-every-header discovery approach the earlier sessions
   used, not a ready-made checklist. Given the author's own "continue on some other chapter"
   instruction, don't default back to Chapter 7 without a reason.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value.**

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- Build: `cd latex && make book` → `latex/book/main.pdf`. Check the log for `undefined` and
  for `multiply defined`/`multiply-defined` (duplicate `\label{}`) every time.
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (or wherever `cna` gets cloned) does not persist across sessions — if a
  screenshot or source re-read needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`.
- After embedding any new screenshot, verify it actually rendered correctly by converting the
  relevant compiled PDF page to an image and reading it back (`pdftoppm` + the `Read` tool).
- When checking where a physical PDF page falls (e.g. to screenshot a specific chapter), note
  that **printed page numbers and physical PDF page numbers now differ** more than before,
  because of the front matter's roman-numeral pages — search by content
  (`pdftotext -f N -l N`) rather than assuming printed page N is physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway — no reason not to now that everything is
  one document, though this isn't a mandatory standalone cleanup pass.
- Verify hand-derived numeric/algebraic claims with an actual computation before writing them
  into the book (a running theme from the last several sessions on Chapter 7 — still applies
  to any future numeric claim in any chapter).
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep the real
  header for every type/class it covers and diff against what the chapter's prose actually
  mentions.
