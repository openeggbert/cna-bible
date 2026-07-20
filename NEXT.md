# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history, and which has the full per-chapter detail this file only summarizes). If you're
reading this mid-session rather than at the start of one, it may already be stale relative to
what's happened since — trust the conversation over this file in that case.

## Where things stand right now (mid-session, 2026-07-20, updated after Chapter 42)

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

## Chapter 47 (Testing Philosophy) is now done too — sixth chapter of Part IX

Grew 103 → 139 lines. Same "make the abstract concrete" gap shape as Chapters 44/46: this
chapter names its two headline pixel-test bugs but never shows an actual test. Read
`/workspace/cna/examples/sdlrenderer_transform_matrix_test.cpp` directly and quoted its core
mechanism (draw at a position only correct if `transformMatrix` was applied, then read back a
specific pixel and assert its real color) as a new worked example. While PNG-rendering the
chapter's pages, caught a real, severe (95.37pt) overfull-hbox defect —
`SpriteEffects::FlipHorizontally` visibly clipped off the page edge — fixed by making the
identifier the first word of its own paragraph (the established single-long-identifier
technique). Full detail in PLAN.md's session log. Volume compiles clean at 295 pages, 0
undefined refs; all four of the chapter's own pages (263-266) PNG-rendered and confirmed
defect-free, including a second render confirming the overfull-hbox fix.

## Chapter 46 (Project Practice) is done too — fifth chapter of Part IX

Grew 100 → 150 lines. Like Chapter 44, this chapter described its own tracking layers
(`NEXT.md`/`AUDIT.md`/`CHECKLIST.md`/`plan_<subsystem>.md`/Doxygen tags) entirely in the
abstract, with no real task entry ever quoted — fixed by reading `/workspace/cna/plan_ascii.md`
directly and quoting its `ASCII-40` row almost in full. Also found a genuinely new convention in
`/workspace/cna/plan_graphics.md`: large tasks spanning multiple backends get split into one
sub-task per backend (Task~868→923, Task~878→899), with the original row rewritten into a
"tracking pointer" rather than deleted. Hit and fixed one real build error along the way:
`\checkmark` needs `amssymb`, which this book's preamble doesn't load — used the plain word
"done" instead of adding a new package for one symbol. Full detail in PLAN.md's session log.
Volume compiles clean at 295 pages, 0 undefined refs; all four of the chapter's own pages
(259-262) PNG-rendered and confirmed defect-free.

## Chapter 45 (cna-samples and cna-examples) is done too — fourth chapter of Part IX

Grew 54 → 104 lines, the biggest relative jump of Part IX so far — cloning `/workspace/cna-samples`
fresh and reading its own `PLAN.md`/`DEFERRED.md`/`missing.md` files turned up a genuine,
documentation-drift-style correction: the chapter's own existing claim that "every one of the
23 [blocked] failures traces to the same root cause" is imprecise. Checked all 23 blocked
samples' own `missing.md` write-ups directly — real breakdown is **three** root causes: 16 (+
`Spacewar`) really are the `.fx` shader gap as claimed, but 4 are blocked on missing
skeletal-animation-playback support (a real unimplemented CNA capability) and 2 more on a
narrower "only a single flat root bone" `.model.json`-reader gap. Corrected the sentence and
added a full new section naming all 23 by real bucket. Also added a second new section on a
genuinely instructive finding: `SimpleAnimation` was marked "Done," but a later session that
actually ran it (not just trusted the status line) found two real CNA bugs, serious enough that
the project opened a dedicated re-audit of all 153 catalogued samples. Full detail in PLAN.md's
session log. Volume compiles clean at 293 pages, 0 undefined refs; all four of the chapter's own
pages (255-258) PNG-rendered and confirmed defect-free.

## Chapter 44 (xna4-spec Auditing) is done too — third chapter of Part IX

Grew 74 → 117 lines. This chapter described its own three-step audit methodology only in the
abstract, so the gap was "actually run it once." Picked `Ray` (small, complete type, already
cloned at `/workspace/xna4-spec`) and audited every field/constructor/method in the spec against
CNA's real `Ray.hpp` member by member — full match, plus two precise, genuinely new
methodological findings: `Ray` has no `Equals(Object)` overload (correctly not a gap — C++ has
no universal boxed root type, a third audit-outcome category distinct from "missing" and
"NOXNA-tagged"), and `GetHashCode` returns `std::size_t` not the spec's `int` (a deliberate
convention substitution). Also found and fixed a genuine pre-existing overfull-hbox defect in
this chapter's opening paragraph — a long URL overflowing ~99pt past the margin, visibly
confirmed via PNG render, fixed with `\allowbreak{}` after each path segment. Full detail in
PLAN.md's session log. Volume compiles clean at **291 pages** (up from 289), 0 undefined refs;
all four of the chapter's own pages (251-254) PNG-rendered and confirmed defect-free.

## Chapter 43 (Blupi Case Study) is done too — second chapter of Part IX

Grew 116 → 172 lines. This chapter was already dense with real call-site audit findings, so the
gap shape was "find a genuinely new real source," not re-derive existing coverage. Read
`/workspace/free-direct/docs/audit_ddraw.md` (already cloned this session) — a dedicated
performance audit of the same DirectDraw implementation, benchmarked against the real compiled
library. Added one new section covering the missing 1:1 fast path in `BlitFrom` (29x/206x
slower than `memcpy`, with a benchmark table), the exact real `BltFast` call-site line numbers
in both games, the `CMAKE_BUILD_TYPE`-unset 6.6x-penalty finding, the one call site where
scaling is genuinely necessary, and a newly-found dead-code call site. Full detail in PLAN.md's
session log. Volume compiles clean at 289 pages, 0 undefined refs; all four of the chapter's own
pages (247-250) PNG-rendered and confirmed defect-free, including the new table.

## Chapter 42 (Migration Guide) is done — first chapter of Part IX

Grew 102 → 165 lines. It's a checklist/synthesis chapter (six numbered "Step" sections), so the
gap shape was "add worked examples to the two steps that most invite one," not a header grep:
(1) a full XNA/FNA `Update()`/`Draw()` C# pair plus its mechanical CNA C++23 translation, every
signature checked against `Game.hpp` directly (caught and fixed a reference-vs-pointer mistake
on `getGraphicsDeviceProperty()` and a by-value-vs-by-reference mistake on the `Update`/`Draw`
override signatures before finalizing); (2) a hand-computed custom-vertex-stride worked example
showing a 48-byte struct is NOT one of the five recognized strides. Also fixed a
newline-continuation `/`-spacing defect the regex pass doesn't catch (`}/%` followed by a
continued `\texttt{}` on the next line — grep for `}/%` by hand every time, it's real and easy
to miss). Full detail in PLAN.md's session log. Volume compiles clean at 289 pages, 0 undefined
refs; all four of Chapter 42's own pages (243-246) PNG-rendered and confirmed defect-free. One
unrelated overfull-hbox warning surfaced for pre-existing Chapter 36 content
(`detect_common_features()`) — rendered that page too, confirmed false positive, no fix needed.

## What to do next

1. **Continue Part IX**: Chapter 48 (Roadmap) is next — the last chapter of Part IX and of the
   whole book's main chapter sequence. Same approach: read
   the real source before assuming whether each chapter is API-reference-shaped,
   tooling/narrative-shaped, or synthesis-shaped like Chapter 41 turned out to be. When a
   chapter doesn't fit the "add worked examples" mold, look instead for a genuine content gap or
   a stale cross-reference (Chapter 41's own pass found both: a missing macOS row and a
   leftover "Part~IV" reference from the merge). For a case-study/audit chapter like Chapter 43,
   the move that worked was finding a *newer* or *different* real audit document than the one
   the chapter already drew from (`/workspace/free-direct/docs/` has several: `audit_ddraw.md`,
   `audit_dsound.md`, `audit_dplay.md`, `directplay-callsite-audit.md` — only `audit_ddraw.md`
   has been mined so far). For a methodology chapter like Chapter 44, the move was picking one
   small real type and actually running the described process against it end to end, rather
   than leaving the process abstract — `/workspace/xna4-spec` (already cloned) has 544 types
   across 19 namespaces, so this pattern (pick another small type, audit it fully) is repeatable
   if Chapter 44 ever needs a second pass. For Chapter 45, the move was cloning the actual
   sibling repo the chapter describes (`/workspace/cna-samples`, not previously cloned this
   session — do it fresh for any chapter about a repo not yet checked out) and checking a
   summary claim against every individual source file it was rounding up from, which is worth
   trying again on Chapter 46 (Project Practice) since it likely describes `cna`'s own
   `PLAN.md`/`AUDIT.md` conventions the same way.
2. **New lesson this session, worth checking on every future chapter's opening/early
   paragraphs specifically**: a long, unbroken `\texttt{}`-wrapped URL or path can overflow far
   more severely (Chapter 44's was ~99pt overfull) than the identifier-length defects seen
   before — fix with `\allowbreak{}` inserted after each `/`-delimited path segment inside the
   `\texttt{}`, not by paragraph restructuring (which only helps when a fresh full-width line
   would actually fit the token — it won't for a long URL).
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
