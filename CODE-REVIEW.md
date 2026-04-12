# Code Review — LightMeter iOS App

Scanned: all 16 Swift source files, 5 test files, Package.swift, project.yml, Info.plist, spec doc.

---

## P0 — Critical (fix before next feature work)

### 1. `ColorTemperatureCalculator` violates the deterministic split

`ColorTemperatureCalculator.calculateColorTemperature` takes an `AVCaptureDevice` as a parameter and calls `device.temperatureAndTintValues(for:)` directly. This makes the "pure logic" struct depend on a hardware side-effect object. It cannot be unit tested without a real device, and the existing test file only covers `clamp()` — the core calculation method has zero test coverage.

**Fix:** Extract the `AVCaptureDevice` call into `CameraManager` (effects layer). Have `CameraManager` resolve the raw Kelvin value and pass it to a pure `clamp()` or validation function. The calculator struct should accept `Double` inputs only.

### 2. `LuxCalculator` depends on `CoreMedia`

`calculateLux` takes a `CMTime` parameter, coupling the pure logic layer to a framework that only exists on Apple platforms. Per the deterministic-split steering, the pure layer must not import platform-specific frameworks for side effects.

**Fix:** Accept `exposureDurationInSeconds: Double` instead of `CMTime`. Move the `CMTimeGetSeconds()` call to `CameraManager` before invoking the calculator. This also makes the SPM test target simpler — no need to link CoreMedia.

### 3. `Package.swift` is incomplete / out of sync

The SPM target only lists 4 source files (`InterpretationResult`, `LuxInterpreter`, `KelvinInterpreter`, `ComparisonGenerator`). `LuxCalculator` and `ColorTemperatureCalculator` are excluded, and the test target excludes `LuxCalculatorTests` and `ColorTemperatureCalculatorTests`. This means `swift test` doesn't exercise the calculator tests at all.

**Fix:** After fixing items 1 and 2 above (removing platform dependencies from pure logic), add `LuxCalculator.swift` to the SPM target sources and `LuxCalculatorTests.swift` to the test target. `ColorTemperatureCalculator` can stay excluded if it still needs AVFoundation, but ideally it becomes pure too.

---

## P1 — High (address in the next 1–2 sprints)

### 4. `CameraManager` is doing too much

This class is ~180 lines handling: permission requests, session setup, camera toggling, frame capture, sample buffer delegation, lux calculation dispatch, and color temperature dispatch. It's the effects layer but it also orchestrates glue-layer concerns.

**Fix:** Consider splitting into:
- `CameraSessionManager` — session lifecycle, input/output setup, start/stop
- `CameraFrameProvider` — sample buffer delegate, frame capture
- Keep the `@Published` properties in a lightweight `CameraViewModel` that the views observe

### 5. Duplicated permission/error UI across views

Both `MeasurementView` and `TemperatureView` contain identical blocks for the "camera not permitted" and "camera error" states. If a third camera-backed tab is added (Flicker Detection is planned), this will triple.

**Fix:** Extract a `CameraBackgroundView` or `CameraStateOverlay` component that handles the permission/error/live-preview branching in one place.

### 6. `MeasurementCardView` calls business logic directly

`MeasurementCardView` calls `LuxInterpreter.interpret(lux:)` and `ComparisonGenerator.generate(lux:)` inline in the view body. This puts business logic invocation in the glue layer's rendering path.

**Fix:** Pre-compute the interpretation results in `MeasurementView` (or a view model) and pass the resolved strings down to the card as plain properties. The card should be a pure display component.

### 7. No accessibility support

None of the views declare `accessibilityLabel`, `accessibilityValue`, or `accessibilityHint`. VoiceOver users get raw system-inferred labels. The lux and kelvin readings are especially important to announce properly.

**Fix:** Add semantic accessibility modifiers to the measurement cards, capture button, camera toggle, and tab items. Use `.accessibilityElement(children: .combine)` on card containers.

---

## P2 — Medium (good improvements, plan when convenient)

### 8. Magic numbers scattered in views

Font sizes (`48`, `22`, `16`, `14`, `13`, `12`), padding values (`40`, `24`, `12`), and dimensions (`70`, `58`, `44`) are hardcoded throughout the views. Changing the design language requires touching every file.

**Fix:** Create a `DesignConstants` or `Theme` enum with static properties for font sizes, spacing, and component dimensions.

### 9. `CameraPreviewView` doesn't handle layout changes

The `AVCaptureVideoPreviewLayer` frame is set in `makeUIView` and updated in `updateUIView`, but only by reading `uiView.bounds`. On device rotation or multitasking size changes, the layer may not resize correctly because `updateUIView` isn't guaranteed to fire on every geometry change.

**Fix:** Use `layoutSubviews()` override on a custom `UIView` subclass, or use `CALayerDelegate` to keep the preview layer frame in sync with the view's bounds at all times.

### 10. No number formatting / locale handling for displayed values

Lux and Kelvin are formatted with `String(format: "%.0f", value)`. This doesn't add thousands separators (e.g., `10,000` vs `10000`). The spec's UI mockups show comma-separated numbers (`100,000 LUX`, `3,800K`).

**Fix:** Use `NumberFormatter` with `.decimal` style, or SwiftUI's `Text(value, format: .number)` for locale-aware formatting.

### 11. `ComparisonGenerator.rangeIndex` duplicates `LuxInterpreter` boundary logic

Both `LuxInterpreter.interpret` and `ComparisonGenerator.rangeIndex` use the same if/else chain with identical thresholds (10, 100, 200, 500, 1000, 2000, 10000). If a threshold changes, both must be updated in lockstep.

**Fix:** Extract a shared `LuxRange` enum or a single `rangeIndex(for:)` function that both consumers use. This is a DRY concern and a future bug magnet.

### 12. Camera session not stopped when app is backgrounded on non-LUX tabs

`ContentView` listens for `willEnterForeground` / `didEnterBackground` to start/stop the session. But if the user is on the Records or Check tab (placeholder), the camera is still running in the background unnecessarily, draining battery.

**Fix:** Only start the camera session when the selected tab actually needs it (tabs 0 and 1). Stop it when switching to tabs 2 or 3.

---

## P3 — Low (nice-to-have / future-proofing)

### 13. No `Sendable` conformance on pure logic structs

Swift 6 strict concurrency is enabled (`SWIFT_VERSION: "6.0"`). The pure logic structs (`LuxInterpreter`, `KelvinInterpreter`, `ComparisonGenerator`, `InterpretationResult`) are value types with no mutable state, so they're implicitly `Sendable`, but explicit conformance documents intent and prevents accidental regressions.

**Fix:** Add `: Sendable` to `InterpretationResult` and confirm the others remain safe.

### 14. `nonisolated(unsafe)` usage in `CameraManager`

Several properties are marked `nonisolated(unsafe)` to bridge between `@MainActor` isolation and the session queue. This works but bypasses Swift's concurrency safety checks. As the codebase grows, this becomes a data-race risk.

**Fix:** Consider using an `actor`-based design for the session queue work, or isolate the session properties behind a dedicated serial executor.

### 15. No error recovery for camera session failures

If `setupSession()` fails (e.g., device unavailable), `cameraError` is set but there's no retry mechanism. The user must kill and relaunch the app.

**Fix:** Add a "Retry" button in the error state UI, or re-attempt setup when the app returns to foreground.

### 16. Test oracle duplication

Every property-based test in the test suite contains a full copy of the production logic as the "expected" oracle (e.g., `LuxInterpreterTests.expectedResult` is a verbatim copy of `LuxInterpreter.interpret`). If the production code changes, the test oracle must be manually updated in lockstep, which defeats the purpose of an independent oracle.

**Fix:** For property tests, prefer structural invariants over duplicated logic. For example: "the result for lux=X should have a non-empty description", "adjacent boundary values should produce different results", "the result should be one of exactly 8 known values". These are true independent properties.

---

## Questions for you

1. Are you planning to keep the dual build system (SPM + Xcode project) long-term, or will you eventually consolidate to Xcode-only? This affects how aggressively we should clean up `Package.swift`.

2. The spec mentions a Settings screen (gear icon, top-right). None of the current views render it. Is that intentionally deferred, or was it missed during the tab navigation spec?

3. For the flicker detection feature (tab 3), do you have a preferred algorithm or library in mind? That will influence whether we need to restructure `CameraManager`'s sample buffer pipeline now or later.
