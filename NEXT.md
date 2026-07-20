# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history). If you're reading this mid-session rather than at the start of one, it may already
be stale relative to what's happened since — trust the conversation over this file in that case.

## Where things stand right now (end of session, 2026-07-20)

`CLAUDE.md` (durable project guide) exists. `PLAN.md` has the full expansion plan (Phase 1
targets ~1,305 pages Vol.I / ~1,163 pages Vol.II) and is being kept current. Both earlier scope
conflicts (free-direct/cna-extended staying marginal; screenshots real-or-nothing) are
resolved — don't re-litigate them, see `PLAN.md`'s "Resolved" section if you need the reasoning.

**Two chapters are now in progress, both real, verified, committed progress — neither complete:**

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 556 lines (~4 → ~13 of a ~90-page target). Full
  coverage added for render targets, vertex/index buffer binding, the 17-overload
  `DrawUserPrimitives`/`DrawUserIndexedPrimitives` family, back-buffer readback, all `NOXNA`
  helpers. One worked example with a real screenshot
  (`latex/volume1/images/ch09-drawprimitives-software.png`).
- **Vol.I Ch.7 (Math and Core Types)**: 270 → 471 lines. Only `Vector2`/`Vector3`/`Vector4`
  (documented once, since all three share the same method set) and `Matrix` are now fully
  expanded with a complete method/factory reference. **Quaternion, Point, Rectangle, Color,
  Plane, Ray, the three Bounding types (Box/Sphere/Frustum), MathHelper, and Curve/CurveKey are
  still at the original narrative-summary depth** — this is the single biggest concrete gap to
  close next in this chapter. One worked example with a real screenshot
  (`latex/volume1/images/ch07-matrix-rotation-software.png`, a real
  `CreateRotationZ`/`CreateLookAt`/`CreatePerspectiveFieldOfView` chain, visually confirmed
  genuinely rotated).

Volume I currently compiles to 127 pages, 598 index entries, 0 undefined references.
Volume II has not been touched in the expansion pass yet at all.

Two screenshot demos now exist and are preserved in `tools/cna-screenshot-infra/`
(`software_screenshot_demo.cpp` for Ch.9, `math_rotation_demo.cpp` for Ch.7), both registered
as CMake targets via one patch file covering both. Adding a third demo for a future chapter
just means: write the `.cpp`, add one `cna_software_test(...)` line to
`cmake/Tests/SoftwareTests.cmake`, reconfigure, build, run headlessly, copy the PNG into
`latex/volumeN/images/`, regenerate the patch file so the next session's fresh clone gets it
too. Full steps are in `tools/cna-screenshot-infra/README.md`.

## What to do next

In order of what's most tractable, per `PLAN.md`:

1. **Finish Chapter 7's remaining 7 type-families** (Quaternion, Point, Rectangle, Color,
   Plane, Ray, Bounding volumes) plus MathHelper and Curve — same treatment as Vector/Matrix
   got: full method reference kept alongside the existing narrative, at least one more worked
   example (a bounding-volume intersection test, or a Quaternion-driven rotation, would both
   be natural and could reuse the same `SOFTWARE`-backend screenshot technique).
2. **Push Chapter 9 further** toward its ~90-page target (currently ~13) — a render-target
   round trip actually built and screenshotted (not just the code snippet already in the
   chapter) would be the next concrete piece.
3. **Start a new chapter** — Chapter 13 (Stock Effects, target ~80 pages) is the next largest
   untouched target in Volume I Part III, and the worked examples in Ch.7/Ch.9 already
   demonstrate `BasicEffect` in passing, which Ch.13 could build on directly.

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
