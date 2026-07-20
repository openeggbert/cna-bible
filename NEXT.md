# Next session — start here

**Read this file first, then `PLAN.md` for the full task list.** This file is a snapshot of
exactly where things stand as of the end of the last session — it gets overwritten each
session, not appended to (unlike `PLAN.md`'s own internal session log, which is a permanent
history, and which has the full per-chapter detail this file only summarizes).

## Where things stand right now (end of session, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean: **321 pages, 0 undefined references, 0 duplicate-label warnings, 1321 index
entries** (verify before quoting — this was true as of the last build this session).

**Branch note, important:** this session merged the working branch
(`claude/cna-bible-book-09gxp0`) into `develop` via fast-forward early on, per explicit author
instruction, and has been committing directly to `develop` (pushed after every chapter) ever
since. There is no longer any unmerged work sitting on the old feature branch — `develop` is
the live branch to keep working on.

## This session's headline result: Part I–IV breadth pass, complete

At the start of this session, only Chapters 7 and 9 (of Parts I–IV, chapters 1–24 + Appendix A)
had ever been touched by the expansion project — every other chapter was still at its original,
pre-expansion length. This session did a **first breadth pass on all 22 previously-untouched
chapters, plus Appendix A** — the same "touch every chapter once" pattern already proven on
Parts V–IX in earlier sessions. Every one of the following got a real, source-grounded addition
(usually one or two worked examples grounded in an actual header/test/`.cpp` read, sometimes a
corrected inaccuracy), was rebuilt, and had its own physical PDF pages rendered to PNG and read
back before committing:

**Part I (Ecosystem):** Ch.1 What Is CNA (history, licensing, a real audit-methodology
worked example), Ch.2 Ecosystem Map (fixed 3 stale chapter-ref placeholders), Ch.3 Design
Philosophy (real NOXNA self-verifying-check worked example, corrected an imprecise claim about
the NOXNA mechanism also present in Ch.1).

**Part II (Getting Started):** Ch.4 Building CNA (full CMake option reference table), Ch.5
First Game (second worked example: keyboard movement, found the first example's `Draw`
overload is `NOXNA`-only), Ch.6 Game Loop (`GameServiceContainer` + `PresentationMode` worked
examples, fixed a running-header overflow), Ch.8 Content and Assets (`ContentManager`
reference + a real manifest-introspection worked example, fixed 4 stale `Chapter~N` citations
including one pointing at the wrong chapter).

**Part III (Graphics Core, Ch.10–15 — now fully depth-passed alongside the already-done Ch.9):**
Ch.10 SpriteBatch (`Draw` overload table — first attempt as a non-floating `tabularx`
literally broke with an empty column when the table ran taller than one page; fixed with
`longtable`), Ch.11 Textures/Render Targets (`Texture2D` `SetData`/`GetData` worked example),
Ch.12 Models and Meshes (bone-transform draw loop + `AnimationPlayer` example adapted from its
own test fixture), Ch.13 Stock Effects (`BasicEffect` lighting worked example), Ch.14 State
Objects (by-value-not-by-reference semantics made concrete), Ch.15 Shader/.fx Gap (**a real,
significant correction**: the chapter previously said `ShaderEffect` only exists on the three
D3D backends with HLSL source — it's actually real on EasyGL/Vulkan/BGFX/SdlGpu too, EasyGL
alone has 38 real tests using GLSL source; rewrote the section and the "honest summary").

**Part IV (Backends, Ch.16–24, all touched for the first time):** Ch.16 Backend Architecture
(`ISpriteBatchBackend` deep dive tying Ch.10's SDL_Renderer bug to its real no-op default),
Ch.17 SDL_Renderer (`SupportsCapability` honest-blanket-false worked example), Ch.18 EasyGL
(computed the exact SpriteBatch quad ceiling, 16,384, from the chapter's own finding), Ch.19
Vulkan (`OcclusionQuery` worked example), Ch.20 BGFX (`VertexDeclaration` Color-attribute
check tied to the black-mesh bug), Ch.21 WebGPU (render-target-size-trap worked example),
Ch.22 Direct3D 9/11/12 (worked `zFarPlane` clip-space math — first draft was placed *before*
the bug it explained was even introduced; caught and reordered before commit), Ch.23
Canvas/ASCII (hand-computed pixel-to-glyph luminance example), Ch.24 DX3/free-direct (fixed a
stale "Chapters~6 and~5" citation; worked blend-preset-detection example — **first draft had a
real math error** claiming Add-vs-Subtract "happen to" coincide only when `dst=0`, when for
`BlendState::Opaque`'s own factors they *always* coincide regardless of `dst`; caught by
working the arithmetic by hand and rewritten using `AlphaBlend`'s genuinely-divergent factors
instead).

**Appendix A (API Quick Reference):** added the previously-entirely-missing `GraphicsDevice`
and four state-object classes as a new section — the single most glaring omission in an
appendix that otherwise already covered every other Part II/III class.

**Every single one of the above chapters is now at "first pass done, well short of full page
target" status** — the same place Parts V–IX were in after their own breadth pass. None of
Parts I–IV is at its final page target yet (see `PLAN.md`'s table for exact current-vs-target
line/page counts per chapter — every row was updated this session with a real current count).

## Real, reusable findings from this session worth knowing before touching these chapters again

- **`ShaderEffect`'s real backend footprint (Ch.15)** was corrected from "three D3D backends
  only" to "EasyGL/Vulkan/BGFX/SdlGpu too, GLSL not HLSL on the GL-family backends" — grep
  `CreateEffectBackend` overrides across `src/CNA/Internal/Backends/*/` before trusting any
  future claim about which backends support custom shading.
- **The NOXNA marker macro vs. the unrelated `CNA_NOXNA` CMake option** (Ch.1/Ch.3/Ch.4) are a
  real, easy-to-confuse name collision — the marker is controlled by `CNA_STRICT_XNA_API`
  compiled into two small CMake targets, not a project-wide toggle; `CNA_NOXNA` gates a
  completely different opt-in "extended render pipeline" feature.
- **A non-floating `tabularx` table that grows taller than one page corrupts silently** (empty
  column, huge row gaps) rather than erroring — this happened once this session (Ch.10). Use
  `longtable` for any reference table with more than ~5-6 rows of wrapped text.
- **`\allowbreak{}` sometimes needs 2-3 rounds inside the same long compound identifier**
  before an overfull-hbox actually resolves (seen repeatedly: Ch.16's
  `std::unique_ptr<IGraphicsBackend>`, Ch.24's `ColorDestinationBlend=Blend::...`) — if two
  rounds don't fix it, the more reliable fix is restructuring the sentence into short
  independent clauses (proven in Ch.24) rather than continuing to chase allowbreak placement.
- **Always hand-verify any arithmetic/formula claim in a worked example before writing it down**
  — this session caught two real self-authored errors this way (the Ch.24 blend-formula claim,
  and almost shipped a forward-reference ordering bug in Ch.22) specifically by working the
  math through by hand rather than trusting the first draft's plausible-sounding phrasing.

## What to do next

Same genuine decision point `NEXT.md` has flagged before, but the landscape has shifted:
**every chapter in the whole book (Parts I–IX plus every appendix touched so far) now has at
least a first pass.** Options, roughly in order of likely value:

1. **Depth pass on Part I–IV's newly-breadth-passed chapters** (1-6, 8, 10-24, A) — these are
   almost all still very early (2-6 pages of a 20-85 page target each). This mirrors exactly
   the depth-pass work already done multiple times on Parts V-IX chapters in earlier sessions:
   pick a chapter, find the real `plan_*.md`/`docs/*.md`/test-suite source behind a claim it
   already makes but doesn't fully unpack, and turn it into fuller worked treatment.
2. **Depth pass on Ch.7 (Math, ~33/110) or Ch.9 (GraphicsDevice, ~23/90)** — both already have
   an established template and real remaining-gaps history in `PLAN.md`'s session log, but
   three-plus prior sessions on Ch.7 alone suggest fresh gaps will need active hunting, not a
   ready-made list.
3. **Depth pass on Parts V-IX** (touched earliest, still 3-15 of 30-70 page targets each) —
   same "find a narrower gap" approach documented in prior `NEXT.md` snapshots.
4. Ask the user which of the above to prioritize if it's not obvious from their own message —
   this file deliberately does not pick one, since the choice is a scope decision.

**Verify the numbers above against `git log` and actual file line counts before trusting them
at face value** — this file's own author (this session) made exactly that mistake once with a
math claim and had to self-correct; don't compound it by trusting a summary without checking.

## Housekeeping reminders

- Branch: `develop` (the merge described above happened this session — do not go looking for
  a separate feature branch, there isn't one to merge anymore).
- Build: `cd latex && make book` → `latex/book/main.pdf`. Check the log for `undefined`,
  `multiply defined`/`multiply-defined`, AND `overfull` every time. Note from this session:
  `grep -i overfull main.log` was frequently empty even when a real, visible overflow existed
  in the rendered PDF — **PNG rendering is the only reliable check**, the log grep is not
  sufficient evidence either way (this has been noted before but was reconfirmed repeatedly
  this session).
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` needed installing at
  the start of this session (the user ran `apt-get install` interactively) — should now persist
  for future sessions in this same container/environment, but verify with
  `command -v latexmk` before assuming.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`) live at
  `/rv/data/development/github.com/openeggbert/<name>` in this environment — **not**
  `/workspace` as older `NEXT.md` snapshots assumed (that was a different environment). Check
  this path first in a fresh session before assuming a re-clone is needed.
- Small commits, pushed after every chapter — this session pushed 23 separate commits, one per
  chapter, exactly per `CLAUDE.md`'s methodology. Keep doing this.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman numerals)
  — search by content (`pdftotext -f N -l N`), never assume printed page N is physical page N.
  A blank padding page immediately before a new Part's or chapter's right-hand start is normal
  book layout, not a rendering defect.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway — this session found and fixed 8+ stale
  plain-text citations this way, several of them pointing at the *wrong* chapter entirely, not
  just missing a `\ref{}`. Worth actively grepping for `Chapter~[0-9]` in any chapter you touch,
  not just fixing ones you happen to notice.
