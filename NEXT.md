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

**All eight Part V chapters (25-32) have a first real expansion pass**, and **Part VI
(Chapters 33-37) is now fully swept too** — 33-36 all got a first pass this session; 37
(free-direct Deep Dive) stays explicitly frozen per the author's own 2026-07-20 confirmation,
not left incomplete. Full per-chapter detail (exact line counts, which
headers were read, every verified finding and worked example added) lives in `PLAN.md`'s
session log — this file only summarizes. The pattern every one of these nine chapters
followed: read the real headers/`.cpp` files for classes already named in the chapter's prose,
add full method references + worked examples grounded in real signatures, and surface at least
one genuinely new verified finding per chapter (not just restate what the prose already said).
Chapters 25-27 needed real content-gap-filling; chapters 28-33 turned out to already have
dense, accurate prose and needed "add worked examples" instead — check this shape for any new
chapter before assuming which kind of gap it has.

**Milestone: every Part V chapter (25-32) has a first pass**, none at their final page targets
yet (roughly 3-10 of a 30-70-page target each — this was a breadth pass, not a depth pass).
**Chapter 33 (Sharp Runtime Overview)** got a first pass: 116 → 167 lines, ~4 → ~5 of a
~40-page target — worked examples for `MulticastAction`'s token-based `Add`/`Remove` (the
re-parenting use case named in its own header) and `Task::ContinueWith`, plus the real finding
that `ContinueWith` always runs its continuation synchronously and inline (no thread
pool/scheduler exists in this port at all).

**Chapter 34** also got a first pass, plus a **documentation-drift catch worth knowing about**:
PLAN.md's own table row for Chapter 34 was stale — it described "Full docs for
TimeSpan/EventHandler/Stream/collections," but the chapter's real `\chapter{}` title is "Sharp
Runtime: Strings, Streams, and a Real Audit History," and TimeSpan/EventHandler are already
covered in Chapter 33 (added last session), not here. PLAN.md's table row is now corrected to
describe the chapter's actual scope (String/StringBuilder, Stream, and two post-stabilization
audit narratives) — if you see PLAN.md's per-chapter description not matching what a chapter's
actual `\chapter{}` title/content says, trust the actual file and correct the table row, the
same way this project has caught and corrected its own stale claims before (see CLAUDE.md's
".xnb reader doesn't exist" precedent). Chapter 34 itself: 90 → 162 lines, ~3 → ~5 of a
~70-page target (that target may need revisiting given the corrected, narrower actual scope).
Added the `StringBuilder::ChunkEnumerator`-always-one-chunk finding and three worked examples
(`String`/`StringBuilder` usage, a minimal `Stream` subclass, and the exact
`Convert::ToInt32` round-half-to-even repro the prose already named numerically).

**Chapter 35 (Parity Philosophy)** also got a first pass: 111 → 134 lines, ~4 → ~6 of a
~35-page target. This chapter is more policy-narrative (reflection/GC/serialization/crypto
scope decisions, quoted directly from the project's own reasoning) than API-reference, so the
worked-example opportunity was narrower — one solid example added, contrasting the three
delegate tiers (`ActionT` alias, `Delegate::Combine`/`Remove`, `MulticastAction`'s token-based
removal) side by side against the same kind of problem each solves. No major new finding this
pass; the existing prose was already unusually precise.

**Chapter 36 (easy-gl Deep Dive)** got a first pass too: 112 → 151 lines, ~4 → ~5 of a
~55-page target. Read `Capabilities.hpp`, `Feature.hpp`, `Device.hpp`, `Program.hpp`, and
`Framebuffer.hpp` directly — cross-checked exact enumerator names (e.g.
`FramebufferAttachment::Depth`) against `Framebuffer.cpp`'s own real test usage, since the enum
definitions live in the sibling `meta-gl` repo which wasn't cloned this session; a worked
example was adjusted mid-pass rather than guessing at an unverified enumerator name. Added two
worked examples (`Device::supports`/`require` querying the real per-feature capability table;
`Program::uniform_block_index`/`Framebuffer` typed-reference fixes shown together). **Found and
fixed two instances of the single-long-identifier overfull-hbox variant while proactively
checking this chapter** — one in this session's own new content, one pre-existing from before
this session — both via the established own-paragraph-break technique, confirmed by re-render.

Volume currently compiles to **285 pages, 0 undefined references, 0 duplicate-label
warnings** (index count not re-checked this session — verify before quoting it).

### The `/`-spacing overfull-hbox defect class — three known variants, all with proven fixes

Every chapter touched this session (25 through 36) has needed at least one of these. Treat
this as a **routine check on every batch**, not a one-off — run the Python regex pass
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
never by printed folio number) then reading the PNG back with the Read tool. Most chapters
this session rendered clean on the first try once the proactive regex pass ran before the
first build — the routine is working.

## What to do next

1. **Continue to Parts VIII-IX** (Chapters 38-48): Cross-platform engineering (38-41),
   Porting/practice/roadmap (42-48) — none touched yet this session. Same approach: read the
   real headers/source for classes already named in the prose, check whether the gap is "add
   worked examples" (as it has been for nearly every chapter this session) or something else,
   add 1-3 worked examples plus at least one new verified finding, and check PLAN.md's own
   table-row description against the chapter's actual `\chapter{}` title/content before
   trusting it (Chapter 34 turned out to have a stale description this session).
2. **Alternatively, return to Part V or VI for real depth**: every Ch.25-36 chapter (all of
   Part V, all of Part VI except the frozen Ch.37) has a first pass now, but all are still well
   short of their page targets. Don't re-run the "which classes exist" grep again (already done
   at least once per chapter) — look for narrower gaps instead:
   worked-example depth per topic, cross-checking against `docs/*.md`/`CHECKLIST.md`/
   `plan_*.md` files in the real repo for anything a header-only pass would miss.
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
  re-cloning (this session found `/workspace/cna` and `/workspace/sharp-runtime` already
  present from earlier work). If nothing exists and a screenshot needs a working clone, redo it
  per `tools/cna-screenshot-infra/README.md`.
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
- Not every chapter's gap is "missing API surface" — several Part V/VI chapters had dense,
  accurate prose already but zero worked code examples. Check for that gap shape too.
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep the real
  header for every type/class it covers and diff against what the chapter's prose actually
  mentions — but once that pass is done once, a second pass on the same chapter needs a
  different angle, not the same class-name grep repeated.
