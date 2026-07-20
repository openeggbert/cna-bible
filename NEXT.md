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

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 790 lines (~4 → ~21 of a ~90-page target). This
  chapter has had three consecutive deepening passes this session and is now genuinely rich:
  - Full method coverage for the entire public surface (properties, Clear/Present/Reset,
    render targets, vertex/index buffers, all `DrawUserPrimitives` overloads, back-buffer
    readback, all `NOXNA` helpers).
  - **Two real, verified, backend-specific gaps found from direct source reading**, not
    assumed: (1) `SpriteBatch` can't correctly sample a `RenderTarget2D` on `SOFTWARE`
    (`dynamic_cast` fails silently for a sibling class); (2) `SupportsCapability
    (MultipleRenderTargets)` returns `true` universally since no backend's override actually
    checks it, so it doesn't guard against the very MRT gap it exists to catch.
  - A new "Private implementation" section tracing all 8 private lifecycle methods
    (`createOrAttachWindow`, `createBackend`, `destroyNativeResources`,
    `UpdateViewportFromWindow`, `SetVirtualResolution`, `SetPresentationMode`,
    `applyPresentationParametersToWindow`, `applySamplerStatesToBackend`) directly from
    `GraphicsDevice.cpp`'s real bodies — including the actual mechanism behind Chapter 6's
    `PresentationMode` enum, a genuine cross-chapter tie-in.
  - Four worked examples with two real screenshots.

  **This chapter is close to feeling "done at this level of depth"** even though it's only
  ~21 of ~90 target pages — further growth from here should mean covering genuinely new ground
  (e.g. GraphicsAdapter/DisplayMode could go deeper, or cross-referencing more Part IV backend
  specifics), not re-explaining what's already there. Worth considering moving to a different
  chapter next rather than mining Ch.9 for a fourth pass.
- **Vol.I Ch.7 (Math and Core Types)**: 270 → 758 lines (~4 → ~22 of a ~110-page target). All
  11 type-families have a full reference and at least one worked example.

Volume I currently compiles to 135 pages, 641 index entries, 0 undefined references.
**Volume II has not been touched in the expansion pass at all yet.**

Three screenshot demos exist in `tools/cna-screenshot-infra/`, one CMake patch covers all
three. **Repeated lesson from this session**: when a worked example's screenshot shows
something unexpected, investigate before assuming a demo-code mistake — it found two real bugs
this session. Trace the actual backend source before writing up a finding; don't speculate.

## What to do next

Given Ch.9 has now had three deepening passes and is starting to show diminishing returns per
additional pass, the strongest next moves are:

1. **Deepen Chapter 7 further** toward ~110 pages (currently ~22) — a second, different worked
   example per type (Quaternion-vs-Matrix comparison, Color premultiplied-alpha conversion,
   Curve's Cycle/Oscillate loop types) — this chapter has more untapped room than Ch.9 does
   right now.
2. **Start a new chapter** — Chapter 13 (Stock Effects, ~80-page target) is the next largest
   untouched Volume I Part III target, and both Ch.7/Ch.9's worked examples already use
   `BasicEffect` in passing. Volume II hasn't been touched at all — starting there (e.g. Ch.1
   Input System, ~70-page target) would be the first real progress on that volume, and is
   probably the single highest-value thing to do next given Volume II is currently at 0% of
   its own Phase 1 progress.
3. **Push Chapter 9 a fourth time** only if a genuinely new angle presents itself (e.g. a
   deeper `GraphicsAdapter`/multi-monitor worked example) — don't pad it just to hit the page
   number.

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
- Avoid hardcoding a section/figure number as plain text inside a code comment or prose — say
  "earlier in this chapter" instead when a real `\ref{}` isn't handy.
