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

**Three consecutive sessions have now worked exclusively on Vol.I Ch.7 (Math and Core
Types)**, per repeated explicit author instruction. It has grown from 270 → 1632 lines
(~4 → ~33 of a ~110-page target, measured by pdftotext-searching the compiled PDF for the
chapter's own opening sentence and Chapter 8's heading). **Be honest about this with the
author if asked: the chapter keeps getting genuinely deeper — every session has found and
fixed real gaps or added real, source-grounded worked examples, none of it padding — but it
is still under a third of its page target after three sessions focused on nothing else.**

### What this (third) session added

Worked through the second session's own remaining-gaps list:

- **`Matrix::CreateConstrainedBillboard`**: worked example (a tree-foliage billboard
  constrained to the vertical axis) plus a real second finding — it has its own independent
  epsilon, `BillboardParallelEpsilon = 0.9982547f` (${\approx}3.39°$ from parallel, computed
  precisely), guarding against the camera direction being nearly parallel to the constrained
  rotation axis, on top of `CreateBillboard`'s own object/camera-coincidence guard.
- **`Matrix::CreateOrthographic`**: worked example built around a real one in CNA's own test
  suite (a shadow-map light-space projection), explaining precisely why orthographic (not
  perspective) is correct there — clip-space `W` is always `1`, ties back to the earlier
  `Vector4::Transform` clip-space finding from session two.
- **`Quaternion::Lerp` vs. `Slerp`**: a numerically-verified angular-velocity comparison
  (standalone script run before writing it down) — both agree exactly at $t=0$, $0.5$, $1$ for
  a 150° test rotation, but `Lerp` eases in/out around that midpoint while `Slerp` stays
  perfectly uniform at every sampled point.
- **`BoundingSphere::Transform`** under a non-uniform scale: confirmed (by reading
  `BoundingSphere.cpp` and hand-computing the expected value) that the resulting radius is the
  original radius times the *largest* single axis scale factor — deliberately conservative,
  not merely wrong.

Volume I currently compiles to **153 pages, 744 index entries, 0 undefined references**.
**Volume II has not been touched in the expansion pass at all yet.**

### Chapter 7's remaining-gaps list is now largely exhausted

Three sessions have worked through essentially every concrete gap identified so far. A fourth
session returning to this chapter should **not** expect a ready-made list — it needs to
rediscover fresh gaps the same way the first session found the biggest one
(`Equals`/`GetHashCode`/`ToString` never mentioned anywhere): systematically grep every real
header this chapter covers against what the chapter's prose currently says, rather than
re-reading what's already there. A few possible starting angles, not yet checked:
- `CurveKey`'s own arithmetic/interpolation behavior in more depth (only `Curve::Evaluate` and
  the loop-type worked examples exist so far; nothing exercises a single `CurveKey`'s tangent
  fields directly).
- Whether any of the eleven type families have a constructor overload or static factory this
  book hasn't named yet — worth a second full grep pass now that three sessions' worth of
  additions may have shifted what looks "complete."
- Cross-type composition worked examples (e.g. a `BoundingFrustum` built from a `Matrix` that
  itself came from `CreateLookAt`/`CreatePerspectiveFieldOfView`, tying multiple sections
  together in one example) rather than more single-type depth.
- At this point it may be more valuable to ask the author directly whether to keep deepening
  Chapter 7 a fourth time, or to treat ~33/110 pages as "deep enough for now" and move to
  Volume II (completely untouched) or another Volume I chapter — three sessions of diminishing
  novel-finding density is a reasonable point to check in, rather than assuming indefinitely
  more passes are automatically wanted.

### Other chapters, for context (untouched these last three sessions)

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 872 lines (~4 → ~23 of a ~90-page target).
- Four screenshot demos exist in `tools/cna-screenshot-infra/` — unchanged; no new demo needed
  (recent Ch.7 additions have all been numeric/source-grounded, not screenshot-based).

## What to do next

1. **If continuing Chapter 7**: read the "remaining-gaps list is now largely exhausted"
   section above first — this is no longer a simple checklist to work through.
2. **Consider asking the author** whether to keep deepening Chapter 7 or move on — three
   sessions in a row on one chapter is worth a check-in, not an assumption.
3. **Start Volume II** — 0% of its own Phase 1 progress, the single highest-value thing to do
   next across the whole project. Ch.1 (Input System, ~70-page target) is a reasonable
   opening chapter.
4. **Deepen Chapter 9 further**, or start Chapter 13 (Stock Effects, ~80-page target).

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value.**

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- `make volume1`/`make volume2` from `latex/`; check the log for `undefined` every time.
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (or wherever `cna` gets cloned) does not persist across sessions — if a
  screenshot or source re-read needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`.
- After embedding any new screenshot, verify it actually rendered correctly by converting the
  relevant compiled PDF page to an image and reading it back (`pdftoppm` + the `Read` tool).
- Avoid hardcoding a section/figure number as plain text inside a code comment or prose.
- When adding a new `\S\ref{...}` cross-reference, double check the label actually exists
  before compiling — this session caught two invented/misattributed cross-references (one
  citing the wrong section for a finding, one citing a section that hadn't happened yet in
  reading order) before they made it into a commit.
- **Verify hand-derived numeric/algebraic claims with an actual computation** before writing
  them into the book — this session's `Quaternion::Lerp`-vs-`Slerp` comparison and the prior
  session's `Plane::Transform` example were both checked this way; the `Plane::Transform`
  check specifically caught a first-draft example that would have shown *no* discrepancy at
  all (an axis-aligned normal under diagonal scale hides the very effect being demonstrated).
- **To find genuine gaps in an already-"complete-looking" chapter**, systematically grep the
  real header for every type it covers and diff against what the chapter's prose actually
  mentions.
- **Double-check matrix/quaternion composition order** against XNA's row-vector convention
  before writing a multi-matrix worked example.
