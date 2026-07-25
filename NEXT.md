# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise, current handoff and is rewritten as the state changes.

## Current state (2026-07-25)

- Branch: `develop`, based on `c714cc4` when this autonomous session started. The tree was clean
  and synchronized with `origin/develop`.
- Book: **468 physical PDF pages, 49 chapters, 6 appendices**.
- Full validation: a forced full-book rebuild completed successfully with:

  ```bash
  cd latex/book
  latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex
  ```

- The final `main.log` has no matches for either targeted check:

  ```bash
  grep -iE 'Warning.*undefined|undefined reference|undefined control' main.log
  grep -iE 'multiply defined|multiply-defined' main.log
  ```

- `makeindex` accepted 1,956 entries, rejected 0, and reported 0 warnings.
- This is the first successful fresh full-book build after commit `87fb144`, whose verified
  baseline was 454 pages. The 14-page increase comes from the isolated continuation work that
  followed that baseline.

## Visual verification closed in this session

Every physical page in each post-`87fb144` content file was rendered from the new full PDF at
110 dpi and inspected directly:

- Ch.20 BGFX: physical pages 207–214.
- Ch.21 WebGPU: 215–222.
- Ch.22 SDL GPU: 223–232.
- Ch.23 Direct3D: 233–244.
- Ch.25 DX3/free-direct: 251–256.
- Ch.34 Sharp Runtime overview: 329–334.
- Ch.35 Sharp Runtime namespaces: 335–346.
- Appendix E: 451–456.
- Appendix F: 457–462.

All are visually clean: no page-edge overflow, listing spill, running-header/folio collision,
or malformed page was found. Ch.5, whose PLAN row had remained incorrectly marked “pending
batch verification,” was also rendered in full (physical pages 49–56) and is clean.

## Work completed before this session, now fully verified

- Ch.20 documents BGFX Texture3D/TextureCube readback and mip allocation.
- Ch.21 corrects stale WebGPU readback, culling, scissor, and viewport limitations.
- Ch.22 covers SDL GPU lifetime, present timing, validation, swapchain recovery/readback,
  custom shaders, pipeline/sampler state, draw ordering, MRT, and remaining limits.
- Ch.23 covers the D3D11 verification ladder and MRT finalization, the D3D11/D3D12
  PresentationMode limitation, and corrected D3D9 Texture3D/render-target coverage.
- Ch.25 covers the real letterbox input transform and the still-open resize/presentation
  mismatch that requires a free-direct-side fix.
- Ch.34 documents the real local CI gate and absent hosted CI.
- Ch.35 documents generic-task continuation scope and MemoryStream close semantics.
- Appendices E/F cover SkinnedPbrEffect/AnimationPlayer and MemoryStream respectively.

## Current focus

1. Reconcile stale project bookkeeping exposed by the full build:
   - several PLAN line counts differ from `wc -l`;
   - the PLAN subtotal still says the book is 266 pages;
   - `CLAUDE.md` still says 48 chapters;
   - `README.md` is empty;
   - Ch.49 still repeats the obsolete claim that Texture3D/TextureCube do not inherit
     `Texture`, contradicting current CNA source and the corrected Ch.11.
2. Rebuild and visually verify the documentation corrections.
3. Continue the highest-value source-grounded expansion work in logical dependency order,
   starting from the active graphics/backend area unless a fresher source audit reveals a
   more important correctness correction.

## Repository-safety notes

- Existing sibling-repository changes are user-owned and must be preserved:
  - `cna`: the reusable Xvfb screenshot registration/source changes documented under
    `tools/cna-screenshot-infra/`;
  - `cna-samples`: a modified `samples/SimpleAnimation/Content/tank.model.json`.
- Do not edit sibling repositories as part of ordinary book work. Read them as authoritative
  sources; make book changes only in this repository unless a future task explicitly expands
  scope.
- The active book repository itself started clean.

## Blockers and `needs_human`

No current book task is blocked on a human decision. The long-standing authenticity limit
remains: Wine/DXVK provides real execution but synthesizes D3D9 capability values, so only
real Windows/D3D9-era hardware can close that narrow claim. Keep it recorded as
`needs_human`; it does not block independent writing or validation work.

## Reusable validation rules

- A successful LaTeX build is necessary but not sufficient. Render every touched physical PDF
  page and inspect it directly.
- Use the targeted undefined-reference expression above; a plain `grep -i undefined` can match
  ordinary prose.
- Printed page numbers differ from physical PDF pages because of front matter. Locate pages by
  extracted title text.
- Never place raw non-ASCII bytes inside an `lstlisting`.
- Run `git diff --check` before each commit.
- Keep content commits small and descriptive; update `PLAN.md` and this file whenever state
  changes materially.
