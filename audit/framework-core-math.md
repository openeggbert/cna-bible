# Audit report — framework core (game lifecycle) and math/core types

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root.

---

## MODULE OWNERSHIP (answering "locate precisely which module owns what")

**F1.** `Game`, `GameWindow`, `GraphicsDeviceManager`, `GameTime`, `GameComponent(Collection)`, `GameServiceContainer`, `LaunchParameters`, `TitleContainer`/`TitleLocation`, `GraphicsDeviceInformation`, `PreparingDeviceSettingsEventArgs`, `ExitingEventArgs`, and the `IGameComponent`/`IUpdateable`/`IDrawable`/`IGraphicsDeviceManager` interfaces **all live in `modules/runtime/`** — 21 headers, 15 sources, 19 test files. **VERIFIED** (directory listing).

**F2.** `modules/runtime` is the **top** of the dependency stack, not the bottom: `modules/runtime/CMakeLists.txt:3-6` links `cna_graphics_core cna_input cna_content cna_audio cna_media cna_core cna_math` PUBLIC + `SDL3` and `SDL3_mixer` PRIVATE. **VERIFIED.**

**F3.** `modules/core` is **not** the framework core. It is a tiny cross-cutting utility module: the `CNAEXT` marker macro, `Logger`/`LogLevel`/`LogCategory`, `Platform`/`DesktopOS`, `GraphicsRendererType`, `CNAException`, `Entrypoint.hpp`, `Internal/PathContainment.hpp`, `PlayerIndex`, `NamespaceDocs`. It exposes **two** CMake targets: an INTERFACE `cna_core_headers` (`CNA::CoreHeaders`) for header-only consumers and an archive `cna_core` (`modules/core/CMakeLists.txt:5-13`). **VERIFIED.**

**F4.** `modules/math` links only `sharp-runtime Core.Base` + `cna_core_headers` (`modules/math/CMakeLists.txt:1-7`) — deliberately kept to a minimal link closure, headers-only on core. **VERIFIED.**

**F5.** **`FrameworkDispatcher` is NOT in `modules/runtime`** — it is `modules/audio/include/Microsoft/Xna/Framework/FrameworkDispatcher.hpp` + `modules/audio/src/Xna/FrameworkDispatcher.cpp`, because it drives `DynamicSoundEffectInstance`, `Microphone`, `MediaPlayer` and `TouchPanel`. `Game.hpp:12` includes it across the module boundary. **VERIFIED.**

**F6.** These three modules are **brand new physical directories**, created 2026-08-10 by `7a8f5806b` ("refactor(modules): establish physical core, math and runtime modules") — a pure `git mv` from `include/` + `src/Core|Math|Xna`. Include spellings did not change. **VERIFIED** (`git show --stat 7a8f5806b`).

---

## PART 1 — FACTS: GAME LIFECYCLE AND FRAMEWORK CORE

### Game construction and disposal

**F7.** `Game::Game()` (`modules/runtime/src/Game.cpp:97-139`) **eagerly value-constructs a full `Graphics::GraphicsDevice` as a member** (`Game.hpp:329`) before any `GraphicsDeviceManager` exists. It then wires `Window_.setWindowInternal(GraphicsDevice_.GetRenderer().GetWindowInternal())` (`:134`), `Content_.setGraphicsDevice(GraphicsDevice_)` (`:135`), calls `FrameworkDispatcher::Update()` (`:137`) and `InitAudio()` (`:138`). **This is the single largest structural divergence from FNA**, where `GraphicsDeviceManager` creates and owns the device. The source names it repeatedly: `GraphicsDeviceManager.cpp:74-76`, `:377-379`. **VERIFIED.**

**F8.** Constructor defaults: `InactiveSleepTime = 20 ms`, `IsActive = false`, `IsFixedTimeStep = true`, `IsMouseVisible = false`, `TargetElapsedTime = TimeSpan(166667)` ticks (= 1/60 s exactly), `worstCaseSleepPrecision_ = 1 ms`, `RunApplication = true` (`Game.cpp:104-127`). All 128 ring-buffer sleep samples seed to 1 ms (`:129-132`). **VERIFIED.**

**F9.** `~Game()` calls `Dispose(false)` then `ShutdownAudio()` (`Game.cpp:141-145`). The `disposing == false` path **skips** the component-`Dispose()` loop, `Content_.Dispose()`, graphics-service disposal, and `SdlInputBridge::ShutdownGamepadSubsystem()` (`Game.cpp:617-652`). Destruction alone therefore never runs the explicit lifecycle callbacks. **VERIFIED.**

**F10.** `Game::Dispose()` (public) is **not** idempotent w.r.t. its event: it calls `Dispose(true)` (which early-returns when `isDisposed_`) and then **unconditionally** raises `Disposed` (`Game.cpp:453-457`). A second `Dispose()` raises the event again. **VERIFIED.**

**F11.** `isDisposed_ = true` is set **last**, after all cleanup (`Game.cpp:651`). An exception thrown by any component, the content manager, or the graphics service aborts the remaining cleanup and leaves the object *not* marked disposed. **VERIFIED.**

### Run / RunOneFrame / Tick

**F12.** `Game::Run()` (`Game.cpp:337-355`) is exactly: `AssertNotDisposed()` → `if (!hasInitialized_) { DoInitialize(); hasInitialized_ = true; }` → `BeginRun()` → `BeforeLoop()` → `previousPerformanceCounter_ = SDL_GetPerformanceCounter()` → `RunLoop()` → `EndRun()` → `AfterLoop()`. **VERIFIED.**

**F13.** `Run()` does **not** reset `RunApplication`. A second `Run()` after `Exit()` still runs `BeginRun`/`BeforeLoop`, executes **zero** ticks, raises `Exiting`, then `EndRun`/`AfterLoop`. **VERIFIED** (`Game.cpp:337-355`, `:843-857`, `:306-310`).

**F14.** `RunOneFrame()` (`Game.cpp:325-335`) does `DoInitialize()` + set the perf counter + `Tick()` — and **never** calls `BeginRun`, `BeforeLoop`, `EndRun`, `AfterLoop`, or `OnExiting`. Consequence: **`IsActive` stays `false` for the whole of `RunOneFrame()`**, because only `BeforeLoop()` sets it (`Game.cpp:834-837`). **VERIFIED.**

**F15.** `Exit()` sets `RunApplication = false` **and** `suppressDraw_ = true` (`Game.cpp:306-310`) — it does not raise `Exiting`. `OnExiting` is raised inside `RunLoop()` *after* the `while` loop ends (`Game.cpp:855`), i.e. **before** `EndRun()`/`AfterLoop()`. An `Exiting` handler runs before an `EndRun()` override. **VERIFIED.**

**F16.** `ResetElapsedTime()` is a **no-op under fixed timestep** — it only sets `forceElapsedTimeToZero_` when `!IsFixedTimeStep_` (`Game.cpp:312-318`), and `IsFixedTimeStep` defaults to `true`. **VERIFIED.**

**F17.** `SuppressDraw()` sets a flag consumed exactly once, at the end of `Tick()` (`Game.cpp:442-450`): `if (suppressDraw_) suppressDraw_ = false; else if (BeginDraw()) { Draw(); EndDraw(); }`. Suppression consumes the flag whether or not a draw would have happened. **VERIFIED.**

**F18.** `BeginDraw()` returning `false` skips **both** `Draw` and `EndDraw` (`Game.cpp:446-450`). `Game::BeginDraw()` delegates to the manager or returns `true` if none (`:483-491`); `Game::EndDraw()` delegates to the manager, or calls `GraphicsDevice::Present()` directly when there is no manager (`:493-503`). **VERIFIED.**

### Timing

**F19.** Timing source is `SDL_GetPerformanceCounter`/`Frequency`, converted through a **`double` milliseconds** intermediate (`Game.cpp:859-880`) — a documented substitution for FNA's `Stopwatch`. Every `TimeSpan` comparison in `Game.cpp` goes through `getTotalMillisecondsProperty()` doubles (`:43-76`), not integer ticks. **VERIFIED.**

**F20.** Fixed-timestep waiting is two-phase (`Game.cpp:361-376`): first `SDL_Delay(1)` while `accumulated + worstCaseSleepPrecision_ < Target`, feeding each measured sleep into `UpdateEstimatedSleepPrecision`; then a `std::this_thread::yield()` busy-spin while `accumulated < Target`. This is FNA's adaptive-sleep loop with `yield()` standing in for `Thread.SpinWait(1)` (comment at `:370`). **VERIFIED.**

**F21.** `UpdateEstimatedSleepPrecision` (`Game.cpp:882-903`) caps each sample at **4 ms**, keeps a 128-entry ring (`PREVIOUS_SLEEP_TIME_COUNT = 128`, mask `127`, `Game.hpp:360-364`), and rescans the whole ring only when the sample being evicted was the current worst case. **VERIFIED.**

**F22.** `MaxElapsedTime = 500 ms` (`Game.cpp:89`). Accumulated time is clamped to it **after** `PollEvents()` and **before** the update loop (`Game.cpp:380-383`) — so a single frame can never issue more than ~30 catch-up updates at 60 Hz. **VERIFIED.**

**F23.** Order inside `Tick()` (`Game.cpp:357-451`) is: `AdvanceElapsedTime()` → fixed-step sleep/spin → **`PollEvents()`** → clamp to `MaxElapsedTime` → update loop → draw. Input is therefore pumped **after** the frame-pacing wait and **before** `Update`. **VERIFIED.**

**F24.** Fixed-step catch-up (`Game.cpp:385-423`): `ElapsedGameTime` is set to `TargetElapsedTime` *before* the loop, `TotalGameTime` accrues one `Target` per step, and after the loop `ElapsedGameTime` is **rewritten** to `TimeSpan::FromTicks(Target.Ticks * stepCount)` — integer ticks, no float drift (comment at `:419`). So an `Update` handler sees `Elapsed == Target`, but a `Draw` handler sees `Elapsed == Target × stepCount`. **VERIFIED.** This asymmetry is worth a book paragraph.

**F25.** `IsRunningSlowly` is **five-tick hysteresis, not a one-frame flag** (`Game.cpp:400-417`): `updateFrameLag_ += max(0, stepCount - 1)`; set `true` at `updateFrameLag_ >= 5`; cleared only when `updateFrameLag_ == 0`; decremented by 1 on any single-step frame. **VERIFIED.**

**F26.** Variable timestep (`Game.cpp:424-440`): if `forceElapsedTimeToZero_`, `ElapsedGameTime = Zero` **and `TotalGameTime` is not advanced at all**; otherwise `Elapsed = accumulated`, `Total += Elapsed`. Then `accumulated = Zero` and exactly one `Update`. `IsRunningSlowly` is **never written** in this branch — it keeps whatever value the fixed-step branch last left. **VERIFIED.**

**F27.** `GameTime` is a 3-field POD (`TotalGameTime`, `ElapsedGameTime`, `IsRunningSlowly`) with **public getters and private setters**, unlocked by `friend class Game` (`modules/runtime/include/Microsoft/Xna/Framework/GameTime.hpp:16,55-58`). Three constructors, no default-arg forms. **VERIFIED.**

### Components, ordering, add/remove during iteration

**F28.** `Game::Update` and `Game::Draw` **snapshot** the component list into a member vector before iterating (`Game.cpp:549-567`, `:569-589`), then clear it. Add/remove during iteration is therefore safe against iterator invalidation — but the snapshot is a **member**, not a local, so a re-entrant `Update` (a component calling `Game::Update`) would clobber it. **VERIFIED** (code); re-entrancy is untested.

**F29.** `Game::Update` calls `FrameworkDispatcher::Update()` **at the very end, after the component loop** (`Game.cpp:588`). A subclass that overrides `Update` and does not call `Game::Update` **silently disables all dynamic-audio, media and touch dispatch**. **VERIFIED** — a high-value gotcha.

**F30.** Ordering is a **sorted-insert into a `std::vector`**, not a sort (`Game.cpp:724-766`): remove-then-`find_if` the first element with a *strictly greater* order, and insert there. Equal `UpdateOrder`/`DrawOrder` values therefore preserve **insertion order** (stable). Lower order runs/draws first. **VERIFIED.**

**F31.** Re-sorting on order change is event-driven: `CategorizeComponent` registers a token per component on `UpdateOrderChanged`/`DrawOrderChanged` (`Game.cpp:700-722`), stored in `std::unordered_map<…, Token>` (`Game.hpp:368-369`), and removed on component removal (`Game.cpp:972-1003`). **VERIFIED.**

**F32.** `Components_.ComponentAdded/Removed` are subscribed **only inside `DoInitialize()`** (`Game.cpp:690-697`). Components added before `Run()`/`RunOneFrame()` are handled by the explicit loop at `Game.cpp:685-688` instead. A component added before initialization and then removed before initialization is fine; but **components added before `DoInitialize` never see `OnComponentAdded`**. **VERIFIED.**

**F33.** `GameComponentCollection` is `final : System::Object` wrapping `std::vector<IGameComponent*>` (`GameComponentCollection.hpp:19,134`). It is a **non-owning** raw-pointer collection. `SetItem` throws `std::logic_error("SetItem is not supported.")` (`GameComponentCollection.cpp:150-156`), the C++ stand-in for FNA's `NotSupportedException` — and it is unreachable from public API. **VERIFIED.**

**F34.** `InsertItem` throws `std::invalid_argument("Cannot Add Same Component Multiple Times")` on duplicate pointer identity (`GameComponentCollection.cpp:114-119`); `operator[]`, `RemoveAt`, `Insert` throw `std::out_of_range` (`:69,123,138`). `Clear()` raises `ComponentRemoved` for **every** element before clearing (`:101-112`). **VERIFIED.**

**F35.** `GameComponentCollection` exposes real C++ `begin()`/`end()` iterators, all marked `CNAEXT` (`GameComponentCollection.hpp:107-125`) — a deliberate extension replacing `IEnumerable<T>`. **VERIFIED.**

**F36.** `GameComponent::CompareTo` returns `other.UpdateOrder - this->UpdateOrder` — **inverted** relative to conventional `CompareTo` (`GameComponent.cpp:73-76`). This is FNA's own quirk, preserved. **VERIFIED.**

**F37.** `GameComponent` property setters raise the public event *and then* call the protected `OnXChanged` virtual — in that order (`GameComponent.cpp:32-41`, `:48-57`; same in `DrawableGameComponent.cpp:31-54`). FNA passes `null` args; CNA passes `EventArgs::Empty` because references cannot be null (comments at `:38`, `:54`). **VERIFIED.**

**F38.** `DrawableGameComponent::Initialize()` calls `LoadContent()` **immediately and unconditionally** on first call, with no `IGraphicsDeviceService` hookup — the source admits this is a placeholder (`DrawableGameComponent.cpp:56-66`). `Dispose(bool)` calls `UnloadContent()` when initialized (`:68-77`). `OnDeviceCreated` exists and calls `LoadContent()` but has **no subscriber anywhere**. **VERIFIED.**

**F39.** `DrawableGameComponent` has **no destructor of its own**, so `~GameComponent()`'s `Dispose(false)` (`GameComponent.cpp:17-20`) resolves to `GameComponent::Dispose(bool)`, **not** the drawable override. Destruction alone never dispatches `UnloadContent()`. **VERIFIED** (C++ virtual-dispatch-during-destruction rule + code).

**F40.** `IUpdateable` and `IDrawable` are pure-virtual interfaces exposing `getEnabledProperty`/`getUpdateOrderProperty` and `getVisibleProperty`/`getDrawOrderProperty` plus *event accessors returning `EventHandler&`* (`IUpdateable.hpp:13-48`, `IDrawable.hpp:13-48`) — the C++ translation of C# events on an interface. **VERIFIED.**

**F41.** There are **zero tests** for `GameComponent` and `DrawableGameComponent`. Both test files are 2-line comments: "No tests: … requires a live Game reference (SDL/graphics renderer)." (`modules/runtime/tests/Microsoft/Xna/Framework/GameComponentTests.cpp:1-2`, `DrawableGameComponentTests.cpp:1-2`). **VERIFIED.**

### Service model

**F42.** `GameServiceContainer` is `std::unordered_map<std::type_index, void*>` (`GameServiceContainer.hpp:92`), keyed on `typeid(TService)` from the **explicit template argument**, with the pointer adjusted by the implicit derived→base conversion at the call site before `static_cast<void*>` (`:39-48`, `:62-66`). This makes multiple-inheritance service lookup correct — but only because callers always name the interface explicitly. **VERIFIED.**

**F43.** It is a **non-owning, duplicate-rejecting** registry: `AddService` throws `std::invalid_argument("provider")` on null and `std::invalid_argument("A service with this type is already registered.")` on a repeat key (`GameServiceContainer.cpp:12-29`). FNA's `type.IsAssignableFrom` check is omitted with an in-source note (`:26-27`) — C++ has no runtime reflection over `void*`. `RemoveService` is a silent no-op if absent (`:42-45`). Copy is deleted; move is defaulted (`GameServiceContainer.hpp:26-32`). **VERIFIED.**

**F44.** Non-primary-base pointer adjustment is explicitly tested — `GetServiceForNonPrimaryBaseReturnsCorrectlyAdjustedPointer`, `VirtualCallThroughRetrievedNonPrimaryBaseServiceDispatchesCorrectly`, `TwoInterfacesOnSameObjectRetrieveIndependentlyAdjustedPointers`, `ContainerDoesNotOwnRegisteredServiceLifetime` (`GameServiceContainerTests.cpp:106,125,139,175`). 13 cases total. **VERIFIED.**

### GraphicsDeviceManager

**F45.** `GraphicsDeviceManager` inherits **four** bases: `System::Object`, `Graphics::IGraphicsDeviceService`, `System::IDisposable`, `IGraphicsDeviceManager` (`GraphicsDeviceManager.hpp:49-52`). **VERIFIED.**

**F46.** `IGraphicsDeviceManager` is only three methods: `BeginDraw()`, `CreateDevice()`, `EndDraw()` (`IGraphicsDeviceManager.hpp:8-25`). **VERIFIED.**

**F47.** The `Game*` constructor **deliberately does NOT call `ApplyChanges()`** — 11 lines of in-source rationale (`GraphicsDeviceManager.cpp:72-85`): `Game::DoInitialize()`'s `CreateDevice()` is the single source of truth, and calling it here caused a visible double-reconfiguration flicker. It throws `std::invalid_argument("The game cannot be null.")` on null (`:63-66`) and calls `registerServices()` (`:71`). **VERIFIED.**

**F48.** `registerServices()` (`GraphicsDeviceManager.cpp:559-576`) registers under **both** `IGraphicsDeviceManager` and `IGraphicsDeviceService`, throws `std::invalid_argument` if a manager is already registered on that `Game`, and subscribes `GameWindow::ClientSizeChanged` → `INTERNAL_OnClientSizeChanged`. **VERIFIED.**

**F49.** `INTERNAL_OnClientSizeChanged` **deliberately does not call `ApplyChanges()`** — it only calls `graphicsDevice_->UpdateViewportFromWindow()`, because forwarding the physical window size as the virtual resolution would corrupt the game's logical coordinate space (`GraphicsDeviceManager.cpp:481-494`). **VERIFIED.**

**F50.** Defaults (`GraphicsDeviceManager.cpp:47-56`): `GraphicsProfile::Reach`, `IsFullScreen=false`, `PreferMultiSampling=false`, `SurfaceFormat::Color`, 800×480, `DepthFormat::Depth24`, `SynchronizeWithVerticalRetrace=true`, `DisplayOrientation::Default`, and — CNA-only — `PresentationMode::FixedHeightDynamicWidth`. `DefaultBackBufferWidth/Height = 800/480` are `static constexpr` (`GraphicsDeviceManager.hpp:56-58`). **VERIFIED.**

**F51. PresentationMode is confirmed a GraphicsDeviceManager-only extension.** The `CNAEXT enum class PresentationMode` is declared **inside `GraphicsDeviceManager.hpp:34-46`** (5 values: `Letterbox=0`, `Overscan=1`, `Stretch=2`, `NativeBackBuffer=3`, `FixedHeightDynamicWidth=4`). `PresentationParameters` has **no** such field — its full member set is BackBufferFormat/Width/Height, Bounds, DeviceWindowHandle, DepthStencilFormat, IsFullScreen, MultiSampleCount, PresentationInterval, DisplayOrientation, RenderTargetUsage, Clone (`modules/graphics/include/Microsoft/Xna/Framework/Graphics/PresentationParameters.hpp:26-203`). The mode reaches the renderer out-of-band via `graphicsDevice_->SetPresentationMode(static_cast<int>(preferredPresentationMode_))` at `GraphicsDeviceManager.cpp:620`. **VERIFIED — the premise in the task brief is correct.**

**F52.** Every preference setter funnels through `markPreferencesChanged()` (`GraphicsDeviceManager.cpp:554-557`), and `ApplyChanges()` early-returns when neither `prefsChanged_` nor `useResizedBackBuffer_` is set (`:215-218`). **VERIFIED.**

**F53.** `ApplyChanges()` order (`GraphicsDeviceManager.cpp:207-249`): no device → `CreateDevice()` and return; else clone current PP into a `GraphicsDeviceInformation` → `INTERNAL_CreateGraphicsDeviceInformation(gdi)` → (if attached) `SetSupportedOrientations` / `BeginScreenDeviceChange` / `EndScreenDeviceChange` → `applyToExistingRenderer(gdi)` → `prefsChanged_ = false`. **VERIFIED.**

**F54.** `PreparingDeviceSettings` fires from **inside** `INTERNAL_CreateGraphicsDeviceInformation`, as its **last** statement (`GraphicsDeviceManager.cpp:550-551`) — so a handler sees the fully-populated `gdi` and its mutations survive into the device. It is raised on both the `CreateDevice()` and `ApplyChanges()` paths. **VERIFIED.**

**F55.** Preference→PP mapping (`GraphicsDeviceManager.cpp:496-552`): vsync maps to `PresentInterval::One` vs `Immediate` (`:534-536`); `PreferMultiSampling == false` forces `MultiSampleCount = 0`, `true` sets **8** unconditionally when currently 0 — FNA queries `FNA3D_GetMaxMultiSampleCount` and caps at 8; CNA hardcodes 8 (comment at `:544`). Orientation swap (portrait ⇒ min×max) applies **only** on iOS/Android, gated by `platformSupportsOrientations()` (`:23-32`); desktop keeps the requested width×height verbatim. **VERIFIED.**

**F56.** `applyToExistingRenderer` (`GraphicsDeviceManager.cpp:599-633`) is the real reset path, in this exact order: `SetGraphicsProfileEXT(gdi.GraphicsProfile)` → `SetPresentationMode(...)` → `GraphicsDevice::Reset(pp, adapter)` → `UpdateViewportFromWindow()`. The presentation mode **must** precede `Reset()` because SDL_Renderer's logical-presentation size depends on the active mode (comment at `:616-619`). **VERIFIED.**

**F57. Device-reset event routing was reworked (REMED-CORE-007).** `ApplyChanges()` **no longer raises `DeviceResetting`/`DeviceReset` itself** (`GraphicsDeviceManager.cpp:241-248`). Instead `CreateDevice()` subscribes this manager to `GraphicsDevice`'s own `DeviceResetting`/`DeviceReset`, once, behind a `deviceEventsSubscribed_` guard, **after** the settle-in `Reset()` so first creation raises only `DeviceCreated` (`:315-336`). A renderer-detected device-lost now reaches manager listeners. **VERIFIED**, and pinned by tests `ApplyChangesRaisesResettingAndResetExactlyOnce`, `RendererDetectedDeviceLostIsForwardedToManagerListeners` (`GraphicsDeviceManagerTests.cpp:71,102`).

**F58.** `OnDeviceDisposing`/`OnDeviceReset`/`OnDeviceResetting` **discard the passed `sender` and re-raise with `this`**, while `OnDeviceCreated` forwards the sender — an asymmetry in real FNA, deliberately preserved and now observable (`GraphicsDeviceManager.cpp:426-448`, with the rationale at `:428-433`). Pinned by `ForwardedDeviceEventsReportTheManagerAsSender` (`GraphicsDeviceManagerTests.cpp:135`). **VERIFIED.**

**F59. `DeviceDisposing` was resurrected (REMED-CORE-014).** The raise in `Dispose(bool)` is deliberately **not** gated on `ownsGraphicsDevice_` — which is always `false` for a `Game`-attached manager, so gating it left `DeviceDisposing` permanently dead for the only configuration this codebase constructs (`GraphicsDeviceManager.cpp:373-395`, rationale at `:375-383`). Only the `delete` stays gated, since `graphicsDevice_` may point at a `Game` value member. **VERIFIED.**

**F60.** `CanResetDevice`, `FindBestDevice`, `RankDevices` all **diverge from FNA, which throws `NotImplementedException`**: CNA returns `graphicsDevice_ != nullptr`, a sensible default GDI, and a no-op respectively (`GraphicsDeviceManager.cpp:456-479`). **VERIFIED.**

**F61.** `CreateDevice()` throws `std::runtime_error` when there is no `Game`-owned device: *"GraphicsDeviceManager cannot create a GraphicsDevice without a Game-owned device in this CNA renderer."* (`GraphicsDeviceManager.cpp:280-284`). The default (no-`Game`) constructor is `CNAEXT`-marked and exists for headless tests. **VERIFIED.**

**F62.** `BeginDraw()` returns `false` **only** when there is no device (`GraphicsDeviceManager.cpp:338-347`); `EndDraw()` presents only when `drawBegun_` (`:349-356`). **VERIFIED.**

### GameWindow

**F63.** `GameWindow` is **one concrete SDL3-backed class**, where FNA has an abstract base with per-platform subclasses — stated in its own doc comment (`GameWindow.hpp:23-28`). It is `friend class Game` + `friend class GraphicsDeviceManager` (`:31-32`). **VERIFIED.**

**F64.** Properties read **live from SDL when a window exists, and fall back to a cached value otherwise**: `AllowUserResizing` reads `SDL_WINDOW_RESIZABLE` (`GameWindow.cpp:49-57`), `ClientBounds` calls `SDL_GetWindowSize` (`:72-80`, `:356-384`), `IsBorderlessEXT` reads `SDL_WINDOW_BORDERLESS` (`:116-124`). `Title`, `ScreenDeviceName`, `CurrentOrientation` are pure cache. **VERIFIED.**

**F65.** Setters **throw `std::runtime_error`** (via `makeSdlError`, `GameWindow.cpp:14-17`) when the SDL call fails: `SDL_SetWindowResizable` (`:67`), `SDL_SetWindowBordered` (`:134`), `SDL_MinimizeWindow` (`:145`), `SDL_RestoreWindow` (`:156`), `SDL_SetWindowSize` (`:179`), `SDL_SetWindowFullscreen` (`:188`), `SDL_SetWindowTitle` (`:282`). **A property setter that throws is a real hazard for porting engineers.** **VERIFIED.**

**F66.** **One SDL failure is deliberately non-fatal**: `queryClientBoundsFromSDL` returns the last-known bounds instead of throwing when `SDL_GetWindowSize` fails, with a 12-line rationale about a reproducible Emscripten startup race where SDL3 reports "not initialized" for the first one or two ticks after `SDL_CreateWindow` succeeded (`GameWindow.cpp:366-381`). **VERIFIED.**

**F67.** `getHandleProperty()` is a raw `reinterpret_cast<IntPtr>(window_)` (`GameWindow.cpp:87-90`); `GetNativeSdlWindowEXT()` is a `CNAEXT` borrowed, nullable view documented as "never for use in the strict XNA-facing API surface" (`GameWindow.hpp:92-102`). `MinimizeEXT`/`RestoreEXT`/`IsBorderlessEXT` are further CNA extensions (`:126-148`). **VERIFIED.**

**F68.** Orientation is **derived from bounds, not from a sensor**: `orientationFromBounds` returns `Portrait` iff `Height > Width`, else `LandscapeLeft`, else `Default` for non-positive extents (`GameWindow.cpp:403-416`). `LandscapeRight` is therefore **never produced** by the SDL refresh path — only by `SetSupportedOrientations`'s fallback chain (`:248-271`). **VERIFIED.**

**F69.** `Begin/EndScreenDeviceChange` are a two-phase commit: `Begin` records `pendingFullScreen_` (`GameWindow.cpp:161-165`); `End` sets size, then fullscreen, then refreshes cached state with `raiseEvents=false` and raises `ClientSizeChanged`/`ScreenDeviceNameChanged` **manually and only on actual change** (`:167-207`). The `SDL_SetWindowSize` call is `#ifndef __ANDROID__`-guarded (`:176-181`). **VERIFIED.**

**F70.** Events raised: `ClientSizeChanged`, `OrientationChanged`, `ScreenDeviceNameChanged` (`GameWindow.hpp:41-47`). `OnActivated`, `OnDeactivated`, `OnPaint` are declared and **defined as empty bodies with no callers** (`GameWindow.cpp:221-241`) — dead XNA API shape. **VERIFIED.**

### FrameworkDispatcher, LaunchParameters, TitleContainer, ExitingEventArgs

**F71.** `FrameworkDispatcher::Update()` (`modules/audio/src/Xna/FrameworkDispatcher.cpp:14-71`) **snapshots `Streams` under the mutex, then runs each `Update()` with the lock released** — because `BufferNeeded` handlers legitimately dispose the instance, which re-locks `StreamsMutex`, and `std::mutex` is not recursive (10-line rationale at `:16-25`). Then it prunes disposed streams, calls `Microphone::CheckAllBuffers()`, `MediaPlayer::Update()`, drains the `ActiveSongChanged`/`MediaStateChanged` flags, and updates `TouchPanel` if a touch device exists. **VERIFIED.**

**F72.** `LaunchParameters` **publicly inherits `std::unordered_map<std::string, std::string>`** (`LaunchParameters.hpp:14`) — a std container with no virtual destructor. **VERIFIED**, and worth flagging in the book.

**F73.** Argument acquisition is platform-specific with a **silent empty fallback**: Win32 `CommandLineToArgvW` + UTF-8 conversion; Linux/Android reads `/proc/self/cmdline`; **every other platform (macOS, iOS, Emscripten) returns `{}`** with an in-source note (`LaunchParameters.cpp:41-102`, esp. `:96-101`). **VERIFIED.**

**F74.** Parsing (`LaunchParameters.cpp:104-141`): strip leading `/` and `-`; require length ≥ 3; find `:` at index ≥ 1 and ≤ `size-2`; first occurrence wins (`ContainsKey` guard). `Add` uses `emplace`, which silently ignores duplicates where FNA's `Dictionary.Add` throws — documented as safe because `Parse` always guards (`:36-38`). **VERIFIED.**

**F75.** `TitleContainer::OpenStream` throws `std::runtime_error` on failure and logs two `CNA::Logger::Info` lines per call (`TitleContainer.cpp:23-61`). `ReadToPointer` returns a `malloc`'d buffer freed by `FreePointer` (`:63-133`) and can throw `std::bad_alloc`. Android additionally tries `SDL_LoadFile` for assets not visible as files. **VERIFIED.**

**F76.** `TitleLocation` is lazily initialized from `SDL_GetBasePath()`, falling back to `std::filesystem::current_path()` (`TitleLocation.cpp:31-53`). `setPathProperty` is `CNAEXT`. The statics `path_`/`initialized_` are **not thread-safe** (`:11-12`, `:31-38`). **VERIFIED.**

**F77. `ExitingEventArgs` is dead code.** It is an empty `: System::EventArgs` with a defaulted constructor (`ExitingEventArgs.hpp:10-15`), its `.cpp` is a single include line, and a repo-wide grep finds it referenced **only** by its own header, its own `.cpp`, and its own 2-case test file. `Game::Exiting` is typed `EventHandler<System::EventArgs>` (`Game.hpp:50`). **VERIFIED.**

### Emscripten divergence

**F78.** Under `__EMSCRIPTEN__`, `RunLoop()` becomes `s_emLoopState.game = this; s_emLoopState.gameTime = gameTime_; emscripten_set_main_loop(EmscriptenMainLoopCallback, 0, 1);` (`Game.cpp:843-857`). Because `simulateInfiniteLoop=1`, the call **never returns** — so **`EndRun()` and `AfterLoop()` are never called in a browser build.** **VERIFIED.**

**F79.** `s_emLoopState` is a **static** (`Game.hpp:396-398`, `Game.cpp:777`) — **only one `Game` can run per process under Emscripten.** **VERIFIED.**

**F80.** The Emscripten callback (`Game.cpp:779-831`) is a **completely separate loop** that never calls `Tick()`. Concretely it diverges as follows — **all VERIFIED**:

| Aspect | Desktop `Tick()` | Emscripten callback |
|---|---|---|
| Timing source | `SDL_GetPerformanceCounter` (ns-class) | `SDL_GetTicks()` (**milliseconds**), `:789` |
| `IsFixedTimeStep` | honoured | **ignored** — always fixed-step, `:808` |
| Frame-pacing sleep/spin | `SDL_Delay`+`yield` loop | **none** (browser drives rAF) |
| Adaptive sleep-precision ring | live | **dead code** |
| Lag clamp | `MaxElapsedTime` = **500 ms** | hard-coded **250 ms**, `:798-801` |
| `IsRunningSlowly` | 5-tick hysteresis | **hard-set `false` every step**, `:814` |
| `suppressDraw_` / `SuppressDraw()` | consumed at `:442` | **never consulted** — no-op |
| `ResetElapsedTime()` | variable-step only | **no effect at all** |
| Draw cadence | every tick | **only if ≥1 Update ran** (`updated` flag), `:820` |
| `GameTime` object | member `gameTime_` | the **static's own copy**, `:812-816` |
| `Exiting` | after `while` in `RunLoop` | `emscripten_cancel_main_loop()` then `OnExiting`, `:826-830` |

**F81.** `Game::Run()`'s Doxygen comment carries a 21-line object-lifetime warning (`Game.hpp:196-219`), backed by `docs/emscripten-mainloop-game-lifetime.md` and `emscripten-mainloop-stack-spike/`. Root cause: `simulateInfiniteLoop=1` is implemented as a raw JS `throw 'unwind'`, and CNA compiles with `-fwasm-exceptions`, whose `catch_all` landing pads catch **foreign** exceptions — so destructors of stack locals between the call site and the JS catch really do run. A stack-allocated `Game` subclass has its `unique_ptr<GraphicsDeviceManager>` destroyed while `Game::graphicsDeviceManager_` keeps a raw pointer to the freed block; the crash surfaces much later as a WASM indirect-call fault inside `BeginDraw()`. The doc explicitly rules out the `GameServiceContainer`/multiple-inheritance hypothesis with sanitizer-verified reproductions. **VERIFIED** (`docs/emscripten-mainloop-game-lifetime.md:17-60`).

### Exception model — framework core

**F82. CONFIRMED with a correction.** `modules/runtime` throws **exclusively `std::` types — never a single `System::*` type.** Complete inventory (30 sites, all VERIFIED):

| Type | Sites |
|---|---|
| `std::out_of_range` | `Game.cpp:196` (InactiveSleepTime < 0), `:280` (TargetElapsedTime ≤ 0); `GameComponentCollection.cpp:69,123,138` |
| `std::runtime_error` | `Game.cpp:31` (MIX_Init), `:658` (**use-after-dispose** — XNA's `ObjectDisposedException`); `GraphicsDeviceManager.cpp:282`; `TitleContainer.cpp:60,76,90,127`; `GameWindow.cpp:67,134,145,156,179,188,282` (all 7 via `makeSdlError`) |
| `std::invalid_argument` | `GameServiceContainer.cpp:16,23` (+ the header template at `GameServiceContainer.hpp:44`); `GameComponentCollection.cpp:118`; `GraphicsDeviceManager.cpp:65,563` |
| `std::logic_error` | `GameComponentCollection.cpp:155` |
| `std::bad_alloc` | `TitleContainer.cpp:84,113` |

**F83. The crucial hierarchy fact the parallel pass missed: `System::Exception` derives from `std::exception`, NOT from `std::runtime_error`** (`/rv/data/development/github.com/openeggbert/sharp-runtime/modules/core/include/System/Exception.hpp:32`: `class Exception : public std::exception`). Therefore `catch (const std::runtime_error&)` does **not** catch `System::*` exceptions, and `catch (const System::Exception&)` does not catch the `std::` ones. Only `catch (const std::exception&)` catches both. **VERIFIED.**

**F84.** The parallel pass's summary is confirmed for the wider tree: Graphics (`DeviceLostException`, `DeviceNotResetException`, `NoSuitableGraphicsDeviceException`) and Content (`ContentLoadException`) derive from `std::runtime_error`; Audio (`NoMicrophoneConnectedException`), GamerServices (`NetworkException`, `GamerPrivilegeException`, …), Net, and Sensors (`SensorFailedException`) derive from `System::Exception`; `CNA::CNAException : System::Exception` (`modules/core/include/CNA/CNAException.hpp:15`). **VERIFIED** (grep of `class .*Exception` across `modules/`). **But `modules/runtime` participates in neither family — it throws only raw `std::` standard types.**

---

## LIFECYCLE ORDER (exact, cited)

### Phase A — construction, before `Run()`
1. `Game::Game()` — members constructed in declaration order: `Components_`, `GraphicsDevice_` (**a real device is created here**), `Content_`, `Window_`, `LaunchParameters_` (parses the command line), `Services_` — `Game.cpp:97-128`.
2. `Window_.setWindowInternal(GraphicsDevice_.GetRenderer().GetWindowInternal())` — `Game.cpp:134`.
3. `Content_.setGraphicsDevice(GraphicsDevice_)` — `Game.cpp:135`.
4. `FrameworkDispatcher::Update()` — `Game.cpp:137`.
5. `InitAudio()` (`MIX_Init`, only under `SOUND_ENABLED`) — `Game.cpp:138`, `:26-34`.
6. *(user code)* `GraphicsDeviceManager gdm(&game)` → `registerServices()` registers both services and subscribes `ClientSizeChanged`; **no `ApplyChanges()`** — `GraphicsDeviceManager.cpp:60-85`, `:559-576`.

### Phase B — `Run()` up to the first `Draw`
7. `AssertNotDisposed()` — `Game.cpp:339`, `:654-660`.
8. `DoInitialize()` begins — `Game.cpp:341-345`, `:662`.
9. &nbsp;&nbsp;`graphicsDeviceManager_ = Services_.GetService<IGraphicsDeviceManager>()` — `Game.cpp:666`.
10. &nbsp;&nbsp;`graphicsDeviceManager_->CreateDevice()` — `Game.cpp:669`. Inside it: build `GraphicsDeviceInformation` from the default adapter + the window handle (`GDM.cpp:286-293`) → `INTERNAL_CreateGraphicsDeviceInformation` → **`PreparingDeviceSettings` fires** (`GDM.cpp:550-551`) → `SetSupportedOrientations` (mobile only) → `BeginScreenDeviceChange` → `EndScreenDeviceChange` (real `SDL_SetWindowSize`/`SDL_SetWindowFullscreen`; may raise `ClientSizeChanged`/`ScreenDeviceNameChanged`) → `applyToExistingRenderer` (`SetGraphicsProfileEXT` → `SetPresentationMode` → `GraphicsDevice::Reset` → `UpdateViewportFromWindow`) → subscribe to the device's own reset events → **`DeviceCreated` fires** (`GDM.cpp:334`).
11. &nbsp;&nbsp;`SdlInputBridge::EnsureGamepadSubsystemInitialized()` — `Game.cpp:678`. Deliberately here so pre-connected gamepads are enumerated before frame one.
12. &nbsp;&nbsp;`Initialize()` (the virtual) — `Game.cpp:680`. The base implementation (`Game.cpp:513-547`) does, in order:
    - a. `component->Initialize()` for every current component, by index — `:515-522`;
    - b. resolve `graphicsDeviceService_` — `:524`;
    - c. subscribe `DeviceDisposing → UnloadContent()` — `:532-533` **(REMED-CORE-006)**;
    - d. if no service **or** the service already has a device → **`LoadContent()` now** — `:536-539`; else subscribe `DeviceCreated → LoadContent()` and defer — `:544-545`.
13. &nbsp;&nbsp;clear the updateable/drawable lists, then `CategorizeComponent()` each component (sorted insert + order-changed subscription) — `Game.cpp:682-688`, `:700-766`.
14. &nbsp;&nbsp;subscribe `Components_.ComponentAdded` / `ComponentRemoved` — `Game.cpp:690-697`.
15. `hasInitialized_ = true` — `Game.cpp:344`.
16. `BeginRun()` — `Game.cpp:347` (base is empty, `:475-477`).
17. `BeforeLoop()` → `setIsActiveProperty(true)` → **`Activated` fires** — `Game.cpp:348`, `:834-837`, `:207-224`.
18. `previousPerformanceCounter_ = SDL_GetPerformanceCounter()` — `Game.cpp:350`.
19. `RunLoop()` → `while (RunApplication) Tick();` — `Game.cpp:351`, `:850-853`.

### Phase C — one desktop frame (`Tick()`, `Game.cpp:357-451`)
20. `AdvanceElapsedTime()` — `:359`.
21. **if fixed-step:** `SDL_Delay(1)` loop while `accumulated + worstCaseSleepPrecision_ < Target`, each iteration re-measuring and feeding `UpdateEstimatedSleepPrecision` — `:363-368`; then `std::this_thread::yield()` spin while `accumulated < Target` — `:371-375`.
22. `PollEvents()` — `:378`, `:905-958`. Per SDL event: `SdlInputBridge::ProcessEvent`; `SDL_EVENT_QUIT` → `Exit()`; **F9 → `DebugSimulateContextLoss()`, F10 → `DebugRestoreContext()`** (`:921-924`); `WINDOW_RESIZED`/`PIXEL_SIZE_CHANGED` → `Window_.updateFromSDL()`; `WILL_ENTER_BACKGROUND`/`FOCUS_LOST` → `IsActive=false` (**`Deactivated`**); `DID_ENTER_FOREGROUND`/`FOCUS_GAINED` → `IsActive=true` (**`Activated`**).
23. Clamp `accumulatedElapsedTime_` to `MaxElapsedTime` (500 ms) — `:380-383`.
24. **Fixed-step:** set `Elapsed = Target`; loop while `accumulated >= Target` { `Total += Target`; `accumulated -= Target`; `++stepCount`; `AssertNotDisposed()`; **`Update(gameTime_)`** } — `:387-398`. Then lag bookkeeping (`updateFrameLag_`, the `>= 5` / `== 0` hysteresis) — `:400-417`. Then rewrite `Elapsed = FromTicks(Target.Ticks * stepCount)` — `:420-422`.
    **Variable-step:** honour `forceElapsedTimeToZero_` or set `Elapsed = accumulated` and `Total += Elapsed`; zero the accumulator; `AssertNotDisposed()`; **one `Update(gameTime_)`** — `:426-439`.
25. Inside each `Game::Update`: snapshot updateables → call `Update` on every `Enabled` one in ascending `UpdateOrder` → clear the snapshot → **`FrameworkDispatcher::Update()`** — `:569-589`.
26. `if (suppressDraw_) suppressDraw_ = false;` **else if** `BeginDraw()` → **`Draw(gameTime_)`** → `EndDraw()` — `:442-450`. `Game::Draw` snapshots drawables and calls `Draw` on every `Visible` one in ascending `DrawOrder` — `:549-567`. `EndDraw` → manager's `EndDraw` → `GraphicsDevice::Present()`.

### Phase D — shutdown
27. `Exit()` (or `SDL_EVENT_QUIT`) sets `RunApplication = false` **and** `suppressDraw_ = true` — `:306-310`. The current frame skips its draw; the loop exits at the next condition check.
28. `OnExiting(this, EventArgs::Empty)` → **`Exiting` fires** — `:855`, `:591-595`.
29. `EndRun()` — `:353`.
30. `AfterLoop()` — `:354` (empty, `:839-841`).
31. *(only if the caller asks)* `Dispose()` → `Dispose(true)`: `Dispose()` every `IDisposable` component → `Content_.Dispose()` → dispose `graphicsDeviceService_` (→ `GraphicsDeviceManager::Dispose(true)` → **`DeviceDisposing` fires** → `Game::UnloadContent()` runs via the step-12c subscription) → `SdlInputBridge::ShutdownGamepadSubsystem()` → `isDisposed_ = true` → **`Disposed` fires** — `:453-457`, `:617-652`, `GDM.cpp:364-399`.

**Emscripten deltas:** steps 20–26 are replaced wholesale by `EmscriptenMainLoopCallback` (F80); steps 29–30 **never execute**; step 28 happens inside the callback after `emscripten_cancel_main_loop()` (`Game.cpp:826-830`).

---

## PART 2 — FACTS: MATH AND CORE TYPES

### Layout, dialect, precision

**F85.** `Vector2/3/4`, `Matrix`, `Quaternion`, `Plane`, `Ray`, `Point`, `Rectangle`, `Curve`, `CurveKeyCollection`, `MathHelper` have **no base classes**. `Color`, `BoundingBox`, `BoundingSphere`, `BoundingFrustum`, `CurveKey` **do**. **VERIFIED** (grep of struct/class declarations across `modules/math/include`).

**F86. `sizeof(Color) == 24`, not 4.** `Color : Graphics::PackedVector::IPackedVectorT<UInt32>` (`Color.hpp:22`), and `IPackedVector` has a pure virtual `PackFromVector4` plus a virtual destructor (`IPackedVector.hpp:30-40`) — so `Color` carries a vptr ahead of its single `uintcs packedValue` (`Color.hpp:554`). The codebase names the exact number in three places: `modules/graphics/src/Xna/Texture3D.cpp:105` and `TextureCube.cpp:104` ("Color has a vtable pointer (sizeof(Color) == 24), so we must never pass…"), and `modules/graphics/tests/…/VertexPositionColorTests.cpp:52-54` ("XNA specifies stride=16 (Vector3=12 + Color=4), but sizeof(Color) is currently 24"). A regression test pins it: `ColorTest.SizeIsLargerThanFourBytesVtablePresent` with the comment "Casting `Color*` to `uint8_t*` for GL pixel I/O writes into the vtable, not the pixel data" (`ColorTests.cpp:507-513`), plus `ConstructedFromRawRgbaBytesYieldsCorrectComponents` guarding the fixed `GetBackBufferData` mis-cast bug (`:517-528`). **VERIFIED — this is the single most consequential deviation in the math module.**

**F87.** By the same mechanism, `System::IEquatable<T>` has a pure virtual `Equals` and a virtual destructor, so **`BoundingBox`, `BoundingSphere`, `BoundingFrustum` and `CurveKey` also carry vptrs**. **VERIFIED** (`sharp-runtime/modules/core/include/System/IEquatable.hpp:18-30`).

**F88. Dialect verification — exact commands and results:**

| Query (over `modules/math`) | Result |
|---|---|
| `grep -rn 'constinit' modules/math` | **4** — all at `src/Vector2.cpp:88-91` |
| `grep -rn 'std::bit_cast' modules/math` | **0** |
| `grep -rn 'std::bit_cast' modules/` (repo-wide) | **19**, in Skia ×3, WebGPU, SDL-GPU, DirectX9, `graphics/src/Xna/Texture2D.cpp` — **none in math** |
| `grep -rowc 'concept' / '\brequires\b'` | **0 / 0** |
| `grep -rn '__m128\|xmmintrin\|immintrin\|arm_neon\|std::simd'` | **0** |
| `grep -ro 'constexpr' modules/math \| wc -l` | **25** (13 non-test) |

**So the parallel pass's claim is 2/3 right: `constinit` at `Vector2.cpp:88-91` ✓, no concepts ✓, but "std::bit_cast 19x" is a repo-wide count that does not apply to `modules/math` at all.** The math module type-puns via `std::memcpy` in a thrice-duplicated anonymous-namespace `FloatHash` (`Vector2.cpp:18-24`, `Vector3.cpp:18-24`, `Vector4.cpp:18-24`). **VERIFIED.**

**F89.** The `constinit` asymmetry has a mechanical cause: `Vector2(float,float)` is the **only `constexpr` constructor** among the three vectors (`Vector2.hpp:43` vs `Vector3.hpp:61`, `Vector4.hpp:52`). `Vector3`'s eleven statics (`Vector3.cpp:88-98`) and `Vector4`'s six (`Vector4.cpp:88-93`) are plain `const` and therefore dynamically initialized — a static-initialization-order hazard `Vector2` does not have. **VERIFIED** (constructor facts); **STRONG** (causal inference).

**F90.** `MathHelper::MachineEpsilonFloat` is a **dynamically-initialized `static const float`**, not `constexpr` (`MathHelper.hpp:44`, `MathHelper.cpp:9` → `GetMachineEpsilonFloat()` at `:197-213`, a halving loop). Its value is **2⁻²⁴ ≈ 5.96e-8** (= `FLT_EPSILON/2`). It is read by `WithinEpsilon`, `Ray::Intersects`, `Curve::ComputeTangent` and `CurveKeyCollection::setItemProperty`, so any *static-time* consumer would see 0. **VERIFIED** (code); **STRONG** (the 2⁻²⁴ value, which depends on rounding mode).

**F91.** All arithmetic is `float`, except three deliberate `double` widenings: `MathHelper::CatmullRom` (`MathHelper.cpp:33-43`), `MathHelper::Hermite` (`:70-98`, so large `amount` yields Infinity rather than NaN), and `BoundingBox::Contains(BoundingSphere)`'s `dmin` accumulation (`BoundingBox.cpp:131-217`). `Matrix::Invert` explicitly **declines** FNA's double widening (`Matrix.cpp:980-981`). `MathHelper::ToDegrees/ToRadians` compute the product in `double` from `double` literals then narrow (`MathHelper.cpp:125,130`). **VERIFIED.**

### Conventions (the semantics that matter most)

**F92. Handedness: right-handed, `Forward = -Z`.** `Vector3::Forward = (0,0,-1)`, `Backward = (0,0,1)`, `Up = (0,1,0)`, `Right = (1,0,0)` (`Vector3.cpp:93-98`), pinned by `Vector3Tests.cpp:45` `DirectionConstantsMatchXnaConvention`. `Matrix.hpp:16` states "Represents a right-handed 4x4 matrix". `Matrix::CreateLookAt` builds `vectorA = normalize(eye - target)`, i.e. view-space forward is −Z (`Matrix.cpp:532-555`). There are **no `LH`/`RH` variants**. **VERIFIED.**

**F93. Storage: row-major, 16 named `float` fields `M11…M44`, no array, no `operator[]`, no `data()`** (`Matrix.hpp:27-60`, doc comments say "first row and first column"; the 16-arg ctor doc at `:66` says "row-major"). Default construction is **all zeros, not identity** (`Matrix.cpp:104-110`); identity is only `Matrix::getIdentityProperty()` — there is **no `Matrix::Identity` constant** (contrast `Quaternion::Identity`, which *is* a real static const at `Quaternion.cpp:13`). **VERIFIED.**

**F94. Multiplication: `Matrix::Multiply(A, B)` applies A FIRST (row-vector convention).** `result.M11 = a.M11*b.M11 + a.M12*b.M21 + a.M13*b.M31 + a.M14*b.M41` (`Matrix.cpp:1081-1082`) is `Σ_k A(i,k)B(k,j)`; and `Vector3::Transform` is `v' = v_row · M` with translation read from **row 4** (`Vector3.cpp:411-419`: `+ matrix.M41`). Hence `v·(A·B) = (v·A)·B`. Independently corroborated by `CreateTranslation` writing `M41/M42/M43` (`Matrix.cpp:847-849`) and `BoundingSphere::Transform` extracting scale from matrix **rows** (`BoundingSphere.cpp:34-40`). **VERIFIED.**

**F95. `Quaternion::Multiply(q1, q2)` applies q2 FIRST — the OPPOSITE argument order from `Matrix::Multiply`.** The product is Hamilton `v = w₁v₂ + w₂v₁ + v₁×v₂`, `w = w₁w₂ − v₁·v₂` (`Quaternion.cpp:441-457`), and `Vector3::Transform(v, q)` is the active `q v q*` rotation (`Vector3.cpp:442-450`), so `Transform(v, q₁⊗q₂) = q₁(q₂ v q₂*)q₁*`. The repo proves it internally: `Concatenate(a,b)` — documented as "value1 is followed by value2" (`Quaternion.hpp:109`) — expands term-for-term to `Multiply(b,a)` (`Quaternion.cpp:139-142` vs `:449-457`). **VERIFIED. A chapter sentence saying "CNA composes left-to-right" would be wrong for one of the two types.**

**F96. Depth range is `[0, 1]` (Direct3D), not `[-1, 1]`.** `CreatePerspectiveFieldOfView` sets `M33 = f/(n−f)`, `M34 = −1`, `M43 = n·f/(n−f)`, `M44 = 0` (`Matrix.cpp:649-652`): at `z_view = −n` → `z_ndc = 0`; at `z_view = −f` → `z_ndc = 1`. Orthographic uses `M33 = 1/(n−f)`, `M43 = n/(n−f)`, `M44 = 1` — same mapping (`Matrix.cpp:570-574`, off-center at `:588-597`). **Independently confirmed by `BoundingFrustum`'s plane extraction** (F103). **VERIFIED.**

**F97. Every angle in the module is radians. `MathHelper::ToDegrees`/`ToRadians` are the only degree-aware APIs.** `CreateRotationX/Y/Z`'s parameter is literally named `radians` (`Matrix.hpp:521-564`); `CreatePerspectiveFieldOfView` documents "in radians" (`:469`) and range-checks against π. **VERIFIED.**

**F98. `Matrix::ToColumnMajor(float out[16])` is `CNAEXT` and does NOT transpose.** It copies the fields in declaration (row-major) order (`Matrix.cpp:1234-1252`); the transpose is a free side effect of GL/Vulkan reading a `float[16]` as column-major. The renderers state the resulting rule: *"GLSL column i == HLSL row i"* (`modules/renderers/easygl/examples/easygl_billboard_shader_test.cpp:46-48`), *"the same CNA row-major -> GL column-major conversion"* (`modules/renderers/portablegl/src/PortableGLRenderer.cpp:289`). **VERIFIED.** The only test (`MatrixTests.cpp:760-769`) uses the **identity matrix**, which is its own transpose — it would pass against a genuine transposing implementation too.

**F99. `Vector3::Transform(v, Matrix)` does NOT perspective-divide and never reads the fourth matrix column** (`Vector3.cpp:411-419` reads only `M11..M43`). `Vector4::Transform` returns a live `W` and leaves the divide to the caller (`Vector4.cpp:419-433`). XNA-faithful. **VERIFIED.**

**F100. `TransformNormal` uses the matrix itself, not the inverse-transpose** (`Vector3.cpp:466-471`, `Vector2.cpp:402-406`) — correct only for orthogonal / uniform-scale matrices. `Vector4` has no `TransformNormal`. **VERIFIED.**

**F101. `CreateFromYawPitchRoll` composes roll(Z) → pitch(X) → yaw(Y) about fixed axes.** It delegates to `Quaternion::CreateFromYawPitchRoll` (`Matrix.cpp:519-523`), whose four component expressions expand exactly to `q_yaw ⊗ q_pitch ⊗ q_roll` (`Quaternion.cpp:238-254`); combined with F95 (rightmost first) that is roll → pitch → yaw. **VERIFIED** (algebraic derivation reproduced term-for-term).

**F102. `Plane` is `Normal·X + D = 0`, so `D` is the negated origin distance.** Proven by the 3-point constructor `D = -Dot(Normal, a)` (`Plane.cpp:27-35`) — which is also the **only** constructor that normalizes. `DotCoordinate = N·v + D` is the signed distance and the classification primitive (`:52-55`). **VERIFIED.**

**F103. `BoundingFrustum` plane extraction independently proves the D3D clip volume and outward-facing normals.** `src/BoundingFrustum.cpp:279-297` builds Near `(−M13,−M23,−M33,−M43)`, Far `(M13−M14, …)`, Left `(−M14−M11, …)`, Right `(M11−M14, …)`, Top `(M12−M14, …)`, Bottom `(−M14−M12, …)`, then normalizes each. Evaluated as `N·p + D` under the row-vector convention these are `−z_c`, `z_c − w_c`, `−w_c − x_c`, `x_c − w_c`, `y_c − w_c`, `−w_c − y_c` — i.e. inside ⟺ `−w ≤ x,y ≤ w` and **`0 ≤ z ≤ w`**. Inside is the *negative* half-space, so the normals point **outward** — which is why `Contains` maps `PlaneIntersectionType::Front` → `Disjoint` (`:86-88`, `:118-120`). **VERIFIED.**

**F104. `BoundingBox::GetCorners` order (the XNA quirk), exact** (`BoundingBox.cpp:236-248`): `0=(Min.X,Max.Y,Max.Z)`, `1=(Max,Max,Max)`, `2=(Max,Min,Max)`, `3=(Min,Min,Max)`, `4=(Min,Max,Min)`, `5=(Max,Max,Min)`, `6=(Max,Min,Min)`, `7=(Min,Min,Min)`. So **`Max` is at index 1 and `Min` at index 7**, the `Max.Z` face comes first, and each face winds TL→TR→BR→BL. `BoundingFrustum`'s corner order is topologically identical (near face first, same winding — `BoundingFrustum.cpp:267-277`). **No test asserts either order** — `BoundingBoxTests.cpp:133-146` only checks Min/Max appear *somewhere*. **VERIFIED.**

### Degenerate-input behaviour (uniformly silent)

**F105. Zero-vector `Normalize()` returns NaN in every component, unguarded** — `1.0f/std::sqrt(0)` = `+inf`, then `0*inf` = NaN: `Vector2.cpp:110-115`, `Vector3.cpp:121-127`, `Vector4.cpp:124-131`. Same hole in `Plane::Normalize` (`Plane.cpp:72-78`, `:132-138`) and `BoundingFrustum::NormalizePlane` (`BoundingFrustum.cpp:299-306`). **VERIFIED.**

**F106.** `Matrix::Invert` has **no singularity check at all** — `1.0f / determinant` at `Matrix.cpp:1009` yields ±inf, then inf/NaN throughout. No `bool` return, no exception, no fallback. `Quaternion::Normalize`/`Inverse` are equally unguarded (`Quaternion.cpp:69`, `:316`), as is `Matrix::CreateReflection`'s plane normalization (`Matrix.cpp:98-99`) and every component-wise `operator/`. **VERIFIED.**

**F107.** `Reflect` with a zero normal returns the input **unchanged** (not NaN): `Dot(v,0)=0` ⇒ every term subtracts 0 (`Vector3.cpp:367-371`, `Vector2.cpp:309-313`). It also **never normalizes** the normal. **VERIFIED.**

**F108. The NaN checkers are dead code.** `CheckForNaNs()` is declared on `Vector2`, `Vector3`, `Vector4`, `Quaternion`, `Matrix` (`Vector2.hpp:691`, `Vector3.hpp:751`, `Vector4.hpp:730`, `Quaternion.hpp:449`, `Matrix.hpp:973`), defined in each `.cpp` to throw `std::logic_error` — and has **zero call sites in the entire repository** (grep returns exactly 5 declarations + 5 definitions). All are `private` and `#if !defined(NDEBUG)`-gated. **VERIFIED.**

**F109. `getDebugDisplayStringProperty()` is likewise dead.** Declared on 10 types (Matrix, Vector2/3/4, Quaternion, Color, Point, Rectangle, BoundingBox, BoundingFrustum), defined in each `.cpp`, **20 total occurrences, zero call sites** — not from `ToString`, not from any test, not from any renderer. **VERIFIED.** The book's ch.07 §1 devotes a section to "two debug-only helpers"; the correct framing is that both are structurally-ported XNA `[Conditional("DEBUG")]` hooks that were never wired up.

**F110. Equality is exact float `==` everywhere, never epsilon** — `Vector2.cpp:101`, `Vector3.cpp:116`, `Vector4.cpp:115-118`, `Matrix.cpp:237-243`, `Quaternion.cpp:43-49`, `Plane.cpp:173-176`, `Ray.cpp:24-27`, `BoundingBox.cpp:451-459`, `BoundingSphere.cpp:171-174`. Consequences: a NaN vector is never equal to itself; `q` and `−q` (the same rotation) compare unequal; `BoundingFrustum::operator==` compares only the source `Matrix`, not the derived planes (`BoundingFrustum.cpp:372-377`). `MathHelper::WithinEpsilon` exists but **no `Equals` uses it**. **VERIFIED.**

### Divergences within the module

**F111. `MathHelper::SmoothStep`/`Hermite`/`CatmullRom` are NOT the same functions as the vectors' same-named operations.** `MathHelper::Hermite` computes in `double` and **short-circuits both endpoints** via `WithinEpsilon` (`MathHelper.cpp:80-87`), so `MathHelper::SmoothStep(a,b,1.0f)` returns `b` exactly; the vectors' file-local `HermiteScalar` is pure `float` with no short-circuits (`Vector3.cpp:53-68`, duplicated in `Vector2.cpp`/`Vector4.cpp`), so `Vector3::SmoothStep(a,b,1.0f)` does not. **VERIFIED.**

**F112. The two `Clamp`s disagree on inverted ranges.** `MathHelper::Clamp` clamps against `max` first then `min`, so **`min` wins** when `min > max` (`MathHelper.cpp:46-51`); the vectors' `ClampScalar` is `std::min(std::max(v,min),max)`, so **`max` wins** (`Vector3.cpp:26-29`). `MathHelper::Clamp(5,10,1)` → `10`; component-wise vector clamp on the same inputs → `1`. Likewise `MathHelper::Max/Min` are ternaries (`MathHelper.cpp:106-114`) while the vectors use `std::max`/`std::min` (`Vector3.cpp:312-324`) — different NaN behaviour. **VERIFIED.**

**F113.** `MathHelper::Lerp` is the **imprecise** `a + (b−a)*t` (`MathHelper.cpp:101-104`); it does not guarantee `Lerp(a,b,1) == b`. There is **no `LerpPrecise`, no `IsPowerOfTwo`, no `NextPowerOfTwo`** — CNA tracks FNA, not MonoGame. Beyond XNA's twelve methods it adds exactly three FNA-internal ones made public for lack of assembly visibility: `Clamp(intcs,…)`, `WithinEpsilon`, `ClosestMSAAPower` (`MathHelper.hpp:40-41`, `:171-188`). **VERIFIED.**

**F114.** `WrapAngle` produces the half-open range **`(-π, π]`** (π maps to itself, −π maps to +π) via a fast path plus `std::fmod(angle, TwoPi)` and one ±TwoPi correction (`MathHelper.cpp:133-154`). **VERIFIED.**

**F115. `Ray` uses three different epsilons in one file.** The box slab test uses `MathHelper::WithinEpsilon(Direction.X, 0.0f)` ≈ **5.96e-8** (`Ray.cpp:39,57,90`); plane parallelism uses a hard-coded **1e-5** (`Ray.cpp:184`); the behind-ray plane tolerance uses **−1e-5** (`:194`); the sphere test has **no epsilon at all** (`:148-172`). Return type is `std::optional<float>` throughout (`Ray.hpp:58-106`). "Starts inside" yields `0.0f` for box (`:123-126`), sphere (strict `<`, so on-surface falls through — `:155-159`), and frustum (`BoundingFrustum.cpp:244-257`). **A zero-direction ray inside a box returns `nullopt`, not `0.0f`** (all three axes take the parallel branch and `tMin` is never assigned — `Ray.cpp:34-134`). **VERIFIED.**

**F116. `Curve::ComputeTangent` uses two DIFFERENT degeneracy tests for the same condition in the same function.** `TangentIn` uses `MathHelper::WithinEpsilon(pn, 0.0f)` ≈ 5.96e-8 (`Curve.cpp:229`); `TangentOut` uses `std::fabs(pn) < std::numeric_limits<float>::denorm_min()` ≈ 1.4e-45 (`:254`) — a **~4×10³⁷ ratio**. The `TangentOut` form matches C#'s `float.Epsilon` exactly, so the `TangentIn` line is the deviation. **VERIFIED.**

**F117.** `Curve::Evaluate`'s `postLoop == Linear` branch uses **`first.getTangentOutProperty()`**, not `last`'s (`Curve.cpp:132`) — an upstream MonoGame/FNA quirk faithfully reproduced, but carrying **no explanatory comment**, unlike every other documented deviation in this repo. **VERIFIED** (code); **PROBABLE** (that it is deliberate rather than a transcription slip).

**F118.** `Curve::GetCurvePosition` is cubic Hermite `(2t³−3t²+1)v₀ + (t³−2t²+t)m₀ + (3t²−2t³)v₁ + (t³−t²)m₁` (`Curve.cpp:302-305`), with a `CurveContinuity::Step` branch whose threshold is a hard-coded `position >= 1.0f` (`:290`) and a silent `return 0.0f` fall-through when no bracketing key is found (`:309`). **VERIFIED.**

**F119.** `CurveKeyCollection::Add` maintains sortedness by inserting before the first key with a **strictly greater** `Position` (`CurveKeyCollection.cpp:76-94`) — duplicates are **allowed** and append after existing equals; nothing throws. `setItemProperty` replaces in place if the position is `WithinEpsilon`-equal, otherwise **erases and re-`Add`s** (`:41-59`) — i.e. an index assignment can silently move the element. All index accessors throw `std::out_of_range` (`:27,36,46,160`); `CopyTo` throws `std::out_of_range` for both the negative-index and too-small cases where FNA raises two different .NET types (comment at `:118-119`). **VERIFIED.**

**F120. `BoundingSphere::CreateFromPoints` is Ritter's algorithm** (six extremal points → widest axis pair → seed → **single** grow pass) — `BoundingSphere.cpp:200-263`. It is **not** the minimum enclosing sphere; it overestimates and is order-dependent. The tests are honest about this: they assert only enclosure (`EXPECT_LE(dist, s.Radius + kEps)`, `BoundingSphereTests.cpp:138,166,444`), never minimality. `CreateFromBoundingBox` is the **circumscribed** sphere (half the space diagonal, `:183-193`). **VERIFIED.**

**F121.** `Rectangle::Contains` is **half-open**: `X <= x && x < X+Width && Y <= y && y < Y+Height` (`Rectangle.cpp:71-93`) — top/left inclusive, bottom/right exclusive. `Intersects` is strict `<` on all four edges, so **touching rectangles do not intersect** (`:142-148`), while `BoundingBox::Intersects` uses inclusive `>=`/`<=`, so touching boxes **do** (`BoundingBox.cpp:324-339`). `IsEmpty` requires **all four** fields to be 0 (`:61-64`). `getCenterProperty` uses **integer** division (`:56-59`). `GetHashCode = X^Y^Width^Height` (`:137-140`). There is **no `Contains(Vector2)`** — XNA-faithful, MonoGame added it. **VERIFIED.**

**F122.** `Point` stores `intcs` (`int32_t`) and has **zero `Vector` interop** — `grep Vector Point.hpp Point.cpp` → 0 matches. Operators are `+ - * /` component-wise plus `== !=` (`Point.cpp:52-80`); `operator/` has no zero guard. **VERIFIED.**

**F123.** Vector operator sets are complete for `- (unary)`, `== !=`, `+ -`, `* (v,v)`, `* (v,s)`, `* (s,v)`, `/ (v,v)`, `/ (v,s)`. **Absent everywhere:** `operator/(scalar, v)`, `operator[]`, `<=>`. **Only `Vector3` has compound assignment** (`+=`, `-=`), and both are explicitly `CNAEXT`-marked (`Vector3.hpp:123,131`). `Matrix` and `Quaternion` have **no** compound assignments at all, and `Matrix` has no `operator*(float, Matrix)`. **VERIFIED.**

**F124.** Conversions are widening-only via constructors: `Vector3(Vector2, float)` (`Vector3.hpp:76`), `Vector4(Vector2, float, float)` (`Vector4.hpp:61`), `Vector4(Vector3, float)` (`:69`). **No narrowing conversions, no conversion operators, no `ToVector2()`.** There is **no `operator<<` anywhere in `modules/math`** — streaming requires `.ToString()`. **VERIFIED.**

**F125.** `ToString` brace style is **inconsistent by design**: `Ray` and `BoundingBox` use double braces `{{…}}`, `BoundingSphere` and `BoundingFrustum` use single. `BoundingBoxTests.cpp:446-448` is literally named `ToStringMatchesFNAFormat` and pins `"{{Min:{X:1 Y:2 Z:3} Max:{X:4 Y:5 Z:6}}}"`. **VERIFIED.**

### Color (item 12)

**F126. THE COUNT IS 141.** Exact commands and output:

```
$ grep -cE "^\s*(CNAEXT\s+)?static const Color [A-Za-z]+;" modules/math/include/Microsoft/Xna/Framework/Color.hpp
141
$ grep -cE "^\s*const Color Color::[A-Za-z]+" modules/math/src/Color.cpp
141
```
Declarations run `Color.hpp:72-352`; definitions `Color.cpp:113-253`. **Every declared constant is defined; there are no orphans. AUDIT.md's 141 is correct and the book's 140 is wrong.** Three refinements that let a reader reconstruct any of the three defensible numbers — **all VERIFIED**:
- **141** = every `static const Color` member.
- **140** = the opaque named colors. `Transparent` is the *only* constant whose alpha is not `0xff`: `grep -nE "^\s*const Color Color::" Color.cpp | grep -vE "0xff[0-9a-f]{6}U"` returns exactly one line, `Color.cpp:113` `Transparent(0x00000000U)`. Excluding it gives 140 — almost certainly how the book arrived at its figure.
- **139** = distinct packed values. Exactly two alias pairs share a value: `Aqua`/`Cyan` (`0xffffff00U`) and `Fuchsia`/`Magenta` (`0xffff00ffU`).

**F127. Packing is `A<<24 | B<<16 | G<<8 | R` in the `uint32`** (`Color.cpp:308-315`), i.e. **numerically ABGR, which is RGBA in memory byte order on a little-endian machine**. The header calls it "packed as AABBGGRR" (`Color.hpp:21,56,63`). Accessors are `R = pv & 0xFF`, `G = (pv>>8)&0xFF`, `B = (pv>>16)&0xFF`, `A = (pv>>24)&0xFF` (`Color.cpp:321-359`), each setter masking its own byte. **The representation is endianness-independent as an integer**, but any code that reinterprets the bytes is little-endian dependent — and F86 makes such reinterpretation illegal anyway. **VERIFIED.**

**F128. Two different float→byte paths, deliberately.** Constructors **clamp**: `ToByteFromUnitClamped` = `MathHelper::Clamp(v*255.0f, 0, 255)` then truncating cast, with **NaN → 0** because `MathHelper::Clamp` passes NaN through unclamped (both comparisons false) and `static_cast<intcs>(NaN)` is UB in C++ where C#'s `(byte)` cast is merely unspecified (`Color.cpp:41-58`, 12-line rationale at `:46-54`). `IPackedVector::PackFromVector4` **truncates without clamping**, matching FNA's `(byte)(vector.X * 255.0f)` exactly, but routes through a `±2²³` bound first so the narrowing is well-defined modulo-256 rather than UB, with non-finite → 0 (`Color.cpp:60-82`, `:484-490`). Integer constructors clamp via `std::clamp(v, 0, 255)` (`:27-35`). **No rounding anywhere — it is always truncation.** **VERIFIED.**

**F129.** `FromNonPremultiplied(Vector4)` = `Color(x·w, y·w, z·w, w)` through the clamping float ctor (`Color.cpp:453-460`); the integer overload uses `r*a/255` with **integer** division (`:462-469`). `Multiply`/`operator*` scale all four channels including alpha (`:471-478`, `:506-514`). `Lerp` clamps `amount` to `[0,1]` then `MathHelper::Lerp`s each channel (`:435-451`). Both `Lerp` and `Multiply` route through `SafeFloatToIntcs`, which maps non-finite → 0 and bounds to ±1e6 before the cast (`:93-101`, rationale at `:84-92`). **The 141 named constants are stored straight (non-premultiplied)** — every one is an opaque `0xff……` literal except `Transparent`. **VERIFIED.**

**F130.** `ToVector3`/`ToVector4` divide by `255.0f` (`Color.cpp:398-413`); `ToString` is `{R:… G:… B:… A:…}` (`:420-429`); `GetHashCode` is the raw packed value (`:415-418`); `Equals` compares packed values (`:393-396`). `R/G/B/A` are get **and set** properties. Only `operator==`, `!=`, `*(Color,float)`, `*(float,Color)` exist — **no `+`, `-`, `/`** (`:496-514`). **Color throws nothing.** **VERIFIED.**

### Math test evidence (item 14)

**F131.** Framework is GoogleTest, flat `TEST(Suite, Name)` only — **zero `TEST_F`, zero `TEST_P`**, no fixtures. Command: `for f in modules/math/tests/Microsoft/Xna/Framework/*.cpp; do echo "$(grep -c '^TEST' $f) $(basename $f)"; done`. **Total: 818 cases.** Largest: `Vector3Tests` 83, `Vector4Tests` 79, `MatrixTests` 78, `Vector2Tests` 76, `Quaternion` 56, `MathHelper` 54, `Color` 57, `BoundingBox` 51, `BoundingSphere` 51, `BoundingFrustum` 40, `Rectangle` 35, `Plane` 32, `Curve` 28, `CurveKeyCollection` 21, `Ray` 19, `Point` 18, `CurveKey` 17, plus small enum suites. **VERIFIED.**

**F132.** Two assertion styles: `EXPECT_FLOAT_EQ` (GoogleTest's **4-ULP** comparison, *not* exact `==`) for pure data movement, and `EXPECT_NEAR` with an explicit tolerance for anything through a transcendental or a division. The tolerance literals across the whole module are exactly three values: **`1e-5f`** (71 uses), **`1e-6f`** (45), **`1e-4f`** (1). The named constant `kEps` is redefined per file — `1e-5f` in `MathHelperTests.cpp:9`, `PlaneTests.cpp:14`, `BoundingSphereTests.cpp:24`, `MatrixTests.cpp:13`, `QuaternionTests.cpp:13`, but **`1e-4f` in `BoundingFrustumTests.cpp:26`** — a 10× loosening that is a direct admission of F103's accumulated error. **No test uses raw `==` on a float.** **VERIFIED.**

**F133. There are NO XNA/MonoGame numeric oracle values anywhere.** `grep -niE 'xna|monogame|fna|oracle'` across the suites yields three substantive hits, none of them a captured number: a *test name* (`Vector3Tests.cpp:45 DirectionConstantsMatchXnaConvention`, asserting 0/±1), a **string-format** contract (`BoundingBoxTests.cpp:446-448 ToStringMatchesFNAFormat`), and a *comment* reasoning about FNA-compatible behaviour (`BoundingFrustumTests.cpp:223`). Everything else is analytic and self-derived, with the derivation in the comment — e.g. `MatrixTests.cpp:55` `// Scale(2,3,4) → det = 2*3*4 = 24`; `:593-596` `EXPECT_NEAR(m.M22, 2.0f/3.0f, kEps)` (the expectation literally re-evaluates the implementation's own formula); `:663-664` `// dot = (0*0 + 1*(-1) + 0*0) = -1`. **VERIFIED. These are wiring tests, not conformance tests.**

**F134. Consequently the suite does not pin the module's most important semantics.** Unpinned: matrix multiplication order (`MatrixTests.cpp:139-145` uses two **translations, which commute**); quaternion multiplication order (`QuaternionTests.cpp:147-167` uses identity and `q·conj(q)`); the `[0,1]` depth mapping (only `M34 == −1` is checked, `:621-652`); `ToColumnMajor`'s transposing behaviour (identity input, F98); `BoundingBox`/`BoundingFrustum` corner order (F104); `Decompose`'s failure path; `Invert` on a singular matrix; `Slerp`'s `dot < 0` shortest-path branch and its `0.999999f` fallback (`QuaternionTests.cpp:207-213` interpolates about a **single shared axis**); `CreateFromYawPitchRoll` at any non-zero angle; and any zero-vector `Normalize`. `grep -niE 'nan|isinf|infinity'` over the vector and MathHelper suites returns **zero** matches. **VERIFIED.**

**F135.** `modules/runtime` has **115** test cases across 19 files, but two of the 19 are empty (F41), and 12 of the 19 files skip entirely without an SDL video subsystem (`GameTests.cpp:24-39` probe idiom). `GameTest.RunExecutesLifecycleInDocumentedOrder` (`:102-118`) is the only end-to-end lifecycle test and asserts only counts (`initializeCalls == 1`, `loadContentCalls == 1`, `updateCalls >= 1`, `drawCalls >= 1`) — **it does not assert order.** **VERIFIED.**

---

## ★ NEW FINDING: a live correctness bug in `Plane::Transform(Plane, Matrix)`

**F136. `Matrix::Transpose(const Matrix&, Matrix&)` is not aliasing-safe, and `Plane::Transform` calls it aliased.**

`modules/math/src/Matrix.cpp:1191-1209` writes `result` field-by-field while reading `matrix`:
```cpp
result.M12 = matrix.M21;   // line 1194
...
result.M21 = matrix.M12;   // line 1197 — reads the value line 1194 just overwrote
```

`modules/math/src/Plane.cpp:147-158` calls it with the same object as both arguments:
```cpp
Matrix transformedMatrix;
Matrix::Invert(matrix, transformedMatrix);
Matrix::Transpose(transformedMatrix, transformedMatrix);   // ← line 151, ALIASED
```

Tracing the aliased call: each upper-triangle cell receives the lower-triangle mirror, and each lower-triangle cell then re-reads the already-overwritten upper cell, so it is left unchanged. The net result is **`symmetrize_from_lower(M)`, not `transpose(M)`** — the two coincide only when `M` is already symmetric.

Step-by-step trace of the aliased call on input `A`:

| Line | Statement | Effect |
|---|---|---|
| 1194 | `result.M12 = matrix.M21` | `M12 := a21` |
| 1195 | `result.M13 = matrix.M31` | `M13 := a31` |
| 1196 | `result.M14 = matrix.M41` | `M14 := a41` |
| 1197 | `result.M21 = matrix.M12` | reads the **already-overwritten** `M12` (= `a21`) ⇒ `M21 := a21`, **unchanged** |
| 1199 | `result.M23 = matrix.M32` | `M23 := a32` |
| 1200 | `result.M24 = matrix.M42` | `M24 := a42` |
| 1201 | `result.M31 = matrix.M13` | reads overwritten `M13` (= `a31`) ⇒ **unchanged** |
| 1202 | `result.M32 = matrix.M23` | reads overwritten `M23` (= `a32`) ⇒ **unchanged** |
| 1204 | `result.M34 = matrix.M43` | `M34 := a43` |
| 1205 | `result.M41 = matrix.M14` | reads overwritten `M14` (= `a41`) ⇒ **unchanged** |
| 1206 | `result.M42 = matrix.M24` | reads overwritten `M24` (= `a42`) ⇒ **unchanged** |
| 1207 | `result.M43 = matrix.M34` | reads overwritten `M34` (= `a43`) ⇒ **unchanged** |

Diagonal cells (1193, 1198, 1203, 1208) are self-assignments.

**Worked counterexample.** `M = CreateTranslation(1,0,0)`. `inverse(M)` has `M41 = −1`, `M14 = 0`, unit diagonal. The aliased "transpose" yields `M14 = −1` **and** `M41 = −1`; the true transpose yields `M14 = −1`, `M41 = 0`.

Now transform the plane `y = 1` (`Normal = (0,1,0)`, `D = −1`), i.e. `Vector4 v = (0,1,0,−1)`, under the row-vector convention (F94):

- **Correct transpose:** `x' = 0·1 + 1·0 + 0·0 + (−1)·0 = 0`; `y' = 1`; `z' = 0`; `w' = 0·(−1) + 1·0 + 0·0 + (−1)·1 = −1` → plane `(0,1,0,−1)`, **unchanged**. Correct: translating along X does not move the `y = 1` plane.
- **Aliased/symmetrized:** `x' = 0·1 + 1·0 + 0·0 + (−1)·(−1) = +1`; `y' = 1`; `w' = −1` → plane `Normal = (1,1,0)`, `D = −1`. **Wrong — a pure translation silently rotates the plane's normal.**

**Blast-radius analysis.** `grep -rn "Matrix::Transpose" modules/` finds 20 call sites: `modules/renderers/easygl/examples/easygl_instancedmodel_shader_test.cpp:135`, `modules/renderers/directx9/src/DirectX9Renderer.cpp:921,965`, `modules/renderers/directx9/src/D3D9SkinnedVertexColorDraw.cpp:81,97`, `modules/renderers/opengl2/examples/opengl2_instancedmodel_test.cpp:89`, `modules/renderers/directx9/src/D3D9EffectDraw.cpp:132,509`, `modules/renderers/directx9/src/D3D9SpriteBatch.cpp:232`, `modules/renderers/directx9/src/D3D9InstancedDraw.cpp:119`, `modules/renderers/opengl4/examples/opengl4_instancedmodel_shader_test.cpp:88`, `modules/renderers/directx9/examples/directx9_effectrenderer_test.cpp:99`, `modules/renderers/directx9/src/D3D9PbrDraw.cpp:90`, `modules/math/tests/…/MatrixTests.cpp:191,328`, `modules/math/src/Plane.cpp:151`, plus comment-only mentions. **`Plane.cpp:151` is the only in-place/aliased one** — every other caller uses the value-returning overload, which allocates a distinct `result` (`Matrix.cpp:1184-1189`) and is therefore safe. The blast radius is exactly `Plane::Transform(const Plane&, const Matrix&, Plane&)` and, by delegation, the value-returning `Plane::Transform(Plane, Matrix)` (`Plane.cpp:140-145`).

**Why it has never been caught:** the only two `Plane::Transform(Matrix)` tests use the **identity matrix** (`PlaneTests.cpp:215-221 TransformByIdentityMatrixUnchanged`, `:298-305 TransformByIdentityMatrixOutRef`), whose inverse is symmetric — the one input class for which symmetrize and transpose agree.

**VERIFIED** by code trace (no build was run, per the audit constraints). **This refutes the parallel pass's fact 12.7 ("`Plane::Transform` correctly uses the inverse-transpose") and invalidates the book's existing "Plane::Transform inverse-transpose finding (numerically verified)" claim** — the *intent* is inverse-transpose; the *behaviour* is not.

---

## TYPE INVENTORY

### `modules/runtime` (21 public types)
| Type | One-line note |
|---|---|
| `Game` | Lifecycle owner; **value-owns a `GraphicsDevice`** (F7); 4 events; `RunApplication` is a public `CNAEXT` loop flag |
| `GameTime` | 3 fields, public getters, **private setters unlocked by `friend class Game`** |
| `GameComponent` | `Enabled`/`UpdateOrder` + `EnabledChanged`/`UpdateOrderChanged`; `CompareTo` is inverted (F36) |
| `DrawableGameComponent` | Adds `Visible`/`DrawOrder`/`LoadContent`/`UnloadContent`; `Initialize()` loads content immediately (F38) |
| `GameComponentCollection` | `final`, non-owning `vector<IGameComponent*>`; raises Added/Removed; real C++ iterators (`CNAEXT`) |
| `GameComponentCollectionEventArgs` | Carries the affected `IGameComponent*` |
| `IGameComponent` / `IUpdateable` / `IDrawable` | Pure-virtual; the latter two expose `EventHandler&` accessors |
| `GameServiceContainer` | `unordered_map<type_index, void*>`, non-owning, duplicate-rejecting, move-only |
| `GameWindow` | **One concrete SDL3 class** where FNA has a hierarchy; live-SDL reads with cache fallback; setters can throw |
| `GraphicsDeviceManager` | 4 bases; owns preferences, not the device; hosts the `PresentationMode` extension |
| `IGraphicsDeviceManager` | 3 methods: `BeginDraw`/`CreateDevice`/`EndDraw` |
| `GraphicsDeviceInformation` | Adapter ptr + `GraphicsProfile` + `PresentationParameters`, with `Clone()` |
| `PreparingDeviceSettingsEventArgs` | Holds a **`GraphicsDeviceInformation*`** — mutations by handlers survive |
| `PresentationMode` (enum) | `CNAEXT`, 5 values, **declared inside `GraphicsDeviceManager.hpp`** (F51) |
| `LaunchParameters` | **Publicly derives `std::unordered_map<string,string>`** (F72) |
| `TitleContainer` / `TitleLocation` | Static-only; `SDL_GetBasePath` + Android `SDL_LoadFile` fallback |
| `ExitingEventArgs` | **Dead code** — declared, never referenced by `Game` (F77) |
| *(`FrameworkDispatcher`)* | Lives in `modules/audio`, not runtime (F5) |

### `modules/math` (24 public types)
| Type | One-line note |
|---|---|
| `Vector2` | Only vector with a `constexpr` ctor; only one with `constinit` statics |
| `Vector3` | 11 statics incl. `Forward = (0,0,-1)`; **only vector with `+=`/`-=`** (both `CNAEXT`) |
| `Vector4` | 6 statics; extra `Vector2`/`Vector3`-source `Transform` overloads for clip space |
| `Matrix` | 16 named row-major floats; default is **zero, not identity**; `CNAEXT ToColumnMajor` |
| `Quaternion` | X,Y,Z,W; real `Identity` constant; **no default constructor**; multiply order opposite `Matrix`'s |
| `Plane` | `Normal·X + D = 0`; only the 3-point ctor normalizes; **`Transform(Matrix)` is buggy (F136)** |
| `Ray` | `std::optional<float>` results; three different epsilons in one file |
| `BoundingBox` | Min/Max + vptr; `CornerCount = 8`; XNA corner order; `Contains(BoundingFrustum)` is legacy-broken |
| `BoundingSphere` | Ritter `CreateFromPoints`; `Contains(BoundingFrustum)` can **never** return `Disjoint` |
| `BoundingFrustum` | `class`, caches 6 planes + 8 corners; **`PlaneCount` is private**; `Intersects(Ray)` throws |
| `Rectangle` | Half-open `Contains`, strict `Intersects`, integer `Center`, `IsEmpty` needs all four zero |
| `Point` | `int32_t` X/Y; **zero `Vector2` interop** |
| `Color` | **`sizeof == 24` because of the `IPackedVector` vptr (F86)**; 141 constants; AABBGGRR packing |
| `Curve` | Hermite evaluation + 5 loop types; two mismatched degeneracy epsilons |
| `CurveKey` | Position/Value/TangentIn/TangentOut/Continuity; derives `IEquatable` (⇒ vptr) |
| `CurveKeyCollection` | Sorted insert, duplicates allowed, `setItemProperty` can reposition |
| `MathHelper` | `final`, deleted ctor; 7 `constexpr` constants + a runtime-computed `MachineEpsilonFloat` |
| `IPackedVector` / `IPackedVectorT<T>` | In `Framework::Graphics::PackedVector` but shipped by `modules/math` because `Color` needs it |
| Enums | `ContainmentType`, `PlaneIntersectionType`, `CurveContinuity`, `CurveLoopType`, `CurveTangent` |

### `modules/core` (11 public types)
| Type | One-line note |
|---|---|
| `CNAEXT` macro | Expands to nothing; to `[[deprecated]]` under `CNA_STRICT_XNA_API` (`CNAHelper.hpp:22-26`) |
| `CNAException` | `: System::Exception` (`CNAException.hpp:15`), i.e. **`: std::exception`**, not `std::runtime_error` |
| `Logger` | Static-only; 7 levels × `*If` variants; **routes to `SDL_LogMessage`**; `SetMinimumLevel`; no env-var config, no mutex |
| `LogLevel` | `FATAL=0 … TRACE=5`, plus `EXPERIMENT = 100` |
| `LogCategory` | 9 values: APPLICATION, ERROR, SYSTEM, AUDIO, VIDEO, RENDER, INPUT, TEST, GPU |
| `Platform` + `getCurrentPlatform()` | `constexpr`, compile-time: Desktop / Android / iOS / Web |
| `DesktopOS` + `getCurrentDesktopOS()` | Windows/Linux/MacOSX/Other; **throws `CNAException`** off-desktop (`DesktopOS.cpp:16`) |
| `GraphicsRendererType` | **46 enumerators** — exact command: `sed -n '/enum class GraphicsRendererType/,/};/p' modules/core/include/CNA/GraphicsRendererType.hpp \| grep -cE "^\s{8}[A-Za-z_]"` → `46` |
| `Entrypoint.hpp` | Includes `<SDL3/SDL_main.h>` on Android (so `SDLActivity.nativeRunMain` finds `SDL_main`); no-op elsewhere — **Emscripten is explicitly in the no-op group** |
| `Internal/PathContainment` | Header-only path-traversal guard: `IsDisallowedAbsolutePath` (catches drive-letter/UNC on POSIX), `ValidateContainedPath` (component-wise, not prefix — so `content-evil` isn't a child of `content`), plus 3 resolvers |
| `PlayerIndex` | One=0…Four=3 |

---

## CONTRADICTIONS: docs vs implementation

**C1. `docs/gdm-coverage.md` is stale in five places** (last updated 2026-06-27 against commit `4d881ef`, per its own line 149):
- `:47-48` "DeviceReset — Raised at end of `ApplyChanges()`" / "DeviceResetting — Raised at start" — **false**. REMED-CORE-007 removed both raises; they are now forwarded from `GraphicsDevice`'s own events (`GraphicsDeviceManager.cpp:241-248`, `:325-332`).
- `:57` "`GraphicsDeviceManager(Game)` … calls `ApplyChanges()`" — **false and deliberately so** (`GraphicsDeviceManager.cpp:72-85`).
- `:109-114` describes `applyToExistingRenderer` as `SetPresentationParameters` → fullscreen → window size → `SetPresentationMode` → `SetVirtualResolution`. The live sequence is `SetGraphicsProfileEXT` → `SetPresentationMode` → `GraphicsDevice::Reset(pp, adapter)` → `UpdateViewportFromWindow` (`:614-632`).
- `:116-119` "`PreferMultiSampling` … not applied to renderer GPU resources until the renderer is recreated" — contradicted by the code comment at `:622-629`, which says `Reset()` reconfigures MSAA via `IGraphicsRenderer::ApplyMultiSampleCount()` and writes the applied value back into the stored PP.
- The Defaults table (`:136-145`) omits `preferredPresentationMode_ = FixedHeightDynamicWidth` (`GraphicsDeviceManager.cpp:56`), and the CNAEXT table omits the `GraphicsProfile` propagation path (`SetGraphicsProfileEXT`, `:614`).

**C2. `AUDIT.md:22` marks `BoundingFrustum` "✅ API complete"** — but `BoundingFrustum::Intersects(Ray)` throws `System::NotImplementedException` on its main case (`BoundingFrustum.cpp:264`), and `RayTests.cpp:211-214` says so in a comment while omitting the test. Two further silently-wrong functions are marked complete: `BoundingSphere::Contains(BoundingFrustum)` (`BoundingSphere.cpp:112-136` — `dmin` is declared, never computed, and compared, so `Disjoint` is unreachable) and `BoundingBox::Contains(BoundingFrustum)` (`BoundingBox.cpp:93-128` — tests the frustum's corners against the box, the reverse question, under a neutral `// Legacy behavior:` comment).

**C3. `AUDIT.md:34` marks `ExitingEventArgs` "✅ CNA-specific addition matching XNA pattern"** — it is unreferenced dead code (F77).

**C4. `AUDIT.md:24` "All 141 named constants + methods present" is CORRECT** and the book's 140 is the wrong figure (F126).

**C5. `PlaneIntersectionType`'s own doc comments are the inverse of every implementation.** `PlaneIntersectionType.hpp:10-17` documents `Front` as "the negative half-space" and `Back` as "the positive half-space"; `Plane::IntersectsPoint` returns `Front` for `distance > 0` (`Plane.cpp:114-117`), and both `BoundingSphere::Intersects(Plane)` (`:355-357`) and `BoundingBox::Intersects(Plane)` (`:424-434`) agree with the code, not the comment. **Operationally: `Front` = entirely on the +N side.**

**C6. `docs/RendererNamingMigration.md` §5 lists 41 identities (42 with OPENVG) — the live enum has 46.** The reconciliation: the doc's list includes `ASCII`, removed by `ea31cabc1`; since then `OPENVG`, `PORTABLEGL`, `SVG_DOM`, `FNA3D`, `BLEND2D`, `OPENGLES2` were added. 41 − 1 + 6 = **46**, matching the enum count.

**C7. `CNAEXT.md` does not document `PresentationMode` at all** — a `grep -n PresentationMode CNAEXT.md` returns nothing, despite it being one of the most user-visible CNA extensions.

**C8. `grep TODO`/`FIXME` over `modules/math` and `modules/runtime` returns clean, and that cleanliness is misleading.** The three unfinished sites in C2 carry no marker (two apparently had FNA's own `TODO` comments stripped and replaced with neutral prose). A marker-based audit of these modules reports "no known gaps" while two silently-wrong functions and one throwing stub remain.

---

## BOOK IMPACT

### Ch.06 "The Game Loop" (630 lines, target 40 pp, currently ~11)

**Wrong — must be corrected:**
1. **Lines 53-58**: *"The presence of `UnloadContent()` … is not a promise that CNA currently calls it… The live `Game` implementation has no call site for its own virtual, and its graphics manager's `DeviceDisposing` route is unreachable for the game-owned device topology."* **This is now false.** REMED-CORE-006 added the `DeviceDisposing → UnloadContent()` subscription (`Game.cpp:532-533`) and REMED-CORE-014 ungated the raise precisely because it was dead for the game-owned topology (`GraphicsDeviceManager.cpp:375-384`). Four tests now pin it (`GameTests.cpp:127,147,167,193`). Lines 106-108 need the same fix.
2. **Line 130**: *"No located CNA `Game` test exercises normal destruction, repeated public disposal, handler exceptions, or this re-entrancy boundary."* Repeated public disposal **is** now tested (`GameTest.RepeatedDisposeDoesNotReinvokeUnloadContent`, `GameTests.cpp:147`). The other three remain untested — narrow the claim rather than dropping it.
3. **Line 515** writes `NOXNA enum class PresentationMode` — the macro was renamed to `CNAEXT` on 2026-08-10.
4. **§Ch.06 "GraphicsDeviceManager's role in the loop"** must absorb C1: the device-reset event route is now forwarding-based, the constructor deliberately does not `ApplyChanges()`, and `applyToExistingRenderer` performs a real `GraphicsDevice::Reset`.

**Missing — the highest-value additions:**
5. **`Game::Update`'s trailing `FrameworkDispatcher::Update()` (F29)** — a subclass that overrides `Update` without calling the base silently kills dynamic audio, media and touch. This is the single best "gotcha" in the chapter's subject area and is currently absent.
6. **The Emscripten divergence table (F80).** The chapter mentions the callback in two sentences (lines 152-156) and defers to the Web chapter. Given that eight distinct behaviours change — `IsFixedTimeStep` ignored, `IsRunningSlowly` hard-false, `SuppressDraw`/`ResetElapsedTime` no-ops, 250 ms vs 500 ms clamp, ms-resolution timing, draw-only-if-updated, one-Game-per-process, and `EndRun`/`AfterLoop` never running — a table belongs *here*, with the cross-reference kept for the `-fwasm-exceptions` root cause.
7. **The `ElapsedGameTime` asymmetry (F24)**: `Update` sees `Target`, `Draw` sees `Target × stepCount`. Not currently stated.
8. **`RunOneFrame()` leaves `IsActive == false` (F14)** — a real trap for tooling and tests.
9. **The exception model (F82-F84)**: `modules/runtime` throws only raw `std::` types, and `System::Exception` derives from `std::exception`, **not** `std::runtime_error` — so no single `catch` clause short of `std::exception` spans the framework. This is porting-critical and belongs in this chapter.
10. **`GameWindow` property setters throw `std::runtime_error` on SDL failure (F65)**, with one deliberate non-fatal exception for the Emscripten `SDL_GetWindowSize` race (F66).

**Split? No.** Ch.06 is at ~11 of 40 pages with room for all of the above; splitting would separate `Game` from `GraphicsDeviceManager`, which the lifecycle order (steps 10, 26, 31) inseparably interleaves.

### Ch.07 "Math and Core Types" (1,675 lines, target 110 pp, currently ~34)

**Wrong — must be corrected:**
11. **Line 1055 §title "Color: 140 named constants"** and **line 1065 "Roughly 140"** → **141** (F126). Give all three numbers with the reasoning, since the 140/141/139 distinction is genuinely interesting: 141 declared, 140 opaque + `Transparent`, 139 distinct packed values (Aqua/Cyan, Fuchsia/Magenta).
12. **The `Plane::Transform` "inverse-transpose finding (numerically verified)"** logged in `PLAN.md:182` is now wrong: the *intent* is inverse-transpose but the aliased `Matrix::Transpose(m, m)` call makes the behaviour symmetrize-from-lower (**F136**). Whatever numeric verification was done must have used a symmetric inverse.
13. **The `NOXNA` spelling appears 10 times in this chapter** (198 times book-wide, across ~30 files, including a chapter file literally named `appendix-e-noxna-catalog.tex`). `grep -ro CNAEXT latex/book/chapters | wc -l` → **0**. This is a mechanical repo-wide rename (`NOXNA`→`CNAEXT`, `CNA_NOXNA`→`CNA_CNAEXT`, `CNA::NoXna`→`CNA::CnaExt`, `NOXNA.md`→`CNAEXT.md`) fully documented in `docs/RendererNamingMigration.md:119-137`, and the book has not absorbed any of it.
14. **Line 14 §"two debug-only helpers"** should say plainly that **both are dead code** — `CheckForNaNs` has 5 declarations, 5 definitions and **zero call sites repo-wide** (F108); `getDebugDisplayStringProperty` has 20 occurrences and zero call sites (F109).

**Missing — the highest-value additions, in priority order:**
15. **`sizeof(Color) == 24` (F86).** The chapter has a full Color section and never mentions that CNA's `Color` is not a 4-byte value type. This one fact changes `VertexPositionColor`'s stride (the test file says so at `VertexPositionColorTests.cpp:52-54`), forbids `reinterpret_cast<uint8_t*>` on pixel arrays (the `GetBackBufferData` bug fixed in `a63475e`), and forced special handling in `Texture3D.cpp:105` and `TextureCube.cpp:104`. It deserves its own subsection. The same vptr affects `BoundingBox`, `BoundingSphere`, `BoundingFrustum` and `CurveKey` (F87).
16. **The opposite multiply orders (F94 vs F95).** `Matrix::Multiply(A,B)` applies A first; `Quaternion::Multiply(q1,q2)` applies q2 first. Both XNA-faithful, both unpinned by any test, and the repo contains its own algebraic proof (`Concatenate(a,b) == Multiply(b,a)`). This is the most consequential semantic in the chapter and is not currently stated as a contrast.
17. **`ToColumnMajor` does not transpose (F98)** — the transpose is the consumer's reading, and the renderers state the rule as *"GLSL column i == HLSL row i"*.
18. **The `[0,1]` Direct3D depth range, derived twice (F96, F103)** — once from the projection builders, once independently from `BoundingFrustum`'s plane extraction, which also proves the frustum planes face **outward**.
19. **`MathHelper::X` ≠ `VectorN::X` for `SmoothStep`/`Hermite`/`CatmullRom`/`Clamp`/`Max`/`Min` (F111, F112)** — different precision, different endpoint behaviour, and *opposite* results on an inverted `Clamp` range. A reader will assume these are the same function.
20. **"Degenerate inputs are uniformly silent" as a chapter theme (F105-F107).** Zero-vector `Normalize` → NaN; singular `Invert` → inf/NaN; zero-quaternion `Normalize`/`Inverse` → NaN; `CreateReflection` on a zero-normal plane → NaN. The only guards in the whole module are four `std::invalid_argument` projection validators — and `CreatePerspectiveFieldOfView`'s upper guard is `3.141593f`, which is numerically **above** `MathHelper::Pi = 3.14159274f`, so `CreatePerspectiveFieldOfView(MathHelper::Pi, …)` does not throw.
21. **The three unfinished functions with no `TODO` marker (C2)** — a genuinely good cautionary anecdote about marker-based auditing.
22. **The split exception families (F82-F84, C-list).** The *same two operations* on sibling types throw different families: empty-input `CreateFromPoints` → `System::ArgumentException` on `BoundingBox` but `std::invalid_argument` on `BoundingSphere`; undersized `GetCorners` → `System::ArgumentOutOfRangeException` on `BoundingBox` but `std::out_of_range` on `BoundingFrustum`. **The tests encode both**, so the divergence is locked in.
23. **Test-evidence honesty (F133-F134).** 818 cases, GoogleTest, no fixtures, three tolerance values (`1e-4f`/`1e-5f`/`1e-6f`), and **no XNA/MonoGame numeric oracle anywhere** — every expectation is analytic or restates the implementation's own formula. Six of the module's most important semantics are therefore unpinned. A chapter that shows the test suite should say what it does *not* prove.
24. **`Ray`'s three different epsilons (F115)** and **`Curve::ComputeTangent`'s two mismatched degeneracy tests (F116)** — a 4×10³⁷ ratio between `TangentIn` and `TangentOut` in the same function.
25. **Module-boundary facts**: `modules/math` links only sharp-runtime + `cna_core_headers` (F4); `IPackedVector` ships from math because `Color` needs it; the `constinit`-only-in-`Vector2` asymmetry and its `constexpr`-constructor cause (F89); `MachineEpsilonFloat` is runtime-computed and is a static-init-order hazard (F90).

**Split? Yes — strongly recommended.** Ch.07 targets **110 pages**, holds eleven independent type families, and is at ~34 after four dedicated sessions. Recommended cut along the natural seam:
- **Ch.07a — Vectors, Matrix, Quaternion, MathHelper** (the convention chapter: handedness, row-vector, depth range, multiply orders, radians, `ToColumnMajor`, degenerate-input policy). ~55 pp.
- **Ch.07b — Geometry, Color, and value types** (Plane, Ray, BoundingBox/Sphere/Frustum, Rectangle, Point, Color, the Curve family, `IPackedVector`, the vptr/layout story, the exception-family split). ~55 pp.

Note that a split renumbers Ch.08–49, which per `CLAUDE.md` makes a project-wide `grep 'Chapter~[0-9]'` pass mandatory — the book's documented most-common failure mode. That is a strong argument for doing the split **before** more pages land, not after.

### Cross-cutting
26. The book has **6** stale `src/…`/`include/…` source-path references and **0** `modules/…` references (`grep -ro "modules/[a-z-]*" latex/book/chapters | wc -l` → 0). Every CNA path is now `modules/<module>/{src,include}/…` (F6). Cheap to fix, but every new citation this edition adds must use the new form.
27. The **backend → renderer** terminology rename (`57aee5f88`) is also unabsorbed: `GraphicsBackendType` → `GraphicsRendererType`, `IGraphicsBackend` → `IGraphicsRenderer`, `CNA_BACKEND_*` → `CNA_RENDERER_*`, `docs/<family>-backend.md` → `docs/<family>-renderer.md`, and the DirectX identity normalization (`DX1`→`DIRECTX1`, `D3D9`→`DIRECTX9`, …, with **no aliases kept for the old names**). Part IV is titled "backends". Full mapping table: `docs/RendererNamingMigration.md:24-102`.

---

## Corrections to parallel audit passes

Three claims from parallel passes are corrected by this one; each matters for the book:

1. **`std::bit_cast` is a repo-wide count that does not apply to `modules/math` at all.** The figure of 19 is correct for `modules/` as a whole (Skia ×3, WebGPU, SDL-GPU, DirectX9, `graphics/src/Xna/Texture2D.cpp`), but `grep -rn 'std::bit_cast' modules/math` returns **0**. The math module type-puns via `std::memcpy` in a thrice-duplicated anonymous-namespace `FloatHash` (`Vector2.cpp:18-24`, `Vector3.cpp:18-24`, `Vector4.cpp:18-24`). The `constinit` and "no concepts" halves of that claim are confirmed. (F88)

2. **`System::Exception` derives from `std::exception`, NOT from `std::runtime_error`** (`sharp-runtime/modules/core/include/System/Exception.hpp:32`). Consequently `catch (const std::runtime_error&)` does not catch `System::*` exceptions and `catch (const System::Exception&)` does not catch the `std::` ones — **no single catch clause short of `std::exception` spans the framework.** (F83)

3. **`modules/runtime` participates in neither exception family.** It throws only raw `std::` standard types — `std::out_of_range`, `std::runtime_error`, `std::invalid_argument`, `std::logic_error`, `std::bad_alloc` — across all 30 throw sites, and never a single `System::*` type. The Graphics/Content-vs-Audio/GamerServices/Net/Sensors split described by the parallel pass is confirmed for those modules but does not describe the framework core. (F82, F84)

A fourth correction applies to a claim about `Plane::Transform` being a correct inverse-transpose: see **F136**, which refutes it.
