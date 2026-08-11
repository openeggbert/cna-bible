# Audit report — input, devices/sensors, audio, media, net, GamerServices, Avatar, storage

Research pass against CNA `7a64362efef4119bf880459ef1704fb2c52199e2` (develop, 2026-08-11).
Read-only; no CNA build was run, no CNA file modified. Paths relative to the CNA repo root.

**Confidence legend:** `VERIFIED` = the exact lines were read directly. `STRONG` = code read plus
a documented rationale, but the runtime claim was not executed. `PROBABLE` / `UNCERTAIN` as usual.

**Scale (hard numbers, `grep -c '^TEST\(_F\|_P\)\?('`):**

| module | production LOC | test cases | test files |
|---|---|---|---|
| input | 25,708 | 522 | 42 |
| audio | 31,622 | 637 | 23 |
| media | 14,056 | 285 | 29 |
| net | 16,680 | 293 | 18 |
| gamer-services | 18,395 | 368 | 14 |
| devices | 22,789 | 462 | 24 |
| devices-ext | 3,713 | 50 | 10 |
| storage | 1,033 | **5** | **1** |
| **all modules** | — | **6,171** | — |

---

# 1. INPUT

## FACTS

1. **`Game::PollEvents()` is the single `SDL_PollEvent` site in the entire project**, and it funnels
   *every* event through one dispatcher before its own switch:
   `CNA::Internal::Input::SdlInputBridge::ProcessEvent(event)` —
   `modules/runtime/src/Game.cpp:905-910`. VERIFIED
2. Input state is **accumulated live by the bridge, not latched per frame**.
   `Keyboard`/`Mouse`/`GamePad`/`TouchPanel::GetState()` are pure reads of `InputManager`'s
   accumulated state. Two `GetState()` calls in one frame therefore return identical snapshots
   (FNA re-queries SDL and could differ). VERIFIED
3. **The whole input pipeline is unsynchronized by design.** `grep -c 'std::mutex\|std::atomic\|
   lock_guard'` over `modules/input/src` and `modules/input/include` returns **zero matching
   files**. Safety rests entirely on the contract that pumping and reading both happen on the
   game-loop thread. VERIFIED
4. `Keys` has **160 enumerators** (`grep -c '= [0-9]'` on
   `modules/input/include/Microsoft/Xna/Framework/Input/Keys.hpp`). VERIFIED
5. Scancode→`Keys` mapping in `modules/input/src/Internal/SdlInputBridge.cpp` has **125
   `case SDL_SCANCODE_…`** arms; the reverse `Keys`→SDL map has **126 `case Keys::…`** arms — i.e.
   the two directions are not symmetric and a subset of `Keys` values has no SDL scancode to map
   back to. VERIFIED (counts) / STRONG (the asymmetry conclusion)
6. `KeyboardState` stores pressed keys as **`std::unordered_set<Keys> pressedKeys_`** —
   `modules/input/include/Microsoft/Xna/Framework/Input/KeyboardState.hpp:109`;
   `GetPressedKeys()` returns `std::vector<Keys>` (`:67`). There is a `CNAEXT` ctor from
   `std::unordered_set<Keys>` (`:33`) and a `CNAEXT ToString()` (`:90`). VERIFIED
7. **Mouse/touch coordinates are transformed into *logical* (render) space, not raw window space**,
   through a two-tier "window registry": `SDL_GetRenderer(window)` →
   `SDL_RenderCoordinatesFromWindow` for the SDL_Renderer backend, else
   `CNA::Internal::Renderers::IGraphicsRenderer::GetForWindow(window)->TransformWindowToLogical(...)`,
   else pass-through — `modules/input/src/Internal/SdlInputBridge.cpp:505-532`. VERIFIED
8. The inverse path (`Mouse::SetPosition`) uses `SDL_RenderCoordinatesToWindow` /
   `IGraphicsRenderer::TransformLogicalToWindow` —
   `modules/input/src/Xna/Mouse.cpp:30-56`. The window it acts on is `Mouse::WindowHandle` if set,
   else `SDL_GetMouseFocus()` (`:13-17`). VERIFIED
9. Touch events are normalized 0..1 by SDL; the bridge multiplies by `SDL_GetWindowSize` **then**
   applies the same `to_logical_position` transform —
   `modules/input/src/Internal/SdlInputBridge.cpp:535-560`. Window resolution falls back from
   `touchEvent.windowID` to `SDL_GetMouseFocus()`. VERIFIED
10. **`MaxSupportedGamePads = 4`** — `modules/input/src/Internal/SdlInputBridge.cpp:37`; an
    out-of-range `PlayerIndex` override is clamped, not rejected (`:42-45`). VERIFIED
11. **Dead-zone constants are the exact XInput values**: `LeftDeadZone = 7849.0f/32768.0f`
    (≈0.2395), `RightDeadZone = 8689.0f/32768.0f` (≈0.2651),
    `TriggerThreshold = 30.0f/255.0f` (≈0.1176) —
    `modules/input/include/Microsoft/Xna/Framework/Input/GamePad.hpp:215,217,219`, all tagged
    `CNAEXT`. VERIFIED
12. All three `GamePadDeadZone` modes are real: `None` (no filtering), `IndependentAxes`
    (`ExcludeAxisDeadZone` per axis), `Circular` (`ExcludeCircularDeadZone` **plus** a subsequent
    `ApplyCircularClamp()`) — `modules/input/src/Xna/GamePadThumbSticks.cpp:22-70`. Triggers use
    `ExcludeAxisDeadZone(…, TriggerThreshold)` then clamp to `[0,1]`
    (`GamePadTriggers.cpp:23-37`). VERIFIED
13. `GamePadDPad` button flags are derived from the *processed* thumbstick by comparing against
    `deadZoneSize` on each axis — `modules/input/src/Xna/GamePadState.cpp:80-86`. VERIFIED
14. **All 10 `GestureType` values are actually detected.** Declared: `None=0, Tap=1, DoubleTap=2,
    Hold=4, HorizontalDrag=8, VerticalDrag=16, FreeDrag=32, Pinch=64, Flick=128,
    DragComplete=256, PinchComplete=512`
    (`modules/input/include/Microsoft/Xna/Framework/Input/Touch/GestureType.hpp:14-44`, with
    `|`/`&`/`|=`/`&=` operators at `:53-96`). `grep 'GestureType::'
    modules/input/src/Internal/GestureDetector.cpp | sort -u` yields exactly that set. **No
    declared-but-undetected gesture exists.** VERIFIED
15. `TextInputEXT` exposes **three** event channels: `System::MulticastAction<charcs> TextInput`,
    `MulticastAction<const std::string&,int,int> TextEditing`, and
    `MulticastAction<const std::vector<std::string>&,int,bool> TextEditingCandidatesEXT` —
    `modules/input/src/Xna/TextInputEXT.cpp:36-38`. The third (IME candidate list) has no FNA
    counterpart. VERIFIED
16. `TextInputEXT` maps to `SDL_StartTextInput` / `SDL_StopTextInput` /
    `SDL_StartTextInputWithProperties` (`:80,88,98`) and an IME cursor-rect hint (`:114`).
    `INTERNAL_OnTextInput` guards on a live delegate (`:121-124`); shutdown nulls all handlers
    (`:142`). VERIFIED
17. **The `CNA::Input` CNAEXT layer is unconditional** — `modules/input/CMakeLists.txt` contains no
    `if()` at all, and `modules/input/include/CNA/Input/*.hpp` carry no `#ifdef`. `Clipboard`,
    `Sensors`, `Power`, `Haptics`, `Joysticks`, `InputDevices`, `HapticDevice`, `KeyModifiers`,
    `TextInputType`, `JoystickState`… are compiled and exported in **every** configuration,
    including `CNA_DEVICES=OFF` and `CNA_CNAEXT=OFF`. VERIFIED
18. `CNA::Input::Sensors` **never calls `SDL_InitSubSystem(SDL_INIT_SENSOR)`**. The input module's
    only subsystem init is `SDL_INIT_GAMEPAD` at
    `modules/input/src/Internal/SdlInputBridge.cpp:1606`. Consequence: `GetSensorsEXT()` returns
    empty and both readers return `false` unless some *other* subsystem (e.g.
    `Microsoft::Devices::Sensors::Accelerometer`) initialized it first. Its own tests inject a fake
    backend, so they never catch it. STRONG
19. `CNA::Input::InputDevices` is the only one of the CNAEXT extras with a real production
    consumer — `modules/input/src/Internal/SdlInputBridge.cpp:1694,1697,1700,1703`. VERIFIED
20. `Game::PollEvents()` sets `IsActive` from `SDL_EVENT_WINDOW_FOCUS_LOST/GAINED` and
    `SDL_EVENT_WILL_ENTER_BACKGROUND/DID_ENTER_FOREGROUND`, and **deliberately does not clear held
    keyboard/mouse state on focus loss** (comment cites `docs/input-fna-fidelity.md` DEC-15) —
    `modules/runtime/src/Game.cpp:932-953`. VERIFIED
21. `F9`/`F10` are hard-wired debug keys for `DebugSimulateContextLoss()` /
    `DebugRestoreContext()` in the game loop itself —
    `modules/runtime/src/Game.cpp:919-925`. A game cannot use them. VERIFIED
22. `FrameworkDispatcher::Update()` pumps `TouchPanel::Update()` when
    `TouchPanel::getTouchDeviceExistsProperty()` —
    `modules/audio/src/Xna/FrameworkDispatcher.cpp` (final block). Gesture *timing* therefore
    depends on the game calling `FrameworkDispatcher::Update()`, not on the event pump. VERIFIED
23. The API surface is frozen by a compile-time test:
    `modules/input/tests/Microsoft/Xna/Framework/Input/PublicApiInputSignatureFreezeTests.cpp`
    plus `PublicApiInputCompileTests.cpp`. VERIFIED

## STATUS TABLE — INPUT

| API family | Status | Evidence | Test |
|---|---|---|---|
| `Keyboard` / `KeyboardState` (160 `Keys`) | IMPLEMENTED | `Keys.hpp`; `KeyboardState.hpp:109` | `KeyboardInputTests.cpp`, `KeyboardModStateTests.cpp` |
| Keyboard scancode/keycode name helpers (`…EXT`) | IMPLEMENTED (CNAEXT) | `modules/input/src/Xna/Keyboard.cpp` | `KeyboardScancodeNameTests.cpp`, `KeyboardKeyNameTests.cpp` |
| `Mouse` / `MouseState` + logical-coord transform | IMPLEMENTED | `Mouse.cpp:13-56`; `SdlInputBridge.cpp:505-532` | `MouseInputTests.cpp`, `MouseGlobalTests.cpp`, `SdlInputBridgeMouseTests.cpp` |
| `MouseCursor` | IMPLEMENTED | `modules/input/src/Xna/MouseCursor.cpp` | — |
| `GamePad` (4 pads, XInput dead zones, all 3 modes) | IMPLEMENTED | `GamePad.hpp:215-219`; `GamePadThumbSticks.cpp:22-70`; `SdlInputBridge.cpp:37` | `GamePadInputTests.cpp`, `GamePadDeadZoneTests.cpp`, `GamePadMappingTests.cpp`, `SdlGamepadBackendTests.cpp` |
| Vibration (`SetVibration`) | IMPLEMENTED (SDL gamepad rumble) | `modules/input/src/Xna/GamePad.cpp` | `GamePadTests.cpp` |
| `TouchPanel` / `TouchCollection` / `TouchLocation` | IMPLEMENTED | `modules/input/src/Xna/Touch/*` | `TouchInputTests.cpp`, `TouchEdgeCaseTests.cpp` |
| Gestures — **all 10 types detected** | IMPLEMENTED | `GestureType.hpp:14-44`; `GestureDetector.cpp` | `GestureDetectorTests.cpp`, `SdlInputBridgeTouchGestureTests.cpp` |
| `TextInputEXT` (+ IME candidates, CNAEXT) | IMPLEMENTED | `TextInputEXT.cpp:36-38,74-121` | `TextInputEXTTests.cpp`, `SdlInputBridgeTextInputTests.cpp` |
| `CNA::Input::Joysticks` / `Haptics` / `HapticDevice` | IMPLEMENTED, **ungated** | `modules/input/src/CnaExt/*`, `src/Internal/SdlJoystickBackend.cpp`, `SdlHapticBackend.cpp` | `SdlJoystickBackendTests.cpp`, `SdlHapticBackendTests.cpp` (fake backends) |
| `CNA::Input::InputDevices` (+hotplug) | IMPLEMENTED, real consumer | `SystemDeviceBackend.cpp`; `SdlInputBridge.cpp:1694-1703` | `InputDevicesTests.cpp`, `InputDevicesHotplugTests.cpp` |
| `CNA::Input::Clipboard` | IMPLEMENTED — **duplicate** of `CNA::Devices::Clipboard` | `modules/input/src/CnaExt/Clipboard.cpp:8-25` | `CNA/Input/ClipboardTests.cpp` |
| `CNA::Input::Power` | IMPLEMENTED — **duplicate** of `CNA::Devices::PowerInfo` | `SystemPowerBackend.cpp:12` | `CNA/Input/PowerTests.cpp` |
| `CNA::Input::Sensors` | **PARTIAL / latent no-op** — never inits `SDL_INIT_SENSOR` | `SystemSensorBackend.cpp:46-87` vs `SdlInputBridge.cpp:1606` | `CNA/Input/SensorsTests.cpp` (fake backend only) |
| Threading | **INTENTIONALLY single-threaded, unsynchronized** | zero mutex/atomic in module | `InputResetTests.cpp` |

## CONTRADICTIONS — INPUT

- **`NEXTinput.md`** is explicitly a 2026-07-18 "documentation-reconciliation pass, nothing built
  or re-tested," describes branch `feature/input` as the working context, and uses **`NOXNA`**
  throughout. As of this SHA `NOXNA` no longer exists anywhere in `modules/` (renamed to
  `CNAEXT`, commit `2ecbca579`). Stale terminology, correct substance.
- **`input_noxna.md` / `input_noxna_progress.md`** are entirely `NOXNA`-titled and phrased. Same
  rename issue.
- **`plan_input.md`** claims 505 tasks / 490 done / 15 hardware-blocked. The 15 blocked items are
  genuinely un-automatable hardware checks; the claim holds, but the test count it implies (`524`
  in the book) is now **522** at this SHA.
- **`docs/input-backend.md` / `docs/platform-input-notes.md`** predate the `modules/` physical
  split; every path they cite (`src/Input/…`, `include/Microsoft/Xna/Framework/Input/…` at repo
  root) has moved under `modules/input/`.

---

# 2. DEVICES / SENSORS

## FACTS

1. **`CNA_DEVICES` defaults OFF** — `CMakeLists.txt:61`. It is emitted only as
   `$<$<BOOL:${CNA_DEVICES}>:CNA_DEVICES>` on the shared `cna_build_flags` INTERFACE target
   (`modules/CMakeLists.txt:67`). VERIFIED
2. **The option gates nothing in `modules/devices`.** Zero `CNA_DEVICES` `#ifdef`s exist under
   `modules/devices/`. The entire `Microsoft::Devices` / `Microsoft::Devices::Sensors` surface
   (all four sensors + `VibrateController`) is compiled and linked in **every** configuration.
   VERIFIED
3. **The option gates *everything* in `modules/devices-ext`.** All 24 headers, 14 sources, and 10
   test files are wrapped `#ifdef CNA_DEVICES … #endif`; zero ungated files. With the default OFF
   build, `CNA::Devices::Camera`/`Clipboard`/`FileDialog`/… **do not exist as types**,
   `libcna_devices_ext.a` contains 14 objects with **zero defined symbols**, and its 10 test files
   register **zero** gtest cases (they are globbed and compiled, not excluded). VERIFIED —
   corroborated against the repo's own pre-existing `cmake-build-debug` tree
   (`CMakeCache.txt:319` = `CNA_DEVICES:BOOL=OFF`).
4. **Therefore the option's own help string is misleading**: "Enable CNA-specific device/**sensor**
   extensions … (battery, camera, clipboard, …)" — sensors are not gated by it at all. VERIFIED
5. **`SensorBase<TSensorReading>`** is a header-only 791-line template
   (`modules/devices/include/Microsoft/Devices/Sensors/SensorBase.hpp:36-790`), `static_assert`ing
   `is_base_of_v<ISensorReading, TSensorReading>`. Default `TimeBetweenUpdates` = **2 ms**
   (`:600`). `getCurrentValueProperty()` throws `InvalidOperationException` when unsupported
   (`:640-644`). VERIFIED
6. **`TimeBetweenUpdates` is a software throttle**, not a hardware rate: `ShouldAcceptUpdateAt()`
   on `steady_clock`, casting elapsed *down* to ticks before comparing to avoid an int64 overflow
   found by UBSan at `TimeSpan::MaxValue` (`:499-534`). VERIFIED
7. **`Accelerometer` and `Gyroscope` are the SDL3-backed pair.** `SDL_SENSOR_ACCEL`
   (`modules/devices/src/Sensors/Accelerometer.cpp:40-43`) / `SDL_SENSOR_GYRO`
   (`Gyroscope.cpp:37-40`). `getIsSupportedProperty()` is a platform allowlist
   `{Android, iOS, Desktop}` — **`Platform::Web` is hard-excluded** despite SDL having a real
   `SDL_SENSOR_EMSCRIPTEN` backend (`Accelerometer.cpp:59-73`) — followed by a real
   `SDL_GetSensors`/`SDL_OpenSensor` probe. VERIFIED
8. Accelerometer divides SDL's SI m/s² by `StandardGravity = 9.80665f` to yield g
   (`Accelerometer.cpp:599,637-651`); Gyroscope applies **no** conversion (SDL3 and WP7 are both
   rad/s) (`Gyroscope.cpp:413-421`). Timestamps are wall-clock `DateTimeOffset::getUtcNowProperty()`
   at dispatch, never SDL's monotonic tick. VERIFIED
9. **There is no polling thread on desktop.** Delivery is an `SDL_EventFilter` installed with
   `SDL_AddEventWatch(&SdlSensorSubsystem::SensorEventWatch, nullptr)` —
   `modules/devices/include/Microsoft/Devices/Sensors/Detail/SdlSensorSubsystem.hpp:526,880`,
   with a `static_assert(is_same_v<decltype(&SensorEventWatch), SDL_EventFilter>)` (`:923-925`)
   that replaced a UB `reinterpret_cast`. **`CurrentValueChanged` therefore fires on whichever
   thread pushes `SDL_EVENT_SENSOR_UPDATE` into SDL's queue.** VERIFIED
10. **`Compass` and `Motion` are Android-only.** On every non-Android platform
    `getIsSupportedProperty()` returns a hardcoded `false` —
    `modules/devices/src/Sensors/Compass.cpp:24-27` ("SDL3 exposes no magnetometer/compass API on
    any supported platform") and `Motion.cpp:23-26` ("no fused-orientation/motion API"). `Start()`
    then throws `SensorFailedException("… not supported on this platform.")`. VERIFIED
11. On Android both are **real**, backed by NDK C (no JNI): `ASensorManager_*` /
    `ASensorEventQueue_*` / `ALooper_*`, linked via
    `target_link_libraries(cna_devices PUBLIC android log)`
    (`modules/devices/CMakeLists.txt:10-22`). VERIFIED
12. **One dedicated worker `std::thread` per bridge.** `AndroidMotionBackend` owns **six** bridges
    (`ROTATION_VECTOR`, `GAME_ROTATION_VECTOR`, `GRAVITY`, `LINEAR_ACCELERATION`, `GYROSCOPE`,
    `MAGNETIC_FIELD` — `AndroidMotionBackend.cpp:31-36`), i.e. **up to six worker threads for one
    `Motion` instance**. Tracked open as `ANDR2-011`. VERIFIED
13. `AndroidSensorBridge.cpp` compiles on non-Android but is inert (`IsAvailable()→false`,
    `Start()→false`, `Stop()` empty) — `:750-756,781,929-933,1110`. `AndroidCompassBackend`/
    `AndroidMotionBackend` are **fully** `#ifdef __ANDROID__` in both header and source and do not
    exist off Android. VERIFIED
14. **Compass heading math (exact).** Flat:
    `heading = fmod(atan2(2(xy−zw), 1−2(x²+z²))·180/π + 360, 360)` (`AndroidCompassMath.hpp:242-248`).
    Upright: `atan2(2(xz+yw), 2(yz−xw))` (`:301-307`). Mode selection: upright iff
    `|gZ| < cos45° && gY < −cos45°` with `gY = 2(yz+xw)`, `gZ = 1−2(x²+y²)`,
    `CosFortyFiveDegrees = 0.70710678118654752440` (`:349-360`). Invalid quaternion → **0.0° (north)**
    by policy (`:371-385`). VERIFIED
15. **`HeadingAccuracy` mapping is CNA-chosen**: `High→5.0`, `Medium→15.0`, `Low→20.0`,
    `Unreliable/NoContact→180.0` (`AndroidCompassMath.hpp:438-454`). `Low` is 20 (not 45) so it
    cannot contradict WP7's "±20° → Calibrate" rule, while `Calibrate` deliberately does *not*
    fire for `Low` (`:469-473`). VERIFIED
16. **`Compass.TrueHeading == MagneticHeading`, deliberately** — no declination source exists
    (`AndroidCompassBackend.cpp:203-218`). INTENTIONALLY-UNSUPPORTED, VERIFIED
17. **Motion attitude is a direct component passthrough** —
    `ConvertRotationVectorToXnaQuaternion(x,y,z,w) = NormalizeOrIdentity(Quaternion(x,y,z,w))`
    (`AndroidMotionMath.hpp:139-143`), justified by a written change-of-basis argument. Euler:
    `pitch = asin(clamp(−M32,−1,1))`, `yaw = atan2(M31,M33)`, `roll = atan2(M12,M22)`
    (`:199-209`). VERIFIED
18. **The landscape axis remap is a `CNAEXT` deviation from WP7, ON by default**, opt-out via a
    process-wide relaxed atomic: `Rotation270 → {−x, y, z}`, `Rotation90` (default)
    `→ {x, −y, z}` (`AndroidSensorOrientation.hpp:68-110`). Applied to Accelerometer, Gyroscope
    and Motion's three vector fields — **not** to `Attitude`, because the corresponding remap is
    a *reflection* (det = −1) and no quaternion can express it (`AndroidMotionMath.hpp:90-108`).
    VERIFIED
19. Motion fusion is **latest-value with a 500 ms window** (`AndroidMotionBackend.cpp:28,357-379`);
    frames outside the window are dropped. Timestamp-aligned fusion is deferred (`MOT2-003`,
    OPEN). PARTIAL, VERIFIED
20. **`VibrateController` is real rumble, not a stub.** `SDL_PlayHapticRumble`
    (`modules/devices/src/Detail/SdlHapticVibrateBackend.cpp:426`) for the simple path;
    `SDL_CreateHapticEffect` + `SDL_RunHapticEffect` with `SDL_HAPTIC_LEFTRIGHT` and `Uint16`
    magnitudes `= clamped × 65535.0f` for `StartLeftRight` (`:580-620`). Duration capped at **5 s**
    (`VibrateController.cpp:15-26`); NaN is canonicalized to 0 rather than clamped (`:46-53`).
    VERIFIED
21. **Gamepads are deliberately excluded from `VibrateController`'s device selection** (correlated
    by instance ID via `SDL_OpenHapticFromJoystick`) so it never fights `GamePad::SetVibration()` —
    `SdlHapticVibrateBackend.cpp:60-95,263-275`. VERIFIED
22. **One process-wide mutex serializes `SDL_INIT_SENSOR` *and* `SDL_INIT_HAPTIC`** —
    `Microsoft::Devices::Detail::GetGlobalSdlSubsystemMutex()`
    (`modules/devices/include/Microsoft/Devices/Detail/SdlSubsystemMutex.hpp:93-97`). Lock order is
    per-class `mutex_` → global, enforced by making
    `EnsureSubsystemInitialized()`/`ProbeIsSupported()` take an unused
    `const std::lock_guard<std::mutex>&` parameter as a compile-time proof of holding it
    (`SdlSensorSubsystem.hpp:279-294`). VERIFIED
23. **`DevicesShutdownCoordinator` orders exactly one thing**: the app must call `Shutdown()`
    before its own `SDL_Quit()`, after which the haptic backend's destructor skips
    `SDL_CloseHaptic`/`SDL_QuitSubSystem` — otherwise a function-local-static `VibrateController`
    destructs *after* `SDL_Quit()` freed the device struct (heap-UAF). Header
    `DevicesShutdownCoordinator.hpp:86-117`; out-of-process ASan harness
    `tools/devices/shutdown_ordering_harness.cpp`. VERIFIED (code) / STRONG (the UAF, per its own
    caveat)
24. **`SDL_INIT_CAMERA` is never initialized anywhere in the repository.** Consequence: unless the
    host app inits it itself, `CNA::Devices::Camera` lands in `CameraState::NotSupported` and
    `getAvailableCamerasProperty()` returns empty. VERIFIED
25. Camera is **RGBA32-only by design** — the requested spec forces `SDL_PIXELFORMAT_RGBA32`, and
    the device is closed and reported `NotSupported` if SDL negotiated anything else
    (`modules/devices-ext/src/Detail/SdlCameraBackend.cpp:25,65-75`). Frames reach a `Texture2D`
    via `SetDataRGBA` (`Camera.cpp:94`). `CameraState::Lost` and `Closed` are **unreachable** in
    the real backend. VERIFIED
26. Every other `CNA::Devices` class is a thin, real SDL3 wrapper:
    `Clipboard`→`SDL_{Get,Set,Has}ClipboardText`; `DisplayInfo`→`SDL_GetWindowDisplayScale`/
    `SDL_GetWindowSafeArea`; `Locale`→`SDL_GetPreferredLocales`;
    `MessageBox`→`SDL_ShowMessageBox`/`SDL_ShowSimpleMessageBox`; `FileDialog`→
    `SDL_ShowOpen/Save/FolderDialog`; `SystemTray`→`SDL_CreateTray`+`SDL_InsertTrayEntryAt`+
    `SDL_SetTrayEntryCallback`; `PowerInfo`→`SDL_GetPowerInfo`; `SystemInfo`→
    `SDL_GetNumLogicalCPUCores`/`SDL_GetSystemRAM`; `UrlLauncher`→`SDL_OpenURL`. **Zero
    `throw`/`TODO`/`NotImplemented` tokens exist in the whole module.** VERIFIED
27. Real gaps in that layer: `MessageBox::getIsSupportedProperty()` is hardcoded `true`; dialogs
    are never parented (`data.window = nullptr`) and **never set a default or escape button**
    (`button.flags = 0`); empty `buttonLabels` is unvalidated despite the header contract
    (`modules/devices-ext/src/Detail/SdlMessageBoxBackend.cpp:31,45,53,61`;
    `src/MessageBox.cpp:43`). `FileDialog`/`SystemTray` platform checks are **advisory only** —
    the `Show*`/ctor paths forward unconditionally. `PowerInfo` calls `SDL_GetPowerInfo` **three
    separate times, once per property** (`PowerInfo.cpp:30,36,43`), so state/percent/seconds are
    three independent snapshots. `SystemTray`'s icon surface is always `nullptr`. `UrlLauncher`
    does no validation. VERIFIED
28. **Live defect, still unfixed:** `Dispose(bool)` is `public` in all four sensor classes while
    `SensorBase` declares it `protected` (`Accelerometer.hpp:224`, `Gyroscope.hpp:202`,
    `Compass.hpp:199`, `Motion.hpp:197`). An external `sensor.Dispose(false)` takes the
    `!disposing` branch and sets `disposed_ = true` **with no cleanup at all** — no `Stop()`, no
    instance-count decrement, no SDL release, no owner-nulling. Tracked `REMED-DEVICES-002`, NOT
    STARTED. VERIFIED
29. **The Android demo is a stale duplicate and it is the copy the APK builds.**
    `modules/devices/examples/demo_devices/android/…/jni/src/DevicesDemo.cpp` (447 lines) vs the
    desktop `src/DevicesDemo.cpp` (523 lines); the Android copy is missing all of Task DEMO-001
    (rate control, `IsDataValid`, full reading dump). VERIFIED
30. **No hardware QA report has ever been filed** — `docs/hardware-qa-reports/` (the directory
    `docs/devices_sensor_hardware_qa_template.md:15` instructs testers to populate) does not
    exist. Every Android sensor claim rests on source reading and host unit tests. The code says
    so itself (`AndroidCompassMath.hpp:220-226`: *"Never checked against real hardware… Treat the
    exact sign/zero-point convention as unverified"*). VERIFIED
31. **The `CNA::Input` ↔ `CNA::Devices` duplication is real, deliberate-by-accident, and tracked.**
    `Clipboard` and `Power`/`PowerInfo` are true independent duplicates with structurally
    identical but type-incompatible enums; `CNA::Input::Sensors` is a *different* API (poll-based,
    stateless open→read→close, raw `Vector3`) not a duplicate of `Microsoft::Devices::Sensors`;
    `CNA::Input::InputDevices` has no counterpart. Git archaeology shows all seven originating
    commits landed 2026-07-06 within ~100 minutes on two parallel, mutually unaware workstreams,
    with split precedence. They cannot collide (disjoint namespaces, no TU includes both, no
    `using namespace`). Tracked `REMED-DEVICES-003`, Sev MEDIUM, P3, NOT STARTED. VERIFIED
32. **Because devices-ext is OFF by default, `CNA::Input::Clipboard` is the *only* clipboard API
    that exists in a default build**, and `CNA::Input::Power` the only host-battery API. VERIFIED

## STATUS TABLE — DEVICES / SENSORS

| API family | Status | Platform | Evidence | Test |
|---|---|---|---|---|
| `SensorBase<T>` | IMPLEMENTED | all | `SensorBase.hpp:36-790` | `SensorBaseTests.cpp` (26) |
| `Accelerometer` (+`ReadingChanged`) | IMPLEMENTED, real SDL3 | Desktop/Android/iOS; **Web excluded** | `Accelerometer.cpp:40-73,599,681-713` | `AccelerometerTests.cpp` (50) |
| `Gyroscope` | IMPLEMENTED, rad/s passthrough | as above | `Gyroscope.cpp:37-40,445-478` | `GyroscopeTests.cpp` (41) |
| `Compass` | **PLATFORM-GATED(Android)**; INTENTIONALLY-UNSUPPORTED elsewhere | Android only | `Compass.cpp:17-27,183-188` | `CompassTests.cpp` (40, fake backend) |
| `Compass.TrueHeading` | INTENTIONALLY-UNSUPPORTED (= magnetic) | Android | `AndroidCompassBackend.cpp:203-218` | `CompassReadingTests.cpp` |
| `Motion` | **PLATFORM-GATED(Android)** | Android only | `Motion.cpp:17-26,145-149` | `MotionTests.cpp` (45) |
| Motion fusion | PARTIAL (latest-value, 500 ms) | Android | `AndroidMotionBackend.cpp:28,328-410` | `AndroidMotionMathTests.cpp` (16) |
| Landscape axis remap | EMULATED (CNAEXT deviation, default ON) | Android | `AndroidSensorOrientation.hpp:68-110` | `AndroidSensorOrientationTests.cpp` (12) |
| `VibrateController` | IMPLEMENTED (real rumble) | all (no-op w/o device) | `SdlHapticVibrateBackend.cpp:426,586,620` | `VibrateControllerTests.cpp` (63) |
| `StartLeftRight` dual motor | IMPLEMENTED desktop; **EMULATED** Android (SDL blends 0.6/0.4) | all | `VibrateController.hpp:153-163` | ″ |
| `CNA::Devices::Camera` | PARTIAL + **PLATFORM-GATED(`CNA_DEVICES`)**; `SDL_INIT_CAMERA` never inited | opt-in | `SdlCameraBackend.cpp:25,35-172` | `CameraTests.cpp` (8, real backend never built) |
| `CNA::Devices::{Clipboard,DisplayInfo,Locale,SystemInfo,UrlLauncher}` | IMPLEMENTED + PLATFORM-GATED | opt-in | `modules/devices-ext/src/*` | 3–5 each |
| `CNA::Devices::MessageBox` | IMPLEMENTED w/ gaps + GATED | opt-in | `SdlMessageBoxBackend.cpp:31,45,53` | `MessageBoxTests.cpp` (5, fake) |
| `CNA::Devices::FileDialog` | IMPLEMENTED + GATED; advisory platform check, cancel≡error | opt-in | `SdlFileDialogBackend.cpp:96-141` | `FileDialogTests.cpp` (7, fake) |
| `CNA::Devices::SystemTray` | IMPLEMENTED + GATED; flat menu, no icon | opt-in | `SdlTrayBackend.cpp:36-134` | `SystemTrayTests.cpp` (8, fake) |
| `CNA::Devices::PowerInfo` | IMPLEMENTED + GATED; 3 inconsistent snapshots | opt-in | `PowerInfo.cpp:30,36,43` | `PowerInfoTests.cpp` (4) |

## CONTRADICTIONS — DEVICES

1. **`docs/devices-native-backend-design.md:38-44`**: *"`Compass` and `Motion` … are permanent,
   honest `SensorState::NotSupported` stubs."* **False on Android** (`Compass.cpp:71-73`,
   `Motion.cpp:72-74`), and the same file self-contradicts at `:154` ("Android backend path —
   IMPLEMENTED").
2. **`docs/devices-native-backend-design.md:181`** documents `LOW → 45°`; code returns **20°**
   (`AndroidCompassMath.hpp:447-448`, Task COMPASS-006).
3. **`docs/devices-native-backend-design.md:285`** says "five separate `AndroidSensorBridge`
   instances"; there are **six** (`AndroidMotionBackend.cpp:31-36`).
4. **`docs/devices-native-backend-design.md:175` / `docs/devices-api-coverage.md:285`** name
   `ConvertRotationVectorToMagneticHeadingDegrees()` as the azimuth entry point; the only
   production call is `…WithTiltMode()` (`AndroidCompassBackend.cpp:99-100`).
5. **`docs/devices-event-contract.md:204-225`**: Android callback exceptions are *"a bare
   `catch (...) { }` with no logging and no counter."* Now fully instrumented through
   `NativeDiagnosticSink::Record()` (`AndroidSensorBridge.cpp:667-692`); `DEVPERF-005` is CLOSED.
6. **`docs/devices-event-contract.md:51`** and `AndroidSensorBridge.hpp:263`: *"joined by
   `Stop()`."* A reentrant self-stop **detaches** (`:1014`); a timed-out external stop detaches
   and permanently sets `abandoned_` (`:1071-1072`).
7. **`docs/cna-devices-camera-design.md:3`**: *"Status: design only, no implementation."* Camera is
   implemented (`DEVICES-CNA-012`, CLOSED 2026-07-07).
8. **`noxna_devices.md:745-758`**: Camera "not yet started", `MOTION-012` "open". Both closed.
9. **`remediation/MASTER_REMEDIATION_PLAN.md:522-527`**: `REMED-DEVICES-001` "NOT STARTED". Fixed
   2026-07-20 (`b12251ccc`) with two 2000-iteration TSan regression tests.
10. **`docs/devices-build.md:130-138`**: the documented "Devices-only" gtest filter is pinned to
    *"exactly the 283 current cases… same 21 suites."* Those suites now hold ~448 cases, the
    module holds 462, and **three suites created since (`NativeDiagnosticTests`,
    `DevicesShutdownCoordinatorTests`, `DevicesShutdownOrderingTests`) are absent from the filter
    entirely** — the documented command silently skips them.
11. **`docs/devices-api-coverage.md:269-291`** lists 10 `Detail::` internals; at least eight more
    exist.
12. **`plan_cna_devices.md:23-57`** cites `include/CNA/Devices/`, `src/CNA/Devices/`,
    `CMakeLists.txt:21` — all moved/renumbered by the `modules/` split;
    `modules/CMakeLists.txt:186-193` now *hard-fails configure* if a root `src/` reappears.
13. **`noxna_devices.md` / `plan_cna_devices.md` / `MASTER_REMEDIATION_PLAN.md`** all still say
    `NOXNA`; the macro is `CNAEXT` and `NOXNA` has zero hits in `modules/`.
14. **`modules/devices/examples/demo_devices/src/DevicesDemo.cpp:88-90`** comment: *"Compass/Motion
    always throw."* False on Android — and the same file's `:293-296` comment already acknowledges
    Android, so the file disagrees with itself.

---

# 3. AUDIO

## FACTS

1. **CNA audio is SDL3_mixer, not FAudio and not a hand-written mixer.**
   `modules/audio/CMakeLists.txt` links `SDL3::SDL3 SDL3_mixer::SDL3_mixer`. The object model is
   `MIX_Mixer` / `MIX_Audio` / `MIX_Track`. VERIFIED
2. **The mixer device spec is a fixed reference format: `SDL_AUDIO_S16`, 2 channels, 44100 Hz** —
   requested unconditionally in production, *never* native-device-matched —
   `modules/audio/src/Internal/AudioMixer.cpp:92-97`. The actually-negotiated format is queried
   via `MIX_GetMixerFormat` and logged once to `stderr` (`:113-126`); a test-only override exists
   (`SetMixerSpecOverrideForTests`, `:52-57`). VERIFIED
3. `GetMixer()` holds **one `std::mutex` for its entire body** (create-or-return) and
   `DestroyMixer()` shares it (`AudioMixer.cpp:24,67,133`). A failed `MIX_CreateMixerDevice` calls
   `MIX_Quit()` to balance the refcount before throwing (`:98-105`). VERIFIED
4. **A permanently-held extra `SDL_INIT_AUDIO` reference is pinned on first use**
   (`g_audioSubsystemPinned`, `:73-76`) specifically so `MIX_DestroyMixer`'s internal
   `SDL_QuitSubSystem(SDL_INIT_AUDIO)` can never zero the global refcount — confirmed necessary by
   a real ASan-symbolized SEGV inside `SDL_UnbindAudioStream_REAL` when
   `DynamicSoundEffectInstance` later destroyed its own `SDL_AudioStream`. VERIFIED
5. **`DestroyMixer()` has no caller anywhere in the codebase** (`AudioMixer.hpp:46-54`); the mixer
   and `MIX_Init` refcount are reclaimed only by the OS at process exit. A `GetMixerGeneration()`
   counter exists so instances holding a `MIX_Track` freed by a hypothetical `DestroyMixer()`
   detect invalidation instead of dereferencing (`:73-79`, `:142`). VERIFIED
6. **`SoundEffect(assetName)` calls `MIX_LoadAudio(mixer, path, /*predecode*/true)`** and
   `SoundEffect::FromStream` calls
   `MIX_LoadAudio_IO(mixer, SDL_IOFromConstMem(...), true, true)` —
   `modules/audio/src/Xna/SoundEffect.cpp:272,746`. **CNA therefore decodes whatever its vendored
   SDL3_mixer decodes, far beyond XNA's WAV-only `SoundEffect`.** VERIFIED
7. **The vendored SDL3_mixer feature set is explicitly narrowed by CNA's own build args**
   (`cmake/ThirdPartySDL.cmake:149-160`): OFF = `GME`, `MOD_XMP`, `MP3_MPG123`,
   `MIDI_FLUIDSYNTH`, `OPUS`, `VORBIS_VORBISFILE`, `VORBIS_TREMOR`, `WAVPACK`, `FLAC_LIBFLAC`.
   Remaining ON by upstream default: **AIFF, WAVE, VOC, AU, FLAC (drflac), MP3 (dr_mp3), Ogg
   Vorbis (stb_vorbis), MIDI (timidity)**. MOD is effectively unavailable (XMP was its only
   backend). **Opus, WavPack and AAC/WMA are not decodable.** VERIFIED
8. **Raw-buffer `SoundEffect` ctors are S16-PCM-only**, via `MIX_LoadRawAudio` with
   `spec.format = SDL_AUDIO_S16` (`SoundEffect.cpp:355-370`). `loopStart`/`loopLength` are
   deliberately **not** validated, matching FNA's unsigned wrap (`:312-314`). VERIFIED
9. Static globals with XNA defaults: `MasterVolume_ = 1.0f`, `DistanceScale_ = 1.0f`,
   `DopplerScale_ = 1.0f`, **`SpeedOfSound_ = 343.5f`** — `SoundEffect.cpp:62-65`.
   `DistanceScale` setter throws on `<= 0`; `DopplerScale` on `< 0`; `SpeedOfSound` is
   unvalidated. VERIFIED
10. **`MasterVolume` is applied once globally via `MIX_SetMixerGain`, never baked into per-track
    gain** (CP-16, `SoundEffect.cpp:546-548`). VERIFIED
11. **Pitch is `2^pitch`** —
    `ComputePitchRatio(pitch) { return std::pow(2.0f, pitch); }`
    (`modules/audio/src/Xna/SoundEffectInstance.cpp:83-86`), fed to
    `MIX_SetTrackFrequencyRatio` with a `0.01f` floor (`:120-121`). The in-source note records
    that the previous linear formula
    `(pitch<0)?(1+pitch*0.5f):(1+pitch)` agreed only at −1/0/+1 and was up to ~1 semitone wrong
    elsewhere, invisible because tests only exercised `Pitch = 0`. VERIFIED
12. **Pan is a crossfeed matrix computed in a per-track "cooked callback", not
    `MIX_SetTrackStereo`.** `MIX_SetTrackStereo` is pinned to unity `{1,1}` and 100% of the
    stereo image comes from `ComputePanCrossfeedMatrix`
    (`SoundEffectInstance.cpp:109-110,254-263`), which matches FNA's `SetPanMatrixCoefficients`
    for the 2→2 branch: hard panning does **not** silence the opposite speaker. `pan` is written
    under `MIX_LockMixer`/`MIX_UnlockMixer` (`:114-118`). VERIFIED
13. **`Apply3D` attenuation is FAudio's computed inverse law, not `1/(1+d)`**:
    `normalizedDistance = distance / DistanceScale`;
    `atten = (normalizedDistance >= 1) ? clamp(1/normalizedDistance, 0, 1) : 1` — i.e. **full
    volume within `DistanceScale`**, inverse falloff only beyond it
    (`SoundEffectInstance.cpp:1029-1035`). VERIFIED
14. **Pan in `Apply3D` projects onto the listener's real right axis**
    `Cross(Forward, Up)`, not world X (`:1041-1052`), which reduces to `(1,0,0)` for the default
    orientation. VERIFIED
15. **Doppler matches F3DAudio's `CalculateDoppler` exactly**, including the
    `min(velComponent, speedOfSound/dopplerScaler)` clamps, the NaN→1.0 guard, and the
    **`clamp(factor, 0.5f, 4.0f)`** "2 octaves up / 1 octave down" limit (`:132-166`). The final
    ratio is `2^pitch × dopplerFactor × globalDopplerScale`. VERIFIED
16. **`Apply3D` state persists.** `attenuation_`, `dopplerFactor_`, `spatialPan_` are stored and
    recombined by `INTERNAL_applyComposedTrackProperties()` on every later `Play()`/volume/pitch
    call (AUDIO-001) — previously one-shot and silently dropped if no live track existed
    (`:1075-1085`). VERIFIED
17. **Aux-send / reverb bus is a documented permanent no-op** — SDL3_mixer has no such concept
    (`SoundEffectInstance.cpp:687`). INTENTIONALLY-UNSUPPORTED, VERIFIED
18. **`SoundEffect::Play()` creates a fresh `MIX_Track` per call** with its own heap
    `FireAndForgetPanState` and cooked callback (`SoundEffect.cpp:533-568`); a deferred
    `PendingPanStateCleanup::Drain()` frees finished ones (`:525`) because freeing inside the stop
    callback was an ASan-caught heap-use-after-free. `Play(volume, pitch, pan)` throws
    `ArgumentOutOfRangeException` for `|pan| > 1` and **clamps** pitch (`:515-519`). VERIFIED
19. **There is no fire-and-forget instance limit.** `InstancePlayLimitException` exists as a
    header and is exercised only by `AudioExceptionsTests.cpp` — it is **never thrown anywhere in
    the implementation** (repo-wide grep). VERIFIED
20. `NoAudioHardwareException` *is* real: thrown when `GetMixer()` fails, at
    `SoundEffect.cpp:246` and `DynamicSoundEffectInstance.cpp:42`. VERIFIED
21. **`DynamicSoundEffectInstance` owns its own `SDL_AudioStream`** (not mixer/track-owned), bound
    with `MIX_SetTrackAudioStream`, played with
    `MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN = false` and `MIX_PROP_PLAY_LOOPS_NUMBER = -1`
    (`DynamicSoundEffectInstance.cpp:199-227`). A non-immediate `Stop()` throws
    `InvalidOperationException`, matching FNA (`:267-271`). VERIFIED
22. **`FrameworkDispatcher::Update()` snapshots the stream list under `StreamsMutex`, then runs
    each `Update()` with the lock released** — because `BufferNeeded` may synchronously dispose
    the instance, which re-locks the same non-recursive mutex (P11-DISPATCH-001, a real
    self-deadlock). It then pumps `Microphone::CheckAllBuffers()`, `MediaPlayer::Update()`, the
    two deferred media event flags, and `TouchPanel::Update()`. VERIFIED
23. **XACT is a real, hand-written parser**, not a stub. `.xgs`: magic `0x46534758` ("XGSF"),
    `contentVersion` 46 expected, else a stderr warning
    (`modules/audio/src/Internal/XactParser.cpp:357-377`). `.xwb`: magic `0x444E4257` ("WBND"),
    version > 46 warns (`:507-513`). `.xsb` sound/cue flags: `COMPLEX=0x01`, `HAS_RPC=0x02`,
    `HAS_TRACK_RPC=0x04`, `RPC_MASK=0x0E`, `HAS_DSP=0x10`, `CUE_SINGLE_SOUND=0x04` (`:137-142`).
    Every read is bounds-checked and throws `std::runtime_error("XACT parse: read past end")`.
    VERIFIED
24. `WaveBank` supports both **in-memory and streaming** construction
    (`ParseXwbStreamingHeader`, `modules/audio/src/Xna/WaveBank.cpp:151-165`). MS-ADPCM entries
    are wrapped into synthetic WAVs using the 7 standard coefficient pairs
    `{256,0, 512,−256, 0,0, 192,64, 240,0, 460,−208, 392,−232}`
    (`modules/audio/src/Internal/WavWrapper.cpp:88-101`), because SDL3's MS-ADPCM decoder
    requires an explicit coefficient table. `AppendSmplChunkIfLooped` writes a real `smpl` chunk
    with `PlayCount = 0` (infinite) (`:103-119`). VERIFIED
25. `AudioEngine` is real: `.xgs` settings parse, `GetCategory`/`GetGlobalVariable`/
    `SetGlobalVariable` (with FACT's READONLY silent-no-op semantics preserved),
    `Update()` → `DoWork` equivalent. `RendererDetails` reports exactly one entry,
    `RendererDetail("SDL3_mixer","SDL3_mixer")` (`AudioEngine.cpp:102`).
    `AudioCategory` Pause/Resume/SetVolume/Stop all forward to real engine internals
    (`AudioCategory.cpp:17-38`). VERIFIED
26. **Known XACT stub:** the instance-limit `REPLACE_QUIETEST` branch is unfinished — CNA
    reproduces FNA/FACT's own behaviour, treating `QUEUE` and `REPLACE_OLDEST` identically
    (`AudioEngine.cpp:462-463`). PARTIAL, VERIFIED
27. **`Microphone` is real capture**, not a stub: `SDL_GetAudioRecordingDevices` enumeration led by
    a synthetic "Default Device" entry (matching FNA), `SDL_OpenAudioDeviceStream(handle,
    {S16,…})`, `SDL_ResumeAudioStreamDevice`, `SDL_GetAudioStreamData`,
    `SDL_GetAudioStreamAvailable` — `modules/audio/src/Xna/Microphone.cpp:41-248`. VERIFIED
28. **`OfflineAudioRenderer.hpp` is the project's most transferable audio idea**: it renders real
    SDL3_mixer decode/resample/mix output to memory via `MIX_CreateMixer()` + `MIX_Generate()` —
    **no device, no `SDL_AUDIODRIVER`, no wall clock** — so "what reaches the speakers" is
    assertable deterministically on any machine
    (`modules/audio/tests/Microsoft/Xna/Framework/Audio/OfflineAudioRenderer.hpp:1-50`). VERIFIED

## STATUS TABLE — AUDIO

| API family | Status | Evidence | Test |
|---|---|---|---|
| `AudioMixer` (SDL3_mixer, fixed S16/2/44100) | IMPLEMENTED | `AudioMixer.cpp:92-97` | `AudioMixerTests.cpp` |
| `SoundEffect` file/stream load (8 container formats) | IMPLEMENTED | `SoundEffect.cpp:272,746`; `ThirdPartySDL.cmake:149-160` | `SoundEffectTests.cpp` |
| `SoundEffect` raw-buffer ctors | IMPLEMENTED, **S16-PCM only** | `SoundEffect.cpp:355-370` | ″ |
| `SoundEffect::Play()` fire-and-forget | IMPLEMENTED, **no instance cap** | `SoundEffect.cpp:500-568` | ″ |
| `InstancePlayLimitException` | **DECLARED BUT NEVER THROWN** | header + `AudioExceptionsTests.cpp` only | — |
| `SoundEffectInstance` vol/pitch/pan/loop/state | IMPLEMENTED; pitch = `2^p` | `SoundEffectInstance.cpp:83-121` | `SoundEffectInstanceTests.cpp` |
| Pan crossfeed matrix | IMPLEMENTED (FNA-exact 2→2) | `:254-263` | ″ |
| `Apply3D` attenuation + pan + doppler | IMPLEMENTED (F3DAudio-exact formulas) | `:1029-1085`, `:132-166` | `AudioListenerTests.cpp`, `AudioEmitterTests.cpp` |
| Aux-send / reverb | INTENTIONALLY-UNSUPPORTED | `:687` | — |
| `DynamicSoundEffectInstance` | IMPLEMENTED (own `SDL_AudioStream`) | `DynamicSoundEffectInstance.cpp:158-283` | `DynamicSoundEffectInstanceTests.cpp` |
| `FrameworkDispatcher::Update` | IMPLEMENTED (deadlock-safe snapshot) | `FrameworkDispatcher.cpp` | `FrameworkDispatcherTests.cpp` |
| XACT `.xgs`/`.xsb`/`.xwb` parse | IMPLEMENTED (v46) | `XactParser.cpp:357,507` | `XactParserTests.cpp`, `XactParserFuzzTests.cpp` |
| `AudioEngine`/`SoundBank`/`WaveBank`/`Cue`/`AudioCategory` | IMPLEMENTED | `AudioEngine.cpp`, `Cue.cpp` (1398 lines) | `AudioEngineTests.cpp`, `CueTests.cpp`, `SoundBankTests.cpp`, `WaveBankTests.cpp` |
| XACT `REPLACE_QUIETEST` | PARTIAL (matches FACT's own unfinished stub) | `AudioEngine.cpp:462-463` | — |
| `Microphone` | IMPLEMENTED (real capture) | `Microphone.cpp:41-248` | `MicrophoneTests.cpp` |
| `DestroyMixer()` | IMPLEMENTED but **unreachable** (no caller) | `AudioMixer.hpp:46-54` | — |

## CONTRADICTIONS — AUDIO

1. **`plan_audio.md`'s three "User-reported release blockers" are still `- [ ]` unchecked**
   (high-pitch effects, missing/failing loads, distorted audio). The file states 438 tasks (224
   P0). Any book claim that audio is "closed" must be scoped to *Phases*, not to these blockers.
2. **`docs/cna_audio_deep_audit_2026-07-17.md` (executive conclusion, finding 2)**: *"CNA's XNB
   `SoundEffectReader` explicitly rejects every format except mono/stereo 16-bit PCM."* **Now
   stale.** `modules/content/src/Xnb/SoundEffectContentTypeReader.cpp:280-307` accepts **PCM
   16-bit** (direct fast path), **PCM 8-bit, IEEE float 32-bit, MS-ADPCM 4-bit and IMA-ADPCM
   4-bit** (wrapped into a synthetic WAV and handed to SDL3's decoder). Only **XMA2 (0x0166)** is
   rejected, with an explicit diagnostic naming tag/bits/channels/rate. Channel count is still
   restricted to mono/stereo (`:267-271`).
3. **Same doc, same finding**: the MS-ADPCM path additionally *synthesizes* the coefficient table
   because XNA's own pipeline writes `cbSize = 0` for MS-ADPCM — a real, empirically-confirmed
   finding (`SoundEffectContentTypeReader.cpp:44-67`) that post-dates the audit.
4. **`NEXTaudio.md`** is branch-scoped to `feature/audio`, declares *"the
   `Microsoft::Xna::Framework::Media` namespace is explicitly out of scope,"* and its phase
   narrative stops at Phase 11. Treat as history, not current state.
5. **`plan_audio.md` progress note** correctly rules out SDL3_mixer's resampler as the pitch-bug
   cause (four offline-render tests) — a genuinely useful, still-valid result the book should
   keep.

---

# 4. MEDIA

## FACTS

1. **FFmpeg gating happens in two places that do not agree.** CMake:
   `if(MINGW OR WIN32 OR EMSCRIPTEN OR ANDROID) set(CNA_FFMPEG_AVAILABLE OFF)` —
   `modules/CMakeLists.txt:15-19`; otherwise `libavcodec`, `libavformat`, `libavutil`,
   `libswresample` are all `REQUIRED` via `pkg_check_modules(... IMPORTED_TARGET)`. VERIFIED
2. When OFF, three TUs are **excluded from the build entirely**:
   `src/Internal/VideoDecoder.cpp`, `src/Xna/Video/VideoPlayer.cpp`, `src/Xna/Video/Video.cpp` —
   `modules/media/CMakeLists.txt:3-9`. Video is therefore *link-absent*, not a runtime throw.
   VERIFIED
3. **Real defect:** `modules/content/src/Xna/ContentManager.cpp:47` guards the `Video.hpp` include
   with `#if !defined(__EMSCRIPTEN__) && !defined(__ANDROID__) && !defined(__MINGW32__) &&
   !defined(__MINGW32__)` — **`__MINGW32__` is duplicated and native MSVC/`_WIN32` is not covered
   at all**, while CMake's condition is `MINGW OR WIN32 OR …`. Its own comment states the CMake
   condition incorrectly ("MINGW OR EMSCRIPTEN OR ANDROID"). On a native MSVC Windows build (which
   this project has — D3D11/D3D12 CI) the include survives while `Video.cpp` is excluded → link
   error. VERIFIED
4. **`SongTypeReader` advertises formats SDL3_mixer cannot decode.**
   `LooseFileContentTypeReader<Media::Song>::Extensions()` returns
   `{".mp3", ".ogg", ".wav", ".flac", ".opus", ".aac", ".wma"}` —
   `modules/content/src/Xna/ContentManager.cpp:2996-3001`. Per Audio fact 7, **`.opus`, `.aac` and
   `.wma` have no decoder in this build**. VERIFIED
5. `PlaylistParser` resolves each entry through
   `CNA::Internal::ResolveContainedPath(baseDir, trimmed)` —
   `modules/media/src/Internal/PlaylistParser.cpp:61` — so a playlist cannot reference a file
   outside its own directory tree. VERIFIED
6. **Media and Audio form a declared, deliberate static-archive cycle**: `cna_audio PRIVATE
   cna_media` and `cna_media PUBLIC cna_audio`, documented as a genuine XNA-semantic cycle
   (`FrameworkDispatcher::Update()` pumps `MediaPlayer`, while `MediaPlayer` plays through the
   audio mixer) and left in place so CMake repeats the archives —
   `modules/audio/CMakeLists.txt:6-12`, `modules/media/CMakeLists.txt:11`. VERIFIED
7. `FrameworkDispatcher::Update()` is the single pump for `MediaPlayer::Update()`,
   `MediaPlayer::OnActiveSongChanged()` and `OnMediaStateChanged()`, gated by two static bool
   flags — `modules/audio/src/Xna/FrameworkDispatcher.cpp`. VERIFIED
8. The `Media` namespace is genuinely broad: 24 public types plus 12 internal helpers, including
   `AudioDurationProbe`, `AudioTagParser`, `MediaLibraryIndex`, `MediaLibraryPaths`,
   `PictureLibraryIndex`, `PlaylistParser`, `SavedPictureStore`, `ThumbnailGenerator`,
   `VideoDecoder`, `VisualizationCapture`, `VisualizationFFT` (full listing under
   `modules/media/include/CNA/Internal/Media/`). 285 test cases across 29 files. VERIFIED
9. `Album::GetAlbumArt` / `Picture::GetImage` return `System::IO::Stream` (the headers explicitly
   record that a prior `void*` placeholder was a mistake, corrected to the FNA/XNA type) —
   `modules/media/include/Microsoft/Xna/Framework/Media/Album.hpp:78`, `Picture.hpp:70`.
   VERIFIED
10. `Song.hpp:99` records that DRM-protected containers are an *intentional* scope limit ("the
    library scan only accepts plain, unencrypted container…"), not an unimplemented stub.
    INTENTIONALLY-UNSUPPORTED, VERIFIED
11. `VideoDecoder`'s multi-track selection returns `false` for an already-active or out-of-range
    track index — "a true no-op" — `modules/media/src/Internal/VideoDecoder.cpp:357-407`.
    VERIFIED
12. `VideoPlayer.cpp:332` records a fixed defect where a no-op state change still tore down and
    reopened the SDL stream, discarding buffered audio. VERIFIED

> **Scope note.** A dedicated media sub-audit was run in parallel; the facts above are the ones I
> re-verified against source myself. Deeper line-level detail on `AudioTagParser` (ID3v2.3/2.4
> text frames, encoding bytes, `POPM`, Vorbis `RATING`, FLAC `PICTURE`), `MediaLibraryPaths` OS-
> directory resolution, the radix-2 `VisualizationFFT`, and `VideoDecoder`'s
> `sws_scale`/`swresample` wiring exists in the source and is largely reflected accurately in the
> current Chapter 28 (see BOOK IMPACT).

## STATUS TABLE — MEDIA

| API family | Status | Evidence |
|---|---|---|
| `Song` + metadata/duration probing | IMPLEMENTED | `src/Xna/Song.cpp`, `src/Internal/AudioTagParser.cpp`, `AudioDurationProbe.cpp` |
| `MediaPlayer` / `MediaQueue` | IMPLEMENTED, pumped by `FrameworkDispatcher::Update()` | `FrameworkDispatcher.cpp`; `src/Xna/MediaPlayer.cpp` |
| `MediaLibrary` + Album/Artist/Genre/Playlist/Picture collections | IMPLEMENTED | `src/Internal/MediaLibraryIndex.cpp`, `MediaLibraryPaths.cpp`, `PictureLibraryIndex.cpp` |
| `SavePicture` / `SavedPictureStore` / `ThumbnailGenerator` | IMPLEMENTED | `src/Internal/SavedPictureStore.cpp`, `ThumbnailGenerator.cpp` |
| `PlaylistParser` (path-contained) | IMPLEMENTED | `PlaylistParser.cpp:61` |
| `VisualizationData` + FFT | IMPLEMENTED (from-scratch radix-2) | `src/Internal/VisualizationFFT.cpp`, `VisualizationCapture.cpp` |
| `Video` / `VideoPlayer` / `VideoDecoder` | IMPLEMENTED **where FFmpeg is available**; **link-absent** on MinGW/Win32/Emscripten/Android | `modules/media/CMakeLists.txt:3-9` |
| Windows/Android/Web video | **PLATFORM-GATED (excluded, not stubbed)** | `modules/CMakeLists.txt:15-19` |
| DRM-protected media | INTENTIONALLY-UNSUPPORTED | `Song.hpp:99` |
| MSVC native-Windows `Video.hpp` include guard | **DEFECT** — omits `_WIN32`, duplicates `__MINGW32__` | `ContentManager.cpp:47` |
| `.opus`/`.aac`/`.wma` advertised as Song extensions | **DEFECT** — no decoder in this SDL3_mixer build | `ContentManager.cpp:3001` vs `ThirdPartySDL.cmake:157-160` |

## CONTRADICTIONS — MEDIA

1. **`ContentManager.cpp:44-46`'s own comment** misstates the CMake condition it claims to mirror
   ("MINGW OR EMSCRIPTEN OR ANDROID"); the real condition includes `WIN32`.
2. **`plan_media.md` / `NEXTmedia.md`** predate the `modules/` split; their `src/Media/…` paths no
   longer exist.
3. `NEXTaudio.md` declares Media out of scope for the audio branch — so **no single planning
   document currently owns the audio↔media boundary**, which is exactly where the
   `FrameworkDispatcher` cycle and the `MediaPlayer`-through-mixer path live.

---

# 5. NET

## FACTS

1. **ENet is vendored at `third_party/enet`** and linked as target `enet` —
   `modules/net/CMakeLists.txt`. `CNA_Net` links `CNA_GamerServices` PUBLIC, so **net cannot be
   built without gamer-services**. VERIFIED
2. `CNA_ENABLE_NET` defaults **ON** (`CMakeLists.txt:62`) and gates
   `add_subdirectory(gamer-services)` **and** `add_subdirectory(net)` together
   (`modules/CMakeLists.txt:110-113`). With it OFF, the entire
   `Microsoft::Xna::Framework::{Net,GamerServices}` surface — including all Avatar types —
   disappears. VERIFIED
3. **Only `NetworkSessionType::SystemLink` is backed by real networking.**
   `bool ENetBackend::RealNetworkingEnabled(t) { return t == SystemLink; }` —
   `modules/net/src/Internal/ENetBackend.cpp:1064-1067`. VERIFIED
4. **`Local`, `LocalWithLeaderboards`, `PlayerMatch` and `Ranked` are *fully synthetic*, and that
   includes local delivery.**
   `modules/net/tests/CNA/Internal/Net/NetworkSessionTypePolicyTests.cpp:94-108`
   (`SendDataStaysFullySyntheticForEverySyntheticType`) asserts
   `EXPECT_FALSE(gamer->getIsDataAvailableProperty())` after a `SendData` + `Update()` for every
   one of the four. The gate is `NetworkSession::Update()`'s `PacketSend` branch, which is nested
   inside `if (RealNetworkingEnabled(sessionType_))` —
   `modules/net/src/Xna/NetworkSession.cpp:375-395`. **`Local` is not "loopback-style real"; it
   delivers nothing.** VERIFIED
5. The same test file additionally proves, for all four synthetic types: no port is ever bound
   (`GetBoundPort == 0`), `Update()` never binds or throws, `ConnectToHost` is a no-op leaving
   exactly 1 gamer, `StartGame`/`EndGame` work locally and raise events, and `Find()` returns
   empty in **< 50 ms** (no network wait). VERIFIED
6. **Wire protocol — complete opcode table**
   (`modules/net/include/CNA/Internal/Net/NetPacketCodec.hpp:25-34`): `ClientHello=0x01`,
   `ServerWelcome=0x02`, `GamerJoinBroadcast=0x03`, `GamerLeaveBroadcast=0x04`, **`0x05` reserved
   for a future `HostChangeBroadcast` — not implemented**, `StateChangeBroadcast=0x06`,
   `AppData=0x10`. VERIFIED
7. **Topology is a star with host relay.**
   `AppDataMessage{SenderWireId, TargetWireId, Options, Payload}` is "relayed by the host"
   (`NetPacketCodec.hpp:83-90`); `NetworkSession::Update()` delivers locally for a
   `LocalNetworkGamer` target and calls `ENetBackend::SendAppData` otherwise
   (`NetworkSession.cpp:381-394`). VERIFIED
8. **Every list-length field on the wire is a single byte**, with an explicit `EncodeCount()`
   guard that throws rather than silently wrapping at 256 (`NetPacketCodec.cpp:38-47`).
   `MaxSupportedGamers = 31` (`NetworkSession.hpp:64`) keeps it unreachable in practice. VERIFIED
9. **`SendDataOptions` → ENet flag mapping** (`NetPacketCodec.cpp:270-284`):
   `None → ENET_PACKET_FLAG_UNSEQUENCED`; **`InOrder → 0`** (ENet's plain unreliable send is
   already per-channel sequenced — an exact match); `Reliable`, `ReliableInOrder` and `Chat` all →
   `ENET_PACKET_FLAG_RELIABLE`. ENet has no "reliable but unordered" primitive, so `Reliable` and
   `ReliableInOrder` genuinely collapse. `Chat` is a judgment call (FNA never implements delivery
   for it). VERIFIED
10. `kMaxPeers = MaxSupportedGamers (31)`, `kChannelLimit = 2`, `kControlChannel = 0`,
    `kMaxPendingPreHandshakeAppData = 64`, `kEmscriptenHostPort = 61191` —
    `modules/net/src/Internal/ENetBackend.cpp:34-52`. Non-Emscripten hosts bind port **0**
    (OS-assigned ephemeral) (`:1088`). VERIFIED
11. **LAN discovery is a raw UDP protocol on a separate socket**, not ENet's connected channel.
    `kDiscoveryPort = 61190`, `kSearchWindowMs = 150`, `kDiscoveryProtocolVersion = 1`
    (`ENetDiscoveryService.cpp:28-29`, `NetDiscoveryProtocol.hpp:19`). Socket options:
    `ENET_SOCKOPT_REUSEADDR`, `ENET_SOCKOPT_BROADCAST`, `ENET_SOCKOPT_NONBLOCK`
    (`:89-91`). VERIFIED
12. Discovery is **client-queries / host-replies**, not periodic host-announce; `FindSessions`
    sends a broadcast **plus an explicit unicast copy to 127.0.0.1** (`:341-346`) as a
    same-machine fallback, then blocks 150 ms collecting `Announce` replies, deduping by connect
    port. VERIFIED
13. **`QualityOfService` has a real RTT measurement** on the discovery path:
    `steady_clock::now() - queryStartTime_` per announce reply, fed to
    `QualityOfService::CreateInternal(TimeSpan)` (`ENetDiscoveryService.cpp:213-227`). Bandwidth
    (`BytesPerSecondUpstream/Downstream`) and `IsAvailable` remain default-constructed
    (`modules/net/src/Xna/QualityOfService.cpp`) — **synthetic**. Peer RTT during a session comes
    from ENet's own `peer->roundTripTime` (`ENetBackend.cpp:1169`). VERIFIED
14. **The discovery wire format is hardened against hostile UDP.** `ValidateProtocolVersion`
    rejects a mismatched version *before* parsing the rest (`NetDiscoveryProtocol.cpp:52-58`);
    property indices are rejected if negative or `>= kMaxPropertyIndex (256)` — the latter
    specifically because an unbounded positive index would drive ~2 billion `Add()` calls from one
    crafted packet (`:60-99`). VERIFIED
15. **Discovery is a permanent no-op on Emscripten** — no raw UDP exists in a browser or in Node's
    `ws`; `RegisterHost`/`UnregisterHost`/`Poll` do nothing and `FindSessions` returns empty.
    Documented as a platform constraint, not a TODO (`ENetDiscoveryService.hpp:34-37`).
    INTENTIONALLY-UNSUPPORTED, VERIFIED
16. **Host migration is genuinely implemented** (`AttemptHostMigration`, `ENetBackend.cpp:~800-885`),
    despite opcode `0x05` being unused. Two paths: (a) local promotion — the surviving peer marks
    its own gamer `IsHost`, calls `ENetDiscoveryService::RegisterHost` on its already-bound host
    handle, and raises a `HostChange` event; (b) **LAN rediscovery by gamertag**, retried up to
    **3 times × 150 ms**, because a star topology leaves clients no direct channel and the dead
    host cannot relay. Falls back to `false` (old immediate-end behaviour) when disabled or no
    host is reachable. `AllowHostMigration` defaults `false` (`NetworkSession.hpp:876`). VERIFIED
17. Migration matches **by gamertag**, an acknowledged limitation (two same-gamertag hosts on one
    LAN are already ambiguous). VERIFIED
18. **Trust model is explicit and enforced.** `IsFromAuthoritativeHost(state, peer)` requires
    `peer == state.HostPeer`; anything else calling a host-only broadcast is logged as a
    first-class protocol event and **disconnected** (`RejectUnauthorizedHostOnlyMessage`,
    `ENetBackend.cpp:370-396`, REMED-NET-001). The threat noted in-source is a custom ENet client
    speaking the fully-inferable wire format — no MITM needed — to kick gamers, inject fake
    gamers, corrupt wire-id assignment, or force a state transition. A peer that has already
    completed its handshake and re-sends `ClientHello` is likewise rejected (REMED-NET-003).
    VERIFIED
19. **`PacketWriter`/`PacketReader` are `BinaryWriter`/`BinaryReader` over a `MemoryStream`.**
    `Write(Matrix)` writes all 16 floats in row order; `Vector2/3/4`, `Quaternion` are
    component-wise; `Write(float)`/`Write(double)` are pure API-parity overrides. VERIFIED
20. **`Color` is not round-trippable through `PacketWriter`/`PacketReader`, deliberately.**
    `Write(Color)` writes **4 bytes** (`R,G,B,A`); `ReadColor()` reads **4 floats = 16 bytes**.
    Preserved from upstream rather than symmetrized, and pinned by two tests that assert exactly
    this asymmetry —
    `modules/net/tests/Microsoft/Xna/Framework/Net/PacketReaderWriterTests.cpp:144-162`. VERIFIED
21. **`NetworkMachine` throws `NotImplementedException` unconditionally**
    (`modules/net/src/Xna/NetworkMachine.cpp:25`), matching FNA's stub. STUBBED, VERIFIED
22. **Voice chat is entirely stubbed.** `LocalNetworkGamer::EnableSendVoice` and
    `SendPartyInvites` have empty bodies (`modules/net/src/Xna/LocalNetworkGamer.cpp:24-30`);
    `hasVoice_`, `isTalking_`, `isMutedByLocalUser_` are inert `false` fields
    (`NetworkGamer.hpp:205-212`). `HasLeftSession` is permanently false. STUBBED, VERIFIED
23. **Only one `NetworkSession` may exist per process**: `activeSession_`/`activeAction_` statics
    gate `BeginCreate`/`BeginFind`/`BeginJoin` with `InvalidOperationException`
    (`NetworkSession.cpp:668-726`). VERIFIED
24. **CNA deliberately deviates from FNA on async completion**: `NetworkSessionAction` sets
    `isCompleted_ = true` at construction, because FNA's own `GamerServicesDispatcher.Update()` is
    a permanent no-op and `Create()`/`Find()`/`Join()`'s polling loop would otherwise spin forever
    once a `GamerServicesComponent` exists — reproduced against the real FNA reference source, not
    just CNA's port (`NetworkSession.cpp:46-58`). VERIFIED
25. `SimulatedLatency` and `SimulatedPacketLoss` are **real**: loss is a probability draw
    (`ShouldDropForSimulatedLoss`, exact 0 and 1 special-cased), latency defers `AppData` delivery
    into a queue drained once per `PumpSession` (`ENetBackend.cpp:78-81, 591-650, 1173`). VERIFIED
26. `NetworkSessionJoinError` has exactly three values: `SessionNotFound`, `SessionNotJoinable`,
    `SessionFull`. VERIFIED
27. **Cross-machine networking is proven by a real two-process test.**
    `modules/net/tests/CNA/Internal/Net/TwoProcessLoopbackTest.cpp` `posix_spawn`s
    `tools/net/net_two_process_harness` twice (host + client) as genuinely separate OS processes
    and verifies a real ENet/UDP join and data exchange. The host's port is handed over
    **out-of-band via a pipe**, not via discovery, because two processes sharing the well-known
    discovery port is fragile here; discovery stays validated at the single-process
    `FindSessions()` level. Watchdogs: 8 s internal, 20 s outer. VERIFIED

## STATUS TABLE — NET

| API family | Status | Evidence | Test |
|---|---|---|---|
| `NetworkSession` — **SystemLink** | IMPLEMENTED (real ENet, cross-process proven) | `ENetBackend.cpp:1064-1067` | `TwoProcessLoopbackTest.cpp`, `ENetBackendTests.cpp` |
| `NetworkSession` — **Local / LocalWithLeaderboards** | **EMULATED, no delivery** (`SendData` is a total no-op) | `NetworkSession.cpp:375-380` | `NetworkSessionTypePolicyTests.cpp:94-108` |
| `NetworkSession` — **PlayerMatch / Ranked** | SYNTHETIC / INTENTIONALLY-UNSUPPORTED | ″ | ″ |
| LAN discovery (UDP 61190, v1, 150 ms) | IMPLEMENTED | `ENetDiscoveryService.cpp:28-29,341-346` | `ENetDiscoveryServiceTests.cpp`, `NetDiscoveryProtocolTests.cpp` |
| Discovery on Emscripten | INTENTIONALLY-UNSUPPORTED (permanent no-op) | `ENetDiscoveryService.hpp:34-37` | — |
| Host migration (promotion + rediscovery) | IMPLEMENTED, default OFF | `ENetBackend.cpp:~800-885` | `ENetBackendTests.cpp` |
| `HostChangeBroadcast` opcode 0x05 | **RESERVED, NOT IMPLEMENTED** | `NetPacketCodec.hpp:31` | — |
| `SendDataOptions` (5 values → 3 real guarantees) | IMPLEMENTED | `NetPacketCodec.cpp:270-284` | `NetPacketCodecTests.cpp` |
| `PacketReader`/`PacketWriter` | IMPLEMENTED; **`Color` asymmetric by design** | `PacketWriter.cpp:32-38` vs `PacketReader.cpp:33-38` | `PacketReaderWriterTests.cpp:144-162` |
| `QualityOfService` RTT | IMPLEMENTED (discovery round trip; ENet peer RTT in-session) | `ENetDiscoveryService.cpp:213-227` | — |
| `QualityOfService` bandwidth | SYNTHETIC (always default) | `QualityOfService.cpp` | — |
| Voice chat | STUBBED | `LocalNetworkGamer.cpp:24-26`; `NetworkGamer.hpp:205-212` | — |
| `NetworkMachine` | STUBBED (always throws) | `NetworkMachine.cpp:25` | — |
| `SimulatedLatency` / `SimulatedPacketLoss` | IMPLEMENTED | `ENetBackend.cpp:78-81,591-650` | `demo_simulated_network_conditions` |
| Single-session-per-process | IMPLEMENTED constraint | `NetworkSession.cpp:668-726` | `NetworkSessionTests.cpp` |
| Forged host-only messages | IMPLEMENTED rejection + disconnect | `ENetBackend.cpp:370-396` | `ENetBackendTests.cpp` |

## CONTRADICTIONS — NET

1. **`NEXTnet.md` is the most valuable and most self-aware document in the repo** — it records
   **seven** consecutive independent post-completion audits, each finding that the previous
   round's "done" claims overstated delivery, and closes with *"Do not assume an eighth pass
   wouldn't find more."* Its own guidance ("treat `plan_net.md`'s checkmarks as 'this task's
   described work was completed at the time,' not 'the feature was correct'") should be quoted,
   not paraphrased away.
2. **`plan_net.md` is 104/104 `[x]` with zero `[ ]`** — yet `NEXTnet.md` documents real bugs found
   *after* that completion. The checkmarks and the truth are decoupled by construction.
3. `plan_net.md`'s Phase 7 avatar assessment was corrected **five separate times in one day**
   (2026-07-18) and still ends at "PARTIALLY FIXED."
4. Both files predate the `modules/` split and the `NOXNA`→`CNAEXT` rename.

---

# 6. GAMERSERVICES

## FACTS

1. **The four "signed-in gamers" are literally named `"Stub Gamer"`, `"Stub Gamer (1)"`, `"(2)"`,
   `"(3)"`** — created by `GamerServicesDispatcher::Initialize()` at
   `modules/gamer-services/src/Xna/GamerServicesDispatcher.cpp:41-58`. Player One is not a guest;
   Two/Three/Four are (`isGuest = true`). `isSignedInToLive` is set to `isInitialized_`, i.e.
   **always `true`**. FNA's own "FIXME: This is stupid" is preserved deliberately. SYNTHETIC,
   VERIFIED
2. `Initialize()` deletes any previous collection's gamers first (a real leak fix, with a
   `GetFreedGamerCountForTesting()` counter) and raises `SignedInGamer::OnSignIn` for each
   (`:35-63`). VERIFIED
3. **`GamerServicesDispatcher::Update()` is an empty function** (`:66-68`); `UpdateAsync()`
   returns `isInitialized_` (`:70-77`). There is **no worker thread anywhere in GamerServices**.
   INTENTIONAL NO-OP, VERIFIED
4. **This no-op is the root of a real, reproduced hang bug.** Because `UpdateAsync()` returns
   `true` forever once initialized, any XNA-idiomatic
   `while (!result->IsCompleted) UpdateAsync();` loop spins at 99–100% CPU. Two independent
   instances were found and fixed by marking actions complete at construction:
   `NetworkSession::Create/Find/Join` (DEFERRED.md #19) and `SignedInGamer::BeginGetAchievements`
   (Task 7.1). Both are regressed by **out-of-process** tests, because `GamerServicesDispatcher`'s
   process-lifetime statics have no reset hook —
   `modules/net/tests/CNA/Internal/Net/GamerServicesDispatcherHangRegressionTest.cpp` (10 s
   watchdog, `posix_spawn` of `tools/net/gamerservices_dispatcher_harness`). VERIFIED
5. **The async model everywhere in GamerServices is "fake async"**: `Begin*` completes
   synchronously, invokes the callback immediately, and returns a caller-owned raw pointer the
   caller must `delete`. `Gamer::BeginGetProfile`, `SignedInGamer::BeginAwardAchievement`,
   `BeginGetAchievements`, `AvatarDescription::BeginGetFromGamer`, `Guide::BeginShow*`,
   `LeaderboardReader::Begin*` all follow it. A specific ordering fix is baked in: the returned
   pointer is captured **before** invoking the callback, so a re-entrant `End*` (which nulls the
   member) cannot make the method return a stale null (`SignedInGamer.cpp:92-102`). VERIFIED
6. **Achievements and leaderboards are the one genuinely persistent thing in this namespace.**
   On-disk root = `StorageDevice::GetStorageRootEXT()` (SDL `SDL_GetPrefPath`) + `/GamerServices`,
   with `achievements/` and `leaderboards/` subdirectories
   (`modules/gamer-services/src/Internal/LocalGamerServicesStore.cpp:28-34`). VERIFIED
7. **Format: one JSON file per gamertag**
   (`achievements/<sanitized-gamertag>.json`), shaped
   `{"achievements":[{"key":"…","earnedTicks":N}, …]}` (`:117-175`). Leaderboards are one file
   per `(sanitized key)_(gameMode)` (`MakeLeaderboardFileKeyEXT`, `:112-114`). Sanitization maps
   anything outside `[A-Za-z0-9._-]` to `_`, empty → `_` (`:87-108`). VERIFIED
8. **Writes are crash-safe**: write to `<path>.tmp`, then `fs::rename`, with a direct-write
   fallback if rename fails across filesystems (`:169-186`). Reads are best-effort — a missing
   *or corrupt* file starts empty and never throws (`:38-56`, plan_net Task 4.7). VERIFIED
9. **Defect (minor, precise):** `earnedTicks` is stored as a JSON **number backed by `double`**
   (`JsonValue::MakeNumber(static_cast<double>(record.EarnedTicks))`, `:170`). `DateTime` ticks
   for 2026 are ≈6.39×10¹⁷, well past double's 2⁵³ exact-integer limit (≈9.01×10¹⁵) — the ULP
   there is ~128 ticks ≈ **12.8 µs**. `LocalGamerServicesStore.hpp:26` claims *"exact round-trip,
   no string parsing."* The serializer does emit an integer when the (already-quantized) value
   round-trips (`modules/content/include/CNA/Internal/Json.hpp:531-537`), so the *stored* value
   is stable — but the *original* tick value is lost to ~13 µs. STRONG (arithmetic reasoning over
   verified code)
10. **Achievement metadata is honestly absent, not fabricated.** `EndGetAchievements` reconstructs
    only `Key`, `IsEarned=true`, `EarnedDateTime`; `Name`/`Description`/`GamerScore`/
    `DisplayBeforeEarned` are left at defaults because there is no local catalog
    (`SignedInGamer.cpp:159-170`). `Achievement::GetPicture()` throws `NotImplementedException`
    (`modules/gamer-services/src/Xna/Achievement.cpp:50-52`). VERIFIED
11. **Leaderboard persistence is triggered by `LeaderboardEntry::Rating` being set**, via a hook
    installed by `LeaderboardWriter::GetLeaderboard` — because the real XNA `LeaderboardWriter`
    API has no commit/submit method at all
    (`modules/gamer-services/src/Xna/LeaderboardWriter.cpp:53-59`). `LeaderboardReader` sorts
    rating-descending and skips rows with no matching signed-in `Gamer*`
    (`LeaderboardReader.cpp:23-64`). `PageDown`/`PageUp` are real here; FNA.NetStub's are all
    `NotSupportedException`. `LeaderboardKey` has 4 values: `BestScoreLifeTime`,
    `BestScoreRecent`, `BestTimeLifeTime`, `BestTimeRecent`. VERIFIED
12. **`Guide` — exactly two of its methods are real; fourteen are permanent empty no-ops.**
    No-ops with empty bodies: `DelayNotifications`, `ShowComposeMessage`, `ShowFriendRequest`,
    `ShowFriends`, `ShowGameInvite` (×2), `ShowGamerCard`, `ShowMarketplace`, `ShowMessages`,
    `ShowParty`, `ShowPartySessions`, `ShowPlayerReview`, `ShowPlayers`, **`ShowSignIn`**,
    `ShowAchievementsEXT` — `modules/gamer-services/src/Xna/Guide.cpp:800-863`.
    `setIsVisibleProperty` is also a no-op (`:355`). INTENTIONAL NO-OP, VERIFIED
13. **Real:** `BeginShowMessageBox`/`EndShowMessageBox` and `BeginShowKeyboardInput`/
    `EndShowKeyboardInput`. These are genuinely *pending* — the action is not completed at
    construction. Completion requires the game to call a `CNAEXT` render hook every frame
    (`Guide::RenderPendingMessageBoxEXT(device, spriteBatch, font, whitePixel)` at `:668`,
    `RenderPendingKeyboardInputEXT` at `:497`) which draws a translucent overlay with
    `SpriteBatch::Draw`/`DrawString` and polls real `Input::Mouse` / keyboard with edge detection
    — or to call `SimulateMessageBoxClickEXT` / `SimulateKeyboardInputCancelEXT`. **Calling
    `EndShowMessageBox` before either throws `InvalidOperationException` whose message names the
    render hook.** VERIFIED
14. `BeginShowMessageBox` throws `ArgumentException` for an empty button list (a CNA-original
    validation — FNA's whole method is a `NotSupportedException` stub) and
    `InvalidOperationException` if one is already pending (`:617-624`). VERIFIED
15. The keyboard-input overlay does real UTF-8↔UTF-16 conversion with surrogate-pair-safe
    backspace (`DecodeUtf8ToUtf16`/`EncodeUtf16ToUtf8`/`RemoveLastCodeUnit`, `:135-311`) and
    subscribes to `Input::TextInputEXT::TextInput`, unsubscribing on reset (`:599`). VERIFIED
16. **`Guide::IsVisible` is real** — `pendingMessageBox_ != nullptr || pendingKeyboardInput_ !=
    nullptr` (`:351-354`) — not FNA's fixed `false`. `IsScreenSaverEnabled` is real too:
    `SDL_ScreenSaverEnabled()` / `SDL_EnableScreenSaver()` / `SDL_DisableScreenSaver()`
    (`:335-346`). VERIFIED
17. **`FriendCollection` is always empty.** `SignedInGamer::GetFriends()` returns
    `FriendCollection::CreateInternal({})` unconditionally, and `IsFriend()` returns `false`
    unconditionally (`SignedInGamer.cpp:55-68`). `FriendGamer` is a fully real class with 13
    properties and no producer. VERIFIED
18. **`GamerProfile` is synthetic but plausible-by-construction**: `gamerScore_=0`,
    `gamerZone_=Pro`, `region_=RegionInfo::getCurrentRegionProperty()` (the one *real* value),
    `reputation_=5.0f`, `titlesPlayed_=1`, `totalAchievements_=0`, `motto_` empty,
    `GetGamerPicture()` returns `nullptr` —
    `modules/gamer-services/src/Xna/GamerProfile.cpp:6-43`. SYNTHETIC, VERIFIED
19. **`GamerPrivileges` is a fixed all-permissive constant** (`Everyone`/`true` across the board)
    and **is never enforced anywhere** —
    `modules/gamer-services/src/Xna/GamerPrivileges.cpp:6-15`. SYNTHETIC, VERIFIED
20. **`GamerPresence` carries the real XNA string table** — all 60 `GamerPresenceMode` display
    strings, including the `{0}`-parameterized ones (`"Co-Op: Level {0}"`, `"Score {0}"`, …) and
    the one deliberately-empty entry — `modules/gamer-services/src/Xna/GamerPresence.cpp:6-64`.
    Setting the mode or value updates the string, then calls `SetPresenceModeStringEXT()`, which
    is an **empty body** (`:113-115`): there is no service to publish presence to. IMPLEMENTED
    data / INTENTIONAL NO-OP publish, VERIFIED
21. `Gamer::GetFromGamertag`, `BeginGetFromGamertag`, `EndGetFromGamertag`, `GetPartnerToken`,
    `BeginGetPartnerToken`, `EndGetPartnerToken` all throw `NotSupportedException`
    (`modules/gamer-services/src/Xna/Gamer.cpp:82-113`). `PropertyDictionary::CopyTo` throws
    `NotImplementedException` (`PropertyDictionary.cpp:190`); `getIsReadOnlyProperty()` returns
    `true` unconditionally (`:183-186`). STUBBED, VERIFIED
22. `GamerServicesComponent::Initialize()` sets `GamerServicesDispatcher::WindowHandle` from
    `Game::Window::Handle` and calls `Initialize(Game::Services)`; `Update()` forwards to the
    no-op dispatcher. Neither calls its base, matching FNA (`GamerServicesComponent.cpp:14-25`).
    VERIFIED
23. There are **14 demos** under `modules/gamer-services/examples/` (7 GamerServices + 7 avatar)
    and 8 under `modules/net/examples/`. VERIFIED

## STATUS TABLE — GAMERSERVICES

| API family | Status | Evidence | Test |
|---|---|---|---|
| `SignedInGamer` × 4 fixed profiles | **SYNTHETIC** ("Stub Gamer"…) | `GamerServicesDispatcher.cpp:41-58` | `GamerServicesGamerTests.cpp` |
| `SignedIn`/`SignedOut` events | IMPLEMENTED (fire at Initialize) | `SignedInGamer.cpp:172-186` | ″ |
| `GamerServicesDispatcher::Update` | **INTENTIONAL NO-OP** (and the cause of two real hangs) | `GamerServicesDispatcher.cpp:66-68` | `GamerServicesDispatcherHangRegressionTest.cpp` |
| Achievements (award + query) | **EMULATED, real disk persistence** | `LocalGamerServicesStore.cpp:117-186` | `GamerServicesServiceTests.cpp` |
| Achievement catalog metadata | **INTENTIONALLY ABSENT** (not fabricated) | `SignedInGamer.cpp:153-170` | ″ |
| `Achievement::GetPicture` | STUBBED (throws) | `Achievement.cpp:50-52` | `GamerServicesDataTests.cpp` |
| Leaderboards (read/write/page) | **EMULATED, real disk persistence** | `LeaderboardWriter.cpp:53-59`; `LeaderboardReader.cpp:23-64` | `GamerServicesServiceTests.cpp` |
| `Guide.ShowMessageBox` / `ShowKeyboardInput` | **IMPLEMENTED — real CNA-built overlay** (requires `Render…EXT` per frame) | `Guide.cpp:497-560,604-798` | `GamerServicesServiceTests.cpp` |
| `Guide.Show*` (14 methods incl. `ShowSignIn`) | **INTENTIONAL NO-OP** | `Guide.cpp:800-863` | — |
| `Guide.IsVisible` / `IsScreenSaverEnabled` | IMPLEMENTED (real) | `Guide.cpp:335-354` | ″ |
| `FriendCollection` / `FriendGamer` | Real classes, **population always empty** | `SignedInGamer.cpp:65-68` | `GamerServicesCollectionsTests.cpp` |
| `GamerProfile` | **SYNTHETIC** (one real field: Region) | `GamerProfile.cpp:6-43` | `GamerServicesDataTests.cpp` |
| `GamerPrivileges` | **SYNTHETIC**, never enforced | `GamerPrivileges.cpp:6-15` | ″ |
| `GamerPresence` (60-string table) | Data IMPLEMENTED; publish **NO-OP** | `GamerPresence.cpp:6-64,113-115` | ″ |
| `Gamer::GetFromGamertag` / `GetPartnerToken` | STUBBED (throw) | `Gamer.cpp:82-113` | `GamerServicesExceptionsTests.cpp` |
| `PropertyDictionary::CopyTo` | STUBBED (throws) | `PropertyDictionary.cpp:190` | — |
| Storage integration | IMPLEMENTED (reuses `StorageDevice::GetStorageRootEXT`) | `LocalGamerServicesStore.cpp:28-31` | — |

## CONTRADICTIONS — GAMERSERVICES

1. **`LocalGamerServicesStore.hpp:26`** — *"as `System::DateTime` ticks (exact round-trip, no
   string parsing)"* — is not strictly true; the double-backed JSON number quantizes to ~12.8 µs
   at 2026 tick magnitudes (fact 9).
2. `plan_net.md` (which owns GamerServices) is 104/104 `[x]` while `NEXTnet.md` documents
   post-completion audits that found real gaps. Same decoupling as Net.
3. No `plan_gamerservices.md` exists; the namespace is documented only inside `plan_net.md`, which
   means the Guide overlay work, the achievement store, and the hang-bug family have no dedicated
   tracking file.

---

# 7. AVATAR

## FACTS

1. **The faithful XNA Avatar API is provably inert, deliberately.**
   `AvatarRenderer::getStateProperty()` **forces `state_ = AvatarRendererState::Unavailable` on
   every single read** — not a one-time initial value —
   `modules/gamer-services/src/Xna/AvatarRenderer.cpp:79-89`. VERIFIED
2. Consequently `getBindPoseProperty()` **always throws** `InvalidOperationException("The
   avatar's bind pose is not available.")`, because it checks the raw `state_ != Ready`
   (`:65-77`), and nothing anywhere ever sets `Ready`. VERIFIED
3. **`AvatarRenderer::Draw(bones, expression)` validates that `bones.size() == 71` (throwing
   `ArgumentException` otherwise) and then does nothing** — "Genuinely a no-op once validated,
   matching the real implementation" (`:117-128`). `Draw(IAvatarAnimation*)` adds a null check
   (CNA-original) and forwards. VERIFIED
4. **Both `AvatarRenderer` constructors ignore their `AvatarDescription*` argument entirely**
   (`:29-44`) — preserved, not "fixed". VERIFIED
5. **The 71-bone parent table is real, decoded data**, not invented: `kParentBoneIds`
   (`:22-26`), 71 entries, root `-1`, "Exact values decoded from the real XNA reference assembly;
   not derived or guessed." VERIFIED
6. **`AvatarDescription` is exactly 1021 bytes** (`DescriptionSize`), and the constructor throws
   `ArgumentException("Resource data must be exactly 1021 bytes.")` otherwise —
   `modules/gamer-services/src/Xna/AvatarDescription.cpp:49-56`. `IsValid` is simply
   `description_[0] != 0` (`:58-65`). VERIFIED
7. **`CreateRandom()` never randomizes anything** — it returns an all-zero, therefore *invalid*,
   description; `CreateRandom(bodyType)` validates `bodyType ∈ {0,1}` and then ignores it. Both
   preserved verbatim from real XNA (`:90-106`). `getHeightProperty()` lazily yields `0.0f`;
   `getBodyTypeProperty()` lazily yields `Female` (`:72-88`). `EndGetFromGamer` always returns an
   all-zero description (`:130-141`). SYNTHETIC-BY-FIDELITY, VERIFIED
8. **`AvatarAnimation` gives every instance 71 zero-valued bone transforms and `Length =
   TimeSpan::Zero`, regardless of preset** —
   `modules/gamer-services/src/Xna/AvatarAnimation.cpp:12-19`. The preset argument is used
   **only** to seed the CNAEXT `realClipName_`. `Update()` implements real looping/clamping
   arithmetic that, with `Length == 0`, always pins `CurrentPosition` to zero (`:39-76`).
   VERIFIED
9. **There are 31 `AvatarAnimationPreset` values**, each mapping to a clip-name string:
   `Stand0`–`Stand7`, `Clap`, `Wave`, `Celebrate`, 11 `Female*`, 10 `Male*` —
   `modules/gamer-services/src/Xna/AvatarAnimationPresetNamesEXT.cpp:9-42`. An unrecognized value
   throws `ArgumentException`. VERIFIED
10. **The real-rendering path is a wholly separate, opt-in CNAEXT API.**
    `EnableRealRenderingEXT(GraphicsDevice&, shared_ptr<SkinnedModelEXT>)`
    (`AvatarRenderer.cpp:130-152`, rejects null model and a disposed renderer),
    `IsRealRenderingEnabledEXT()`, `SetAppearanceEXT(AvatarAppearanceEXT)`,
    `DrawRealEXT(clipName, position, loop)`. `DrawRealEXT` throws `InvalidOperationException` if
    real rendering was never enabled (`:185-189`). VERIFIED
11. **`DrawRealEXT` is a genuine GPU-skinned draw**: `SkinnedModelEXT::ComputeBoneTransformsEXT`
    → `SkinnedEffect::SetBoneTransforms` → per-part `SetVertexBuffer`/`SetIndexBuffer`/
    `DrawIndexedPrimitives(TriangleList, …)` (`:191-235`). VERIFIED
12. **Lighting is XNA-faithful and was a real bug fix.** `DirectionalLight0` is configured as the
    single key light from `LightDirection`/`LightColor`, **`DirectionalLight1` and
    `DirectionalLight2` are explicitly disabled**, specular and emissive are zeroed, and
    `AmbientLightColor` is set last — replacing an earlier `EnableDefaultLighting()` call that
    leaked XNA's generic fill/back lights into every avatar, invisible in tests only because they
    back-faced the test quads (REMED-GFX-008, `:198-218`). VERIFIED
13. **Tint routing is substring-based on part name**: `"Hair"`→HairColor, `"Shirt"`→ShirtColor,
    `"Pants"`→PantsColor, `"Shoes"`→ShoesColor, else SkinColor — `PartTintEXT`, `:169-176`.
    Applied as `SkinnedEffect::DiffuseColor` per part. VERIFIED
14. **The avatar content path is `"avatar/male/avatar"` / `"avatar/female/avatar"`** —
    `AvatarBodyTypeToContentNameEXT`,
    `modules/gamer-services/src/Xna/AvatarBodyTypeNamesEXT.cpp:9-15`. VERIFIED
15. **Avatar rendering is proven by real pixel readback, and only on two backends.** The three
    integration tests (`avatar_real_render_integration_test.cpp`,
    `avatar_attach_part_integration_test.cpp`, `avatar_tint_routing_integration_test.cpp`) are
    registered **only** by `modules/renderers/easygl/examples/CMakeLists.txt:299-315` and
    `modules/renderers/vulkan/examples/CMakeLists.txt:892-906`. VERIFIED
16. The real-render test does three `GraphicsDevice::GetBackBufferData` 1×1 reads at NDC ≈ −0.75 /
    0.00 / +0.75 and asserts green/red/green, proving GPU skinning moved a one-bone quad by
    (+0.5, 0, 0) —
    `modules/gamer-services/examples/avatar_real_render_integration_test.cpp:100-165`. **It uses a
    synthetic one-bone quad model, not a real avatar asset**, deliberately, so it has no
    dependency on the asset pipeline having been run. It also sets `RasterizerState::CullNone`
    because the quad's winding is back-facing under CNA's real default state. VERIFIED
17. **The avatar art is fully original and the "never touch Xbox assets" rule is absolute.**
    `docs/avatar-art-direction.md` records the author decisions verbatim: toy-like stylization,
    *"Never use them, not even for private reference/measurement,"* geometry generated as glTF via
    the sibling `mesh-craft` tool. VERIFIED
18. **`docs/avatar-real-rendering-ext.md` states the load-bearing reason the base API is inert and
    it is not a CNA limitation**: the real Xbox avatar mesh/texture/animation data was always
    streamed at runtime from Xbox LIVE servers offline for over a decade — the reference assembly
    never bundled any of it. VERIFIED
19. `SkinnedModelEXT` is deliberately *not* built on `Model`/`ModelBone`/`ModelMesh` (which encode
    rigid per-mesh parenting, the wrong shape for per-vertex skinning). It has its own independent
    skeleton (~50–65 bones for a Mixamo-style rig, against `SkinnedEffect::MaxBones = 72`), named
    `Parts`, named `Clips`, and `ComputeBoneTransformsEXT` doing Lerp translation/scale +
    `Quaternion::Slerp` rotation, topological-order hierarchy walk, then multiply by
    `InverseBindPoseGlobal`. VERIFIED (doc) / STRONG (impl, read via doc + AvatarRenderer call
    site)
20. **The two bone-index spaces are fully decoupled**: `AvatarRenderer::ParentBones` /
    `IAvatarAnimation::BoneTransforms` stay the real 71-entry Xbox arrays and are untouched by the
    extension; `Draw(vector<Matrix>&, …)` hard-throws unless given exactly 71. VERIFIED
21. **The avatar visual quality is, per the repo's own record, still not fully fixed.**
    `plan_net.md` Phase 7 was corrected five times in one day (2026-07-18) across five independent
    audits; the final state is *"PARTIALLY FIXED"* with garment/body interpenetration measurably
    remaining (collar and cuffs the visible offenders). Root causes found along the way:
    mesh-craft CSG seams (normals), an **EasyGL shader-fidelity bug (EmissiveColor multiplied by
    DiffuseColor twice → ambient landing as `ambient·diffuse²`)**, and a `fix_automatic_weights`
    bend-joint blend that selected an *infinite slab* perpendicular to the bone axis, weighting
    Pants to `Shoulder.L`/`Shoulder.R` (108/107 vertices). VERIFIED (as the repo's own record)
22. **Eight avatar demos exist**: `demo_avatar`, `demo_avatar_animation_gallery` (cycles all 31
    presets × both genders), `demo_avatar_appearance_tint_studio`,
    `demo_avatar_bone_state_boundary` (documents the faithful-vs-EXT boundary),
    `demo_avatar_dual_compare`, `demo_avatar_multi_attach_stress`, `demo_avatar_wardrobe_hotswap`,
    and `demo_net_avatar_sync` (two real processes syncing position/yaw/clip over a real
    `NetworkSession`). All support `--smoke N`, `--screenshot <path>`, `--show-help`. VERIFIED

## STATUS TABLE — AVATAR

| API family | Status | Evidence | Test |
|---|---|---|---|
| `AvatarRenderer::State` | **INTENTIONALLY INERT** (forced `Unavailable` on every read) | `AvatarRenderer.cpp:79-89` | `AvatarRendererTests.cpp` |
| `AvatarRenderer::BindPose` | **INTENTIONALLY INERT** (always throws) | `:65-77` | ″ |
| `AvatarRenderer::Draw` (both overloads) | **INTENTIONAL NO-OP** after 71-bone validation | `:102-128` | ″ |
| `AvatarRenderer::ParentBones` (71, real data) | IMPLEMENTED | `:22-26` | ″ |
| `AvatarDescription` (1021 B, always zero/invalid) | **INTENTIONALLY INERT** | `AvatarDescription.cpp:49-141` | `AvatarDescriptionTests.cpp` |
| `AvatarAnimation` (71 zero bones, zero length) | **INTENTIONALLY INERT**; `Update()` arithmetic real | `AvatarAnimation.cpp:12-76` | `AvatarAnimationTests.cpp` |
| `AvatarAnimationPreset` → clip name (31) | IMPLEMENTED (CNAEXT) | `AvatarAnimationPresetNamesEXT.cpp:9-42` | `AvatarAnimationPresetNamesEXTTests.cpp` |
| `AvatarExpression` (mouth/eyes/eyebrows) | IMPLEMENTED (data only; ignored by Draw) | `AvatarExpression.cpp` | `AvatarExpressionTests.cpp` |
| `EnableRealRenderingEXT` / `DrawRealEXT` | **IMPLEMENTED — real GPU-skinned draw, opt-in** | `AvatarRenderer.cpp:130-236` | `avatar_real_render_integration_test.cpp` (pixel readback) |
| `AvatarAppearanceEXT` + `PartTintEXT` | IMPLEMENTED (substring routing) | `:159-176` | `avatar_tint_routing_integration_test.cpp` |
| `AttachPartEXT` / `RemovePartEXT` | IMPLEMENTED | `SkinnedModelEXT` | `avatar_attach_part_integration_test.cpp` |
| Backend coverage for real rendering | **EasyGL + Vulkan only** (registered) | `easygl/examples/CMakeLists.txt:299-315`; `vulkan/examples/CMakeLists.txt:892-906` | ″ |
| Avatar visual quality | **PARTIAL** (interpenetration remains) | `plan_net.md` Phase 7 / `NEXTnet.md` §3 | `tools/` regression scripts |

## CONTRADICTIONS — AVATAR

1. **`docs/avatar-demos.md`** is dated 2026-07-17 and defers control documentation to each demo's
   own F1 overlay — deliberately; but its "31 `AvatarAnimationPreset` clips" claim is confirmed
   accurate.
2. `docs/avatar-art-direction.md`'s Task 7.1 baseline lists three defects (proportions, broken
   topology, skinning ring artifacts) as *current*; `NEXTnet.md`/`plan_net.md` record five
   subsequent rounds that resolved two of the three and reduced the third. Reading the
   art-direction doc alone leaves a reader with a stale, worse picture than the truth.
3. All three avatar docs use the pre-rename `NOXNA`/mixed terminology in places.

---

# 8. STORAGE

## FACTS

1. **Storage is the smallest module in the project by an order of magnitude**: 931 lines of
   header+source, **5 test cases in 1 file**.
   `modules/storage/tests/Microsoft/Xna/Framework/Storage/StorageDeviceTests.cpp` is the entire
   suite. VERIFIED
2. **The async model is XNA 4.0 "fake async", stated as such in the header**: *"BeginXxx completes
   synchronously and the paired EndXxx extracts the result"* —
   `modules/storage/include/Microsoft/Xna/Framework/Storage/StorageDevice.hpp:19-22`. Both
   `SelectorResult` and `ContainerResult` hard-code `IsCompleted == true`,
   `CompletedSynchronously == true`, and carry an already-signalled `EventWaitHandle` —
   `modules/storage/src/StorageDevice.cpp:24-54`. **No thread, no queue, no deferral.** VERIFIED
3. **All four `BeginShowSelector` overloads ignore `sizeInBytes` and `directoryCount` entirely**
   and invoke the callback inline before returning (`:220-253`). The two-arg overload sets
   `playerIndex = std::nullopt`; the `PlayerIndex` overloads store it. `EndShowSelector`
   `dynamic_cast`s and throws `std::invalid_argument` on a foreign result. VERIFIED
4. **Storage root resolution is a real three-tier chain**: `SDL_GetPrefPath(nullptr, appName)`
   (which also *creates* the directory), with the trailing separator stripped; else
   `$XDG_DATA_HOME/<app>`; else `$HOME/.local/share/<app>`; else `fs::current_path()` —
   `modules/storage/src/StorageDevice.cpp:69-106`. `appName_` defaults to the literal `"game"`
   (`:74`). It is cached behind `storageRootInitialized_` and invalidated by `SetAppNameEXT`
   (`:266-271`). VERIFIED
5. **Container layout is `<root>/<displayName>/Player<N+1>`**, or
   `<root>/<displayName>/AllPlayers` when no `PlayerIndex` was selected —
   `modules/storage/src/StorageContainer.cpp:52-59`; directories are created eagerly in the
   constructor. An empty `displayName` throws `std::invalid_argument` (`:48-50`). VERIFIED
6. **`FreeSpace`/`TotalSpace` are real** — `fs::space(root).available` / `.capacity` — but return
   **`std::numeric_limits<long long>::max()`** when the root does not exist yet, and convert any
   `std::exception` into `StorageDeviceNotConnectedException` with the original as an inner
   exception (`StorageDevice.cpp:119-163`). VERIFIED
7. `IsConnected` walks up to the nearest existing ancestor and reports true if any exists; it
   swallows all exceptions and returns `false` (`:135-147`). VERIFIED
8. **`DeleteContainer` IS path-traversal-guarded, and IS tested.**
   `CNA::Internal::ResolveContainedPath(EnsureStorageRoot(), titleName)` rejects absolute paths
   and `..` escapes, throwing `std::invalid_argument` before `fs::remove_all`
   (`StorageDevice.cpp:195-214`, REMED-CONTENT-002). The 5 tests are exactly: empty name, absolute
   name, `"../../../../../../../../tmp"`, `"."`, and the happy path — each asserting *nothing was
   deleted* — `StorageDeviceTests.cpp:64-95`. VERIFIED
9. **`StorageContainer` is NOT guarded.** `ResolvePath(relative)` is the whole implementation:
   `return (fs::path(storagePath_) / relative).string();` —
   `modules/storage/src/StorageContainer.cpp:84-87` — with **no containment check of any kind**.
   Every one of `CreateDirectory`, `DirectoryExists`, `DeleteDirectory`, `CreateFile`,
   `FileExists`, `DeleteFile`, and all three `OpenFile` overloads routes through it.
   `container->CreateFile("../../outside.txt")` escapes the sandbox; an absolute `relative`
   silently discards the root (`fs::path::operator/` semantics). **VERIFIED — the gap is live at
   this SHA.**
10. **`StorageContainer` has zero tests.** Repo-wide grep for `StorageContainer`, `GetFileNames`,
    `GetDirectoryNames`, or `GlobMatch` inside any `modules/*/tests` returns nothing. VERIFIED
11. **The search-pattern overloads use a hand-rolled backtracking glob**, not a library call: a
    22-line `GlobMatch(pattern, str)` supporting `*` and `?` with star-backtracking state, in an
    anonymous namespace — `StorageContainer.cpp:13-35`. **It has no test at all.** VERIFIED
12. **`OpenFile`'s `fileShare` parameter has nowhere to go** — the three-overload chain funnels
    into `OpenFile(file, mode, access, /*fileShare*/)` where the parameter is unnamed and
    discarded, constructing a plain `System::IO::FileStream(path, mode, access)` —
    `StorageContainer.cpp:204-212`. `CreateFile` uses `FileMode::Create`. VERIFIED
13. `Dispose()` is idempotent and raises `Disposing`; the destructor calls it if not already
    disposed (`:62-72`). VERIFIED
14. `GetTypeName()` returns the literal `"Microsoft.Xna.Framework.Storage.StorageContainer"`
    (`:78-82`). VERIFIED
15. **Module wiring**: `cna_storage` links `cna_core_headers` PUBLIC (headers-only — no core
    symbol is referenced), sharp-runtime `Core.Base IO Runtime Threading` PUBLIC, and
    `SDL3::SDL3` PRIVATE (for `SDL_GetPrefPath`/`SDL_getenv`/`SDL_free`) —
    `modules/storage/CMakeLists.txt`. VERIFIED
16. **`GetStorageRootEXT()` is load-bearing outside Storage** — it is the root that
    `LocalGamerServicesStore` appends `GamerServices/` to (§6 fact 6). A change to `SetAppNameEXT`
    silently relocates every persisted achievement and leaderboard. VERIFIED

## STATUS TABLE — STORAGE

| API family | Status | Evidence | Test |
|---|---|---|---|
| `StorageDevice::Begin/EndShowSelector` (4 overloads) | IMPLEMENTED as fake-async; **`sizeInBytes`/`directoryCount` ignored** | `StorageDevice.cpp:220-260` | — |
| `StorageDevice::Begin/EndOpenContainer` | IMPLEMENTED, synchronous | `:169-193` | — |
| `StorageDevice::DeleteContainer` | **IMPLEMENTED + path-contained** | `:195-214` | `StorageDeviceTests.cpp` (5) |
| `FreeSpace` / `TotalSpace` | IMPLEMENTED (`fs::space`); `LLONG_MAX` sentinel if root absent | `:119-163` | — |
| `IsConnected` | IMPLEMENTED (ancestor walk) | `:135-147` | — |
| `DeviceChanged` event | **DECLARED, never raised** | `:60` | — |
| Storage root resolution (3-tier) | IMPLEMENTED | `:69-106` | — |
| `StorageContainer` file/dir CRUD | IMPLEMENTED | `StorageContainer.cpp:91-212` | **NONE** |
| `StorageContainer` path sandboxing | **ABSENT — live traversal gap** | `:84-87` | **NONE** |
| `GlobMatch` (`*`/`?` search patterns) | IMPLEMENTED, hand-rolled | `:13-35` | **NONE** |
| `OpenFile(fileShare)` | **PARAMETER DISCARDED** | `:204-212` | **NONE** |
| Per-player containers | IMPLEMENTED (`PlayerN` / `AllPlayers`) | `:52-59` | **NONE** |

## CONTRADICTIONS — STORAGE

1. **No `plan_storage.md` or `NEXTstorage.md` exists.** This namespace has no task history at all
   — the only planning artifact touching it is `remediation/` (REMED-CONTENT-002, which produced
   the `DeleteContainer` guard).
2. `StorageDevice.hpp:19-22`'s "fake-async" framing is accurate and should be quoted rather than
   paraphrased — it is the clearest single statement of the pattern anywhere in the repo.

---

# 9. CROSS-CUTTING CONTRADICTIONS AND REPO-STATE FACTS

These affect more than one chapter and, in two cases, the whole book.

1. **`NOXNA` no longer exists.** Commit `2ecbca579` ("refactor(extensions): rename NOXNA feature
   macro to CNAEXT") renamed it repo-wide; `grep -rn NOXNA modules/ --include=*.hpp
   --include=*.cpp` returns **0**, against **551** `CNAEXT` occurrences in the four modules
   sampled alone. The macro is defined at `modules/core/include/CNA/CNAHelper.hpp:23-25`:
   **empty in a normal build**, `[[deprecated("CNAEXT: not part of the XNA 4.0 API surface")]]`
   only under `CNA_STRICT_XNA_API`. **The book uses `NOXNA` 221 times across 36 files, including
   an entire appendix (`appendix-e-noxna-catalog.tex`).**
2. **The strict-XNA gate is enforced in *both* directions** and is the single most transferable
   idea in the repo: `cna_strict_xna_api_check` must compile clean with
   `-Werror=deprecated-declarations`, and `cna_strict_xna_api_leak_check` is `EXCLUDE_FROM_ALL` +
   `WILL_FAIL TRUE` — it **must fail to compile**, so the gate itself cannot silently rot
   (`cmake/Harnesses.cmake:171-241`). The book does not mention this at all.
3. **The book's CMake variable is wrong everywhere.** The real cache variable is
   **`CNA_GRAPHICS_RENDERER`** (`cmake/RendererSelection.cmake:15-16`), with **46 legal values**;
   `EASYGL` is not one of them (EasyGL is reached via `OPENGLES2`/`OPENGLES3`/`OPENGL33`/
   `WEBGL1`/`WEBGL2`). The book writes `-DCNA_GRAPHICS_BACKEND=EASYGL` and similar in ch04 (×5),
   ch39, ch40 and ch41 — **every build command line in the book is non-functional.**
4. **The book never mentions `CNA_DEVICES`, `CNA_CNAEXT`, or `CNA_ENABLE_NET`** (grep across
   `latex/`). Three build options gate the subject matter of three whole chapters:
   - `CNA_DEVICES=OFF` (default) compiles out **all** of Chapter 29's second half.
   - `CNA_ENABLE_NET=OFF` removes Chapters 30, 31 **and 32** entirely.
   - `CNA_CNAEXT=OFF` (default) gates the `CNA::Graphics` extension layer.
5. **The book has absorbed none of the `modules/` physical split.** Zero occurrences of
   `modules/` anywhere in `latex/`; one stale literal path (`src/Media` in ch01). Every `src/…` /
   `include/…` path a reader might follow has moved.
   `modules/CMakeLists.txt:186-193` now *hard-fails configure* if a root `src/` tree reappears, so
   this is permanent.
6. **Test counts everywhere in the book are stale.** Current: **6,171** test cases across all
   modules. Per-module: input 522 (book says 524), audio 637, media **285** (book says
   "5,471 tests exist for this namespace" — that number is neither media-specific nor current,
   and its accompanying "four hardware-only skips (accelerometer/gyroscope)" belongs to Devices,
   not Media), net 293 (book says "4,935 tests touching this area, 4,884 pass"), gamer-services
   368, devices 462, devices-ext 50, storage **5**.
7. **These eight modules have had no functional change since the modularization/rename campaign**
   (`git log -- modules/audio modules/net modules/gamer-services modules/storage` tops out at
   `fbbc8da84`/`2ecbca579`/`86872b81f`, all structural). Recent development is entirely in
   `modules/renderers` — **44 renderer directories now exist**. Part V's *subject matter* is
   stable; its *scaffolding* (paths, macro names, build flags, counts) is not.

---

# 10. BOOK IMPACT

Verdicts for the new edition, per chapter. Existing sizes: ch26 664 lines, ch27 463, ch28 392,
ch29 272, ch30 345, ch31 487, ch32 336, ch33 281 (3,240 total for Part V).

### Ch. 26 — Input → **UPDATE + EXPAND** (structurally sound; the strongest chapter in Part V)
The architecture section (event-driven vs FNA's re-query, the two-identical-snapshots
consequence, the single-threaded contract) is **correct and verified**. Keep it.
- **Fix:** `NOXNA` → `CNAEXT` (15 occurrences) and explain the macro's `[[deprecated]]`
  strict-mode behaviour.
- **Fix:** "524 input-specific tests" → **522**.
- **Add:** the exact XInput dead-zone constants (7849/32768, 8689/32768, 30/255) and the three
  dead-zone algorithms — the chapter currently discusses dead zones without giving the numbers.
- **Add:** `MaxSupportedGamePads = 4` explicitly.
- **Add:** the **window-registry coordinate transform** — `IGraphicsRenderer::GetForWindow()` /
  `TransformWindowToLogical` and the `SDL_RenderCoordinatesFromWindow` fast path. This is the
  single most under-covered mechanism in the chapter and it is what makes input correct on a
  scaled/letterboxed window.
- **Add:** F9/F10 are reserved by `Game::PollEvents()`.
- **Add:** the honest statement that **all 10 gesture types are genuinely detected** — a rare
  "no gap here" fact worth stating.
- **Add:** `Keys` = 160 values, and the 125-vs-126 scancode-map asymmetry behind the "non-US
  layouts drop characters" note the chapter already makes qualitatively.
- **Fix/expand:** the `CNA::Input` extras section must now explain the **duplication with
  `CNA::Devices`** (Clipboard, Power) *and* the fact that, because `CNA_DEVICES` defaults OFF,
  `CNA::Input::Clipboard` is the **only** clipboard API in a default build. Cross-reference ch29.
- **Add (new, honest gap):** `CNA::Input::Sensors` never initializes `SDL_INIT_SENSOR` and is a
  latent no-op unless something else does.

### Ch. 27 — Audio → **EXPAND (substantially)**
Framing, the SDL3_mixer rationale, and the "real user-reported bug" section are good. It is
under-length for the material.
- **Fix:** the claim that `SoundEffect` "loads raw PCM/WAV assets" is too narrow.
  `MIX_LoadAudio`/`MIX_LoadAudio_IO` decode **WAV, AIFF, VOC, AU, FLAC, MP3, Ogg Vorbis and MIDI**
  in CNA's vendored build — a *superset* of XNA. Give the enabled/disabled table from
  `cmake/ThirdPartySDL.cmake:149-160` (Opus, WavPack, MOD, mpg123, fluidsynth, libFLAC, vorbisfile
  all OFF).
- **Add:** the exact formulas — `pitch = 2^p`, the FAudio inverse-law attenuation (full volume
  *within* `DistanceScale`), the doppler clamp `[0.5, 4.0]`, `SpeedOfSound = 343.5f`, the pan
  crossfeed matrix and why hard pan does not silence the far speaker. The chapter currently
  gestures at 3D audio without the math.
- **Add:** the `MIX_Mixer` / `MIX_Audio` / `MIX_Track` object model and the fixed
  S16/2ch/44100 device spec as the *first* thing after the SDL3_mixer rationale.
- **Add:** the `SDL_INIT_AUDIO` pin and the ASan crash that motivated it — a genuinely
  instructive C++/C-library lifetime story.
- **Add:** `DestroyMixer()` has no caller; the mixer lives to process exit.
- **Add:** `InstancePlayLimitException` is declared and tested but **never thrown** — there is no
  fire-and-forget cap.
- **Add:** the XNB `SoundEffectReader`'s **five** supported formats and the synthesized MS-ADPCM
  coefficient table (this is the fix for the deep audit's headline "missing sounds" finding, and
  the book should carry the corrected version, not the audit's stale one).
- **Add:** `OfflineAudioRenderer` (`MIX_CreateMixer` + `MIX_Generate`, no device, no wall clock) —
  the answer to "how do you test what reaches the speakers", and the best methodology story in
  the audio module.
- **Correct the status framing:** `plan_audio.md`'s three release blockers are **still open**.
  Say so.

### Ch. 28 — Media → **UPDATE (light) + one correction**
The most accurate chapter in Part V; its self-corrections about stale docs are exemplary.
- **Fix:** the "5,471 tests exist for this namespace, with 5,467 passing and only four
  hardware-only skips (accelerometer/gyroscope)" claim. That is a whole-suite number with a
  Devices-specific skip note attached to Media. Media has **285** test cases; the whole project
  has **6,171**.
- **Add:** the `SongTypeReader` extension list advertises `.opus`, `.aac`, `.wma`, which this
  build cannot decode — a real, small, checkable inconsistency in exactly the style this chapter
  already does well.
- **Add:** the `ContentManager.cpp:47` guard defect (duplicated `__MINGW32__`, missing `_WIN32`)
  as a concrete instance of the "two gating expressions that must agree" hazard the FFmpeg
  section already discusses.
- **Add:** the media↔audio declared static-archive cycle and why it is genuine XNA semantics, not
  a build smell.

### Ch. 29 — Devices/Sensors → **REWRITE (largest single rewrite in Part V)**
The craft/thread-safety narrative is excellent and must survive. Everything around it is wrong or
missing.
- **CRITICAL — add:** `CNA_DEVICES` defaults **OFF**, and it gates `modules/devices-ext`
  **completely** (all 49 files `#ifdef`-wrapped; the static library ships with **zero defined
  symbols**; its 10 test files register **zero** cases) while gating **nothing** in
  `modules/devices`. As written, the chapter's entire "CNA::Devices: a desktop utility layer"
  section describes an API that **does not exist in a default build**. This must be stated before
  any of it.
- **CRITICAL — correct:** the chapter presents all four sensors as one family. **`Compass` and
  `Motion` are Android-only.** Off Android, `IsSupported()` is a hardcoded `false` and `Start()`
  throws — SDL3 exposes no magnetometer and no fused-orientation API on any platform.
- **Add:** the Android half is **NDK C, not JNI** (`ASensorManager_*`/`ALooper_*`,
  `libandroid.so`+`liblog.so`, minSdk 24 because of the deprecated `ASensorManager_getInstance`),
  with **one worker thread per bridge — six for a single `Motion`**.
- **Add:** the delivery mechanism, which the chapter's whole thread-safety argument depends on but
  never names: `SDL_AddEventWatch` + `SDL_EVENT_SENSOR_UPDATE`, with the
  `static_assert(is_same_v<…, SDL_EventFilter>)` that replaced a UB `reinterpret_cast`. **There is
  no polling thread on desktop; there IS one per bridge on Android.** That asymmetry is the
  chapter's real subject.
- **Add:** the one global mutex shared by `SDL_INIT_SENSOR` *and* `SDL_INIT_HAPTIC`, and the
  `const std::lock_guard&`-as-compile-time-proof idiom.
- **Add:** `DevicesShutdownCoordinator` and the static-destruction-order UAF it exists to prevent
  — a first-rate C++ lifetime story the chapter currently omits entirely.
- **Add:** the compass/motion math with formulas (`atan2` azimuth both modes, the `cos45°` tilt
  switch, the `Low→20°` accuracy choice and why, `TrueHeading == MagneticHeading` and why, the
  quaternion passthrough, and the **reflection-not-rotation** reason `Attitude` is never
  remapped).
- **Add:** `VibrateController` is **real rumble** (`SDL_PlayHapticRumble`, `SDL_HAPTIC_LEFTRIGHT`
  effects), 5 s cap, NaN→0, and it **deliberately skips gamepads** so it never fights
  `GamePad::SetVibration`.
- **Add:** `SDL_INIT_CAMERA` is never initialized — Camera is inert unless the host app inits it.
- **Add:** the honest state — **zero hardware QA reports have ever been filed**; every Android
  claim rests on source reading and host unit tests, which the source itself says.
- **Fix:** the Camera worked example, `NOXNA`→`CNAEXT`, and the missing note that the Android
  demo the APK builds is a stale 447-line copy of the 523-line desktop demo.
- **Consider splitting**: `Microsoft::Devices::Sensors` (a real WP7 port with genuine concurrency
  engineering, Android-gated for half its surface) and `CNA::Devices` (an off-by-default SDL3
  host-integration layer) now share almost nothing. A **split into 29a/29b** is defensible.

### Ch. 30 — GamerServices → **UPDATE + EXPAND**
The summary table is accurate. The Guide section is accurate and well-judged.
- **Add:** the four gamers are literally `"Stub Gamer"`, `"Stub Gamer (1..3)"`, one non-guest +
  three guests, `IsSignedInToLive` always true. Naming them is more honest and more memorable
  than "synthetic profiles".
- **Add:** the exact on-disk contract — `SDL_GetPrefPath` root +
  `GamerServices/{achievements,leaderboards}/`, one JSON file per gamertag / per
  `(key)_(gameMode)`, `{"achievements":[{"key","earnedTicks"}]}`, filename sanitization to
  `[A-Za-z0-9._-]`, temp-file+rename crash safety, corrupt-file-starts-empty. This is the most
  concrete, checkable thing in the namespace and the chapter currently only says "locally
  persisted."
- **Add (new, small, precise):** the `earnedTicks`-as-`double` ~12.8 µs quantization vs the
  header's "exact round-trip" claim.
- **Add:** enumerate the **14** `Guide.Show*` no-ops explicitly, including `ShowSignIn` — a
  reader porting a sign-in flow needs to know it is silent.
- **Add:** the `GamerServicesDispatcher::Update()`-is-empty → infinite-spin bug family, both
  instances, and the **out-of-process regression harness** pattern needed because the
  dispatcher's statics have no reset hook. This is a strong methodology story and it belongs here
  rather than in ch31.
- **Add:** `GamerPresence` carries all **60** real XNA display strings but
  `SetPresenceModeStringEXT` is empty — real data, no consumer.
- **Add:** `GamerPrivileges` is a fixed all-permissive constant that nothing enforces;
  `GamerProfile`'s only real field is `Region`.

### Ch. 31 — Networking → **UPDATE (one real correction) + EXPAND**
Strong chapter. One table row is materially wrong.
- **CORRECT (important):** the "Real versus stub by `NetworkSessionType`" table says `Local` is
  *"Real, loopback-style, no network transport"* and `LocalWithLeaderboards` is *"`Local` plus …
  leaderboards"*. **Both are wrong about delivery.** `RealNetworkingEnabled` is true only for
  `SystemLink`; `NetworkSession::Update()`'s entire `PacketSend` branch is nested inside that
  gate, so **`SendData` on a `Local` session delivers nothing, not even between two local
  gamers** — asserted directly by `NetworkSessionTypePolicyTests.cpp:94-108` for all four
  synthetic types. What `Local` *does* keep is session lifecycle: `StartGame`/`EndGame`, state
  transitions, and their events.
- **Add:** the full opcode table (0x01–0x06, 0x10) including **`0x05` reserved-but-unimplemented**,
  and the star-with-host-relay topology.
- **Add:** the constants — discovery UDP **61190**, protocol version 1, **150 ms** search window,
  Emscripten host port 61191, `kChannelLimit = 2`, `kMaxPeers = 31`, 64 pre-handshake queue slots,
  migration retry 3 × 150 ms.
- **Add:** the exact `SendDataOptions` → ENet flag mapping, especially `InOrder → 0` (ENet's
  unreliable send is already sequenced) — this is the crisp technical answer behind the chapter's
  existing "four values, three guarantees" section.
- **Add:** the discovery protocol's hostile-input hardening (version-check-before-parse, negative
  index, `kMaxPropertyIndex = 256` against a 2-billion-`Add()` DoS) and the **trust model** — a
  custom ENet client speaking the inferable wire format needs no MITM; host-only messages from a
  non-host peer are logged and the peer disconnected.
- **Keep and strengthen:** the `Color` asymmetry section — it is correct, and the two tests that
  *pin* the asymmetry are worth quoting.
- **Fix:** "4,935 tests touching this area, 4,884 pass" → the net module has **293** cases; the
  project has **6,171**.
- **Add:** quote `NEXTnet.md`'s seven-audits lesson verbatim. It is the single best piece of
  engineering writing in the repo and it belongs in this book.

### Ch. 32 — Avatar → **UPDATE (one correction) + EXPAND**
Conceptually the sharpest chapter in Part V; the faithful/EXT split is exactly right.
- **CORRECT:** *"proven end-to-end via pixel readback on EasyGL; Vulkan and BGFX both have the
  real pipeline wiring in place but had not … been separately smoke-tested."* At this SHA all
  three avatar integration tests are registered for **both EasyGL and Vulkan**
  (`vulkan/examples/CMakeLists.txt:892-906`). BGFX is not registered.
- **Add:** the hard numbers — 1021-byte description, `IsValid` = `description_[0] != 0`, 71-bone
  parent table decoded from the real reference assembly, **31** animation presets,
  `SkinnedEffect::MaxBones = 72`, content path `avatar/{male,female}/avatar`.
- **Add:** `CreateRandom()` never randomizes; `AvatarAnimation` gives 71 zero bones and zero
  length regardless of preset; `State` is *forced* to `Unavailable` on every read (not merely
  initialized to it); `BindPose` therefore always throws.
- **Add:** the `DrawRealEXT` lighting fix (three-light `EnableDefaultLighting()` → one key light +
  disabled 1/2 + zeroed specular/emissive), and the **EasyGL `ambient·diffuse²` shader bug** that
  defeated three rounds of ambient tuning — the chapter's best available "when tuning a parameter
  fails, suspect the formula" lesson.
- **Add:** substring-based `PartTintEXT` routing.
- **Add:** the honest current state — five audit rounds, two of three defects resolved,
  garment/body interpenetration (collar, cuffs) measurably remaining, "PARTIALLY FIXED".
- **Add:** the eight demos by name and what each proves.
- **Note:** the real-render integration test uses a **synthetic one-bone quad**, deliberately, so
  it does not depend on the asset pipeline — worth stating so a reader does not over-read
  "pixel-verified" as "avatar-verified".

### Ch. 33 — Storage → **REWRITE the central narrative; keep the analysis**
The chapter's technical analysis is excellent. Its two load-bearing claims are now false.
- **CORRECT:** *"it is the one ported XNA namespace in this whole project with no automated test
  coverage at all… No `tests/Microsoft/Xna/Framework/Storage/` directory exists."* **It exists
  now** — `modules/storage/tests/Microsoft/Xna/Framework/Storage/StorageDeviceTests.cpp`, 5
  cases.
- **CORRECT and sharpen:** those 5 tests are *precisely* about path traversal — and
  `StorageDevice::DeleteContainer` **is now guarded** by `ResolveContainedPath`
  (REMED-CONTENT-002). The chapter says the traversal gap is untested and unreviewed; half of
  that is no longer true.
- **KEEP — and re-aim:** the traversal gap is **still live in `StorageContainer::ResolvePath`**
  (`StorageContainer.cpp:84-87`), which every file and directory operation routes through. The
  corrected narrative is far stronger than the original: *the traversal question was reviewed,
  guarded and tested — on `StorageDevice`, and only there; the container, which is where games
  actually write, was left unguarded.*
- **KEEP:** `StorageContainer` and the hand-rolled `GlobMatch` still have **zero** tests; the
  `fileShare`-goes-nowhere section is correct.
- **Add:** `sizeInBytes`/`directoryCount` are ignored by every `BeginShowSelector` overload;
  `DeviceChanged` is declared and never raised; `FreeSpace`/`TotalSpace` return `LLONG_MAX` when
  the root does not exist yet.
- **Add:** the cross-chapter dependency — `GetStorageRootEXT()` is also the root of the
  GamerServices achievement/leaderboard store (ch30), so `SetAppNameEXT` silently relocates saved
  achievements.
- **Consider merging** ch33 into ch30 or placing them adjacent with an explicit cross-reference;
  they now share one on-disk root.

### Missing entirely (candidates for new material in Part V)
1. **A build-configuration section** covering `CNA_GRAPHICS_RENDERER` (46 values), `CNA_DEVICES`
   (OFF), `CNA_ENABLE_NET` (ON), `CNA_CNAEXT` (OFF), `CNA_BUILD_TESTS`, `CNA_BUILD_EXAMPLES`,
   `CNA_USE_CCACHE` — and what each one *removes*. Belongs in ch04 but must be cross-referenced
   from 29, 30, 31, 32.
2. **The `modules/` physical architecture** — 16 modules, `cna_add_module()`, the
   `cna_build_flags` INTERFACE target, the declared audio↔media cycle, the ownership gate that
   hard-fails configure on a resurrected root `src/`. Nothing in the book describes it. Appendix D
   is about sibling *repos*, not layout.
3. **The `CNAEXT` marker and the two-directional strict-XNA compile gate** — currently
   `appendix-e-noxna-catalog.tex` documents the old name and none of the mechanism.
4. **`FrameworkDispatcher::Update()` as the cross-subsystem pump** — it drives dynamic audio,
   `Microphone::CheckAllBuffers`, `MediaPlayer` and its two deferred events, *and* `TouchPanel`
   gestures. It is referenced in passing from three chapters and owned by none.
5. **The out-of-process regression-harness pattern** (`posix_spawn` + watchdog) used for the
   dispatcher hang, the two-process net loopback, and the devices shutdown-ordering UAF — three
   independent uses of one technique, driven by process-lifetime statics with no reset hook. This
   is a genuine methodology contribution and would fit ch48 (Testing Philosophy) with pointers
   from 29/30/31.

---

*Note on renderer-count references above: this report's body text (§9 item 3) was written before
the final settlement of the identity count; the correct figure at this SHA is 46 identities / 42
implementation families, and the text above has been updated to say 46 rather than the 45 an
earlier draft used.*
