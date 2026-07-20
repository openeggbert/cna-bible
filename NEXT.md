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

**Two former-Volume-II chapters now have a first real expansion pass**: Chapter 25 (Input
System, 170 → 534 lines, ~4 → ~10 of a ~70-page target) and, this session, **Chapter 26 (Audio
System, 118 → 317 lines, ~4 → ~8 of a ~60-page target)**. Both follow the same pattern: full
method references + worked examples for every named class, each grounded in a direct
header/source read, with real verified findings (not just API summaries) called out
explicitly.

### What Chapter 26 got this session

- **`SoundEffect`**: four static process-wide mixing knobs, three constructor families.
  Worked example: loading from raw headerless PCM.
- **`SoundEffectInstance`/`Apply3D`**: a verified finding read from `SoundEffectInstance.cpp`
  — calling `Apply3D` even once permanently latches an internal `is3D` flag that never resets,
  so its derived attenuation/pan/Doppler values keep governing output on every later call.
  Worked example: a 3D explosion sound tracking a moving listener.
- **`DynamicSoundEffectInstance`**: the pull-based `BufferNeeded`/`SubmitBuffer` streaming
  model. Worked example: a procedurally generated tone.
- **`AudioEngine`/`SoundBank`/`WaveBank`/`Cue`**: the XACT object model, distinguishing
  `GetCue` (caller-owned) from `PlayCue` (bank-owned, fire-and-forget). Worked example: a
  footstep cue driven by a global XACT runtime variable, plus a held looping engine sound.
- **`Microphone`**: a verified finding that `BufferDuration`'s constraint is enforced by
  actually throwing, not just documented. Worked example: mic capture piped into playback.

Caught and fixed a real constructor-signature mistake in a first draft (`SoundBank`/`WaveBank`
take `AudioEngine*`, not a reference) before finalizing.

Volume currently compiles to **276 pages, 1164 index entries, 0 undefined references, 0
duplicate-label warnings**.

### The `/`-spacing overfull-hbox defect class — now a routine check

Three consecutive chapters (25, and now 26) have needed the same fix: a
`\texttt{A}/\texttt{B}` chain with no space around the slash is one unbreakable LaTeX token,
and when long enough this causes overfull-hbox warnings, sometimes severe enough to visibly
cut text off the page edge. **This is now a routine step, not a one-off fix**:
1. Before the first build of any batch, `grep -n '}/\\texttt{\|}/\\cnaclass{'` on the file(s)
   you edited and add a space (`} / \texttt{`) to any long chain.
2. Also watch for the sneakier `}/%`-newline-continuation variant (doesn't match that grep).
3. After building, `grep -i overfull main.log` for the file/line range you touched. This
   session confirmed (again) that a residual warning under ~40pt does not reliably mean a
   visible defect — render the actual page to PNG and read it back before spending more time
   chasing a warning that may already look fine.

## What to do next

1. **Move to Chapter 27 (Media)** or another Part V–IX chapter (28 Devices/Sensors, 29
   GamerServices, 30 Networking, 31 Avatar, 32 Storage) — same systematic approach.
2. **Deepen Chapter 9 (GraphicsDevice)** further, or start Chapter 13 (Stock Effects) — both
   still open Part I–IV targets, untouched for several sessions now.
3. Chapter 7 (Math and Core Types) is at ~33 of a ~110-page target after three sessions — a
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
  `tools/cna-screenshot-infra/README.md`.
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
  before writing a worked example that calls them — this session caught a
  reference-vs-pointer mistake this way before it shipped.
- To find genuine gaps in an already-"complete-looking" chapter, systematically grep the real
  header for every type/class it covers and diff against what the chapter's prose actually
  mentions.
