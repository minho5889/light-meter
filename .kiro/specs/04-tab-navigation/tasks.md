# Implementation Plan: Tab Navigation

## Overview

Add a four-tab navigation structure following the deterministic-split pattern. No new pure logic is needed — this spec is entirely glue layer (SwiftUI views). The Temperature tab reuses existing `KelvinInterpreter` and `CameraPreviewView`. Placeholder views stub out Check and Records tabs. The existing `MeasurementView` gets minor modifications for tab bar visibility and state reset.

## Tasks

- [x] 1. Create TemperatureCardView and TemperatureView
  - [x] 1.1 Create `TemperatureCardView` with Kelvin reading and interpretation
    - Create `LightMeter/TemperatureCardView.swift` accepting `kelvin: Double`
    - Display the Kelvin value in large monospaced text with a "K" unit label
    - Add a `Divider` below the reading
    - Display the color tone label from `KelvinInterpreter.interpret(kelvin:).description` (e.g., "Warm White 💡")
    - Display the recommended environment from `KelvinInterpreter.interpret(kelvin:).tip` (e.g., "Bedrooms, living rooms, relaxation spaces")
    - Use frosted-glass background (`.ultraThinMaterial`), `.cornerRadius(16)`, white foreground color
    - Use fixed font sizes (`.system(size: N)`) — no Dynamic Type
    - _Requirements: 3.3, 3.4, 3.5, 3.6, 3.8_

  - [x] 1.2 Create `TemperatureView` with live camera background and temperature card
    - Create `LightMeter/TemperatureView.swift` accepting `@ObservedObject var cameraManager: CameraManager`
    - Display `CameraPreviewView(session: cameraManager.session)` as the full-screen background when `permissionGranted` is true
    - Display `Color.black` with a permission-required message when `permissionGranted` is false
    - Overlay `TemperatureCardView(kelvin: cameraManager.colorTemperature)` near the top of the screen
    - Values update in real time as `CameraManager` publishes new color temperature readings
    - _Requirements: 3.1, 3.2, 3.7, 3.9_

- [x] 2. Create PlaceholderView for stub tabs
  - [x] 2.1 Create `PlaceholderView` as a reusable stub view
    - Create `LightMeter/PlaceholderView.swift` accepting `title: String` and `subtitle: String`
    - Display the title in bold white text and the subtitle in gray text, centered on a black background
    - Use fixed font sizes and `Color.black.ignoresSafeArea()` for the background
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [x] 3. Refactor ContentView to use TabView
  - [x] 3.1 Replace single-view layout with a four-tab `TabView` in `ContentView`
    - Add `@State private var selectedTab: Int = 0` to `ContentView`
    - Wrap the view body in a `TabView(selection: $selectedTab)` with four tabs
    - Tab 0 (LUX): `MeasurementView(cameraManager: cameraManager)` with `Image(systemName: "sun.max")` and `Text("LUX")`
    - Tab 1 (Temperature): `TemperatureView(cameraManager: cameraManager)` with `Image(systemName: "thermometer.medium")` and `Text("Temperature")`
    - Tab 2 (Check): `PlaceholderView(title: "Flicker Detection", subtitle: "Coming Soon")` with `Image(systemName: "checkmark.shield")` and `Text("Check")`
    - Tab 3 (Records): `PlaceholderView(title: "Records", subtitle: "Coming Soon")` with `Image(systemName: "list.clipboard")` and `Text("Records")`
    - Keep existing `.onAppear` (requestPermission), foreground/background lifecycle handlers at the `TabView` level
    - LUX tab is selected by default (selectedTab = 0)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 2.1, 2.2, 6.1, 6.4_

- [x] 4. Modify MeasurementView for tab bar integration
  - [x] 4.1 Hide tab bar in captured mode and reset state on tab switch
    - Add `.toolbar(isCaptured ? .hidden : .visible, for: .tabBar)` to the `MeasurementView` root `ZStack`
    - Add `.onDisappear { if isCaptured { returnToLiveMode() } }` to reset captured state when the user switches away from the LUX tab
    - Verify that the capture button, camera toggle, back arrow, and frozen frame behavior remain unchanged
    - _Requirements: 2.3, 2.4, 6.3_

- [x] 5. Final checkpoint — Verify project compiles and all tests pass
  - Ensure all existing tests still pass (ComparisonGenerator, LuxInterpreter, KelvinInterpreter, LuxCalculator, ColorTemperatureCalculator)
  - Verify the tab bar displays four tabs with correct icons and labels
  - Verify the LUX tab preserves all existing capture-freeze behavior
  - Verify the Temperature tab shows live Kelvin reading with interpretation
  - Verify Check and Records tabs show placeholder content
  - Ask the user if questions arise.

## Notes

- This spec introduces no new pure logic — it is entirely glue layer (SwiftUI views)
- No new tests are needed since there is no new business logic; existing tests validate the interpreters and generators that the new views consume
- `TemperatureCardView` and `TemperatureView` follow the same patterns as `MeasurementCardView` and `MeasurementView`
- The `CameraManager` is unchanged — a single instance is shared across tabs via `@StateObject` in `ContentView`
- `PlaceholderView` is intentionally minimal; it will be replaced by real implementations in future specs (flicker detection, records system)
- The tab bar hiding in captured mode uses SwiftUI's `.toolbar` modifier, which requires iOS 16+ (already the deployment target)
