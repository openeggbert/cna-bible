# Audit report — content pipeline, XNB container, type readers, CNJ

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root
unless absolute.

---

Repo root elided below as `$CNA` = `/rv/data/development/github.com/openeggbert/cna`. No files were modified; no build was run.

**Scale**: `$CNA/modules/content/` is 130 files / ~33k lines. 41 test files, ~350 test cases. The content module is now one of the largest single subsystems in CNA, and its centre of gravity has moved decisively since the book's Ch. 8 was written.

---

## FACTS

### A. Module shape and build

**A1.** The content pipeline is a first-class CMake module `cna_content`, not part of a monolith. `$CNA/modules/content/CMakeLists.txt:12-15` — `cna_add_module(cna_content Content ${CNA_CONTENT_SOURCES})`, linking `cna_graphics_core cna_audio cna_media cna_math cna_core` plus `SDL3`/`SDL3_mixer` privately. **VERIFIED**

**A2.** The module has three internal namespaces, deliberately separated: `Microsoft::Xna::Framework::Content` (the XNA-faithful public API), `CNA::Internal::Xnb` (the binary readers, all `internal`-equivalent), and `CNA::Internal` / `CNA::Internal::GltfImport` (CNJ envelope, JSON, glTF). Directory split: `$CNA/modules/content/include/Microsoft/Xna/Framework/Content/` (10 headers) vs `$CNA/modules/content/include/CNA/Internal/Xnb/` (17 headers). **VERIFIED**

**A3.** `VideoContentTypeReader.cpp` is excluded from the build when FFmpeg is unavailable: `$CNA/modules/content/CMakeLists.txt:8-10` (`list(FILTER ... EXCLUDE REGEX ".*/src/Xnb/VideoContentTypeReader\.cpp$")`), matched by an `#ifdef CNA_FFMPEG_AVAILABLE` guard at `$CNA/modules/content/src/Xnb/XnbBuiltInReaders.cpp:38-40` and a triple-platform `#if` in `$CNA/modules/content/src/Xna/ContentManager.cpp:47-49, 3012, 3046`. So the reader set is **platform-dependent**. **VERIFIED**

**A4.** The content module depends on two vendored third-party headers: `third_party/cgltf` and `third_party/stb` (`$CNA/modules/content/CMakeLists.txt:20-23`), and optionally `draco::draco` (`:24-26`). Content loading is no longer dependency-free. **VERIFIED**

---

### B. ContentManager

**B5.** Three constructors, none validating `serviceProvider`: `$CNA/modules/content/src/Xna/ContentManager.cpp:87-103`. FNA's two public constructors both throw `ArgumentNullException`. All three call `RegisterBuiltinLoaders()`. **VERIFIED**

**B6.** The member-initialiser list at `$CNA/modules/content/src/Xna/ContentManager.cpp:95` (`serviceProvider_(serviceProvider), rootDirectory_(rootDirectory)`) is in the opposite order from the declarations (`rootDirectory_` at `ContentManager.hpp:50`, `serviceProvider_` at `:52`). Harmless (no interdependency) but a `-Wreorder` smell. **VERIFIED**

**B7.** `serviceProvider_` is **stored and never consulted**. Its only uses are the constructor initialisers and the getter — `$CNA/modules/content/src/Xna/ContentManager.cpp:88, 95, 107`. Nothing anywhere in `modules/` calls `getServiceProviderProperty()` other than its own definition. The GraphicsDevice arrives instead via a separate `setGraphicsDevice()` setter (`:110-113`). **VERIFIED**

**B8.** `RootDirectory` is a `DEF_PROP` property (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentManager.hpp:109`) with a plain string member defaulting to `"Content"` (`:50`); accessors at `ContentManager.cpp:68-81`. **VERIFIED**

**B9.** `BuildAssetPath()` performs an **unguarded** `fs::path(rootDirectory_) / assetName` (`$CNA/modules/content/src/Xna/ContentManager.cpp:296-308`). An absolute `assetName` therefore discards the root entirely — and this is **deliberate**, documented as an established contract at `:376-378`: *"ContentManager::Load() accepts a root-relative logical name and, by established contract, an explicit absolute outside-root asset."* `RootDirectory` is a base, not a sandbox. **VERIFIED**

**B10.** `NormalizeKey()` folds `\` → `/` and lowercases (`$CNA/modules/content/src/Xna/ContentManager.cpp:310-317`), correctly matching FNA's `StringComparer.OrdinalIgnoreCase` asset cache. **VERIFIED**

**B11.** The generic cache key is `(std::type_index, normalizedName)`, not name alone — `$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentManager.hpp:61-81`. The header comment (`:55-60`) explains this was a real bug fix (plan_cnj.md CNB-36): a name-only key made a second `Load<T2>()` throw `std::bad_any_cast` instead of a `ContentLoadException`. Pinned by `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/CnjAssetCacheTypeSafetyTests.cpp`. **VERIFIED**

**B12.** There are **three caches with three different lifetime policies**, not one:
- `loadedAssets_` — strong `std::unordered_map<AssetCacheKey, std::any>`, requires `CopyConstructible` (`ContentManager.hpp:81`).
- `textureCache_` — `Texture2D`-only **weak** cache holding `weak_ptr<ITextureRenderer>` + `weak_ptr<vector<uint8_t>>` + format + level count (`ContentManager.hpp:89-95`), consulted by the `Load<Texture2D>` specialisation (`ContentManager.cpp:3073-3093`), which reconstructs via `Texture2D::ReconstructFromCache` on hit and erases the stale entry on expiry.
- **No cache at all** for `SoundEffect` (`ContentManager.cpp:3149-3183`) and `TextureCube` (`:3191-3226`) — both move-only, each `Load` re-decodes. **VERIFIED**

**B13.** Three explicit `Load<T>` specialisations exist and each **re-implements** the `.xnb`-first check independently: `Graphics::Texture2D` (`ContentManager.cpp:3064-3143`), `Audio::SoundEffect` (`:3149-3183`), `Graphics::TextureCube` (`:3191-3226`). Declared at `ContentManager.hpp:549-567`. Four copies of the same resolution logic exist in total (the template plus these three). **VERIFIED**

**B14.** Resolution order in the generic `Load<T>()` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentManager.hpp:303-358`):
1. disposed check → `std::runtime_error` (`:306-309`)
2. cache lookup by `(typeid(T), normalizedName)` (`:315-319`)
3. `<root>/<name>.xnb` exists → `LoadXnbAsset<T>()`, **hard error on failure, never falls through** (`:328-334`)
4. per-`T` `LooseFileContentTypeReader` lookup; missing → `ContentLoadException` (`:336-342`)
5. `ResolveAssetPath()` → `reader.Read()` → cache store (`:353-357`)

`ResolveAssetPath()` (`:499-543`) then tries, in order: **literal path** (`:514`, `exists()` rather than `has_extension()` — deliberate, so `"Flag.en-US"` still gets an extension appended), **`.cnj`** (`:524-528`), each **reader-declared extension** (`:530-539`), then falls back to the bare path (`:542`). **VERIFIED**

**B15.** `.xnb` beats `.cnj` beats native, confirmed by test: `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/ContentManagerXnbTests.cpp:251-263` (`XnbWinsOverCnjAndNativeExtensionForTheSameName`) and `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/CnjResolverOrderTests.cpp` (3 cases). **VERIFIED**

**B16.** `LoadXnbAsset<T>()` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentManager.hpp:423-488`) reads the **entire file into a `std::string`** (`:426-433`) with no size cap, parses the 10-byte header, then cross-checks `header.totalLength` against actual file size (`:446-451`) — a fix for a confirmed heap-buffer-overflow (plan_xnb.md XNB-43/47). Branches: `None` → body at offset 10; `Lzx` → 4-byte decompressed size at 10, `compressedSize = totalLength - 14`, payload at 14; `Lz4` → `ContentLoadException` naming XNB-30C; `Unknown` → `ContentLoadException`. **VERIFIED**

**B17.** `XnbReadLimits::maxFileSize` (64 MB, `$CNA/modules/content/include/CNA/Internal/Xnb/XnbReadLimits.hpp:20`) is **never enforced on the whole-file read**. Its only consumer is `compressedSize` in `$CNA/modules/content/src/Xnb/XnbDecompression.cpp:19`. `LoadXnbAsset` and `ScanXnbReaderNames` both slurp arbitrarily large files. **VERIFIED** — a genuine declared-but-partially-unenforced control (the same class of defect REMED-CONTENT-006 fixed for `maxObjectNestingDepth`/`maxStringBytes`).

**B18.** `Dispose()` (`ContentManager.cpp:126-133`) calls `Unload()` and sets `disposed_`. `Unload()` (`:135-139`) is **two `.clear()` calls**, with no disposal of any cached asset — FNA's `Unload()` disposes every tracked `IDisposable` first. The disposal-tracking list does not exist: `ContentReader::RecordDisposable()` explicitly says the `ContentManager` fallback "is deferred to Phase B2 (XNB-17B)" (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentReader.hpp:451-452`). **VERIFIED**

**B19.** No thread safety anywhere. `ContentTypeReaderManager`'s registry is a function-local `static std::unordered_map` with **no mutex** (`$CNA/modules/content/src/Xna/ContentTypeReaderManager.cpp:6-11`); `ContentManager`'s caches are plain unordered_maps. Concurrent `Load` on one manager, or `AddTypeCreator` concurrent with any `Load`, is a data race. **VERIFIED**

**B20.** `Game` owns a `ContentManager` **by value** (`$CNA/modules/runtime/include/Microsoft/Xna/Framework/Game.hpp:330`), `setContentProperty` **copies** (`$CNA/modules/runtime/src/Game.cpp:167-170`), and `Game` wires the device at `:135` and disposes at `:634`. **`Game` never calls `RegisterAllBuiltInXnbReaders()`** — verified by repo-wide grep; the only non-test callers are `$CNA/tools/audio/xnb_audio_metadata_dump.cpp:61` and a doc snippet. **A real CNA game that does not call it itself cannot load any `.xnb`.** **VERIFIED**

**B21.** Content manifest (CNAEXT introspection, plan_xnb.md Phase B3): `RefreshContentManifest()` (`ContentManager.cpp:197-255`) does a `recursive_directory_iterator` scan with `skip_permission_denied` and `std::error_code` throughout, grouping by extension-stripped relative path into `ContentManifestEntry{relativePath, hasXnb, hasCnj, nativeExtensions, xnbReaderNames}` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentManifestEntry.hpp:22-45`). `GetContentManifest()` builds lazily (`:257-264`); `GetXnbReaderUsageSummary()` aggregates per reader name plus an `isRegistered` flag (`:266-290`). It is **not wired into `ResolveAssetPath()`** — explicitly stated at `ContentManager.hpp:97-103`. Output order is **unsorted** (iteration of an `unordered_map`). **VERIFIED**

**B22.** `ScanXnbReaderNames()` (`ContentManager.cpp:145-195`) returns an **empty inventory for any compressed file** (`:168-175`) — XNB-61b is the one plan row still genuinely open. Malformed files are swallowed by a bare `catch(...)` so one bad file cannot abort the scan (`:188-193`). **VERIFIED**

**B23.** `ResourceContentManager` is a pure stub: `OpenStream()` throws `std::runtime_error("...is not implemented in CNA.")` — `$CNA/modules/content/src/Xna/ResourceContentManager.cpp:13-17`. It is also a **non-virtual-dispatch dead end**: `OpenStream` is declared `virtual` on the derived class only and `ContentManager` never calls it. **VERIFIED**

---

### C. The CNJ format

**C24.** CNJ is **plain JSON, always** — no magic bytes, no binary header, no version-prefixed container. `$CNA/cnj.md:10-14` records the rename from `.cnb` precisely because the old name "misleadingly implied a binary format". `cnj.md:301-303`: *"There is no shared binary primitive layer, no 7-bit encoded integers, no shared-resource object graph — ordinary JSON object/array/number/string nesting *is* the object graph."* **VERIFIED**

**C25.** The envelope is three optional-but-checked top-level fields, parsed by `CNA::Internal::ParseCnjEnvelope` (`$CNA/modules/content/include/CNA/Internal/CnjEnvelope.hpp:68-116`): `cnjVersion` (number; kept both truncated-`int` and raw-`double` so `1.5` is rejected rather than truncated, `:25-35`), `type` (string), `sourceFile` (string, optional). Parsing **never throws**; failure is recorded in `parseErrorDetail` (`:49-54`). Validation is a separate function (`ValidateCnjEnvelopeBaseline`, `:140-176`). **VERIFIED**

**C26.** **`cnjVersion` is no longer globally 1.** `ValidateCnjEnvelopeBaseline(envelope, path, int maxVersion = 1)` — the ceiling is **per type** (`CnjEnvelope.hpp:130-135, 141, 160-169`). Only `Model` passes 2 (`$CNA/modules/content/src/Xna/ContentManager.cpp:2277`, `/*maxVersion=*/2`), for the `"bones"` hierarchy + per-mesh `"parentBone"` added by plan_gltf.md GLTF-129. Pinned by 5 tests in `$CNA/modules/content/tests/CNA/Internal/CnjEnvelopeTests.cpp` including `ARaisedCeilingDoesNotLeakToOtherTypes` and `NonIntegerVersionIsRejectedEvenInsideARaisedRange`. **VERIFIED**

**C27.** Dispatch is by the caller's compile-time `T`; `"type"` is a **cross-check**, not the key — `ValidateCnjEnvelope()` (`CnjEnvelope.hpp:196-211`) throws naming both types on mismatch. The one exception is the user-registered path (see C33). **VERIFIED**

**C28.** Eleven distinct `.cnj` `"type"` values are accepted by built-in readers. Enumerated from the `ValidateCnjEnvelope` call sites in `$CNA/modules/content/src/Xna/ContentManager.cpp`: `Texture2D` (`:497`), `TextureCube` (`:546`), `Texture3D` (`:590`), `SoundEffect` (`:672`), `SpriteFont` (`:1090`), `AnimationClip` (`:1468`), `Curve` (`:1622`), `Model` (`:2277`), plus `EffectTypeReader`'s own six-way `"type"` switch (`:806-816`): `Effect`, `BasicEffect`, `AlphaTestEffect`, `DualTextureEffect`, `EnvironmentMapEffect`, `SkinnedEffect`. **VERIFIED**

**C29.** The `sourceFile` capability matrix is **enforced in code**, not just documented. Delegating types (`Texture2D`, `TextureCube`, `SoundEffect`) require it and throw when absent (`ContentManager.cpp:499-504, 548-554, 674-680`); self-contained types call the shared `RejectSourceFileForSelfContainedCnj()` helper (`:409-419`) — used by `Texture3D` (`:591`), `Effect`/stock effects (`:818`), `SpriteFont` (`:1091`), `AnimationClip` (`:1469`), `Model` (`:2278`), `Curve` (`:1623`). Six of these are pinned by `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/CnjCapabilityMatrixTests.cpp`. **VERIFIED**

**C30.** `sourceFile` resolution is hardened by `ResolveCnjSourceFileSafely()` (`$CNA/modules/content/include/CNA/Internal/CnjSourceFile.hpp:52-138`), which rejects: empty (`:59-63`), absolute (`:65-71`), escaping the root after `weakly_canonical` **component-wise** comparison — not string prefix (`:90-107`), a target that *is* a `.cnj` (`:109-114`), and a target that *would resolve to* a sibling `.cnj` via the normal resolver, closing the self-referential cycle (`:116-125`). Six tests in `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/CnjSourceFileSafetyTests.cpp`. **VERIFIED**

**C31.** CNJ documents are parsed by **two different parsers depending on which reader you hit** — an under-documented split. Newer readers (`Texture3D` `:593`, `AnimationClip` `:1471`, `Curve` `:1625`, stock effects `:824`) use the real recursive-descent parser `CNA::Internal::ParseJson` (`$CNA/modules/content/include/CNA/Internal/Json.hpp`, 595 lines, 14 tests in `JsonTests.cpp` covering escapes, surrogate pairs, strict number grammar). Older readers still use hand-rolled substring scanners: `ExtractJsonStringField` (`ContentManager.cpp:703-719`), `JsonInt` (`:971`), `JsonBool` (`:984`), `JsonFloat` (`:998`), `JsonIntArray4` (`:1019`), `JsonFloatArray3` (`:1036`), `JsonFloatArrayN` (`:1057`), `TryParseColorKeyRGB` (`:425-444`), plus manual brace-depth object scans (SpriteFont `:1116-1152`, Model `:2414-2431`). `SpriteFont`, `Model`, `SkinnedModel`, `Texture2D`'s `colorKey`, and the custom-GLSL `Effect` branch all still run on the naive scanners. **VERIFIED**

**C32.** **The CNJ JSON parser has no recursion depth limit.** `JsonParser::ParseValue()` recurses via `ParseObject()`/`ParseArray()` (`$CNA/modules/content/include/CNA/Internal/Json.hpp:195-211, 235, 261`) with no depth counter anywhere in the file. This is asymmetric with the XNB side, which explicitly bounds both type-name nesting (`XnbTypeName.hpp:80-87`) and object nesting (`ContentReader.hpp:368-384`) after REMED-CONTENT-006. A crafted `.cnj` of `[[[[…]]]]` is a stack-exhaustion vector. There is no `.cnj` fuzz test (all fuzzing is XNB/LZX only). **VERIFIED (code), STRONG (exploitability — not empirically demonstrated here since no build was run)**

**C33.** Custom CNJ loaders: `RegisterCnjLoader<T>(typeName, CnjLoaderFn<T>)` where `CnjLoaderFn<T> = std::function<T(const std::string& cnjJson, ContentManager& cm)>` — `$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentManager.hpp:217-289`. The factory receives **raw JSON text**, not a parsed value. Registration is deterministic and fails fast: empty name or empty factory → `std::invalid_argument` (`:250-259`); a `T` that already has a reader → `std::logic_error` (`:262-271`); duplicate `(T, typeName)` → `std::logic_error`, never silent replacement (`:274-280`). The first registration for a `T` lazily installs a private `GenericCnjTypeReader<T>` (`:282-288`, defined `:367-408`) which validates the envelope baseline then dispatches on `envelope.type`. Nine tests in `CnjCustomLoaderTests.cpp`. **VERIFIED**

**C34.** **What produces `.cnj`**: `$CNA/tools/gltf_to_cnj/gltf_to_cnj.cpp` (699 lines), built unconditionally as `cna_tool_gltf_to_cnj` via `$CNA/cmake/ToolGltfToCnj.cmake:7-15`, linking only `CNA` + `SHARP_RUNTIME` + `third_party/cgltf` — **no graphics device, no window**. It is a developer tool, not part of the runtime and not gated behind `CNA_BUILD_TESTS`. There is **no XNA→CNJ exporter**; `cnj.md:557-590` describes one only as future work. **VERIFIED**

**C35.** The offline tool has been largely superseded at runtime: `ModelTypeReader::GetExtensions()` returns `{".cnj", ".gltf", ".glb"}` (`$CNA/modules/content/src/Xna/ContentManager.cpp:2250-2257`) and `.gltf`/`.glb` are parsed directly with **no sidecars at all** (`:2259-2269` → `ReadGltfModel`). The shared parsing core is `CNA::Internal::GltfImport::GltfImportCore` (`$CNA/modules/content/src/GltfImport/GltfImportCore.cpp`, 1852 lines; header 632 lines) used by **both** the CLI tool and the runtime reader. Documented runtime limitation (plan_cnj.md CNB-70): a single `Load<Model>()` imports only the file's **first** mesh group, and `unitScale` is always `1.0`. **VERIFIED (code) / STRONG (limitation, from plan text)**

**C36.** **No `.cnj` file is committed anywhere in the repository** — `find . -name "*.cnj"` outside `.git`/build dirs returns nothing. Every CNJ test writes its fixture at runtime into a temp directory. By contrast 32 `.gltf`/`.glb` fixtures are committed under `tests/`. **VERIFIED**

**C37.** CNJ also owns three binary sidecar formats read by hand: `.skeleton.bin` / `.clip.bin` (bone count + `SkeletonHierarchy` + `BindPose` + `InverseBindPose`, plus an **optional appended** `SkeletonRootPrefix` block detected purely by `Remaining() >= boneCount*64` — `$CNA/modules/content/src/Xna/ContentManager.cpp:2378-2383`), and raw vertex/index blobs. Read through a bespoke `BinReaderEXT` struct (`:1175-1189`). Bone counts are sanity-capped at 100000 (`:2353-2359`). **VERIFIED**

---

### D. XNB container

**D38.** Header is 10 bytes, parsed by `ParseXnbHeader()` (`$CNA/modules/content/include/CNA/Internal/Xnb/XnbHeader.hpp:96-157`): `'X','N','B'`, platform byte, version byte, flags byte, `int32` totalLength. Deliberate deviation from FNA documented at `:80-85` — CNA reads each magic byte through the `BinaryReader`, so a truncated file throws `EndOfStreamException` rather than failing a magic comparison against garbage. **VERIFIED**

**D39.** Exactly 16 platform bytes accepted, FNA-exact: `w x m i a d X W n u p M r P g l` (`XnbHeader.hpp:63-70`). MonoGame's post-fork identifiers (`b`, `5`, `O`, `S`, `V`) are **deliberately rejected**, pinned by `$CNA/modules/content/tests/CNA/Internal/Xnb/XnbHeaderTests.cpp` `MonoGameWebAssemblyPlatformIsNotAcceptedMatchingFnaExactly`. **VERIFIED**

**D40.** Version must be 4 or 5 (`XnbHeader.hpp:128-133`). **VERIFIED**

**D41.** Compression is a real 4-valued enum, not a bool: `XnbCompression{None, Lzx, Lz4, Unknown}` (`XnbHeader.hpp:23-33`), decoded from bits `0x80` (Lzx) and `0x40` (Lz4) at `:135-153`; **both bits set → `Unknown`**, rejected rather than guessed. Both bit values are documented as confirmed against MonoGame's own `ContentManager.cs`, not inferred. **VERIFIED**

**D42.** **LZX is fully implemented; LZ4 is not.** `$CNA/modules/content/src/Xnb/LzxDecoder.cpp` (680 lines) is a line-by-line port of FNA's `LzxDecoder.cs` preserving FNA's variable names, control flow and error-as-return-code style (`$CNA/modules/content/include/CNA/Internal/Xnb/LzxDecoder.hpp:10-18`). Window exponent must be 15–21 or `UnsupportedLzxWindowSizeRange` is thrown (`:21-26`); `.xnb` always uses 16. One decoder instance per file — state (sliding window, repeated-offset LRU, Huffman tables) persists across blocks (`:29-36`). LZ4 throws a named `ContentLoadException` citing XNB-30C (`ContentManager.hpp:479-482`). **VERIFIED**

**D43.** `DecompressXnbPayload()` (`$CNA/modules/content/src/Xnb/XnbDecompression.cpp:12-87`) validates `compressedSize` against `maxFileSize` and `decompressedSize` against `maxDecompressedSize` **before allocating** (`:19-30`), walks the block framing (2-byte big-endian block size; `0xFF` sentinel → 5-byte extended form with explicit frame size, `:47-64`), and **verifies the final output length exactly matches the declared decompressed size** (`:81-84`). **VERIFIED**

**D44.** Type-reader table parsing: `ParseXnbTypeReaderTable()` (`$CNA/modules/content/include/CNA/Internal/Xnb/XnbTypeReaderTable.hpp:49-96`) reads a 7-bit-encoded count (bounded by `maxTypeReaderCount = 4096`), then per entry a length-prefixed string (post-hoc bounded by `maxStringBytes = 1 MB`, `:75-80` — the comment at `:70-74` is candid that `BinaryReader::ReadString()` has no way to take a cap), a normalized name, and an `int32` version. `std::invalid_argument` from the name parser is caught and re-thrown as `ContentLoadException` so callers only ever need one exception type (`:81-90`). Entry struct keeps **both** `rawName` and `normalizedName` (`:18-28`). **VERIFIED**

**D45.** Type-name normalization is a real recursive parser, not a `substr(0, find(','))`: `XnbTypeName::ParseOne()` (`$CNA/modules/content/include/CNA/Internal/Xnb/XnbTypeName.hpp:80-152`) handles nested generic argument brackets by bracket-depth matching and strips assembly/version/culture/publicKeyToken. `ToCanonicalString()` (`:36-54`) rebuilds `Base[[arg1],[arg2]]`. **Depth-bounded** by `maxObjectNestingDepth` (`:80-87`) — the fix for REMED-CONTENT-006, whose comment records that "a crafted type name costs ~4 bytes per nesting level, so a sub-1MB file previously exhausted the C++ call stack; confirmed empirically". 11 tests in `XnbTypeNameTests.cpp`. **VERIFIED**

---

### E. Type-reader architecture

**E46.** `ContentTypeReaderBase` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentTypeReader.hpp:37-93`) is the forced rename of FNA's non-generic `ContentTypeReader`; `ContentTypeReader<T>` (`:104-162`) keeps the real XNA name because that is what a ported reader subclasses. `TargetType` is a **canonical name string**, not a `Type` object — CNA has no reflection (`:29-35`). **VERIFIED**

**E47.** `ReadUntyped()` boxes through `std::any`, with an `if constexpr` split: a **move-only `T` is boxed as `std::shared_ptr<T>`** because `std::any` requires `CopyConstructible` (`ContentTypeReader.hpp:143-161`), unwrapped symmetrically in `ContentReader::InnerReadObject` (`ContentReader.hpp:428-437`). **VERIFIED**

**E48.** `existingInstance` is `std::optional<T>`, not FNA's bare `T` — documented rationale at `ContentTypeReader.hpp:112-124`: C#'s `default(T)` is free for a reference type but real construction for a value type, and `SpriteFont` has no default constructor. **VERIFIED**

**E49.** Reader-version enforcement is a **CNAEXT addition FNA does not have**: `SupportsVersion(int)` defaults to exact equality against `getTypeVersionProperty()` (`ContentTypeReader.hpp:51-64`), enforced in `ContentReader::InitializeTypeReaders()` (`$CNA/modules/content/src/Xna/ContentReader.cpp:227-232`). **No reader anywhere overrides either method** — grep across `modules/content` returns only the base definitions and the one call site. So every reader's `TypeVersion` is 0 and **any `.xnb` declaring a nonzero reader version is rejected**. Test: `ContentReaderTest.ReaderVersionMismatchThrowsContentLoadException`. **VERIFIED**

**E50.** `getCanDeserializeIntoExistingObjectProperty()` is declared (`ContentTypeReader.hpp:43`) and overridden to `true` by `ListReader` (`CollectionContentTypeReaders.hpp:143`) and `DictionaryReader` (`:197`) — but **`ContentReader` never reads it**. Grep across `ContentReader.hpp`/`.cpp` shows zero consultations. In FNA this property gates whether `existingInstance` is passed down; in CNA it is inert metadata. **VERIFIED**

**E51.** `ContentTypeReaderManager` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentTypeReaderManager.hpp:28-73`) is a **process-wide static registry** of `std::function<std::unique_ptr<ContentTypeReaderBase>()>` factories. FNA uses this dictionary only as an AOT reflection fallback; in CNA it is the sole mechanism (`:20-26`). `AddTypeCreator` **silently ignores** a repeat registration of the same key (`ContentTypeReaderManager.cpp:16-19`), matching FNA. `CreateReader` returns a **fresh instance per call** — one per file, never shared. `ClearTypeCreators()` exists primarily for test isolation. **VERIFIED**

**E52.** `ContentReader` extends `System::IO::BinaryReader` and is a **one-shot session over one file's object graph**, constructed with `(manager, stream, assetName, version, platform, recordDisposableFn, limits)` — `$CNA/modules/content/include/Microsoft/Xna/Framework/Content/ContentReader.hpp:79-86`. `manager` **may be null** (`:50-53`), unlike real XNA. `ReadAsset<T>()` is the single entry point: `InitializeTypeReaders(); ReadObject<T>(); ReadSharedResources();` (`:253-260`). **VERIFIED**

**E53.** Root/nested dispatch is the correct **1-based type-reader index** via `Read7BitEncodedInt()`; index 0 means null (`ContentReader.hpp:386-407`). For a null with no default constructor and no existing instance, CNA throws `ContentLoadException` where FNA would return `default(T)` — a documented, unavoidable C++ deviation (`:392-406`). Out-of-range index → `ContentLoadException` (`:408-412`). **VERIFIED**

**E54.** Object-graph recursion is bounded by an RAII `ObjectDepthGuard` against `maxObjectNestingDepth = 256` (`ContentReader.hpp:361-384`) — REMED-CONTENT-006's second half, decrementing on every exit path including exceptions. Tests: `ObjectNestingDepthExceedingLimitThrowsContentLoadException` and `…AtLimitDoesNotThrow`. **VERIFIED**

**E55.** Shared resources are correctly two-pass: `ReadSharedResource<T>(fixup)` queues a lambda against a 1-based index (0 = no reference), range-checked (`ContentReader.hpp:232-246`); `ReadSharedResources()` reads **every** resource first, then runs all fixups (`$CNA/modules/content/src/Xna/ContentReader.cpp:272-289`), matching FNA's own "read all objects first, BEFORE doing fixups". Count bounded by `maxSharedResourceCount = 1,000,000` (`:246-251`). **VERIFIED**

**E56.** `ReadObject` has five forms plus `ReadRawObject` in two (`ContentReader.hpp:157-219`), matching FNA's surface. There is a **non-template `std::any ReadObject()`** for `Tag`-style untyped fields (`:177-180` → `InnerReadObjectAny()` at `ContentReader.cpp:256-270`); it deliberately does **not** call `RecordDisposable()` (`:345-353`). **VERIFIED**

**E57.** `ReadExternalReference<T>()` returns `std::optional<T>` rather than FNA's bare `T`, because CNA's asset types are value types with no uniform null (`ContentReader.hpp:120-155`). It is **explicitly instantiated for exactly two types**: `Texture2D` and `TextureCube` (`$CNA/modules/content/src/Xna/ContentReader.cpp:91-92`). Anything else fails to link. **VERIFIED**

**E58.** External-reference path hardening (no FNA equivalent — FNA "just lets the OS fail"): `ResolveRelativeAssetPath()` (`ContentReader.cpp:26-70`) rejects an absolute/drive-letter/UNC reference via `IsDisallowedAbsolutePath` (`:51-56`) and rejects a resolution that climbs above the content root (`:62-68`), while deliberately **allowing** legitimate `..` siblings. The comment at `:38-50` records that the absolute case was previously unenforced despite the doc claiming otherwise (REMED-CONTENT-002). Five tests in `ContentReaderExternalReferenceTests.cpp`. **VERIFIED**

**E59.** `LooseFileContentTypeReader<T>` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/LooseFileContentTypeReader.hpp:27-53`) is a **completely separate, CNA-original interface** — `Read(const std::string& path, ContentManager&)` + `GetExtensions()`. It was renamed out of `ContentTypeReader<T>` on 2026-07-16 (`:18-25`) to free that name for the real XNA class. Registered per-`T` on a **per-instance** map (`ContentManager::RegisterTypeReader<T>`, `ContentManager.hpp:203-208`), in contrast to the process-wide XNB registry. **VERIFIED** — this two-registry split is the single most confusable thing in the whole subsystem.

---

### F. Custom user readers

**F60.** There are **two independent extension points**, both real at this SHA:
- `.xnb`: `ContentTypeReaderManager::AddTypeCreator(canonicalName, factory)` — public/`CNAEXT`, generic over any `ContentTypeReader<T>` subclass defined entirely outside CNA. End-to-end proof in `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/CustomContentTypeReaderTests.cpp:133-147`: a test-local `GameLevelData`/`GameLevelDataReader` loaded through `cm.Load<GameLevelData>("level1")` from a hand-built `.xnb`. Nothing about that type exists in CNA. **VERIFIED**
- `.cnj`: `ContentManager::RegisterCnjLoader<T>` (see C33). **VERIFIED**

**F61.** `ReflectiveReader<T>` is **not supported, by design** — a `.xnb` compiled with XNA's implicit reflection fallback cannot be loaded at all. Documented decision at `$CNA/docs/xnb-content-pipeline-support.md:122-133`; the workaround is to rebuild with an explicit `ContentTypeWriter` pair. No code path exists. **VERIFIED**

**F62.** The general `EffectReader` (compiled platform shader bytecode) is registered as a **deliberate poison pill**: `KnownUnsupportedContentTypeReader` whose `ReadUntyped` always throws naming the target type and a structured `UnsupportedContentReaderReason::CompiledPlatformShaderBytecode` (`$CNA/modules/content/include/Microsoft/Xna/Framework/Content/KnownUnsupportedContentTypeReader.hpp:19-52`; registered `$CNA/modules/content/src/Xna/KnownUnsupportedContentTypeReader.cpp:38-47`). This buys a precise error instead of "unknown reader". **VERIFIED**

---

### G. Robustness / security

**G63.** `XnbReadLimits` (`$CNA/modules/content/include/CNA/Internal/Xnb/XnbReadLimits.hpp:17-39`), with **verified enforcement sites**:

| Limit | Value | Enforced at | Status |
|---|---|---|---|
| `maxFileSize` | 64 MiB | `XnbDecompression.cpp:19` (compressed payload only) | **partially unenforced** — whole-file read is uncapped (B17) |
| `maxDecompressedSize` | 256 MiB | `XnbDecompression.cpp:25`; `ContentReader.cpp:186` (`CheckDecodedByteSize`) | enforced |
| `maxStringBytes` | 1 MiB | `XnbTypeReaderTable.hpp:75` | enforced (post-read) |
| `maxTypeReaderCount` | 4096 | `XnbTypeReaderTable.hpp:57` | enforced |
| `maxSharedResourceCount` | 1,000,000 | `ContentReader.cpp:246` | enforced |
| `maxCollectionElementCount` | 10,000,000 | `ContentReader.cpp:176` (`CheckCollectionElementCount`) | enforced |
| `maxObjectNestingDepth` | 256 | `ContentReader.hpp:378`; `XnbTypeName.hpp:82` | enforced |

**VERIFIED**

**G64.** `ReadBytesExactOrThrow()` (`$CNA/modules/content/src/Xna/ContentReader.cpp:194-210`) exists because `BinaryReader::ReadBytes(int)` **silently trims** on a truncated stream (matching .NET), and callers were then passing the *original declared* count to raw pointer+count APIs — a confirmed heap-buffer-overflow. Now used by every declared-length blob read: Texture2D (`Texture2DContentTypeReader.cpp:178`), TextureCube (`TextureCubeContentTypeReader.cpp:80`), Texture3D, VertexBuffer (`ModelContentTypeReaders.cpp:148-149`), IndexBuffer (`:166`), SoundEffect (`SoundEffectContentTypeReader.cpp:235, 253, 257`). **VERIFIED**

**G65.** `CheckedMultiplyOrThrow()` (`$CNA/modules/content/include/CNA/Internal/Xnb/XnbArithmetic.hpp:38-59`) division-checks each multiplication before performing it. The header comment (`:18-31`) records REMED-CONTENT-009: widening to `int64_t` was **insufficient** — two near-`INT32_MAX` dimensions times 4 overflows `int64_t` itself, confirmed by UBSan. Used by all three texture readers. 11 tests in `XnbArithmeticTests.cpp` including `ProductExactlyAtInt64MaxDoesNotThrow` / `ProductOneOverInt64MaxThrows`. **VERIFIED**

**G66.** `Texture2DReader` carries the deepest input-admission checks in the codebase (`$CNA/modules/content/src/Xnb/Texture2DContentTypeReader.cpp:99-169`): individual positivity of width/height (two negatives would otherwise multiply to a small positive), checked byte size, **device max-texture-dimension query** (`:133-139`), a computed max mip-level ceiling (`:140-147`), and rejection of a *partial* mip prefix — only level-0-only or the complete chain is accepted, so content loading "never fabricates absent mip data" (`:148-158`). The comment at `:126-132` records that neither Vulkan's validation layer nor wgpu's lazy validation caught these; the fuzzer produced **real process crashes** (Vulkan stack smashing, a non-catchable WebGPU panic) before the fix. **VERIFIED**

**G67.** Compressed-level byte counts are validated against the DXT block-rounded expectation before decompression (`Texture2DContentTypeReader.cpp:185-194`), and uncompressed levels against `pixelCount*4` after (`:222-229`). `TextureCubeReader` carries the ported-verbatim equivalent (`TextureCubeContentTypeReader.cpp:105-118`). **VERIFIED**

**G68.** **Three fuzz/property harnesses, all deterministic (fixed LCG seed, no `std::random_device`)**:
- `$CNA/modules/content/tests/CNA/Internal/Xnb/XnbContainerFuzzTests.cpp` — whole-container mutation (bit flip / truncate / overwrite / **insert**, the last shifting every later field's alignment) of three real fixtures, loaded through the real `ContentManager::Load<T>()`, **1500 iterations each** for Model / Texture2D / SoundEffect. Asserts every outcome is success or one of an enumerated set of clean exceptions; `std::bad_alloc` is an explicit **`ADD_FAILURE`** as "an allocation-bomb guard gap, not an acceptable outcome" (`:178-183`).
- `$CNA/modules/content/tests/CNA/Internal/Xnb/LzxDecoderFuzzTests.cpp` — 2000 iterations over two real LZX payloads, also corrupting the decompressed-size hint; successful decompressions must still produce exactly the declared size (`:135`).
- `$CNA/modules/content/tests/CNA/Internal/Xnb/SoundEffectContentTypeReaderPropertyTests.cpp` — WAVEFORMATEX boundary-value sweep.

All documented as also run under `-DCNA_SANITIZE=address,undefined`. **VERIFIED**

**G69.** `$CNA/modules/content/tests/CNA/Internal/Xnb/LzxDecoderDifferentialTests.cpp` compares CNA's LZX output **byte-for-byte against FNA's unmodified `LzxDecoder.cs` run under Mono**, with the reference bytes vendored at `$CNA/tests/assets/xnb/monogame/windows/lzx/reference-decompressed/`. This is a genuine cross-implementation oracle, not a self-consistency check. It found a real heap-buffer-overflow in `MakeDecodeTable()`'s long-code table-growth path. **VERIFIED**

**G70.** Path containment is a **shared, tested primitive**, `$CNA/modules/core/include/CNA/Internal/PathContainment.hpp`: `IsDisallowedAbsolutePath` (POSIX absolute + Windows drive-letter + UNC, `:24-36`), `ValidateContainedPath` (component-wise `lexically_relative` after optional `weakly_canonical`, explicitly *not* a string prefix so `content-evil` is not a child of `content`, `:66-102`), `ResolveContainedPathFromBase`, `ResolveContainedPath`, and `ResolveContainedPathRelativeToFile`. The last encodes the **"explicit external bundle"** rule (`:190-234`): a referring file lexically inside the content root is confined to that root; a referring file loaded through an explicit outside-root API is confined instead to its own directory. **VERIFIED**

**G71.** `$CNA/modules/content/tests/Microsoft/Xna/Framework/Content/ContentPathContainmentTests.cpp` (951 lines, **18 tests**) is the single largest security test file in the module. It covers deep traversal, absolute paths, Unicode-encoded traversal, **existing-symlink escapes**, and — importantly — asserts rejection happens **before file creation/read** and **does not poison the cache** (test names `…RejectsBeforeCreationAndDoesNotPoisonCache`). It also pins the legitimate cases: `ExplicitExternalSongXnbRemainsConfinedAndLoadable`, `ModelNormalizedInRootBinaryFieldsStillLoad`. **VERIFIED**

**G72.** Real boundaries, stated without inflation: symlink checking is **not** race-proof (TOCTOU is not claimed to be closed); `.` segments, repeated separators, and `..` that normalizes back inside the root are all accepted by design; `ContentManager::Load()` with an absolute asset name is permitted by contract (B9). Path containment governs **file-internal references** (`sourceFile`, sidecar fields, `ReadExternalReference`, embedded Song/Video media paths) — not the caller's own argument. **VERIFIED**

**G73.** The `.cnj` side is materially less hardened than the `.xnb` side: no depth limit (C32), no size limit (`ReadTextFile` at `ContentManager.cpp:691-701` slurps whole files), no fuzzing, and the legacy substring scanners (C31) use `std::stoi`/`std::stof` on unbounded substrings inside loops. The scanners are **not** memory-unsafe (they bound-check `pos < json.size()`), but they will silently accept malformed JSON that the real parser rejects, and `SpriteFont`'s glyph loop (`:1123-1150`) terminates only on running out of `{` — so a truncated document yields a partial font rather than an error. **STRONG**

---

### H. Test evidence

**H74.** 41 test files in `$CNA/modules/content/tests/`, split `CNA/Internal/Xnb/` (18 files), `CNA/Internal/GltfImport/` (11), `Microsoft/Xna/Framework/Content/` (20), plus `JsonTests.cpp` and `CnjEnvelopeTests.cpp`. Roughly 350 test cases. **VERIFIED**

**H75.** The real `.xnb` fixture corpus is **30 files, 568 KB**, all externally produced, each with a `.manifest.json` recording producer and expected fields (`$CNA/tests/assets/xnb/monogame/windows/`):
- `uncompressed/`: `white-1.xnb` (Texture2D), `Default.xnb` (SpriteFont), `SampleCube64DXT1Mips.xnb` (TextureCube, all 6 faces + full DXT1 mip chain), `BlenderDefaultCube.xnb` (Model + VertexBuffer/IndexBuffer/BasicEffect)
- `uncompressed/audio/`: six SoundEffect fixtures — `tone_mono_44khz_{16bit,8bit,float,imaadpcm,msadpcm}`, `tone_stereo_44khz_16bit`
- `uncompressed/song/`: `one_two_three.xnb` + the real `one_two_three.ogg` it references
- `lzx/`: `Explosion.xnb`, `FontCalibri14.xnb` + two vendored FNA-decompressed reference blobs + a reproduction README

**VERIFIED**

**H76.** Synthetic fixtures are built **in-test** for everything with no real-world source: `CustomContentTypeReaderTests.cpp:95-123` (`BuildGameLevelXnbFile`), `ContentManagerXnbTests.cpp` (`BuildTestXnbFile`, and hand-laid 10-byte headers for the malformed cases at `:172, 184, 196, 241`), `ContentManagerManifestTests.cpp:203` (`BuildXnbFile`), and the hand-constructed field streams in `StockEffectContentTypeReaderTests.cpp` / `Texture3DTextureCubeContentTypeReaderTests.cpp`. `$CNA/tests/fixtures/` holds only 7 files, 36 KB, all Direct2D — nothing content-related. **VERIFIED**

**H77.** 32 committed `.gltf`/`.glb` fixtures under `tests/`, driven by a Python corpus generator at `$CNA/tools/gltf_fixtures/` (`corpus.py`, `manifest.py`, `l5.py`, `defs/`). `builder.py` is **git-ignored** by the repo-wide `build*` pattern (`$CNA/.gitignore:1`) — an accidental exclusion, since it is a source file, not a build directory. **VERIFIED**

**H78.** The glTF test suite is organized as a **five-layer conformance ladder** (`GltfConformanceL1`…`L5` — container structure → decoded accessors → semantic mesh streams → expected world positions → golden bytes) with two dedicated differential oracles (`GltfOracleEXT.cpp`, `GltfBufferOracleEXT.cpp`, 999 lines combined) that attribute a one-byte buffer difference to the exact vertex and field that owns it. `GltfKnownDefectTests.cpp` pins **open defects as executable tests**, including a meta-test `EveryOpenDefectInTheCorpusLedgerHasAnExecutableTestHere`. **VERIFIED** — this is a notably more rigorous verification architecture than anything on the XNB side, and the book does not describe it at all.

**H79.** End-to-end "fresh ContentManager loads a real fixture with no other setup" is pinned for six types: Texture2D, TextureCube, Model, SpriteFont, SoundEffect, Song (`$CNA/modules/content/tests/CNA/Internal/Xnb/XnbBuiltInReaderRegistrationTests.cpp:139-…`). LZX end-to-end is pinned for Texture2D and SpriteFont (`ContentManagerTexture2DXnbTests.cpp`, `ContentManagerSpriteFontXnbTests.cpp`). **VERIFIED**

**H80.** `XnbBuiltInReaderRegistrationTests.cpp:105` asserts `DecimalReader` is registered **unconditionally**, but its registration is guarded by `#if SHARP_RUNTIME_HAS_NATIVE_INT128` (`$CNA/modules/content/src/Xnb/DecimalDateTimeContentTypeReaders.cpp:12-15`). On a platform without native `__int128`, this test fails. **PROBABLE** (build not run; the code asymmetry is verified).

---

## READER TABLE

Every concrete `.xnb` `ContentTypeReader` at this SHA. Canonical names are the exact registry keys. "Test" cites `$CNA/modules/content/tests/`.

### Primitives — `$CNA/modules/content/src/Xnb/PrimitiveContentTypeReaders.cpp:12-36`

| Reader | Status | Evidence |
|---|---|---|
| `BooleanReader`, `ByteReader`, `SByteReader`, `Int16Reader`, `UInt16Reader`, `Int32Reader`, `UInt32Reader`, `Int64Reader`, `UInt64Reader`, `SingleReader`, `DoubleReader` | **Implemented** | thin `BinaryReader` delegates, `PrimitiveContentTypeReaders.hpp`; 11 round-trip tests, `PrimitiveAndMathContentTypeReaderTests.cpp` |
| `CharReader` → `char16_t` | **Implemented** | `PrimitiveContentTypeReaders.hpp:112-118`; `CharReaderRoundTrips` |
| `StringReader` → `std::string` | **Implemented** | `:120-126`; `StringReaderRoundTrips` |

### Math — `$CNA/modules/content/src/Xnb/MathContentTypeReaders.cpp:12-39`

| Reader | Status | Evidence |
|---|---|---|
| `Vector2Reader`, `Vector3Reader`, `Vector4Reader`, `MatrixReader`, `QuaternionReader`, `ColorReader` | **Implemented** | `MathContentTypeReaders.hpp:30-75`, delegating to `ContentReader::ReadVector*/ReadMatrix/ReadQuaternion/ReadColor` (`ContentReader.cpp:112-165`); field order pinned by `ContentReaderTest.MathReadHelpersReadFieldsInFnaOrder` |
| `PlaneReader` | **Implemented** | `MathContentTypeReaders.hpp:77-88`; `PlaneReaderRoundTrips` |
| `PointReader`, `RectangleReader` | **Implemented** | round-trip tests |
| `BoundingBoxReader`, `BoundingSphereReader` | **Implemented** | `ContentReader::ReadBoundingSphere` at `ContentReader.cpp:167-172`; round-trip tests |
| `BoundingFrustumReader` | **Implemented** | `MathContentTypeReaders.hpp:143-152` — reads one `Matrix`, constructs `BoundingFrustum(matrix)`. **Registered and tested for registration only** (`RegistersEveryMathReader`); no round-trip value test exists |
| `RayReader` | **Implemented** | `:154-165`; `RayReaderRoundTrips` |

### Calendar / decimal — `$CNA/modules/content/src/Xnb/DecimalDateTimeContentTypeReaders.cpp:10-21`

| Reader | Status | Evidence |
|---|---|---|
| `DecimalReader` | **Implemented, conditionally registered** — `#if SHARP_RUNTIME_HAS_NATIVE_INT128` (`:12-15`) | `DecimalReaderRoundTrips`; see H80 |
| `TimeSpanReader` | **Implemented** | plain `int64` ticks; `TimeSpanReaderRoundTrips` |
| `DateTimeReader` | **Partial** — ticks decoded correctly, **`DateTimeKind` parsed then discarded** (`System::DateTime` cannot store it) | `DateTimeReaderExtractsTicksMaskingOutKindBits`; documented deviation, plan_xnb.md XNB-18C |

### Collections — `$CNA/modules/content/include/CNA/Internal/Xnb/CollectionContentTypeReaders.hpp` (templates)

| Reader | Status | Evidence |
|---|---|---|
| `ArrayReader<T>` → `std::vector<T>` | **Implemented as a template; NOT registered generically** | `:73-122`. Reads `uint32` count, bounds-checks, **resizes** a mismatched `existingInstance` (deliberate FNA deviation, `:66-71`). `shared_ptr`-shaped `T` uses per-element polymorphic dispatch; otherwise a fixed element reader created by canonical name. Tests: `ArrayReaderReadsElementsViaExplicitElementReader`, `…RejectsAnAdversarialElementCountBeforeAllocating` |
| `ListReader<T>` → `std::vector<T>` | **Implemented as a template** | `:133-173`. Reads `int32` count; **appends without clearing** `existingInstance`, faithfully matching FNA's surprising `list.Add()` loop (`:128-131`). Test `ListReaderAppendsToExistingInstanceWithoutClearing` |
| `DictionaryReader<K,V>` → `std::unordered_map` | **Implemented as a template** | `:184-231`. **Clears** `existingInstance` first (opposite of `ListReader`, matching FNA). Test `DictionaryReaderClearsExistingInstanceThenRepopulates` |
| `NullableReader<T>` → `std::optional<T>` | **Implemented as a template** | `:238-261`; 2 tests |
| **Any closed generic instantiation** | **Only 3 exist** | `ListReader<Rectangle>`, `ListReader<char16_t>`, `ListReader<Vector3>` — registered by `SpriteFontContentTypeReader.cpp:57-77` because `SpriteFontReader` needs exactly those. **No `ArrayReader`, `DictionaryReader`, or `NullableReader` instantiation is registered anywhere.** Design note at `CollectionContentTypeReaders.hpp:16-33`: CNA has no reflection to resolve `typeof(T)`, so each closed combination must be hand-registered. Element readers are constructed fresh via `CreateReader()` in the constructor rather than looked up from the file's own table via `Initialize()` — valid only because every CNA reader is stateless (`:26-30`) |
| `EnumReader<T>` | **MISSING** | No such class anywhere; repo-wide grep is empty. The book's Ch. 8 §"no enum fallback" is still correct |
| `ReflectiveReader<T>` | **MISSING, by design** | `$CNA/docs/xnb-content-pipeline-support.md:122-133` |
| `ExternalReferenceReader` | **MISSING as a reader class** | The *mechanism* exists as `ContentReader::ReadExternalReference<T>()` (E57), instantiated for `Texture2D`/`TextureCube` only |

### Graphics

| Reader | Status | Evidence |
|---|---|---|
| `Texture2DReader` | **Partial (format-limited)** — `Color`, `Dxt1`, `Dxt3`, `Dxt5` only; DXT is **always** software-decompressed to `Color`; any other `SurfaceFormat` throws (`Texture2DContentTypeReader.cpp:108-114`). Legacy XNA pre-4.0 format ordinals mapped for container version < 5 (`:27-45`). Level-0-only or full mip chain, never a prefix | Real fixture `white-1.xnb`; LZX fixture; 9 tests in `Texture2DContentTypeReaderTests.cpp`; 1500-iteration fuzz |
| `Texture3DReader` | **Partial** — same format scope. Returns `std::shared_ptr<Texture3D>` (type is move-only) | **No real fixture exists anywhere**; verified against a hand-constructed stream field-by-field against FNA's `Texture3DReader.cs`. 5 tests |
| `TextureCubeReader` | **Partial** — same format scope; 6 faces × mip chain, per-level byte-count validation (`TextureCubeContentTypeReader.cpp:105-118`) | Real fixture `SampleCube64DXT1Mips.xnb` incl. sub-4×4 block-rounding; 5 tests |
| `SpriteFontReader` | **Implemented**; `existingInstance` path deliberately **not** ported — throws `System::NotImplementedException` because `CanDeserializeIntoExistingObject` is false so the path is unreachable (`SpriteFontContentTypeReader.cpp:22-32`) | Real fixtures `Default.xnb` (uncompressed) + `FontCalibri14.xnb` (LZX); 3 unit + 2 end-to-end tests. **Does not validate its parallel glyph/cropping/kerning table lengths against each other** — verified by reading `:34-48` |
| `VertexDeclarationReader` | **Implemented**; element count capped at 1024 (`ModelContentTypeReaders.cpp:101-105`) | via Model fixture |
| `VertexBufferReader` | **Implemented**; `int64` widening + explicit overflow rejection on `vertexCount * stride` (`:143-147`) | via Model fixture + fuzz |
| `IndexBufferReader` | **Implemented**; 16/32-bit | via Model fixture |
| `ModelReader` | **Implemented** — full bone hierarchy with FNA's 8-bit/32-bit `ReadBoneReference` encoding (`:62-70`), mesh/part graph, `BoundingSphere`, and all three `ReadSharedResource` slots (VertexBuffer/IndexBuffer/Effect) with an owned-resource keepalive (`:85-93, 285-304`). **Rejects non-null `Tag` values** rather than dropping them (`:46-57`). Reload into an existing `Model` throws (`:190-201`) | Real fixture `BlenderDefaultCube.xnb`; `LoadRealMonoGameFixtureEndToEnd`; 1500-iteration fuzz |
| `BasicEffectReader` | **Implemented**; texture via `ReadExternalReference<Texture2D>`, then diffuse/emissive/specular/specularPower/alpha/vertexColorEnabled (`StockEffectContentTypeReaders.cpp:34-54`) | **`BasicEffectReaderParsesRealFnaProducedBytes`** — the only stock effect with real-asset evidence |
| `AlphaTestEffectReader` | **Implemented** | hand-constructed bytes only |
| `DualTextureEffectReader` | **Implemented**; two `Texture2D` external refs | hand-constructed bytes only |
| `EnvironmentMapEffectReader` | **Implemented**; `Texture2D` + `TextureCube` external refs | hand-constructed bytes only |
| `SkinnedEffectReader` | **Implemented** | hand-constructed bytes only |
| **All 5 stock effects** | target `std::shared_ptr<Effect>`, **not** the concrete type — required because `std::any_cast` needs exact type match and `ModelReader`'s `ReadSharedResource<shared_ptr<Effect>>` cannot know which concrete type a file used (`StockEffectContentTypeReaders.hpp:28-36`) | design note verified |
| general `EffectReader` | **Deliberately unsupported** — `KnownUnsupportedContentTypeReader` always throws with a structured reason | `KnownUnsupportedContentTypeReaderTests.cpp` |
| `EffectMaterialReader` | **MISSING** | not registered anywhere |
| `Texture` base reader | **MISSING** | not registered |

### Audio / media

| Reader | Status | Evidence |
|---|---|---|
| `SoundEffectReader` | **Substantially widened since the docs**: 16-bit PCM direct fast path; **8-bit PCM, 32-bit IEEE float, MS-ADPCM, IMA-ADPCM** all supported via synthesizing an in-memory WAV and routing through SDL3's decoder (`SoundEffectContentTypeReader.cpp:280-301`). MS-ADPCM gets a **synthesized coefficient table** because real XNB writes `cbSize=0` and SDL3's MS-ADPCM decoder requires one — verified against a real fixture by hex dump (`:44-58`). XMA2's 34-byte extension is parsed for stream positioning then **rejected** (`:212-236, 307-313`). Channels restricted to 1 or 2 (`:266-271`). Xbox (`'x'`) byte-swap ported verbatim though unreachable (`:21-36`). Uses the file's own stored duration as a **validation oracle**, rejecting a >2×/<0.5× disagreement (`:86-103`) | 6 real audio fixtures covering every supported format; **26 tests** in `SoundEffectContentTypeReaderTests.cpp` (1105 lines) + a property sweep + 1500-iteration fuzz. The richest single-reader test surface in the module |
| `SongReader` | **Implemented** — external file reference with FNA's `Normalize()` extension probing (`.ogg`/`.oga`/`.qoa`), path-containment-checked **twice**: on the embedded spelling and again on the extension-probed selection, so a probe cannot land on an outside symlink (`SongContentTypeReader.cpp:88-93`) | Real fixture `one_two_three.xnb` + `.ogg`; 3 unit + 2 end-to-end tests; 4 containment tests |
| `VideoReader` | **Implemented but platform-conditional** — excluded from the build without FFmpeg (A3). Same double-containment pattern (`VideoContentTypeReader.cpp:92-97`) | **No real MonoGame Video fixture obtainable**; 5 tests + 1 end-to-end on a synthesized file |

**Registered reader count**: 50 canonical names when FFmpeg and native `__int128` are both available (13 primitive + 13 math + 3 decimal/date + Curve + Texture2D + Texture3D + TextureCube + SpriteFont + 3 `ListReader` + SoundEffect + Song + Video + 5 stock effects + 4 model + the `EffectReader` poison pill). `RegisterAllBuiltInXnbReaders()` (`$CNA/modules/content/src/Xnb/XnbBuiltInReaders.cpp:22-44`) is the single call site; it is **idempotent** and **deliberately not auto-invoked** from the `ContentManager` constructor, because doing so would defeat the `ClearTypeCreators()`-based isolation many tests rely on (`XnbBuiltInReaders.hpp:12-16`).

### `.cnj` loose-file readers (`LooseFileContentTypeReader<T>`, all in `$CNA/modules/content/src/Xna/ContentManager.cpp`)

| Reader | `T` | Extensions | Line |
|---|---|---|---|
| `Texture2DTypeReader` | `Texture2D` | `.png .jpg .jpeg .bmp .gif .tga .tif .tiff .qoi` (+ `.cnj` via resolver) | `:472-519` |
| `TextureCubeTypeReader` | `TextureCube` | `.dds` (+`.cnj`) | `:521-561` |
| `Texture3DTypeReader` | `shared_ptr<Texture3D>` | `.cnj` only | `:571-647` |
| `SoundEffectTypeReader` | `SoundEffect` | `.wav` (+`.cnj`) | `:649-687` |
| `EffectTypeReader` | `shared_ptr<Effect>` | `.cnj` only; 6-way `"type"` dispatch | `:778-965` |
| `SpriteFontTypeReader` | `SpriteFont` | `.cnj` only | `:1074-1164` |
| `AnimationClipTypeReader` | `AnimationClipEXT` | `.cnj` only; exactly one of `"clipFile"`/`"tracks"` | `:1452-1575` |
| `CurveTypeReader` | `Curve` | `.cnj` only | `:1604-1705` |
| `ModelTypeReader` | `Model` | `.cnj .gltf .glb` | `:2247-…` |
| `SkinnedModelTypeReader` | `shared_ptr<SkinnedModelEXT>` | `.skinnedmodel.json` — **deliberately never migrated to `.cnj`** | `:2825-…` |
| `SongTypeReader` | `Song` | `.mp3 .ogg .wav .flac .opus .aac .wma` | `:2996-3010` |
| `VideoTypeReader` | `Video` | `.mp4 .ogv .webm .mkv .avi .mov` (FFmpeg only) | `:3013-3025` |
| `GenericCnjTypeReader<T>` | user `T` | `.cnj` | `ContentManager.hpp:367-408` |

**Defect found**: `ResolveAssetPath()` tries `.cnj` before *every* reader's declared extensions (B14), but `SongTypeReader::Read` (`:3004-3009`) and `VideoTypeReader::Read` (`:3021-3024`) — unlike Texture2D/TextureCube/SoundEffect — **do not branch on a `.cnj` extension**. Given `Content/theme.cnj` and `Content/theme.ogg`, `Load<Song>("theme")` resolves to the `.cnj`, and `Song`'s constructor only checks `exists()` (`$CNA/modules/media/src/Xna/Song.cpp:14-29`), so it succeeds and returns a `Song` pointing at a JSON file that will fail at playback. Same shape for `Video`. **STRONG** (mechanically derived from verified code; not exercised by any test).

---

## CONTRADICTIONS

Ordered by how badly each would mislead a book author.

**X1 — `xnb.md` contains a flat self-contradiction and is the most dangerous file to read.** `$CNA/xnb.md:36-39` still reads **"Status: planning document only. Nothing described here is implemented yet."**, immediately below a 2026-07-16 banner that says Phases 0/A/B/B2/B3/C/D/E are complete. `xnb.md:106` ("CNA today does **not** read `.xnb` at all") and `:409-414` ("None of it is wire-compatible with real FNA-produced `.xnb` assets") are the same un-retracted pre-implementation prose. `$CNA/plan_xnb.md:39` carries the twin: *"Nothing here is implemented yet — every row starts ⬜."* Reality: 50 registered readers, 30 real fixtures, ~350 tests.

**X2 — `xnb.md`'s own banner is also stale, in the opposite direction from X1.** It says *"Phase D3/F onward — `Model` and the top-quality hardening pass — remain frozen/deferred pending a future decision to resume them; nothing there is started."* But `plan_xnb.md:3-7` states Phase F, D3 and G are all **fully complete**, and the code confirms it (`ModelContentTypeReaders.cpp`, `Texture3D`/`TextureCube` readers, `XnbContainerFuzzTests.cpp`). Two documents in the same repo disagree about the same phases.

**X3 — Five separate docs still assert CNA cannot read `.xnb` at all.** `$CNA/docs/migration-guide.md:80-82, 155-162, 171-176, 283`; `$CNA/docs/xna-4-api-coverage.md:57, 699-712, 847, 856`; `$CNA/docs/coverage.md:29, 40, 56, 90, 114, 148` (*"Content pipeline (.xnb) — 0 %"*); `$CNA/docs/README.md:57`; `$CNA/AUDIT.md:104` (*"ContentManager | ✅ | API complete (non-XNB approach)"*). `xna-4-api-coverage.md:57` specifically claims *"`ContentReader`/`ContentTypeReaderManager`/`LzxDecoder` — no header exists in CNA at all"* — all three exist. `AUDIT.md`'s `Content` namespace table has **no rows** for `ContentReader`, `ContentTypeReaderManager`, `ContentTypeReaderBase`, `KnownUnsupportedContentTypeReader`, `LooseFileContentTypeReader`, or `ContentManifestEntry`.

**X4 — `docs/xnb-content-pipeline-support.md`'s audio matrix is wrong.** `:56` and `:166-173` claim `SoundEffectReader` is *"16-bit PCM only"* with 8-bit PCM / IEEE float / MS-ADPCM / IMA-ADPCM *"explicitly rejected — no decode path exists yet"*, repeated in the gaps table at `:213`. The implementation supports all four (`SoundEffectContentTypeReader.cpp:289-301`), backed by four real fixtures and four passing tests. `plan_xnb.md:537-538` records the supersession explicitly (AUD-06, 2026-07-17 — one day after the doc was written). **The doc is otherwise the single most accurate content document in the repo**, which makes this one stale table especially hazardous.

**X5 — `cnj.md`'s "strict `cnjVersion == 1`" is no longer true, and the doc knows it hasn't been updated.** `cnj.md:20-22, 277` and `plan_cnj.md:369` all state a global `== 1` policy. Code enforces a **per-type** ceiling with `Model` at 2 (`CnjEnvelope.hpp:130-141`; `ContentManager.cpp:2277`). The doc-update task is still open and marked `⬜` at `$CNA/plan_gltf.md:2469` (GLTF-455). Worse, `cnj.md:283-285`'s design claim — that `cnjVersion` versions the *envelope only* and per-type evolution is handled by each type's own fields — has been **factually inverted** by the implementation.

**X6 — `cnj.md` claims the manifest cache services asset resolution. It does not.** `cnj.md:199-201`: the extra `.cnj` existence check is *"now serviced by the content-manifest cache … rather than a raw stat call."* Contradicted by `plan_xnb.md:460` (scope explicitly narrowed), by `ContentManager.hpp:97-103` (*"NOT yet consulted by ResolveAssetPath()/Load<T>()"*), and by three live `std::filesystem::exists()` calls at `ContentManager.hpp:514, 525, 534`.

**X7 — `docs/model-content-pipeline-support.md` is stale below its own correction banner.** The 2026-07-16 banner correctly scopes the body to the loose-file path, but the body then says *"CNA has **no binary `.xnb` model reader at all**"* (`:59`), describes a `.model.json` descriptor (`:64-72`) that **no longer exists** — `ModelTypeReader::GetExtensions()` is `{".cnj",".gltf",".glb"}` (`ContentManager.cpp:2256`), and `plan_cnj.md:349` confirms zero `.model.json`/`.font.json`/`.shader.json` files remain — claims *"**Zero test coverage**: … no test or example anywhere exercises `ModelTypeReader`"* (`:86-94`) when `CnjModelTests.cpp`, `RuntimeGltfModelTests.cpp` (9 tests) and `GltfToCnjToolTests.cpp` (20 tests) all do, and its summary row `:112` (*"`Model` binary `.xnb` loading | ❌ Not implemented"*) contradicts the file's own banner.

**X8 — `cnj.md`'s native-extension table and "core rule" omit glTF entirely.** `cnj.md:256-262` lists `.png/.jpg/.jpeg/.bmp`, `.dds`, `.wav`, conditional `.ogg/.mp3`. Actual: Texture2D has 9 extensions (`ContentManager.cpp:477`), Song 7 (`:3001`), Video 6 (`:3018`), Model `{.cnj,.gltf,.glb}` (`:2256`). Neither the table nor the five-step "core rule" mentions `.gltf`/`.glb` at all, despite runtime glTF being a headline capability (CNB-70/71).

**X9 — `cnj.md`'s `sourceFile` capability matrix is incomplete.** `cnj.md:386-405` lists six readers. The code enforces the rule for **nine**: the missing three are `Texture3D` (`ContentManager.cpp:591`), `AnimationClip` (`:1469`) and `Curve` (`:1623`), all of which reject `sourceFile`.

**X10 — `cnj.md` says there is no JSON library; there now is, but only half the readers use it.** `cnj.md:303-306` describes the pre-CNB-35 world (*"small hand-rolled helpers … not a general JSON library"*). `CNA/Internal/Json.hpp` (595 lines, 14 tests) now exists and `cnj.md:19-21` itself says the envelope uses it. Both statements are in the same document. Neither states the real situation: a **hybrid**, where `SpriteFont`, `Model`, `SkinnedModel`, `Texture2D`'s colorKey and the custom-GLSL `Effect` branch still run on substring scanners (C31).

**X11 — Every source path in all four design docs is stale.** The repo is now a `modules/<name>/{include,src,tests}` monorepo (promoted 2026-08-10). `src/Microsoft/Xna/Framework/Content/` does not exist. Affected: `cnj.md:17-20, 304, 335, 370, 686-688`; `plan_cnj.md:248, 366, 369, 389, 507`; `xnb.md:102, 409`; `plan_xnb.md:339-597` throughout; `docs/model-content-pipeline-support.md:17` (cites an intermediate layout that is *also* gone); `gltfissues.md:97-124` (cites line numbers against a file that has since grown to 3227 lines). The entire `$CNA/audit/` tree (2297 `.audit.md` files) is likewise keyed on the old layout.

**X12 — The `audit/` corpus still lists a fixed HIGH finding as open.** `$CNA/audit/src/Microsoft/Xna/Framework/Content/ContentReader.cpp.audit.md:24-26, 91-94` records *"a confirmed HIGH-severity gap: it only rejects a `..`-style relative escape, not an absolute-path escape."* That is **fixed at this SHA** (`ContentReader.cpp:51-56`, `IsDisallowedAbsolutePath`) and pinned by `ContentReaderExternalReferenceTest.AbsolutePathReferenceThrowsContentLoadException`. The same audit file (`ContentManager.cpp.audit.md:4-5`) states the file is 2976 lines; it is 3227. The audit's *other* two findings — no `serviceProvider` null-check, `Unload()` doesn't dispose — remain **accurate** (B5, B18).

**X13 — `plan_cnj.md` marks `CNB-61` as `⬜` while the same file records it closed.** `plan_cnj.md:474` says *"Still deliberately out of scope"*; `plan_cnj.md:14-24` (Phase 14I) says the backend sweep closed it.

**X14 — `plan_gltf.md`'s own banner is stale on this branch.** `plan_gltf.md:9-11`: *"THIS DOCUMENT IS A PLAN. NOTHING IN IT WAS IMPLEMENTED."* But `$CNA/modules/content/tests/CNA/Internal/GltfImport/GltfKnownDefectTests.cpp:1-28` records D1/D2/D3/D4/D8 fixed, D5 partially remediated, **D6 and D7 untouched** — and encodes that ledger as executable tests. `$CNA/FUTURE.md:27, 43` ("glTF correctness campaign | not started", "glTF is **not** corrected") are correspondingly stale.

**X15 — Every test-count figure in every doc is a dated snapshot.** `cnj.md` cites 4452/4661/4680/4683/4689/4696 at six different points; `plan_cnj.md` cites 4748/4824/4845/4843; `plan_xnb.md:683` cites 4637. `$CNA/NEXT.md:881` reports 5906. None is current.

**X16 — What the docs get *right*, and the book should not "correct":** `plan_xnb.md` is the most reliable document in the repo. Its three open markers were independently verified: **XNB-61b** `⬜` (compressed-file reader inventory) is genuinely still open — `ContentManager.cpp:168-175` still early-returns for compressed files, exactly where `plan_xnb.md:465` says the fix belongs; **XNB-30C** `⏸` (LZ4) is genuinely deferred; **Phase I** (`XNB-61`–`64`, XNA-sample compatibility inventory) is genuinely not started; **Phase H** (Lua-scripted readers) is genuinely cancelled outright, its task rows deleted rather than deferred.

**X17 — `known_bugs.md` has zero content entries.** Grepped in full: it is entirely graphics/LLGL/Vulkan. The real content-security ledger lives in `$CNA/remediation/` under IDs `REMED-CONTENT-001` … `-011`. `-001` (malformed `Texture2D` `.xnb` crashing the process — Vulkan stack smashing, non-catchable WebGPU panic) was the **only CRITICAL in the entire remediation audit**; it is DONE. `-002`, `-003`, `-006`, `-007`, `-008`, `-009`, `-011` are DONE (`-007`/`-008` only closed 2026-08-08, three days before this SHA). **`REMED-CONTENT-010` (vendored cgltf misaligned load, LOW) is still OPEN** — `$CNA/NEXT.md:802, 834, 879`. Any book claim about content-loading security posture must cite `remediation/` and `NEXT.md`, never `known_bugs.md`.

---

## BOOK IMPACT

### The verdict

**Yes — split it, and promote it out of Part II.** Three independent arguments, none of which rests on line count alone:

1. **The chapter is in the wrong Part.** `ch08-content-and-assets.tex` sits in *Part II: Getting Started*, between "Math & Core Types" and "GraphicsDevice". A reader learning to write their first CNA game does not need 2,247 lines on LZX block framing, `std::any` boxing of move-only types, `int64` overflow guards, and a five-layer glTF conformance ladder. The chapter has outgrown its Part.

2. **There are now four genuinely separate subsystems under one roof**, sharing only the `ContentManager` façade: the XNA-faithful binary reader stack (`CNA::Internal::Xnb`, ~5k lines + 18 test files), the CNA-original JSON format (`CnjEnvelope`/`Json`/the loose-file readers, ~3k lines + 15 test files), the glTF import core (`GltfImportCore`, 2.5k lines + 11 test files with its own oracles and conformance ladder), and the `ContentManager` object itself. The book currently has **zero coverage of the third**, and the existing chapter's section list confirms it: no section mentions glTF, `GltfImportCore`, `gltf_to_cnj`, the conformance ladder, or `cnjVersion 2`.

3. **The two-registry split is the subsystem's central confusion, and one chapter cannot foreground it.** `LooseFileContentTypeReader<T>` (per-manager, keyed by `type_index`, `Read(path, cm)`) and `ContentTypeReader<T>` (process-wide, keyed by canonical string, `Read(ContentReader&, optional<T>)`) share a near-identical name and nothing else. They were the *same class* until the 2026-07-16 rename. In a single chapter this reads as a naming quirk; across two chapters it becomes the architectural fact it is.

### Proposed split — a dedicated **Part: The Content Pipeline**, five chapters

Sizes are relative depth, not page mandates.

**Ch. A — "Loading an asset: ContentManager and the resolution order" (~medium, 25–30 pp)**
The façade and the decision procedure. Three constructors and the unused service provider (B5–B7); `RootDirectory` as a base and explicitly *not* a sandbox (B9); the four-tier resolution order with the `exists()`-not-`has_extension()` subtlety (B14); the three-cache reality — strong `std::any`, `Texture2D`'s weak renderer cache, and the two types with no cache at all (B12–B13); why the cache key is `(type_index, name)` and the `bad_any_cast` bug that forced it (B11); `Unload()` as two `.clear()` calls with no disposal, and the missing tracking list (B18); the content manifest as unsorted introspection deliberately *not* wired into resolution (B21–B22); no thread safety (B19); `Game` owning a manager by value and **never registering the built-in readers** (B20) — the single most important practical fact in the entire subsystem for a real porter. `ResourceContentManager` as a one-line stub (B23).
*Salvageable from Ch. 8*: §"The resolution order, precisely", §"ContentManager: constructing it and calling Load" and their subsections — largely still correct, needing the `.gltf`/`.glb` addition and the manifest correction.

**Ch. B — "The XNB container" (~medium, 20–25 pp)**
Header layout, the 16 FNA-exact platform bytes and the deliberate MonoGame rejection (D38–D40); compression as a four-valued enum with both bit values sourced from MonoGame's own code (D41); LZX as a line-by-line port with per-file decoder state, verified byte-for-byte against FNA under Mono (D42, G69); LZ4 as a named refusal; the type-reader table and the real generic-name parser (D44–D45); `XnbReadLimits` as a **table with an enforcement column** (G63) — including the honest note that `maxFileSize` is only half-enforced (B17). Close on the `totalLength`-vs-file-size cross-check and the heap-buffer-overflow it fixed (B16).
*New material*: most of it. Ch. 8's §"An XNB header chooses a decoder" is a good seed but predates the limits audit.

**Ch. C — "Type readers: the reader architecture" (~large, 30–35 pp)**
`ContentTypeReaderBase`/`ContentTypeReader<T>` and why the base had to be renamed (E46); `std::any` boxing with the `shared_ptr` fallback for move-only types (E47); `optional<T>` for `existingInstance` and the `default(T)` problem (E48, E53); `ContentTypeReaderManager` as a process-wide registry that is *empty by default* because CNA has no reflection (E51); 1-based dispatch, the depth guard, and the two-pass shared-resource protocol (E53–E55); `ReadObject`'s five forms plus the untyped `std::any` overload (E56); `ReadExternalReference<T>` instantiated for exactly two types (E57) and its containment hardening (E58).
**Two findings the book should state plainly**: no reader overrides `SupportsVersion`/`TypeVersion`, so any `.xnb` declaring a nonzero reader version is rejected (E49); and `CanDeserializeIntoExistingObject` is declared, overridden twice, and **never consulted** (E50).
Then the **full reader table** (see above) with per-reader status and evidence, and the closing boundary: the four collection templates exist but only **three closed instantiations** are registered anywhere (all for `SpriteFont`); no `EnumReader`; no `ReflectiveReader`, by design.
*Salvageable*: Ch. 8's per-reader subsections (`Texture2DReader`, `SpriteFontReader`, `ModelReader`, stock effects, `SoundEffectReader`, `CurveReader`, `Decimal`/calendar) are individually good and mostly still accurate — but **`SoundEffectReader`'s section must be rewritten** (X4: four formats gained support after the doc was written), and the "no enum fallback" observation should be kept verbatim, since it is still true.

**Ch. D — "CNJ: CNA's own content format" (~medium-large, 25–30 pp)**
What CNJ actually is — plain JSON, no magic bytes, and the `.cnb`→`.cnj` rename that exists precisely to stop people expecting a binary (C24). The envelope and the **per-type version ceiling** (C26) — correcting the docs' `== 1` claim head-on. Dispatch by `T` with `"type"` as a cross-check (C27). The eleven built-in types (C28). The `sourceFile` capability matrix as *enforced code*, not documentation (C29), and `ResolveCnjSourceFileSafely`'s five rejection rules including the implicit-`.cnj` self-cycle (C30). `RegisterCnjLoader<T>` with its full fail-fast contract (C33). The binary sidecar formats and their optional-block-by-remaining-bytes detection (C37).
**Two things the book must say that no CNA doc says**: the parser is a **hybrid** — half the readers use the real recursive-descent parser, half still use substring scanners (C31); and the `.cnj` side is materially less hardened than the `.xnb` side — no depth limit (C32), no size limit, no fuzzing (G73). That asymmetry is the honest headline of this chapter.
*Salvageable*: Ch. 8's §"CNA's own format: .cnj" and its two quoted files — but the version claim and the capability matrix both need correcting.

**Ch. E — "glTF, the offline tool, and asset provenance" (~medium, 20–25 pp)**
**Entirely new; the book currently has nothing on this.** `gltf_to_cnj` as a graphics-free developer tool built unconditionally (C34); `GltfImportCore` as the shared core used by both the CLI and the runtime reader (C35), and the fact that `Load<Model>("x.gltf")` now works with **no sidecars at all** — which quietly makes the offline tool optional for the common case. The documented runtime limitation (first mesh group only, `unitScale` fixed at 1.0). Then the verification architecture, which is the most interesting engineering story in the whole subsystem: the five-layer conformance ladder, the two differential oracles that attribute a one-byte difference to the owning vertex and field, the Python-generated fixture corpus, and `GltfKnownDefectTests.cpp` encoding **open defects as executable tests** with a meta-test asserting the ledger and the test file stay in sync (H78). Close on the current defect ledger: D1–D4 and D8 fixed, D5 partial, **D6 and D7 untouched** (X14).

### Cross-cutting: a "Robustness and security" section, or a sixth short chapter

Everything under FACTS §G — the limits table with its enforcement column, `ReadBytesExactOrThrow`, `CheckedMultiplyOrThrow` and the `int64`-still-overflows lesson, the three fuzz harnesses with their exact iteration counts and their `bad_alloc`-is-a-failure stance, the Mono differential oracle, `PathContainment` and the "explicit external bundle" rule, and the 951-line/18-test containment suite. This can live as the closing section of Ch. B or as its own ~15-page chapter.

**State the real boundaries, and do not inflate them**: symlink checking is not race-proof; normalizing-`..` and `.` segments are accepted by design; `ContentManager::Load()` with an absolute asset name is permitted by contract; containment governs file-internal references, not caller arguments; `maxFileSize` is only enforced on compressed payloads. The remediation record is genuinely strong — one CRITICAL and several HIGHs found and closed, most by fuzzing rather than review — and it reads as *more* credible when the remaining gaps are named alongside.

### Sourcing warnings for whoever writes these chapters

- **Never source a content claim from `xnb.md`, `docs/migration-guide.md`, `docs/xna-4-api-coverage.md`, `docs/coverage.md`, `docs/README.md`, or `AUDIT.md` without checking the code.** All six still assert CNA cannot read `.xnb` (X1, X3).
- `docs/xnb-content-pipeline-support.md` is the best content document in the repo — **except its audio matrix** (X4).
- `plan_xnb.md` is the most trustworthy; its three open markers were independently verified as still accurate (X16).
- `cnj.md` is a good *design* reference and a poor *status* reference (X5, X6, X8, X9, X10).
- Every source path in every design doc is stale (X11); the `audit/` tree is keyed on the same dead layout and lists at least one already-fixed HIGH (X12).
- The only current authorities on content-loading security are `$CNA/remediation/` and `$CNA/NEXT.md` — **not** `known_bugs.md`, which has no content entries at all (X17).

### Two book-worthy defects surfaced by this audit

Both mechanically derived from verified code; neither is covered by any test, and neither appears in any CNA document:

- **`Load<Song>` / `Load<Video>` will happily return an asset pointing at a `.cnj` file.** The resolver tries `.cnj` before native extensions for *every* type, but only `Texture2D`, `TextureCube` and `SoundEffect` branch on it in their `Read()`. `Song`'s constructor only checks `exists()`, so it succeeds. (READER TABLE, closing note.)
- **The `.cnj` JSON parser recurses without a depth bound** (C32), while the `.xnb` side bounds both type-name and object-graph nesting after REMED-CONTENT-006 explicitly flagged unbounded recursion as a stack-exhaustion DoS. Same threat model, same repo, opposite treatment.
