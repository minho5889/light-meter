# How the LightMeter Codebase Works

This is your map to the iOS codebase. It covers what the app does, how the code is organized, where each module lives, and how the tests cover it. Read this before you start porting anything — it'll save you from guessing what a file does or why it's structured the way it is.

For the physics behind lux, Kelvin, and flicker, see the [Light Science Primer](docs/light-science-primer.md). For the React Native port plan, see the [Handover Guide](docs/react-native-handover.md).

---

<a id="table-of-contents"></a>
## Table of Contents

1. [What the App Does](#what-the-app-does)
2. [How the Code Is Organized](#how-the-code-is-organized)
3. [How Data Flows](#how-data-flows)
4. [The Test Suite](#the-test-suite)
5. [Building and Running](#building-and-running)

---

## [What the App Does](#table-of-contents)

LightMeter turns an iPhone camera into a real-time light measurement tool. Open the app, point it at a scene, and a translucent card overlays two live readings: lux (brightness) and Kelvin (color temperature).

Four tabs:

- **LUX** — live lux + Kelvin measurement with a capture button. Tap capture to freeze the frame and see a human-readable interpretation: what environment matches that brightness, a practical tip, and a comparison sentence like "Brighter than a movie theater but darker than a living room." Close button returns to live mode. Tab bar hides during capture.
- **Temperature** — live Kelvin reading with color tone label and environment tip. No capture mode.
- **Check** — placeholder for flicker detection (the React Native team builds this).
- **Records** — placeholder for saved measurement history.

### Lux ranges

The app uses 8 brightness ranges, each mapping to an environment description and a practical tip. The thresholds are defined in [`LuxRange.swift`](../LightMeter/Logic/LuxRange.swift) and the descriptions/tips live in [`LuxInterpreter.swift`](../LightMeter/Logic/LuxInterpreter.swift). See the [Light Science Primer](docs/light-science-primer.md) for the scale table and the science behind the spacing.

### Kelvin ranges

6 color temperature ranges, each with a color tone label and environment tip. The classification logic and exact strings are in [`KelvinInterpreter.swift`](../LightMeter/Logic/KelvinInterpreter.swift). See the [Light Science Primer](docs/light-science-primer.md) for the scale table and the physics behind warm vs. cool light.

---

## [How the Code Is Organized](#table-of-contents)

The codebase follows a "functional core, imperative shell" pattern (you'll see it called the "deterministic split" in the steering docs and spec files). Every file belongs to one of three layers:

**Logic** — pure, deterministic, portable. These are the files you'll port to TypeScript.

| File | Role |
|------|------|
| [`LuxCalculator`](../LightMeter/Logic/LuxCalculator.swift) | `calculateLux(iso:exposureDurationInSeconds:)` → lux as Double. Returns 0.0 for invalid inputs (zero/negative). |
| [`LuxRange`](../LightMeter/Logic/LuxRange.swift) | `rangeIndex(for:)` → index 0–7. Shared by `LuxInterpreter` and `ComparisonGenerator` so thresholds aren't duplicated. |
| [`LuxInterpreter`](../LightMeter/Logic/LuxInterpreter.swift) | `interpret(lux:)` → `InterpretationResult` with environment description + tip. Uses `LuxRange` internally. |
| [`KelvinInterpreter`](../LightMeter/Logic/KelvinInterpreter.swift) | `interpret(kelvin:)` → `InterpretationResult` with color tone + environment tip. |
| [`ColorTemperatureCalculator`](../LightMeter/Logic/ColorTemperatureCalculator.swift) | `calculateColorTemperature(rawKelvin:)` → Kelvin clamped to [1 000, 15 000]. |
| [`ComparisonGenerator`](../LightMeter/Logic/ComparisonGenerator.swift) | `generate(lux:)` → "Brighter than X but darker than Y." Uses `LuxRange` internally. |
| [`InterpretationResult`](../LightMeter/Logic/InterpretationResult.swift) | `{ description, tip }` — conforms to `Equatable` and `Sendable`. |
| [`TabTransitionAction`](../LightMeter/Logic/TabTransitionAction.swift) | `resolve(from:to:)` → `.startSession`, `.stopSession`, or `.none`. Camera↔camera returns `.none`. |

**Effects** — thin hardware wrappers. Rewrite these per platform; the logic layer stays the same.

| File | Role |
|------|------|
| [`CameraSessionManager`](../LightMeter/Camera/CameraSessionManager.swift) | AVCaptureSession lifecycle: setup, start, stop, camera toggle. Guards against redundant `startSession()` calls. |
| [`CameraFrameProvider`](../LightMeter/Camera/CameraFrameProvider.swift) | Reads ISO, exposure, white balance from each frame. Calls pure logic calculators. Provides `captureFrame()` → UIImage. |

**Glue** — views, view model, wiring. No business logic lives here.

| File | Role |
|------|------|
| [`CameraViewModel`](../LightMeter/Camera/CameraViewModel.swift) | Single source of truth: `@Published` lux, Kelvin, permission, error, camera position. Wires SessionManager + FrameProvider. |
| [`ContentView`](../LightMeter/ContentView.swift) | Four-tab layout. Uses `TabTransitionAction.resolve` for camera lifecycle on tab switches. Handles foreground/background. |
| [`Features/Measurement/`](../LightMeter/Features/Measurement/) | LUX tab — live mode (compact card + capture button) and captured mode (frozen frame, expanded card, hidden tab bar). |
| [`Features/Temperature/`](../LightMeter/Features/Temperature/) | Temperature tab — live Kelvin reading with color tone label. No capture mode. |
| [`SharedViews/`](../LightMeter/SharedViews/) | `CameraPreviewView` (UIKit bridge), `CameraStateOverlay` (permission/error/preview), `PlaceholderView` (stub tabs). |
| [`DesignConstants`](../LightMeter/Design/DesignConstants.swift) | Centralized font sizes, spacing, dimensions. |

Tests live in `LightMeterTests/` — 121 tests covering the pure logic layer only. See [The Test Suite](#the-test-suite) for the breakdown.

---

## [How Data Flows](#table-of-contents)

Every frame follows the same path: hardware → effects → pure logic → glue → screen.

```mermaid
graph LR
    CAM["📷 Camera"]
    CSM["CameraSessionManager"]
    CFP["CameraFrameProvider"]
    LC["LuxCalculator"]
    CTC["ColorTemperatureCalculator"]
    CVM["CameraViewModel"]
    VIEWS["SwiftUI Views"]

    CAM --> CSM --> CFP
    CFP --> LC --> CVM
    CFP --> CTC --> CVM
    CVM --> VIEWS

    style CAM fill:#6b7280,stroke:#374151,color:#fff
    style CSM fill:#f59e0b,stroke:#d97706,color:#fff
    style CFP fill:#f59e0b,stroke:#d97706,color:#fff
    style LC fill:#10b981,stroke:#059669,color:#fff
    style CTC fill:#10b981,stroke:#059669,color:#fff
    style CVM fill:#3b82f6,stroke:#2563eb,color:#fff
    style VIEWS fill:#3b82f6,stroke:#2563eb,color:#fff
```

> 🟢 Pure logic &nbsp;&nbsp; 🟡 Effects &nbsp;&nbsp; 🔵 Glue &nbsp;&nbsp; ⚫ Hardware

`CameraFrameProvider` reads raw values from the device and passes them to `LuxCalculator` and `ColorTemperatureCalculator`. The pure logic never touches the camera. `CameraViewModel` publishes the results so SwiftUI views can observe them.

The interpreters (`LuxInterpreter`, `KelvinInterpreter`) and `ComparisonGenerator` are called at display time — they take the computed lux/Kelvin values and return human-readable strings.

---

## [The Test Suite](#table-of-contents)

All 121 tests target the pure logic layer. The effects and glue layers require real hardware and aren't unit tested — that's by design. The architecture pushes all testable logic into the pure layer so the untested surface is as thin as possible.

- **LuxCalculatorTests** (7) — formula correctness, edge cases (zero/negative ISO, zero exposure), large ISO, non-negativity invariant
- **LuxInterpreterTests** (26) — all 8 range mappings, boundary values at every threshold, negative value fallback, oracle equivalence
- **LuxRangeTests** (17) — range index at every boundary, negative lux handling, equivalence with oracle
- **KelvinInterpreterTests** (22) — all 6 color tone ranges, boundary values, below-1000K fallback, determinism
- **ColorTemperatureCalculatorTests** (10) — clamping at min/max, identity for in-range values, invariant across random inputs
- **ComparisonGeneratorTests** (30) — sentence format for lowest/middle/highest ranges, boundary values, consistency with LuxInterpreter, completeness and correctness properties
- **TabTransitionActionTests** (8) — bug condition exploration (camera↔camera returns `.none`), preservation properties (camera→non-camera, non-camera→camera, non-camera→non-camera, same-tab), randomized verification
- **NumberFormattingTests** (1) — round-trip: format a number → parse it back → same value

The suite uses two styles: unit tests (specific input → expected output) and property-based tests (random inputs → invariant rules like "lux is never negative"). Every module has both. When you port to TypeScript, replicate the boundary tests and representative value tests. For property-based tests, `fast-check` is a good equivalent.

Notable cross-module coverage: `ComparisonGeneratorTests` cross-checks against `LuxInterpreter` to verify both agree on range boundaries. Both `LuxInterpreterTests` and `ComparisonGeneratorTests` exercise `LuxRange` indirectly since they depend on it.

---

## [Building and Running](#table-of-contents)

Two build systems, different purposes:

- **Swift Package Manager** (`swift build` / `swift test`) — builds and tests the pure logic layer only. Fast, no Xcode needed. Good for iterating on logic and CI pipelines.
- **Xcode via XcodeGen** (`xcodegen generate` then Cmd+R) — builds the full app including camera, UI, and device deployment. Required for running on an iPhone.

`Package.swift` lists only the pure logic files and `DesignConstants.swift` — it excludes camera and UI code since those depend on iOS frameworks SPM can't build in isolation.

`project.yml` (XcodeGen config) sources directories recursively, so new files are picked up automatically after running `xcodegen generate`.
