# CNA defects found while auditing for The CNA Bible

This file collects every genuine defect in the **CNA ecosystem** that the new-edition source audit
turned up. It exists because the audit is read-only by design: the book repository must never
patch CNA, so findings that would otherwise be lost are recorded here for the project owner to
triage upstream.

| | |
|---|---|
| Audited revision | CNA `develop` @ `7a64362efef4119bf880459ef1704fb2c52199e2` (2026-08-11) |
| Sibling revisions | sharp-runtime `f827a6c5`, easy-gl `0b46d35`, meta-gl `571d3a6`, free-direct `934f72f`, free-api `53d7a31` |
| Method | Static source reading, `git` history, and build-configuration analysis across ten parallel audit passes |
| **Not done** | **No build, no test run, no execution of any kind.** Every finding below is derived from code, not reproduced at runtime. |

Full evidence for each item is in `audit/*.md`; the curated matrix and the documentation-staleness
log are in `AUDIT.md`.

## How to read this

**Confidence** is about the *finding*, not about severity:

- **VERIFIED** — the code was read directly and the defect follows from it mechanically.
- **STRONG** — the code was read; the consequence is inferred but hard to escape.
- **PROBABLE** — one leg of the argument could not be checked without building.

**Severity** is the audit's judgement, offered as a starting point for triage rather than a claim
of authority over the project's priorities.

---

## 1. Correctness defects in library code

### CNA-BUG-001 — `Plane::Transform(Plane, Matrix)` computes a symmetrization, not an inverse-transpose
**Severity: high · Confidence: VERIFIED · Area: `modules/math`**

`Matrix::Transpose(const Matrix&, Matrix&)` writes `result` field-by-field while reading `matrix`
(`modules/math/src/Matrix.cpp:1191-1209`):

```cpp
result.M12 = matrix.M21;   // :1194
...
result.M21 = matrix.M12;   // :1197 — reads the value :1194 just overwrote
```

It is therefore not aliasing-safe, and `Plane::Transform` calls it aliased
(`modules/math/src/Plane.cpp:147-158`):

```cpp
Matrix transformedMatrix;
Matrix::Invert(matrix, transformedMatrix);
Matrix::Transpose(transformedMatrix, transformedMatrix);   // :151 — same object twice
```

Each upper-triangle cell receives its lower-triangle mirror; each lower-triangle cell then
re-reads the cell that was just overwritten and is left unchanged. The net effect is
`symmetrize_from_lower(M)`, which coincides with `transpose(M)` only when `M` is already
symmetric.

**Worked counterexample.** For `M = CreateTranslation(1,0,0)`, `inverse(M)` has `M41 = −1` and
`M14 = 0`. The aliased call produces `M14 = −1` *and* `M41 = −1`; a true transpose produces
`M14 = −1`, `M41 = 0`. Transforming the plane `y = 1` (Normal `(0,1,0)`, `D = −1`) then yields
Normal `(1,1,0)` instead of the correct, unchanged `(0,1,0)` — **a pure translation silently
rotates the plane's normal.**

**Blast radius is exactly one function.** `Matrix::Transpose` has 20 call sites; `Plane.cpp:151`
is the only aliased one. Every other caller uses the value-returning overload
(`Matrix.cpp:1184-1189`), which allocates a distinct result and is safe.

**Why it was never caught:** both `Plane::Transform(Matrix)` tests use the identity matrix
(`PlaneTests.cpp:215-221`, `:298-305`), whose inverse is symmetric — the single input class for
which symmetrize and transpose agree.

**Suggested fix:** make `Matrix::Transpose` aliasing-safe (compute into a temporary, or swap
pairs), or have `Plane::Transform` transpose into a second `Matrix`.

### CNA-BUG-002 — `BoundingSphere::Contains(BoundingFrustum)` can never return `Disjoint`
**Severity: medium · Confidence: VERIFIED · Area: `modules/math`**

`modules/math/src/BoundingSphere.cpp:112-136`: `dmin` is declared and compared, but never
computed between those two points. The `Disjoint` branch is therefore unreachable, and a frustum
entirely outside the sphere reports as intersecting. CNA's own `AUDIT.md:22` marks
`BoundingFrustum` "✅ API complete", so this is invisible to a marker-based audit.

### CNA-BUG-003 — `BoundingBox::Contains(BoundingFrustum)` answers the reverse question
**Severity: medium · Confidence: VERIFIED · Area: `modules/math`**

`modules/math/src/BoundingBox.cpp:93-128` tests the frustum's corners against the box — i.e. it
computes whether the frustum's corner hull is inside the box, not the documented containment
relation. The comment above it reads only `// Legacy behavior:`, with no explanation, and no
`TODO`/`FIXME` marker.

### CNA-BUG-004 — `BoundingFrustum::Intersects(Ray)` throws on its main case while documented complete
**Severity: low · Confidence: VERIFIED · Area: `modules/math`**

`modules/math/src/BoundingFrustum.cpp:264` throws `System::NotImplementedException`.
`RayTests.cpp:211-214` acknowledges this in a comment and omits the test. CNA's `AUDIT.md:22`
nonetheless records the type as complete.

> **Cross-cutting note for CNA-BUG-002/003/004:** all three are unfinished or wrong functions that
> carry **no `TODO` or `FIXME` marker** — in two cases FNA's own `TODO` comments appear to have
> been replaced with neutral prose during the port. A marker-based sweep of `modules/math` reports
> "no known gaps" while these remain.

### CNA-BUG-005 — `Model::Draw` uses a process-wide static scratch buffer
**Severity: medium · Confidence: VERIFIED (fact); STRONG (consequence) · Area: `modules/graphics`**

`modules/graphics/src/Xna/Model.cpp:13` declares `static … sharedDrawBoneMatrices_`, resized at
`:107-108` and filled at `:110`. Two `Model` instances drawn concurrently from different threads
share it. Neither `Model::Draw` nor `ModelMesh::Draw` has a unit test.

### CNA-BUG-006 — `SpriteEffect::OnApply()` is unreachable past its first line
**Severity: low (currently latent) · Confidence: VERIFIED · Area: `modules/graphics`**

`CacheEffectParameters()` looks up `getParametersProperty()["MatrixTransform"]`
(`modules/graphics/src/Xna/SpriteEffect.cpp:29`), but nothing ever *adds* a parameter of that
name: `Effect`'s base constructor adds only a technique (`Effect.cpp:14-15`) and `SpriteEffect`
has no `AddParam` call. `matrixParam_` is therefore always null and `OnApply()` returns
immediately (`SpriteEffect.cpp:32-33`) without computing the orthographic projection and
half-pixel offset the rest of the method describes.

Harmless today only because every renderer supplies the sprite transform itself — it would become
a real bug the moment one stopped. `SpriteEffectTests.cpp` (38 lines) only checks `Clone()` and
that `Apply()` does not throw; it never asserts the parameter exists.

### CNA-BUG-007 — glTF import errors escape `catch (ContentLoadException&)`
**Severity: medium · Confidence: VERIFIED · Area: `modules/content`**

`ExtractMesh`'s rejections throw plain `std::runtime_error`
(`modules/content/src/GltfImport/GltfImportCore.cpp:1145-1155`) and `ReadGltfModel` does not wrap
them. `Load<Model>` on a TRIANGLE_STRIP `.glb` therefore throws `std::runtime_error` where the
rest of the reader throws `ContentLoadException`. Because `ContentLoadException` derives from
`std::runtime_error` and not the reverse, a `catch (ContentLoadException&)` misses it.

### CNA-BUG-008 — `Load<Song>` / `Load<Video>` can return an asset pointing at a `.cnj` file
**Severity: medium · Confidence: STRONG · Area: `modules/content`, `modules/media`**

`ResolveAssetPath()` tries `.cnj` before every reader's declared native extensions, for *every*
type. But only `Texture2D`, `TextureCube` and `SoundEffect` branch on a `.cnj` extension inside
their `Read()`. `SongTypeReader::Read` (`ContentManager.cpp:3004-3009`) and `VideoTypeReader::Read`
(`:3021-3024`) do not, and `Song`'s constructor only checks `exists()`
(`modules/media/src/Xna/Song.cpp:14-29`).

Given `Content/theme.cnj` and `Content/theme.ogg`, `Load<Song>("theme")` resolves to the `.cnj`,
succeeds, and returns a `Song` pointing at a JSON file that will fail at playback. Same shape for
`Video`. No test covers it.

### CNA-BUG-009 — Morph targets silently skip normals on PBR strides
**Severity: low · Confidence: VERIFIED (fact); STRONG (impact) · Area: `modules/graphics`**

`BlendMorphTargetsEXT` applies normal deltas only for strides 32/52/56
(`modules/graphics/src/Xna/MorphTargetEXT.cpp:31`). `ExtractMesh` can produce strides 20, 24, 48
and 68 as well (`GltfImportCore.cpp:1299-1300`). A stride-48/68 PBR mesh with morph targets
therefore gets **position-only morphing with no diagnostic**. The header's documented value set,
`MorphTargetEXT.hpp:84` "(32, 52, or 56)", understates the real input domain.

### CNA-BUG-010 — The runtime glTF path computes a UV-set mismatch warning and discards it
**Severity: low · Confidence: VERIFIED · Area: `modules/content`**

`pbrUv2Mismatch` is set when a PBR map references a different `TEXCOORD` set than the one baked
into the vertex buffer (`GltfImportCore.cpp:1280-1292`). The CLI surfaces it as a warning
(`gltf_to_cnj.cpp:249-256`); the runtime caller computes the flag and never reads it. The header
(`GltfImportCore.hpp:206-217`) states the warning is surfaced, which is true only of the offline
path. A game loading a `.glb` directly gets exactly the silent mis-render the flag exists to
prevent.

---

## 2. Capability reporting that contradicts the implementation

`IGraphicsRenderer::SupportsCapability` defaults to **`true`** for everything except
`MultiStreamVertexInput` (`IGraphicsRenderer.hpp:1823-1834`). A renderer must therefore opt *out*.
The documented contract is that callers query the capability **instead of** catching an exception,
which makes each of the following a trap rather than a cosmetic inaccuracy.

### CNA-BUG-011 — WebGPU and bgfx report `CustomEffects == true` but cannot honour it
**Severity: medium · Confidence: VERIFIED (paths); STRONG (that it is unintended) · Area: renderers**

WebGPU has no `CreateEffectRenderer` anywhere, and its `SupportsCapability` special-cases only
`WireFrame` before falling through (`WebGPURenderer.cpp:6065-6075`) — so it inherits `true` while
returning `nullptr`. The only backstop is `WebGPUSpriteBatchRenderer::SetCustomEffect` throwing
(`:2211-2215`).

bgfx has no `CustomEffects` case outside its examples, so it also inherits `true`, while
`CompileProgram` is a hardcoded `return false` with the message "bgfx renderer requires
pre-compiled binary shaders (not GLSL source)" (`BgfxRenderer.hpp:182-188`).

Every other non-supporting renderer returns `false` explicitly (diligent
`DiligentRenderer.cpp:2665`, wicked `WickedRenderer.cpp:3552`, opengl1 `:508`, skia
`SkiaRenderer.cpp:897`, fna3d `Fna3dRenderer.cpp:888`, portablegl `:1614`).

### CNA-BUG-012 — SDL_GPU and WebGPU misreport occlusion-query support, and a test encodes the wrong expectation
**Severity: medium · Confidence: VERIFIED · Area: renderers**

The capability query contradicts the factory. Worse than the reporting error itself: an existing
test asserts the incorrect expectation, so fixing the renderer would break a green test. See
`audit/renderer-catalog.md` FACT 5 for the exact sites.

### CNA-BUG-013 — DIRECTX6/7/8 report no stencil support while shipping tested stencil code
**Severity: low · Confidence: VERIFIED · Area: renderers**

Three legacy DirectX renderers return `false` for the stencil capability despite having working,
tested stencil implementations — the inverse of CNA-BUG-011/012, and equally likely to send a
caller down an unnecessary fallback path. See `audit/renderer-catalog.md` FACT 7.

### CNA-BUG-014 — LLGL's `SlopeScaleDepthBias` is wired but unguarded
**Severity: low · Confidence: VERIFIED · Area: `modules/renderers/llgl`**

LLGL's `SupportsCapability` has no `default:` arm and no cases for `StencilBuffer`, `Instancing`
or `MultiStreamVertexInput`, so all three correctly fall through to `false`. But
`SlopeScaleDepthBias` remains wired and unguarded (`LlglRenderer.cpp:3029-3034`): a caller who
respects the capability system still gets **silently wrong output rather than a throw**.

### CNA-BUG-015 — SOKOL reports `Texture3D == true` while allocating no GPU resource
**Severity: low · Confidence: VERIFIED · Area: `modules/renderers/sokol`**

Same silent-failure shape as CNA-BUG-014: the capability is advertised, the resource is never
created.

---

## 3. Resource limits and input handling

### CNA-BUG-016 — The `.cnj` JSON parser recurses without a depth bound
**Severity: medium · Confidence: VERIFIED (code); STRONG (exploitability) · Area: `modules/content`**

`JsonParser::ParseValue()` recurses via `ParseObject()`/`ParseArray()`
(`modules/content/include/CNA/Internal/Json.hpp:195-211, 235, 261`) with no depth counter
anywhere in the file. A crafted `.cnj` of `[[[[…]]]]` is a stack-exhaustion vector.

This is asymmetric with the XNB side, which bounds **both** type-name nesting
(`XnbTypeName.hpp:80-87`) and object-graph nesting (`ContentReader.hpp:368-384`) after
`REMED-CONTENT-006` explicitly identified unbounded recursion as a stack-exhaustion DoS and
recorded that it was "confirmed empirically". Same threat model, same repository, opposite
treatment. There is also no `.cnj` fuzz harness — all three fuzzers are XNB/LZX only.

### CNA-BUG-017 — `XnbReadLimits::maxFileSize` is declared but not enforced on the whole-file read
**Severity: low · Confidence: VERIFIED · Area: `modules/content`**

The 64 MiB limit (`XnbReadLimits.hpp:20`) has exactly one consumer: the compressed-payload check
at `XnbDecompression.cpp:19`. `LoadXnbAsset` reads the entire file into a `std::string` with no
cap (`ContentManager.hpp:426-433`), and `ScanXnbReaderNames` does the same. This is the same class
of defect that `REMED-CONTENT-006` closed for `maxObjectNestingDepth` and `maxStringBytes`.

### CNA-BUG-018 — glTF input is never validated against its own declared requirements
**Severity: low · Confidence: VERIFIED · Area: `modules/content`**

`cgltf_validate` is never called anywhere in `modules/` or `tools/`, and `extensionsRequired` /
`extensionsUsed` are never read. A file declaring a required extension CNA does not implement
loads silently and renders wrongly rather than reporting the unmet requirement.

---

## 4. Lifecycle and API-contract defects

### CNA-BUG-019 — `Game::Dispose()` raises `Disposed` on every call
**Severity: low · Confidence: VERIFIED · Area: `modules/runtime`**

`Game::Dispose()` calls `Dispose(true)` — which early-returns when already disposed — and then
raises `Disposed` **unconditionally** (`modules/runtime/src/Game.cpp:453-457`). A second
`Dispose()` therefore re-raises the event to every subscriber.

### CNA-BUG-020 — A throwing component leaves `Game` permanently un-disposed
**Severity: low · Confidence: VERIFIED · Area: `modules/runtime`**

`isDisposed_ = true` is set last, after all cleanup (`Game.cpp:651`). An exception from any
component's `Dispose()`, from the content manager, or from the graphics service aborts the
remaining cleanup and leaves the object not marked disposed — so a later `Dispose()` re-runs the
partially-completed teardown.

### CNA-BUG-021 — `ContentManager::Unload()` disposes nothing
**Severity: medium · Confidence: VERIFIED · Area: `modules/content`**

`Unload()` is two `.clear()` calls (`ContentManager.cpp:135-139`). FNA's `Unload()` disposes every
tracked `IDisposable` first. The disposal-tracking list does not exist:
`ContentReader::RecordDisposable()` states the `ContentManager` fallback "is deferred to Phase B2
(XNB-17B)" (`ContentReader.hpp:451-452`). GPU resources loaded through the content manager are
therefore leaked until device teardown.

### CNA-BUG-022 — Any `.xnb` declaring a nonzero reader version is rejected
**Severity: medium · Confidence: VERIFIED · Area: `modules/content`**

`SupportsVersion(int)` defaults to exact equality against `getTypeVersionProperty()`
(`ContentTypeReader.hpp:51-64`) and is enforced in `ContentReader::InitializeTypeReaders()`
(`ContentReader.cpp:227-232`). **No reader anywhere overrides either method** — a repo-wide grep
finds only the base definitions and the single call site. Every reader's `TypeVersion` is
therefore 0, and any asset whose type-reader table declares a nonzero version fails to load.

### CNA-BUG-023 — `CanDeserializeIntoExistingObject` is declared, overridden, and never consulted
**Severity: low · Confidence: VERIFIED · Area: `modules/content`**

Declared at `ContentTypeReader.hpp:43` and overridden to `true` by `ListReader`
(`CollectionContentTypeReaders.hpp:143`) and `DictionaryReader` (`:197`), but `ContentReader`
never reads it — zero consultations in `ContentReader.{hpp,cpp}`. In FNA this property gates
whether `existingInstance` is passed down; in CNA it is inert metadata.

### CNA-BUG-024 — Exception base classes diverge across namespaces, undocumented
**Severity: low · Confidence: STRONG · Area: cross-cutting**

XNA-native exception types split across two roots. `Audio`, `GamerServices`, `Net` and `Sensors`
exceptions derive from `System::Exception`; `Graphics`'s `DeviceLostException`,
`DeviceNotResetException` and `NoSuitableGraphicsDeviceException` (`…/Graphics/*.hpp:10`) and
`Content`'s `ContentLoadException` (`…/Content/ContentLoadException.hpp:10`) derive from
**`std::runtime_error`**. In real XNA all four descend from `System.Exception`. This is not listed
in `CHECKLIST.md`'s deliberate-deviations table, so it reads as drift rather than decision.

A related trap for callers, worth documenting whichever way it is resolved: `System::Exception`
derives from **`std::exception`, not `std::runtime_error`**
(`sharp-runtime/modules/core/include/System/Exception.hpp:32`), and `modules/runtime` throws only
raw `std::` types and never a `System::*` type. So no single `catch` clause short of
`catch (const std::exception&)` spans the framework.

### CNA-BUG-025 — `PlaneIntersectionType`'s documentation is the inverse of every implementation
**Severity: low · Confidence: VERIFIED · Area: `modules/math`**

`PlaneIntersectionType.hpp:10-17` documents `Front` as "the negative half-space" and `Back` as
"the positive half-space". `Plane::IntersectsPoint` returns `Front` for `distance > 0`
(`Plane.cpp:114-117`), and `BoundingSphere::Intersects(Plane)` (`:355-357`) and
`BoundingBox::Intersects(Plane)` (`:424-434`) both agree with the code. Operationally `Front`
means entirely on the **+N** side.

### CNA-BUG-026 — `CreatePerspectiveFieldOfView` does not reject a field of view of exactly π
**Severity: low · Confidence: VERIFIED · Area: `modules/math`**

The upper guard literal is `3.141593f`, which is numerically **above** `MathHelper::Pi`
(`3.14159274f`), so `CreatePerspectiveFieldOfView(MathHelper::Pi, …)` passes validation and
produces a degenerate projection instead of throwing.

### CNA-BUG-027 — The two `Clamp` implementations disagree on inverted ranges
**Severity: low · Confidence: VERIFIED · Area: `modules/math`**

`MathHelper::Clamp` clamps against `max` first, then `min`, so **`min` wins** when `min > max`
(`MathHelper.cpp:46-51`). The vectors' file-local `ClampScalar` is
`std::min(std::max(v,min),max)`, so **`max` wins** (`Vector3.cpp:26-29`). `MathHelper::Clamp(5,10,1)`
returns `10`; a component-wise vector clamp on the same inputs returns `1`. `MathHelper::Max/Min`
are ternaries while the vectors use `std::max`/`std::min`, giving different NaN behaviour too.

### CNA-BUG-028 — `Curve::ComputeTangent` uses two different degeneracy epsilons for the same test
**Severity: low · Confidence: VERIFIED · Area: `modules/math`**

`TangentIn` uses `MathHelper::WithinEpsilon(pn, 0.0f)` ≈ 5.96e-8 (`Curve.cpp:229`); `TangentOut`
uses `std::fabs(pn) < std::numeric_limits<float>::denorm_min()` ≈ 1.4e-45 (`:254`) — a ratio of
roughly 4×10³⁷ inside one function. The `TangentOut` form matches C#'s `float.Epsilon`, so the
`TangentIn` line is the deviation.

### CNA-BUG-029 — Renderer-tracked resources are registered by raw address, and copies escape tracking
**Severity: medium · Confidence: VERIFIED · Area: `modules/graphics`**

`GraphicsDevice` keeps a non-owning `std::vector<GraphicsResource*>`; registration happens in
`GraphicsResource`'s normal constructor, but the **copy constructor sets `graphicsDevice_` without
calling `AddResourceReference`** (`GraphicsResource.cpp:10-15` vs `:17-24`). A copied resource is
therefore untracked, is not disposed by `GraphicsDevice::Dispose()`, and — because `Texture2D` is
freely copyable by design (`Texture2D.hpp:96-100`) — can outlive its device and destroy a native
backend after the context is gone. Move construction transfers the handle while leaving the
moved-from address in the tracker.

This was recorded in the previous edition's audit as a `needs_human` item and is repeated here so
it is not lost: the policy choice (repair registration, or prohibit copy/move on tracked resources
with a deliberate `Texture2D` alias rule) is the project owner's, not the book's.

---

## 5. Build, CI and tooling defects

### CNA-BUG-030 — The main CI workflow cannot configure, and takes the only sanitizer run with it
**Severity: high · Confidence: VERIFIED — corroborated independently by two audit passes · Area: CI**

`.github/workflows/general-tests-ci.yml:133` passes `-DCNA_GRAPHICS_RENDERER=EASYGL`. `EASYGL` is
**not** one of the 46 public identities — it is an internal family name, publicly selected as
`OPENGLES2`/`OPENGLES3`/`OPENGL33`/`WEBGL1`/`WEBGL2` — so selection falls through to
`message(FATAL_ERROR "CNA: Unknown graphics renderer: EASYGL")`
(`cmake/RendererSelection.cmake:869`). The workflow triggers on **every push**.

Two of the five `input-ci.yml` legs use the same dead selector (`:38`, `:43`), and one of those is
the **only ASan+UBSan run in the whole CI system**.

The workflow's own header calls EasyGL "the documented default renderer on Linux
(cmake/RendererSelection.cmake)", but that file's Linux default is `OPENGLES3` (`:11`). Commit
`ea31cabc1` (2026-08-11) edited this workflow for the ASCII removal and left the selector
untouched.

### CNA-BUG-031 — Four wired-in validation gates read paths that no longer exist
**Severity: medium · Confidence: VERIFIED · Area: scripts / CI**

Post-modularization path rot. All four paths were confirmed absent:

| Script | Reads | Wiring |
|---|---|---|
| `scripts/validate_skia_release_gate.py:26` | `cmake/Tests/SkiaTests.cmake` | CTest (`skia/examples/CMakeLists.txt:87`) |
| `scripts/validate_skia_test_matrix.py:108` | `cmake/Tests/EasyGLTests.cmake` | CTest (`:73`) |
| `scripts/validate_skia_surface_formats.py:97` | `src/Graphics/Xna/Texture.cpp` | CTest (`:101`) |
| `scripts/verify_hlsl_shaders_native_msvc.py:30` | `src/CNA/Internal/Renderers/D3DCommon/shaders` | live CI step (`d3d-windows-ci.yml:273`) |

`cmake/Tests/` now contains only `ModuleProbes.cmake` and `WickedTests.cmake`; there is no
top-level `src/`. The first three would abort before doing any work under a SKIA configure; the
fourth fails on `ModuleNotFoundError` at import, so it reports a Python error rather than a shader
regression.

### CNA-BUG-032 — Every `ModuleLinkClosure_*` gate skips under the project's own presets and CI
**Severity: medium · Confidence: VERIFIED · Area: build tooling**

`scripts/check_module_link_closure.py:32-35` reads
`<build>/CMakeFiles/<target>.dir/link.txt` and returns **77 (CTest SKIP)** when it is absent. That
file is a Makefiles-generator artifact. The `tests` preset sets `"generator": "Ninja"`
(`CMakePresets.json:66`) and every CI job configures with `-G Ninja`.

The gates themselves are well-designed and correct — they encode real architectural invariants
(e.g. Math may link nothing but itself) — but under the configurations the project actually uses,
**none of them ever runs**.

### CNA-BUG-033 — `validate_direct2d_plan.py --release-gate` has never gated anything
**Severity: low · Confidence: VERIFIED · Area: scripts / CI**

The gate requires `docs/direct2d-native-evidence.md` and
`docs/direct2d-physical-presentation-evidence.md` (`:68-74`); neither exists, which the script's
own comment describes as deliberate ("their absence is what keeps the gate honest"). But CI runs
the script **without** `--release-gate` (`d3d-windows-ci.yml:111`), so the release gate is never
exercised at all.

### CNA-BUG-034 — `run-wine-direct2d.sh` defaults to the developer's personal Wine prefix
**Severity: low · Confidence: VERIFIED · Area: scripts**

`scripts/run-wine-direct2d.sh:30` defaults `WINEPREFIX` to `$HOME/.wine`. Both Proton scripts
hard-**refuse** any prefix resolving under `~/.wine` (`run-proton-vkd3d.sh:70-89`), citing a
documented 2026-07-14 incident in which a half-upgraded personal prefix hung for 9.5 hours. The
Wine path retains the hazard the Proton path was hardened against.

### CNA-BUG-035 — `devices-tests.yml`'s filter does not cover what its comment claims
**Severity: low · Confidence: VERIFIED · Area: CI**

`.github/workflows/devices-tests.yml:53-56` claims `DEVICES_GTEST_FILTER` covers "every `TEST(...)`
under `modules/devices/tests/Microsoft/Devices/`, no more and no fewer." It selects **446 of 462**.
The 16 missed cases are in `DevicesShutdownCoordinatorTest` (4), `DevicesShutdownOrderingTest` (1),
`IndependentReferenceCrossCheckTests` (2) and `NativeDiagnosticSinkTest` (9).

This is exactly the hand-maintained-filter drift that `INPUT-BUILD-003` introduced
`CNA_INPUT_TEST_FILTER` + `ctest -L input` to eliminate (`cmake/UnitTests.cmake:396-401`); the
devices workflow still uses hand-written `--gtest_filter` strings.

### CNA-BUG-036 — `run-all-renderer-smoke-tests.sh` is unreachable and structurally lenient
**Severity: low · Confidence: VERIFIED · Area: scripts**

The script presents itself as the cross-renderer smoke orchestrator but is **invoked from nowhere**
in the repository. It also covers only 4 of 46 identities, ignores the build exit code
(`:47-51`), reports configure failures as SKIPPED rather than FAIL (`:41-43`), excludes both
golden-image renderers, and uses `-j4`.

### CNA-BUG-037 — WICKED loads `libdxcompiler.so` relative to the working directory
**Severity: low · Confidence: VERIFIED · Area: `modules/renderers/wicked`**

The library is `dlopen`ed relative to the process CWD rather than the executable path, so the
renderer works only when launched from one specific directory. A packaging trap.

### CNA-BUG-038 — bgfx's shader generator has no staleness check and no CI reference
**Severity: low · Confidence: VERIFIED · Area: `modules/renderers/bgfx`**

`compile_shaders.py` bakes four profiles (`glsl`, `essl`, `spv`, `wgsl` — 108 arrays from 27
shaders) but has **no `--check` mode** and is referenced by no CI job, so a `.sc` edit without
regeneration drifts silently. LLGL's and Sokol's generators both *do* have `--check`.

Separately and more consequentially: **no DXBC and no Metal blobs exist**, so bgfx's D3D11, D3D12
and Metal backends have no shader content at all and would fail to draw if selected.

### CNA-BUG-039 — `XnbBuiltInReaderRegistrationTests` asserts an unconditional registration that is conditional
**Severity: low · Confidence: PROBABLE (build not run) · Area: `modules/content` tests**

`XnbBuiltInReaderRegistrationTests.cpp:105` asserts `DecimalReader` is registered unconditionally,
but its registration is guarded by `#if SHARP_RUNTIME_HAS_NATIVE_INT128`
(`DecimalDateTimeContentTypeReaders.cpp:12-15`). On a platform without native `__int128` the test
fails.

### CNA-BUG-040 — A demo violates the project's own entry-point policy
**Severity: trivial · Confidence: VERIFIED · Area: examples**

`modules/devices/examples/demo_devices/src/Main.cpp:1-19` includes `<SDL3/SDL_main.h>` directly,
contrary to `Entrypoint.hpp:16-17`, which states that game code must go through the CNA header.

---

## 6. Unreachable and dead code

### CNA-BUG-041 — `TitleContainer` has no in-tree consumer, so its Android asset fallback is unreachable
**Severity: medium · Confidence: STRONG (grep-negative) · Area: `modules/runtime`, `modules/content`**

A grep for `TitleContainer::` / `TitleLocation::` outside their own sources and tests returns
nothing; `WaveBank.cpp:119,124` and `SoundBank.cpp:51` mention them only in comments explaining
that CNA deliberately does *not* route through them.

The consequence is concrete: `ContentManager` resolves content **CWD-relative with no base-path
prefix** (`ContentManager.hpp:50`, `ContentManager.cpp:296-308`), while `TitleLocation` wraps
`SDL_GetBasePath()` and is never called from the content path. So the `SDL_LoadFile` Android-asset
fallback at `TitleContainer.cpp:36-58, 97-125` cannot be reached from asset loading at all — a
latent portability problem on Android and macOS bundles, and a substantive reason Android graphics
support is blocked beyond scheduling.

### CNA-BUG-042 — `CheckForNaNs()` and `getDebugDisplayStringProperty()` are dead across the math module
**Severity: trivial · Confidence: VERIFIED · Area: `modules/math`**

`CheckForNaNs()` is declared on `Vector2/3/4`, `Quaternion` and `Matrix`, defined in each `.cpp`
to throw `std::logic_error`, and has **zero call sites repo-wide** (5 declarations + 5 definitions
only). `getDebugDisplayStringProperty()` is declared on ten types, 20 occurrences, **zero call
sites** — not from `ToString`, not from any test, not from any renderer. Both are structurally
ported XNA `[Conditional("DEBUG")]` hooks that were never wired up.

### CNA-BUG-043 — `ExitingEventArgs` is unreferenced
**Severity: trivial · Confidence: VERIFIED · Area: `modules/runtime`**

An empty `: System::EventArgs` with a defaulted constructor, a one-line `.cpp`, and references
only from its own header, its own source and its own two-case test. `Game::Exiting` is typed
`EventHandler<System::EventArgs>` (`Game.hpp:50`). CNA's `AUDIT.md:34` marks it
"✅ CNA-specific addition matching XNA pattern".

### CNA-BUG-044 — `ResourceContentManager::OpenStream` is a non-dispatching stub
**Severity: trivial · Confidence: VERIFIED · Area: `modules/content`**

`ResourceContentManager.cpp:13-17` throws "…is not implemented in CNA." The method is declared
`virtual` only on the derived class and `ContentManager` never calls it, so it is also a
virtual-dispatch dead end.

---

## 7. Attribution

### CNA-BUG-045 — `THIRD_PARTY_NOTICES.md` omits vendored cgltf, stb and Draco
**Severity: low · Confidence: VERIFIED · Area: licensing**

The file has eight sections (Avatar content, XNA stock effects ×2, FNA3D, Skia, wgpu-native,
DiligentCore, sokol). `third_party/cgltf/` (MIT, © 2018-2021 Johannes Kuhlmann,
`third_party/cgltf/LICENSE:1`) and `third_party/stb/` are compiled directly into `cna_content` and
are not listed; Draco, when found, is likewise unlisted.

`plan_gltf.md:1568-1570` makes attribution in this file the explicit review procedure for *new*
assets, while the already-vendored parsers fall through it.

---

## 8. Documentation defects

These are recorded in full, with both sides of each contradiction, in **`AUDIT.md` §5**. They are
not repeated here because there are too many to be actionable as a bug list, but three deserve
naming because they would actively mislead a reader or a future audit:

1. **`xnb.md:36-39` contradicts its own banner.** The line "Status: planning document only.
   Nothing described here is implemented yet." sits directly beneath a 2026-07-16 revision note
   recording Phases 0/A/B/B2/B3/C/D/E complete. Reality: 50 registered readers, 30 real fixtures,
   ~350 tests.
2. **Five documents still assert CNA cannot read `.xnb` at all** — `docs/migration-guide.md`,
   `docs/xna-4-api-coverage.md`, `docs/coverage.md` ("Content pipeline (.xnb) — 0 %"),
   `docs/README.md`, and CNA's own `AUDIT.md:104`.
3. **`docs/graphics-renderer-feature-matrix.md:3` self-labels "Master, up-to-date"** while
   carrying rows refuted by the code (Tasks 871 and 872 marked open, both closed), omitting FNA3D
   entirely, and covering 4 renderers where there are 42 families.

A related structural issue: **the entire `audit/` tree (2,297 `.audit.md` files) is keyed on the
pre-modularization layout** and lists at least one already-fixed HIGH finding as open
(`audit/src/Microsoft/Xna/Framework/Content/ContentReader.cpp.audit.md:24-26, 91-94`, the absolute
-path escape, fixed at `ContentReader.cpp:51-56` and pinned by a test).

---

## 9. Live security gap in Storage

### CNA-BUG-046 — `StorageContainer` has no path-containment guard at all
**Severity: high · Confidence: VERIFIED · Area: `modules/storage`**

`StorageContainer::ResolvePath(relative)` is exactly `return (fs::path(storagePath_) / relative).string();`
(`modules/storage/src/StorageContainer.cpp:84-87`), with **no containment check of any kind**.
Every file/directory operation routes through it: `CreateDirectory`, `DirectoryExists`,
`DeleteDirectory`, `CreateFile`, `FileExists`, `DeleteFile`, and all three `OpenFile` overloads.
`container->CreateFile("../../outside.txt")` escapes the sandbox; an absolute `relative` silently
discards the storage root entirely (`fs::path::operator/` semantics).

This is the more dangerous half of a two-part story. `StorageDevice::DeleteContainer` **is**
guarded, via `CNA::Internal::ResolveContainedPath` (REMED-CONTENT-002), and its guard is the
subject of the module's only 5 tests (`StorageDeviceTests.cpp:64-95` — empty name, absolute name,
an 8-level `../` escape, `.`, and the happy path). `StorageContainer`, which is where a real game
actually reads and writes save files, was left completely unguarded, and has **zero tests** of any
kind.

A second, unrelated gap in the same class: `OpenFile`'s `fileShare` parameter is accepted and
silently discarded (`StorageContainer.cpp:204-212` — the parameter is unnamed in the final
`FileStream` construction).

### CNA-BUG-047 — `StorageContainer`'s search-pattern glob is untested
**Severity: low · Confidence: VERIFIED · Area: `modules/storage`**

The `*`/`?` search-pattern overloads use a 22-line hand-rolled backtracking `GlobMatch()`
(`StorageContainer.cpp:13-35`), not a library call, and it has no test at all.

---

## 10. Live security gap and misreported capability in Input/Devices/Audio/Media/Net/GamerServices/Avatar/Storage

### CNA-BUG-048 — `Sensors` (`CNA::Input`) never initializes `SDL_INIT_SENSOR`, and is a latent no-op
**Severity: medium · Confidence: STRONG · Area: `modules/input`**

`CNA::Input::Sensors` never calls `SDL_InitSubSystem(SDL_INIT_SENSOR)` — the input module's only
subsystem init is `SDL_INIT_GAMEPAD`
(`modules/input/src/Internal/SdlInputBridge.cpp:1606`). `GetSensorsEXT()` therefore returns empty
and both readers report `false` unless some *other* subsystem (e.g.
`Microsoft::Devices::Sensors::Accelerometer`) happened to initialize it first. Its own tests use a
fake backend and never catch this.

### CNA-BUG-049 — `AvatarRenderer::Dispose(bool)` is `public`, contrary to its base class
**Severity: low · Confidence: VERIFIED · Area: `modules/devices`**

Not directly a bug in Avatar itself, but the same shape recurs across all four sensor classes:
`Dispose(bool)` is `public` in `Accelerometer`, `Gyroscope`, `Compass` and `Motion`, while
`SensorBase` declares it `protected` (`Accelerometer.hpp:224`, `Gyroscope.hpp:202`,
`Compass.hpp:199`, `Motion.hpp:197`). An external `sensor.Dispose(false)` call takes the
`!disposing` branch and sets `disposed_ = true` **with no cleanup at all** — no `Stop()`, no
instance-count decrement, no SDL release, no owner-nulling. Tracked in-repo as
`REMED-DEVICES-002`, not started.

### CNA-BUG-050 — `GamerServicesDispatcher::Update()` is a permanent no-op that causes real infinite-spin hangs
**Severity: medium · Confidence: VERIFIED · Area: `modules/gamer-services`, `modules/net`**

`GamerServicesDispatcher::Update()` is an empty function
(`modules/gamer-services/src/Xna/GamerServicesDispatcher.cpp:66-68`); `UpdateAsync()` returns
`isInitialized_`, i.e. always `true` once initialized. Any XNA-idiomatic
`while (!result->IsCompleted) UpdateAsync();` loop therefore spins at ~100% CPU forever. Two real
instances of this were found and fixed by completing the action at construction instead
(`NetworkSession::Create/Find/Join`, `SignedInGamer::BeginGetAchievements`) — but the underlying
no-op remains, so any future `Begin*`/`End*` pair that does not adopt the same synchronous-complete
pattern will reproduce the hang. Regression coverage exists only via out-of-process harnesses,
because `GamerServicesDispatcher`'s process-lifetime statics have no reset hook.

### CNA-BUG-051 — `ContentManager.cpp`'s Windows video guard is wrong on native MSVC
**Severity: medium · Confidence: VERIFIED · Area: `modules/content`, `modules/media`**

`modules/content/src/Xna/ContentManager.cpp:47` guards the `Video.hpp` include with
`#if !defined(__EMSCRIPTEN__) && !defined(__ANDROID__) && !defined(__MINGW32__) && !defined(__MINGW32__)`
— `__MINGW32__` is checked twice and plain `_WIN32`/native MSVC is not checked at all, while the
CMake condition that actually excludes the video sources is
`if(MINGW OR WIN32 OR EMSCRIPTEN OR ANDROID)` (`modules/CMakeLists.txt:15-19`). On a native MSVC
Windows build the header include survives while `modules/media/src/Xna/Video/{Video,VideoPlayer}.cpp`
are excluded from the build — a link error. The project's own D3D11/D3D12 CI targets exactly this
configuration.

### CNA-BUG-052 — `SongTypeReader` advertises three extensions this build cannot decode
**Severity: low · Confidence: VERIFIED · Area: `modules/content`, `modules/media`**

`LooseFileContentTypeReader<Media::Song>::Extensions()` returns
`{".mp3", ".ogg", ".wav", ".flac", ".opus", ".aac", ".wma"}`
(`modules/content/src/Xna/ContentManager.cpp:2996-3001`). CNA's vendored SDL3_mixer build
explicitly disables Opus, WavPack, mpg123 and libFLAC-alternative decoders
(`cmake/ThirdPartySDL.cmake:149-160`); `.opus`, `.aac` and `.wma` have no decoder in this
configuration. `Content.Load<Song>()` on such a file will fail at the point of actual decode, not
at resolution.

### CNA-BUG-053 — Two renderers advertise `CustomEffects == true` while unable to compile a shader
**Severity: medium · Confidence: VERIFIED (paths); STRONG (unintended) · Area: `modules/renderers`**

`IGraphicsRenderer::SupportsCapability` defaults to `true` for everything except
`MultiStreamVertexInput`. WebGPU has no `CreateEffectRenderer` override at all, and its capability
switch special-cases only `WireFrame` before falling through (`WebGPURenderer.cpp:6065-6075`), so
it inherits `true` while returning `nullptr` — the only backstop is
`WebGPUSpriteBatchRenderer::SetCustomEffect` throwing. bgfx has no `CustomEffects` case outside its
examples, so it too inherits `true`, while its `CompileProgram` is a hardcoded
`return false` (`BgfxRenderer.hpp:182-188`, "bgfx renderer requires pre-compiled binary shaders").
Every other non-supporting renderer returns `false` explicitly. (See also CNA-BUG-011/012/013,
which record the sibling capability-reporting defects found in the renderer catalog.)

---

## What this list does not cover

Stated plainly so nothing here is over-read:

- **Nothing was executed.** No build, no test, no renderer was run. Every finding is static.
  Severity judgements in particular would benefit from reproduction.
- **The per-renderer draw-path matrix was not audited.** Which of the 42 renderer families
  implement `DrawPrimitivesEx`/`DrawIndexedPrimitivesEx` versus inheriting the default that
  **silently discards the entire `GpuDrawParams`** and falls back to the colored-primitive path
  (`IGraphicsRenderer.hpp:1718-1742`) is unknown. Any renderer in that set renders an untextured,
  unlit approximation of every stock effect with no error and no diagnostic. This is the largest
  known blind spot in the audit.
- **Only five of 46 renderers were checked for oracle coverage.** Only `directx9`, `easygl`,
  `fna3d`, `opengles1` and `skia` build a `cna_oracle_render_*` binary, and only the D3D9 one is a
  hard gate; the others' pixel verification is entirely self-referential.
- **Sibling repositories were audited only where CNA depends on them.** free-direct and free-api
  have had no commits since 2026-07-18 and were reviewed for their CNA-facing surface, not
  exhaustively.
