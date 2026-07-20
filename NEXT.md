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

**Two consecutive sessions have now worked exclusively on Vol.I Ch.7 (Math and Core Types)**,
per explicit author instruction both times. It has grown from 270 → 1473 lines (~4 → ~29 of a
~110-page target, measured by pdftotext-searching the compiled PDF for the chapter's own
opening sentence and Chapter 8's heading, not estimated from line count alone). **Be honest
about this with the author if asked: the chapter keeps getting genuinely, substantively
deeper — every session so far has found and fixed real gaps, not padded — but it is still
under 30% of its page target after two sessions focused on nothing else.** Reaching ~110 pages
this way is realistically several more sessions of the same density of work.

### What this session added (on top of the prior session's shared-surface/Length/Decompose/Concatenate work)

Worked through the prior session's own "known remaining gaps" list item by item, each as a new
`\subsection` with source-grounded code:

- **`Vector4`'s extra `Transform(Vector2/Vector3 input) -> Vector4` overloads**: tied to
  something real rather than invented — CNA's own `SOFTWARE` backend rasterizer
  (`SoftwareGraphicsBackend.cpp`) calls exactly this overload to build clip-space vertices
  before the perspective divide; `Vector3::Transform` would have silently discarded the `W`
  component that step needs.
- **`Matrix::CreateBillboard`**: worked example plus its real degenerate-case handling
  (`BillboardEpsilon = 0.0001f`, falling back to `cameraForwardVector`/`Vector3::Forward` when
  object and camera positions coincide).
- **`Matrix::CreateShadow`/`CreateReflection`**: worked example plus a real asymmetry —
  `CreateReflection` normalizes its input `Plane` defensively; `CreateShadow` does not. Caught
  and fixed a matrix-multiplication-order mistake in this example's own first draft before
  finalizing it (row-vector convention: the object's own world matrix goes on the left).
- **`Plane::Transform`**: worked example demonstrating the real inverse-transpose technique it
  uses internally. The first draft used an axis-aligned normal under a diagonal scale — a
  quick Python check showed this produces **no visible discrepancy** between the naive and
  correct approaches (an axis-aligned normal under a diagonal scale doesn't change direction).
  Replaced with a genuinely sloped normal and re-verified numerically before writing it down.
- **`BoundingBox::Contains(Vector3)`**: a dedicated trigger-volume worked example.
- **`BoundingFrustum::Contains`** (vs. `Intersects`): a worked example built around a real
  finding read from `BoundingFrustum.cpp` — it short-circuits to `Disjoint` the moment any one
  of the six planes tests `Front`, and only reports full `Contains` when every plane comes back
  `Back` — exactly the distinction a LOD system can use to skip per-submesh culling.

Volume I currently compiles to **149 pages, 740 index entries, 0 undefined references**.
**Volume II has not been touched in the expansion pass at all yet.**

### Known remaining gaps in Chapter 7 (start here if returning to it again)

- `Matrix::CreateConstrainedBillboard` still has no worked example (only plain
  `CreateBillboard` does now).
- `Matrix::CreateOrthographic`/`CreateOrthographicOffCenter` have no worked example — every
  existing Matrix example in this chapter uses a perspective projection.
- `BoundingSphere::Transform` (translation + uniform scale only) has no worked example
  demonstrating its documented limitation with a non-uniform scale.
- `Quaternion::Lerp` vs. `Slerp` — the chapter documents both and has a `Slerp` worked example,
  but no side-by-side example showing *why* `Lerp`'s non-uniform angular velocity actually
  matters (e.g. a visible speed-up/slow-down artifact over a large rotation).
- The chapter's target of ~110 pages implies substantially more per-type depth than a
  reference table + 2-3 worked examples each — as flagged in the prior session's note, it may
  be worth revisiting the ~110-page figure itself with the author once "what's actually
  missing" has been asked of more chapters than just this one.

### Other chapters, for context (untouched these last two sessions)

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 872 lines (~4 → ~23 of a ~90-page target). Full method
  coverage, three real backend-specific gaps documented, a multi-monitor `Adapters`
  enumeration subsection, a private lifecycle section, four worked examples with two real
  screenshots.
- Four screenshot demos exist in `tools/cna-screenshot-infra/` — unchanged these last two
  sessions; no new demo was needed (recent additions have all been numeric/source-grounded).

## What to do next

1. **If continuing Chapter 7**: work through the "known remaining gaps" list above.
2. **Start Volume II** — it is at 0% of its own Phase 1 progress and is the single highest-value
   thing to do next across the whole project. Ch.1 (Input System, ~70-page target) is a
   reasonable opening chapter.
3. **Deepen Chapter 9 further**, or start a new Volume I chapter (Chapter 13, Stock Effects,
   ~80-page target, is the next largest untouched Volume I Part III target).

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
  before compiling.
- **Verify hand-derived numeric/algebraic claims with an actual computation** (a throwaway
  Python/C++ script) before writing them into the book — this session's `Plane::Transform`
  example would have shipped a misleading (accidentally-non-discrepant) worked example without
  that check; the prior session's `Concatenate`-vs-`Multiply` finding was caught the same way.
- **To find genuine gaps in an already-"complete-looking" chapter**, systematically grep the
  real header for every type it covers and diff against what the chapter's prose actually
  mentions — this is how both sessions' highest-value findings surfaced (the missing
  `Equals`/`GetHashCode`/`ToString` mention, and this session's clip-space `Vector4::Transform`
  tie-in to the real `SOFTWARE` backend source).
- **Double-check matrix/quaternion composition order** against XNA's row-vector convention
  before writing a multi-matrix worked example — this session caught and fixed one such mistake
  (`characterWorldMatrix * shadowMatrix`, not the reverse) before it shipped.
