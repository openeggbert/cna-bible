# Next session — start here

**Read this file first, then `PLAN.md` for the full task list, per-chapter page targets, and
the permanent session log.** This file is a snapshot of where things stand as of the end of
the session that just finished — it gets overwritten each session, not appended to (unlike
`PLAN.md`'s own internal session log, a permanent history).

## Where things stand (end of session, 2026-07-21)

**The book is a single, unified book**, built via `make book` (→ `latex/book/main.pdf`).
Compiles clean as of the last commit: **349 pages, 0 undefined references, 0
duplicate-label warnings** (re-verify — run `make book` and grep the log — before trusting
this number in a future session; grep the log with `grep -i undefined` and
`grep -i "multiply defined"`, both of which *are* reliable, unlike `grep -i overfull`, which
is not — see "Reusable findings" below).

**Milestone reached this session: Appendices B–F now all have a depth pass.** Tasks #42–46
are complete. Every appendix (A–F) and every chapter (1–48) in the book has now had at least
one depth-pass touch. Highlights:

- **Appendix B (Feature Matrix)**: fixed a real, stale defect — every "See" column entry used
  a leftover plain-text "Ch.~N (Vol.~I)" citation from the pre-merge two-volume era (factually
  wrong now, there is no "Vol. I" anymore); converted all 12 to real `\ref{}`s.
- **Appendix C (Glossary)**: added 4 new entries (ContentManager, ENet, GraphicsCapability,
  PbrEffect); fixed a pre-existing misalphabetization ("Storage" was stranded at the end,
  after "xna4-spec").
- **Appendix D (Repo Map)**: added a real, genuinely missing repository, `free-api`
  (`free-direct`'s own second-level dependency), verified directly from its README.
- **Appendix E (NOXNA Catalog)**: added 3 missing Graphics-section entries (`PbrEffect`,
  `AnimationPlayer`, `MorphTargetEXT`) and `ContentManager`'s 3 build-auditing NOXNA methods.
- **Appendix F (API Quick Reference)**: added a genuinely missing section, F.4 Storage
  (`StorageDevice`/`StorageContainer`) — this appendix covered Input/Audio/Networking/
  GamerServices/SharpRuntime-core-types but had no Storage entry at all, despite Storage
  having full narrative coverage in Ch.32.

All five committed and pushed individually (commits `deb09a9`, `d673504`, `bd08bd6`,
`71dcec7`, `04bea17`), each rebuilt, checked for undefined/duplicate-label errors, and
PNG-rendered/visually verified before committing, per the project's standard methodology.

## What is NOT yet done — the natural next body of work

**No task is currently active or blocked.** With every chapter and appendix now having had at
least one depth pass, the entire remaining scope is a **third pass**: continuing to grow every
chapter toward its still-distant page target, using the identical "find one more real,
grounded gap per chapter" methodology tasks #24–46 used. This is not a sign anything was done
wrong — the original page targets were always aspirational multi-session goals, not a
single-pass expectation. Per `PLAN.md`'s own table, most chapters remain at roughly 10–30% of
target even after two passes. The chapters furthest below target in **absolute page terms**
(biggest opportunity per chapter) are, roughly:

- Ch.22 Direct3D Backends: ~5 of ~85 pages (80 short)
- Ch.13 Stock Effects: ~10 of ~80 pages (70 short)
- Ch.7 Math and Core Types: ~34 of ~110 pages (76 short, but already deeply worked across four
  sessions — see its own PLAN.md row for what's already covered before adding more)
- Ch.30 Networking: ~8 of ~70 pages (62 short)
- Ch.25 Input System: ~12 of ~70 pages (58 short)
- Ch.9 GraphicsDevice: ~24 of ~90 pages (66 short)
- Ch.19 Vulkan Backend, Ch.18 EasyGL Backend, Ch.11 Textures, Ch.12 Models, Ch.26 Audio,
  Ch.14 State Objects: all roughly 45–55 pages short

No `TaskCreate` entries exist yet for a third pass — create them following the same
one-task-per-chapter pattern tasks #24–46 used if picking this up. Given the scale (48
chapters), consider batching into groups (e.g. by Part) rather than creating all 48 up front.

## The single highest-value technique discovered this session (still true, gets harder each pass)

**For any chapter about a specific CNA subsystem or sibling repo, check that repo's own most
recently dated planning/audit document before assuming a chapter is already exhaustively
covered.** This found real, substantial, previously-uncovered material in nearly every chapter
it was tried on across two full passes. The recipe:

1. Find the newest plan/audit doc for the chapter's subsystem:
   `ls /rv/data/development/github.com/openeggbert/cna/plan_*.md` (or `NEXT.md`/`AUDIT.md` at
   the root of `cna` or the relevant sibling repo — `sharp-runtime`, `easy-gl`, `free-direct`,
   `cna-samples` each have their own).
2. Check dates: `grep -o "2026-[0-9-]*" plan_X.md | sort -u | tail -5`, or just read the tail
   of the phase/section outline (`grep -n "^#\|^##" plan_X.md | tail -20`) — the newest phase
   is usually the least likely to have been mined yet.
3. Read that newest phase/section for a concrete, real, dated finding — ideally with real
   before/after numbers or a named test, not just a description.
4. Grep the book chapter for whether that specific finding is already mentioned. **Watch
   out: LaTeX escapes underscores as `\_`, so grepping for `result_u64` will silently miss
   `result\_u64` in the source — search for the term with the escape accounted for, or use a
   looser pattern.** If genuinely absent, it is very likely a fresh, addable gap.
5. Before asserting a "still open" claim from an older doc as current fact, **grep the actual,
   current source directly** — this session's earlier work found this exact trap sprung at
   least four/five separate times across unrelated subsystems (see Ch.46/Ch.48's own
   first-person write-up of the pattern). It will keep happening on a third pass too — don't
   skip the live-source check just because a chapter already looks thorough.
6. **A third-pass mining attempt is more likely to come up empty than the first two were** —
   the easiest, most obvious gaps are gone now. If a chapter's most-recent plan doc has already
   been fully mined (check the chapter's own PLAN.md row — it names which doc/phase was used),
   look for a *different* kind of gap instead: a worked example using a class/method the
   chapter mentions but never demonstrates in code; a cross-reference to another chapter's
   already-documented finding that this chapter hasn't drawn out yet; a reference-table
   omission (compare the chapter's own coverage against a `grep -c` of public methods in the
   real header). Don't force a low-quality addition just to move a page count — an honest "this
   chapter's obvious material is exhausted, needs a structural rewrite to grow further" is a
   more useful thing to record in PLAN.md than padding.
7. **Always check `PLAN.md`'s own row for a chapter before editing it.** Ch.37 is a real,
   live example of an explicit author scope cap ("do not expand") that must be honored, not
   treated as just another under-target chapter.

## Reusable technical/mechanical findings (still true, carried forward)

- **PNG-rendering the affected pages remains the only reliable overflow check.**
  `grep -i overfull main.log` is proven unreliable in both directions this project — it
  missed real, visible overflows repeatedly, and separately, `grep -a "verfull"` (accounting
  for binary-detection false negatives in a plain `grep -i`) revealed hundreds of pre-existing
  "overfull" log lines that plain `grep -i` was silently missing entirely. Always rebuild,
  locate the chapter's physical page range via `pdftotext -f N -l N`, render to PNG via
  `pdftoppm -png -f N -l N -r 120`, and actually read the rendered pages.
- **Overflow-fix technique, in order of what actually worked:** (1) For a long identifier in
  prose, try `\allowbreak{}` at camelCase/`::`/`_` boundaries, 1–2 rounds max. (2) If that
  doesn't resolve it, restructure the sentence into shorter independent clauses — the more
  reliable fix nearly every time it was tried. (3) For a `\description` list `\item[...]` label
  combining two full method signatures (e.g. `A(...)  / B(...)`), split into two separate
  `\item` entries rather than fighting the label width. (4) For a too-long single line *inside*
  an `lstlisting` code block, restructure the code itself — `\allowbreak{}` does not apply
  inside `lstlisting`. (5) For a running-header vs. page-number folio collision on a long
  `\section{}` title, use `\section[short title]{long title}`.
- **A heavily-worked chapter can still hide undiscovered pre-existing overfull-hboxes** — don't
  assume a well-covered chapter is layout-clean; render and check it the same as any other.
- **Always verify a specific method/property name against the real header before finalizing a
  worked example, even for "obvious" names** — this project has repeatedly caught
  plausible-but-wrong guesses before commit. Grep the header every time.
- **A numerical discrepancy between two sources doesn't always mean one is wrong** — resolve an
  apparent contradiction by re-deriving both numbers yourself before assuming either source is
  stale (Ch.43's `BltFast` count example).
- `\cnaclass{}`/`\cnans{}` both wrap in `\texttt{}` *and* emit `\index{}` — never put
  `\allowbreak{}` inside their arguments (would corrupt the index).

## Housekeeping (unchanged, still true)

- Build: `cd latex && make book` → `latex/book/main.pdf`. Grep the log for `undefined` and
  `multiply defined`/`multiply-defined` every time — these two checks are reliable.
- `latexmk`/`pdflatex`/`texlive-latex-extra`/`texlive-fonts-recommended` are installed in this
  environment.
- Sibling repos (`cna`, `sharp-runtime`, `easy-gl`, `free-direct`, `xna4-spec`, `cna-samples`,
  `cna-extended`, `cna-template`, `libcna.com`, `free-api`, `free-eggbert`, `planetblupi`)
  live at `/rv/data/development/github.com/openeggbert/<name>` in this environment — not
  `/workspace`. `free-eggbert`/`planetblupi` are also mirrored read-only under
  `/rv/data/library/github.com/openeggbert/`.
- Printed page numbers and physical PDF page numbers differ (front matter uses roman
  numerals) — search by content (`pdftotext -f N -l N`), never assume printed page N is
  physical page N.
- Prefer real `\ref{ch:label}` over a plain-text `Chapter~N` citation when a label already
  exists and you're touching that paragraph anyway.
- Run the project's spacing-fix regex on every touched file before rebuilding:
  `python3 -c "import re; p='PATH'; t=open(p).read(); n=re.sub(r'\}/(\\\\texttt\{|\\\\cnaclass\{)', r'} / \1', t); open(p,'w').write(n) if n!=t else None"`
  — then manually grep for the `}/%` newline-continuation variant, which the regex doesn't
  catch (that variant is usually intentional and correct as-is; only fix it if it's actually
  producing a visible overflow).
- No task is currently blocked/`needs_human`. If a genuine architectural ambiguity comes up in
  future work, mark it clearly here and in `PLAN.md`'s session log, and continue with other
  independent work rather than stalling.
