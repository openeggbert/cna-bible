# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history). If you're reading this mid-session rather than at the start of one, it may already
be stale relative to what's happened since — trust the conversation over this file in that case.

## Where things stand right now (end of session, 2026-07-20)

`CLAUDE.md` (durable project guide) and this file now exist. `PLAN.md` has the full expansion
plan: Phase 1 targets ~1,305 pages for Volume I and ~1,163 pages for Volume II, broken down
chapter-by-chapter. Both scope conflicts (free-direct/cna-extended staying marginal;
screenshots being real-or-nothing) are resolved, not open — see `PLAN.md`'s "Resolved" section
and its screenshot-feasibility section if you need the reasoning, but don't re-litigate them.

**The expansion has actually started.** Volume I Chapter 9 (GraphicsDevice) is the first
chapter touched: grew from 171 to 556 lines (~4 to ~13 pages, against a 90-page target — real
progress, not complete). It now has full coverage of render targets, vertex/index buffer
binding, the complete 17-overload `DrawUserPrimitives`/`DrawUserIndexedPrimitives` family,
back-buffer readback, and every `NOXNA` helper method — none of which the original chapter
covered. It also has a real worked example with a real, verified screenshot (built and ran
CNA's `SOFTWARE` backend headlessly; the PNG is at
`latex/volume1/images/ch09-drawprimitives-software.png`, embedded via a `Figure` environment,
confirmed correct by rendering the actual compiled PDF page). Volume I recompiles clean:
123 pages, 577 index entries, 0 undefined references.

This establishes the **per-chapter template** every subsequent chapter should follow:
1. Re-read the class's full header fresh (don't rely on this file or PLAN.md to carry
   method-level detail forward — they don't).
2. Keep existing narrative sections intact; add a full method-by-method reference under/beside
   them covering every overload, parameter, and exception the original chapter skipped.
3. Add at least one real worked example; where the chapter is graphics-facing and a real
   screenshot is feasible (see `PLAN.md`'s screenshot-feasibility notes for which backends
   currently can/can't), build and run it for real and embed the actual output — never fake one.
4. Recompile, grep for `undefined`, fix stale cross-references.
5. Commit and push.
6. Update `PLAN.md`'s status column + session log, and rewrite this file's "where things stand"
   section for the next session.

Whether Chapter 9 should be pushed further toward its 90-page target before moving on, or
whether to move to the next chapter now and return to deepen Chapter 9 later, is an open
judgment call for whichever session picks this up — nothing forces either order.

**Check `git log`/`git status` and the current chapter files' actual line counts before
trusting the numbers above at face value** — if a session ran after this note was written and
didn't update this file, this section is stale.

## What to do next

Two reasonable next steps, in order of what `PLAN.md` currently flags as most tractable:

- **Push Chapter 9 further** toward its ~90-page target (it's at ~13). More worked examples
  (a render-target round trip actually built and screenshotted, not just the code snippet
  currently in the chapter; a multi-render-target example) would close real gaps, not padding.
- **Start Chapter 7 (Math and Core Types)**, `latex/volume1/chapters/part2-getting-started/ch07-math-core-types.tex`,
  target ~110 pages (the largest single target in Volume I). The eleven math/geometry types
  (Vector2/3/4, Matrix, Quaternion, Point, Rectangle, Color, Plane, Ray, BoundingBox/Sphere/
  Frustum) were already read in full earlier this session for the Volume I API Quick Reference
  appendix (`latex/volume1/chapters/appendices/appendix-a-api-quick-reference.tex`) — re-read
  the actual headers again rather than trusting that appendix's condensed summaries, but it's
  a useful map of what exists before diving back into the full header text.

## Housekeeping reminders

- Branch: `claude/cna-bible-book-09gxp0`. Push there; never force-push.
- `make volume1`/`make volume2` from `latex/`; check the log for `undefined` every time.
- Small commits, pushed often — see `CLAUDE.md` for the full methodology list.
- `/workspace/cna` (or wherever `cna` gets cloned) does not persist across sessions — if a
  screenshot or source re-read needs a working clone, redo it per
  `tools/cna-screenshot-infra/README.md`.
