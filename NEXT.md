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

**Seven former-Volume-II chapters now have a first real expansion pass**, all following the
same pattern (full method references + worked examples for every named class, each grounded in
a direct header/source read, with real verified findings called out explicitly, not just API
summaries):

- **Chapter 25 (Input System)**: 170 → 534 lines, ~4 → ~10 of a ~70-page target.
- **Chapter 26 (Audio System)**: 118 → 378 lines (two passes — an initial pass, then a
  gap-filling pass directly answering the author's "is this bible-level comprehensive"
  question), ~4 → ~8 of a ~60-page target.
- **Chapter 27 (Media)**: 103 → 300 lines, ~4 → ~6 of a ~45-page target. Read `Song`,
  `MediaQueue`, `MediaPlayer`, `MediaLibrary`, `AudioTagParser`, `MediaLibraryPaths`,
  `PlaylistParser`, `Video`/`VideoPlayer`, `VisualizationData`, `VisualizationCapture`, and
  `VisualizationFFT` directly. Added: `Song`'s content-based `GetHashCode` (a documented
  deviation from FNA's own contract-violating identity-based version); the real multi-format
  tag-reading pipeline; `MediaQueue`'s ownership model (`MediaPlayer::LoadSong()` defensively
  clones every song before handing it to the owning queue, since `SongCollection` itself is
  non-owning); `MediaPlayer::Stop()`'s queue-wide `PlayCount` reset; three real `VideoPlayer`
  multi-track-switching bugs found by external code review and fixed; and
  `GetVisualizationData`'s from-scratch lock-free-ring-buffer + radix-2-FFT pipeline.
- **Chapter 28 (Devices and Sensors)**, this session: 115 → 208 lines, ~4 → ~6 of a ~45-page
  target. Unlike 25–27, this chapter's PROSE was already dense and well-grounded (the
  `SensorBase` disposal-protocol and integer-overflow narrative was already accurate) — its gap
  was zero worked code examples anywhere. Read `SensorBase.hpp`, `Accelerometer.hpp`,
  `AccelerometerReading.hpp`, `SensorReadingEventArgs.hpp`, `EventHandler.hpp`,
  `VibrateController.hpp`, `Camera.hpp`, `CameraState.hpp` directly. Added two new verified
  findings not previously in the text: `SetCurrentValueAndMarkDataValid` closes a real
  observable-inconsistency window between two individually race-free locked calls; and
  `VibrateController::Start(duration, 0.0f)` deliberately does NOT act as an implicit `Stop()`
  (still plays a real, if inert, zero-strength effect). Added three worked examples
  (`Accelerometer::CurrentValueChanged` subscription, `VibrateController::StartLeftRight`,
  `Camera::TryAcquireFrame`'s poll-every-frame contract).
- **Chapter 29 (GamerServices)**, this session: 117 → 169 lines, ~4 → ~5 of a ~55-page target.
  Same gap shape as Chapter 28 — dense, accurate prose but zero worked examples. Read
  `SignedInGamer.hpp`, `GamerPresence.hpp`, `LeaderboardWriter.hpp`, `LeaderboardEntry.hpp`,
  `LeaderboardIdentity.hpp`, and `Guide.hpp` directly. Added one new real detail: the NOXNA
  non-`const` `getPresenceProperty()` overload exists specifically to preserve real XNA's
  get-only-property-returning-a-mutable-reference-type idiom. Added three worked examples:
  `SignedInGamer::AwardAchievement`/presence mutation; `LeaderboardWriter::GetLeaderboard` +
  `setRatingProperty` (showing "assigning Rating is the whole commit step" in code, not just
  prose); and a full `Guide::BeginShowMessageBox`/`RenderPendingMessageBoxEXT`/
  `EndShowMessageBox` round-trip.
- **Chapter 30 (Networking)**, this session: 125 → 170 lines, ~4 → ~5 of a ~70-page target.
  Same gap shape again — dense, accurate prose, zero worked examples. Read `NetworkSession.hpp`,
  `GamerJoinedEventArgs.hpp`, `LocalNetworkGamer.hpp`, `PacketWriter.hpp`, `PacketReader.hpp`
  directly. Added two worked examples: the documented `GamerJoined`-replay-on-subscribe gap and
  its "call `Update()` once right after subscribing" workaround, now shown in code; and the
  `PacketReader`/`PacketWriter` `Color` read/write asymmetry (4 bytes write, 4 floats read) as
  an actual send/receive round-trip.
- **Chapter 31 (Avatar)**, this session: 131 → 179 lines, ~4 → ~4 of a ~55-page target (line
  growth this pass came from prose/example depth, not page count — worked-example code blocks
  compress efficiently). Same gap shape once more. Read `SkinnedModelEXT.hpp`,
  `AvatarRenderer.hpp`, `AvatarAppearanceEXT.hpp` directly. Added one new real detail:
  `AttachPartEXT`/`RemovePartEXT` had two real found-and-fixed bugs — a GPU-resource leak (the
  old erase-from-Parts-vector approach only discarded a non-owning descriptor) and a real
  ordering bug (re-attaching a same-named part used to render both old and new simultaneously
  until replace-by-name was added). Added two worked examples: the full faithful-vs-real
  rendering bridge (`EnableRealRenderingEXT`/`SetAppearanceEXT`/`DrawRealEXT`), and a wardrobe
  hot-swap via `AttachPartEXT`.

Volume currently compiles to **281 pages, 0 undefined references, 0 duplicate-label
warnings** (index count not re-checked this session — verify before quoting it).

### The `/`-spacing overfull-hbox defect class — three known variants, all with proven fixes

Every chapter touched so far (25, 26, 27, 28, 29, 30, 31) has needed at least one of these. Treat this as a
**routine check on every batch**, not a one-off — run the Python regex pass
(`re.sub(r'\}/(\\texttt\{|\\cnaclass\{)', r'} / \1', text)`) over any file you touch before the
first build of a batch:

1. **Chain variant**: `\texttt{A}/\texttt{B}` (or `\cnaclass{}`) with no space around the slash
   is one unbreakable LaTeX token; long enough, it overflows the line. The regex pass above
   fixes this automatically.
2. **Newline-continuation variant**: `\texttt{A}/%` followed by a newline-continued
   `\texttt{B}` — the `%` suppresses the newline's implicit space, and this does NOT match the
   grep/regex above. Only caught by reading the actual source around any overfull warning's
   line range.
3. **Single-long-identifier variant**: even ONE very long `\texttt{}`/`\cnaclass{}`-wrapped
   identifier can cause severe, visibly-confirmed cutoff if it lands with too little remaining
   space on its line — REGARDLESS of spacing fixes around it. **The fix that works**:
   restructure so the sentence/clause containing the long identifier starts fresh (its own
   sentence, paragraph, or list-item continuation), maximizing its available line width from
   its very first character. Hit and fixed again in ch27 this session (two long `Reconfigure*`
   identifiers packed onto one itemized-list line — split into two sentences fixed it).

**Verification bar, unchanged**: `grep -i overfull main.log` alone is not reliable evidence
either way. The only real verification is `pdftoppm -png -f N -l N -r 100 main.pdf
/tmp/.../pageN` (find N by content search: `pdftotext -f N -l N main.pdf - | grep <text>`,
never by printed folio number) then reading the PNG back with the Read tool. Chapter 28 this
session rendered clean on the first try — the proactive regex pass alone was sufficient, no
second round needed, which is a good sign the routine is actually working now.

## What to do next

1. **Move to Chapter 32 (Storage)** — the last untouched Part V (Ch.25-32) chapter. Same
   systematic approach (read the real headers directly, add full method references + worked
   examples, watch for the three overfull-hbox variants above). Chapters 28/29/30/31 all
   turned out to need "add worked examples" rather than "add missing API coverage" — check 32's
   existing prose density first; if the same shape holds, the pass is: read the real headers
   for classes already named in the prose, find 2-3 genuinely worked-example-shaped gaps (a
   lifecycle, a send/receive round-trip, a state-machine walkthrough), ground each in real
   signatures, and watch for one new real detail worth adding along the way (there's been at
   least one per chapter so far). Once 32 is done, Part V (Ch.25-32) has a first pass on every
   chapter — worth updating PLAN.md's task-tracking to reflect that milestone.
2. **If returning to Chapter 25, 26, 27, 28, 29, 30, or 31 for further depth**, don't re-run the
   "which classes exist" grep again (already done at least once each) — look for narrower gaps
   instead: worked-example depth per topic, cross-checking against `docs/*.md`/`CHECKLIST.md`/
   `plan_*.md` files in the real repo for anything a header-only pass would miss.
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
  (not just the header) is often where the best verified findings come from (Chapter 27's
  `MediaQueue`/`LoadSong` ownership finding and its three `VideoPlayer` bug-fix findings all
  came from `.cpp` reads, not header reads). Also verify event-handler callback signatures
  (e.g. `const T&` vs `T&`) against the actual `EventHandler.hpp` template before writing a
  lambda in a worked example — Chapter 28 caught exactly this kind of mismatch this session.
- Not every chapter's gap is "missing API surface" — Chapter 28's prose was already dense and
  accurate, but had zero worked code examples. Check for that gap shape too, not just missing
  classes/methods.
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep the real
  header for every type/class it covers and diff against what the chapter's prose actually
  mentions — but once that pass is done once, a second pass on the same chapter needs a
  different angle, not the same class-name grep repeated.
