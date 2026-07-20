# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history). If you're reading this mid-session rather than at the start of one, it may already
be stale relative to what's happened since — trust the conversation over this file in that case.

## Where things stand right now (end of session, 2026-07-20)

**The book is a single, unified book** (merged from two volumes earlier this same session).
`latex/volume1`/`latex/volume2` no longer exist; everything is under `latex/book/`, built via
`make book` (→ `latex/book/main.pdf`). Chapters 1–24 = former Volume I (Parts I–IV, unchanged
numbering). Chapters 25–48 = former Volume II (Parts V–IX, renumbered +24). Appendices A–F.
Full renumbering table is in `PLAN.md`'s merge session-log entry.

**Chapter 25 (Input System) is now essentially fully expanded at the "reference + worked
example per major type" depth**, though still well short of its ~70-page target (currently
534 lines, ~10 pages). Every named subsystem now has a full method reference and at least one
worked example: `Keyboard`/`KeyboardState` (incl. `GetKeyFromScancodeEXT`), `Mouse`/
`MouseState` (incl. relative-mouse-mode), `GamePad`/`GamePadState`/`GamePadDeadZone`,
`TouchPanel`/`TouchCollection`/`GestureSample`, `TextInputEXT`, and all five NOXNA-only device
subsystems (`Clipboard`, `Joysticks`, `Sensors`, `Power`, `Haptics`). The "Platform-specific
behavior" and "Status" sections at the end are unchanged from before this session's work
started (still just narrative, no worked examples) — those are the remaining known gap if
returning to this chapter specifically, though there may not be much real additional content
to add there (they're already fairly complete narrative, not reference material).

Volume currently compiles to **272 pages, 1146 index entries, 0 undefined references, 0
duplicate-label warnings**.

### A recurring defect class — watch for this in every future chapter

Two consecutive passes on Chapter 25 both turned up the same LaTeX typographic bug: a
`\texttt{A}/\texttt{B}` (or `\texttt{A}/%`-newline-continued) chain with **no space around the
slash** is one unbreakable token to LaTeX. When the combined text is long, this causes
overfull-hbox warnings — sometimes severe enough (up to ~225pt, ~3 inches) to visibly run text
off the page edge. **After any batch of edits to a chapter with dense multi-method-name
descriptions**, before considering it done:
1. `grep -n '}/\\texttt{\|}/\\cnaclass{'` on the file you just edited — fix any hit by adding a
   space (`} / \texttt{`) unless it's short enough to clearly not matter.
2. Also check for the sneakier `}/%`-newline-continuation variant, which doesn't match that
   grep — visually skim any paragraph with a lot of inline `\texttt{}` names.
3. `grep -i overfull main.log` after building, for the specific file/line range — anything
   over ~40pt is worth rendering the actual page to PNG and reading it back, since the log
   warning alone doesn't tell you whether it's a real visible defect or a harmless loose line.

## What to do next

1. **Move to Chapter 26 (Audio System)** or another Part V–IX chapter (Chapters 27–32 are
   Media, Devices/Sensors, GamerServices, Networking, Avatar, Storage) — same systematic
   approach that worked for Chapters 7 and 25: read the real headers, find full method
   references and real verified findings, add worked examples, watch for the `/`-spacing
   defect class above.
2. **Deepen Chapter 9 (GraphicsDevice)** further, or start Chapter 13 (Stock Effects) — both
   still open Part I–IV targets, untouched for several sessions now.
3. Chapter 7 (Math and Core Types) is at ~33 of a ~110-page target after three sessions — a
   legitimate target but needs fresh gap-discovery, not a ready-made list.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value.**

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- Build: `cd latex && make book` → `latex/book/main.pdf`. Check the log for `undefined`,
  `multiply defined`/`multiply-defined`, AND `overfull` (see above) every time.
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (or wherever `cna` gets cloned) does not persist across sessions — if a
  screenshot or source re-read needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`.
- After embedding any new screenshot OR any dense full-method-reference section, verify it
  actually rendered correctly by converting the relevant compiled PDF page to an image and
  reading it back (`pdftoppm` + the `Read` tool) — a page can "build successfully" while still
  visibly cutting off text.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`) rather than assuming printed page N
  is physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Verify hand-derived numeric/algebraic claims with an actual computation before writing them
  into the book.
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep the real
  header for every type/class it covers and diff against what the chapter's prose actually
  mentions.
