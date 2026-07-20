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

**Three former-Volume-II chapters now have a first real expansion pass**, all following the
same pattern (full method references + worked examples for every named class, each grounded in
a direct header/source read, with real verified findings called out explicitly, not just API
summaries):

- **Chapter 25 (Input System)**: 170 → 534 lines, ~4 → ~10 of a ~70-page target.
- **Chapter 26 (Audio System)**: 118 → 378 lines (two passes — an initial pass, then a
  gap-filling pass directly answering the author's "is this bible-level comprehensive"
  question), ~4 → ~8 of a ~60-page target.
- **Chapter 27 (Media)**, this session: 103 → 300 lines, ~4 → ~6 of a ~45-page target. Read
  `Song`, `MediaQueue`, `MediaPlayer`, `MediaLibrary`, `AudioTagParser`, `MediaLibraryPaths`,
  `PlaylistParser`, `Video`/`VideoPlayer`, `VisualizationData`, `VisualizationCapture`, and
  `VisualizationFFT` directly. Added: `Song`'s content-based `GetHashCode` (a documented
  deviation from FNA's own contract-violating identity-based version); the real multi-format
  tag-reading pipeline (Vorbis, ID3v2.3/2.4, native-FLAC, Ogg-Opus, plus the filename/folder
  fallback and the real cross-format rating-scale ambiguity); `MediaQueue`'s ownership model
  (a verified finding: `MediaPlayer::LoadSong()` defensively clones every song before handing
  it to the owning queue, because `SongCollection` itself is non-owning); a verified finding
  that `MediaPlayer::Stop()` resets every queued song's `PlayCount`, not just the one playing;
  three real `VideoPlayer` multi-track-switching bugs found by external code review and fixed
  (an unbounded-memory-growth audio-buffer leak, a stale frame-texture-size bug, and a wrongly
  coupled audio/video reconfigure step); and `GetVisualizationData`'s genuine from-scratch
  pipeline (a lock-free ring buffer using relaxed atomics — verified to avoid real UB, not
  pedantry — feeding a from-scratch 512-sample radix-2 FFT).

Volume currently compiles to **279 pages, 0 undefined references, 0 duplicate-label
warnings** (index count not re-checked this session — verify before quoting it).

### The `/`-spacing overfull-hbox defect class — three known variants, all with proven fixes

Every chapter touched so far (25, 26, 27) has needed at least one of these. Treat this as a
**routine check on every batch**, not a one-off:

1. **Chain variant**: `\texttt{A}/\texttt{B}` (or `\cnaclass{}`) with no space around the slash
   is one unbreakable LaTeX token; long enough, it overflows the line. Fix: proactively
   `grep -n '}/\\texttt{\|}/\\cnaclass{'` before the first build of a batch, or just run the
   established Python regex pass (`re.sub(r'\}/(\\texttt\{|\\cnaclass\{)', r'} / \1', text)`)
   over the whole file before the first build — this session did that for ch27 and it caught
   21 instances in one pass.
2. **Newline-continuation variant**: `\texttt{A}/%` followed by a newline-continued
   `\texttt{B}` — the `%` suppresses the newline's implicit space, and this does NOT match the
   grep above. Only caught by reading the actual source around any overfull warning's line
   range.
3. **Single-long-identifier variant**: even ONE very long `\texttt{}`/`\cnaclass{}`-wrapped
   identifier can cause severe, visibly-confirmed cutoff if it lands with too little remaining
   space on its line — REGARDLESS of spacing fixes around it. Not fixable by adding spaces.
   **The fix that works**: restructure so the sentence/clause containing the long identifier
   starts fresh (its own sentence, paragraph, or list-item continuation), maximizing its
   available line width from its very first character. Hit and fixed AGAIN this session in
   ch27: an itemized-list bullet naming `ReconfigureAudioOutputForCurrentTrack()` immediately
   followed by `ReconfigureVideoOutputForCurrentTrack()` on the same line overflowed even with
   `/`-spacing already applied — splitting the pair into two separate sentences (the second
   identifier starting its own sentence) fixed it, confirmed by re-rendering the page.

**Verification bar, unchanged**: `grep -i overfull main.log` alone is not reliable evidence
either way. The only real verification is `pdftoppm -png -f N -l N -r 100 main.pdf
/tmp/.../pageN` (find N by content search: `pdftotext -f N -l N main.pdf - | grep <text>`,
never by printed folio number) then reading the PNG back with the Read tool. This session
verified all six of ch27's own pages this way before considering the chapter done.

## What to do next

1. **Move to another Part V–IX chapter**: 28 (Devices/Sensors), 29 (GamerServices), 30
   (Networking), 31 (Avatar), 32 (Storage) — same systematic approach (read the real headers
   directly, add full method references + worked examples, watch for the three overfull-hbox
   variants above).
2. **If returning to Chapter 25, 26, or 27 for further depth**, don't re-run the "which classes
   exist" grep again (already done at least once each) — look for narrower gaps instead:
   worked-example depth per topic, cross-checking against `docs/*.md`/`CHECKLIST.md`/
   `plan_*.md` files in the real repo for anything a header-only pass would miss (e.g.
   platform-specific notes, performance guidance, concurrency contracts like the one found in
   `VisualizationCapture.hpp` this session).
3. **Deepen Chapter 9 (GraphicsDevice)** further, or start Chapter 13 (Stock Effects) — both
   still open Part I–IV targets, untouched for several sessions now.
4. Chapter 7 (Math and Core Types) is at ~33 of a ~110-page target after three sessions — a
   legitimate target but needs fresh gap-discovery, not a ready-made list.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value.**

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- Build: `cd latex && make book` → `latex/book/main.pdf`. Check the log for `undefined`,
  `multiply defined`/`multiply-defined`, AND `overfull` every time (see above).
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (or wherever `cna` gets cloned) does not persist across sessions — if a
  screenshot or source re-read needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`. This session found a clone already present at
  `/workspace/cna` from earlier in the same session — check there first before re-cloning.
- After embedding any new screenshot OR any dense full-method-reference section, verify it
  actually rendered correctly by converting the relevant compiled PDF page to an image and
  reading it back (`pdftoppm` + the `Read` tool).
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`) rather than assuming printed page N
  is physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Verify hand-derived numeric/algebraic claims with an actual computation before writing them
  into the book. Also double-check constructor/method signatures against the real header
  before writing a worked example that calls them — reading the actual `.cpp` implementation
  (not just the header) is often where the best verified findings come from (e.g. this
  session's `MediaQueue`/`LoadSong` ownership finding, the `Stop()` PlayCount-reset finding,
  and the three `VideoPlayer` bug-fix findings all came from `.cpp` reads, not header reads).
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep the real
  header for every type/class it covers and diff against what the chapter's prose actually
  mentions — but once that pass is done once, a second pass on the same chapter needs a
  different angle, not the same class-name grep repeated.
