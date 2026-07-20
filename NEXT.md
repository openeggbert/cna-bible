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

- **Vol.I Ch.7 (Math and Core Types)**: 270 → 840 lines (~4 → ~24 of a ~110-page target). All
  11 type-families have a full reference and at least one worked example; three of them now
  have a *second* worked example added in the most recent pass:
  - Quaternion: a numeric+visual equivalence proof that `Matrix::CreateRotationZ(30°)` and
    `Quaternion::CreateFromAxisAngle(Vector3::Backward, 30°) -> Matrix::CreateFromQuaternion`
    produce identical results (max abs difference across all 16 components: exactly `0`;
    transformed test point matches to 6 decimals). Deliberately does **not** embed a duplicate
    screenshot — it's pixel-identical to the existing Matrix rotation figure, so the text cites
    the numeric proof and the existing figure instead.
  - Color: a `FromNonPremultiplied` worked example contrasting a "WRONG" naive `Color`
    construction from straight-alpha values against the "RIGHT" premultiplied conversion.
  - Curve: a worked example distinguishing `CurveLoopType::Cycle` vs `Oscillate` vs
    `CycleOffset` (snap-repeat vs. ping-pong vs. accumulating-repeat) — an easily-confused set
    of semantics.
  - The demo behind the Quaternion proof (`quaternion_vs_matrix_demo.cpp`) is saved in
    `tools/cna-screenshot-infra/` along with everything needed to rebuild it.
  - **This chapter still has real untapped room** (Vector2/3/4, Plane, Ray, Rectangle, Point,
    MathHelper, and Bounding volumes have only one worked example each so far) — a good
    candidate for a fourth deepening pass if returning to it.
- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 790 lines (~4 → ~21 of a ~90-page target), unchanged
  since the prior session's third deepening pass. Full method coverage for the entire public
  surface; two real, verified, backend-specific gaps found from direct source reading
  (`SpriteBatch`/`RenderTarget2D` sampling on `SOFTWARE`; `SupportsCapability
  (MultipleRenderTargets)` never actually checked by any backend); a "Private implementation"
  section tracing all 8 private lifecycle methods; four worked examples with two real
  screenshots. This chapter was already assessed as "close to done at this depth" last
  session — further growth here should mean genuinely new ground (e.g. GraphicsAdapter/
  DisplayMode/multi-monitor), not re-explaining what's already there.

Volume I currently compiles to **137 pages, 643 index entries, 0 undefined references**.
**Volume II has not been touched in the expansion pass at all yet.**

Four screenshot demos now exist in `tools/cna-screenshot-infra/` (`software_screenshot_demo`,
`math_rotation_demo`, `rendertarget_roundtrip_demo`, `quaternion_vs_matrix_demo`), one CMake
patch covers all four. **Repeated lesson from this session**: when a worked example's
screenshot shows something unexpected, investigate before assuming a demo-code mistake — it
found two real bugs earlier this session. Trace the actual backend source before writing up a
finding; don't speculate.

## What to do next

Given both Ch.7 and Ch.9 have each had multiple deepening passes and both still have real
untapped room, but Volume II remains completely untouched, the strongest next moves are:

1. **Start Volume II** — it is at 0% of its own Phase 1 progress and is the single highest-value
   thing to do next. Ch.1 (Input System, ~70-page target) is a reasonable opening chapter.
2. **Deepen Chapter 7 further** toward ~110 pages (currently ~24) — Vector2/3/4, Plane, Ray,
   Rectangle, Point, MathHelper, and Bounding volumes each still have only one worked example.
3. **Start a new Volume I chapter** — Chapter 13 (Stock Effects, ~80-page target) is the next
   largest untouched Volume I Part III target; Ch.7/Ch.9's worked examples already use
   `BasicEffect` in passing, so there's a natural bridge.
4. **Push Chapter 9 a fourth time** only if a genuinely new angle presents itself (e.g. a
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
