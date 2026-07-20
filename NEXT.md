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

- **Vol.I Ch.7 (Math and Core Types)**: 270 → 974 lines (~4 → ~28 of a ~110-page target). All
  11 type-families have a full reference and at least one worked example. Six type-families now
  have a *second* worked example: Quaternion (numeric+visual Matrix-vs-Quaternion equivalence
  proof), Color (`FromNonPremultiplied`), Curve (`Cycle`/`Oscillate`/`CycleOffset`), Vector3
  (`Cross` — this filled a real, previously-undocumented gap: `Cross` had never been mentioned
  anywhere in the chapter despite being the one shared-vector-family method that's genuinely
  Vector3-only), Plane (`DotCoordinate` half-space test), Rectangle (`Intersect`/`Union`),
  MathHelper (`WrapAngle`), and Bounding volumes (`BoundingSphere::CreateFromPoints`, with an
  honest note that it's a fast approximation, not an exact minimum-enclosing-sphere solver).
  **Remaining untapped room**: Vector2/Vector4-specific angles, Point, and Ray each still have
  only one worked example; Ray's mouse-picking example could grow a second (e.g. a `BoundingBox`
  raycast for tile-based picking).
- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 872 lines (~4 → ~23 of a ~90-page target). Full method
  coverage for the entire public surface; three real, verified, backend-specific gaps found
  from direct source reading: (1) `SpriteBatch` can't correctly sample a `RenderTarget2D` on
  `SOFTWARE`; (2) `SupportsCapability(MultipleRenderTargets)` returns `true` universally since
  no backend's override actually checks it; (3) **new this session** — `IsProfileSupported`,
  `QueryRenderTargetFormat`, and `QueryBackBufferFormat` are only genuinely hardware-checked on
  the D3D9 backend (real `D3DCAPS9`/`CheckDeviceFormat`/`CheckDeviceType` queries); every other
  backend's source honestly comments (labelled `D9-101`/`D9-102`) that it deliberately does not
  fake a capability table, falling back to unconditional `true` / a simplified format check /
  a hardcoded `SurfaceFormat::Color` instead. Also added this session: a multi-monitor
  enumeration subsection using the static `Adapters` list, with a worked example letting a
  player pick which physical display a `GraphicsDevice` opens against (there is no
  `GraphicsDeviceManager`-level adapter selector — the adapter goes straight into
  `GraphicsDevice`'s constructor/`Reset`). Plus the existing "Private implementation" section
  (8 private lifecycle methods traced from `GraphicsDevice.cpp`) and four worked examples with
  two real screenshots from prior sessions.

Volume I currently compiles to **139 pages, 654 index entries, 0 undefined references**.
**Volume II has not been touched in the expansion pass at all yet.**

Four screenshot demos exist in `tools/cna-screenshot-infra/` (`software_screenshot_demo`,
`math_rotation_demo`, `rendertarget_roundtrip_demo`, `quaternion_vs_matrix_demo`) — unchanged
this session, no new demo was needed (this pass's new worked examples were all numeric/source-
grounded, not screenshot-based). One CMake patch covers all four.

**Repeated lesson from this session**: before writing a "full method reference," actually grep
the real header for methods the chapter's own prose doesn't mention yet (`Vector3::Cross` had
been missed entirely across three prior passes on this chapter) — don't assume a chapter's
existing reference table is complete just because it reads as thorough.

## What to do next

Given both Ch.7 and Ch.9 have each now had multiple deepening passes and both still have real
untapped room, but Volume II remains completely untouched, the strongest next moves are:

1. **Start Volume II** — it is at 0% of its own Phase 1 progress and is the single highest-value
   thing to do next. Ch.1 (Input System, ~70-page target) is a reasonable opening chapter.
2. **Deepen Chapter 7 further** toward ~110 pages (currently ~28) — Point, Ray, and the
   Vector2/Vector4-specific surfaces each still have only one worked example.
3. **Start a new Volume I chapter** — Chapter 13 (Stock Effects, ~80-page target) is the next
   largest untouched Volume I Part III target; Ch.7/Ch.9's worked examples already use
   `BasicEffect` in passing, so there's a natural bridge.
4. **Push Chapter 9 a fifth time** only if a genuinely new angle presents itself — this
   chapter's public surface, private lifecycle, render targets/MRT, back-buffer readback, and
   now `GraphicsAdapter`/format-query behavior are all covered in real depth; further passes
   should target genuinely new ground, not re-explain what's already there.

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
- When adding a new `\S\ref{...}` cross-reference, double check the label actually exists
  (`grep -n "label{...}"`) before compiling — an invented label silently compiles as "??" or
  triggers an "undefined" warning that's easy to miss among LaTeX's other routine warnings.
