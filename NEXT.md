# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history). If you're reading this mid-session rather than at the start of one, it may already
be stale relative to what's happened since — trust the conversation over this file in that case.

## Where things stand right now (end of session, 2026-07-20)

`CLAUDE.md` (durable project guide) exists. `PLAN.md` has the full expansion plan (Phase 1
targets ~1,305 pages Vol.I / ~1,163 pages Vol.II). Both earlier scope conflicts (free-direct/
cna-extended staying marginal; screenshots real-or-nothing) are resolved — don't re-litigate.

**Two chapters are in progress, both real committed progress, neither at its full target:**

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 556 lines (~4 → ~13 of a ~90-page target). Render
  targets, vertex/index buffer binding, the 17-overload `DrawUserPrimitives`/
  `DrawUserIndexedPrimitives` family, back-buffer readback, all `NOXNA` helpers all fully
  documented now. One worked example with a real screenshot.
- **Vol.I Ch.7 (Math and Core Types)**: 270 → 758 lines (~4 → ~22 of a ~110-page target).
  **All 11 type-families now have a full method/constructor reference and at least one worked
  example** — Vector2/3/4, Matrix, Quaternion, Plane, Ray, Rectangle, Point, Color, MathHelper,
  the three Bounding types, and Curve/CurveKey. Two real screenshots (a rotated triangle via
  Matrix, embedded in the Matrix worked example). This chapter is no longer lopsided toward
  just Vector/Matrix, but every type-family could still go considerably deeper before hitting
  110 pages — more worked examples per type, more edge-case/gotcha coverage, is the way to get
  there, not new type-families (there aren't any left uncovered).

Volume I currently compiles to 131 pages, 632 index entries, 0 undefined references.
**Volume II has not been touched in the expansion pass at all yet.**

Two screenshot demos exist, preserved in `tools/cna-screenshot-infra/`
(`software_screenshot_demo.cpp` for Ch.9, `math_rotation_demo.cpp` for Ch.7), registered as
CMake targets via one patch file covering both. Adding a third: write the `.cpp`, add one
`cna_software_test(...)` line to `cmake/Tests/SoftwareTests.cmake`, reconfigure, build, run
headlessly, copy the PNG into `latex/volumeN/images/`, regenerate the patch file. Full steps
in `tools/cna-screenshot-infra/README.md`.

## What to do next

Three reasonable directions, roughly in order of how much real, un-padded content each one has
left to add before diminishing returns set in:

1. **Push Chapter 9 (GraphicsDevice) further** toward ~90 pages (currently ~13) — a
   render-target round trip actually built and screenshotted (not just the code snippet
   already in the chapter), a multi-render-target example, and deeper per-backend behavior
   notes (Part IV chapters already have some of this material to cross-reference) are the
   next concrete pieces, not repetition of what's already there.
2. **Deepen Chapter 7 (Math and Core Types) further** toward ~110 pages (currently ~22) — every
   type has one worked example now; a second, different worked example per type (e.g., a
   Quaternion+Matrix comparison for the same rotation, a Color premultiplied-alpha worked
   example, a Curve with Cycle/Oscillate loop types demonstrated) would add real depth without
   repeating what's there.
3. **Start a new chapter** — Chapter 13 (Stock Effects, target ~80 pages) is the next largest
   untouched target in Volume I Part III, and both Ch.7's and Ch.9's worked examples already
   use `BasicEffect` in passing, which Ch.13 could build on directly. Alternatively, Volume II
   hasn't been touched at all — starting there (e.g. Ch.1 Input System, ~70-page target) would
   be the first real progress on that volume.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value** — if a session ran after this note was written and didn't update this file,
treat this section as stale and re-derive current state from the repo itself.

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- `make volume1`/`make volume2` from `latex/`; check the log for `undefined` every time.
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (or wherever `cna` gets cloned) does not persist across sessions — if a
  screenshot or source re-read needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`.
- After embedding any new screenshot, verify it actually rendered correctly by converting the
  relevant compiled PDF page to an image and reading it back (`pdftoppm` + the `Read` tool) —
  don't just trust that `\includegraphics` didn't error.
