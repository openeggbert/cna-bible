# Next session — start here

Read this file first, then `PLAN.md`. `PLAN.md` is the durable expansion plan and historical
session log; this file is the concise live handoff.

## Current state (2026-07-25)

- Branch: `develop`.
- Book: **543 physical PDF pages, 49 chapters, 6 appendices**.
- The local branch is ahead of `origin/develop` by twenty-four documentation commits: `944fa54`
  (render-target binding/usage contracts), the Reset-order contracts batch, the resource-lifecycle
  audit, the construction/SDL-ownership audit, the multisample-backend-rebuild audit, and the
  Game/GraphicsDeviceManager lifecycle and callback/disposal audits, plus the Game
  exit/destruction/component-lifetime and ContentManager cache/disposal and
  copy/replacement, service-provider/device-resolution, reader-registration, root/path, and
  Load-failure/type/cache-mutation, concurrency/reentrancy, content-manifest introspection,
  format-selection/fallback, ResourceContentManager/OpenStream, TitleContainer/TitleLocation,
  ContentReader, ContentTypeReader, XNB header/decompression, XNB type-reader-name/table, and
  scalar/math-reader audits below. The previous twenty-three-commit count was accurate before this
  local batch and is retained only in the
  historical session log.
- `a8b38ae` could not be pushed because the escalation approval service disconnected while
  reviewing `git push`. Its response explicitly rejected the request rather than granting
  permission. Do not bypass that control; retry only when approval is available or the user
  explicitly authorizes another attempt.

## Latest completed batch: scalar/math XNB-reader layouts and generic-enum boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
primitive/math reader and registration families, umbrella registration, ContentReader composite
methods, sharp-runtime BinaryReader/BinaryWriter, focused unit tests, real MonoGame SpriteFont
fixtures, current FNA reader-manager source, and every CNA enum-reader reference establish:

- CNA installs 13 primitive and 13 math reader factories only when explicitly registered; the
  umbrella helper includes them but ContentManager construction does not. All inherit the common
  exact serialized-version-zero rule, unlike FNA's version-discarding reader table.
- Primitive wire values are explicit little-endian scalars; Boolean is one nonzero-true byte,
  Char is a variable-length UTF-8-decoded UTF-16 code unit, and String is a 7-bit byte length plus
  raw std::string bytes. Char/length failures remain binary-reader errors. String adds neither
  UTF-8 validation nor maxStringBytes enforcement.
- Geometry is direct component order: vectors, quaternion, M11..M44 matrix, RGBA Color, and the
  documented Plane/Point/Rectangle/bounds/frustum/ray field sequences. Readers construct results
  without their own finiteness, range, normal, min/max, size, or invertibility validation.
- CNA has no generic EnumReader<T> class, key, or fallback. FNA's manager explicitly creates
  generic enum readers. CNA's parser accepts an EnumReader table spelling, then factory lookup
  rejects it as unregistered; callers need their own exact canonical factory.
- The unit test uses the matching local BinaryWriter and direct ReadUntyped calls: all primitives
  round-trip, but only 8 of 13 math readers get field checks. It covers no external scalar XNB,
  header/table dispatch, malformed/truncated input, serialized version, Unicode/string edge, or
  enum. Real MonoGame SpriteFont fixtures additionally exercise Char, Rectangle, and Vector3.

Ch.8 now records the reader set, layouts, strict-version and validation behavior, generic-enum
gap, and test scope. Full latexmk succeeded at **543 pages**; targeted undefined-reference and
duplicate-label checks are empty; makeindex accepted **2,212** entries with zero rejected and
zero warnings; git diff --check passes. Rendered physical pages **110--111** are clean. Ch.8 is
**1,379** lines and Ch.6 is **621** lines. The plan-consistency validator remains absent from this
checkout.

Next recommended start: retain the XNB scope and audit the separate Decimal/DateTime/TimeSpan
reader family, especially its platform guard, Decimal bit/scale validation, DateTime-kind loss,
serialized versions, and fixture/test coverage. Treat the generic-enum gap as current develop
behavior; implementing a universal enum mechanism is a compatibility and registration-design
decision, not a documentation-only correction.

## Previous completed batch: XNB type-reader-name grammar and table-admission contract

No CNA source changes were made; the sibling repository remained a read-only authority. The
recursive XnbTypeName parser, XnbTypeReaderTable parser, ContentReader initialization/factory
handoff, global registration source, XNB limits, sharp-runtime BinaryReader implementation,
focused parser/table tests, and current FNA type-reader manager establish:

- CNA recursively removes outer and nested assembly metadata, turning an XNB reader name into a
  canonical global factory key. It has no reflection-backed type identity: a bare name and
  differently assembly-qualified forms select the same key, while unknown keys fail only at the
  later factory lookup. FNA instead tries the original creator string and then a rewritten
  reflection name.
- The parser is not a full .NET grammar validator. It accepts empty/untrimmed bases, never checks
  generic arity or a legal name alphabet, leaves both top-level and nested parse cursors
  unconsumed, and has no generic-depth cap. That deliberately discards valid assembly suffixes
  but also lets arbitrary trailing/malformed material survive canonicalization.
- The table bounds only its count (0..4,096 by default). It accepts a zero table, duplicate raw
  and canonical names, and any signed reader version. ContentReader preserves order, creates a
  fresh reader per entry, then checks the entry version; an unknown reader fails before version
  compatibility is considered.
- Name bytes do not use maxStringBytes and recursive generic parsing does not use
  maxObjectNestingDepth. BinaryReader rejects a seekable name length past the remaining stream but
  can still allocate a physically supplied name below that bound. Only parser
  std::invalid_argument failures are wrapped as ContentLoadException; malformed 7-bit prefixes
  and truncated name/version fields leak their original binary-reader exceptions despite the
  table header's broader documentation claim.
- Focused tests cover healthy bare/nested generic names, two bracket failures, count rejection,
  and one MonoGame fixture. They do not cover empty/trailing/whitespace/arity forms, duplicate
  keys, truncation, a long name, or nesting depth.

Ch.8 records the canonicalization, FNA contrast, admission/error/limit boundary, duplicate/version
behavior, and test gaps. Full latexmk succeeded at **541 pages**; targeted undefined-reference
and duplicate-label checks are empty; makeindex accepted **2,204** entries with zero rejected and
zero warnings; git diff --check passes. Rendered physical pages **109--110** are clean. Ch.8 is
**1,320** lines and Ch.6 is **621** lines. The plan-consistency validator remains absent from this
checkout.

Next recommended start: retain the XNB scope and audit the supported scalar/math/enum built-in
type readers for byte layout, endian/count boundaries, reader-version policy, and the fixture/test
matrix. Keep the just-established parser limitations documented as current develop behavior,
rather than treating the unintegrated feature/audit branch as a source fix.

## Previous completed batch: XNB container header, LZX handoff, and input-limit boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
header, default limits, LZX wrapper/decoder, ContentManager load and manifest paths, all focused
header/manager/LZX/fuzz tests, hardening history, sharp-runtime stream behavior, and current FNA
loader establish:

- Header parsing validates XNB magic, the FNA-compatible platform set, versions 4/5, and the
  LZX/LZ4/both compression-bit cases. It does not validate the other flags. Its signed
  totalLength is only checked by normal loading, after the whole physical file is already read,
  and only for 10 <= declared <= physical; equality is not required.
- A smaller declared length and physical trailing data are accepted. Uncompressed loading gives
  every byte after the header to ContentReader and never verifies end-of-asset; LZX instead uses
  only the declared compressed span. Header length is therefore not an integrity assertion.
- LZX needs four bytes after the header for the decompressed size, but a declared compressed
  totalLength from 10 through 13 reaches that field before a 14-byte physical minimum is checked.
  This is outside the established safe parsing contract and has no focused test.
- The declared compressed/decompressed sizes have useful checks, but the decoder writes each
  frame to a growing MemoryStream and only compares accumulated output with the declared size at
  the end. A crafted multi-block stream can exceed maxDecompressedSize before that mismatch
  fails. maxFileSize only constrains declared LZX bytes after full-file materialization; it does
  not bound uncompressed input or padded physical files. ContentManager exposes no limit
  configuration.
- The manifest scanner is deliberately weaker: whole-file, uncompressed-only, and catch-all
  best effort, without a declared-length check. FNA trusts its XNB header lengths even more, so
  its behavior is not a safety guarantee for CNA.

Ch.8 now records the exact flag, length, prefix, allocation-budget, configuration, manifest, FNA,
and test boundary. Full latexmk succeeded at **541 pages**; targeted undefined-reference and
duplicate-label checks are empty; makeindex accepted **2,200** entries with zero rejected and zero
warnings; git diff --check passes. Rendered physical pages **107--108** are clean. Ch.8 is
**1,261** lines and Ch.6 is **621** lines. The plan-consistency validator remains absent from this
checkout.

Next recommended start: retain the XNB scope and audit XnbTypeName/XnbTypeReaderTable canonical
name normalization, nested-generic parsing, version/name admission, and error behavior. Treat the
already documented inactive string/nesting limits as current develop facts, not as implemented
hardening.

## Previous completed batch: ContentTypeReader erased-value and collection boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
generic/base/manager API, all focused registration/custom/collection/unsupported-reader tests,
normal dispatch, concrete registrations, and current FNA reader/manager/collection sources
establish:

- ContentTypeReaderBase is the unavoidable C++ non-template companion to the public
  ContentTypeReader<T> template. Its target type is only an advisory canonical-name string, not a
  reflected type identity. The erased ReadUntyped boundary carries std::any; disagreement among
  the table name, target name, template, and returned object is ultimately a bad_any_cast rather
  than a normalized ContentLoadException.
- Copyable target values live directly in any. Bare move-only targets instead live as
  shared_ptr<T>, which normal indexed dispatch unwraps correctly. This applies to SoundEffect and
  TextureCube. Public direct ReadObject/ReadRawObject overloads do not implement the matching
  convention: direct reads of a move-only result throw bad_any_cast, while the overload accepting
  an existing bare move-only instance cannot instantiate. Use ordinary indexed dispatch for those
  types.
- An existing instance is moved as an input value and returned as a replacement, not mutated in
  the caller. No production CNA code reads CanDeserializeIntoExistingObject; manager loads start
  fresh and cache the result. Lists append to a supplied value, dictionaries clear it, and arrays
  resize a mismatched vector. Only ListReader and DictionaryReader advertise the capability.
- FNA resolves collection element readers from a per-file reflected type table during Initialize.
  CNA instead needs each closed generic and each non-reference element reader registered manually,
  then creates fresh global-factory readers at decode time. Those nested readers get neither
  per-file Initialize nor serialized version checking, so this is valid only for the current
  stateless built-ins. The umbrella registration intentionally omits arbitrary closed generics;
  SpriteFont contributes its three known list shapes.
- All counted collections validate declared counts before allocation. But CNA uses
  unordered_map::emplace for dictionaries, silently retaining the first duplicate key where FNA's
  Dictionary.Add throws. Tests do not cover reference-shaped collections, a stateful custom
  element reader, null/throwing factories, duplicate keys, incorrect any boxing, or the direct
  move-only overload trap. The known unsupported EffectReader is a deliberate named-error
  placeholder, not a fallback.

Ch.8 corrects its previous claim that only SoundEffect used the move-only branch and records this
extension/compatibility boundary. Full latexmk succeeded at **539 pages**; targeted
undefined-reference and duplicate-label checks are empty; makeindex accepted **2,193** entries
with zero rejected and zero warnings; git diff --check passes. Rendered physical pages
**106--107** are clean. Ch.8 is **1,197** lines and Ch.6 is **621** lines. The
plan-consistency validator remains absent from this checkout.

The next recommended audit at this checkpoint was the XNB header/decompression handoff. It was
completed in the newer batch above.

## Previous completed batch: ContentReader XNB object-graph session boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
complete reader implementation and tests, ContentManager XNB call site, stream base behavior,
reader-table/name parsers, XNB-limit declaration and consumers, history, and current FNA source
establish:

- CNA's public, non-final ContentReader is one body/session reader, not a reusable file utility.
  `ReadAsset<T>()` parses its reader table at the current position immediately after the ten-byte
  XNB header, then reads one root, all shared values, and queued fixups. The constructor comment
  claiming that the table is already consumed is stale. A second call does not rewind; it parses
  post-asset bytes as a new table.
- The stream and manager are raw, non-owning pointers, but BinaryReader's default `leaveOpen =
  false` closes the supplied stream when the reader dies. ContentManager's stack ordering makes its
  local body stream safe; standalone callers must keep both referents alive and must expect their
  stream to close. CNA's temporary type-reader initializer manager dies before reads begin, and
  session reader instances die with the session: neither is asset-owned state. Late shared parsing
  or a callback can still fail after a root reader has produced side effects.
- Positive shared references are fixed up only after every shared value decodes, so forward/cyclic
  graphs work. Negative indexes silently behave as zero; a typed mismatch leaks
  `std::bad_any_cast`, unlike FNA's normalized content-load error. Disposal tracking works only
  for statically typed `shared_ptr<IDisposable>` results with an explicit callback. The normal
  manager supplies no callback, the promised manager fallback is absent, and type-erased shared
  values skip tracking.
- `ReadExternalReference<T>()` is link-instantiated only for Texture2D and TextureCube. Empty
  names return nullopt; relative upward escape is rejected, but absolute logical references still
  reach ContentManager's unrestricted absolute path. FNA's counterpart is genuinely generic.
- Current `develop` applies only part of `XnbReadLimits`: `maxStringBytes` and
  `maxObjectNestingDepth` have no live consumer, while `maxFileSize` applies only to LZX
  compressed input. Do not infer a universal input-admission policy. A corrective commit
  (`30a4fb35`) exists only on the separate, non-integrated `feature/audit` branch; it is not
  behavior of the audited branch.

Ch.8 now records the source-established stream, dispatch, shared-resource, lifetime, disposal,
external-reference, error, limits, FNA, and test-coverage boundary. Full `latexmk` succeeded at
**539 pages**; targeted undefined-reference and duplicate-label checks are empty; makeindex
accepted **2,188** entries with zero rejected and zero warnings; `git diff --check` passes.
Rendered physical pages **105--106** are clean. Ch.8 is **1,127** lines and Ch.6 is **621**
lines. The plan-consistency validator remains absent from this checkout.

The next recommended audit at this checkpoint was ContentTypeReader. It was completed in the
newer batch above. The current `develop` branch remains separate from the unintegrated
`feature/audit` hardening change; deciding whether to integrate that source fix belongs to CNA
maintainers, not this documentation worktree.

## Previous completed batch: TitleContainer and TitleLocation direct-file boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The live
title classes and tests, every live reference, sharp-runtime stream ownership, SDL3's installed
filesystem declaration, ContentManager's actual path, history, and current FNA sources establish:

- TitleContainer is a static direct-file helper, not a ContentManager or ResourceContentManager
  stream layer. Neither manager calls it: their own root/path resolution opens filesystem streams
  directly. Changing the CNA title-location setter therefore cannot redirect `Content.Load()`, and
  a ContentManager root cannot redirect `TitleContainer::OpenStream()`.
- The global base initializes once from SDL3's cached, const application-base pointer, with the
  current working directory as fallback only when SDL supplies no path. This is not an SDL-owned
  allocation to free. CNA's NOXNA setter accepts arbitrary strings, has no synchronization, and
  can invalidate references returned by either getter spelling; configure it once before threads
  begin and copy a returned path if later mutation is possible. FNA instead makes title location
  internal and getter-only through its platform layer.
- Resolution replaces backslashes, then only lexical-normalizes an absolute name or a name
  appended to the title base. It has no containment/canonical/symlink check: `..` and symlinks can
  escape, and it is not an untrusted-filename sandbox. On normal platforms a missing path throws
  the title helper's plain `std::runtime_error`, while filesystem/direct-stream failures retain
  their own exception boundaries. Both requested and resolved names are Info-logged.
- Android tries SDL asset loading after a normal filesystem miss, first with the normalized
  relative name then with the resolved name. It copies bytes into MemoryStream before SDL frees
  them, so there is no borrowed buffer; the unchecked `size_t` to signed `intcs` narrowing leaves
  assets larger than that maximum outside the established safe contract.
- The four focused tests are happy-path probes only: relative/absolute cases never read bytes;
  the test labelled backslash normalization passes a forward slash; and none covers traversal,
  symlinks, directory/access errors, logging, Android, initialization, returned-reference
  lifetime, or concurrent global mutation. Fixed temporary locations are not restored.

Ch.8 now contains the full source-established contract and Ch.6 cross-references it. Full
`latexmk` succeeded at **537 pages**; targeted undefined-reference and duplicate-label checks are
empty; makeindex accepted **2,174** entries with zero rejected and zero warnings; `git diff
--check` passes. Rendered physical pages **112--114** are clean. Ch.8 is **1,039** lines and Ch.6
is **621** lines. The plan-consistency validator remains absent from this checkout.

Next recommended start: keep the content/I/O scope and audit `ContentReader`'s stream ownership,
asset-name/context stack, shared-resource fixups, exception and disposal behavior, and its exact
relationship to type readers/XNB decoding. Compare all focused ContentReader tests and current FNA
before documenting it; do not reopen the explicitly `needs_human` embedded-resource architecture.

## Previous completed batch: ResourceContentManager and virtual OpenStream boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The live
stub/header, every in-repository reference and test path, API-coverage records, and current FNA
`ResourceContentManager`/`ContentManager` source establish:

- CNA's public subclass has only `ResourceContentManager(IServiceProvider*)` and protected virtual
  `OpenStream(string)`. It has no resource-manager argument or storage, accepts the same passive
  nullable provider as its base, preserves the base `"Content"` root and builtin readers, and its
  sole method ignores the name and unconditionally throws `std::runtime_error`. That is a stub
  signal, not a normalized `ContentLoadException` for a bad embedded asset.
- No CNA source calls that virtual method. Every inherited generic or special `Load<T>()` takes
  the normal filesystem/XNB/CNJ path and opens file streams directly, so a ResourceContentManager
  can incidentally load loose files like ContentManager but cannot load embedded content. An
  override in a further derived class does not redirect inherited Load templates; it needs a
  separate loader or a deliberate base architecture change. No CNA test constructs the class,
  probes its protected throw, or proves the inherited bypass.
- Current FNA instead requires a non-null `System.Resources.ResourceManager`, uses it to retrieve
  an exact-name binary resource as a buffer-visible memory stream, converts missing/non-binary
  entries to `ContentLoadException`, and reaches virtual OpenStream from normal `ReadAsset<T>()`
  before its raw-file fallback. CNA therefore lacks both the source abstraction and dispatch seam,
  not just one method body.
- Embedded-resource support is explicitly **needs_human**: it needs a public choice between an
  FNA-shaped resource-manager constructor and a deliberate NOXNA C++ abstraction, plus ownership,
  stream, fallback, compatibility, and test decisions. Do not fill this gap through loose-reader
  registration or silently change base Load behavior.
- Full `latexmk` succeeded at **535 pages**; targeted undefined-reference and duplicate-label
  checks are empty; makeindex accepted **2,166** entries with zero rejected and zero warnings;
  `git diff --check` passes. Rendered physical pages **112--113** are clean. Ch.8 is now **972**
  lines. The plan-consistency validator remains absent from this checkout.

## Previous completed batch: ContentManager exact format selection and fallback boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
generic template and all three bespoke Load specializations, every built-in loose reader and its
extension list, focused resolver/cache/XNB/glTF tests, and CNJ source-file helper establish:

- On a cache miss CNA first checks `BuildAssetPath(assetName) + ".xnb"`, before it needs a local
  reader. Only then does it select the first existing loose candidate: literal `base`, then
  `base.cnj`, then the reader's ordered extensions; if none exists it still passes bare `base` to
  the reader. The same chain applies to generic loads, weak-cached Texture2D, and uncached
  SoundEffect/TextureCube. A cache hit never reevaluates the filesystem.
- Selection is terminal, not a successful probe. A malformed/mismatched XNB, invalid CNJ,
  corrupt native candidate, directory, or reader rejection does not fall through to a lower
  candidate. The explicit logical XNB name trap follows directly: `Load<T>("a.xnb")` probes
  `a.xnb.xnb` first and, if that is absent, routes the literal XNB through the loose reader;
  callers use `Load<T>("a")` to activate `a.xnb` parsing. Dots do not otherwise suppress
  suffixing.
- An extensionless `Load<Texture2D>("hero")` gives `hero.cnj` priority over `hero.png`; an
  existing literal `Load<Texture2D>("hero.png")` selects the PNG (after the independent
  `hero.png.xnb` check). The global CNJ probe is not gated by `GetExtensions()`, so custom
  readers can receive CNJ paths. A CNJ `sourceFile` begins a new, safe logical Load and can again
  be preempted by a sibling XNB.
- Ch.8 now records all built-in native-extension orders and the platform-excluded Video reader,
  including Model's CNJ/glTF/GLB precedence. Existing focused tests cover healthy native/CNJ
  texture selection, CNJ-over-native priority, XNB priority, cache isolation, and missing-CNJ
  glTF; they omit invalid-candidate fallback, explicit-XNB names, unsupported literal extensions,
  directories, and a failed first extension followed by a valid later one.
- Full `latexmk` succeeded at **535 pages**; targeted undefined-reference and duplicate-label
  checks are empty; makeindex accepted **2,160** entries with zero rejected and zero warnings;
  `git diff --check` passes. Rendered physical pages **105--107** are clean. Ch.8 is now **920**
  lines. The plan-consistency validator remains absent from this checkout.

Next recommended start: finish the remaining ContentManager public surface by auditing
`ResourceContentManager` and its virtual `OpenStream()` contract. Compare its constructor/base
state, actual stream availability, inheritance effects on `Load<T>()`, test coverage, and FNA
semantics before documenting or changing any use pattern.

## Previous completed batch: ContentManager manifest introspection, ordering, and diagnostic boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
manifest implementation and entry API, the focused manifest tests, `plan_xnb.md`/`xnb.md`, and
the normal resolver establish:

- The NOXNA manifest is an additive snapshot for diagnostics, not a resolver or a loadability
  check: normal `Load<T>()` and `ResolveAssetPath()` continue with live filesystem probes. Its
  `hasXnb`, `hasCnj`, and native-extension fields therefore mean candidates were seen, not that a
  requested reader/type/device/CNJ/XNB is valid. An existing malformed XNB still wins and fails
  instead of falling through to a displayed native or CNJ sibling.
- The scan is neither deterministic nor comprehensive. It uses exact lower-case `.xnb`/`.cnj`
  extension comparisons, leaves directory/native-extension order and both manifest/summary maps
  unsorted, records `.XNB` as a native extension, and gives dotless files an empty native
  extension. It exposes no status/error result or entry/depth/byte bound: an inaccessible root
  looks empty, iterator errors can leave a partial built scan, and every uncompressed XNB is read
  wholesale. Copy and sort the returned vector before retaining or reporting it; it is a const
  reference to manager-owned storage and a refresh invalidates element references/iterators.
- Reader names are available only for well-formed, uncompressed XNB tables. An unreadable,
  malformed, LZX, or currently unsupported LZ4 file still has `hasXnb` with an indistinguishable
  empty reader-name vector; normal LZX loading exists but compressed reader-name inventory remains
  unimplemented. The summary rereads global registration on each call, so a registration changes
  its boolean without a refresh, while file/table changes require one. That boolean remains only
  a factory-map-key test, not a callable-factory check.
- Ch.8 now makes the worked example an honest inventory and spells out its ordering, failure,
  compression, freshness, and lifetime limits. Full `latexmk` succeeded at **533 pages**;
  targeted undefined-reference and duplicate-label checks are empty; makeindex accepted **2,143**
  entries with zero rejected and zero warnings; `git diff --check` passes. Rendered physical pages
  **112--113** are clean. Ch.8 is now **804** lines. The plan-consistency validator remains
  absent from this checkout.

Next recommended start: keep the ContentManager scope and audit exact format-selection and
fallback behavior across generic and specialized loads. Distinguish literal filename, `.xnb`,
`.cnj`, and registered native-extension candidates; identify where a selected invalid candidate
prevents a lower-priority fallback; and do not repeat the completed root-confinement, cache-key,
or manifest work.

## Previous completed batch: ContentManager concurrency, reentrancy, and configuration-mutation boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
complete ContentManager mutable layout and load paths, manifest APIs, type-reader replacement
path, focused content tests, and current FNA manager source establish:

- CNA has no mutex, atomic guard, loading sentinel, or reader/writer synchronization around its
  asset/reader/factory/texture `unordered_map`s, manifest vector/flag, root string, raw pointers,
  or disposed flag. Any overlap involving a write—two cache-miss loads, Load versus Unload,
  registration, manifest refresh, or configuration/disposal—is a C++ data race and undefined
  behavior, not merely duplicate work. No located content test creates a thread or runs a race
  detector. FNA's current per-manager Load cache also has no manager-level lock; its similarly
  named lock protects only a static weak manager list.
- Reentrant calls have separate, sequential hazards. A nested same-key load has no provisional
  cache entry or cycle check, so it recurses until stack exhaustion. Reentrant `Unload()` clears
  immediately but an outer reader can write its result after returning; reentrant `Dispose()` can
  likewise allow the already-running call to return and cache a result despite the newly set guard.
  These calls are not cancellation barriers. A nested different asset can cache successfully even
  when its outer reader later fails.
- `Load<T>()` does not retain a local shared pointer to its selected loose reader. If that reader
  invokes `RegisterTypeReader<T>` for its own type, map replacement can destroy the active reader
  during its `Read()` member function: a single-threaded lifetime hazard, not a supported reader
  hot swap. Finish registrations/configuration before loading; serialize mutable manager use;
  keep recursive references acyclic; and publish completed values to workers rather than sharing
  the manager as a concurrent cache. A naive non-recursive external mutex can deadlock legitimate
  nested loads and cannot solve self-replacement.
- Ch.8 now gives the source-established ownership discipline. Full `latexmk` succeeded at
  **531 pages**; targeted undefined-reference and duplicate-label checks are empty; makeindex
  accepted **2,143** entries with zero rejected and zero warnings; `git diff --check` passes.
  Rendered physical pages **108--109** are clean. Ch.8 is now **758** lines. The
  plan-consistency validator remains absent from this checkout.

Next recommended start: keep the ContentManager scope and audit the NOXNA content-manifest
introspection APIs. Trace scan ordering, duplicate and extension treatment, malformed/unreadable
XNB behavior, compression inventory, root/error behavior, reader-usage summary freshness, and
returned-reference lifetime before expanding the manifest worked example's limits.

## Previous completed batch: ContentManager `Load<T>()` failure, type, and cache-mutation boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The live
generic and specialized Load paths, XNB `ContentReader` dispatch, content reader/manager tests,
native-image and Song companion-file tests, and current FNA `ContentManager` establish:

- CNA deliberately uses `ContentLoadException` for many validated content failures (missing/null
  readers, malformed or unsupported XNB, unregistered/unsupported XNB readers, bad CNJ, wrong
  CNJ type), but not as a universal `Load<T>()` wrapper. A disposed manager throws
  `std::runtime_error`; an empty asset name is not proactively rejected. A direct or CNJ-mediated
  missing native image propagates its `std::runtime_error`; an XNB Song with an unresolvable
  companion media file propagates `System::IO::FileNotFoundException`; custom loose/CNJ readers
  likewise propagate their own exceptions. Root-object type mismatch can yield
  `std::bad_any_cast`, and a truncated payload can yield `System::IO::EndOfStreamException`.
- The generic cache write happens only after its XNB or loose reader returns successfully, and
  Texture2D likewise writes its weak entry only after success; a failed top-level attempt does
  not cache the requested generic asset, so the next call retries it. SoundEffect and TextureCube
  do not have manager cache entries. This is not a multi-asset transaction: reader code can cache
  nested assets before later failing, and an expired Texture2D weak entry is removed before an
  attempted replacement read. There is no loading sentinel, rollback, or cycle detection.
- Current FNA instead rejects null/empty names with `ArgumentNullException` and disposed managers
  with `ObjectDisposedException` before looking up its cache. CNA's located integration tests
  cover malformed XNB, known CNJ errors, native-image propagation, and Song companion-file
  propagation, but not empty names, root-type mismatch, callback throws, or failed-load retry.
- Ch.8 now provides an explicit two-tier catch pattern and records the precise distinction. Full
  `latexmk` succeeded at **531 pages**; targeted undefined-reference and duplicate-label checks
  are empty; makeindex accepted **2,143** entries with zero rejected and zero warnings;
  `git diff --check` passes. Rendered physical pages **107--108** are clean. Ch.8 is now
  **706** lines. The plan-consistency validator remains absent from this checkout.

Next recommended start: keep the ContentManager scope and audit concurrency, reentrancy, and
configuration mutation. Trace concurrent `Load`/`Unload`/registration/root changes, nested same-key
loads, the absence or presence of synchronization, reader lifetime during replacement, and FNA's
corresponding synchronization before adding only source-established thread-safety guidance.

## Previous completed batch: ContentManager root, asset path, and cache-key boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The live
path helpers and all Load specializations, root setter/manifest, CNJ and XNB nested-reference
paths, relevant focused tests, a C++ filesystem join probe, and current FNA ContentManager
establish:

- `RootDirectory` is a base, not a sandbox. General CNA `Load()` accepts `..` and absolute asset
  names; native symlinks are not contained. An absolute right operand replaces the base, and no
  general canonical-path check occurs. FNA likewise allows a rooted root and raw caller-name
  fallback, so strict root confinement is not an XNA/FNA promise. Untrusted names require an
  application-level relative/canonical allow-list.
- Cache normalization is textual only: backslashes become slashes and all characters lowercase;
  the key excludes the root and does not collapse dot segments. Equivalent physical aliases can
  cache separately, case-distinct files can collapse to one first-wins entry, and changing root
  then loading the same generic/Texture2D name returns the old cache until `Unload()`. The root
  setter also leaves the old lazy content manifest intact until `RefreshContentManifest()`.
- CNJ `sourceFile` is deliberately safer: it rejects absolute paths, traversal, symlink escape,
  chaining, and implicit sidecar cycles through weakly-canonical checks, and focused tests cover
  them. XNB `ReadExternalReference<T>()` rejects a relative escape but does not reject an absolute
  reference before passing it to general Load; its tests omit that bypass. Song and Video XNB
  readers perform no root check for their embedded media references, so traversal and absolute
  paths can leave the root there too.
- Ch.8 now separates these mechanisms and documents the root-switch/cache example. Validation:
  incremental `latexmk` succeeded at **529 pages**; targeted undefined-reference and
  duplicate-label checks are empty; makeindex accepted **2,142** entries with zero rejected and
  zero warnings; `git diff --check` passes. Rendered physical pages **105--106** are clean. Ch.8
  is now **642** lines. The plan-consistency validator remains absent from this checkout.

Next recommended start: retain the ContentManager scope and audit its error and type boundary.
Trace empty/malformed asset names, missing files, reader/type mismatches, `.xnb` root-object
casts, exceptions from loader callbacks, cache mutation after failures, and comparison with FNA's
`Load<T>()` diagnostics before expanding the chapter's failure-contract guidance.

## Previous completed batch: ContentManager reader-registration ownership and scope

No CNA source changes were made; the sibling repository remained a read-only authority. The live
ContentManager registration templates, builtin loaders, XNB reader dispatch and static registry,
the startup helper, custom/CNJ/registry tests, copy/cache behavior, history, and current FNA
manager establish:

- Corrected a prior Ch.8 error: `RegisterTypeReader<T>()` is a per-ContentManager loose-file/CNJ
  table and cannot register an XNB reader. XNB wins before that table is examined; its reader names
  dispatch through the process-wide `ContentTypeReaderManager`. Since CNA lacks FNA's reflection
  fallback, an application must explicitly call
  `CNA::Internal::Xnb::RegisterAllBuiltInXnbReaders()` before XNB loads, plus global
  `AddTypeCreator()` registrations for its own canonical reader names. Neither ContentManager nor
  Game calls the umbrella helper. Its built-in family set deliberately excludes arbitrary closed
  generic collection readers.
- The global creator map keeps the first factory for a name, makes a fresh reader per XNB file,
  and `ClearTypeCreators()` erases every family process-wide. It has no synchronization or
  validation for empty inputs: the manifest test registers a null factory and observes
  `IsRegistered()` true, but `CreateReader()` would invoke the empty `std::function`. Tests cover
  fresh creations, first-wins registration, clear, builtin umbrella completeness, and a fully
  custom XNB round trip, but not this bad-factory execution or concurrency.
- Per-manager `RegisterTypeReader<T>()` silently overwrites an existing reader pointer, accepts
  null, and does not evict a matching generic asset cache entry. `RegisterCnjLoader<T>()` instead
  makes its generic reader once and rejects empty/duplicate names, empty factories, and an already
  non-generic reader. If a later RegisterTypeReader override replaces its generated reader, CNA
  retains named factories that are now unreachable and can accept more unreachable names; no
  located test covers this unsupported layering. ContentManager copies share loose-reader pointers
  and copy named-CNJ factories.
- Ch.8 now gives the actual startup/custom-XNB code pattern and distinguishes these registration
  planes from FNA's reflection-capable manager. Validation: incremental `latexmk` succeeded at
  **529 pages**; targeted undefined-reference and duplicate-label checks are empty; makeindex
  accepted **2,142** entries with zero rejected and zero warnings; `git diff --check` passes.
  Rendered physical pages **103--105** are clean. Ch.8 is now **576** lines. The plan-consistency
  validator remains absent from this checkout.

The root/path recommendation from this batch has been completed by the newer audit above.

## Previous completed batch: ContentManager service-provider and graphics-device resolution

No CNA source changes were made; the sibling repository remained a read-only authority. The live
ContentManager constructors and all provider/device uses, GPU/no-device tests, Game's default
construction, `GameServiceContainer`, `ResourceContentManager`, relevant history, and current FNA
source establish:

- CNA's `ContentManager(IServiceProvider*)` overloads only store the raw provider pointer, retain
  the `"Content"` field default unless another root is supplied, and register readers.
  `getServiceProviderProperty()` only returns the stored address. There is no
  `IServiceProvider::GetService()` call anywhere in ContentManager, so adding an
  `IGraphicsDeviceService` to a `GameServiceContainer` cannot configure a manager. The header's
  claim that this provider resolves graphics and other services is stale.
- Null is accepted; much of the parser-only test suite deliberately constructs
  `ContentManager(nullptr, root)`. A GPU-backed load instead needs a prior explicit
  `setGraphicsDevice()`. The Video XNB test pair proves this boundary: attaching the device
  succeeds, while an otherwise equivalent no-device load throws `ContentLoadException`. No
  located test passes a non-null provider or checks provider lookup.
- FNA rejects a null provider and, only when it first needs a device, requests
  `IGraphicsDeviceService` from `ServiceProvider`, caching its device or throwing a named
  `ContentLoadException`. CNA Game works because it default-constructs `Content_` and immediately
  attaches `GraphicsDevice_`; its Services container is not passed to Content. The
  provider-taking ResourceContentManager takes the same passive base path and remains an
  embedded-resource-stream stub.
- Ch.8 now gives the correct standalone pattern: a service container may be passed as retained
  metadata, but `setGraphicsDevice(device)` is separately mandatory before a GPU-backed load and
  the device must outlive that use. This is source-established behavior, not a runtime injection.
- Validation: incremental `latexmk` succeeded at **527 pages**; targeted undefined-reference and
  duplicate-label checks are empty; makeindex accepted **2,141** entries with zero rejected and
  zero warnings; `git diff --check` passes. Rendered physical pages **105--107** are clean. Ch.8
  is now **525** lines. The plan-consistency validator remains absent from this checkout.

The reader-registration recommendation from this batch has been completed by the newer audit
above.

## Previous completed batch: ContentManager copy assignment and `Game::Content` replacement

No CNA source changes were made; the sibling repository remained a read-only authority. The live
`Game` constructor/setter, `ContentManager` object layout and load paths, all setter call sites,
focused tests, and current FNA `Game` establish:

- `Game` constructs its own `Content_`, then attaches `GraphicsDevice_`. Its public
  `setContentProperty(const ContentManager&)` performs only `Content_ = value`. Because
  `ContentManager` declares no copy constructor or assignment operator, C++ memberwise-copies the
  root, disposed flag, manifest snapshot, generic cache, weak Texture2D entries, reader/loader
  tables, and raw graphics-device/service-provider addresses. This is a state snapshot, not
  replacement of one manager identity with another.
- Assigning a fresh standalone `ContentManager` replaces the game-configured device pointer with
  null; the next Texture2D or TextureCube load reaches `getGraphicsDeviceInternal()` and throws.
  A source manager configured for another device instead leaves the copied raw address dependent
  on that external device's lifetime. A disposed source transfers its guard and makes later loads
  fail. Reader-table shared pointers and cached values are copied as well.
- Current FNA's `Game.Content` rejects null and stores the supplied manager reference. It does not
  clone caches or raw device pointers, so CNA's C++ assignment is materially different even though
  the public property name resembles FNA. The reference parameter itself naturally excludes null
  in CNA, but it does not restore reference-replacement semantics.
- No CNA call site of this setter and no test covering manager copy, game-content replacement,
  assigned-device use, or disposed-manager assignment was found. Ch.8 now recommends configuring
  the game's existing manager in place for ordinary root changes and using a separate manager only
  when the caller deliberately owns its device and asset lifetimes.
- Validation: incremental `latexmk` succeeded at **527 pages**; targeted undefined-reference and
  duplicate-label checks are empty; makeindex accepted **2,141** entries with zero rejected and
  zero warnings; `git diff --check` passes. Rendered physical pages **106--107** are clean. Ch.8
  is now **479** lines. The plan-consistency validator remains absent from this checkout.

The service-provider recommendation from this batch has been completed by the newer audit above.

## Previous completed batch: ContentManager cache ownership and disposal boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The live
ContentManager header/source, its Texture2D/SoundEffect/TextureCube specializations, focused
tests, and the real avatar wardrobe-hotswap example establish:

- `Unload()` has exactly two actions: clear the generic `std::any` asset cache and the Texture2D
  weak-reference cache. It does not call a common Dispose method on returned assets and leaves
  reader registrations, root/device pointers, and the independent manifest snapshot intact.
  It is cache eviction, not universal invalidation of already returned values.
- The generic key is `(typeid(T), normalized logical name)`. Clearing it drops only the manager's
  stored copy, so an external shared_ptr keeps a shared model/effect alive. The hotswap demo uses
  this safely: it keeps its current model/renderer, evicts the lookup, and loads a fresh base
  model. `Texture2D` is distinct: its cache is weak from the beginning; retained copies keep the
  backend alive, but a post-Unload load creates a new backend. The focused real-XNB test proves
  exactly that.
- Move-only `SoundEffect` and `TextureCube` are never in either cache and every Load decodes an
  independent instance. SoundEffect's branch prevents a disposal cascade from one caller
  affecting another caller's playback.
- `Dispose()` calls `Unload()` then makes future `Load<T>()` calls throw; another `Unload()` does
  not clear that guard. The C++ destructor is defaulted rather than an implicit public Dispose.
  `GetContentManifest()` and `RefreshContentManifest()` are independent diagnostics: an unload
  leaves the old scan intact, and neither checks the disposed flag in current source.
- The tests prove generic-XNB reload after cache eviction and weak-Texture2D eviction with the
  first texture retained. They do not cover manager destruction, post-disposal Load, or a general
  cross-type shutdown protocol. Ch.8 corrects its formerly over-broad Unload comment and adds the
  exact cache/lifetime contract.
- Validation: incremental `latexmk` succeeded at **525 pages**; target undefined-reference and
  duplicate-label checks are empty; makeindex accepted **2,140** entries with zero rejected and
  zero warnings; `git diff --check` passes. Rendered physical pages **105--106** are clean. Ch.8
  is now **433** lines. The plan-consistency validator remains absent from this checkout.

The copy/assignment recommendation from this batch has been completed by the newer audit above.

## Previous completed batch: Game exit, disposal, destructor, and component lifetime

No CNA source changes were made; the sibling repository remained a read-only authority. The live
`Game`, component/collection, SDL gamepad, and focused test sources, the current FNA `Game`, and
the relevant history establish:

- On desktop, `Exit()` only clears `RunApplication` and suppresses the current tick's draw.
  `RunLoop()` delivers `Exiting` after its loop has ended and before `Run()` reaches `EndRun()` and
  `AfterLoop()`. `RunOneFrame()` does not invoke any of those run-boundary hooks or the event.
  `Run()` does not reset the public flag, so a second call after exit has zero ticks but still takes
  the desktop exit-notification path. The browser callback likewise raises only after it observes
  the false flag and cancels its loop.
- Explicit `Game::Dispose()` is materially different from ordinary scope destruction. Its true
  path disposes current disposable components, ContentManager, a cached graphics service, and the
  SDL gamepad subsystem; then it sets the flag and the public wrapper raises `Disposed`. The
  destructor calls only `Dispose(false)`, then audio shutdown, before normal member destruction.
  It skips that explicit cleanup path, and ContentManager's defaulted destructor is not a public
  `Dispose()` call. The current gamepad shutdown call site is only the true path.
- An automatically destroyed `DrawableGameComponent` also does not dispatch its own protected
  `Dispose(false)`/`UnloadContent()` override: C++ virtual dispatch from the later
  `GameComponent` base destructor resolves to the base implementation. Explicit component or Game
  disposal is consequently the only located route to that drawable hook.
- A throw during Game's true cleanup aborts the rest, leaves the disposed flag false, and prevents
  the public event. Conversely, the public wrapper raises `Disposed` even after the protected call
  returns for an already disposed object; repeated public disposal repeats the event and a handler
  which disposes the game recurses. The wrapper is shaped the same way in current FNA. No located
  CNA Game test covers destruction, repeated disposal, exceptions, or re-entrancy.
- After initialization Game stores raw-this order-change callbacks in every component and removes
  them only from `OnComponentRemoved`. `Game::Dispose()` does not remove collection items/tokens,
  and the collection's implicit destructor emits no removal events. An independently owned
  component can therefore notify a still-live disposed Game, or notify a dangling Game after it
  outlives Game destruction. The chapter's member-component example now calls `Remove()` in its
  derived destructor body; this corrects the prior false C++ claim that a derived member outlives
  the base Game collection. The standalone collection tests and direct gamepad-helper test do not
  exercise this integration boundary.
- Ch.6 now documents the lifecycle event order, the explicit/destructor distinction, exception and
  re-entrancy caveats, and the safe raw-component RAII pattern. Validation: incremental `latexmk`
  succeeded at **525 pages**; target undefined-reference/duplicate-label checks are empty;
  makeindex accepted **2,136** entries with zero rejected and zero warnings; `git diff --check`
  passes. No new Ch.6 overfull box was introduced. Rendered physical pages **58--59** and **63**
  are clean. Ch.6 is now **619** lines.
- The historical plan-consistency command remains unavailable: no
  `test/validate_plan_consistency.py` or replacement validator exists in this checkout.

Next recommended start: continue the now-focused ownership audit with `ContentManager` itself:
trace cache ownership and `Unload()`/`Dispose()`/ordinary destruction through the loaded asset
types, then document only behavior established by current source and tests. Keep it separate from
the completed Game component-token conclusion.

## Previous completed batch: GraphicsDeviceManager resize callback and disposal boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
current GraphicsDeviceManager, Game, GameWindow, EventHandler, focused real-window-resize
example, empty manager unit file, Git history, and bundled FNA reference establish:

- Manager construction registers two type-keyed services and also appends a raw-this lambda to
  GameWindow::ClientSizeChanged. It refreshes the viewport after either Game's SDL resize-event
  route or a manager EndScreenDeviceChange(). The registered EasyGL real-window-resize test proves
  the public window event, but not this callback's necessity because Present() separately refreshes
  the viewport every frame.
- The event runtime already provides Add() tokens and Remove(token), but this registration uses
  operator+= and discards the token. unregisterServices() removes only the two map entries. Thus
  an explicitly disposed but still-live manager continues to receive resize callbacks; a
  replacement manager is permitted while that stale listener remains. Destroying the old manager
  before its still-live game then leaves a lambda with a dangling this, invoked on the next resize.
  The usual derived-member destruction order avoids a resize after the member dies, but it does not
  make early reset/replacement safe.
- FNA currently has the same-looking no-unsubscribe registration, but its C# delegate keeps the
  target object alive. CNA's raw capture does not, changing an otherwise retained-object issue
  into possible native use-after-free. No located test destroys/replaces a manager and resizes its
  game afterward.
- ownsGraphicsDevice_ starts false and every current assignment writes false, so both
  DeviceDisposing call sites are unreachable in the game-attached topology. An explicit
  Game::Dispose() after normal initialization disposes the manager service, but not the game-owned
  device and not through DeviceDisposing. Game::UnloadContent() has no call site and no
  service-event subscription in current source; DrawableGameComponent's own
  Dispose(bool)/UnloadContent() route remains separate.
- The manager sets disposed_ only after raising Disposed: a re-entrant Dispose() handler recurses
  and a throwing one leaves it false. The resize callback also ignores that flag. An older
  reachable history commit (ebf75803) claimed the FNA-style device-event/Game subscriptions were
  wired, but HEAD lacks them; the book deliberately documents the live implementation, not the
  historical commit message.
- Ch.6 now warns that Game-level UnloadContent() is not automatic; Ch.9 documents resize callback
  lifetime, the unreachable teardown event, and disposal re-entrancy. This is source-established
  behavior, not failure-injection or a runtime UAF reproduction.
- Validation: incremental latexmk succeeded at **523 pages**; targeted undefined-reference and
  duplicate-label checks are empty; makeindex accepted **2,132** entries with zero rejected and
  zero warnings; git diff --check passes. All drafting overfull boxes were removed. Rendered
  physical pages 58 and 115--116 are clean. Ch.6 and Ch.9 are now **527** and **1,513** lines;
  Ch.9 spans printed pages **88--115** (28 pages).
- The historical plan-consistency command cannot currently run: this repository has no
  `test/validate_plan_consistency.py` file. This is an absent validator, not a validation failure
  caused by the documentation batch.

Next recommended start: audit Game's own disposal/destructor, Disposed/Exiting event ordering, and
component/content teardown after the newly established fact that Game::UnloadContent() is not
framework-invoked. Keep normal member destruction separate from explicit Game::Dispose() and from
the manager's independent lifetime.

## Previous completed batch: Game/GraphicsDeviceManager lifecycle and event boundary

No CNA source changes were made; the sibling repository remained a read-only authority. The
`Game` and `GraphicsDeviceManager` implementations, event runtime, focused examples/CMake
registrations, unit-test coverage, Git history, and bundled FNA reference establish:

- CNA's standard C++ `Game` topology differs from FNA's manager-owned construction. `Game`
  default-constructs its `GraphicsDevice_` before a derived game constructs its manager; the
  manager only registers services, then `Game::DoInitialize()` calls `CreateDevice()` to apply
  its first settings through `Reset()` on that same object. The book's previous claims that the
  manager creates/owns a device and that a derived constructor has no backend were stale.
- Startup raises the manager's `PreparingDeviceSettings` and then `DeviceCreated`, but not its
  manager-level resetting/reset pair. A later preference-changing `ApplyChanges()` instead
  orders manager `DeviceResetting`, device `DeviceResetting`, device `DeviceReset`, and manager
  `DeviceReset`, after preparing the candidate and performing the window transition. These are
  distinct subscriptions: CNA never forwards a device's events into `IGraphicsDeviceService`, so
  direct `GraphicsDevice::Reset()` reaches only device listeners.
- `PreparingDeviceSettings` mutates only the one local candidate record. Its edits reach the
  current reset but never become manager preference fields; its handler must reproduce an intended
  override on each invocation. There is no post-handler adapter validation, so replacing the
  default non-null pointer with null reaches a later dereference.
- Event handlers run without exception containment or an `ApplyChanges()` re-entrancy guard.
  A throw before the last manager event leaves the dirty flag set; a throw from that last event
  repeats an already-successful reset next time. A preference assignment from a lifecycle handler
  is similarly erased by the outer call's final dirty-flag clear. These outcomes are
  source-established, not injected runtime reproductions.
- The sole registered manager event program proves only manager resetting-before-reset after an
  explicit EasyGL width change; its statement that the constructor implicitly applies settings is
  stale, though subscribing in `Initialize()` still excludes startup. The SDL Renderer program
  proves the separate direct-device pair. The unit file has no live manager test; no located test
  covers startup routing, both subscriptions, preparing-event persistence, listener exceptions,
  or re-entrancy.
- Ch.5/6 correct the ownership/constructor wording, the unusable selection virtuals, and
  `DrawableGameComponent`'s false implied service subscription; Ch.9 documents the complete
  event order, transient settings record, failure behavior, and evidence boundary.
- Validation: incremental `latexmk` succeeded at **523 pages**; targeted undefined-reference
  and duplicate-label checks are empty; makeindex accepted **2,124** entries with zero rejected
  and zero warnings; `git diff --check` passes. All newly introduced manager-audit overfull boxes
  were removed. Physical pages 50, 60, 63--64, and 114--115 were rendered and are clean. Ch.5,
  Ch.6, and Ch.9 are now **379**, **518**, and **1,449** lines; Ch.9 spans printed pages
  **87--114** (28 pages).

Next recommended start: trace `GraphicsDeviceManager` registration/disposal against
`GameWindow::ClientSizeChanged`. The manager adds a lambda capturing `this` but its service
unregistration does not visibly remove that listener; determine its token/lifetime behavior,
whether deleting a manager while its game stays alive can leave a dangling callback, and how
manager/game/device disposal events interact. Keep that audit separate from the completed reset
ordering work.

## Previous completed batch: multisample backend rebuild and failure state

No CNA source changes were made; the sibling repository remained a read-only authority. The
legacy hook, the normal `GraphicsDeviceManager` route, all direct callers, their registrations,
and the current backend interface establish:

- Runtime `GraphicsDeviceManager::ApplyChanges()` does reach `GraphicsDevice::Reset()` and the
  backend's in-place `ApplyMultiSampleCount()` hook. That normal path records the actual clamped
  count in `PresentationParameters`; the older `RecreateBackendForMultiSampleCount(int)` header
  assertion that the manager has no reset path is stale.
- The legacy hook instead first destroys `backend_`, constructs a replacement, and only then asks
  the viewport helper to run. Its three remaining callers are focused Vulkan programs, all during
  `Initialize()` before their first `SpriteBatch`, texture, or render target. They demonstrate
  successful Vulkan rendering only; they do not exercise state, resources, events, clamping, or
  a failed replacement.
- Its ``before resources'' restriction is prose, not enforcement: it neither inspects the
  resource vector nor raises `DeviceResetting`/`DeviceReset`. It also does not reapply the stored
  blend/depth/rasterizer, sampler, vertex/index, effect, blend-factor, stencil, or custom
  viewport/scissor state. Same-size replacement commonly leaves the new backend without an
  explicit viewport update because the old backend's dimensions are remembered. Unlike normal
  Reset, the requested count is stored before construction but the actual clamped result is never
  written back.
- If replacement construction throws, the previous backend is already gone, the new requested
  presentation value remains, and `GetBackend()`/`SupportsCapability()` throw with a null backend.
  Ordinary `Reset()` still emits its events but skips backend work in that state; only another
  successful legacy rebuild can restore a backend. This is a source-established recovery hole,
  not an injected failure reproduction.
- Ch.9 records the corrected routing, unsafe legacy contract, state omissions, failure outcome,
  and narrow proof boundary. Incremental `latexmk` succeeded at **521 pages**; targeted
  undefined-reference and duplicate-label checks are empty; makeindex accepted **2,124** entries
  with zero rejected and zero warnings; `git diff --check` passes. One initially introduced
  overfull box was removed. Physical pages 124--125 (printed 102--103) were rendered and are
  clean. Ch.9 is now **1,393** lines and remains printed pages **87--112**.

Next recommended start: trace the `GraphicsDeviceManager` event/lifecycle layer around
`ApplyChanges()`: determine whether its `DeviceResetting`/`DeviceReset` notifications forward or
duplicate device notifications, their state observations and failure behavior, and the exact
cross-backend test evidence. Keep it separate from the completed device-level Reset audit.

## Previous completed batch: construction defaults, rollback, and SDL video ownership

No CNA source changes were made; the sibling repository remained a read-only authority.
The constructor path, focused Headless/Software/D3D12 examples, generic pixel-test preflight,
and current SDL3 documentation establish:

- The parameterless `GraphicsDevice()` is a convenience delegation, not a general headless
  constructor. It is windowless only in compile-time Headless/Software builds. Elsewhere the
  default `HeadlessEXT` is false and it initializes video and creates the standard default window;
  a no-window D3D12 device requires the three-argument form with `HeadlessEXT=true`.
- SDL video initialization is reference-counted and must be paired once per successful init. CNA
  skips that init for compile-time Headless/Software and runtime `HeadlessEXT`, but always issues
  the video quit in `Dispose()`. A headless device can therefore release the last video reference
  held by a live normal device or another SDL client. Existing Headless/Software smoke tests only
  prove absence during the device lifetime; D3D12 proves construction without a window. None
  checks reference state after disposal or the mixed-device case.
- Construction is not rollback-safe after a successful video init. `SDL_CreateWindow`, window
  sizing, backend creation, or default-state application may throw. Member-owned backends unwind,
  but the raw owned window, published text/mouse window handles, and this device's video reference
  do not: a C++ destructor is not run for a failed constructor. The pixel-test preflight only
  detects a completely unavailable display before construction and injects no later failure.
- Ch.9 corrects the parameterless-constructor claim and records both ownership defects, the
  test boundaries, and the official SDL3 reference-count rule. This is source-established, not
  an injected runtime reproduction; the sibling source was not modified.
- Validation: incremental `latexmk` succeeded at **521 pages**; targeted undefined-reference
  and duplicate-label checks are empty; makeindex accepted **2,123** entries with zero rejected
  and zero warnings; `git diff --check` passes. The one overfull box introduced while drafting
  was removed. Current physical pages 110--111 (printed 88--89) and 126--127 (printed 104--105)
  were rendered and are clean. Ch.9 is now **1,373** lines and spans printed pages **87--112**.

Next recommended start: trace `RecreateBackendForMultiSampleCount()` and the reset-side backend
replacement path. It first destroys the current backend and then constructs a replacement, so
determine whether a failed replacement leaves a device that is safely recoverable, how state is
reapplied, and which focused tests actually prove it.

## Previous completed batch: resource registration, events, and disposal

No CNA source changes were made; the sibling repository remained a read-only authority.
The implementation, focused examples/CMake registration, and current FNA source establish:

- `ResourceCreated` is raised from the `GraphicsResource` base constructor, before a derived
  texture, buffer, or effect has constructed its backend handle. `ResourceDestroyed` follows
  a derived `Dispose(bool)` handle release but precedes base `IsDisposed` and raw-pointer
  deregistration; it carries a `Name`/`Tag` snapshot, not a resource pointer. Event handlers
  must therefore record lifecycle facts rather than inspect a usable backend.
- For ordinary, unbound resources, device disposal moves and clears the tracking vector,
  disposes the resources, then destroys the native context. The earlier book wording and the
  sibling `docs/graphics-resource-lifetime.md` were wrong about the destructor route:
  `Dispose(false)` suppresses only the resource's own `Disposing` event; it still emits the
  device `ResourceDestroyed` event and removes the resource pointer.
- Two untested public-state failures break that ordinary-order guarantee. A bound
  `RenderTarget2D` throws during device disposal after the tracking vector was moved/cleared,
  so the exception aborts backend teardown and a retry no longer tracks that target. Separately,
  `GraphicsDevice::IsDisposed` remains false while its `Disposing` handlers run, so a handler
  which calls `Dispose()` re-enters rather than being idempotently rejected. Current FNA sets
  the flag before its notification; no CNA test covers this re-entrant case.
- Default C++ move construction transfers a registered resource's backend without replacing
  the raw entry in the device vector. The existing EasyGL move test proves only backend-handle
  transfer with a live device, not device-first destruction or tracking/event correctness. Do
  not move an already registered resource; construct it in place or move it before registration.
- The existing event test proves explicit created/destroyed counts, `Name`/`Tag`, and
  double-dispose suppression. The device-order test owns only buffers and an ordinary texture;
  it does not exercise a bound render target. These boundaries are stated explicitly instead
  of being elevated into runtime proof.
- Ch.9 now carries the constructor/destructor timing, corrected finalizer behavior, the two
  teardown holes, and the precise move outcome. Its historical FNA-audit note now separates the
  stale “no tracking” claim from the still-true absence of a CNA per-resource reset callback;
  FNA's corresponding reset loop is itself currently commented out.
- Validation: incremental `latexmk` succeeded at **519 pages**; targeted undefined-reference
  and duplicate-label checks are empty; makeindex accepted **2,123** entries with zero rejected
  and zero warnings; `git diff --check` passes. The four overfull boxes introduced while
  drafting were removed. Rendered printed pages 103--104 are clean. Ch.9 is now **1,338** lines.

Next recommended start: reassess the remaining construction/failure paths of the public
`GraphicsDevice` lifecycle, beginning with SDL video-subsystem ownership and exception safety
between backend creation and a fully usable device. Keep resource-event conclusions limited to
the source/test evidence above.

## Previous completed batch: `GraphicsDevice::Reset()` event order

No CNA source changes were made; the sibling repository remained a read-only authority.
The implementation, focused examples/CMake registration, and current FNA source establish:

- CNA raises `DeviceResetting` before it copies the new presentation parameters or changes a
  non-null adapter. Its handler therefore observes the old settings; `DeviceReset` observes
  the new settings after any backend MSAA clamp. FNA assigns parameters/adapter and clamps MSAA
  before `DeviceResetting`, then issues one native backbuffer reset and restores both default
  rectangles.
- CNA has no equivalent universal backend-reset operation. It runs SDL window changes, virtual
  resolution, MSAA, swap-interval, and presentation-format hooks, then asks the backend for
  viewport dimensions. A final `DeviceReset` only means this shared route returned; it does not
  prove acceptance of fullscreen, format, or timing requests.
- Evidence is deliberately narrow. The registered SDL Renderer event program proves one event
  of each kind, their order, and the 32-to-64 old/new parameter observations. The reusable
  resize test is registered on EasyGL, Vulkan, and BGFX and proves only a custom viewport's
  eventual full-size restoration after an actual resize. It does not prove same-size behavior,
  scissor reset, adapter replacement, or native presentation acceptance.
- Ch.9 now carries the staged ordering, the FNA contrast and direct source URL, test boundary,
  and cross-reference to the existing same-size viewport/scissor limitation. Its actual printed
  span is pages 87--110 (24 pages), correcting the stale 31-page plan figure.
- Validation: incremental `latexmk` succeeded at **519 pages**; targeted undefined-reference
  and duplicate-label checks are empty; makeindex accepted **2,119** entries with zero rejected
  and zero warnings; `git diff --check` passes. Rendered printed pages 91--92 are clean. The
  32-line addition introduced no overfull box; Ch.9 is now 1,294 lines.

Next recommended start: continue the remaining public `GraphicsDevice` audit with resource
registration/disposal and the six lifecycle events. First trace the internal resource vector,
`OnResourceCreated`/`OnResourceDestroyed`, re-entrant `Dispose()`, and backend/window teardown
against FNA and actual tests; do not conflate its event delivery with a native device-loss reset.

## Previous completed batch: render-target binding and `RenderTargetUsage`

No CNA source changes were made; the sibling repository remained a read-only authority.
Findings were verified against the live shared source, all fourteen backend implementations,
focused tests and plans, Git history, and current FNA source:

- CNA has three separate public binding implementations rather than FNA's one unified route.
  Rebinding the identical 2D target, cube face, MRT set, or already-active backbuffer is not
  detected as redundant. Every call resets viewport/scissor; a repeated
  `DiscardContents` 2D bind also requests another implicit clear. Some backends additionally
  resolve/regenerate/unbind and rebind the same resource. Current FNA applies sampler/
  rasterizer state first, then returns early for an identical binding set.
- The singular 2D path retains a binding and clears black on exact `DiscardContents`, but asks
  only for target plus optional depth, never stencil. The singular cube path retains neither
  cube pointer nor face and performs no usage-dependent clear. Thus `GetRenderTargets()` is
  empty while a cube is bound even though `Present()` still throws through the separate
  Boolean.
- The plural path accepts `RenderTargetBinding(Texture*, CubeMapFace)` publicly but converts
  only `RenderTarget2D`; every cube binding becomes a null backend entry. Depending on the
  selected product this binds a backbuffer/no target, throws, or dereferences null. FNA stores
  and binds cube entries normally.
- `PresentationParameters.RenderTargetUsage` is stored, cloned, and exposed but never used
  when returning to the backbuffer. `RenderTarget2D` passes only
  `usage == PreserveContents` to the backend, while shared bind-time clearing tests only
  `usage == DiscardContents`. Consequently `PlatformContents` is split: most immediate
  backends preserve because shared code does not clear, but Vulkan/WebGPU receive “not
  preserve” and discard; BGFX can inherit persistent view-clear state. FNA passes every
  non-discard usage as the native preserve request.
- `RenderTargetCube` cannot pass any usage to its backend because
  `CreateRenderTargetCube` has no preserve argument. Vulkan and WebGPU therefore discard every
  cube-face pass; SDL GPU and immediate persistent-resource implementations generally load/
  retain content because the shared cube path issues no implicit clear. No test covers cube
  usage, `PlatformContents`, backbuffer usage, redundant binding, plural cube binding, or
  implicit stencil discard.
- Existing evidence is strongest only for non-MSAA 2D colour: SDL Renderer and EasyGL have
  discriminating pixel readback, Vulkan has a two-frame partial-draw pixel test, and BGFX has
  smoke/no-crash coverage only. Vulkan's preserve pass loads colour but discards depth/stencil,
  and Preserve+MSAA plus all Vulkan MRT/cube passes use discard-shaped render passes. WebGPU
  preserves all three 2D attachments when requested but always discards cube faces. SDL GPU's
  per-attachment pending load ops make 2D preserve/discard work through the shared clear, while
  cube usage is effectively preserve-like for every enum value.

- Ch.9 now distinguishes CNA's unconditional bind/reset work from FNA's identity fast path;
  Ch.11 documents the three enum values and their actual backend split; Ch.16 adds the
  complete fourteen-product matrix; Ch.17--25 carry backend-local qualifications; and
  Appendices A/B add the portability warning and a deliberately narrow feature-grid row.
- Final validation: forced and subsequent incremental `latexmk` builds produce **519 pages**;
  targeted undefined-reference and multiply-defined-label checks are empty; makeindex accepts
  **2,119 entries** with zero rejected and zero warnings; `git diff --check` passes. Rendered
  physical pages 114--115, 149, 205--207, 219, 226, 236, 243, 257, 265--266, 283--284, 293,
  299, 481--482, and 489 have no clipping, cell collision, page-edge spill, malformed heading,
  running-header collision, or folio defect. The new longtable header repeats correctly. The
  complete set of 492 pre-existing overfull warnings is unchanged from the clean reference
  build; the eight warnings introduced while drafting were removed.
- Exact line counts: Ch.9 1,262; Ch.11 572; Ch.16 1,842; Ch.17 417; Ch.18 400; Ch.19 512;
  Ch.20 424; Ch.21 368; Ch.22 554; Ch.23 888; Ch.24 378; Ch.25 322; Appendix A 410;
  Appendix B 185.

Next recommended start: reassess the remaining public `GraphicsDevice` surface after this
commit, beginning with a source/test audit of construction and reset-default behavior rather
than revisiting the now-closed Clear, viewport/scissor, presentation, or render-target contracts.

## Previous completed batch: `GraphicsDevice::Clear` / `ClearOptions`

No CNA source changes were made; the sibling repository remained a read-only authority.
Findings were verified against the live shared source, backend implementations, tests,
Task 1113, and current FNA source:

- CNA's `Clear(Color)` now correctly requests `Target | DepthBuffer | Stencil`, uses the
  current viewport's `MaxDepth`, and therefore no longer matches Ch.9's stale “colour only”
  description. Conversely the NOXNA raw-float overload bypasses shared routing and is not
  equivalent to `Clear(Color)`: each backend receives only its plain `Clear(r,g,b,a)` hook.
- The shared full overload validates an out-of-range depth before target-capability masking,
  but only when `DepthBuffer` was requested. It derives one binary `hasRealDepthBuffer` value
  from the backbuffer or the first bound target, then dispatches the seven non-empty flag
  combinations. This is too coarse for XNA/FNA's real depth-format contract: FNA removes both
  depth and stencil for `DepthFormat::None`, and removes stencil alone for every format other
  than `Depth24Stencil8`.
- The binary mask creates two concrete CNA defects. `Depth16`/`Depth24` targets still receive
  a requested stencil clear. A singular `RenderTargetCube` is not retained in
  `currentRenderTargets_` at all, so the mask falls back to the backend-wide backbuffer answer
  and cannot see that cube's own `DepthFormat`; plural binding likewise recognizes only
  `RenderTarget2D`. Cube clears can therefore be forwarded for nonexistent attachments or
  suppressed according to unrelated backbuffer state rather than the active face.
- FNA settles Task 1113's alleged open policy question: a depth/stencil-only clear on a
  depthless active target is legal and becomes an empty, silent no-op. The SDL_Renderer audit
  and render-target-depth-decision tests still expect throws and are stale; their assertions
  fail before any backend `ThrowNo3D` hook can be reached because CNA's public mask follows the
  same no-op policy. Target-containing combinations still clear colour.
- Immediate backend behavior is not uniform. D3D11 selects the requested native views/flags
  exactly after shared routing. D3D9 also issues exact `D3DCLEAR_*` flags, but gates them with
  the presentation/backbuffer `depthStencilFormatOrdinal_` even while a custom target is bound;
  target format and backbuffer format can therefore disagree. D3D12's exact offscreen
  implementation still throws before a depth-only no-op if no colour resource is bound.
  EasyGL's supposedly colour-only hook includes `GL_DEPTH_BUFFER_BIT`, so `Target` and the raw
  float overload may clear depth too, and every GL clear remains scissor-sensitive.
- Deferred Vulkan and BGFX render passes/views unconditionally clear all existing
  colour/depth/stencil attachments at pass start, irrespective of the public option subset;
  their depth-only hooks also fail to begin/touch an otherwise empty pass. WebGPU and SDL GPU
  track independent pending flags (except discard/fresh-attachment clears), but still collapse
  multiple same-pass calls to final clear values before queued draws. Software has independent
  colour/depth storage but no real stencil. SDL Renderer, ASCII, Canvas, and DX3 mask
  depth/stencil away publicly; Headless records synthetic operations only.
- Existing proof is uneven. EasyGL tests public overload routing and depth-range validation;
  cross-frame EasyGL/BGFX/Vulkan tests prove real stencil values; the generic depth test proves
  the two colour+depth combinations but explicitly omits depth-only on Vulkan/BGFX. D3D9's smoke
  test calls all seven public combinations but its depth/stencil checks mostly prove colour is
  unchanged, while D3D12 has strong direct-backend depth/stencil readback proof rather than a
  shared-API test. No current test discriminates the shared cube-mask defect, the
  depth-without-stencil format rule, or deferred same-pass call ordering.

- Ch.9 now states the overload and active-format contract; Ch.11 corrects the stale Vulkan
  render-target ledger; Ch.14 narrows the stencil-mirror recommendation; Ch.16 carries the
  complete fourteen-product matrix; Ch.17--25 carry backend-local qualifications; Appendices
  A/B carry the portability warning and corrected compact capability row.
- Final validation: a forced full build and the subsequent incremental build produce **513
  pages**; targeted
  undefined-reference and multiply-defined-label checks are empty; makeindex accepts **2,103
  entries** with zero rejected and zero warnings; `git diff --check` passes. Rendered physical
  pages 112--113, 127--128, 147--148, 171, 203--205, 217, 227, 231--232, 239, 253--254,
  264--265, 274--275, 287, 293, 478, and 483 have no clipping, cell collision, page-edge
  spill, malformed heading, running-header collision, or folio defect. Pages 254 and 265 are
  intentional chapter-boundary blanks; the matrix header repeats correctly on both
  continuation pages. All overfull warnings introduced by the batch were removed.
- Exact line counts: Ch.9 1,220; Ch.11 526; Ch.14 353; Ch.16 1,697; Ch.17 413; Ch.18 396;
  Ch.19 503; Ch.20 414; Ch.21 360; Ch.22 538; Ch.23 871; Ch.24 367; Ch.25 318; Appendix A
  403; Appendix B 175.

## Previous completed batch: viewport and scissor contract

The public `GraphicsDevice.Viewport` / `ScissorRectangle` audit is complete:

- Both setters store the public value and immediately invoke `IGraphicsBackend::SetViewport`
  or `SetScissorRect`. `RasterizerState.ScissorTestEnable` is a separate switch delivered by
  `ApplyRasterizerState`; storing a rectangle must not by itself enable clipping.
- Construction obtains the initial full-window viewport, but unlike FNA it leaves CNA's
  initial public scissor rectangle at its default zero rectangle. Every actual 2D, cube, or
  MRT target switch later resets both public properties to the full dimensions of the new
  target (the first target for MRT), including the backbuffer on unbind. Ordinary
  `Present()` preserves a custom viewport unless the backend/window size truly changed.
- CNA's in-place `GraphicsDevice::Reset()` does not reproduce FNA's unconditional reset of
  both properties. It calls the size-change-sensitive `UpdateViewportFromWindow()` only:
  same-size reset preserves both custom values; a real size change eventually resets only
  the viewport, leaving the old scissor rectangle intact. The resize regression test checks
  viewport only, and its header still predates the now-real manager-to-`Reset()` routing.
- FNA is the reference contrast: its constructor initializes both properties to the
  presentation bounds, both setters immediately forward to FNA3D, `Reset()` restores both
  full-backbuffer rectangles, and each non-redundant `SetRenderTargets()` resets both to the
  first target or backbuffer dimensions.
- Real custom viewport and independently-enabled scissor behavior is pixel-proven on EasyGL.
  D3D11 and D3D9 issue immediate native calls; D3D11 has direct native state round-trip proof,
  while no viewport/scissor oracle scene exists in the current 39-scene D3D9 corpus despite
  `plan_dx9.md`'s stale statement that both are oracle-proven.
- The EasyGL statement needs a SpriteBatch qualifier: each SpriteBatch flush unconditionally
  restores a full physical-window or full-render-target GL viewport and does not restore the
  prior custom viewport. Thus the dedicated viewport test proves 3D, not SpriteBatch, and a
  SpriteBatch flush can leave native state disagreeing with the still-custom public property.
  EasyGL's scissor state is not similarly overwritten.
- Vulkan stores both values and samples them only when recording the backbuffer pass; custom
  render-target viewport/scissor values are replaced by full-target rectangles. WebGPU
  samples and clamps both once per backbuffer/2D-target/cube pass. Both therefore use the
  state current at deferred pass recording, not a per-queued-draw snapshot.
- BGFX applies an enabled, nonzero scissor before SpriteBatch and 3D submissions, but applies
  a custom viewport only to backbuffer 3D submissions; SpriteBatch and render-target views
  remain full-size, and viewport depth limits are ignored. Both public features have
  dedicated pixel tests.
- SDL GPU implements an independently-enabled scissor once per deferred pass for backbuffer,
  2D targets, and cube faces, with pixel proof, but has no viewport hook. SDL Renderer (and
  ASCII by delegation) has the opposite semantic defect: setting a nonzero rectangle
  immediately enables SDL clipping regardless of `ScissorTestEnable`, because the backend
  never consumes `RasterizerState`; neither implements a viewport hook.
- D3D12 inherits both empty hooks and explicitly programs full-target viewport/scissor state
  in every 3D and SpriteBatch command list. Software explicitly discards both, Canvas and DX3
  inherit both no-ops, and Headless only validates/traces them without rasterizing.
- Independently of the backend matrix, CNA's shared `SpriteBatch::Begin(...,
  RasterizerState*, ...)` ignores that argument completely. A caller cannot enable scissoring
  through the normal SpriteBatch parameter as in FNA; only an already-applied
  `GraphicsDevice.RasterizerState` can reach a capable backend, and the null/default Begin path
  also fails to restore FNA's default cull/scissor state. No dedicated test currently catches
  this cross-backend public-routing gap.
- Ch.9--11 and Ch.14 now state the shared property, lifecycle, render-target, and SpriteBatch
  consequences. Ch.16 contains the complete fourteen-product draw-time matrix; Ch.17--25 carry
  each applicable backend qualification; Appendix A has the concise portability warning and
  Appendix B now warns that its aggregate `RasterizerState` row is not field-level evidence.
- Final validation: a forced and subsequent incremental `latexmk` rebuild produces **509
  pages**; targeted undefined-reference and multiply-defined-label checks are empty; makeindex
  accepts **2,092 entries** with zero rejected and zero warnings; `git diff --check` passes.
  Rendered physical pages 111--112, 131, 147--148, 172, 203--205, 215, 222--223, 231, 244,
  250, 256, 269--270, 283, 289--290, 473--474, and 479 have no clipping, cell collision,
  edge spill, malformed heading, running-header collision, or folio defect. The matrix header
  repeats correctly and all overfull warnings introduced by this batch were removed.
- Exact line counts: Ch.9 1,211; Ch.10 530; Ch.11 523; Ch.14 353; Ch.16 1,556; Ch.17 411;
  Ch.18 379; Ch.19 496; Ch.20 402; Ch.21 344; Ch.22 525; Ch.23 849; Ch.24 358; Ch.25 306;
  Appendix A 396; Appendix B 171.

Next recommended start: select the next independent public `GraphicsDevice` contract whose
shared default is not already covered by a recent matrix, avoiding the actively moving
BlendState work in the sibling `feature/audit` worktree. Re-read the live sibling source,
tests, and plans before choosing; do not infer implementation status from old plan labels.

## Previous recovery/debug batch

The `SetContextRecoveryEnabled()`, `DebugSimulateContextLoss()` /
`DebugRestoreContext()`, and `SetStringMarkerEXT()` audit is complete:

- `GraphicsDevice::SetContextRecoveryEnabled()` always changes a framework-level flag used by
  `Texture2D::MaybeFreeCpuPixels()`, even when the backend hook is empty. The current Ch.9
  statement that it must run before device initialization is impossible literally: the device
  and backend already exist before the method can be called. The intended safe point, confirmed
  by the change's Git history, is after device construction but before game resources load.
- EasyGL additionally uses the hook to stop registering subsequently-created GL resources.
  Existing registrations/shadows are not retroactively normalized, so this is a creation/upload
  policy, not a reversible live migration. D3D9 changes the shared flag first and then throws
  `NotYetImplemented`; the other twelve products inherit the backend no-op while retaining the
  shared `Texture2D` memory/readback consequences.
- Every `Game::PollEvents()` reserves non-repeated F9/F10 key-down events for the two debug
  methods after input processing. EasyGL implements real context loss/restore (asynchronous
  separate events on Web; either key performs a complete synchronous loss+restore cycle on
  desktop). D3D9 uses the same keys for deterministic
  `DeviceLost`--`DeviceResetting`--`DeviceReset` event testing. The other twelve products
  silently do nothing.
- Vulkan alone implements a real marker, queued into its pending 3D/render-target stream and
  emitted only when `vkCmdInsertDebugUtilsLabelEXT` is available. D3D9 overrides the empty
  default with a loud `runtime_error`; the other twelve inherit silence. This corrects Ch.9's
  current “no-op on every other backend” overclaim. FNA exposes the same marker extension by
  forwarding it to FNA3D, but does not install CNA's global F9/F10 hooks.
- Ch.6 documents the global event-pump reservation, Ch.9 corrects all three public extension
  contracts and the stale legacy-MSAA rationale, Ch.16 contains the complete fourteen-product
  matrix, Ch.18/23/40 record the EasyGL/D3D9/Web boundaries, and Appendix E now indexes the
  extension family.
- Validation: a forced `latexmk -g` build produces **507 pages**; targeted undefined-
  reference and duplicate-label checks are empty; makeindex accepts **2,080 entries** with
  zero rejected and zero warnings; `git diff --check` passes. Rendered physical pages 58,
  121, 205--207, 218, 262, 410, and 489 have no clipping, cell collision, edge spill,
  malformed heading, running-header collision, or folio defect. All overfull warnings
  introduced by this batch were removed. Exact line counts: Ch.6 513; Ch.9 1,167; Ch.16
  1,433; Ch.18 362; Ch.23 824; Ch.40 247; Appendix E 227.
- The separate `feature/audit` CNA worktree is actively repairing omitted BlendState fields.
  Do not publish a new state-field gap matrix from `develop` while that unmerged work is
  moving; this completed recovery/debug cluster is independent of it.

## Previous presentation-format batch

The `PresentationParameters.BackBufferFormat` / `DepthStencilFormat` / `IsFullScreen` and
`IGraphicsBackend::UpdatePresentationFormatEXT()` audit is complete:

- `GraphicsDevice::Reset()` first stores the whole requested object, applies fullscreen and
  non-Android size to the SDL window, reapplies virtual resolution/MSAA/interval, and calls
  the presentation-format hook last. SDL fullscreen failure is cleared and non-fatal; size
  failure throws. Stored state therefore cannot be used as an actual window query.
- Only D3D9 overrides the otherwise-empty hook. It maps color/depth enums into real D3D9
  presentation parameters, sets `Windowed = !IsFullScreen`, and immediately resets the
  device. The smoke suite observes a real D24S8 surface after manager-driven setup. An
  unsupported combination can nevertheless fail after public requested state changed.
- The other thirteen products do not provide per-field runtime format selection. Their
  native results range from no attachments (the 2D-only and Headless products), through
  fixed CPU/DirectX/WebGPU formats, to driver/platform-selected SDL, GL, bgfx, Vulkan,
  SDL_gpu, or Canvas targets. Several allocate real depth even for public `None`; WebGPU
  can select an sRGB surface while public state reports `Color`.
- Fullscreen remains a separate SDL-window route for windowed products, even with an empty
  backend hook. D3D11/12 may acquire a fullscreen-sized SDL window but never call DXGI
  `SetFullscreenState`; DX3 remains at `DDSCL_NORMAL`. Software and Headless have no window.
- Eager `Game` construction starts with bare `Color`/`None`/windowed parameters before the
  manager's `Color`/`Depth24`/windowed defaults are applied. D3D9's hook upgrades the native
  device; the remaining products keep their independent attachment policies.
- Existing EasyGL depth/fullscreen and SDL Renderer fullscreen tests explicitly prove stored
  round-trip/no-throw/continued rendering, not native format or display acceptance. D3D9 is
  the strong native exception. No dedicated test was found that requests two different
  backbuffer formats and queries the resulting native formats. FNA instead submits one
  complete native presentation structure to `FNA3D_ResetBackbuffer`.
- Ch.6 and Ch.9 now explain the caller-visible requested/actual split. Ch.16 contains the
  complete fourteen-product color/depth/window/evidence matrix. Ch.17--23 and Ch.25 record
  the applicable native policy, Ch.21's stale Vulkan render-target comparison is corrected,
  and Appendix A carries the concise warning.
- Final validation: a forced `latexmk` rebuild produces **505 pages**; targeted undefined-
  reference and duplicate-label checks are empty; makeindex accepts **2,069 entries** with
  zero rejected and zero warnings; `git diff --check` passes and the recorded chapter counts
  match `wc -l`.
  Rendered pages 64, 113, 190--192, 209, 216, 227, 233, 243, 252, 264, 287, and 470 have no
  clipping, cell collision, page-edge spill, malformed heading, running-header collision, or
  folio defect. The matrix header repeats correctly on both continuation pages.

## Previous swap-interval batch

The `PresentationParameters.PresentationInterval` /
`IGraphicsBackend::SetSwapInterval()` audit is complete:

- The public conversion is exact (`Immediate` to 0, `Default`/`One` to 1, `Two` to 2).
  `GraphicsDeviceManager::SynchronizeWithVerticalRetrace` itself selects only `One` or
  `Immediate`; callers need explicit `PresentationParameters` or
  `PreparingDeviceSettings` to request `Two`.
- Both backend construction and the ordinary `GraphicsDevice::Reset()` path now receive the
  selected value. The latter forwarding was a real prior cross-backend repair, but the
  interface default is still a silent no-op.
- Nine products override the runtime hook: SDL_RENDERER, ASCII, EASYGL, BGFX, WEBGPU,
  SDL_GPU, and D3D9/11/12. VULKAN, CANVAS, DX3, SOFTWARE, and HEADLESS inherit the no-op.
  Vulkan uniquely consumes the initial construction value while ignoring later resets.
- The semantic split is wider than override/no-override: D3D9 maps interval 2 literally;
  SDL Renderer attempts it at runtime with a fallback to 1; EasyGL submits the exact value
  but ignores driver rejection. BGFX, WebGPU, SDL GPU, and D3D11/12 collapse every positive
  interval to ordinary VSync. SDL Renderer's constructor also collapses `Two`, even though
  its runtime handler no longer does. Vulkan's initial `Two` means FIFO_RELAXED, not
  half-refresh pacing.
- D3D9's exact mapping is incomplete and unsafe: it checks neither
  `D3DCAPS9::PresentationIntervals` nor the native rule that windowed mode supports only
  Default/Immediate/One. A rejected reset is logged and retried on every present while the
  public property remains `Two`. D3D11/12 could pass 2 directly because DXGI supports
  intervals 1--4; their Boolean collapse is CNA-imposed.
- Validation evidence is uneven. EasyGL proves real 0/positive context state for the public
  manager/reset path; SDL Renderer proves routing and stored parameters but has no public
  actual-state query. The SDL GPU suite's old roughly-one-second-per-frame virtual-display
  timeout demonstrates that public VSync selection affects real presentation, but no located
  test proves interval 2. Most other rows remain source-proven only.
- Ch.6 separates fixed timestep from presentation blocking; Ch.9 distinguishes requested
  from applied state; Ch.16 carries the complete fourteen-product construction/runtime/
  evidence matrix; Ch.17, Ch.19, Ch.23, and Appendix A now agree with it.

## Previous backbuffer-readback batch

The public `GraphicsDevice::GetBackBufferData()` /
`IGraphicsBackend::ReadBackbuffer()` audit is complete:

- Twelve of the fourteen backend products override the method. `SDL_GPU` and `D3D12` inherit
  the default `runtime_error`; neither public path has back-buffer readback.
- The name is not a uniform semantic contract. SDL_Renderer, ASCII, Software, EasyGL, DX3,
  and browser Canvas read the currently bound render target when one is active; Vulkan,
  BGFX, D3D11, WebGPU, and D3D9 always read the real swapchain/backbuffer; Headless returns
  only a synthetic image of the last global clear. FNA always routes to its actual
  backbuffer read API.
- The shared wrapper validates only `data != nullptr`, `elementCount >= width*height`, and
  the stored presentation format. It does not reject a negative `startIndex`, prove caller
  capacity through `startIndex + pixelCount`, validate the rectangle against the target,
  or guard `width*height` overflow. A null rectangle takes dimensions from
  `GetViewportSize()`, which several scaled/high-density backends do not express in the same
  coordinate space as their native readback.
- Exact-pixel proof is strongest where tests discriminate the source: Software and DX3 read
  bound target then restored backbuffer; Vulkan explicitly proves that it always reads the
  swapchain. ASCII returns its pre-quantized game target, not the displayed glyph grid.
  Canvas has no real browser/DOM proof; Headless has no dedicated public pixel assertion;
  D3D12's exact smoke readbacks call render-target helpers directly.
- Ch.9 now labels its worked bound-target probe as Software-specific and records all caller
  preconditions. Ch.16 carries the complete target/region/evidence matrix and FNA contrast;
  Ch.22 and Ch.23 distinguish resource readback from the missing SDL GPU/D3D12 public
  bridge; Appendix A has the concise warning.

## Previous input-coordinate batch

The logical/window input-coordinate audit is complete:

- `Mouse::SetPosition()` and `SdlInputBridge` first use an SDL renderer associated with the
  window, then the `IGraphicsBackend` registry, then raw pass-through. The two backend
  transform defaults return `false`.
- SDL_Renderer and ASCII use SDL's complete logical-presentation transform. DX3 unexpectedly
  uses the same route because `free-direct`'s supposedly private renderer remains discoverable
  through `SDL_GetRenderer(window)`; its dedicated test calls the backend methods directly and
  therefore does not prove public routing. Before DX3's first `Present()`, that renderer has
  not yet been assigned a logical presentation and public input is still pass-through.
- EasyGL and Canvas register height-only transforms that are exact for
  `FixedHeightDynamicWidth` but do not implement their other stored presentation modes.
  WebGPU and SDL GPU register the full five-mode viewport math in physical pixels, but SDL
  events and cursor warps use window coordinates. The two spaces differ on a high-pixel-density
  window, producing a density-factor error in both directions. They also return `false` for a
  point in a letterbox bar; the caller then substitutes raw window coordinates instead of the
  already-computed out-of-content logical coordinates.
- Vulkan inherits pass-through even though its SpriteBatch projection maps the virtual size
  across the physical swapchain, so resized/non-1:1 windows misalign absolute mouse/button/
  touch positions and `Mouse::SetPosition()`. BGFX and D3D9/11/12 also inherit pass-through,
  but currently ignore logical presentation and render in physical coordinates, making that
  fallback consistent with their separate presentation limitation. Software and Headless
  have no window.
- Existing proof is narrow: the SDL route has direct read/write tests, DX3 proves only its
  bypassed helper math, ASCII's immediate SetPosition/GetState check can pass from
  `InputManager`'s synchronous state assignment alone, and no dedicated transform test was
  found for EasyGL, Canvas, Vulkan, WebGPU, or SDL GPU.
- Ch.16 now carries the three-tier route and complete fourteen-product matrix; Ch.25
  distinguishes DX3's helper math from its real public path; Ch.26 explains the
  caller-visible consequences and evidence boundary; Appendix F has the quick-reference
  warning.

## Earlier completed batch

The draw-fallback, instancing, and vertex-binding audit is complete:

- The ordinary `DrawPrimitivesEx` / `DrawIndexedPrimitivesEx` fallbacks are dead today. All
  ten constructible 3D/diagnostic backends override them; the four 2D-only backends fail
  buffer construction first and their fallback target throws anyway.
- The shared throwing `DrawInstancedPrimitivesEx` default is live on SDL GPU and Software.
  Seven GPU backends override it; Headless records logical statistics; the four 2D-only
  backends cannot reach it through public buffer construction.
- `GraphicsDevice` forwards only the first binding with `InstanceFrequency > 0` as one raw
  instance-buffer pointer. `GpuDrawParams` carries neither the actual frequency nor binding
  offsets, so no backend can reproduce FNA's complete binding array. EasyGL's custom-effect
  path binds the caller's declaration with divisor one; the other real GPU paths use a fixed
  internal instancing shader and predominantly a 64-byte world-matrix record.
- Binding state itself is inconsistent: the offset-taking singular setter ignores its offset
  and leaves `currentVertexBuffers_` stale; an empty plural setter leaves
  `currentVertexBuffer_` stale. A later instanced draw can therefore combine a new mesh slot
  with an old instance slot. The existing `VertexBufferBindingTests` never constructs a
  `GraphicsDevice`, so its “GetVertexBuffers contract” comments do not exercise this state.
- Backend proof is strongest on public EasyGL/Vulkan multi-instance pixel tests; WebGPU and
  D3D9 have direct multi-instance pixel tests; D3D11/12 directly prove only one instance;
  BGFX, SDL GPU, Software, and Headless have no dedicated instancing pixel/contract test.
- Ch.9 now documents the public narrowing and the unsynchronized singular/plural binding
  state; Ch.16 carries the complete fallback/override/evidence matrix; Ch.20 removes a
  previous BGFX overclaim; Ch.22 expands its open-limit count from seven to nine; Appendix A
  carries the concise caller warning.

## Earlier completed Texture2D batch

The `Texture2D` interface-default audit is complete:

- `Texture2D::SetData(Color*, count)` replaces this object's backend resource, while the
  detailed level/rectangle overload alone reaches `ITextureBackend::UpdatePixels*`.
- Every current texture factory product overrides the empty level-0 default, so
  `UpdatePixels()` is unreachable dead fallback today. SDL GPU still inherits the empty
  `UpdatePixelsLevel()` default and allocates one physical level even when public
  `LevelCount` reports a full mip chain. Software explicitly discards higher levels;
  Headless records only a trace. SDL_Renderer/ASCII, Canvas, and DX3 throw instead.
- Ordinary `Texture2D::GetData()` reads the CPU shadow. Therefore the existing public
  SetData/GetData mip round trip does not prove GPU upload; separate sampled-pixel or native
  readback tests provide the real evidence on EasyGL/Vulkan/BGFX, WebGPU, and D3D11/12.
- WebGPU deliberately regenerates the complete ordinary-texture mip chain after every
  level-0 upload, unlike FNA and the other CNA implementations; a later level-0 write can
  overwrite authored higher levels.
- Ch.11 now explains both update paths and why its former public round-trip example was not
  GPU evidence. Ch.16 contains the full backend matrix and evidence limits. Ch.19 corrects
  its stale Vulkan no-op claim, and Appendix A carries the concise caller-facing warning.

## Earlier completed work

The remaining `RenderTargetCube` interface defaults were traced through the public API,
every factory/override, backend target state, FNA, and the relevant examples:

- `RenderTargetCube` inherits `TextureCube.SetData()` in both CNA and FNA. FNA forwards it to
  FNA3D even for a render-target texture. CNA redeclares it as an empty
  `IRenderTargetCubeBackend` default; only EasyGL overrides it. Every other constructed
  target validates and converts a public upload, then silently discards it. Null-factory
  backends discard it one layer earlier. No dedicated RT-cube upload test exists.
- `IGraphicsBackend::SetRenderTargetCubeFace()` binds a non-null cube but never calls the
  outgoing cube's `UnbindAsRenderTarget()`; its null case merely enters the 2D-null path.
  Vulkan, WebGPU, SDL GPU, and D3D9 remain sound through their own state models or override.
- D3D11/12 inherit that common route while tracking only `RenderTarget2D`.
  D3D11's later public null-target call neither finalizes the cube nor restores the
  backbuffer. D3D12 restores the backbuffer but skips cube MSAA resolve and mip generation.
  Their smoke tests call cube bind/unbind directly, so exact pixels prove the algorithms
  only when explicitly invoked; no public `GraphicsDevice` cube-transition test was found.
- EasyGL correctly finalizes cube-to-2D/backbuffer and transitions between different cube
  objects, but same-object face-to-face switching skips unbind. Its shared MSAA renderbuffer
  therefore resolves only the last face unless the caller unbinds between faces. No
  dedicated EasyGL cube-MSAA test exists.
- BGFX's ordinary 2D-null path restores view 0 and native attachment flags handle resolve/
  mip work. Its explicit cube-null overload simply returns, however, and the established
  single-view-ID-per-cube same-frame face boundary remains.
- Ch.11, Ch.16, Ch.23, and Appendix A now agree. Ch.16 contains the complete matrix; Ch.23
  explicitly distinguishes working D3D backend callbacks from the missing public routing.

## Additional earlier work

The preceding readback audit established real ordinary Texture3D/TextureCube GPU readback on
EasyGL, Vulkan, BGFX, WebGPU, SDL GPU, and D3D9/11/12, with the separate
RenderTargetCube/null/placeholder matrix recorded in Ch.16.

The earlier buffer-interface audit established that the public `dynamic` constructor flag is ignored,
but EasyGL, SDL GPU, D3D9, and D3D11 still map upload options distinctly. It also found that
the options-taking public wrappers fail to refresh `cpuShadow_`, so inherited `GetData()` sees
empty or stale bytes. Ch.16 contains the full backend matrix. The same batch corrected the
fixed vertex-stride family to 16/20/24/32/48/52/56/68 bytes and documented EasyGL's unique
arbitrary-`VertexDeclaration` path.

The earlier capability passes corrected confirmed `GraphicsCapability` false positives,
documented the real `IEffectBackend` setter boundary, and established the current
ShaderEffect/D3D ABI matrix. See `PLAN.md` for the durable detail.

## Validation

The final forced build succeeded:

```bash
cd latex/book
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -g main.tex
```

Results:

- `main.pdf`: 502 pages.
- Targeted undefined-reference check: no matches.
- Duplicate-label check: no matches.
- `makeindex`: 2,056 accepted, 0 rejected, 0 warnings.
- Rendered and inspected Ch.6 physical page 64, Ch.9 pages 112--113, Ch.16 pages
  188--190, Ch.17 page 207, Ch.19 page 226, Ch.23 pages 261--262, and Appendix A page 467.
- No clipping, table collision, page-edge spill, malformed heading, running-header collision,
  or folio defect was found. The new Ch.16 matrix repeats its header cleanly after the page
  break. All overfull warnings introduced by this batch were removed before the final build;
  older warnings remain elsewhere.
- `git diff --check`: pass.

Useful verification commands:

```bash
wc -l latex/book/chapters/part2-getting-started/ch06-game-loop.tex \
      latex/book/chapters/part3-graphics-core/ch09-graphicsdevice.tex \
      latex/book/chapters/part4-backends/ch16-backend-architecture.tex \
      latex/book/chapters/part4-backends/ch17-sdl-renderer.tex \
      latex/book/chapters/part4-backends/ch19-vulkan-backend.tex \
      latex/book/chapters/part4-backends/ch23-direct3d-backends.tex \
      latex/book/chapters/appendices/appendix-a-core-graphics-quick-reference.tex
git diff --check
```

## Documentation synchronized

- `PLAN.md` records 502 total pages and exact current line counts: Ch.6 473; Ch.9 1,141;
  Ch.16 1,192; Ch.17 390; Ch.19 473; Ch.23 786; Appendix A 378.
- Its durable session log records the construction/runtime split, exact/collapsed/no-op
  interval semantics, D3D9 native-validity defect, Vulkan eager-construction trap, evidence
  strength, FNA contrast, and PDF inspection.
- `README.md` has build/navigation guidance; `CLAUDE.md` says 49 chapters.

## Repository safety

Do not modify the existing user-owned sibling-repository changes:

- `cna`: `cmake/Tests/EasyGLTests.cmake`, `cmake/Tests/SdlRendererTests.cmake`, and
  `examples/xvfb_screenshot_demo.cpp`;
- `cna-samples`: `samples/SimpleAnimation/Content/tank.model.json`.

Sibling repositories remain read-only source authorities for ordinary book work.

## Blockers and `needs_human`

- No book-writing task currently needs a human decision.
- Push is operationally blocked by the failed approval-service review described above; local
  work and commits can continue safely.
- Real Windows/D3D9-era hardware remains the only way to close the narrow authenticity limit
  around capability values synthesized by DXVK. Keep that marked `needs_human`; it does not
  block independent work.

## Recommended next starting point

Continue Ch.16's backend-interface-default audit. Buffer defaults, volume/cube readback,
RenderTargetCube upload/transitions, Texture2D updates, draw/instancing fallbacks,
coordinate transforms, backbuffer readback, swap intervals, presentation formats, and
recovery/debug hooks are closed. The next safe candidate is the paired
`IGraphicsBackend::SetViewport()` / `SetScissorRect()` defaults: trace public property
assignment and draw-time reapplication, all fourteen products, native coordinate
conventions, and actual pixel assertions. Compare Ch.9/14 and the existing EasyGL, Vulkan,
and WebGPU notes before writing. Avoid the BlendState field matrix while the separate
`feature/audit` worktree is changing it. Do not modify CNA itself; sibling repositories
remain read-only source authorities.
