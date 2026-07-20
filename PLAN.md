# The CNA Bible — Expansion Plan (1000–2000 pages per volume)

**Status: Phase 1 planning complete, execution starting. This is a long-running,
multi-session project — this file is the durable task list and progress tracker across
sessions. Update the status column and the session log at the bottom every session.**

## The ask, restated honestly

The author's target is roughly 1000–2000 pages **per volume** (currently ~114 pages in
Volume I, ~119 in Volume II — each chapter needs to grow to roughly 10–20× its current
length). This is not achievable in one sitting; it is a genuine multi-session content
project, expected to take many further sessions of focused writing, verification, and
compilation. This file exists so that work can stop and resume cleanly across sessions
without losing track of what's done, what's next, and what page target each chapter is
aiming for.

**Phase 1 target (this plan's committed scope): ~1,300 pages for Volume I, ~1,200 pages
for Volume II (~2,500 combined).** This lands solidly inside the requested 1000–2000/volume
range without overclaiming the top of it. Reaching the very top of the range (2000/volume)
is a **Phase 2 stretch goal** — once every chapter below hits its Phase 1 target, a second
pass can go deeper still (more worked examples, more edge-case coverage) if the author wants
to keep going. Phase 2 targets are not yet broken out per chapter; revisit once Phase 1 is
done.

## Author's answers to the scoping questions (2026-07-20)

- **Expansion style:** full API documentation (every method, overload, parameter, exception,
  per class — not the condensed summary style the two Quick Reference appendices already
  use) **plus** more worked examples/tutorials. Not a narrative/history-depth expansion —
  design rationale and FNA/XNA comparisons stay at their current depth unless a worked
  example naturally needs one.
- **Structure:** expand the existing ~24 chapters per volume in place. Do **not** fragment
  into one-chapter-per-class. The Part/chapter structure in both `main.tex` files stays as-is.
- **Pace:** long-running incremental project. Work through this list across many sessions;
  commit and push after each chapter (or small batch of chapters); recompile and check for
  new undefined references/errors before every push, exactly as every prior pass in this
  project has done.
- **Code examples and screenshots (2026-07-20, follow-up instruction):** every expanded
  chapter needs real, compilable code examples (already implied by "worked examples" above,
  now stated explicitly), and graphics-facing chapters should additionally include real
  screenshots of the example programs actually running wherever that's feasible. A feasibility
  check of building/running CNA and capturing real screenshots in this environment is
  in progress as of this session — see the session log for what it found and how screenshot
  coverage got scoped as a result (this environment is a headless remote container with no
  guaranteed GPU/display, so the realistic answer may be "some backends yes, others no" rather
  than uniform coverage across every chapter).

## Methodology (unchanged from the rest of this project)

- Every new page must be grounded in an actual source read: the class's own header, its
  `.cpp` implementation where it clarifies behavior, and its test file where one exists (test
  files are often the best source of a realistic, runnable usage example — prefer adapting a
  real test's call pattern over inventing a new example from scratch).
- "Full API documentation" means: every public method and overload gets its own subsection —
  signature, each parameter's meaning/units/valid range, return value, every documented
  exception and when it's thrown, and (per the author's second answer) a short worked example
  showing it called in context, not just a signature restated in prose.
- Every worked example must be real, compilable code — adapted from an actual test/example
  call site wherever one exists, not invented from scratch and never presented as tested when
  it wasn't actually compiled.
- **Screenshots: real or not at all.** Where a chapter includes a screenshot of an example
  program running, it must be a real, actually-captured image from an actually-built and
  actually-run CNA program in this environment — never a mockup, a hand-drawn diagram
  presented as a screenshot, or an AI-generated image. If a given backend/chapter genuinely
  cannot produce a real screenshot in this environment (no GPU, no display, a backend that
  needs Windows/Wine, etc.), the chapter says so explicitly and either omits the screenshot or
  substitutes a real, clearly-labeled textual/ASCII capture instead — it does not fake one.
- Recompile (`make volume1` / `make volume2`) after every chapter or small batch; grep the log
  for `undefined` before moving on; fix any stale cross-references immediately (this project's
  established failure mode after any renumbering or heavy insertion).
- Keep committing in small, reviewable increments with descriptive messages — not one giant
  commit at the end. Push after each one.
- Update this file's status column and append a dated entry to the session log at the bottom
  every time work stops, so the next session (which may not share this conversation's context)
  can pick up correctly.

## Open conflicts to flag (do not resolve silently)

Two earlier, explicit author instructions from this same project narrow scope in a way that
now conflicts with "every chapter must expand":

1. **Vol. II Ch.13 (free-direct deep dive)** was explicitly capped by the author at ~2 pages,
   as part of a combined "5–10 pages total for free-direct across both volumes" instruction.
   Expanding it to a full ~35-page chapter directly contradicts that.
2. **cna-extended**, in Vol. II Appendix C, was explicitly kept to "one paragraph, not a
   dedicated chapter, only marginal coverage" by author instruction.

**Default unless told otherwise:** honor the newer, blanket "every chapter must expand"
instruction for Ch.13 specifically (it is a real chapter with a real class surface to
document — `free-direct`'s own DirectDraw/DirectSound/DirectPlay API), but leave the
cna-extended appendix paragraph as-is (it was never a chapter, and "expand every chapter"
doesn't obviously reach a one-paragraph appendix aside). Flag this row in the table below so
the author can override either default at any time.

## Volume I — target ~1,300 pages (24 chapters + Appendix A)

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 1 | What Is CNA | 145 | 20 | More ecosystem history/context; still narrative, light expansion | Not started |
| 2 | Ecosystem Map | 141 | 25 | Deeper per-repo detail, more cross-links | Not started |
| 3 | Design Philosophy | 256 | 30 | More NOXNA-discipline worked examples | Not started |
| 4 | Building CNA | 173 | 35 | Full CMake option reference, per-platform build walkthroughs | Not started |
| 5 | First Game | 131 | 40 | Multiple complete worked example programs, step-by-step | Not started |
| 6 | Game Loop | 216 | 40 | Full `Game`/`GameTime`/`GameWindow` method-by-method docs + examples | Not started |
| 7 | Math and Core Types | 270 | 110 | Full method docs for all 11 types (Vector2/3/4, Matrix, Quaternion, Point, Rectangle, Color, Plane, Ray, 3 Bounding types) + worked examples per type | Not started |
| 8 | Content and Assets | 125 | 55 | Full `ContentManager` API + CNJ/XNB worked walkthroughs | Not started |
| 9 | GraphicsDevice | 171 | 90 | Full method-by-method docs for the 887-line header | Not started |
| 10 | SpriteBatch | 130 | 55 | Every `Begin`/`Draw`/`DrawString` overload documented + examples | Not started |
| 11 | Textures and Render Targets | 207 | 60 | Full `Texture2D`/`RenderTarget2D` API + examples | Not started |
| 12 | Models and Meshes | 103 | 60 | Full `Model`/`ModelMesh`/`ModelBone` family + examples | Not started |
| 13 | Stock Effects | 191 | 80 | Full property/method docs for all 5 effects + examples each | Not started |
| 14 | State Objects | 159 | 55 | Full `BlendState`/`DepthStencilState`/`RasterizerState`/`SamplerState` docs | Not started |
| 15 | Shader/.fx Gap | 78 | 30 | More worked examples of the runtime-compiled path | Not started |
| 16 | Backend Architecture | 133 | 40 | Deeper interface-by-interface backend contract docs | Not started |
| 17 | SDL_Renderer Backend | 115 | 55 | Full bug-list detail, more worked examples | Not started |
| 18 | EasyGL Backend | 100 | 65 | Deeper feature-by-feature coverage | Not started |
| 19 | Vulkan Backend | 110 | 65 | Deeper feature-by-feature coverage | Not started |
| 20 | BGFX Backend | 87 | 55 | Full 38-gap-list detail with worked repro examples | Not started |
| 21 | WebGPU Backend | 108 | 45 | Deeper feature-by-feature coverage | Not started |
| 22 | Direct3D Backends | 152 | 85 | Split attention across D3D9/D3D11/D3D12 in full | Not started |
| 23 | Canvas/ASCII Backends | 139 | 40 | More worked examples | Not started |
| 24 | DX3/free-direct Backend | 65 | 30 | Deeper coverage (see free-direct conflict note above) | Not started |
| A | API Quick Reference | 229 | 40 | Expand summary tables into fuller per-class entries, still a reference (not full docs — that lives in the narrative chapters above) | Not started |

**Volume I subtotal: ~1,305 pages.**

## Volume II — target ~1,200 pages (24 chapters + Appendices A–E)

| # | Chapter | Current (lines) | Target (pages) | Approach | Status |
|---|---------|-----------------:|----------------:|----------|--------|
| 1 | Input System | 170 | 70 | Full Keyboard/Mouse/GamePad/TouchPanel docs + examples | Not started |
| 2 | Audio System | 118 | 60 | Full SoundEffect family docs + examples | Not started |
| 3 | Media | 103 | 45 | Full Song/MediaPlayer/MediaLibrary docs + examples | Not started |
| 4 | Devices and Sensors | 115 | 45 | Full sensor API docs + examples | Not started |
| 5 | GamerServices | 117 | 55 | Full Achievement/Leaderboard/Gamer docs + examples | Not started |
| 6 | Networking | 125 | 70 | Full NetworkSession/NetworkGamer docs + worked multi-peer examples | Not started |
| 7 | Avatar | 131 | 55 | Full Avatar/SkinnedModelEXT docs + examples | Not started |
| 8 | Storage | 78 | 30 | Full StorageDevice/StorageContainer docs + examples | Not started |
| 9 | Sharp Runtime Overview | 116 | 40 | Deeper architectural detail | Not started |
| 10 | Sharp Runtime Namespaces | 90 | 70 | Full docs for TimeSpan/EventHandler/Stream/collections + examples | Not started |
| 11 | Parity Philosophy | 111 | 35 | More worked deviation examples | Not started |
| 12 | EasyGL Deep Dive | 112 | 55 | Deeper coverage | Not started |
| 13 | free-direct Deep Dive | 65 | 35 | **See open conflict note above before expanding** | Not started |
| 14 | Windows/Wine | 103 | 45 | Deeper verification detail | Not started |
| 15 | Web/Emscripten | 88 | 40 | Deeper build/deploy detail | Not started |
| 16 | Android/NDK | 82 | 40 | Deeper build/deploy detail | Not started |
| 17 | Verification Methodology | 68 | 35 | More worked audit examples | Not started |
| 18 | Migration Guide | 102 | 55 | Full worked porting walkthroughs | Not started |
| 19 | Blupi Case Study | 116 | 55 | Deeper call-site audit detail | Not started |
| 20 | xna4-spec Auditing | 74 | 40 | More worked audit examples | Not started |
| 21 | Samples and Examples | 54 | 45 | Per-sample summaries, more of the 86 samples covered | Not started |
| 22 | Project Practice | 100 | 40 | Deeper task-tracking-methodology detail | Not started |
| 23 | Testing Philosophy | 103 | 45 | More worked test examples | Not started |
| 24 | Roadmap | 82 | 30 | Deeper detail | Not started |
| A | Feature Matrix | 58 | 15 | Modest expansion, stays a reference table | Not started |
| B | Glossary | 74 | 15 | More terms | Not started |
| C | Repo Map | 127 | 20 | Modest expansion | Not started |
| D | NOXNA Catalog | 114 | 20 | More entries | Not started |
| E | API Quick Reference | 155 | 25 | Modest expansion, stays a reference | Not started |

**Volume II subtotal: ~1,195 pages.**

## Session log

- **2026-07-20 (this session):** Author restated the original 1000–2000-page/volume target
  and asked for this plan. Asked 3 scoping questions (expansion style, structure, pace) via
  AskUserQuestion; answers recorded above. Surveyed current per-chapter line counts for both
  volumes. Wrote this file with per-chapter Phase 1 page targets summing to ~1,305 (Vol. I)
  and ~1,195 (Vol. II). Flagged the free-direct and cna-extended scope conflicts. Execution has
  not yet started — next session should begin with Volume I Chapter 7 (Math and Core Types) or
  Chapter 9 (GraphicsDevice), the two largest, most mechanically tractable targets (full method
  documentation pulled directly from already-read headers), to establish the expanded-chapter
  template other chapters will follow.
