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

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 622 lines (~4 → ~16 of a ~90-page target). Full
  coverage of render targets, vertex/index buffer binding, the 17-overload `DrawUserPrimitives`
  family, back-buffer readback, all `NOXNA` helpers. **Three worked examples**, one of which
  found and documented a real bug: a render-target round trip revealed that `SpriteBatch`
  cannot correctly sample a `RenderTarget2D` on the `SOFTWARE` backend (root cause: a
  `dynamic_cast` in `SoftwareSpriteBatchBackend::Draw` fails silently for
  `SoftwareRenderTargetBackend`, a sibling class of `SoftwareTextureBackend` rather than a
  subclass — see the chapter's own `sourcenote` for the full trace, and
  `tools/cna-screenshot-infra/README.md` for the reproduction). This was written up honestly
  with the actual (partially broken) screenshot as evidence, not hidden or faked around.
- **Vol.I Ch.7 (Math and Core Types)**: 270 → 758 lines (~4 → ~22 of a ~110-page target). All
  11 type-families have a full reference and at least one worked example. Every type could
  still go deeper (more worked examples per type, more edge cases) before hitting 110 pages.

Volume I currently compiles to 131 pages, 636 index entries, 0 undefined references.
**Volume II has not been touched in the expansion pass at all yet.**

Three screenshot demos now exist in `tools/cna-screenshot-infra/`
(`software_screenshot_demo.cpp`, `math_rotation_demo.cpp`, `rendertarget_roundtrip_demo.cpp`),
registered as CMake targets via one patch file covering all three. Adding a fourth: write the
`.cpp`, add one `cna_software_test(...)` line to `cmake/Tests/SoftwareTests.cmake`,
reconfigure, build, run headlessly, copy the PNG into `latex/volumeN/images/`, regenerate the
patch file. Full steps in `tools/cna-screenshot-infra/README.md`. **Worth remembering**: a
worked example that surfaces a real bug is not a failure — write it up as a finding (like
Ch.9's render-target example just did), don't discard it or quietly fix the demo to route
around the bug.

## What to do next

Three reasonable directions, roughly in order of how much real, un-padded content each one has
left to add:

1. **Push Chapter 9 further** toward ~90 pages (currently ~16) — a multi-render-target (MRT)
   example, and deeper per-backend behavior notes cross-referencing Part IV's backend chapters,
   are natural next pieces.
2. **Deepen Chapter 7 further** toward ~110 pages (currently ~22) — a second, different worked
   example per type (e.g. a Quaternion-vs-Matrix comparison for the same rotation, a Color
   premultiplied-alpha worked example, Curve's Cycle/Oscillate loop types demonstrated).
3. **Start a new chapter** — Chapter 13 (Stock Effects, ~80-page target) is the next largest
   untouched Volume I Part III target, and both Ch.7/Ch.9's worked examples already use
   `BasicEffect` in passing. Volume II hasn't been touched at all — starting there (e.g. Ch.1
   Input System, ~70-page target) would be the first real progress on that volume.

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
  don't just trust that `\includegraphics` didn't error. If the screenshot shows something
  unexpected, investigate before assuming it's a demo-code mistake — it might be a real,
  book-worthy finding, as Ch.9's render-target example turned out to be.
