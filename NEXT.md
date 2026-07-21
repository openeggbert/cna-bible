# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session (or the last checkpoint of an
in-progress autonomous one) — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, which is a permanent history, and which has the full
per-chapter detail this file only summarizes).

## Where things stand right now (mid-session, autonomous depth pass in progress, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last checkpoint: **329 pages, 0 undefined references, 0
duplicate-label warnings** (verify before quoting — re-run `make book` and grep the log
before trusting this number).

**This is an autonomous, long-running session** (the user explicitly authorized "continue
autonomously for as long as there is useful, safe work within scope" and asked not to be
interrupted with further questions unless something genuinely architecture-affecting comes
up). If you are picking this up fresh, there is no reason to stop and ask what to work on —
just continue the depth-pass task list below in order, using the same proven per-chapter
loop this whole project has used throughout: read current chapter → find a real,
source-grounded gap → write it → rebuild → render the chapter's own physical pages to PNG and
read them back → commit → push → move to the next chapter.

**Branch: `develop`.** A prior session merged the old feature branch into it; there is no
separate branch to look for. Commit and push directly to `develop`, small commits, one per
chapter, exactly as this whole session has been doing (check `git log --oneline -20` to see
the pattern if in doubt).

## This session's work so far: depth pass on Part I–II chapters (7 of ~18+ planned)

The prior session did a **breadth pass** (first-ever touch) on all 22 previously-untouched
Part I–IV chapters plus Appendix A. This session is doing the natural next step, a **depth
pass** (second, deeper touch, adding more real worked examples/findings per chapter) —
mirroring the exact pattern already validated multiple times on Parts V–IX in even earlier
sessions. Completed so far this session, each with a real new worked example or finding,
grounded in an actual source read, rebuilt and PNG-verified before commit:

- **Ch.1 What Is CNA** — added "Design goals in the project's own words" (all 6 real README
  goals) and a cross-backend "scale of verification" comparison table (test counts + method
  per backend, side by side).
- **Ch.2 Ecosystem Map** — added a real, previously-undocumented second-level sibling
  dependency: `free-direct` itself depends on a third repo, `free-api` (a ~1998-era WinAPI
  subset via SDL3), confirmed by reading `BackendSelection.cmake` directly; named
  `free-eggbert`/`planetblupi` as independent real consumers.
- **Ch.3 Design Philosophy** — added a validated-property-setter worked example
  (`SkinnedEffect::WeightsPerVertex`) and a full missing-dependency lifecycle worked example
  (`sharp-runtime`'s `BinaryReader::ReadChar`/`ReadDecimal` — real gap, documented stopgap,
  now properly implemented; verified against the current header).
- **Ch.4 Building CNA** — added real Android/NDK and Web/Emscripten build walkthroughs
  (grounded in `docs/devices-build.md` and the project's own real `emcc` 6.0.2 verification
  record, including a real `sharp-runtime` bug — `FileSystemWatcher.hpp`'s unconditional
  `inotify` fields — found and fixed along the way).
- **Ch.5 First Game** — added a third complete worked program (edge-bounce + `SoundEffect`,
  real `Viewport`-bounds clamp-in-same-branch finding).
- **Ch.6 Game Loop** — added a full `DrawableGameComponent` worked example
  (`FpsCounterComponent`), including the real `Add(IGameComponent*)` raw-pointer-ownership
  finding and the `DrawOrder` finding.
- **Ch.8 Content and Assets** — quoted two real `.cnj` files directly from `cnj.md` (a
  self-contained `SpriteFont` document and a `Texture2D` `sourceFile`/`colorKey` metadata
  sidecar).

**Every one of the above also had at least one genuine pre-existing overfull-hbox defect
found and fixed while reading the whole page** (not just the new content) — this remains the
single most common defect class in this whole project; see "Reusable findings" below for the
patterns that actually worked to fix them this time.

## Remaining depth-pass work, in the planned order (see Task list / PLAN.md)

Not yet started this session, roughly in the order a fresh session should continue in:

1. **Ch.10 SpriteBatch** through **Ch.16 Backend Architecture** (Part III tail + start of
   Part IV) — not yet touched this session.
2. **Ch.17 through Ch.24** (the rest of Part IV's backend chapters) — not yet touched this
   session.
3. **Appendix A** — not yet touched this session (already has a `GraphicsDevice`/state-object
   section from the prior breadth pass; look for what's still missing beyond that).
4. **Ch.7 (Math, ~33/110 pages) and Ch.9 (GraphicsDevice, ~23/90 pages)** — both already
   depth-passed multiple times in much earlier sessions; the previously-known gap lists are
   exhausted, so this needs fresh gap-hunting (diff the real header against the chapter's
   prose again, from scratch) rather than a ready-made list.
5. **Parts V–IX (chapters 25–48)** — each still 3–15 of a 30–70 page target; same "find a
   real, narrower gap and turn it into a worked example" approach as everything above.

None of this needs to happen in the exact order listed — it's a reasonable default sequence,
not a hard dependency chain. A session with limited time should prioritize finishing whichever
Part is already partway through (right now: finish Part III/IV's depth pass) before starting a
new Part, so the book doesn't end up with an uneven, hard-to-track patchwork of "which chapters
got a second touch."

## Reusable findings from this session, worth knowing before continuing

- **A non-floating `tabularx`/plain `tabular` that overflows the page width just runs text off
  the margin silently** — this happened repeatedly this session (Ch.1's new verification-scale
  table needed `tabularx` instead of `tabular`; several chapters had pre-existing long
  identifiers/paths overflow). The fix that actually works reliably, in order of preference
  tried this session:
  1. First try `\allowbreak{}` at natural boundaries (underscores, `::`, `/`) inside the long
     token. Sometimes needs 2–3 rounds of adding more break points before it actually resolves
     — don't assume one round fixed it; **always re-render the exact page at 150dpi+ and look**.
  2. If that doesn't work after 2 rounds, **restructure the sentence** so the long
     identifier(s) are split into multiple shorter `\texttt{}` tokens with ordinary prose
     between them (e.g. "has three constructors: X; a second form additionally taking Y; and Z"
     instead of one comma-separated run of three full signatures). This was the *only* thing
     that worked for a couple of the worst cases this session (Ch.8's `ContentManager`
     constructor list, Ch.24's blend-factor list) — don't keep chasing `\allowbreak` placement
     past two failed attempts, switch to restructuring instead.
- **`grep -i overfull main.log` remains unreliable as a check** — it was empty in every single
  build this session, even immediately before rendering a page to PNG and finding a real,
  visible overflow. Treat it as worthless for this project specifically; PNG rendering at
  100–150dpi and actually reading the page is the only check that has ever caught anything,
  all session.
- **Verify every real API call in a worked example against the actual header before writing
  it down, every time, even for "obvious" things.** This session caught a real mistake this
  way: a first draft of the `FpsCounterComponent` example (Ch.6) used
  `TimeSpan::operator+=`, which `sharp-runtime`'s `TimeSpan.hpp` does not declare (only
  `operator+`) — caught by grepping the header before commit, not after. Two similar
  self-authored mistakes were also caught and fixed in the *prior* session (a math error in a
  blend-formula claim, a forward-reference ordering bug) — this is a real, recurring risk
  category for this specific kind of writing (plausible-sounding C++ that doesn't actually
  compile against the real headers), not a one-off.
- **`GameComponentCollection::Add(IGameComponent*)` takes a raw, non-owning pointer** — any
  worked example registering a component needs to keep it alive itself (a plain member field
  outliving the collection), not a temporary or a forgotten `new`.
- **Two-level (and deeper) sibling dependencies exist in this ecosystem beyond what the
  Ecosystem Map chapter's own table shows** — `free-direct` depends on `free-api`. Worth
  checking whether any other sibling repo has its own further `add_subdirectory(../something)`
  the same way, next time Ch.2 or the repo-map appendix gets touched again.

## Housekeeping reminders (unchanged from before, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log for `undefined` and
  `multiply defined`/`multiply-defined` every time — these two checks *are* reliable, unlike
  the `overfull` grep (see above).
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed in this
  environment as of this session — verify with `command -v latexmk` if in doubt, but do not
  expect to need to reinstall.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`) live at
  `/rv/data/development/github.com/openeggbert/<name>` in this environment — not `/workspace`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`), never assume printed page N is
  physical page N. A blank padding page immediately before a new Part's or chapter's
  right-hand start is normal book layout, not a rendering defect.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway — grep for `Chapter~[0-9]` in any chapter
  you touch as routine, not just when you happen to notice one.
- No task is currently blocked/`needs_human` — everything found so far has been resolvable by
  reading more source. If a genuine architectural ambiguity comes up (not just "which chapter
  to do next," which is explicitly not one), mark it clearly in this file and in `PLAN.md`'s
  session log, and move on to another chapter rather than stalling the whole session.
