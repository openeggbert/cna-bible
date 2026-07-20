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

**This session worked exclusively on Vol.I Ch.7 (Math and Core Types)**, per an explicit
author instruction to find and fix everything missing in that one chapter. It grew from
270 → 1240 lines (~4 → ~24-25 of a ~110-page target, measured by pdftotext-searching the PDF
for the chapter's own opening sentence and Chapter 8's heading to bound its real page range).
**Be honest about this with the author if asked: the chapter is substantially deepened and a
real number of previously-unnoticed gaps got fixed, but it remains well short of the
~110-page target even after a session focused on it exclusively.** Reaching that target for
real is several more sessions of the same kind of direct-source-reading work, not one more
pass.

### What actually got fixed this session (the important part)

The most valuable finding wasn't a new worked example — it was systematically grepping every
type's real header against the chapter's existing prose and discovering that
**`Equals`/`GetHashCode`/`ToString` are implemented by every single type in this chapter, but
had never been mentioned anywhere in the text.** Fixed with a new section right after the
chapter intro (`\S`\texttt{sec:shared-debug-surface}) documenting the shared triad once. That
same pass made good on the chapter's own opening-paragraph claim about
`CheckForNaNs()`/`getDebugDisplayStringProperty()`, and turned up two genuine findings while
verifying it: (1) neither helper is ever called from anywhere outside its own defining `.cpp`
file anywhere in the codebase (no test, no example, no other class; no `.natvis`/LLDB
summary-provider file exists either — both are currently unreachable through any public code
path); (2) the three vector types' `CheckForNaNs()` runs unconditionally in every build, while
`Matrix`'s and `Quaternion`'s are wrapped in `#if !defined(NDEBUG)` and compile to nothing in a
release build.

Also fixed a real accuracy gap: the vector "full method reference" never mentioned
`Length()`/`LengthSquared()`, despite the chapter's own very first worked example already
calling `toTarget.Length()` without the method ever having been named anywhere in the text.

Other real, source-verified additions this session: a full reference + worked example for
`Point` (previously only described in passing inside the Rectangle section); a full reference
for `CurveKeyCollection`'s `Count`/`IsReadOnly`/`Item`/`Clear`/`Clone`/`Contains`/`CopyTo`/
`IndexOf`/`RemoveAt`; a `Matrix` arithmetic-statics reference plus a `Decompose` worked example
(which itself turned up two more findings: a locally-duplicated `WithinEpsilon` in
`Matrix.cpp`'s own anonymous namespace, and a documented FNA-vs-CNA negative-zero sign
divergence); a `Quaternion` `Concatenate`-vs-`Multiply`/`operator*` ordering finding — derived
by hand from both methods' component formulas, then **verified numerically with a standalone
Python script** across five random quaternion pairs — showing `Concatenate(value1, value2)`
computes exactly `Multiply(value2, value1)`, i.e. the promised "value1 applied first" reading
is actually the right-to-left reading of `operator*`, not the left-to-right one the argument
order suggests; a second `Ray` worked example (nearest-of-several picking, since `Intersects`
calls don't return hits in distance order); and a precise correction to `Rectangle::IsEmpty`
(checks all four fields equal zero, not just zero area).

Volume I currently compiles to **145 pages, 716 index entries, 0 undefined references**.
**Volume II has not been touched in the expansion pass at all yet.**

### Known remaining gaps in Chapter 7 specifically (start here if returning to it)

- Vector2/Vector4-specific worked examples — both are currently only exercised via the shared
  Vector2 example and Matrix/Quaternion `Transform` overloads, never with anything
  Vector4-specific (e.g. its extra `Transform(Vector2/Vector3 input) -> Vector4` overloads).
- `Plane::Transform` has no worked example (only `DotCoordinate` does).
- `BoundingBox`/`BoundingFrustum` each still lack a worked example of their own beyond the
  shared bounding-volume examples (frustum culling, `CreateFromPoints`).
- `Matrix`'s billboard, constrained-billboard, shadow, and reflection factory methods are
  described in the reference table but none has a worked example.
- The chapter's target of ~110 pages implies substantially more per-type depth than a
  reference table + 1-2 worked examples each — consider whether further sessions should keep
  adding worked examples/findings at this same density, or whether the ~110-page figure itself
  needs revisiting with the author once the "what's actually missing" question has been asked
  of most chapters, not just this one.

### Other chapters, for context (untouched this session)

- **Vol.I Ch.9 (GraphicsDevice)**: 171 → 872 lines (~4 → ~23 of a ~90-page target), unchanged
  since the prior session. Full method coverage, three real backend-specific gaps documented
  (SpriteBatch/RenderTarget2D sampling; `SupportsCapability(MultipleRenderTargets)`;
  `IsProfileSupported`/`QueryRenderTargetFormat`/`QueryBackBufferFormat` only genuinely
  hardware-checked on D3D9), a multi-monitor `Adapters` enumeration subsection, a private
  lifecycle section, four worked examples with two real screenshots.
- Four screenshot demos exist in `tools/cna-screenshot-infra/` — unchanged this session, no
  new demo was needed (this session's additions were all numeric/source-grounded, not
  screenshot-based).

## What to do next

1. **If continuing Chapter 7**: work through the "known remaining gaps" list above — each is a
   concrete, scoped addition, not a re-read of what's already there.
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
  (`grep -n "label{...}"`) before compiling.
- **New this session**: when a hand-derived numeric/algebraic claim (e.g. "these two formulas
  are equivalent under argument swap") is going into the book, verify it with an actual
  computation (a throwaway Python/C++ script), not just by eye — one such claim in this
  session (`Concatenate` vs `Multiply`) was verified this way before being written down.
- **New this session**: to find genuine gaps in an already-"complete-looking" chapter,
  systematically grep the real header for every type it covers and diff against what the
  chapter's prose actually mentions — don't assume a "full method reference" is actually full
  just because it reads as thorough. This is how the `Equals`/`GetHashCode`/`ToString` gap (the
  single highest-value fix this session) was found.
