# Audit report — sibling foundation libraries (sharp-runtime, easy-gl, meta-gl, free-direct, free-api)

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only across all six repositories; no build, clone or write anywhere.

**Audit date:** 2026-08-11 · **Method:** read-only (`git log/show/rev-parse/cat-file`, `grep`, `wc`, `cloc`). No builds, no clones, no writes to any source repository.
**CNA reference point:** `/rv/data/development/github.com/openeggbert/cna` @ `7a64362efef4119bf880459ef1704fb2c52199e2` (2026-08-11T18:33:25+02:00, *"integration: reconcile parallel feature lanes"*) — confirmed at the pinned SHA.

## Headline corrections the new edition must absorb

1. **The premise "CNA includes only two sharp-runtime headers directly" is FALSE.** CNA directly `#include`s **54 distinct sharp-runtime headers** — 2 under the `SharpRuntime/` prefix and **52 under `System/`**. CNA owns **zero** `System/` headers of its own. Details in §1 FACT 12.
2. **easy-gl now backs FIVE CNA GL profiles, not four.** `OPENGLES2` landed 2026-08-11 (commit `33abdd8f9`), the same day as the CNA pin. CNA's own `integration/INTEGRATION_BRANCH_INVENTORY.md:536-543` still says "exactly **four**" — stale by one.
3. **The MetaGL/EasyGL public-history rewrite is confirmed, and it is content-preserving but SHA-destroying.** Both HEADs and both tree hashes match CNA's record exactly. Every pre-rewrite SHA the book might cite is now unreachable from any ref.
4. **sharp-runtime became modular on 2026-08-10** — one day before the CNA pin — in a merge touching **3,828 files (+270,341 / −17,757)**. Any description of sharp-runtime as "one static archive" is now wrong.
5. **free-direct and free-api are frozen.** Zero commits on any ref since 2026-07-18. Nothing invalidates a description written before 2026-07-26 *about these two*.

---

## 0. Identity table (all five)

| Repo | Branch | HEAD SHA | HEAD date | local vs origin | Working tree |
|---|---|---|---|---|---|
| `sharp-runtime` | `develop` | `f827a6c5349234d5ac938886788ed8eca8fe1c10` | 2026-08-10T09:04:44+02:00 | **identical** (develop and master both) | clean |
| `easy-gl` | `develop` | `0b46d35c394a9fb6aea6a85c6587894b5013da33` | 2026-08-07T17:37:46+02:00 | **identical** | **untracked `VERSION`** (`0.1.0-SNAPSHOT`) |
| `meta-gl` | `develop` | `571d3a62fe166b9781ac6193d137b12ff3757620` | 2026-08-07T18:21:27+02:00 | **identical** | **staged+modified `VERSION`** (`0.4.0-snapshot`) |
| `free-direct` | `develop` | `934f72ff0c52902631fceeb52c006f3ed2767485` | 2026-07-18T14:15:40+02:00 | **identical** | clean |
| `free-api` | `develop` | `53d7a3124110fb30eea370a42c86ccff0c39aef3` | 2026-07-18T15:29:20+02:00 | **identical** | clean |

All five match the SHAs given in the brief. **No branch has an upstream configured** (`git rev-parse --abbrev-ref develop@{upstream}` → *fatal: no upstream configured*), so `git status -sb` prints a bare `## develop` with no ahead/behind marker. I verified equality by comparing `rev-parse develop` against `rev-parse origin/develop` directly — VERIFIED for all five, on both `develop` and `master`.

**Book caveat:** the two `VERSION` files are uncommitted. `meta-gl/VERSION` says `0.4.0-snapshot` while `meta-gl/CMakeLists.txt:3-4` says `project(meta-gl VERSION 0.3.0)`. Cite `0.3.0`; the `0.4.0-snapshot` file is not part of any commit.

---

# 1. sharp-runtime

## IDENTITY
`/rv/data/development/github.com/openeggbert/sharp-runtime` · `develop` @ `f827a6c5349234d5ac938886788ed8eca8fe1c10` · 2026-08-10 · local == origin · clean · 2,216 commits total.

## FACTS

1. **Purpose: a C++23 reimplementation of a subset of the .NET Base Class Library, reproducing the .NET namespace tree literally.** The namespace is `System::`, not a vanity namespace. `modules/core/include/System/Object.hpp:37`, `modules/core/include/System/Exception.hpp:16`. Nested C++17 form is mandated: `CLAUDE.md:19`. — **VERIFIED**

2. **41 module directories, registered through a custom CMake registry, not `add_library`.** The authoritative ordered list is `cmake/SharpRuntimeModules.cmake:13-55`. Registration is `sharp_runtime_register_module()` (41 call sites) plus `sharp_runtime_register_component()` (3 call sites) — `cmake/SharpRuntimeComponents.cmake:222` and `:13`. Sources are **globbed**, never listed (`cmake/SharpRuntimeComponents.cmake:244`). — **VERIFIED**

3. **44 registered component names → 30 STATIC, 13 INTERFACE, 1 ALIAS.** Derived by AWK over `modules/*/CMakeLists.txt` (command in SIZE TABLE). Full list: `Buffers, Collections, Collections.Async, Collections.Blocking, Collections.Core, Collections.ObjectModel, ComponentModel, Console, Core, Core.Base, Diagnostics, Globalization, IO, IO.Compression, IO.Compression.Zip, IO.Hashing, IO.IsolatedStorage, Net, Net.Http, Net.Http.Headers, Net.Http.Json, Net.Mime, Net.NetworkInformation, Net.Security, Net.Sockets, Net.WebSockets, Numerics, Runtime, Security, Security.Cryptography, Security.Cryptography.Random, Storage, Text, Text.Json, Text.RegularExpressions, Threading, Threading.Channels, Threading.Tasks, Timers, TimeZone, Uri, Xml, Xml.Linq, Xml.XPath`. `Xml.XPath` is the sole `ALIAS_OF Xml` (`modules/xml/CMakeLists.txt:30-34`, rationale: mutual binary dependency). — **VERIFIED**
   > Minor correction to CNA's own `MODULARIZATION_PLAN.md:133`, which says "41 modules (30 STATIC, 11 INTERFACE)". The STATIC count is right; the INTERFACE count is **13**, and there are 44 *components* across 41 *directories* (two compatibility umbrellas — `Core` and `Collections` — plus the `Xml.XPath` alias).

4. **There is no umbrella header.** Every one of the ~1,037 headers sits under exactly two include roots: `System/` (1,026 files) and `SharpRuntime/` (6). The on-disk path is a mechanical transliteration of the .NET FQN — `System.IO.FileStream` → `modules/io/include/System/IO/FileStream.hpp`. One .NET type per header, named after the type. `INCLUDE_DIRECTORY` is set to `include/` only (`cmake/SharpRuntimeComponents.cmake:275`), so the 5 private `.hpp` under `src/` are unreachable to consumers. — **VERIFIED**

5. **`System::String` is not a string class.** `modules/core/include/System/String.hpp:23-28` declares `class String` with `String() = delete;` and `~String() = delete;`. Its own doc comment (`:19-20`): *"This class is not a wrapper around std::string. Instead, it offers static helper methods useful for source-porting C# code to C++."* The actual string type is `std::string`, aliased at `modules/core/include/SharpRuntime/SharpRuntimeHelper.hpp:210` as `SharpRuntime::String = std::string`. — **VERIFIED**

6. **`System::Object` is vestigial, and deliberately so.** Exactly **two** classes in the whole repository derive from it: `modules/core/include/System/DateTime.hpp:31` and `modules/core/include/System/DateTimeOffset.hpp:44`. It is abstract (pure-virtual `GetTypeName()`, `Object.hpp:138`), which is why nothing else pays for it. `Object.hpp:47-48` admits: *"In this port the class is abstract because C++ has no universal root type."* **This is not a rooted object model** — a claim a book could easily get wrong. — **VERIFIED**

7. **Exceptions derive from `std::exception`, not from `Object`.** `modules/core/include/System/Exception.hpp:32` — `class Exception : public std::exception`; second tier `modules/core/include/System/SystemException.hpp:20`. ~111 exception classes; ~915 `throw` sites across `modules/*/src/*.cpp`; **no `ThrowHelper`**. `Exception` carries `innerException_` as `std::exception_ptr` and an `hResult_` defaulting to `0x80131500` (`Exception.hpp:39`). **`getStackTraceProperty()` returns an empty string** (`Exception.hpp:83-88`) and `GetBaseException()`/`ToString()` are deliberately absent — the header explains why at `:27-30` (slicing without a virtual-clone mechanism; `ToString()` needs reflection). — **VERIFIED**

8. **Reflection is identity-only and honestly self-documented as fake.** `modules/core/include/System/Type.hpp:32` (238 lines) is RTTI-backed; `Type::From<T>()` (`:59-63`) is the `typeof` equivalent and genuinely works as a type identity (good enough as a service-container key). But `Type.hpp:21-30` volunteers that the predicates *"return a fixed value regardless of what T actually is"* and are *"**not mutually consistent**: e.g. `Type::From<int>()` reports both IsClass()==true and IsValueType()==false simultaneously… Do not branch on these predicates."* `System::Activator` is template-only; the reflection overloads are explicitly unavailable (`modules/core/include/System/Activator.hpp:13-15`). — **VERIFIED**

9. **Memory/lifetime: value semantics + RAII, no custom smart pointer, no GC.** `std::shared_ptr` appears in ~118 of ~1,032 headers (~11%), `std::unique_ptr` in ~37 (~3.6%), used where .NET reference semantics genuinely leak (e.g. `modules/net-http/include/System/Net/Http/StreamContent.hpp:42`). Policy: `CLAUDE.md:228` — *"**GC** (`System::GC`) — all methods are no-ops. Memory is managed by RAII / `std::shared_ptr`."* — **VERIFIED**

10. **Type families, primary headers:**
    - *Strings:* `System/String.hpp:23` (712 L, static-only), `System/Text/StringBuilder.hpp:45` (351 L), `System/Text/Encoding.hpp:41` (186 L) + `ASCIIEncoding`/`UTF8Encoding`/`UTF32Encoding`/`UTF7Encoding`/`UnicodeEncoding`/`Latin1Encoding`, `Rune`, `Utf8`/`Utf16`/`Ascii`, encoder/decoder fallbacks, `System::Text::Encodings::Web` (`HtmlEncoder`/`JavaScriptEncoder`/`UrlEncoder`), `CompositeFormat`.
    - *Collections* (the fullest area after core): Generic — `List` (`System/Collections/Generic/List.hpp:77`, 817 L), `Dictionary` (`:78`, 434 L), `HashSet` (`:63`, 409 L), `SortedSet`, `SortedList`, `SortedDictionary`, `OrderedDictionary`, `LinkedList`, `Queue`, `Stack`, `PriorityQueue`, `KeyValuePair`, the comparer family. Non-generic — `ArrayList`, `Hashtable`, `BitArray`. Immutable — `ImmutableArray/List/Dictionary/HashSet/Queue/Stack/SortedDictionary/SortedSet`. Concurrent — `ConcurrentDictionary/Queue/Stack/Bag`, `BlockingCollection`. Frozen — `FrozenDictionary`, `FrozenSet`. ObjectModel — `Collection`, `KeyedCollection`, `ReadOnlyCollection`, `ObservableCollection`. Specialized — `NameValueCollection`, `BitVector32`, … Collections carry a .NET-style fail-fast mutation counter (`System/Collections/detail/MutationCounter.hpp`).
    - *Streams/IO:* `System/IO/Stream.hpp:64` (175 L) — **does not derive from `Object`**; capability properties are *virtual with defaults, not pure virtual* (design recorded in `docs/StreamCapabilityContractDesign.md`). Plus `FileStream.hpp:20`, `MemoryStream.hpp:17`, `BufferedStream`, `UnmanagedMemoryStream`, `BinaryReader.hpp:39`, `BinaryWriter.hpp:27`, `TextReader/TextWriter/StreamReader/StreamWriter/StringReader/StringWriter`.
    - *Filesystem:* `System/IO/File.hpp:21` (55 L), `Directory.hpp:26` (54 L), `Path.hpp:19` (70 L) — thin static facades, bodies in `modules/io/src/`. Plus `FileInfo`, `DirectoryInfo`, `FileSystemInfo`, `DriveInfo`, `FileSystemWatcher`, and the `FileMode`/`FileAccess`/`FileShare`/`FileAttributes`/`FileOptions`/`UnixFileMode` enums.
    - *Threading/tasks:* `System/Threading/Tasks/Task.hpp:44` is the largest single type header at **1,123 lines**; `Thread.hpp:34` (338 L), `CancellationToken.hpp:21` (119 L), `Mutex.hpp:28` (85 L), `Channels/Channel.hpp:35` (603 L). Full sync surface: `Monitor`, `Interlocked`, `Volatile`, `SpinLock`, `SpinWait`, `Barrier`, `CountdownEvent`, `Semaphore(Slim)`, `ManualResetEvent(Slim)`, `AutoResetEvent`, `EventWaitHandle`, `WaitHandle`, `ReaderWriterLock(Slim)`, `Lock`, `ThreadPool`, `ThreadLocal`, `AsyncLocal`, `ExecutionContext`, `SynchronizationContext`, `Timer`/`PeriodicTimer`; tasks add `TaskCompletionSource`, `TaskFactory`, `TaskScheduler`, `ValueTask`, `Parallel`.
    — **VERIFIED** (structural); **STRONG** on semantics of headers not read line-by-line.

11. **The two `SharpRuntime/`-prefixed headers CNA includes — both in `modules/core` (component `Core.Base`):**
    - **`modules/core/include/SharpRuntime/SharpRuntimeHelper.hpp` (211 L)** — the primitive-type Rosetta stone, and the most load-bearing header in the repo: **367 of ~1,032 public headers include it (36%)**. Provides (a) `SHARP_RUNTIME_HAS_NATIVE_INT128` (`:19-29`), set by the CMake probe at `CMakeLists.txt:14-29` with a `__SIZEOF_INT128__` fallback; (b) two **unnamespaced, unprefixed macros** at `:31-32` — `CONTAINS(STRING, SUBSTR)` and a no-op `INTERNAL` (a genuine macro-collision hazard worth flagging); (c) `namespace SharpRuntime` (`:34`) with the C#-fidelity integer aliases `sbytecs`/`bytecs`/`ubytecs`/`shortcs`/`ushortcs`/`intcs`/`uintcs`/`longcs`/`ulongcs`/`charcs`(=`char16_t`)/`IntPtr` at `:40-95`; (d) `inline constexpr` min/max constants at `:100-185`; (e) PascalCase .NET aliases at `:187-210` including `Single = float` and `String = std::string`. `SharpRuntime::intcs` is binding, not decorative — `CLAUDE.md:20` mandates it and it appears **1,243 times** in public headers.
    - **`modules/core/include/SharpRuntime/Prop.hpp` (193 L)** — a **pure macro header** (only `#include <utility>`; the trailing `namespace SharpRuntime {}` at `:193-194` is empty). Six public macros in declare/implement pairs: `DDATA`/`IDATA` (`:103`/`:166`, read-write), `DGETTER`/`IGETTER` (`:116`/`:177`, read-only), `DGETTERSTATIC`/`IGETTERSTATIC` (`:129`/`:190`). Generated shape (`:36-38`): field `name_`, `getNameProperty()` (`[[nodiscard]]`, returns `const T&`), `setNameProperty(...)` in both const-ref and rvalue-ref overloads (`:90-91`, `:150-156`). Underneath is a token-pasting kit (`:53-77`).
    **Skeptical finding worth a sidebar: `Prop.hpp` is dead code *inside* sharp-runtime.** Zero of the 41 modules include it (`grep -rl 'SharpRuntime/Prop.hpp' modules/` → 0 files). Its only in-repo consumer is `tests/integration/Task41Tests.cpp:28`. sharp-runtime's own 2,927 `getXxxProperty()` / 589 `setXxxProperty()` declarations are all hand-written. **Prop.hpp exists as an exported facility for downstream code such as CNA** — which is exactly why CNA includes it and the library does not. — **VERIFIED**

12. **★ How the rest of sharp-runtime reaches CNA — and why "two headers" is wrong.** CNA `#include`s **54 distinct sharp-runtime headers** directly. CNA owns **zero** `System/` headers itself (`git -C cna ls-files | grep -c 'System/'` → **0**), and every one of the 52 `System/*` spellings resolves into `sharp-runtime/modules/*/include/System/...`. The top of the distribution (occurrence counts across CNA's own tracked sources, excluding `third_party/`):

    | Occurrences | Header | Owning module |
    |---:|---|---|
    | 112 | `System/NotSupportedException.hpp` | core |
    | 101 | `System/ArgumentOutOfRangeException.hpp` | core |
    | **67** | **`SharpRuntime/SharpRuntimeHelper.hpp`** | core |
    | 65 | `System/TimeSpan.hpp` | core |
    | 58 | `System/Object.hpp` | core |
    | 57 | `System/EventArgs.hpp` | core |
    | 52 | `System/InvalidOperationException.hpp` | core |
    | 50 | `System/ObjectDisposedException.hpp` / `System/IDisposable.hpp` | core |
    | 43 | `System/IO/MemoryStream.hpp` | io |
    | 20 | `System/IO/BinaryWriter.hpp` | io |
    | **9** | **`SharpRuntime/Prop.hpp`** | core |
    | 1 | `System/Security/Cryptography/SHA256.hpp` | security-cryptography |

    The "two headers" framing is a **naive reading of the `SharpRuntime/` prefix only**. Its likely origin is `cna/CLAUDE.md:106` — *"Include `\"SharpRuntime/SharpRuntimeHelper.hpp\"` to access these"* — which is about the *primitive-alias table specifically*, not about the whole dependency. The correct statement for the book: **CNA consumes sharp-runtime through `System/…` include paths that mirror .NET fully-qualified type names; `SharpRuntime/SharpRuntimeHelper.hpp` and `SharpRuntime/Prop.hpp` are the only two headers under the library's *own* `SharpRuntime/` namespace prefix that CNA uses.** — **VERIFIED**

13. **Parity strategy — the governing statement.** `CLAUDE.md:222-224`: *"sharp-runtime and .NET will naturally differ — C++ has no GC, no IL, no runtime reflection, and no delegate infrastructure. The goal is **maximum practical parity**: the public API, method semantics, default values, error messages, and algorithmic behaviour should match .NET as closely as C++ allows."* Failure mode is specified at `CLAUDE.md:245`: unimplementable methods *"should throw `System::NotImplementedException` with a comment explaining why — never silently return a wrong value."* Platform gaps get different treatment — `README.md:222-225`: *"Unsupported operations should compile and fail explicitly with `PlatformNotSupportedException`, rather than silently degrade."* — **VERIFIED**

14. **Deliberate permanent deviations** (`CLAUDE.md:226-243`, *"Known permanent deviations (not bugs, not TODO)"*; restated publicly at `README.md:227-239`):
    - `:227` **Reflection** — *"completely out of scope. Stubs are the correct end state."*
    - `:228` **GC** — all no-ops.
    - `:229-240` **Delegates**, in three tiers: most delegate-shaped types are bare `using X = std::function<...>` aliases (single-target, no multicast, no `BeginInvoke`/`EndInvoke`); **but** `System::Delegate` (`modules/core/include/System/Delegate.hpp`) *is* a real multicast base with `Combine`/`Remove`/`RemoveAll`/`GetInvocationList`, and `System::MulticastAction<Args...>` (`modules/core/include/System/MulticastAction.hpp`) is a purpose-built multicast event field with `+=`/`-=` and reentrancy-safe snapshot invocation. `DynamicInvoke` always throws.
    - `:241` **Serialization** ignored. `:242` **P/Invoke / interop** out of scope.
    - `:243` **Symmetric/asymmetric crypto, X.509, TLS** — out of scope by explicit dated decision (2026-07-07, commit `5954eb5c`), because it needs *"either a large new external dependency (OpenSSL/mbedTLS) or a hand-rolled, security-critical implementation, neither of which is worth it for game code."* Hashes (`MD5`/`SHA*`/`HMAC`/`PBKDF2`) stay in scope.
    — **VERIFIED**

15. **Naming: PascalCase throughout, with one systematic deviation — properties.** `CLAUDE.md:15-18`: always `getXxxProperty()` / `setXxxProperty()`, *except* indexers which use `getItem()`/`setItem()`. Verified: 2,927 `get…Property(` + 589 `set…Property(` in public headers, and 35 `getItem(`/`setItem(` indexers. Other binding rules: `CLAUDE.md:21` — *"**No LINQ.** Use `std::ranges`"*; `:24` — copy .NET XML doc-comments as Doxygen. And, directly relevant to this book, **`CLAUDE.md:23`: *"No broad header refactor — naming conventions touch 449+ files and would break CNA."*** CNA is named as the reason the conventions are frozen. — **VERIFIED**

16. **A reproducibility caveat the book should state.** `CLAUDE.md:267` and `:278` anchor doc-comments and line-by-line logic parity to `/rv/tmp/runtime/src/libraries/` — an absolute path to a .NET source checkout **outside the repo**, neither vendored nor pinned. `NEXT.md:19-20` records that *"Doxygen, `ccache` and the `/rv` reference tree are all absent"* in the environment that produced the current HEAD. The parity process is therefore not reproducible from the repository alone. — **VERIFIED**

17. **Tests: three distinct locations, and the singular/plural split is real.**
    - `modules/<m>/tests/` — the primary home, **477 test `.cpp`**, mirroring the header tree.
    - `tests/` (plural) — cross-cutting only: `tests/integration/` (10 `.cpp`) and `tests/Platform/SharpRuntimeI686CompileBoundary.cpp`.
    - `test/` (singular) — **not gtest at all**: Python meta-tests (`test/validate_module_boundaries_test.py`, `test/check_negative_consumer_fixtures_test.py`, `test/check_version_seam_odr_test.py`) and `test/consumer/` CMake fixtures, some of which must **fail** to compile (negative fixtures).
    Framework is **GoogleTest, vendored as a submodule** at `vendor/googletest`, hard-required at `CMakeLists.txt:88-92`. — **VERIFIED**

18. **Test registration is fully automatic and doubles as boundary enforcement.** `cmake/SharpRuntimeComponents.cmake:240-242` globs each module's `tests/*.cpp`; `:598` `sharp_runtime_add_component_tests()` builds **one executable per component** (`SharpRuntimeTests_${component_key}`, `:634/:648`) linking only `SharpRuntime::${component}` + `gtest_main` (`:649-654`); `:667-670` `gtest_discover_tests(... TEST_PREFIX "${component}::")`. Extra test-only edges come from `TEST_DEPENDENCIES` (e.g. `modules/io/CMakeLists.txt:9`), keeping test wiring out of the production graph. **Because each test binary links only its own component, a test that reaches across an undeclared module boundary fails to link.** Reinforced by `sharp_runtime_validate_source_partition()` (`cmake/SharpRuntimeModules.cmake:64`) and an **empty** `cmake/SharpRuntimeModuleDependencyAllowlist.json`. — **VERIFIED**

19. **Current test scale: 16,310 tests across 37 executables — 16,303 passing, 1 skipped, 6 failing.** `NEXT.md:17`. **36 modules have tests; 5 have none** (`io-compression-zip`, `io-isolated-storage`, `security-cryptography-random`, `storage`, `text-regular-expressions`) — 36 component executables + 1 integration executable = 37, which reconciles exactly. Note `text-regular-expressions` is a 12-header INTERFACE module with **zero implementation and zero tests** — a real gap. — **VERIFIED**

20. **★ The modularization merge is the single most important recent event.** `f827a6c5` (2026-08-10) *"merge: integrate the modular remediation snapshot into develop"* integrates snapshot `a284b6e4` of `claude/remediation-batch-1804-namespace-b1yjh5`. Size vs. its first parent: **3,828 files changed, +270,341 / −17,757**. The commit body records five semantically-resolved textual conflicts, including retaining `SHARP_RUNTIME_HAS_NATIVE_INT128` on the `sharp_runtime_headers` INTERFACE so it reaches every component *and consumer* — matching the monolith's PUBLIC semantics. The message also states the remediation branch *"continues to advance; later increments merge separately"* — **develop is a snapshot of a still-moving lane**. — **VERIFIED**

21. **Only 2 first-parent commits since 2026-07-26**: `bc5ddafe` (2026-08-09, *"fix(FINAL-STAB-001): restore i686 dependency boundary"*) and the modularization merge above. Everything before that is 2026-07-20 and earlier (a BSD/Darwin portability run: `getentropy()`, ICMPv4 header ABI, Apple `htonl` macros, `HOST_NAME_MAX`/`CLOCK_BOOTTIME`, portable `from_chars`). **The July history is stable; the August merge is what invalidates pre-2026-07-26 descriptions.** — **VERIFIED**

22. **An audit apparatus larger than most projects' source.** `audit/` holds **1,748 `*.audit.md` files** — essentially one per tracked source file (1,796 `.hpp`/`.cpp`/`.h`/`.c`) — plus `AUDIT_FINDINGS_INDEX.md` with stable `SR-AUD-###` identifiers, severity and status. `NEXT.md:14-15`: *"Audit **161 remediated / 203 confirmed / 364 total**… numbering frozen at 364."* `docs/` holds 73 design/plan/migration documents. `plan.sqlite3` is a 7.4 MB tracked SQLite database. — **VERIFIED**

## SIZE TABLE — sharp-runtime

All counts from tracked files at HEAD; build dirs and untracked files excluded by construction.

| Metric | Value |
|---|---:|
| Tracked files (all types) | **3,761** |
| Tracked `.md` files | **1,875** |
| Public headers under `modules/` (non-test) | **1,037** |
| Implementation `.cpp` under `modules/` (non-test) | **217** |
| Test `.cpp` under `modules/` | **477** |
| Non-test lines under `modules/` (physical) | **157,676** |
| Test `.cpp` lines under `modules/` (physical) | **139,547** |
| Non-test **code** lines under `modules/` (cloc) | **78,934** (+60,984 comment, +17,769 blank) |
| Test **code** lines under `modules/` (cloc) | **102,342** |
| Files outside `modules/` (`.hpp/.cpp/.h/.c`) | 63 files / **54,719** lines — dominated by vendored `nlohmann/json.hpp` (26,753), miniz, tinyxml2 |
| Markdown outside `modules/` and `audit/` | **89,308** lines (`NEXT.md` alone = 19,596) |
| CMake (`CMakeLists.txt` + `*.cmake`) | **1,678** lines |
| Components / modules | **44 components** (30 STATIC, 13 INTERFACE, 1 ALIAS) across **41 directories** |
| Commits (`develop`) | **2,216** |

> **The single most quotable size fact: sharp-runtime's tests (102,342 code lines) exceed its implementation (78,934 code lines) by ~30%.**

**Exact derivation commands** (run from `/rv/data/development/github.com/openeggbert`):
```bash
git -C sharp-runtime ls-files | wc -l
git -C sharp-runtime ls-files '*.md' | wc -l
git -C sharp-runtime ls-files 'modules/*.hpp' | grep -Ev '/tests?/' | wc -l
git -C sharp-runtime ls-files 'modules/*.cpp' | grep -Ev '/tests?/' | wc -l
git -C sharp-runtime ls-files 'modules/*.cpp' | grep -E  '/tests?/' | wc -l
git -C sharp-runtime ls-files 'modules/*' | grep -E '\.(hpp|h|cpp|c)$' | grep -Ev '/tests?/' \
  | sed 's|^|sharp-runtime/|' | xargs wc -l | tail -1
git -C sharp-runtime ls-files 'modules/*.cpp' | grep -E '/tests?/' \
  | sed 's|^|sharp-runtime/|' | xargs wc -l | tail -1
cloc --quiet --exclude-dir=tests,test,build,vendor \
     --include-lang=C++,"C/C++ Header" sharp-runtime/modules
git -C sharp-runtime ls-files 'CMakeLists.txt' '*/CMakeLists.txt' '*.cmake' \
  | sed 's|^|sharp-runtime/|' | xargs wc -l | tail -1
# component table (NAME / TARGET / TYPE):
awk '/sharp_runtime_register_(module|component)\(/{b=1;n="";t="(default)"}
     b&&/^[[:space:]]+NAME /{n=$2} b&&/^[[:space:]]+TYPE /{t=$2}
     b&&/^\)/{print n, t; b=0}' sharp-runtime/modules/*/CMakeLists.txt | sort
# CNA's sharp-runtime include surface:
git -C cna ls-files '*.hpp' '*.cpp' '*.h' '*.cc' | grep -v '^third_party/' | sed 's|^|./|' \
  | xargs grep -hn '#include *[<"]\(SharpRuntime\|System\)/' \
  | sed 's/.*#include *[<"]//; s/[>"].*//' | sort | uniq -c | sort -rn
```

## HOW CNA CONSUMES IT

**Unconditional. sharp-runtime is the one sibling CNA cannot build without.**

1. `cna/CMakeLists.txt:95` — `set(SHARP_RUNTIME_BUILD_TESTS OFF CACHE BOOL "..." FORCE)`. Without this, CNA would build 37 gtest executables.
2. `cna/CMakeLists.txt:103-104` — `CNA_SHARP_RUNTIME_ROOT` cache PATH, defaulting to `../sharp-runtime`, overridable to point at e.g. a pinned read-only worktree.
3. `cna/CMakeLists.txt:105-112` — **hard `FATAL_ERROR`** if `${CNA_SHARP_RUNTIME_ROOT}/CMakeLists.txt` is missing, with a `git clone` remedy in the message. Sibling checkout, **not** a submodule.
4. `cna/CMakeLists.txt:114` — `add_subdirectory("${CNA_SHARP_RUNTIME_ROOT}" SHARP_RUNTIME)`, unconditionally, before any renderer selection.
5. `cna/CMakeLists.txt:118-119` — `include(cmake/SharpRuntimeConsumption.cmake)` then `cna_detect_sharp_runtime_shape()`.
6. **`cna/cmake/SharpRuntimeConsumption.cmake` (59 lines) is a dual-shape adapter.** Its header comment names both shapes explicitly: *modular* (sharp-runtime develop since 2026-08-10, commit `81624983`) — the `SharpRuntime::<Component>` targets plus a compatibility `SHARP_RUNTIME` INTERFACE that **exists only under the default `All` selection**, described as *"the AUTHORITATIVE shape for the sibling-develop combination"*; and *monolithic* (pre-modularization checkouts) — one `SHARP_RUNTIME` static archive, *"kept as a cheap fallback for old checkouts."* Detection is a single `if(TARGET SharpRuntime::Core.Base)` (`:33`).
7. `cna_link_sharp_runtime(<target> <visibility> [<Component>...])` (`:44-58`) links `SharpRuntime::${component}` per name against a modular checkout, or the single `SHARP_RUNTIME` archive against a monolith. With no components it uses `CNA_SHARP_RUNTIME_DEFAULT_COMPONENTS` (`:22-32`): `Core.Base IO Collections.Core Collections.ObjectModel Runtime Threading Text Globalization Storage` — transitive PUBLIC deps (`Uri`, `TimeZone`, `ComponentModel`, `Buffers`, …) arrive through those.
8. **18 CNA call sites declare narrower per-module closures**, e.g. `modules/math/CMakeLists.txt:3` → `Core.Base`; `modules/input/CMakeLists.txt:4` → `Core.Base`; `modules/graphics/CMakeLists.txt:7` → `Core.Base IO Collections.Core Text`; `modules/net/CMakeLists.txt:11` → `Core.Base IO Collections.Core Runtime Threading`; `modules/gamer-services/CMakeLists.txt:11` → `Core.Base IO Collections.Core Globalization Runtime Threading`; `modules/renderers/CMakeLists.txt:22` → the default closure.
9. **Component selection never fires for CNA.** `sharp-runtime/CMakeLists.txt:32-39` only creates the `SHARP_RUNTIME_COMPONENTS` cache entry when `CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR` — i.e. only when sharp-runtime is top-level. Under CNA's `add_subdirectory`, the variable is undefined and `:49-53` falls through to `All`. So CNA always gets every component built, and the compatibility `SHARP_RUNTIME` target always exists; `cna_link_sharp_runtime`'s narrow component lists are a *link-time* narrowing, not a build-time one.
10. **If absent:** configure fails immediately with the `FATAL_ERROR` at `cna/CMakeLists.txt:106-112`. There is no fallback, no vendored copy, no `FetchContent`.

## CONTRADICTIONS — sharp-runtime

| # | Claim | Reality | Confidence |
|---|---|---|---|
| C1 | `sharp-runtime/CLAUDE.md:12` — verified baseline **"15,071 tests across 37 executables"**, measured 2026-08-01. | `NEXT.md:17` records **16,310 / 37, with 6 failing**. CLAUDE.md predates the 2026-08-10 merge and is stale by ~1,240 tests. **Cite NEXT.md, not CLAUDE.md.** | VERIFIED |
| C2 | CNA `MODULARIZATION_PLAN.md:133` — *"41 modules (30 STATIC, **11 INTERFACE**)"*. | 41 *directories*, but **44 components**: 30 STATIC, **13** INTERFACE, 1 ALIAS. STATIC is right; INTERFACE is under by 2. | VERIFIED |
| C3 | The brief's premise — CNA includes only `SharpRuntimeHelper.hpp` and `Prop.hpp`. | 54 headers, 52 of them `System/*`. See FACT 12. | VERIFIED |
| C4 | `CLAUDE.md:227` — reflection is out of scope, *"stubs are the correct end state."* | Holds, but **understates**: `Type::From<T>()` and `Object::GetType()` are genuinely functional RTTI-backed identity. The accurate description is "identity-only, predicates fake" — and `Type.hpp:21-30` says so more honestly than the policy requires. | VERIFIED |
| C5 | `CLAUDE.md:245` — unimplementable methods throw `NotImplementedException`. | Holds, but the population is tiny: only ~23 `NotImplementedException` references across headers + src. Out-of-scope areas were mostly **not built at all** rather than stubbed — consistent with `CLAUDE.md:257` disqualifying bare-throw bodies from `ported`. | VERIFIED |
| C6 | Book `appendix-d-repo-map.tex:193-194` — sharp-runtime *"~70.7k"* lines (cloc, July 2026, `src/`+`include/` only). | Now **78,934** code lines (same cloc scope). Direction is right; the figure is ~8k stale. | VERIFIED |
| C7 | `NEXT.md` describes branch `claude/remediation-batch-1804-namespace-b1yjh5`, not `develop`. | Its snapshot `a284b6e4` **is** an ancestor of `develop` (verified via `git merge-base --is-ancestor`), so NEXT.md's state *is* develop's state — but a reader will find the branch name confusing. The merge message explicitly says the branch *"continues to advance."* | VERIFIED |
| C8 | `CLAUDE.md:267/:278` anchor parity to `/rv/tmp/runtime/src/libraries/`. | That tree is **absent** from the environment that produced HEAD (`NEXT.md:19`). | VERIFIED |

## BOOK IMPACT — sharp-runtime

**Current treatment: 3 chapters, 1,058 lines** (`ch34-sharp-runtime-overview.tex` 315 · `ch35-sharp-runtime-namespaces.tex` 529 · `ch36-parity-philosophy.tex` 214). **Recommendation: expand to 5–6 chapters.**

What a 3-chapter treatment omits, in priority order:

1. **The modularization and the consumption seam (a chapter on its own).** 44 components, the registry, the two compatibility umbrellas, `SharpRuntimeConsumption.cmake`'s dual-shape adapter, the `All`-only compatibility target, and the 18 per-module component closures. This is *the* CNA↔sharp-runtime interface and the existing book cannot contain it — it postdates the text.
2. **The real object model, told honestly (a chapter).** `Object` with two derivations; `String` non-instantiable; `Exception : std::exception`; empty stack traces; `Type` with mutually-contradictory predicates. Every one of these contradicts the naive "it's .NET in C++" reading a reader arrives with, and each is *self-documented in the source* — ideal `sourcenote` material.
3. **Testing and verification as a designed system (a chapter, or a long section of the testing chapter).** 477 module test files, 16,310 tests / 37 executables with 6 honestly-recorded failures, per-component link isolation as boundary enforcement, negative consumer fixtures that must fail to compile, the Python meta-tests, and the 1,748-file `audit/` apparatus with frozen `SR-AUD-###` numbering. Ch. 48 (`testing-philosophy`, 236 lines) should cite this heavily.
4. **Expand the parity chapter (ch36, currently 214 lines — the thinnest of the three).** It should carry the full permanent-deviation list including the **three-tier delegate story** (which self-corrects an earlier inaccurate version in sharp-runtime's own CLAUDE.md), the 2026-07-07 crypto/TLS scope decision, the `PlatformNotSupportedException` vs `NotImplementedException` split, the `getXxxProperty()` convention with its `getItem()` exception, and — critically — **`CLAUDE.md:23`, where CNA is named as the reason the naming conventions are frozen.** That single line is the best evidence in the whole ecosystem that these two repos co-evolved.
5. **Keep ch35 (namespaces) but re-derive it** against 44 components rather than a flat namespace list, and state the include-path rule explicitly: *if you know the .NET type name, you know the include path.*

---

# 2. easy-gl

## IDENTITY
`/rv/data/development/github.com/openeggbert/easy-gl` · `develop` @ `0b46d35c394a9fb6aea6a85c6587894b5013da33` · 2026-08-07 · local == origin · untracked `VERSION` file only · 85 commits.

## FACTS

1. **Purpose: a toolkit-independent, RAII/OOP C++ wrapper over OpenGL / OpenGL ES, built on meta-gl.** `README.md:3`. It creates **no windows and no GL contexts** — the host owns window, context, event processing, swap/present, and supplies a `GetProcAddress` callback (`README.md:29-40`). — **VERIFIED**

2. **easy-gl depends on meta-gl by sibling `add_subdirectory`, and links it PUBLIC.** `easy-gl/CMakeLists.txt:20` — `add_subdirectory(../meta-gl meta-gl)`; `:98` — `target_link_libraries(easy-gl PUBLIC meta-gl::meta-gl)`. The dependency is unconditional and non-optional. CNA's own error message documents the chain: *"easy-gl itself expects its own sibling '../meta-gl' checkout (branch 'develop' of meta-gl)"* (`cna/cmake/RendererSelection.cmake:459-460`). — **VERIFIED**

3. **Public API: one namespace, `easygl`, 30 headers under `include/easygl/`, one umbrella `easygl.hpp`.** Resource classes: `Buffer`, `Framebuffer`, `Program`, `ProgramPipeline`, `Query`, `Renderbuffer`, `Sampler`, `Shader`, `Sync`, `Texture`, `TransformFeedback`, `VertexArray`. Support: `Device` (init, state, draw), `Capabilities`, `ContextInfo`, `Feature`, `Config`, `Types`, `Exception`, `Export`, `Version`. RAII/lifetime helpers: `ScopedBind`, `ScopedDebugGroup`, `ResourceRegistry`, `ResourceRegistration`, `RecoverableResource`, `UniformCache`, and `detail/GenerationTracked` + `detail/NonCopyable`. All 30 are declared as a CMake `FILE_SET HEADERS` (`CMakeLists.txt:52-95`). — **VERIFIED**

4. **Architecture: move-only RAII over meta-gl's typed handles.** All resource classes are non-copyable/move-only; base `detail::GenerationTracked` supplies `handle_`, `generation_`, `is_created()`, `native_handle()`; meta-gl typed handles (`BufferId{handle_}`, `TextureId{handle_}`, …) are wrapped at every call site; `UniformLocation`/`AttribLocation` are typed structs requiring explicit wrapping (`NEXT.md:14-19`). — **STRONG** (from `NEXT.md`, corroborated by the header list and CNA ch37's independent finding that 19 easy-gl headers include meta-gl headers).

5. **Error model: C++ exceptions — and this is the one place it diverges hard from meta-gl.** `include/easygl/Exception.hpp` defines `UnsupportedFeatureException`. `cmake/EasyGlPlatform.cmake:5-15` spells out the consequence: *"easy-gl (unlike meta-gl, which uses a `std::terminate()`-based Invalid Input Contract) reports unsupported/missing GL features via C++ exceptions… Emscripten requires this to be explicitly opted into via the modern Wasm exception handling proposal"* — hence `-fwasm-exceptions` applied **globally, before `add_subdirectory(meta-gl)`**, so every object file including meta-gl's agrees on the exception model. This is a genuinely interesting cross-layer design constraint and excellent book material. — **VERIFIED**

6. **WebGL support is real and recent.** Commit `1a22091` (2026-08-07) *"Fix WebGL correctness gaps: reuse meta-gl detection, gate ES3+ features, add Emscripten preset."* `Device::initialize()` now reuses meta-gl's `GetContextInfo()`/`GetCapabilities()` instead of duplicating `GL_VERSION`-string parsing and surfaces `ApiKind::WebGL` + `Capabilities::is_webgl()/is_webgl1()/is_webgl2()`. `Query`, `Sampler`, `TransformFeedback`, `Sync`, `ProgramPipeline::create()` and `Texture::get_level_parameter*()` now check `metagl::IsFunctionAvailable()` and throw `UnsupportedFeatureException` instead of dereferencing a null function pointer. VAO support below GLES/WebGL 3.0 now requires `GL_OES_vertex_array_object` to be advertised rather than being silently assumed. `ProgramPipeline.hpp` documents that separable shader programs have **no WebGL equivalent at all — not even WebGL 2 — a permanent gap, not a version tier.** (`NEXT.md` §3.) — **STRONG**

7. **Tests: 4 hand-rolled smoke binaries, all mock-loader based, no real GL context required.** `tests/CMakeLists.txt` registers `easy-gl-smoke-tests` (`smoke/SmokeInitTests.cpp`, 131 L), `easy-gl-resource-smoke-tests` (`SmokeResourceTests.cpp`, 479 L), `easy-gl-context-lifecycle-tests` (`ContextLifecycleTests.cpp`, **664 L — the largest file in the repo**), `easy-gl-webgl-tests` (`WebGLTests.cpp`, 317 L). The first two are **skipped under Emscripten** (`tests/CMakeLists.txt:9`) with an explicit rationale: they mock desktop-OpenGL-shaped `GL_VERSION` strings a real WebGL host can never report, because meta-gl always classifies `__EMSCRIPTEN__` builds as `ApiKind::WebGL`. What they assert: ResourceRegistry context-loss/restore cycles, GLES2/GLES3 tiered mock loaders, `ApiKind::WebGL` classification, `GL_OES_vertex_array_object` gating, and `UnsupportedFeatureException` (not a crash) from the six entry points above. — **VERIFIED**

8. **★ CNA builds easy-gl's tests and examples, because it never turns them off.** `easy-gl/cmake/EasyGlOptions.cmake:2-3` sets `EASYGL_BUILD_TESTS` and `EASYGL_BUILD_EXAMPLES` to **ON by default**, and `grep -rn 'EASYGL_BUILD' cna/CMakeLists.txt cna/cmake/*.cmake` returns **nothing**. So any of CNA's five GL-profile builds also compiles 4 easy-gl test binaries. The example is self-limiting — `examples/integration-placeholder/hello-triangle-sdl/CMakeLists.txt:1-6` does `find_package(SDL3 QUIET)` and returns early if not found — but since CNA has already vendored SDL3 targets, this may well build too. Contrast `cna/CMakeLists.txt:95`, which explicitly forces `SHARP_RUNTIME_BUILD_TESTS OFF`. **This is an unremarked asymmetry in CNA's build and a genuine, checkable finding.** — **VERIFIED** (config-level; no build was run, per the read-only constraint)

9. **Recent history (85 commits, whole first-parent log read).** Two eras separated by a six-week gap: a single enormous 2026-06-27 feature day (≈65 commits, task-coded `F1`–`T1`: state getters, indexed blend/color-mask, advanced draw calls, debug message API, separable programs, buffer textures, compressed sub-images, `ScopedBind`, `ScopedDebugGroup`, `UniformCache`, `ResourceRegistration`), then five commits on 2026-08-07: `c4f1a71` (adapt to meta-gl's split typed enums `ClearBuffer`/`TextureParameter`/`InternalFormat`), `1a22091` (WebGL correctness), `721ae4f`/`d618d6a` (delete stale `TODO.md` and `MIGRATION.md`), `0b46d35` (Texture `bind()`/`active_bind()` semantics + regression test). — **VERIFIED**

10. **The HEAD commit fixes a real behavioral regression.** `0b46d35`: `Texture::bind(target)` activates and uses texture unit 0; `active_bind(unit, target)` uses the given unit; both leave that unit active. This *restores behavior lost in an earlier refactoring* — `bind()` previously did not call `glActiveTexture` at all. Covered by `test_texture_bind_and_active_bind_semantics` in `tests/smoke/SmokeResourceTests.cpp`, and the stale `texture.bind(unit)` example in `CLAUDE.md` was corrected. (`NEXT.md` §3.) — **STRONG**

## SIZE TABLE — easy-gl

| Metric | Value |
|---|---:|
| Tracked files | **71** |
| Public headers (`include/easygl/`) | **30** files / **1,485** lines |
| Implementation (`src/`) | **21** files / **~3,256** lines |
| Tests (`tests/smoke/`) | **4** files / **1,591** lines |
| `src/` + `include/` physical (excl. tests/examples) | **4,449** lines |
| `src/` + `include/` **code** (cloc) | **3,606** (2,468 C++ + 1,138 headers; +167 comment, +682 blank) |
| CMake | **216** lines |
| Markdown | **1,455** lines |
| Commits | **85** |
| Largest files | `tests/smoke/ContextLifecycleTests.cpp` 664 · `src/Device.cpp` 658 · `src/Program.cpp` 529 · `tests/smoke/SmokeResourceTests.cpp` 479 |

```bash
git -C easy-gl ls-files | wc -l
git -C easy-gl ls-files 'include/*' 'src/*' | grep -Ev '(^|/)tests?/|examples' \
  | grep -E '\.(hpp|h|cpp|c|inc)$' | sed 's|^|easy-gl/|' | xargs wc -l | tail -1
cloc --quiet --exclude-dir=tests,examples,build,cmake-build-debug easy-gl/src easy-gl/include
git -C easy-gl rev-list --count HEAD
```

## CONTRADICTIONS — easy-gl

| # | Claim | Reality | Confidence |
|---|---|---|---|
| C1 | `README.md:3` and `:45` — *"toolkit-independent **C++20** wrapper"*, *"C++20 compiler"*. | `CMakeLists.txt:26` sets `CXX_STANDARD 23` and `:100` `target_compile_features(easy-gl PUBLIC cxx_std_23)`. **easy-gl is C++23**, and it propagates `cxx_std_23` to consumers. `NEXT.md` §2 already flags this as open task W1. Cite C++23. | VERIFIED |
| C2 | `README.md:16` — *"Current focus is a small working vertical slice (Hello Triangle first)."* | Severe underclaim. The 2026-06-27 feature day added ~65 API commits: compute dispatch, transform feedback, sync objects, separable programs, program/shader binaries, indexed blend state, debug groups, buffer textures. The README describes a project two months behind the code. | VERIFIED |
| C3 | `README.md:57` — *"`EASYGL_BUILD_TESTS` (default `ON`)"* … and `README.md:52` documents `EASYGL_BUILD_SHARED`. | Options themselves match `cmake/EasyGlOptions.cmake:1-5`. The unstated consequence is FACT 8: CNA inherits both defaults. | VERIFIED |
| C4 | `README.md:107-129` "Minimal render flow" example. | Uses `vao.set_attribute_pointer(...)`, `program.use()`, `device.draw_arrays(...)` — API shapes consistent with the current headers, but the README predates the `Texture::bind()`/`active_bind()` split (FACT 10) and the WebGL feature gating. Treat README examples as approximately-current, not authoritative. | PROBABLE |
| C5 | Book `ch37-easygl-deep-dive.tex:9` — section titled *"A layer this book did not cover: meta-gl."* | Honest at the time, but now a self-declared gap in a book whose own `appendix-d` calls meta-gl the **larger** of the two libraries (8.3k vs 3.6k). See §3 BOOK IMPACT. | VERIFIED |
| C6 | Book `appendix-d-repo-map.tex:193` — easy-gl *"~3.6k"*. | **cloc reproduces 3,606 exactly.** The book's figures are cloc-derived, `src/`+`include/` only. Keep the methodology note; the number is still correct. | VERIFIED |

---

# 3. meta-gl

## IDENTITY
`/rv/data/development/github.com/openeggbert/meta-gl` · `develop` @ `571d3a62fe166b9781ac6193d137b12ff3757620` · 2026-08-07 · local == origin · **staged + modified `VERSION`** (uncommitted, `0.4.0-snapshot`) · 135 commits · tags: `v0.2.0`, `archive/preintegration/metagl-followup-audit-20260804`.

## FACTS — role, and the split versus easy-gl

1. **meta-gl is the lower layer: a low-level, procedural, type-safe C++23 wrapper over OpenGL ES 2.0–3.2 and the common programmable subset of desktop OpenGL 3.3+.** ES older than 2.0 and desktop GL older than 3.3 are explicitly unsupported. `README.md:3-6`. — **VERIFIED**

2. **★ The split, stated by meta-gl's own README (`:9-21`) and confirmed in both build files:**
   ```
   Host application  →  provides GL context + GetProcAddress callback
     └── easy-gl   (OOP/RAII wrapper, namespace easygl)
           └── meta-gl  (function pointers + type-safe API, namespace metagl)
                 └── actual OpenGL driver
   ```
   The division of labour is precise and worth quoting: **meta-gl owns typed enums, typed handles, function loading, capability/context tracking, and per-call validation; easy-gl owns *ownership*.** `meta-gl/NEXT.md:24-26`: *"`meta-gl` deliberately does not provide RAII resource ownership, engine abstractions, or an object-oriented rendering API. Typed handles are lightweight identifiers only; ownership belongs in `easy-gl`."* — **VERIFIED**

3. **The second axis of the split is the error model, and it is the sharper distinction.** meta-gl enforces an **Invalid Input Contract even in Release**: contract violations (`size_t`→`GLsizei` overflow, incomplete matrix data, unsupported bitfields) call `std::terminate()` immediately (`README.md:98-106`). easy-gl throws C++ exceptions instead (see §2 FACT 5). *The same stack uses two incompatible failure philosophies one layer apart, deliberately* — and that is what forces the global `-fwasm-exceptions` in `easy-gl/cmake/EasyGlPlatform.cmake`. **This is the single best paragraph available for a meta-gl section.** — **VERIFIED**

4. **Public API: namespace `metagl`, 12 headers under `include/metagl/`, umbrella `metagl.hpp`.** `Capabilities`, `Context`, `ContextEvents`, `Debug`, `DesktopEsTier`, `Emscripten`, `EnumNames`, `Enums`, `Functions`, `Loader`, `Types`. Plus vendored Khronos headers under `third_party/Khronos/` (`GLES2/gl2ext.h`, `GLES3/gl32.h`, `GLES3/gl3platform.h`, `KHR/khrplatform.h`, MIT-licensed) so consumers need no separate GLES dev package (`README.md:34-37`). — **VERIFIED**

5. **358 typed `metagl::gl*` wrappers — VERIFIED exactly.** `grep -cE '^    // #[0-9]+$' src/Functions.cpp` → **358**, and `tools/verify_api.py:26-42` enforces that the markers form the contiguous range 1..358 with 358 unique names, failing the build otherwise. The verifier also cross-checks the exact mandatory sets added by GLES 3.0/3.1/3.2 — **104 / 68 / 44** (`tools/verify_api.py:119`) — against the vendored `gl32.h`, with the ES 2.0 baseline validated directly by `minimum_loaded()`. — **VERIFIED**

6. **Enum and handle counts — NEXT.md is wrong on both.** `NEXT.md:69-70` claims *"99 enum classes and 15 lightweight handle/location/index types."* Actual: **105 `enum class` in `Enums.hpp`, 108 repo-wide** across `include/metagl/*.hpp`; **16 struct declarations in `Types.hpp`** (`ShaderId`, `ProgramId`, `TextureId`, `BufferId`, `FramebufferId`, `RenderbufferId`, `SamplerId`, `VertexArrayId`, `QueryId`, `TransformFeedbackId`, `ProgramPipelineId`, `UniformLocation`, `AttribLocation`, `ActiveAttribIndex`, `ImageUnit`, plus `GlBitfieldTraits`) — so ~15 handle/location/index types **plus** a traits helper, which is arguably how 15 was reached. `EnumNames.hpp` carries **119** `to_string` mentions. The 358 figure is right; the 99 is not. — **VERIFIED**

7. **ABI/release discipline is unusually strict for a 12-header library.** Explicit `METAGL_API` export macro + hidden visibility (`CMakeLists.txt:45`); a linker version script `cmake/metagl.version` applied via `--version-script` on GNU/Clang (`:57-61`); `tests/test_soname.py` and `tests/test_export_symbols.py` enforce SONAME identity and exported-symbol policy; `tests/test_installed_package.cmake` + `tests/package-consumer/` prove a freshly installed package works standalone. `find_package(meta-gl 0.3 CONFIG REQUIRED)` is supported, with same-minor-version compatibility only for `0.x` (`README.md:81-90`). — **VERIFIED**

8. **Options do not leak into parent projects — a deliberate contrast with easy-gl.** `CMakeLists.txt:15-30`: `METAGL_BUILD_TESTS`, `METAGL_BUILD_GPU_TESTS`, `METAGL_BUILD_EXAMPLES`, `METAGL_BUILD_DOCS`, `METAGL_SANITIZE`, `METAGL_ENABLE_DEBUG_LOGGING`, `METAGL_DEBUG_IMMEDIATE` — **all default OFF**, and the legacy `BUILD_TESTING`/`BUILD_EXAMPLES`/`SANITIZE` aliases are honoured **only when `PROJECT_IS_TOP_LEVEL`**. So when CNA pulls easy-gl which pulls meta-gl, **meta-gl builds nothing extra**, while easy-gl builds its tests and examples. — **VERIFIED**

9. **Tests: 9 executables + Python policy tests + an opt-in GPU test.** `tests/CMakeLists.txt` registers `metagl-compile-tests` (`test_compile.cpp`), `metagl-mock-loader-test` (`test_mock_loader.cpp`), `metagl-release-contract-test` (`test_release_contract.cpp`), `metagl-thread-test` (`test_threads.cpp`), `metagl-desktop-tier-test` (`test_desktop_es_tier.cpp`), plus `metagl-soname-test` and `metagl-export-symbols-test` (Python), installed-package consumer tests, and — only under `METAGL_BUILD_GPU_TESTS` — `metagl-egl-smoke-test` (`egl_smoke.cpp`), which needs a real EGL/Mesa implementation. `METAGL_BUILD_GPU_TESTS` without `METAGL_BUILD_TESTS` is a `FATAL_ERROR` (`CMakeLists.txt:146-148`). — **VERIFIED**

10. **Recent history (135 commits).** Three phases: a 2026-06-27 documentation sprint (Doxygen across `Enums.hpp` 89 enum classes, `Functions.hpp` 358 wrappers, `EnumNames.hpp` 89+ `to_string` overloads) closing out `v0.2.0`; a 2026-07-18 hardening run (typed GL enum domains, atomic context restoration, MSVC conforming preprocessor, MSVC enum-name nesting limit, Windows DLL teardown I/O, packaging, `0.3.0` prep); and a 2026-08-07 release-gate push (`6950ad0`…`571d3a6`): installed-package consumer tests, tag-triggered release workflow, `METAGL_API` + hidden visibility, thread-local state and snapshot-based listener dispatch (R50–R60), `FormatGlError`, **desktop OpenGL ES-tier equivalence detection (R76–R78)**, export-symbol test, a debug-log shutdown use-after-free fix, and finally a missing `<exception>` include for `std::terminate()`. — **VERIFIED**

11. **`DesktopEsTier.hpp` is the newest concept and is undocumented anywhere in the book.** Added 2026-08-07 (`2b2930f`/`6be7c73`, R76–R78): it maps a desktop OpenGL context onto the equivalent OpenGL ES tier so the ES-shaped API surface can be served by a desktop driver. This is precisely the mechanism that lets CNA's `OPENGL33` profile share one implementation with `OPENGLES2`/`OPENGLES3`. — **STRONG**

## SIZE TABLE — meta-gl

| Metric | Value |
|---|---:|
| Tracked files | **54** |
| Public headers (`include/metagl/`) | **12** files / **7,177** lines |
| Implementation (`src/`) | **3** `.cpp` + 1 `.inc` / **5,445** lines |
| `src/` + `include/` physical | **12,546** lines |
| `src/` + `include/` **code** (cloc) | **9,078** — of which 222 are `RequiredFunctions.inc` **misdetected by cloc as PHP**; true C/C++ figure ≈ **8,856** (4,583 header + 4,273 C++), with **2,448 comment lines** |
| Tests | 9 `.cpp` + 3 Python/CMake test scripts |
| Vendored Khronos headers | 4 files (`third_party/Khronos/`) |
| CMake | **560** lines |
| Markdown | **1,933** lines tracked (+ `OpenGL_ES.md` at 63 KB, the ES reference used by `verify_api.py`) |
| Commits | **135** |
| Largest files | `src/Functions.cpp` **4,712** · `include/metagl/Enums.hpp` **2,121** · `include/metagl/Functions.hpp` **1,850** · `include/metagl/EnumNames.hpp` **1,763** |

```bash
git -C meta-gl ls-files | wc -l
git -C meta-gl ls-files 'include/*' 'src/*' | sed 's|^|meta-gl/|' | xargs wc -l | sort -rn
cloc --quiet --exclude-dir=tests,examples,third_party,build,cmake-build-debug \
     meta-gl/src meta-gl/include
grep -cE '^    // #[0-9]+$' meta-gl/src/Functions.cpp      # -> 358
grep -c '^\s*enum class' meta-gl/include/metagl/Enums.hpp  # -> 105
```

## CONTRADICTIONS — meta-gl

| # | Claim | Reality | Confidence |
|---|---|---|---|
| C1 | **`NEXT.md:3-5` — *"Updated on 2026-07-19 for the isolated `feature/followup-audit` worktree. The shared `develop` worktree remains unchanged at `d51fcd7`; the follow-up changes described here are not committed or merged."*** | **Entirely stale.** They *were* merged; develop is `571d3a62`; and `d51fcd7f` is now **unreachable from any ref** (`git branch -a --contains d51fcd7f` → empty). A reader following NEXT.md's own instructions cannot reproduce the state it describes. **This is the single most misleading document in the two GL repos.** | VERIFIED |
| C2 | `NEXT.md:69` — *"99 enum classes"*; `:70` — *"15 lightweight handle/location/index types"*. | 105 in `Enums.hpp` (108 repo-wide); 16 structs in `Types.hpp`. See FACT 6. | VERIFIED |
| C3 | `NEXT.md:36` / `CMakeLists.txt:4` — version `0.3.0`. | Uncommitted `VERSION` file says `0.4.0-snapshot`, staged as a new empty file *and* modified in the worktree. Not part of any commit. **Cite 0.3.0.** | VERIFIED |
| C4 | `NEXT.md:56` — *"passes all 5 tests."* | `tests/CMakeLists.txt` registers 9+ tests (5 C++ executables + 2 Python policy tests + installed-package tests + optional EGL). The "5" counts C++ executables only. | VERIFIED |
| C5 | Commit `c5b5a56` (2026-06-27) — *"Add Doxygen documentation to Enums.hpp (**89** enum classes)"* vs `NEXT.md` **99** vs actual **105**. | Three different numbers across three artifacts. The count grew (typed-enum splits landed 2026-07-18 `95d7477` and 2026-08-07 `c4f1a71`); nobody updated NEXT.md. | VERIFIED |
| C6 | Book `appendix-d-repo-map.tex:194` — meta-gl *"~8.3k"*. | Now ~8,856 code lines (same cloc scope, discounting the .inc misdetection). Consistent with `git diff --shortstat 9ac4be4 571d3a6 -- include src` = **13 files changed, +1,452 / −870** since the July snapshot. Figure is ~550 lines stale. | VERIFIED |
| C7 | CNA `integration/INTEGRATION_BRANCH_INVENTORY.md:536-543` — *"The public backends supplied by this lane are exactly **four**."* | **Five as of 2026-08-11.** See §6 Q1. | VERIFIED |

---

# 4. free-direct

## IDENTITY
`/rv/data/development/github.com/openeggbert/free-direct` · `develop` @ `934f72ff0c52902631fceeb52c006f3ed2767485` · 2026-07-18T14:15:40+02:00 · local == origin · clean.
**Zero commits on any ref since 2026-07-18** (`git log --since=2026-07-18 --all` → empty; `for-each-ref` shows only `develop`@2026-07-18 and `master`@2026-04-21). **Nothing about free-direct has changed since the existing book was written.**

## FACTS

1. **Purpose: a C++20 reimplementation of a narrow, game-driven subset of DirectX 3 (2D only) over SDL3, layered on free-api.** `README.md:6-8`, `CLAUDE.md:14-30` (*"exactly two named target games"* — Free Eggbert / Speedy Blupi and Planet Blupi). — **VERIFIED**

2. **It implements DirectDraw + DirectSound + DirectPlay. Direct3D is genuinely absent.** `grep -rli "direct3d\|d3d" include/ src/` → **zero files**. The README's *"Direct3D → Not implemented"* is accurate. Public interfaces: `IDirectDraw`, `IDirectDrawSurface`, `IDirectDrawPalette`, `IDirectDrawClipper` (`include/ddraw.h:316-324`); `IDirectSound`, `IDirectSoundBuffer` (`include/dsound.h:38-39`); `IDirectPlay`, `IDirectPlay2A` (`include/dplay.h:24-26,271-297`). All three headers `#include <windows.h>` — i.e. **free-api's**. — **VERIFIED**

3. **★ Per-method honesty census — 95 `@note Status:` tags across the 3 public headers: 56 IMPLEMENTED / 23 PARTIAL / 16 STUB.** By header: `ddraw.h` 24/12/7, `dplay.h` 12/7/7, `dsound.h` 20/4/2. Every public method carries a Doxygen status tag. **This is unusual, verifiable, and exactly the kind of table a book chapter should reproduce.** — **VERIFIED** (`cat include/*.h | grep -o 'Status: [A-Z_]*' | sort | uniq -c`)

4. **Namespaces: `free_direct_directdraw`, `free_direct_directplay`, `free_direct_diag` — snake_case, deliberately different from free-api's `FreeApi::Internal`.** Public headers are global-namespace, DirectX-shaped C++ (abstract structs with `virtual HRESULT WINAPI` methods). One cross-repo internal reach: `src/diagnostics/Diagnostics.cpp:18` re-declares `namespace FreeApi::Platform { long ReadRssKB(); }`. — **VERIFIED**

5. **Implementation depth: real, not a stub shell.**
   - `src/directdraw/DirectDrawSurface.cpp` (840 L) — real CPU pixel buffers, SDL texture upload on `Flip`, a surface registry for renderer invalidation, diagnostics accounting. `Blt` at `:321`, `BltFast` at `:444`, `Lock`/`Unlock` at `:725`/`:753`, `Flip` at `:812`. The two honest stubs are exactly as documented: `IsLost()` and `Restore()` both unconditionally `return DD_OK` (`:531-540`).
   - `src/directsound/DirectSound.cpp` (797 L) — real `SDL_OpenAudioDevice`/`SDL_CreateAudioStream`/`SDL_BindAudioStream`, shared-device singleton with mutex, `10^(cB/2000)` volume conversion (`:127`), constant-power pan (`:151-153`), a 64 MiB buffer ceiling, and a subtle `PCMWAVEFORMAT` vs `WAVEFORMATEX` offset fix (`:265-266`).
   - `src/directplay/DirectPlayInternal.hpp` (**933 L**) holds the real `DirectPlay2AImpl` entirely inline: broadcast (`:503`, `:666-701`), host-side relay (`:824-847`, "Decision 21").
   **Caveat worth stating:** `src/directplay/DirectPlay2A.cpp` is **11 lines** and `DirectPlaySession.cpp` is **6 lines** — empty TUs that only include the header, existing *"to give it its own discoverable CMake source entry"* (`DirectPlay2A.cpp:5-9`). A file-count reading of `src/directplay/` overstates how split-up that subsystem is. — **VERIFIED**

6. **ENet is opt-in and OFF by default — so a stock free-direct has no real networking.** `CMakeLists.txt:67` defaults `FREE_DIRECT_ENABLE_ENET` to OFF; `:70-98` resolve either the `third_party/enet` submodule or system libenet via pkg-config, aliased `FreeDirect::ENet`, linked **PRIVATE**; `:189-202` add `EnetDirectPlayTransport.cpp` and `DirectPlayDiscovery.cpp` **only in that branch**. DirectPlay is in-process loopback only in a default build. Real UDP peers live in `EnetDirectPlayTransport.cpp` (303 L) and `ENET_HOST_BROADCAST` LAN discovery in `DirectPlayDiscovery.cpp:148-183`. — **VERIFIED**

7. **Header hygiene is machine-enforced.** `tests/check_header_hygiene.sh` fails the build if any SDL3/SDL3_net/ENet identifier appears in `include/`, so free-direct's public surface leaks no backend types. — **VERIFIED**

8. **Tests: 9 CTest tests by default (10 with ENet), hand-rolled, ~837 assertions, default OFF.** `FREE_DIRECT_BUILD_TESTS` defaults **OFF** (`CMakeLists.txt:221-224`). Tests: `directplay_tests` (2,218 L, 424 CHECK sites — the largest file in the repo), `directdraw_tests` (1,454 L, 210), `directsound_tests` (648 L, 102), `directsound_nodriver_test` (own process, forced bad `SDL_AUDIODRIVER`), `integration_tests` (230 L, 29), three compile-only `header_smoke_{ddraw,dplay,dsound}`, `header_hygiene` (bash), and opt-in `enet_directplay_tests` (520 L, 72). No third-party framework — a per-file `#define CHECK(expr) Check((expr), #expr, __FILE__, __LINE__)`. Notably self-honest: `tests/directplay_tests.cpp:20-31` records that the suite **fails 29/61 checks by design** if built with ENet enabled, because loopback and ENet have different timing semantics. — **VERIFIED**

9. **★ Consumers: CNA plus two independent games — and the games consume it differently from CNA.** `free-eggbert/CMakeLists.txt:100,105-107` and `planetblupi/CMakeLists.txt:102,109-111` each do `add_subdirectory(../free-api FREE_API)` **first**, then `add_subdirectory(../free-direct FREE_DIRECT)`. CNA does not — it relies on free-direct pulling free-api in itself. (`mobile-eggbert/CMakeLists.txt:71` mentions free-direct only in a comment; it is *not* a consumer.) — **VERIFIED**

10. **CNA's FreeDirect renderer is a deep consumer, not a thin shim.** `modules/renderers/freedirect/src/FreeDirectRenderer.cpp` is **1,374 lines** (+ 216-line header): `IDirectDraw::CreateSurface` (`:119`), `Lock`/`Unlock` pixel round-trips for write/read/clear (`:127-192`), and a full **CPU compositor** doing quad blending through locked surfaces (`:332-443`), plus a shadow-backbuffer resize transaction with failure injection. Ten example/test files, 8 registered CTest binaries, all under `SDL_VIDEODRIVER=dummy` reading back through the shadow backbuffer. — **VERIFIED**

11. **★ A containment hazard that deserves a page of its own.** `FreeDirectRenderer.hpp:5-12` deliberately does **not** include `<ddraw.h>`, because free-direct's `<ddraw.h>` pulls free-api's `<windows.h>`, which **globally `#define fopen free_api_fopen`** (`free-api/include/windows.h:179`). That macro would otherwise rewrite `fopen()` in every translation unit across CNA. All ddraw usage is hidden behind a pimpl in the `.cpp`. This is a genuine, correctly-identified, cross-repository hazard — and a superb concrete illustration of what "reimplementing Win32" actually costs a consumer. — **VERIFIED**

12. **Do not confuse FREEDIRECT with CNA's DIRECTX1/2/3/5/6/7 renderers.** Those also `#include <ddraw.h>` but resolve it to the **real Microsoft/Wine DirectDraw SDK** via MinGW cross-compile — `modules/renderers/directx3/CMakeLists.txt:5-6` links `SDL3::SDL3 ddraw dxguid`, no free-direct; `modules/renderers/directx1/CMakeLists.txt:2` says so explicitly (*"no free-direct, no DXVK"*); `cna/cmake/RendererSelection.cmake:63-64` confirms DIRECTX3 *"deliberately does NOT use ../free-direct."* The FREEDIRECT renderer was itself **named DIRECTX3 until 2026-08-04**, when it was renamed by owner instruction (`RendererSelection.cmake:77-79`). — **VERIFIED**

## SIZE TABLE — free-direct

| Metric | Value |
|---|---:|
| Tracked files | **66** |
| Public headers (`include/`) | **3** (`ddraw.h` 439 · `dplay.h` 309 · `dsound.h` 212) |
| Implementation (`src/`, incl. private `.hpp`) | ~30 files |
| `src/` + `include/` physical | **7,039** lines |
| `src/` + `include/` **code** (cloc) | **4,311** (2,487 C++ + 1,824 headers; **+2,009 comment**) |
| Tests | 9 `.cpp` + `TestHelpers.hpp` + a bash hygiene script / ~**5,070** lines / ~**837** CHECK sites |
| CMake | **380** lines |
| Markdown | **15,604** lines (`plan.md` 110 KB · `NEXT.md` 35 KB · `CLAUDE.md` 25 KB · 12 `docs/` files) |
| Public-method status | **56 IMPLEMENTED / 23 PARTIAL / 16 STUB** |
| CNA-side consumer | `FreeDirectRenderer.cpp` **1,374** L + `.hpp` **216** L + 10 example files / 8 CTest binaries |

```bash
git -C free-direct ls-files | wc -l
git -C free-direct ls-files 'include/*' 'src/*' | grep -Ev '(^|/)tests?/|third_party' \
  | grep -E '\.(hpp|h|cpp|c)$' | sed 's|^|free-direct/|' | xargs wc -l | tail -1
cloc --quiet --exclude-dir=tests,third_party,build free-direct/src free-direct/include
cat free-direct/include/*.h | grep -o 'Status: [A-Z_]*' | sort | uniq -c
```

## CONTRADICTIONS — free-direct

| # | Claim | Reality | Confidence |
|---|---|---|---|
| C1 | `CLAUDE.md:8-9` — *"see `NEXT.md` (**does not exist yet**…)"* | `NEXT.md` is 35,100 bytes and was **written in the HEAD commit itself** (`934f72f` *"Refresh NEXT.md after the full plan.md phase sweep"*). The charter was never updated. | VERIFIED |
| C2 | `NEXT.md:3` — *"Last updated: 2026-07-19, after commit `af80a98`."* | `af80a98` exists as an object but **is not an ancestor of HEAD**; the on-branch commit with that subject is `020c879`. Also HEAD's date is **2026-07-18** while NEXT.md and 3 commit messages claim 2026-07-19 — the docs are dated a day ahead of the history they describe. | VERIFIED |
| C3 | `NEXT.md` — *"189/189 atomic `TASK-24H-XXXX` tasks DONE (grep-verified)."* | Running that grep on the **live** `plan.md` yields **0** `### TASK-24H-` headings. The 189 figure is reproducible only against `archive/plan20260718.md`. Defensible, but not verifiable by its own stated recipe. | VERIFIED |
| C4 | README's per-method status table. | **Matches the code.** `IsLost`/`Restore` listed STUB → `DirectDrawSurface.cpp:531-540` unconditionally returns `DD_OK`. Direct3D listed absent → zero d3d files. Broadcast/relay/LAN-discovery claims → real code at the cited lines. **The README is the most trustworthy document in this repo.** | VERIFIED |
| C5 | Doc volume vs code volume. | `plan.md` (110 KB) + `archive/plan20260718.md` + `NEXT.md` (35 KB) + `CLAUDE.md` (25 KB) + 12 `docs/` files **substantially exceed** the ~3,900 lines of non-test library source. | VERIFIED |
| C6 | Book `ch02-ecosystem-map.tex:57,63,67` — *"`-DCNA_GRAPHICS_BACKEND`"* and *"`BackendSelection.cmake`'s own comment."* | **Both renamed.** The variable is `CNA_GRAPHICS_RENDERER`; the file is `cmake/RendererSelection.cmake` (`ls cna/cmake | grep -i backend` → empty). The quoted comment is now at `RendererSelection.cmake:465-471`. **These are stale cross-references in the existing book that must be fixed.** | VERIFIED |
| C7 | 2026-07-18 commit day. | ~20 of the top 22 commits are pure bookkeeping (`Close Phase N`, `Cancel …`, `Fix NEXT.md staleness`, `Delete TODO.md`), several closing items *already implemented* but never checked off (`07925c3`, `99e0a08`). The only code changes that day were two pure refactors (`dd3b4d7` split DirectDraw.cpp, `d69d8c7` split DirectPlay.cpp) — one of which produced the 6- and 11-line placeholder TUs. **Last real feature work: `147a74e` (2026-07-09), GPU-side palette lookup for 8-bit DirectDraw surfaces.** | VERIFIED |
| C8 | Book `appendix-d-repo-map.tex:193` — free-direct *"~4.3k"*. | **cloc reproduces 4,311 exactly**, and the repo is frozen. **This number is still correct.** | VERIFIED |

## BOOK IMPACT — free-direct

**Current treatment: `ch25-dx3-freedirect-backend.tex` (322 lines) + `ch38-freedirect-deep-dive.tex` (65 lines) = 387 lines.** The 65-line "deep dive" is the shortest chapter in the book and is not a deep dive by any measure.

**Verdict: yes, it deserves a real chapter — one substantial chapter, not two, and roughly 250–350 lines of new material.** The case rests on five things the current 65 lines cannot contain:

1. **It is three DirectX APIs, not one.** DirectDraw *and* DirectSound *and* DirectPlay — with a wire protocol, session management, a transport interface with two implementations, and LAN discovery. The book currently frames it as a DirectDraw backend.
2. **The 56/23/16 per-method status census.** A reproducible, verifiable table of exactly what a DirectX-3 reimplementation does and does not cover. Nothing else in the ecosystem offers this shape of evidence.
3. **The `fopen` macro containment hazard (FACT 11).** The single best concrete illustration in the whole book of what consuming a Win32 reimplementation costs — and CNA's pimpl-based defense is a real, quotable engineering decision.
4. **It has three consumers, and CNA is the odd one out.** free-eggbert and planetblupi add free-api explicitly; CNA gets it transitively. That asymmetry is worth a paragraph and it demolishes any framing of free-direct as CNA-specific machinery.
5. **The DIRECTX3-vs-FREEDIRECT renaming and the deliberate non-use of free-direct by CNA's six MinGW/Wine DirectX renderers.** Currently a live source of confusion; `RendererSelection.cmake:63-64,77-79` settles it.

Merge the two existing chapters into one. Two chapters split 322/65 is worse than one chapter of ~600.

---

# 5. free-api

## IDENTITY
`/rv/data/development/github.com/openeggbert/free-api` · `develop` @ `53d7a3124110fb30eea370a42c86ccff0c39aef3` · 2026-07-18T15:29:20+02:00 · local == origin · clean. **Zero commits on any ref since 2026-07-18.**

## FACTS

1. **Purpose: a static C++20 library reimplementing a deliberately tiny subset of the Win32 API on top of SDL3**, so exactly two legacy games compile and run without Windows. `README.md:6-10` (*"roughly targeting ~1998 (Win32 era)"*), `README.md:33-38` (*"targets exactly two games… It is **not Wine** and not a general Win32 SDK reimplementation."*). — **VERIFIED**

2. **★ Does CNA depend on it? YES — transitively, hard, and load-bearing.** `free-direct/CMakeLists.txt:24-26` — `if(NOT TARGET free-api) set(FREE_API_BUILD_TESTS OFF); add_subdirectory(../free-api FREE_API) endif()`; `:180-182` — `target_link_libraries(free-direct PUBLIC free-api::free-api)`. **PUBLIC**, so it propagates to every consumer. CNA never calls `add_subdirectory(../free-api)` itself — its only three mentions of free-api are *comments* (`cmake/RendererSelection.cmake:467,470`; `modules/renderers/freedirect/CMakeLists.txt:2`). But when `CNA_GRAPHICS_RENDERER=FREEDIRECT`, free-api is compiled and linked into CNA, and its `<windows.h>` (with the `fopen` macro) becomes reachable from CNA's renderer TU. **The book's existing claim — `appendix-d-repo-map.tex:56-63`, "a real, second-level dependency… not itself a direct `cna` dependency" — is exactly right, and was found the right way (by reading a sibling's build files).** — **VERIFIED**

3. **The public surface is C, not C++-namespaced.** ~80 `extern "C"` `WINAPI` declarations across 23 flat Win32-named headers in `include/`: `basestd.h, commdlg.h, debugapi.h, digitalv.h, direct.h, free_api_bridge.h, handleapi.h, io.h, mciapi.h, minwindef.h, mmiscapi2.h, mmsystem.h, rpcndr.h, synchapi.h, sysinfoapi.h, winbase.h, windef.h, windows.h, windowsx.h, winerror.h, wingdi.h, winnt.h, wtypes.h` (+ `winuser.h`). `windows.h` is a real umbrella pulling the rest. Internal namespaces are `FreeApi::Internal` and `FreeApi::Platform`. Every header carries a Doxygen `@note Status: IMPLEMENTED/PARTIAL/STUB/HEADER_ONLY` tag. — **VERIFIED**

4. **`include_non_windows/` is a case-sensitivity shim directory, not a subsystem.** `Windows.h` and `WinUser.h` are 12-line forwarders to the lowercase real headers; `sys/timeb.h` is real code (`struct timeb` + `ftime()` via `std::chrono`). Wired into a separate `freeapi_compat_headers` INTERFACE target (`CMakeLists.txt:279`, installed at `:743`). This matters because free-eggbert's and planetblupi's CMakeLists both comment on it at their line 20-21. — **VERIFIED**

5. **`include/free_api_bridge.h` is the free-direct seam.** Three functions — `FreeApiCreateSurfaceDC`, `FreeApiDestroySurfaceDC`, `FreeApiSetWindowFullscreen` — that exist *solely* for free-direct (`free_api_bridge.h:1-22`), consumed at `free-direct/src/directdraw/DirectDraw.cpp:15` and `DirectDrawSurface.cpp:13`. A documented, deliberate scope exception. — **VERIFIED**

6. **Subsystems, all real:** window/message loop (`src/internal/FreeApiMessageQueue.cpp`, 441 L — SDL events → Win32 `MSG`), window creation over `SDL_Window` (`src/winuser_window.cpp`, 397 L), input translation, GDI-lite (DC/bitmap/blit), file+path CRT shims, user + multimedia timers, **MCI/MIDI music** (`src/MidiMusic.cpp`, 895 L — a genuine shared SDL3 audio stream, background mixing thread, TSF synthesis, SoundFont lookup chain, `MM_MCINOTIFY` posting), **joystick** (`src/winmm.cpp:238-306`, real `SDL_Joystick` behind `joyGetPosEx`), string resources (RC → generated C++ via `cmake/ExtractStringTable.cmake`, 262 L), and diagnostics/RSS. `HWND` is internally an `SDL_Window*` cast to `void*` (`include/windef.h:8`); **public headers never expose SDL types.** — **VERIFIED**

7. **Dependencies: SDL3 / SDL3_image / SDL3_mixer only, plus two vendored single-header libraries.** `CMakeLists.txt:43-45` (find_package floors 3.4.0/3.4.0/3.2.0), `:328-334` link, `:48-55` hard error if absent. Vendored: `external/tsf.h` (TinySoundFont, 2,079 L) and `external/tml.h` (TinyMidiLoader, 531 L). **No enet. No sharp-runtime. No dependency on free-direct** — the relationship is strictly one-directional. Exports as `free-api::free-api` (`:259-260`). — **VERIFIED**

8. **Tests: 29 CTest registrations, hand-rolled, gated OFF when consumed as a subdirectory.** 20 test `.cpp` + 9 CMake-script-level tests (hardcoded-path scan, public-surface baseline + self-tests, 5 `ExtractStringTable` fail-loud negative controls, an `SDL_Log` gating source scan). Framework is a static `g_failures` counter + `Check(bool, const char*)` (`tests/test_winuser_regressions.cpp:75-85`). `FREE_API_BUILD_TESTS` is ON standalone, **OFF when consumed as a subdirectory** (`CMakeLists.txt:365-370`) — and free-direct forces it OFF anyway (`free-direct/CMakeLists.txt:25`). What they assert: SDL→`WM_*` translation fidelity and VK sweeps, `PeekMessage` filters/coalescing, timer races under TSan, GDI blit clamping and bitmap-leak accounting, path normalization lock-in, `LoadStringA` against the RC manifest, MCI open/play/notify/close sequences, MIDI silence-without-soundfont, `FreeApiRunWinMain`, `struct timeb`, quiet-by-default logging. — **VERIFIED**

9. **Backlog bookkeeping is unusually accurate.** `NEXT.md` §2 claims *"220 tasks total — 215 DONE, 1 OBSOLETE, 4 TODO"*; actual `grep -cE '^### TASK-(24H-)?[0-9]{4}' plan.md` = **220** and `grep -c '^Status: DONE'` = **215**. Exact match. The 29-test claim also matches exactly. — **VERIFIED**

10. **★ The quality signal the book should not omit.** On 2026-07-18, commit `88f1c80` *"Fix 9 findings from an independent 5-lens re-audit"* was **immediately followed by two self-inflicted regressions it introduced**: `05533da` *"Fix startup SIGABRT regression: reentrant magic-static initialization"* and `a903171` *"Fix real RAM regression: CreateBitmap pooling leaked into every DeleteObject."* **Both were found by user report, not by the 29-test suite.** On the same day, `dfb362d`/`52f8992` deleted `audit.md` and the performance TODO. An audit round shipped a broken binary twice in one day and then reduced its own documentation. — **VERIFIED**

## SIZE TABLE — free-api

| Metric | Value |
|---|---:|
| Tracked files | **127** |
| Public headers (`include/`) | **23** flat Win32-named headers (+3 case-shims in `include_non_windows/`) |
| Implementation (`src/`) | **26** `.cpp` |
| `src/` + `include/` + `include_non_windows/` physical | **7,755** lines |
| `src/` + `include/` **code** (cloc) | **4,505** (3,330 C++ + 1,175 headers; **+2,316 comment**) |
| Vendored (`external/`) | 2 files / **2,610** lines (`tsf.h` 2,079 · `tml.h` 531) |
| Tests | 20 `.cpp` + support / ~**7,000** lines / **29** CTest registrations |
| CMake | **1,413** lines (root `CMakeLists.txt` alone is 40 KB) |
| Markdown | **12,007** lines (`plan.md` **549 KB** · `NEXT.md` 37 KB · 13 `docs/` files) |
| Largest sources | `src/MidiMusic.cpp` 895 · `include/winuser.h` 641 · `src/winmain_bridge.cpp` 509 · `src/internal/FreeApiMessageQueue.cpp` 441 · `src/winuser_window.cpp` 397 · `src/winmm.cpp` 379 |

```bash
git -C free-api ls-files | wc -l
git -C free-api ls-files 'include/*' 'src/*' 'include_non_windows/*' \
  | grep -Ev '(^|/)tests?/|examples' | grep -E '\.(hpp|h|cpp|c)$' \
  | sed 's|^|free-api/|' | xargs wc -l | tail -1
cloc --quiet --exclude-dir=tests,examples,build free-api/src free-api/include \
     free-api/include_non_windows
```

## CONTRADICTIONS — free-api

| # | Claim | Reality | Confidence |
|---|---|---|---|
| C1 | `NEXT.md:5` and §2 pin state to commit `6ff92a6`. | `6ff92a6` is **not an ancestor of HEAD** — an orphaned/amended twin of `a903171` (identical subject). NEXT.md warns about its own staleness at `:8-12`, which is fair but does not make the reference resolvable. | VERIFIED |
| C2 | `README.md:33-38` / `NEXT.md` §1 — *"targets exactly two games."* | Now technically stale: **CNA is a third consumer** via free-direct's PUBLIC link. The docs anticipate the free-direct *bridge* exception but do not know about CNA. | STRONG |
| C3 | README's feature coverage. | **Underclaims.** No mention of joystick support (`src/winmm.cpp:14-60,238-306`), `LoadStringA` string resources (`src/internal/FreeApiStringTable.cpp` + a 262-line CMake extractor), or the diagnostics/RSS subsystem — all real code. | PROBABLE |
| C4 | Header stubs. | **Honest.** `commdlg.h` (20 L), `mmiscapi2.h` (8 L), `rpcndr.h` (21 L), `basestd.h` (25 L) declare zero functions — consistent with `windows.h:24-26`'s explicit list of unsupported areas (common dialogs, real GDI drawing, palettes, DIB sections). `src/winapi.cpp` is 31 lines and intentionally empty; `README.md:229` says so. | VERIFIED |
| C5 | Book `ch02-ecosystem-map.tex:64-71` and `appendix-d-repo-map.tex:56-63`. | **Substantively correct** — free-api is a real second-level dependency, found by reading free-direct's build files, sharing one SDL3 build across the three-level chain, with free-eggbert and planetblupi as independent consumers. The **only** errors are the two renamed identifiers in C6 of §4 (`CNA_GRAPHICS_BACKEND`, `BackendSelection.cmake`). | VERIFIED |
| C6 | Book `appendix-d-repo-map.tex:193` — free-api *"~4.5k"*. | **cloc reproduces 4,505 exactly**, and the repo is frozen. **Still correct.** | VERIFIED |

## BOOK IMPACT — free-api

**Current treatment: mentioned in `ch02` (a `sourcenote`), `ch44`, and `appendix-d`. Recommendation: no chapter. Keep it as an expanded sidebar plus a strengthened appendix entry.**

Rationale: free-api is genuinely *below* the book's subject — CNA never names it, never links it directly, and would not notice it existed but for one macro. But three things earn it more than a name-drop, and all three belong in the **free-direct** chapter rather than a chapter of its own:

1. **The `fopen` macro** — free-api is where the hazard originates; free-direct is where CNA meets it.
2. **The `free_api_bridge.h` three-function seam** — a clean, documented, deliberate scope exception, and a good model of how to keep a compatibility layer from metastasizing.
3. **The 2026-07-18 double regression (FACT 10)** — the most instructive quality anecdote in the sibling set, and a natural counterpoint for `ch48-testing-philosophy.tex`.

The existing `ch02` sourcenote is already the right shape; it needs the two renamed-identifier fixes and one added sentence about the `fopen` macro.

---

# 6. Answers to the four specific questions

### Q1 — easy-gl vs meta-gl: what is the split? Does easy-gl still back all five CNA GL profiles?

**The split is two-dimensional, and both dimensions are load-bearing:**

| | meta-gl | easy-gl |
|---|---|---|
| Namespace | `metagl` | `easygl` |
| Layer | procedural function pointers + typed enums/handles | RAII/OOP resource ownership |
| Ownership | **none** — handles are lightweight identifiers | move-only resource classes over `detail::GenerationTracked` |
| Error model | **`std::terminate()` even in Release** (Invalid Input Contract) | **C++ exceptions** (`UnsupportedFeatureException`) |
| Size (cloc) | ~8,856 code lines, 12 headers | 3,606 code lines, 30 headers |
| Standard | C++23 | C++23 (README says C++20 — wrong) |
| Options when nested | all default OFF, aliases honoured only at top level | tests **and** examples default ON |
| Dependency | none (vendors Khronos headers) | `add_subdirectory(../meta-gl)` + `PUBLIC meta-gl::meta-gl` |

meta-gl is the **larger** of the two by ~2.5×, which inverts the intuition a reader forms from "easy-gl is the library CNA uses."

**Yes — easy-gl backs all five profiles, and the fifth is brand new.** `cna/cmake/RendererSelection.cmake:546-562`: `OPENGLES2`, `OPENGLES3`, `OPENGL33`, `WEBGL1`, `WEBGL2` all resolve to `RENDERER_DIR=modules/renderers/easygl`, `RENDERER_TARGET=cna_renderer_easygl`, `add_compile_definitions(CNA_RENDERER_EASYGL)` plus `CNA_GL_PROFILE_${CNA_GRAPHICS_RENDERER}`. `:430-463` gates the sibling `add_subdirectory(../easy-gl easy-gl)` on exactly that five-way condition, with a `FATAL_ERROR` at `:453-461` naming meta-gl as easy-gl's own sibling requirement.

**`OPENGLES2` was added on 2026-08-11** (commit `33abdd8f9` *"feat(renderers): add the OPENGLES2 public GL profile identity"*), implemented per `cna/plan_opengles2.md`, which records (`plan_opengles2.md:6-9`) that OPENGLES2 is *"CNA's 42nd public renderer identity (41 → 42) and the **fifth public GL-family profile**"*, with *"The implementation-family count stays 38; only the public identity count grows."*

> **Qualification on those two numbers.** The 42/38 figures are a **dated quotation from `plan_opengles2.md`, written while the OPENGLES2 lane was in flight, and they are not current.** At the pinned CNA HEAD the settled figures are **46 public renderer identities / 42 implementation families** — the `CNA_GRAPHICS_RENDERER` cache `STRINGS` block carries 46 entries and the `GraphicsRendererType` enum 46 enumerators (independently verified by the coordinator). Quote the plan for its *design reasoning* — that OPENGLES2 is a shared-family profile rather than a new implementation — but cite **46/42** for any count the book states as current.

The plan also records, importantly for this audit: *"verified against the sibling repositories before implementation, easy-gl `develop` @ `0b46d35c`, meta-gl `develop` @ `571d3a62`… **Neither sibling was modified.**"* (`plan_opengles2.md:11-13,25-31`). OPENGLES2 is characterised as *"WEBGL1's GLSL ES 1.00 dialect + OPENGLES3's native context path + ES 2.0-only GL mechanics."*

**So `integration/INTEGRATION_BRANCH_INVENTORY.md:536-543`'s "exactly four" is stale by one, four days after it was last touched.** The document's own framing — *"EasyGL is internal and hidden. It is a support library, not a CNA backend a user selects… Do not count or expose EasyGL as an additional public CNA backend"* — remains correct and is worth quoting; only the number changed.

### Q2 — The MetaGL/EasyGL public-history rewrite: confirmed, and what it means for a book

**Confirmed, exactly.** `cna/integration/INTEGRATION_BRANCH_INVENTORY.md:3-13` records the post-campaign addendum (2026-08-09). Every claim checks out:

| Doc claim | Measured | Match |
|---|---|---|
| MetaGL `develop` = `571d3a62fe166b9781ac6193d137b12ff3757620` | `git -C meta-gl rev-parse develop` | ✅ |
| MetaGL tree = `a7771c5593a4ec4b71283d38523a0cde3fbf6d4b` | `git -C meta-gl rev-parse 571d3a62^{tree}` | ✅ |
| EasyGL `develop` = `0b46d35c394a9fb6aea6a85c6587894b5013da33` | `git -C easy-gl rev-parse develop` | ✅ |
| EasyGL tree = `e89ff546d3782e2b32e02f4b9dc56da42c4c463a` | `git -C easy-gl rev-parse 0b46d35c^{tree}` | ✅ |
| *"Those trees equal the content accepted during Batch 4"* | `c964e736^{tree}` = `a7771c55…`; `9b831dee^{tree}` = `e89ff546…` — **identical** | ✅ |

**What the rewrite actually did — and what it means for the book:**

1. **Content is byte-identical; only commit objects changed.** The pre-rewrite Batch-4 heads (`c964e736`, `9b831dee`) have exactly the same trees as the current heads. Nothing in the source changed.
2. **★ Every pre-rewrite SHA is now unreachable from any ref.** `git branch -a --contains` returns **empty** for `c964e736`, `d51fcd7f`, `d5bc155f` (meta-gl) and `9b831dee`, `62c0a248` (easy-gl). They survive locally only as dangling objects; `b52f671379c0fe6d71d8c091ee4334c348beec8e` (the EasyGL `rvc` head) **does not resolve at all**. **A book that cites any of these SHAs cites something a reader cannot look up.**
3. **The archive tags were re-pointed and their annotations are now self-contradictory.** `archive/preintegration/metagl-followup-audit-20260804` names *"Original head: `d5bc155f8e70…`"* in its annotation but its tag object points at `94121228751a…`. `archive/preintegration/easygl-rvc-20260807` names *"Original head: `b52f671379c0…`"* but points at `36f8c6465a97…`. Both tag targets have trees identical to their branch HEADs and commit dates reset to **2026-07-19** — clear rewrite artifacts. This is precisely what the addendum means by *"the external archive tags were also rewritten and are now unsigned targets with legacy annotations."*
4. **★ The rewritten public history is unsigned.** `git log --format='%G?'` returns `N` for every recent commit on both `develop` branches, and none of the three tag objects contains a PGP block. Yet `INTEGRATION_BRANCH_INVENTORY.md:544-546` says the *pre-rewrite* histories were *"100 % Robert Vokac-authored and GPG-signed (MetaGL 16/16 good, EasyGL 5/5 good)."* Both statements are true of different objects, and a careless reading produces a false claim.
5. The `Co-authored-by: Junie` trailers on 15/16 MetaGL and 5/5 EasyGL commits (`:527-531`) are what motivated the trailer-stripped replay in the first place.

**Book guidance:** state the identity as **branch + tree hash + date**, not as a commit SHA — the tree hash is the only stable identifier that survived. If a SHA must appear, use the current one and add a footnote that the public history was rewritten on 2026-08-09 with content preserved. And **do not repeat the "GPG-signed" claim** without scoping it to the pre-rewrite objects.

### Q3 — sharp-runtime: does current scope justify more than 3 chapters?

**Yes — 5 to 6 chapters.** See §1 BOOK IMPACT for the breakdown. The compressed case:

- Scope has grown materially since the existing text: **~70.7k → 78,934** code lines, **44 components** where there was one archive, **16,310 tests / 37 executables**, and a **3,828-file modularization merge** landing one day before the CNA pin.
- The three existing chapters (1,058 lines) can describe *what namespaces exist*. They cannot describe **the consumption seam** (`SharpRuntimeConsumption.cmake`'s dual-shape adapter and the 18 per-module component closures) — that machinery did not exist when they were written.
- They also omit the four facts most likely to mislead a reader: `Object` has two derivations, `String` is non-instantiable, `Exception` derives from `std::exception` with an always-empty stack trace, and `Type`'s predicates are *self-documented as mutually contradictory*.
- And they omit **the testing system as a designed artifact** — per-component link isolation as boundary enforcement, negative consumer fixtures that must fail to compile, and a 1,748-file audit apparatus with frozen `SR-AUD-###` numbering. `ch48-testing-philosophy.tex` (236 lines) is the natural home for the last of these.
- Finally, `sharp-runtime/CLAUDE.md:23` — *"No broad header refactor — naming conventions touch 449+ files and would break CNA"* — is the best single line of evidence in the ecosystem that these two repos co-evolved, and the book does not use it.

### Q4 — free-api: what is it, and does CNA depend on it?

**It is a static C++20 library reimplementing a ~1998-era Win32 subset on SDL3 (4,505 cloc lines, 23 public headers, 26 `.cpp`, 29 tests), built for two legacy games and explicitly not Wine.**

**Yes, CNA depends on it — transitively and non-optionally, whenever `CNA_GRAPHICS_RENDERER=FREEDIRECT`.** CNA never names it in a build file (only three comments); the edge is `free-direct/CMakeLists.txt:180-182`'s `PUBLIC free-api::free-api`. The dependency is not nominal: free-api's `<windows.h>` reaches CNA's renderer translation unit and globally `#define`s `fopen`, which is why `FreeDirectRenderer.hpp:5-12` refuses to include `<ddraw.h>` and hides all DirectDraw use behind a pimpl.

**The existing book already gets this right** (`ch02-ecosystem-map.tex:62-77` sourcenote, `appendix-d-repo-map.tex:56-63`) and even documents *how* it was found — by reading a sibling's build files rather than trusting a first-level dependency list. It needs only: the two renamed-identifier fixes (`CNA_GRAPHICS_RENDERER`, `RendererSelection.cmake`), one sentence about the `fopen` macro, and the note that free-eggbert and planetblupi add free-api *explicitly* while CNA does not.

---

# 7. Consolidated recommendation: chapter allocation

| Library | Now | Recommended | Net |
|---|---:|---:|---|
| sharp-runtime | 3 ch / 1,058 L | **5–6 ch** | +2–3 chapters: modularization & consumption seam; the real object model; testing/audit system; expand parity (ch36 is the thinnest at 214 L) |
| easy-gl | 2 ch / 694 L | **2 ch, revised** | Keep ch18 + ch37; fix C++20→C++23; add the CNA-builds-easy-gl's-tests finding; add WebGL feature gating |
| meta-gl | **0 ch** (a §37.1 titled *"A layer this book did not cover"*) | **1 ch, or a substantial ch37 half** | The larger of the two GL libraries. Must cover: the two-dimensional split, the `std::terminate()`-vs-exceptions contract and its `-fwasm-exceptions` consequence, the 358-wrapper verifier, ABI/SONAME discipline, `DesktopEsTier` |
| free-direct | 2 ch / 387 L (one is **65 L**) | **1 merged ch, ~600 L** | Three DirectX APIs; the 56/23/16 census; the `fopen` hazard; three consumers; the DIRECTX3→FREEDIRECT rename |
| free-api | sidebar only | **sidebar, expanded** | Correct, keep as-is plus the `fopen` macro and the double-regression anecdote |

**Highest-value single fix, independent of chapter counts:** `ch02-ecosystem-map.tex:57,63,67` cites `-DCNA_GRAPHICS_BACKEND` and `BackendSelection.cmake`, both of which no longer exist. That paragraph is where a reader first meets the sibling dependency graph, and it currently sends them to a file that isn't there.
