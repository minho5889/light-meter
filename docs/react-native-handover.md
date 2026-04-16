# React Native Handover — LightMeter Android App

<a id="table-of-contents"></a>
## Table of Contents

1. [Overview](#overview)
2. [Team Structure](#team-structure)
3. [Reference Codebase Map](#reference-codebase-map)
4. [Three-Layer Architecture](#three-layer-architecture-must-preserve)
5. [Priority Breakdown](#priority-breakdown)
6. [Camera Pipeline — Key Technical Details](#camera-pipeline--key-technical-details)
7. [Key Differences: Swift/iOS vs React Native/Android](#key-differences-swiftios-vs-react-nativeandroid)
8. [What Ports Directly](#what-ports-directly-common-ground)
9. [Week-by-Week Suggested Timeline](#week-by-week-suggested-timeline)
10. [Testing Requirements](#testing-requirements)
11. [Out of Scope](#out-of-scope)
12. [Reference Files to Read First](#reference-files-to-read-first)

---

## [Overview](#table-of-contents)

You are building an Android version of the LightMeter iOS app using React Native. The iOS codebase in this repo is your reference implementation. Your target is flagship Samsung phones (Galaxy S24/S25 series). The engagement is three weeks with two developers: a lead and a support developer.

The iOS app is a real-time light measurement tool that uses the camera to display lux (brightness), color temperature (Kelvin), and will eventually detect light flicker. The React Native version should be functionally equivalent — same features, same measurement logic, but adapted to Android's camera APIs and React Native's UI paradigm.

---

## [Team Structure](#table-of-contents)

| Role | Focus | Weeks |
|------|-------|-------|
| Lead developer | Project setup, camera pipeline, lux/temperature tabs, records shell, integration | All 3 weeks |
| Support developer | Flicker detection feature (research, native module, UI) | All 3 weeks |

Both developers should coordinate on the camera pipeline early (week 1) since flicker detection depends on frame-level access.

---

## [Reference Codebase Map](#table-of-contents)

The iOS project follows a strict three-layer architecture called the "deterministic split." Understanding this is critical because the pure logic layer ports directly to TypeScript with zero changes to the algorithms.

### Source structure

```
LightMeter/
├── LightMeterApp.swift              # App entry point
├── ContentView.swift                # Tab navigation (4 tabs)
├── Logic/                           # PURE LAYER — port this to TypeScript
│   ├── LuxCalculator.swift          # Lux formula: (C × A²) / (ISO × exposure)
│   ├── LuxInterpreter.swift         # Maps lux → description + tip (8 ranges)
│   ├── LuxRange.swift               # Shared range index function
│   ├── KelvinInterpreter.swift      # Maps Kelvin → color tone + tip (6 ranges)
│   ├── ColorTemperatureCalculator.swift  # Clamps Kelvin to [1000, 15000]
│   ├── ComparisonGenerator.swift    # "Brighter than X but darker than Y"
│   └── InterpretationResult.swift   # { description, tip } data type
├── Camera/                          # EFFECTS LAYER — rewrite for Android
│   ├── CameraSessionManager.swift   # AVCaptureSession lifecycle
│   ├── CameraFrameProvider.swift    # Frame buffer delegate, metadata extraction
│   └── CameraViewModel.swift        # Glue: wires camera → logic → UI state; holds sessionReady, captureFrameAsync()
├── Features/                        # VIEWS — rebuild in React Native
│   ├── Measurement/
│   │   ├── MeasurementView.swift    # LUX tab (live + captured modes)
│   │   └── MeasurementCardView.swift
│   └── Temperature/
│       ├── TemperatureView.swift    # Temperature tab
│       └── TemperatureCardView.swift
├── SharedViews/
│   ├── CameraPreviewView.swift      # Camera preview (UIViewRepresentable)
│   ├── CameraStateOverlay.swift     # Permission/error/live state wrapper
│   └── PlaceholderView.swift        # Placeholder for unbuilt tabs
└── Design/
    └── DesignConstants.swift         # Font sizes, spacing, dimensions
```

### Test structure

```
LightMeterTests/
├── Logic/
│   ├── LuxCalculatorTests.swift
│   ├── LuxInterpreterTests.swift
│   ├── LuxRangeTests.swift
│   ├── KelvinInterpreterTests.swift
│   ├── ColorTemperatureCalculatorTests.swift
│   └── ComparisonGeneratorTests.swift
└── Formatting/
    └── NumberFormattingTests.swift
```

---

## [Three-Layer Architecture (Must Preserve)](#table-of-contents)

This is the most important architectural constraint. The iOS codebase enforces it and the React Native version must too.

| Layer | What it does | iOS example | React Native equivalent |
|-------|-------------|-------------|------------------------|
| Pure Logic | Deterministic functions, no side effects, same input → same output | `Logic/*.swift` | TypeScript modules in `src/logic/` |
| Effects | Thin wrappers around hardware/platform APIs | `Camera/*.swift` | Native modules or library wrappers |
| Glue | Wires logic to effects, no business logic | `ContentView.swift`, `CameraViewModel.swift` | React components, hooks, context |

Rules:
- Business logic lives only in the pure layer
- The pure layer must not import any platform-specific modules
- Effects must not contain business logic
- Glue must not contain business logic or direct platform calls

This split exists so the pure logic is portable. You are proving that right now by porting it from Swift to TypeScript.

---

## [Priority Breakdown](#table-of-contents)

### P0 — Must complete (week 1–2)

These are blocking. Nothing else works without them.

#### P0.1 — Project scaffolding and camera pipeline

Set up the React Native project with camera access on Android. This is the foundation everything else builds on.

- Initialize React Native project (Expo or bare — your choice)
- Install and configure `react-native-vision-camera` (recommended) or equivalent
- Request camera permission on Android
- Display live camera preview full-screen
- Extract per-frame metadata from Android's Camera2 API:
  - ISO sensitivity (`SENSOR_SENSITIVITY`)
  - Exposure duration in seconds (`SENSOR_EXPOSURE_TIME`, convert from nanoseconds)
  - White balance / color temperature (`COLOR_CORRECTION_GAINS` or `SENSOR_NEUTRAL_COLOR_POINT`)
- This is the hardest part of the project. See the "Camera Pipeline" section below for details.

#### P0.2 — Pure logic layer port + unit tests

Port all 7 files from `Logic/` to TypeScript. Write equivalent unit tests. This is a hard requirement.

Files to port:
1. `LuxCalculator` — formula: `lux = (calibrationConstant × aperture²) / (ISO × exposureDurationInSeconds)`, defaults: calibration=12.5, aperture=1.6. Returns 0 for invalid inputs.
2. `ColorTemperatureCalculator` — clamps raw Kelvin to [1000, 15000]
3. `LuxInterpreter` — maps lux to one of 8 ranges, returns `{ description, tip }`
4. `KelvinInterpreter` — maps Kelvin to one of 6 ranges, returns `{ description, tip }`
5. `ComparisonGenerator` — generates "Brighter than X but darker than Y" sentences
6. `LuxRange` — shared `rangeIndex(lux)` function returning 0–7
7. `InterpretationResult` — TypeScript type/interface `{ description: string, tip: string }` (Swift version conforms to `Equatable` and `Sendable`)

Test expectations:
- Port the boundary value tests (every threshold crossing)
- Port the representative value tests (one value per range)
- Port the property-based tests or convert them to equivalent randomized tests using a library like `fast-check`
- All tests must pass in CI via `jest` or `vitest`

#### P0.3 — LUX tab (live measurement + capture)

Build the main measurement screen with two modes:

Live mode:
- Full-screen camera preview as background
- Frosted/translucent card overlay showing real-time lux and Kelvin
- Capture button (circle) and camera toggle button at bottom
- No settings gear icon in the current iOS build (was planned but not implemented)

Captured mode:
- Freeze the camera frame (display last captured image as UIImage)
- Expand the card to show: interpretation description, tip, comparison sentence
- Close button (× icon + "Close" label) top-left to return to live mode
- Hide the bottom tab bar while in captured mode

Reference: `MeasurementView.swift`, `MeasurementCardView.swift`

#### P0.4 — Temperature tab

Simpler than the LUX tab — live mode only, no capture.

- Full-screen camera preview background
- Card showing Kelvin value, color tone label, recommended environment tip
- No settings gear icon in the current iOS build (was planned but not implemented)

Reference: `TemperatureView.swift`, `TemperatureCardView.swift`

#### P0.5 — Tab navigation

Four-tab bottom navigation:

| Tab | Icon | Label |
|-----|------|-------|
| 1 | sun icon | LUX |
| 2 | thermometer icon | Temperature |
| 3 | shield/check icon | Check |
| 4 | clipboard icon | Records |

- Camera session starts when on tab 1 or 2, stops on tab 3 or 4
- Camera stops when app goes to background, restarts on foreground (only if on tab 1 or 2)

Reference: `ContentView.swift`

---

### P1 — Should complete (week 2–3)

#### P1.1 — Flicker detection (support developer)

This is the main new feature not yet implemented in the iOS version. The goal is to analyze light flicker from the camera feed and classify it by safety level.

Recommended approach — FFT-based luminance analysis:
1. Capture frames at a consistent rate (30fps minimum, 60fps preferred)
2. For each frame, compute the mean luminance (average pixel brightness across the frame or a center-weighted region)
3. Maintain a rolling buffer of N luminance samples (e.g., 128 or 256 frames for good FFT resolution)
4. Apply a Fast Fourier Transform (FFT) to the luminance buffer
5. Look for peaks at 100Hz and 120Hz (these are the doubled frequencies of 50Hz and 60Hz AC power — lights flicker at double the mains frequency)
6. Compute flicker percentage: `flicker% = (Lmax - Lmin) / (Lmax + Lmin) × 100` over the detected periodic component, where Lmax and Lmin are the peak and trough luminance values within the dominant flicker cycle

Flicker classification table (from the spec):

| Flicker % | Safety Level | Description |
|-----------|-------------|-------------|
| 0–3% | Very Safe | Minimal eye fatigue even with prolonged use |
| 3–10% | Safe | Sensitive individuals may feel mild dryness or fatigue |
| 10–30% | Caution | Noticeable eye pain, blurred focus, discomfort |
| 30–60% | Dangerous | Severe eye fatigue, migraines, dizziness |
| 60%+ | Very Dangerous | Visible flickering, risk of seizures for sensitive individuals |

Implementation notes:
- This will likely require a native frame processor plugin (Java/Kotlin) for performance — doing FFT in JavaScript on every frame will be too slow
- `react-native-vision-camera` supports custom frame processor plugins that run on the native thread
- Consider using Android's `RenderScript` or a lightweight FFT library (e.g., Apache Commons Math, or JTransforms) on the native side
- The flicker detection logic itself (classification from percentage) should live in the pure TypeScript logic layer
- The native module only computes the raw flicker percentage; classification happens in TypeScript
- Write unit tests for the classification function

UI for the Check tab:
- Full-screen camera preview background
- Card showing: flicker percentage, safety level label, description
- Color-coded indicator (green/yellow/orange/red based on safety level)
- Real-time updates as the analysis runs

#### P1.2 — Records tab (UI shell)

Build the Records tab as a UI shell. No real persistence — use in-memory state or a simple array.

- Display a list of record cards (newest first)
- Each card shows: date/time, brightness (lux), color temperature (Kelvin)
- Swipe left to reveal delete button
- Tapping a card opens a detail view with the captured photo and interpretations
- Close button returns to the list
- If no records exist, show an empty state

This is a UI shell only. Data does not persist across app restarts. Real persistence (SQLite, AsyncStorage) is out of scope.

Reference: the handover doc's P1.2 section above describes the card layout and detail view design.

#### P1.3 — Number formatting

Use locale-aware number formatting with thousands separators for all displayed values. `120000` should display as `120,000`. Use `Intl.NumberFormat` in JavaScript.

Reference: `MeasurementCardView.formatValue()`, `TemperatureCardView.formatValue()`

---

### P2 — Nice to have (if time permits)

#### P2.1 — Camera toggle (front/rear)

Toggle button to switch between front and rear cameras. The iOS app supports this.

Reference: `CameraViewModel.toggleCamera()`, `CameraSessionManager.toggleCamera()`

#### P2.2 — Permission and error state handling

Proper UI states for:
- Camera permission not granted → show explanation text
- Camera error → show error message
- These should be shared components used by all camera-backed tabs

Reference: `CameraStateOverlay.swift`

#### P2.3 — Design polish

- Frosted glass / blur effect on measurement cards (Android equivalent of iOS `.ultraThinMaterial`)
- Consistent spacing and font sizes (reference `DesignConstants.swift`)
- Accessibility labels on interactive elements

#### P2.4 — Settings placeholder

Gear icon in top-right of LUX and Temperature tabs, navigating to a placeholder screen showing "Settings — Coming Soon." Note: this is not implemented in the current iOS build — it was planned but deferred. If you implement it in React Native, use `PlaceholderView.swift` as a reference for the placeholder pattern.

Reference: `PlaceholderView.swift`

---

## [Camera Pipeline — Key Technical Details](#table-of-contents)

This is the most significant technical challenge. The iOS app reads camera metadata directly from `AVCaptureDevice` properties on every frame. Android requires a different approach.

### What the iOS app reads per frame

```
ISO          ← device.iso (Float)
Exposure     ← device.exposureDuration (CMTime → converted to seconds)
White balance← device.deviceWhiteBalanceGains → device.temperatureAndTintValues(for:) → .temperature
```

These are read from the hardware while auto-exposure is running. The app does not set manual exposure — it reads whatever the camera's auto-exposure algorithm decides.

### Android equivalent (Camera2 API)

On Android, you read these from `CaptureResult` metadata attached to each frame:

```
ISO          ← CaptureResult.get(CaptureResult.SENSOR_SENSITIVITY)        // Integer
Exposure     ← CaptureResult.get(CaptureResult.SENSOR_EXPOSURE_TIME)      // Long, in nanoseconds
                → divide by 1_000_000_000.0 to get seconds
Color temp   ← Requires computation from CaptureResult.get(CaptureResult.SENSOR_NEUTRAL_COLOR_POINT)
                or from COLOR_CORRECTION_GAINS
```

Samsung Galaxy S24/S25 flagships support `MANUAL_SENSOR` capability and expose full Camera2 metadata. This is not guaranteed on budget phones, but for flagships it works.

### How to access this in React Native

`react-native-vision-camera` does not expose per-frame ISO/exposure/white-balance metadata to JavaScript out of the box. You have two options:

Option A — Custom frame processor plugin (recommended):
- Write a small Kotlin native module that implements a VisionCamera frame processor plugin
- In the plugin, access the frame's `CaptureResult` metadata to read ISO, exposure time, and color correction gains
- Return the computed values (or raw values) to JavaScript
- The pure logic layer in TypeScript then computes lux and Kelvin

Option B — Standalone native module:
- Write a Kotlin module that opens its own Camera2 session
- Stream metadata values to JavaScript via events
- More control but more code, and you lose VisionCamera's preview/capture features

Option A is strongly recommended. It keeps the camera preview, capture, and metadata extraction in one pipeline.

### Color temperature on Android

iOS provides a convenient `temperatureAndTintValues(for:)` method. Android does not. You will need to compute color temperature from the white balance gains or the neutral color point.

A common approach: use the red/blue ratio from `COLOR_CORRECTION_GAINS` and map it to an approximate Kelvin value using McCamy's formula or a lookup table. This does not need to be exact — the iOS app clamps to [1000, 15000] and maps to 6 broad ranges, so approximate values are fine.

### Aperture constant

The lux formula uses `aperture = 1.6` (iPhone wide camera f/1.6). Samsung Galaxy S24 main camera is f/1.7, S25 is f/1.9. Update the default aperture constant accordingly, or make it configurable. The `LuxCalculator` already accepts aperture as a parameter.

---

## [Key Differences: Swift/iOS vs React Native/Android](#table-of-contents)

| Aspect | iOS (this repo) | React Native Android |
|--------|----------------|---------------------|
| Camera API | AVFoundation (AVCaptureSession, AVCaptureDevice) | Camera2 API via native module or react-native-vision-camera |
| Frame metadata | `device.iso`, `device.exposureDuration`, `device.deviceWhiteBalanceGains` — read directly from device object | `CaptureResult.SENSOR_SENSITIVITY`, `SENSOR_EXPOSURE_TIME`, `COLOR_CORRECTION_GAINS` — read from capture result metadata |
| Color temperature | `device.temperatureAndTintValues(for:).temperature` — built-in conversion | Must compute from white balance gains manually (McCamy's formula or gain ratio mapping) |
| UI framework | SwiftUI (declarative, native) | React Native (declarative, bridge to native views) |
| Blur/material effects | `.ultraThinMaterial` (one line) | Requires `@react-native-community/blur` or similar library, or a semi-transparent overlay |
| Tab navigation | SwiftUI `TabView` | `@react-navigation/bottom-tabs` |
| State management | `@StateObject`, `@ObservedObject`, `@Published` | React hooks (`useState`, `useContext`), or Zustand/Jotai |
| Concurrency | Swift concurrency (`async/await`, `@MainActor`, `DispatchQueue`) | JavaScript single thread + native module threads |
| Testing | Swift Testing framework (`@Test`, `#expect`) | Jest or Vitest with TypeScript |
| Build system | Xcode + XcodeGen | Metro bundler + Gradle |
| Permissions | `NSCameraUsageDescription` in Info.plist | `<uses-permission android:name="android.permission.CAMERA"/>` in AndroidManifest.xml |

## [What Ports Directly (Common Ground)](#table-of-contents)

These are identical between the two platforms — same algorithms, same thresholds, same output:

- Lux calculation formula
- Lux interpretation ranges and text (all 8 ranges)
- Kelvin interpretation ranges and text (all 6 ranges)
- Comparison sentence generation logic
- Kelvin clamping logic [1000, 15000]
- LuxRange index function
- Flicker percentage classification table
- Number formatting approach (locale-aware, thousands separators)
- Tab structure (4 tabs, same icons and labels)
- Measurement card layout (lux + Kelvin + interpretation)
- Capture flow (freeze frame → show interpretation → close button to return to live)

---

## [Week-by-Week Suggested Timeline](#table-of-contents)

### Week 1 — Foundation

Lead developer:
- Project setup, dependencies, build pipeline
- Camera preview working on Samsung device
- Frame metadata extraction (ISO, exposure, white balance) — this is the risky item, spike early
- Port pure logic layer to TypeScript with full test coverage
- Basic LUX tab with live lux/Kelvin display

Support developer:
- Research flicker detection approaches, prototype FFT analysis
- Set up native module skeleton for frame processor plugin
- Get mean luminance computation working per frame
- Build rolling buffer + FFT pipeline (native side)

### Week 2 — Features

Lead developer:
- Capture mode (freeze frame, expanded card, back button)
- Temperature tab
- Tab navigation with camera lifecycle management
- Number formatting
- Records tab UI shell

Support developer:
- Flicker percentage computation working end-to-end
- Classification logic in TypeScript with unit tests
- Check tab UI (card with flicker %, safety level, description)
- Color-coded safety indicator

### Week 3 — Polish and integration

Lead developer:
- Camera toggle (front/rear)
- Permission/error state handling
- Design polish (blur effects, spacing, accessibility)
- Settings placeholder
- Integration testing on Samsung device

Support developer:
- Flicker detection accuracy tuning on real lights
- Edge case handling (no flicker detected, camera switching, background/foreground)
- Unit tests for flicker classification
- Documentation of the flicker detection approach

---

## [Testing Requirements](#table-of-contents)

| What | Required | Tool |
|------|----------|------|
| Pure logic unit tests | Yes, hard requirement | Jest or Vitest |
| Flicker classification unit tests | Yes | Jest or Vitest |
| Property-based tests for logic layer | Recommended | fast-check |
| On-device manual testing | Yes, on Samsung flagship | Physical device |
| UI/integration tests | Nice to have | Detox or Maestro |

---

## [Out of Scope](#table-of-contents)

- iOS support (this is Android-only for now)
- Real data persistence for Records (in-memory only)
- App Store / Play Store submission
- Settings screen implementation (placeholder only)
- Localization / internationalization
- Offline mode or background processing
- Cloud sync or user accounts

---

## [Reference Files to Read First](#table-of-contents)

If you are short on time, read these files in this order to understand the app:

1. `docs/developer-guide.md` — how the codebase works, module reference, architecture diagrams
2. `LightMeter/Logic/LuxCalculator.swift` — the core formula (15 lines)
3. `LightMeter/Logic/LuxInterpreter.swift` — how lux maps to descriptions
4. `LightMeter/Logic/KelvinInterpreter.swift` — how Kelvin maps to color tones
5. `LightMeter/Camera/CameraFrameProvider.swift` — how iOS reads camera metadata per frame
6. `LightMeter/Features/Measurement/MeasurementView.swift` — the main screen with live/captured modes
7. `LightMeter/ContentView.swift` — tab navigation and camera lifecycle
8. `LightMeterTests/Logic/LuxCalculatorTests.swift` — test patterns to replicate

---

## [Questions? Contact](#table-of-contents)

If anything in this document is unclear or you hit a blocker with the Camera2 API metadata extraction, escalate early. The camera pipeline is the highest-risk item — if it slips past week 1, the whole timeline is at risk.
