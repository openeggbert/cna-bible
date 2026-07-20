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

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 722 lines (~4 → ~19 of a ~90-page target). Full method
  coverage plus **two real, verified, backend-specific gaps found and documented from direct
  source reading**, not assumed or invented:
  1. `SpriteBatch` cannot correctly sample a `RenderTarget2D` on the `SOFTWARE` backend
     (`dynamic_cast` in `SoftwareSpriteBatchBackend::Draw` fails silently for
     `SoftwareRenderTargetBackend`, a sibling class rather than a subclass of
     `SoftwareTextureBackend`).
  2. `SupportsCapability(GraphicsCapability::MultipleRenderTargets)` returns `true`
     universally (nothing overrides it) even on backends like `SOFTWARE` where
     `SetRenderTargets` silently only binds the first target and drops the rest — the
     capability check that exists specifically to guard against this doesn't actually catch it.

  Four worked examples total now (raw draw calls, render-target round trip, MRT discussion,
  back-buffer readback + capability checks). This is a genuinely strong chapter for real,
  source-verified content — worth knowing if picking where to invest further effort.
- **Vol.I Ch.7 (Math and Core Types)**: 270 → 758 lines (~4 → ~22 of a ~110-page target). All
  11 type-families have a full reference and at least one worked example.

Volume I currently compiles to 133 pages, 638 index entries, 0 undefined references.
**Volume II has not been touched in the expansion pass at all yet.**

Three screenshot demos exist in `tools/cna-screenshot-infra/` (`software_screenshot_demo.cpp`,
`math_rotation_demo.cpp`, `rendertarget_roundtrip_demo.cpp`), one CMake patch covers all three.
**Important lesson from this session, worth repeating to any future session**: when a worked
example's screenshot shows something unexpected, investigate before assuming a mistake in the
demo code — it may be a real, book-worthy finding (this happened twice in Ch.9 this session).
Trace the actual backend source before writing up a finding; don't speculate.

## What to do next

Three reasonable directions:

1. **Push Chapter 9 further** toward ~90 pages (currently ~19) — deeper per-backend behavior
   notes cross-referencing Part IV's specific backend chapters would be a natural next piece;
   the render-target/MRT/capability findings already give this chapter real momentum.
2. **Deepen Chapter 7 further** toward ~110 pages (currently ~22) — a second, different worked
   example per type (Quaternion-vs-Matrix comparison, Color premultiplied-alpha conversion,
   Curve's Cycle/Oscillate loop types).
3. **Start a new chapter** — Chapter 13 (Stock Effects, ~80-page target) is the next largest
   untouched Volume I Part III target. Volume II hasn't been touched at all — starting there
   (e.g. Ch.1 Input System, ~70-page target) would be the first real progress on that volume.

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
  relevant compiled PDF page to an image and reading it back (`pdftoppm` + the `Read` tool).
- Avoid hardcoding a section/figure number as plain text inside a code comment or prose (it
  won't auto-update like a real `\ref{}` would across renumbering) — one such case was caught
  and fixed this session; say "earlier in this chapter" instead when a real `\ref` isn't handy.
