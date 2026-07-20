# The CNA Bible — project guide for Claude Code sessions

This repository is a two-volume LaTeX technical book about the `openeggbert/cna` ecosystem
(CNA: a C++23 reimplementation of the Microsoft XNA 4.0 programming model, built on SDL3 with
pluggable graphics backends). It is being written incrementally, across many sessions, by
Claude Code itself, under the direction of the repository's author.

**Start every session by reading `NEXT.md`**, not just this file — it carries the specific,
current-state context (what was just finished, what's in progress, what to do immediately
next) that this file deliberately does not repeat. Then read `PLAN.md` for the full task list
and per-chapter page targets. `PROGRESS.md` is the historical log of everything completed
before the current expansion phase started; useful for background, not for "what's next."

## Repository layout

- `latex/volume1/` — Volume I: *The Core Framework and the Graphics Machine*. Chapters under
  `chapters/part{1-4}-*/chNN-slug.tex`, one appendix under `chapters/appendices/`.
- `latex/volume2/` — Volume II: *The Ecosystem, the Platforms, and the Practice*. Chapters
  under `chapters/part{1-5}-*/chNN-slug.tex`, five appendices under `chapters/appendices/`.
- `latex/common/preamble.tex` — shared preamble (fonts, `cnacpp`/`cnashell` listings styles,
  hyperref, the `\cnaclass`/`\cnans`/`\repolink` macros, the `sourcenote` callout box). Shared
  by both volumes via `\input{../common/preamble.tex}`.
- `latex/Makefile` — `make volume1` / `make volume2` (latexmk, pdflatex).
- `PLAN.md` — the expansion project's task list, per-chapter page targets, methodology, open
  questions/conflicts, and a dated session log. This is the durable source of truth for what
  page count each chapter is aiming for and why.
- `NEXT.md` — short, current-state briefing for whichever session picks up work next. Update
  this at the **end** of every session (not just when a chapter finishes) so a fresh session
  with no memory of this conversation can resume correctly without re-deriving context.
- `PROGRESS.md` — historical record of the original ~230-page book's construction (both
  volumes' first complete pass, the content-completeness pass, the API quick-reference
  appendices, the index fix). Read for background; don't add new entries here — new work goes
  in `PLAN.md`'s session log and `NEXT.md`.
- `tools/cna-screenshot-infra/` — a patch, a demo source file, and a README documenting how to
  build CNA and capture a real, headless screenshot via its `SOFTWARE` graphics backend.
  `/workspace/cna` (or wherever `cna` gets cloned for a given session) does **not** persist
  across sessions — reapply this patch to a fresh clone whenever screenshot capture is needed.

## Build

```bash
cd latex && make volume1   # -> volume1/main.pdf
cd latex && make volume2   # -> volume2/main.pdf
```

Both use `latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error`. After any
edit, rebuild and grep the log for `undefined` before committing:

```bash
grep -i undefined latex/volumeN/main.log | grep -v "san-i-tiz"   # the "-tiz" exclusion is
                                                                   # for an unrelated sanitizer
                                                                   # mention in running prose
```

## Non-negotiable methodology (established across this whole project, not just the expansion)

- **Every claim is grounded in an actual source read.** Read the real header, `.cpp`
  implementation, test file, or `docs/*.md`/`plan_*.md`/`CHECKLIST.md` file before writing a
  sentence about it. Never paraphrase from memory or invent a plausible-sounding API surface.
  This project has caught and corrected its own stale/incorrect claims more than once
  (Vol. I Ch.8's original ".xnb reader doesn't exist" claim, later corrected) — treat that as
  the standard to hold every new page to, not an embarrassment to hide.
- **Screenshots: real or not at all.** Never fabricate, mock up, or AI-generate an image
  presented as a screenshot of running code. If a real one can't be captured for a given
  backend (see `tools/cna-screenshot-infra/README.md` for exactly which backends currently
  can/can't), say so explicitly in the chapter text instead of skipping the question silently.
- **Code examples must be real, compilable code**, adapted from an actual test or example call
  site wherever one exists — not invented from scratch, and never presented as verified when it
  wasn't actually compiled.
- **Recompile after every chapter or small batch of edits.** This project's most common real
  failure mode is a stale cross-reference (a plain-text "Chapter~17" citation, or a `\ref{}` to
  a label in the other volume) left behind after inserting or renumbering a chapter — grep for
  `Chapter~[0-9]` patterns project-wide after any renumbering and fix every stale one by hand.
- **Commit in small, descriptive increments and push after each one** — not one giant commit at
  the end of a session. This is what makes a multi-session project actually resumable.
- **Honor explicit author scope decisions even when they conflict with a later, broader
  instruction** — flag the conflict in `PLAN.md` and ask, don't resolve it silently by picking
  whichever reading is more convenient. (Two such conflicts already came up and were resolved
  this way: free-direct/cna-extended's scope cap vs. "every chapter must expand.")
- Cross-volume citations mostly use plain-text chapter numbers rather than `\ref{}` (the two
  volumes compile separately); the exceptions are resolved via `latex/volume2/xrefs-volume1.tex`,
  a small `\newlabel` shim mapping Volume I's labels to their real chapter numbers.
- `\cnaclass{}` and `\cnans{}` (in `preamble.tex`) both wrap their argument in `\texttt{}` *and*
  emit `\index{}` for it — this is how the back-of-book index gets populated. Keep using these
  macros for every class/method/namespace name rather than bare `\texttt{}`, or the index stops
  growing.
