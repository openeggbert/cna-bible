# Audit report — 3D model runtime, glTF import, skinning/animation, CNJ toolchain

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root.

---

## 0. The `feature/gltf` lane in one paragraph

Lane 2/10 (`264be1270`, branch tip `e9336a107`) landed **118 files, +19,545/−79 lines**. It is
not a feature lane; it is a **correctness remediation** lane. It added a 2,572-line campaign
plan (`plan_gltf.md`, 460 tasks / 24 phases), a 426-line normative reference doc
(`docs/gltf-conformance.md`), a deterministic Python fixture generator (`tools/gltf_fixtures/`,
11 modules), a 16-asset committed conformance corpus with a SHA-256 manifest, five layers
(L1–L5) of numerical oracle, an executable known-defect ledger, and **four real production
fixes** (sparse index decoding, primitive-mode classification, the glTF node hierarchy as real
`ModelBone`s, and the skin coordinate spaces). Eighteen of nineteen lane commits are
`test(gltf)`/`docs(gltf)`; three are `fix`/`feat`.

---

## FACTS

### A. Model runtime (`modules/graphics`)

**A1.** The XNA model runtime is eight small classes totalling **1,703 lines** of
header+source: `Model` (129 hpp / 135 cpp), `ModelBone` (79/22), `ModelBoneCollection`
(75/59), `ModelEffectCollection` (67/45), `ModelMesh` (122/71), `ModelMeshCollection`
(71/59), `ModelMeshPart` (156/71), `ModelMeshPartCollection` (48/26), plus `SkinnedModelEXT`
(226/242). — **VERIFIED**

**A2.** `Model` owns nothing by value: raw `ModelBone*`/`ModelMesh*` in its two collections
plus a type-erased `std::shared_ptr<void> ownedResources_` (`Model.hpp:125`, set via
`Model::setOwnedResources`, `Model.cpp:50-52`). Every loader constructs a private
`ModelResources` struct of `unique_ptr` vectors and hands it over as that opaque handle
(`modules/content/src/Xna/ContentManager.cpp:1714-1728`). A hand-built `Model` therefore has
**no automatic owner at all**. — **VERIFIED**

**A3.** `Model::CopyAbsoluteBoneTransformsTo` composes `bone.Transform * dest[parentIndex]` in
a single forward pass (`Model.cpp:60-81`). Correct **only** because bones are stored
parent-before-child; nothing in `Model` checks that invariant (unlike `AnimationPlayer`, which
does — A9). — **VERIFIED**

**A4.** `Model::Draw` uses a **`static` process-wide scratch buffer**
`sharedDrawBoneMatrices_` (`Model.cpp:13`, resized `:107-108`, filled `:110`). Two `Model`s
drawn concurrently from different threads share it. — **VERIFIED** (fact); thread-safety
consequence **STRONG**.

**A5.** `Model::Draw` throws `std::runtime_error("Effect does not implement IEffectMatrices")`
for any effect that is not an `IEffectMatrices` (`Model.cpp:121-123`), sets
`World = boneAbsolute * world` (`:127-128`), then calls `mesh->Draw()`. It never touches bone
*palettes* — skinning matrices are the caller's job. — **VERIFIED**

**A6.** `ModelMesh::Draw` (`modules/graphics/src/Xna/ModelMesh.cpp:42-70`): calls
`GetRenderer().Ensure3DSupported("ModelMesh::Draw")` first (`:45`); **silently skips** any part
whose effect is null or whose `primitiveCount <= 0` (`:50-51`); binds VB/IB per part; and
**hardcodes `PrimitiveType::TriangleList`** (`:61`). There is no topology field anywhere in
`ModelMeshPart`. — **VERIFIED**

**A7.** `ModelMeshPart::setEffectProperty` maintains the parent mesh's
`ModelEffectCollection` by scanning every sibling part for shared use before removing the old
effect (`ModelMeshPart.cpp:27-57`) — an O(parts) de-duplication, not a refcount.
`ModelMeshPart` holds `Effect*`, `VertexBuffer*`, `IndexBuffer*` as **non-owning raw
pointers** (`ModelMeshPart.hpp:148-152`). — **VERIFIED**

**A8.** There are **two independent, deliberately non-shared skeletal systems**:
`SkinningData` + `AnimationPlayer` (`AnimationPlayer.hpp:48-163`) is the *real-`Model`* path,
with `SkinningData` inheriting `System::Object` and attached to `Model.Tag`;
`SkinnedModelEXT` (`SkinnedModelEXT.hpp:79-226`) is the *Avatar* path, explicitly documented
as "deliberately not built on Model/ModelBone/ModelMesh" (`:71-78`). `AnimationPlayer.cpp:15-19`
states the duplicated `SampleTrack` helper is an intentional copy, not an oversight.
— **VERIFIED**

**A9.** Both animation systems validate input: array-size/`BoneCount` mismatch throws
(`AnimationPlayer.cpp:108-120`, `SkinnedModelEXT.cpp:161-171`), and a non-topological
`parent >= i` throws (`AnimationPlayer.cpp:143-150`, `SkinnedModelEXT.cpp:222-229`). Loop
wraparound is floor-mod via raw ticks (`AnimationPlayer.cpp:85-88`). — **VERIFIED**

**A10.** `SkinningData` gained a **fourth matrix array** in this lane: `SkeletonRootPrefix`
(`AnimationPlayer.hpp:74`). `RecomputeTransforms` composes `world(root) = local * prefix` for
root bones only; an empty array reads as all-identity (`AnimationPlayer.cpp:155-161`). This is
the carrier for the glTF scene-ancestry and mesh-node-cancellation terms. — **VERIFIED**

**A11.** Interpolation is LERP for translation/scale and SLERP for rotation in both players
(`AnimationPlayer.cpp:49-51`, `SkinnedModelEXT.cpp:41-43`). Keyframe search is a **linear
scan** (`AnimationPlayer.cpp:37-40`) — O(keys) per bone per frame. — **VERIFIED**

**A12.** `SkinnedEffect::MaxBones = 72` (`SkinnedEffect.hpp:28`) and
`SkinnedPbrEffect::MaxBones = 72` (`SkinnedPbrEffect.hpp:41`). With `BlendIndices` as
4×`uint8`, the hard caps are: 4 influences/vertex, ≤255 joints addressable, ≤72 bones per
effect, one UV channel. — **VERIFIED** (also `plan_gltf.md:230-232`)

**A13.** Morph targets are **CPU-blended and re-uploaded**, not a GPU technique:
`MorphTargetDataEXT` keeps the whole base vertex-byte array, `BlendMorphTargetsEXT` recomputes
it, `SetMorphWeightsEXT` re-uploads the vertex buffer (`MorphTargetEXT.hpp:71-75, 109-119`;
`MorphTargetEXT.cpp:19-60`). Normal deltas apply only to strides 32/52/56
(`MorphTargetEXT.cpp:31`). Attached to `ModelMeshPart.Tag`. — **VERIFIED**

### B. glTF importer: where it lives and what it is

**B1.** There **is** an in-tree glTF importer, and it is a shared library core rather than a
tool-only parser: `modules/content/include/CNA/Internal/GltfImport/GltfImportCore.hpp` (632
lines) + `modules/content/src/GltfImport/GltfImportCore.cpp` (1,852 lines), namespace
`CNA::Internal::GltfImport`. Consumed by **both** the offline CLI
(`tools/gltf_to_cnj/gltf_to_cnj.cpp`, 699 lines) and the runtime reader
(`ContentManager.cpp`'s `ReadGltfModel`). — **VERIFIED**

**B2.** Parsing is delegated to **vendored cgltf 1.15** (MIT), `third_party/cgltf/cgltf.h`
(7,175 lines; version at `:4`). `GltfImportCore.cpp:16` is the single `CGLTF_IMPLEMENTATION`
TU. `stb_image.h`/`stb_image_write.h` are compiled `STATIC` in the same TU to avoid colliding
with SDL_image's own copy (`:19-37`). — **VERIFIED**

**B3.** GLB and `.gltf` share one `cgltf_parse_file` call; no separate container code exists.
`ModelTypeReader::GetExtensions()` returns `{".cnj", ".gltf", ".glb"}` with `.cnj`
deliberately first, so a sidecar always wins (`ContentManager.cpp:2250-2257`). — **VERIFIED**

**B4.** `cgltf_validate` is **never called** anywhere in `modules/` or `tools/`.
`extensionsRequired` / `extensionsUsed` are **never read**. A file declaring a required
extension CNA does not implement loads silently. — **VERIFIED** (grep over all four
glTF-consuming TUs returns nothing)

**B5.** Only `asset.version == "2.0"` is accepted; anything else throws
(`ContentManager.cpp:1882-1887`, `gltf_to_cnj.cpp:609-613`). — **VERIFIED**

**B6.** The complete set of cgltf symbols the CNA glTF path touches is 60 identifiers. It
contains **no** `cgltf_sampler`, no `cgltf_camera`, no `alpha_mode`, no `alpha_cutoff`, no
`double_sided`, no `base_color_factor`, and no variants/transmission symbol. Samplers,
cameras, alpha coverage, double-sidedness and base-colour factor are therefore *structurally
absent* from the import, not merely unwired. — **VERIFIED**

### C. Scene graph and node transforms (the lane's headline fix)

**C1.** `BuildSceneGraph(data)` (`GltfImportCore.cpp:1588-1651`) flattens the default scene
(`data->scene`, else `scenes[0]`) parent-before-child with an explicit stack (no recursion,
`:1604-1613`), inserts a **synthetic identity root at index 0 named `"Root"`** (`:1595-1597`),
reads each node's local transform through `cgltf_node_transform_local` (which applies the
spec's `matrix`-xor-TRS rule for free, `:1631-1634`), converts to XNA row-vector form, and
composes `world = local * parentWorld` (`:1638`). A node reachable twice is imported once
(`:1623`). — **VERIFIED**

**C2.** `ConvertGltfMatrix` (`:95-102`) copies basis vectors rather than transposing
generically, dropping the projective row — correct for affine node transforms, silently wrong
for a non-affine `node.matrix` (which glTF forbids anyway). — **VERIFIED**

**C3.** `CollectMeshGroups(data, scene)` (`:1653-1705`) produces one `MeshGroup` per distinct
`cgltf_skin*` (plus one for unskinned), each holding
`MeshInstanceOut{node, mesh, sceneNodeIndex, worldTransform, skinned}`. Nodes **not reachable
from the default scene are excluded** (`:1665-1668`). A file where no scene node references
any mesh falls back to "every mesh at the identity root" (`:1692-1702`). — **VERIFIED**

**C4.** Both loaders build **one `ModelBone` per scene node, index-for-index**: runtime at
`ContentManager.cpp:1934-1946`, `.cnj` at `:2299-2328`. Vertex positions stay **mesh-local** —
the transform is never baked — so instancing survives (one mesh, two nodes ⇒ two `ModelMesh`es
sharing geometry, different parent bones). — **VERIFIED**

**C5.** The rigid/skinned asymmetry is deliberate and asserted: a rigid mesh is parented to its
own instancing node's bone; a **skinned** mesh's node bone still exists and still carries its
transform, but the mesh hangs off bone 0 (`ContentManager.cpp:2137-2139`; `.cnj` at
`:2621-2629`). Rationale in-code at `:2130-2136`. — **VERIFIED**

### D. Skinning import (the lane's second fix, D8)

**D1.** `BuildSkeleton` has two overloads. The 1-arg form is a compatibility shim passing an
empty graph and identity mesh-node transform; its own comment says callers that can build a
graph **must** use the 4-arg form (`GltfImportCore.cpp:640-647`). Both loaders use the 4-arg
form (`ContentManager.cpp:1920`, `gltf_to_cnj.cpp:196`). — **VERIFIED**

**D2.** Joints are topologically reordered breadth-first into parent-before-child order with an
`oldToNew` remap; an unresolvable parent chain throws (`:649-698`). `JOINTS_0` values are
remapped through `oldToNew` at vertex-pack time (`:1477-1483`). — **VERIFIED**

**D3.** For a **root** joint (parent outside the skin's joint set),
`parentWorldPrefix = ancestorWorld * Invert(meshNodeWorld)` (`:723-749`). `skin.skeleton` is
explicitly **not** a traversal stop (`:719-722`). A joint hanging off a node outside the
default scene falls back to `cgltf_node_transform_world` rather than losing ancestry
(`:735-741`). — **VERIFIED**

**D4.** The prefix is deliberately **not** folded into `bindPoseLocal`, because an animation
clip replacing a root joint's local transform would silently undo it
(`GltfImportCore.hpp:39-59`, `AnimationPlayer.hpp:61-74`, commit `e9336a107` message).
— **VERIFIED**

**D5.** `unitScale` applies to translations only, never to rotation/scale (`ScaleTranslation`,
`:357-364`), consistently across bind poses, inverse-bind matrices, ancestor worlds, vertex
positions, morph deltas and animation translation channels/tangents (`:717, :746, :754, :795,
:1454, :1564`). The runtime path **hardcodes `unitScale = 1.0f`** (`ContentManager.cpp:1920,
:2050`) — only the CLI exposes it (`gltf_to_cnj.cpp:657-686`). — **VERIFIED**

### E. Mesh extraction, GPU packing, index handling

**E1.** `ExtractMesh` reads `mesh.primitive.mode` **first**, classifies it into
`PrimitiveTopology` (glTF's own 0…6 numbering, `GltfImportCore.hpp:124-140`), and **rejects**
every non-`TRIANGLES` mode with the real mode named (`:1145-1155`).
`IsPrimitiveTopologySupported` returns true for `Triangles` **only** (`:1130-1133`). A mode
outside 0…6 throws rather than defaulting to triangles (`:1105-1107`). — **VERIFIED**

**E2.** Index decoding is **CNA's own**, not `cgltf_accessor_read_index`:
`UnpackIndexAccessor` (`:223-348`) validates SCALAR-ness, non-normalized-ness and the three
legal unsigned component types; computes an overflow-safe required byte span (`RequiredSpan`,
`:199-217`); bounds-checks against the bufferView; resolves `accessor.sparse` overrides
including the null-base-bufferView case; and reads each component with `memcpy` because a
bufferView may start at any byte offset (`:168-194`). Every failure is a *named*
`std::runtime_error`. Rationale — `cgltf_accessor_read_index` returns 0 with no error channel
for a sparse accessor — documented at `:130-139`. — **VERIFIED**

**E3.** A non-indexed primitive synthesises the implicit sequential range (`:1359-1368`). Every
index is proved `< POSITION.count` before anything consumes it (`:1376-1386`), which is what
makes the later `uint16` narrowing safe (`:1534-1544`). — **VERIFIED**

**E4.** Index width is chosen purely by `vertexCount > 65535` (`:1537`) — **not** by the source
accessor's component type. A file with `UNSIGNED_INT` indices and 100 vertices is narrowed to
16-bit. — **VERIFIED**

**E5.** The **vertex stride ABI** is decided by one expression (`:1299-1300`):

| Stride | Layout (offsets) | Selected when | Effect |
|---|---|---|---|
| 20 | Pos 0, UV 12 | unskinned, uncoloured, non-PBR, base-colour **and** occlusion map | `DualTextureEffect` |
| 24 | Pos 0, Color(u8×4) 12, UV 16 | unskinned + `COLOR_0` | `BasicEffect` + `VertexColorEnabled` |
| 32 | Pos 0, Nrm 12, UV 24 | default unskinned | `BasicEffect` |
| 48 | Pos 0, Nrm 12, Tan(vec4) 24, UV 40 | unskinned, uncoloured, normal **or** MR map | `PbrEffect` |
| 52 | Pos 0, Nrm 12, UV 24, Weights 32, Indices(u8×4) 48 | skinned | `SkinnedEffect` |
| 56 | 52 + Color(u8×4) 52 | skinned + `COLOR_0` | `SkinnedEffect` + `VertexColorEnabled` |
| 68 | Pos 0, Nrm 12, Tan 24, UV 40, Weights 48, Indices 64 | skinned + PBR | `SkinnedPbrEffect` |

Missing attributes are filled: normal `(0,0,1)`, UV `(0,0)`, colour alpha `255` (`:1499-1501,
:1455-1456, :1466`). — **VERIFIED**

**E6.** There is **no `VertexDeclaration` on the glTF path at all**. Bytes are packed tightly
by `ExtractMesh` and re-interpreted downstream by a `switch (stride)` in
`BuildVertexBufferFromRawBytes` (`ContentManager.cpp:1746-1817`) — strides 16/20/24/32 are
rebuilt as real C++ vertex structs and uploaded via typed `SetData`; strides 48/52/56/68 go
through `SetDataRaw`. The comment at `:1730-1745` explains why: CNA's vertex structs inherit
polymorphic `IVertexType`, so `sizeof()` is vtable-inflated past the clean stride, and a
`reinterpret_cast` reads every field from the wrong offset — identified there as the confirmed
root cause of a long-standing "invisible model" symptom family. `plan_gltf.md:213-216` calls
the stride table "the single largest structural hazard in the GPU packing layer" because it has
no single source of truth. — **VERIFIED**

**E7.** **No handedness or axis conversion is performed anywhere**, and this is correct: glTF
and XNA are both right-handed, +Y up, −Z forward, with a top-left UV origin
(`plan_gltf.md:433, :749, :761, :1973, :2091`). The only "handedness" in `GltfImportCore.cpp`
is the tangent `w` sign (`:527, :599-600`). — **VERIFIED**

**E8.** Winding is **never flipped for negative-determinant node scales**; that is `GLTF-116`,
unstarted (`plan_gltf.md:1984`). — **VERIFIED** (absence)

**E9.** Tangents: the file's own `TANGENT` accessor is used when present; otherwise
`ComputeTangentsEXT` (`:538-603`) generates one — Lengyel/MikkTSpace position+UV-gradient
formula, per-triangle, **angle-weighted** at each corner, skipping degenerate-UV triangles,
finalized by Gram-Schmidt with a handedness sign. Its own comment states it is **not** a
bit-for-bit MikkTSpace port (no position+normal corner welding across hard seams) and calls
that a deliberate scope cut (`:531-537`). — **VERIFIED**

**E10.** `primitiveCount` is computed as `numIndices / 3` in **all three** model loaders
(`ContentManager.cpp:2059` runtime glTF, `:2486` `.cnj`, `:2941` skinned-model) and
`ModelMesh::Draw` hardcodes `TriangleList`. Replacing this with a topology-aware helper is
`GLTF-078`, unstarted (`docs/gltf-conformance.md:424-426`). — **VERIFIED**

### F. Materials, textures, extensions

**F1.** PBR is selected **only** when a normal map or metallic-roughness *map* is present:
`out.usePbr = (!out.colored) && (normalImage || metallicRoughnessImage)` (`:1241-1242`). A
factor-only metallic-roughness material — glTF's default material block — falls through to
`BasicEffect`. — **VERIFIED**

**F2.** `MeshOut` carries `metallicFactor`, `roughnessFactor`, `emissiveFactor` — assigned
**only inside `if (out.usePbr)`** (`:1243-1258`). There is **no `baseColorFactor` field on
`MeshOut` at all**, and no `alphaMode`, `alphaCutoff` or `doubleSided`. For a factor-only
material, *zero* material properties survive import. — **VERIFIED**

**F3.** `DualTextureEffect` is chosen for an unskinned, uncoloured, non-PBR primitive with both
a base-colour and an occlusion map (`:1270-1271`), and the occlusion image is **decoded,
RGB-halved and re-encoded as PNG** first (`RemapOcclusionImageForDualTextureEXT`, `:940-974`)
because XNA's dual-texture blend does `base.rgb *= 2.0` and expects "0.5 = neutral" while glTF
occlusion is "1.0 = fully visible" (derivation at `GltfImportCore.hpp:422-440`). The two caches
are kept separate so the same image can also serve as an unmodified `PbrEffect::OcclusionMap`
(`ContentManager.cpp:2015-2021`). — **VERIFIED**

**F4.** Images resolve all three glTF storage forms — embedded `bufferView`, base64 `data:`
URI, external file with percent-decoding (`ExtractImage`, `:867-938`). The runtime path decodes
straight from memory via `MemoryStream` + `Texture2D::FromStream`, with **no temp files**,
cached by `cgltf_image*` per `Load<Model>()` call (`ContentManager.cpp:1997-2013`).
— **VERIFIED**

**F5.** Exactly **four** glTF extensions are handled, all in `GltfImportCore.cpp`:
`KHR_texture_transform` (base-colour texture only; `texcoord` override honoured `:1192-1196`;
offset/rotation/scale baked into the single shared UV channel `:1399-1411`),
`KHR_materials_emissive_strength` (multiplies `emissiveFactor`, PBR path only `:1253-1257`),
`KHR_lights_punctual` (up to **3** lights from the default scene, approximated as directional;
point/spot become a direction from the light's world position toward the origin;
`color * intensity` clamped to [0,1]; `:1712-1762`, cap at `:1719`; applied via
`dynamic_cast<IEffectLights*>` at `ContentManager.cpp:1826-1843`), and
`KHR_draco_mesh_compression` (**optional**, compiled only when `find_package(draco CONFIG)`
succeeds — `modules/CMakeLists.txt:40-46`, `modules/content/CMakeLists.txt:24-26`; without it
a Draco primitive throws a named "compiled without libdraco support" error `:1168-1173`).
— **VERIFIED**

**F6.** `KHR_materials_transmission`, `KHR_materials_variants`, sRGB/linear colour-space
distinction, glTF samplers (wrap/filter), and cameras are **entirely absent**. `gltfissues.md`
documents the first two and the colour space as real losses on a real asset. — **VERIFIED**

**F7.** Per-map UV-set mismatch is **detected but not fixed**: `pbrUv2Mismatch` is set when any
present PBR map references a different `TEXCOORD` set than the one baked into the vertex buffer
(`:1280-1292`), and the CLI emits a warning (`gltf_to_cnj.cpp:249-256`). The runtime path
computes the flag and **never surfaces it** — no warning, no log. — **VERIFIED**

### G. Animation import

**G1.** `ExtractClips` resamples every animated bone onto the **union of its channels' key
times**, deduplicated at 1e-9, filling absent channels from the bone's decomposed bind pose
(`:826-859`). LINEAR, STEP (`:459, :477`) and real **CUBICSPLINE Hermite** (`HermiteEvaluate`,
`:432-452`, with the spec's `deltaT` tangent scaling) are all implemented; CUBICSPLINE
rotations are re-normalised after component-wise evaluation (`:483-494`). — **VERIFIED**

**G2.** `ExtractClips` resolves every channel target through **`skel.nodeToNewIndex` only**; a
channel targeting a non-joint node is `continue`d with no record (`:784-785`). `clip.duration`
is the max sampler input time (`:807-811`). — **VERIFIED**

**G3.** Both loaders call `ExtractClips` **only when the group has a skin**
(`ContentManager.cpp:1966` inside `if (hasSkin)`; `gltf_to_cnj.cpp:412-414`). Therefore
**rigid (unskinned) node animation is dropped by two independent mechanisms**, and dropped
*silently* — the `sawUnsupportedTarget` warning at `:805, :814-820` fires only for
`weights`-path channels, never for a TRS channel on a non-joint node. — **VERIFIED**

**G4.** Morph-weight animation is a **separate, skin-independent** path:
`ExtractMorphWeightTrack` (`:1772-1851`) finds the `weights` channel on the node instancing the
mesh, and preserves CUBICSPLINE in/out tangents **unbaked** so `EvaluateMorphWeightsEXT` can
evaluate the real Hermite curve lazily at playback (rationale at `GltfImportCore.hpp:338-350`).
A mesh referenced by several nodes resolves to the first — a documented simplification
(`:1777-1782`). — **VERIFIED**

### H. Runtime vs offline: the two model routes

**H1.** Runtime: `ContentManager::Load<Model>("x")` resolves `x.cnj` → `x.gltf` → `x.glb`;
`.gltf`/`.glb` dispatch to `ReadGltfModel` (`ContentManager.cpp:2259-2269`), which parses
in-process, builds bones/skinning/textures/effects/morphs and returns a `Model` with
`Tag = SkinningData*` (`:1860-2245`, tag at `:2243`). — **VERIFIED**

**H2.** `ReadGltfModel` imports **`groups.front()` only** (`:1899`). A file combining a skinned
character and static scenery silently loses one whole group. Documented as a limitation at
`:1853-1859`; tracked as `GLTF-137`. — **VERIFIED**

**H3.** Offline: `cna_tool_gltf_to_cnj` (`cmake/ToolGltfToCnj.cmake`, 15 lines) is built
**unconditionally** — not gated behind `CNA_BUILD_TESTS` — links `CNA` + `SHARP_RUNTIME` only,
and never initialises a renderer or window. CLI:
`gltf_to_cnj <input.gltf|.glb> <outputDir> <baseName> [unitScale]` (`gltf_to_cnj.cpp:657-686`).
— **VERIFIED**

**H4.** The tool emits, per mesh group: one `<name>.cnj` (JSON, `cnjVersion: 2`,
`type: "Model"`), `<name>_meshN_verts.bin`, `<name>_meshN_idx.bin`, optional
`<name>_meshN_morph.bin`, optional `<name>.skeleton.bin`, one standalone `<name>_<clip>.cnj`
per animation clip (`cnjVersion: 1`, `type: "AnimationClip"`), and extracted textures
(`_texN.*`, `_texoccN.*`). Multiple skins ⇒ multiple `.cnj` Models, suffixed `_static` /
`_<skinName>` (`gltf_to_cnj.cpp:630-650`). — **VERIFIED**

**H5.** The `.cnj` Model schema went to **version 2** in this lane, adding a top-level
`"bones"` array (name/parent/16-float local transform, parent-before-child, index 0 = identity
root) and a per-mesh `"parentBone"` index (`gltf_to_cnj.cpp:444-472, :506`).
`ValidateCnjEnvelope(..., "Model", path, /*maxVersion=*/2)` — **Model is the only type with a
version 2**; every other type still rejects anything but 1 (`ContentManager.cpp:2274-2277`,
`CnjEnvelope.hpp:140-211`). Version-1 files still load via a per-mesh fallback bone
(`ContentManager.cpp:2296-2299, :2620-2637`). — **VERIFIED**

**H6.** `.skeleton.bin` gained an **optional third matrix block** (the per-root prefix),
appended after the two existing blocks and detected by `Remaining() >= boneCount * 64` so older
sidecars still load (`ContentManager.cpp:2375-2383`, written at `gltf_to_cnj.cpp:402-404`).
— **VERIFIED**

**H7.** There are **four** distinct `Model`-producing routes in-tree, not three: XNB
`ModelReader` (`modules/content/src/Xnb/ModelContentTypeReaders.cpp:190-344`, the only one that
reads a real `VertexDeclaration` from the asset, `:96-118`), `.cnj` `ModelTypeReader`, runtime
`.gltf`/`.glb` `ReadGltfModel`, and — for the Avatar-specific `SkinnedModelEXT` type —
`.skinnedmodel.json` `SkinnedModelTypeReader` (`ContentManager.cpp:2825`). — **VERIFIED**

**H8.** `ExtractMesh`'s rejections throw plain `std::runtime_error`, and `ReadGltfModel` does
not wrap them, so `Load<Model>` on a TRIANGLE_STRIP `.glb` throws `std::runtime_error` where
the rest of the reader throws `ContentLoadException`. Since
`ContentLoadException : std::runtime_error` (`ContentLoadException.hpp:10`), a
`catch (ContentLoadException&)` misses it. — **VERIFIED** (fact); severity **PROBABLE**

### I. Validation / oracle methodology

**I1.** `docs/gltf-conformance.md` (426 lines) pins the glTF 2.0 specification to Khronos
commit `2b29723d025a995971726f2989697cdc49b1222a`, SHA-256 `55986799…4b27967`, 149,830 bytes,
pinned 2026-08-11, with a re-verification `curl | sha256sum` recipe (`:53-76`). The spec is
**not** vendored and CNA has no dependency on it. A resolved anchor map of 40 sections is given
(`:106-149`). — **VERIFIED**

**I2.** A **seven-layer oracle ladder** is defined; **five are implemented** (`:192-199`): L1
container structure, L2 decoded accessor arrays (`DumpAccessorEXT`), L3 semantic mesh streams
(`DumpMeshOutEXT`), L4 world positions after node composition (`EvaluateWorldPositionsEXT`), L5
byte-exact VB/IB goldens (`CompareVertexBytesEXT`/`CompareIndexBytesEXT`). **L6 (bound effect
parameters) and L7 (rendered pixels vs golden PNG) are not implemented.** All helpers are
test-scope-only, in namespace `CnaTest::GltfOracle`, under
`modules/content/tests/CNA/Internal/GltfImport/`. — **VERIFIED**

**I3.** The corpus is a **committed, generator-produced, digest-verified** tree:
`tests/assets/gltf/` holds **16** distinct assets × (`.gltf` + `.glb` + `.expected.json`) plus
**14** `.vb.bin`/`.ib.bin` golden pairs = **76 files**, every one carrying a SHA-256 in
`manifest.json` (`files[]`, 76 entries; `distinctAssetCount: 16`). The two assets without
goldens are `mode-points` and `mode-triangle-strip` — the ones `GLTF-071` rejects.
— **VERIFIED**

**I4.** `tools/gltf_fixtures/` is a **stdlib-only, deterministic** Python generator (11 modules
+ README): `--out` regenerates, `--check` verifies byte-identity, `--list` prints the inventory.
`CnaTests` never runs it — it re-verifies digests instead, so no Python interpreter is needed at
test time (`tools/gltf_fixtures/README.md:11-40`). — **VERIFIED**

**I5.** `<id>.expected.json` keeps three things strictly apart: `l1`–`l4` **spec-derived**
expectations that never change when CNA is fixed; `defects[]` with `currentActual` = what CNA
produces *today* as dated evidence; and a per-defect `status` (`:249-262`). A known-defect test
asserts *both* that the spec expectation is unmet *and* that the divergence is exactly the
recorded one (`:263-267`). — **VERIFIED**

**I6.** The defect ledger has a **three-state lifecycle** (`known-failing` →
`partially-remediated` → `fixed`) and a record is **never deleted** — a fixed defect becomes a
regression witness with its original measurement moved to `priorActual` (`:269-281`). Current
state from `tests/assets/gltf/manifest.json`:

| Defect | Status | Closed by | Remaining |
|---|---|---|---|
| D1/D2/D3 (node TRS, parent-child, `node.matrix`) | **fixed** | GLTF-103→113→114→115 | — |
| D4 (sparse index accessor → zeros) | **fixed** | GLTF-063 | — |
| D5 (non-TRIANGLES reinterpreted) | **partially-remediated** | GLTF-071 | GLTF-072 |
| D6 (rigid node animation dropped) | **known-failing** | — | GLTF-284 |
| D7 (factor-only PBR material lost) | **known-failing** | — | GLTF-217/228/229 |
| D8 (skin ancestor chain dropped) | **fixed** | GLTF-245→247→248→260 | — |
— **VERIFIED**

**I7.** The L5 golden layout table is **deliberately stated twice** — in
`tools/gltf_fixtures/l5.py:34-45` and in `GltfBufferOracleEXT.cpp` — and a test asserts they
agree, on the reasoning that "a table stated once cannot catch its own drift" (`:398-400`). The
packer raises an explicit `NotImplementedError` for strides 20/48/68 rather than emitting an
unchecked golden (`l5.py:74-76`). — **VERIFIED**

**I8.** **No pixel oracle and no geometry oracle above L5 exists for glTF.** There is no glTF
golden PNG. The nearest thing is a per-renderer example programme,
`modules/renderers/easygl/examples/easygl_model_skinned_animation_playback_test.cpp`, which
drives `AnimationPlayer → SkinnedEffect::SetBoneTransforms → Model::Draw` on a hand-authored
`.model.json` fixture and samples one screen pixel at two clip times (`:1-26, :283`). It uses a
`.model.json` fixture, **not** a glTF file. — **VERIFIED**

**I9.** `tests/assets/gltf/` contains **no third-party asset**. Every fixture is CNA-authored
and MS-PL (`:178-180`). `medieval_castle.glb` (5.5 MB, in the parent directory) is **not
referenced anywhere in CNA** — grep across all sources, CMake and docs returns nothing. Khronos
sample assets, `glTF-Validator` and the reference renderer are all explicitly **not pinned
yet** (`:176-180`). — **VERIFIED**

### J. Test evidence

**J1.** glTF-specific suites, `modules/content/tests/CNA/Internal/GltfImport/` — **4,530 lines,
76 `TEST(...)` cases** across 9 test files plus 3 oracle helper TUs (`GltfOracleEXT.cpp` 719,
`GltfBufferOracleEXT.cpp` 280, `GltfFixtureCorpus.cpp` 242, all zero-test infrastructure):

| File | Lines | Tests | What it asserts |
|---|---:|---:|---|
| `GltfIndexDecodeTests.cpp` | 547 | 16 | u8/u16/u32 decode; both byte offsets; implicit range; sparse override; sparse with null base view; sparse with a *different* component type; 6 negative cases each asserting the error **names** the offending value/type (`:422, :441, :454, :471, :489, :513, :531`) |
| `GltfFixtureCorpusTests.cpp` | 577 | 11 | per-file SHA-256 vs manifest (`:128`); owning-group count sums to `distinctAssetCount` (`:169`); all 14 audit fixtures promoted (`:192`); every `.glb` twin is a valid container carrying the same asset (`:224`); conformance L1/L2/L3/L4 field-by-field (`:273`–`:547`) |
| `GltfAccessorDecodeLockTests.cpp` | 289 | 8 | locks the *verified-correct* attribute path (`GLTF-041`): interleaving, both offsets, normalized u8 colour byte-exact round-trip, MAT4 IBM decode, non-normalized joint indices staying integral; cross-checks the L2 dump against what **production** `ExtractMesh` produced (`:201`) |
| `GltfBufferOracleEXTTests.cpp` | 391 | 10 | the L5 comparator proving itself (perturbed byte reported at the right offset/field/vertex `:116, :155`; truncation at the first missing byte `:216`; unknown stride reported not guessed `:274`), the twice-stated-table agreement (`:239`), and the golden comparisons (`:291, :350, :375`) |
| `GltfPrimitiveTopologyTests.cpp` | 336 | 9 | all seven modes classify by number *and* name; exactly one is supported and it is TRIANGLES (`:177`); absent mode = TRIANGLES per spec default (`:208`); a rejected primitive produces **no index list at all** (`:299`); mode outside 0…6 rejected, not assumed (`:323`) |
| `GltfSceneGraphBonesTests.cpp` | 402 | 9 | the `scene.nodes[i] ↔ model.Bones[i]` contract through the **real** `ContentManager::Load<Model>` on committed fixtures; that `BuildSceneGraph`'s composed worlds equal `CopyAbsoluteBoneTransformsTo`'s recomposed worlds (two independent computations, `:129-137`); the rigid/skinned parenting asymmetry (`:163-178`); `GltfSkinSpaces` asserting the joint matrix is exactly identity for `skin-armature-ancestor` (`:307`) and exactly `T(0,0,-50)` for `skin-mesh-node-transform`, with the failure message spelling out that 0 means the cancellation is missing and −100 means it was applied twice (`:370-372`) |
| `GltfImportCoreTests.cpp` | 611 | 10 | UV-set mismatch detection both ways; occlusion remap success/failure; Draco decode; angle-weighted tangent contributions; Draco + generated tangents; `KHR_texture_transform` + emissive strength; punctual-light approximation and the 3-light cap |
| `GltfKnownDefectTests.cpp` | 440 | 5 | D5 ×2, D6, D7 — each asserting the divergence is *exactly* the ledger's `currentActual`, with failure messages instructing the implementer to mark the defect fixed and delete the test (`:296-298, :329-331`); plus a **bidirectional ledger-completeness test** (`:385`) that fails if an open defect lacks a test *or* a remediated one still has one |
| `GltfOracleEXTTests.cpp` | 260 | 8 | the oracles themselves: dump stability/round-trip, out-of-range reported not read, agreement with cgltf on every fixture (`:211`), and that **using the oracle does not alter production output** (`:224`) |
— **VERIFIED**

**J2.** Content-level model/CNJ suites: `GltfToCnjToolTests.cpp` (1,732 lines, **20 tests**,
spawns the real `cna_tool_gltf_to_cnj` binary as a subprocess via `CNA_GLTF_TO_CNJ_TOOL_PATH`,
`cmake/UnitTests.cmake:262-269`; **excluded on WIN32/EMSCRIPTEN/ANDROID**, `:113-118`);
`RuntimeGltfModelTests.cpp` (796/9, in-process, embedded base64 fixtures);
`ContentManagerSkinnedModelTests.cpp` (345/9, all malformed-input rejection); `CnjModelTests.cpp`
(170/2); `CnjModelSharedAnimationClipTests.cpp` (251/3); `CnjEnvelopeTests.cpp` (340/**28**);
`ModelContentTypeReaderTests.cpp` (161/3, the XNB route). — **VERIFIED**

**J3.** Graphics-level suites: `ModelTests.cpp` (270/17), `ModelMeshPartTests.cpp` (221/22),
`ModelBoneTests.cpp` (169/17), `ModelBoneCollectionTests.cpp` (115/11),
`ModelMeshCollectionTests.cpp` (121/12), `ModelMeshTests.cpp` (66/8),
`ModelCollectionIndexTests.cpp` (173/6), `SkinnedModelEXTTests.cpp` (477/22),
`AnimationPlayerTests.cpp` (173/12), `MorphTargetEXTTests.cpp` (289/15),
`SkinnedEffectTests.cpp` (535/57), `SkinnedPbrEffectTests.cpp` (351/46), `PbrEffectTests.cpp`
(250/33). — **VERIFIED**

**J4.** **`Model::Draw` and `ModelMesh::Draw` have no unit test.** `ModelTests.cpp` covers only
the three `CopyBoneTransforms*` methods and the constructors; grep for `Draw()` in
`ModelTests.cpp` and `ModelMeshTests.cpp` returns nothing. The draw path is exercised only
indirectly, by renderer example programmes. — **VERIFIED**

**J5.** Every 3D-pipeline test is gated on a **real capability**, not on luck — the pattern
introduced by `7de755c84`:
`if (!gd.SupportsCapability(CNA::GraphicsCapability::ThreeD)) GTEST_SKIP() << "renderer has no 3D pipeline (GraphicsCapability::ThreeD is false)";`
appears in `RuntimeGltfModelTests.cpp` ×9, `GltfToCnjToolTests.cpp` ×8,
`ModelContentTypeReaderTests.cpp` ×2, `CnjModelSharedAnimationClipTests.cpp` ×2. The
`GltfImport/` suites are **not** so gated — they test the importer, not the GPU. — **VERIFIED**

**J6.** Suite size and health are recorded in the lane's own commit messages: **5,490 tests /
21 failures** at `e0638644d`, **5,492 / 21** at `e9336a107`, both described as "byte-identical
to the pre-P0-C failing set, all pre-existing STUB-renderer capability gaps unrelated to
glTF". — **VERIFIED** (as a claim in the commit trailer; not independently reproduced, since
building was out of scope)

### K. Renderer interaction

**K1.** `IGraphicsRenderer::Ensure3DSupported` defaults to a **no-op**
(`modules/graphics/include/CNA/Internal/Renderers/Common/IGraphicsRenderer.hpp:1604`). It is
called at the top of every 3D draw route in `GraphicsDevice`
(`modules/graphics/src/Xna/GraphicsDevice.cpp:1073, 1145, 1235, 1339, 1391, 1570, 1594, 1618,
1642, 1673`) and once in `ModelMesh::Draw` (`:45`). Only **five** renderers override it to
refuse: html-dom (`HtmlDomRenderer.cpp:1023`), openvg (`OpenVgRenderer.cpp:656`), direct2d
(`Direct2DRenderer.cpp:3165`), skia (`SkiaRenderer.cpp:906`), svg-dom (`SvgDomRenderer.cpp:666`).
Other 2D-only renderers refuse deeper, inside the draw implementations. — **VERIFIED**

**K2.** `IGraphicsRenderer::SupportsCapability` defaults to **`true`** for everything except
`MultiStreamVertexInput` (`IGraphicsRenderer.hpp:1823-1835`). `GraphicsCapability::ThreeD`
therefore reports true unless a renderer explicitly says otherwise
(`modules/graphics/include/CNA/GraphicsCapability.hpp:16-23`). Across the 43 renderer
directories:
- **Explicitly `ThreeD = false`** (2D-only): blend2d (`Blend2DRenderer.cpp:507`), direct2d
  (`:335`), skia (`SkiaRenderer.cpp:886`), canvas (`CanvasRenderer.hpp:88-93` — true only for
  `AdditiveBlending`), sdl-renderer (`SdlRenderer.hpp:179-184`, same shape), gdi
  (`GdiRenderer.cpp:926-936`), directx1 (`DirectX1Renderer.hpp:122-127`), openvg
  (`OpenVgRenderer.hpp:118-131`), html-dom (`HtmlDomRenderer.cpp:729`), svg-dom
  (`SvgDomRenderer.cpp:651`).
- **Explicitly `ThreeD = true`**: diligent, directx2/3/5/6/7/8/10, glide, llgl, magnum, metal,
  opengl1/2/4, opengles1, portablegl, sokol, wicked.
- **True by inherited default** (no override): bgfx, directx9, directx11, directx12, easygl,
  fna3d, freedirect, headless, sdl-gpu, software, stub, vulkan, webgpu.
— **VERIFIED**

**K3.** PBR shader coverage is uneven. Files referencing `PbrEffect`/`SkinnedPbrEffect` per
backend: directx9 (13/8), vulkan (12/10), llgl (11/7), bgfx (10/6), sdl-gpu (10/6), magnum
(8/2), diligent (6/4), easygl (5/4), metal (5/7), opengl2 (5/3), opengl4 (5/3), webgpu (5/5),
directx11 (4/3), wicked (4/3), directx12 (2/2), opengl1 (2/2), sokol (2/1), skia (2/2 — refusal
paths), portablegl (2/0), opengles1 (2/0), glide (1/0). **Zero** in blend2d, canvas, direct2d,
directx1/2/3/5/6/7/8/10, gdi, html-dom, openvg, software, stub, svg-dom, freedirect, fna3d,
headless. — **VERIFIED** (file counts are a proxy; per-renderer shader completeness **PROBABLE**)

**K4.** `CNAEXT.md:110-120` publishes a hand-maintained PBR coverage table (EasyGL/Vulkan/
Bgfx/SdlGpu/D3D11 ✅, WebGPU unskinned only, D3D9/D3D12 compile-verified). It does **not** list
Metal, LLGL, Magnum, Diligent, OpenGL 1/2/4, Sokol, Wicked, DirectX12 — all of which carry
`PbrEffect` code. — **VERIFIED**

**K5.** There is exactly **one** golden-image asset family for skinned/PBR rendering, all
EasyGL: `examples/golden/easygl_pbreffect_golden_test_{a..d}.png`,
`easygl_skinnedeffect_golden_test.png`, `easygl_skinnedeffect_vertexcolor_test_{a,b}.png` — 7
of the repository's 17 goldens. **None is produced from a glTF file.** — **VERIFIED**

---

## GLTF FEATURE TABLE

Importer = what `GltfImportCore` + a loader actually produce. Runtime = what CNA does with it
at draw time. "n/a" = the feature has no runtime component.

| glTF 2.0 feature | Importer | Runtime | Test evidence |
|---|---|---|---|
| `.gltf` container | yes, cgltf 1.15 | n/a | corpus ×16, `GltfFixtureCorpus.EveryFixtureParsesAndLoadsItsBuffers` |
| `.glb` container | yes, same path | n/a | `EveryGlbTwinIsAValidContainerCarryingTheSameAsset` |
| base64 `data:` URI buffers | yes | n/a | all 16 fixtures load |
| external `.bin` / percent-encoded URI | yes (`cgltf_load_buffers`, `cgltf_decode_uri`) | n/a | **none** (corpus is data-URI-only) |
| `asset.version` gate (2.0 only) | yes, throws otherwise | n/a | **none** |
| `extensionsRequired` honoured | **no, never read** | no | none |
| Scenes / default-scene selection | yes; non-reachable nodes excluded | n/a | `scene-default-selection` at L1/L3/L4 |
| Node hierarchy → `ModelBone` | yes, synthetic identity root at 0 | yes | `GltfSceneGraphBones` ×6, `GltfConformanceL4` ×2 |
| `node.matrix` | yes via `cgltf_node_transform_local` | yes | `xf-matrix-node` (D3 fixed) |
| Node TRS | yes | yes | `xf-parent-child`, `xf-shared-mesh` (D1/D2 fixed) |
| Mesh instancing (one mesh, N nodes) | yes, one `MeshInstanceOut` per placement | yes, N `ModelMesh`es sharing geometry | `SharedMeshGetsOneBonePerInstancingNode` |
| Multiple mesh groups (skins) per file | offline: one `.cnj` per group | **runtime: `groups.front()` only** | `ImportsAllSkinsAsSeparateModels`; runtime limit untested |
| Accessors: `byteOffset`, `byteStride`, interleaving | yes | n/a | `GltfAccessorDecodeLock` ×8 |
| Accessors: normalized integer conversion | yes | n/a | `normalized-u8-color`, byte-exact repack |
| Sparse *attribute* accessors | yes incl. null base bufferView | n/a | `sparse-position` |
| Sparse *index* accessors | yes, CNA-side reader (D4 fixed) | n/a | `GltfIndexDecode` ×16 |
| Index component types u8/u16/u32 | decoded; **width re-chosen** by `vertexCount > 65535` | yes | `u8-idx`; width rule at L5 |
| Index bounds validation | yes, named error | n/a | `AnIndexBeyondTheVertexCountIsAnErrorNamingTheValue` |
| Non-indexed primitives | yes, implicit range synthesised | yes | `NonIndexedPrimitiveSynthesisesTheImplicitRange` |
| `mode 4` TRIANGLES | yes | yes | whole corpus |
| modes 0/1/2/3/5/6 | **classified and rejected**, mode named (D5 partial) | no | `GltfPrimitiveTopology` ×9, `GltfKnownDefect.D5_*` ×2 |
| POSITION/NORMAL/TEXCOORD_n/COLOR_0/JOINTS_0/WEIGHTS_0/TANGENT | yes | yes | corpus + `GltfConformanceL3` |
| TEXCOORD set selection (base-colour's own `texcoord`) | yes | yes | `UsesTexcoordSetSelectedByMaterial` |
| Second UV channel (per-map `texCoord`) | **detected only** (`pbrUv2Mismatch`) | no, single shared UV | `Extract...MismatchedPbrMapUvSets` |
| `JOINTS_1`/`WEIGHTS_1` (>4 influences) | no | no | none |
| Tangent generation when absent | yes, angle-weighted, not full MikkTSpace | yes, stride 48/68 | `ComputeTangentsEXT*` ×2 |
| PBR metallic-roughness — **maps** | yes | yes, `PbrEffect`/`SkinnedPbrEffect` | `LoadsPbrMaterialWithAllFourMapsAndFactorsFromGltf` |
| PBR **factors** (metallic/roughness/emissive) | only when `usePbr` already true | yes | same |
| **`baseColorFactor`** | **no `MeshOut` field exists** | no | `GltfKnownDefect.D7_*` |
| `alphaMode`/`alphaCutoff`/`doubleSided` | no | no | `GltfKnownDefect.D7_*` |
| PBR selection for a factor-only material | **no** — falls to white `BasicEffect` (D7 open) | no | `GltfKnownDefect.D7_*` |
| Occlusion → `DualTextureEffect` Texture2 | yes, decode/halve/re-encode | yes | `RemapsOcclusionTextureBrightness…` |
| Images: bufferView / data-URI / external file | all three | yes, in-memory decode, cached | `ExtractsEmbeddedBaseColorTextureAndLoadsIt` |
| Samplers (wrap, min/mag filter) | **never read** | device default `LinearWrap` | none |
| sRGB vs linear colour space | no | no | none |
| Skins: joints, `inverseBindMatrices` | yes, topological reorder + palette remap | yes | `LoadsSkinnedAnimated…WithReversedJointOrder` |
| Skin scene ancestry above the joint set | yes (D8 fixed, `parentWorldPrefix`) | yes, `SkeletonRootPrefix` | `RootJointCarriesTheSceneAncestryAboveTheJointSet` |
| `inverse(globalTransform(meshNode))` cancellation | yes, exactly once | yes | `MeshNodeTransformIsCancelledExactlyOnce` |
| `skin.skeleton` treated as hint, not stop | yes | n/a | `skin-armature-ancestor` |
| Animation: skin-joint TRS channels | yes, resampled onto union key times | yes, `AnimationPlayer` | `RuntimeGltfModelTest`, `AnimationPlayerTests` ×12 |
| Interpolation LINEAR/STEP/**CUBICSPLINE** | yes, real Hermite with `deltaT`; quats renormalised | yes (baked to keys for bone tracks) | `EvaluatesCubicSplineWithRealHermiteBasis` |
| **Rigid (unskinned) node animation** | **dropped by two mechanisms, silently** (D6 open) | no | `D6_RigidNodeAnimationIsSilentlyDropped` |
| Morph targets: POSITION/NORMAL deltas | yes | yes, CPU blend + VB re-upload | `LoadsMorphTargetData…`, `MorphTargetEXTTests` ×15 |
| Morph TANGENT deltas | no, documented scope cut | no | — |
| Mesh default `weights` | yes, applied at load if non-zero | yes | `LoadsMorphTargetData…` |
| Morph `weights` animation channel | yes, tangents preserved unbaked | yes, `EvaluateMorphWeightsEXT` | `LoadsCubicSplineMorphWeightAnimation…` |
| `KHR_draco_mesh_compression` | **optional** (`find_package(draco)`); clear throw when absent | yes | `ExtractMeshDecodesDracoCompressedTriangle` |
| `KHR_texture_transform` | base-colour only, baked into shared UV | yes | `AppliesTextureTransformAndEmissiveStrength` |
| `KHR_materials_emissive_strength` | yes (PBR path only) | yes | same |
| `KHR_lights_punctual` | ≤3, all approximated as directional | yes via `IEffectLights` | `ExtractPunctualLights…` ×2 |
| `KHR_materials_transmission` | no | no | none |
| `KHR_materials_variants` | no | no | none |
| Cameras | no | no | none |
| Negative-scale winding flip | no | no | none |

---

## CONTRADICTIONS

**C-1 — `plan_gltf.md` contradicts itself about what has landed.** Its §29 prose (`:1776-1805`)
says "Two batches are complete", that P0-B "changes glTF behaviour" but "**No D1–D8 production
fix was implemented**" in P0-A, and — explicitly — "**D1, D2, D3, D6, D7 and D8 are untouched by
P0-B** … No renderer, no `cna-gltf-viewer` and no node-transform work was started." The same
file's own task tables mark `GLTF-103/113/114/115/129/130/245/247/248/260` as DONE (`:1971-1998,
:2171-2186`), and both `docs/gltf-conformance.md:292-299` and the manifest ledger record
D1/D2/D3/D8 as **fixed**. The prose is a stale P0-B-era snapshot. **Implementation wins.**
— **VERIFIED**

**C-2 — `FUTURE.md` says the campaign has not started.** `FUTURE.md:27` — "Phase 5 — glTF
correctness campaign | **not started**; blocked on Phase 4" — and `:43` — "glTF is **not**
corrected." Twenty-one `GLTF-xxx` tasks have landed, including all of D1–D4 and D8.
`plan_gltf.md:2463` (`GLTF-449`) exists specifically to fix this text and is itself still open.
— **VERIFIED**

**C-3 — `gltfissues.md` is materially superseded and its line citations no longer resolve.**
Dated 2026-07-28, written against the pre-modularization tree. Its headline finding #1 ("CNA
discards glTF node transforms", `:12-14, :117-154`) is **now fixed** (D1/D2/D3). Its cited paths
(`include/CNA/Internal/GltfImport/GltfImportCore.hpp:163`, `src/CNA/Internal/GltfImport/
GltfImportCore.cpp:1231`, `src/Microsoft/Xna/Framework/Content/ContentManager.cpp:2126`) do not
exist — those trees moved to `modules/content/...` in `05a123277`. Its findings #2
(baseColorFactor + `usePbr` map-gating), #4 (transmission), and the sub-findings on samplers,
multi-UV, variants, sRGB and rigid animation **all still hold verbatim** against HEAD.
— **VERIFIED**

**C-4 — `docs/gltf-conformance.md` is one fixture behind.** §3.4 lists 15 fixtures and §4.3
(`:415`) says "13 of the 15 fixtures carry a golden". The committed corpus is **16** assets with
**14** goldens — `skin-mesh-node-transform` was added in the lane's last commit (`e9336a107`)
and the two prose counts were not updated. The manifest (`distinctAssetCount: 16`) is
authoritative per the doc's own rule (`:236-238`). — **VERIFIED**

**C-5 — `plan_gltf.md` §24.1 claims the generator self-validates; it does not.**
"**Self-validated.** The generator runs `glTF-Validator` over every emitted file" (`:1502-1503`).
`tools/gltf_fixtures/` imports only `argparse`, `hashlib`, `json`, `pathlib`, `sys`, `typing` —
no subprocess, no validator. `docs/gltf-conformance.md:178-180` concedes the validator is among
the artefacts "not pinned yet" (`GLTF-015`). — **VERIFIED**

**C-6 — `plan_gltf.md` §24.3's licensing/asset statement is stale.** "`git ls-files` finds
**no** tracked `.gltf`/`.glb` binaries in CNA … Every current glTF test builds its fixture as an
inline JSON string literal" (`:1560-1566`). Sixteen `.gltf` + sixteen `.glb` are now tracked.
(The *substance* — every fixture CNA-authored, MS-PL — is still true.) — **VERIFIED**

**C-7 — the "136-asset corpus" number is used in two incompatible senses.** `plan_gltf.md:1517,
:1548` define 136 as the **planned** total; commit `e9336a107`'s trailer states flatly "Corpus
is 136 assets". The committed corpus is 16 (11.8% of plan). A reader of the commit log alone
would badly overestimate coverage. — **VERIFIED**

**C-8 — `CNAEXT.md` §3.2 reads as a completeness statement.** `:122-132` lists "Imports:
geometry, PBR materials (4 maps + factors), … skins/skeleton, animation (LINEAR/STEP/CUBICSPLINE
Hermite)…" with no caveats. `plan_gltf.md:241-249` grades this exact section itself: runtime path
**PARTIAL** (`groups.front()` only), PBR **PARTIAL** (`baseColorFactor`/`alphaMode`/`alphaCutoff`/
`doubleSided`/normal scale/occlusion strength all lost), animation **PARTIAL** (rigid node
animation dropped). D1–D4 and D8 have since closed, but those PARTIAL verdicts remain accurate
against HEAD and §3.2 still does not mention them. — **VERIFIED**

**C-9 — `cnj.md` documents a `cnjVersion == 1` policy that is no longer true.** `cnj.md:22` —
"validates against the requested C++ type with a strict `cnjVersion == 1` policy".
`ContentManager.cpp:2277` passes `maxVersion = 2` for `Model`, and the tool emits
`"cnjVersion": 2` (`gltf_to_cnj.cpp:444`). `cnj.md`'s Model example (`:277`) still shows version
1, and `:283` says the version is "for the *envelope* itself (not per-type)" — now exactly
backwards: `ValidateCnjEnvelope`'s ceiling **is** per-type (`CnjEnvelope.hpp:196-211`), and
`CnjEnvelopeTests.cpp` locks that a raised ceiling on one type does not leak to another.
— **VERIFIED**

**C-10 — two doc comments cite a "CLAUDE.md stride table" that does not exist.**
`GltfImportCore.hpp:158` and `MorphTargetEXT.hpp:84` both say "see CLAUDE.md's stride table".
`CLAUDE.md` contains **zero** occurrences of the word "stride". The real table is
`plan_gltf.md:219-227` and `tools/gltf_fixtures/l5.py:34-45`. — **VERIFIED**

**C-11 — `MorphTargetDataEXT::Stride`'s documented value set is incomplete.**
`MorphTargetEXT.hpp:84` says "(32, 52, or 56)". `ExtractMesh` can hand it 20, 24, 48 or 68 as
well (`GltfImportCore.cpp:1299-1300`), and `BlendMorphTargetsEXT` handles that by simply not
writing normals for strides without a normal slot (`MorphTargetEXT.cpp:31`) — but a stride-48/68
PBR mesh with morph targets gets **position-only** morphing with no diagnostic, because 48/68
are not in `hasNormalSlot`. — **VERIFIED** (fact); user impact **STRONG**

**C-12 — `THIRD_PARTY_NOTICES.md` omits cgltf and stb.** The file has 8 sections (Avatar
content, XNA stock effects ×2, FNA3D, Skia, wgpu-native, DiligentCore, sokol).
`third_party/cgltf/` (MIT, © 2018-2021 Johannes Kuhlmann, `third_party/cgltf/LICENSE:1`) and
`third_party/stb/` are compiled directly into `cna_content` and are **not listed**. Draco, when
found, is likewise unlisted. — **VERIFIED**

**C-13 — `audit/` notes are pre-modularization and pre-lane.**
`audit/src/CNA/Internal/GltfImport/GltfImportCore.cpp.audit.md` audits
"`src/CNA/Internal/GltfImport/GltfImportCore.cpp`" at "1409 lines", with `BuildSkeleton()` at
"lines 419-499". The file is now `modules/content/src/GltfImport/GltfImportCore.cpp`, 1,852
lines, `BuildSkeleton` at 649-762. It also records `BuildSkeleton` as "Confirmed correct" —
which was the exact site of **D8**. The audit tree is a stale snapshot and must not be cited as
current. — **VERIFIED**

**C-14 — `AUDIT.md` and `README.md` say nothing about glTF at all.** Case-insensitive grep for
"gltf" returns **zero** hits in either (`AUDIT.md` 168 KB; `README.md` 61 KB). Not a
contradiction of fact — a coverage gap that will mislead anyone using either as an index.
— **VERIFIED**

**C-15 — the runtime path's `pbrUv2Mismatch` warning is documented but unreachable.**
`GltfImportCore.hpp:206-217` states "`ExtractMesh`'s caller (`gltf_to_cnj.cpp`) surfaces this as
a warning". The **runtime** caller (`ReadGltfModel`) computes the flag and discards it — no
warning, no log, no exception. A game loading a `.glb` directly gets the silent mis-render the
flag exists to prevent. — **VERIFIED**

---

## BOOK IMPACT

### Verdict

**A dedicated 3D/glTF Part is justified, and the existing single chapter is no longer
adequate.** The justification is *not* "CNA supports glTF well." It is that CNA now contains a
fully-formed, unusually rigorous **correctness-campaign apparatus** around glTF — a pinned
specification, a generated digest-verified corpus, a five-layer numerical oracle, and an
executable defect ledger with a three-state lifecycle — and that apparatus is more instructive
than most of the feature surface it guards. It is the single best worked example of engineering
method anywhere in the CNA tree, and the book currently does not mention it.

Scale supporting it: ~2,500 lines of importer + tool, ~4,500 lines of glTF-specific test, 76
test cases, 76 committed corpus files, 426 lines of normative reference doc, 2,572 lines of
campaign plan, four distinct `Model`-producing routes, two independent skeletal-animation
systems, an eight-entry stride ABI with no single source of truth, and 43 renderer backends of
which only some can draw any of it.

The existing `ch12-models-meshes.tex` (558 lines) already covers well: the runtime hierarchy,
the draw contract, the part↔effect setter invariant, asset routes, value-syntax lifetime, the
two-skinning-systems split, a morph worked example, and the arbitrary-root-bone constructor. It
should **stay largely as it is**, as the *XNA-surface* chapter — with the glTF material lifted
out and "three model asset routes" corrected to four.

### Proposed new Part: "3D Content: glTF, CNJ, and Conformance" — five chapters

**Chapter A — "From glTF file to `Model`: the import core"** (~16–18 pp). One-library-two-callers
architecture; vendored cgltf 1.15 and the single-`CGLTF_IMPLEMENTATION`/`STB_IMAGE_STATIC`
linking constraint; `BuildSceneGraph` and the synthetic identity root; `CollectMeshGroups` and
`MeshInstanceOut`; why vertex positions stay mesh-local so instancing survives;
`ConvertGltfMatrix` and the row-vector/column-vector transpose; the "no axis or handedness
conversion" invariant and why it is *correct* rather than an omission. Ends with the two honest
limitations: `groups.front()` on the runtime path, and `unitScale` being CLI-only.

**Chapter B — "GPU packing: the stride ABI"** (~14–16 pp). The seven-entry stride table as a
de-facto ABI with **no single source of truth**. The vtable-inflation bug
(`ContentManager.cpp:1730-1745`) is an excellent teaching case: a polymorphic `IVertexType` base
inflates `sizeof()` past the packed stride, so the resulting `reinterpret_cast` reads every
field from the wrong offset — diagnosed as the real cause of an "invisible model" symptom
family. Then index widths (chosen by vertex count, not source type), the bounds proof that makes
the `uint16` narrowing safe, the hardcoded `numIndices / 3` in three loaders, and
`ModelMesh::Draw`'s hardcoded `TriangleList`. Close with the caps: 4 influences, 255 joints, 72
bones, one UV set.

**Chapter C — "Skinning and animation across two systems"** (~16–18 pp). The deliberate
`SkinningData`/`AnimationPlayer` vs `SkinnedModelEXT` split and the documented reason for the
duplicated `SampleTrack`. Topological joint reorder and the `sceneNodeIndex` ↔ `paletteIndex`
two-index-space distinction. Centrepiece **D8**: `BuildSkeleton` originally walked parents only
inside the joint set, so the armature transform above the joints was dropped from the bind pose
while the file's `inverseBindMatrices` — which contain it — were kept verbatim; every skinned
vertex was multiplied by the inverse of what was lost, and for a uniformly-scaled armature that
is a division by the scale, i.e. a character collapsing toward the origin. The fix, and
specifically **why the two recovered terms ride on a separate
`parentWorldPrefix`/`SkeletonRootPrefix` rather than being folded into the bind pose** (folding
would be undone the instant a clip replaced a root joint's local transform), is one of the
sharpest design arguments in the codebase.

**Chapter D — "The CNJ toolchain: `gltf_to_cnj` and the `.cnj` Model format"** (~12–14 pp).
`cmake/ToolGltfToCnj.cmake` and why the tool is built unconditionally and links no renderer. The
complete emitted file set. The `.cnj` v2 schema and the **per-type version ceiling**. The
`.skeleton.bin` optional-third-block trick that keeps older sidecars loading. The offline↔runtime
parity requirement (`GLTF-130`) as a *tested* contract. The `DualTextureEffect`
occlusion-brightness derivation as a short worked example of an approximation documented and
then corrected.

**Chapter E — "Proving it: the conformance corpus and the seven-layer oracle"** (~18–20 pp) —
*the chapter with the most to teach*. The specification pin and why the AsciiDoc source rather
than a registry HTML snapshot. The generator: one source of truth emits asset *and* expectation
so the two cannot drift; committed not generated; digests re-verified at test time. The seven
layers, of which five exist and **two (L6 effect parameters, L7 golden pixels) do not** — state
that plainly. The separation of spec-derived truth from CNA-measured evidence, and the two-sided
assertion. The three-state defect lifecycle and the never-delete rule. The bidirectional
ledger-completeness test. The `skin-mesh-node-transform` fixture, authored so "not cancelled /
cancelled once / cancelled twice" are three numerically distinct outcomes. The twice-stated
layout table with an agreement test. And the honest closing: 16 of a planned 136 assets, 21 of
460 tasks, D5 partial, D6 and D7 open.

### Cross-cutting edits to existing chapters

- **`ch12-models-meshes.tex`** — change "three model asset routes" to four (XNB `ModelReader` is
  real and is the only route that reads a `VertexDeclaration` from the asset). Add
  `Model::Draw`'s `static sharedDrawBoneMatrices_` as a concrete, citable reason the class is
  not thread-safe. Note that `Model::Draw`/`ModelMesh::Draw` carry no unit test, so every claim
  about them must be sourced to implementation or to a renderer example programme, never to a
  test.
- **The renderer Part** — add the 3D-capability picture: `SupportsCapability(ThreeD)` **defaults
  to true**, so a renderer must opt *out*; ten do; five of those also override
  `Ensure3DSupported` to refuse at the earliest possible point while the others refuse deeper.
  Worth a page because the default-true polarity is a genuine trap.
- **Stock-effects chapter** — reconcile with real PBR coverage. `CNAEXT.md`'s published table
  omits Metal, LLGL, Magnum, Diligent, OpenGL 1/2/4, Sokol, Wicked and D3D12, all of which carry
  `PbrEffect` code. Do not reproduce that table; derive one from the tree.
- **Feature-matrix appendix** — the GLTF FEATURE TABLE above is directly usable with its
  importer/runtime/test-evidence columns preserved. The three-column shape is what keeps it
  honest: several rows are "importer parses it, runtime ignores it". Collapsing to a single
  yes/no column would misrepresent them.

### Two rules the book must adopt for this material

1. **Never cite `gltfissues.md`, `AUDIT.md`, `audit/**`, `FUTURE.md` or `plan_gltf.md`'s §29
   prose as current state.** Every one is stale in a way that would put a wrong claim in print
   (C-1, C-2, C-3, C-13). The three sources that *are* current: the code,
   `tests/assets/gltf/manifest.json`'s defect ledger, and `docs/gltf-conformance.md` §3.3 — and
   even the last is one fixture behind (C-4).
2. **Say "the importer parses it" and "the runtime plays it" as separate claims, every time.**
   The gap is real and load-bearing: rigid node animation is *in every fixture* and *in no
   clip*; `pbrUv2Mismatch` is *computed* and *never surfaced at runtime*; morph targets on a
   stride-48/68 PBR mesh blend positions and silently skip normals. A book that flattens these
   into "supported" will be wrong within a page.
