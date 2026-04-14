# Implementation Plan: Code Review Polish

## Overview

Address six code review items (P1 #7, P2 #8, P2 #10, P2 #11, P2 #12, P3 #13) across the pure logic and glue layers. The implementation proceeds bottom-up: new pure-logic constructs first (`LuxRange`, `DesignConstants`, `Sendable` conformance), then glue-layer view updates (accessibility, locale formatting, DesignConstants refs, per-tab camera management). Each step builds on the previous and wires into existing code incrementally.

## Tasks

- [x] 1. Create LuxRange shared construct and refactor consumers
  - [x] 1.1 Create `LightMeter/LuxRange.swift` with the `LuxRange` enum
    - Define `static let thresholds: [Double]` with canonical values `[10, 100, 200, 500, 1000, 2000, 10000]`
    - Implement `static func rangeIndex(for lux: Double) -> Int` using the if/else chain returning 0–7
    - No framework imports — pure logic only
    - Add `"LuxRange.swift"` to the SPM target sources in `Package.swift`
    - _Requirements: 6.1, 6.5, 6.6_

  - [x] 1.2 Refactor `LuxInterpreter` to use `LuxRange.rangeIndex(for:)`
    - Replace the inline if/else chain with an array lookup keyed by `LuxRange.rangeIndex(for: lux)`
    - Define `private static let results: [InterpretationResult]` array with all 8 entries in index order
    - Public API `interpret(lux:) -> InterpretationResult` remains identical
    - _Requirements: 6.2_

  - [x] 1.3 Refactor `ComparisonGenerator` to use `LuxRange.rangeIndex(for:)`
    - Remove the `private static func rangeIndex(for:)` method
    - Replace its call in `generate(lux:)` with `LuxRange.rangeIndex(for: lux)`
    - Keep the `ranges` array and sentence-building logic unchanged
    - _Requirements: 6.3_

  - [x] 1.4 Write property test for LuxRange equivalence
    - **Property 2: LuxRange equivalence**
    - Generate 150+ random non-negative Doubles in [0, 200_000]
    - Compare `LuxRange.rangeIndex(for:)` against an independent oracle implementing the original if/else chain
    - Assert equality for every generated value
    - Add to `LightMeterTests/LuxRangeTests.swift` and add file to SPM test target sources
    - **Validates: Requirements 6.1, 6.4**

  - [x] 1.5 Write unit tests for LuxRange boundary values
    - Test each threshold boundary: 0, 10, 10.001, 100, 100.001, 200, 200.001, 500, 500.001, 1000, 1000.001, 2000, 2000.001, 10000, 10000.001
    - Test negative lux maps to index 0
    - Add to `LightMeterTests/LuxRangeTests.swift`
    - _Requirements: 6.1, 6.4_

- [x] 2. Checkpoint — Verify LuxRange refactor
  - Run `swift test` to ensure all existing tests (`LuxInterpreterTests`, `ComparisonGeneratorTests`, etc.) still pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Create DesignConstants and add Sendable conformance
  - [x] 3.1 Create `LightMeter/DesignConstants.swift` with the `DesignConstants` enum
    - Define static properties for font sizes: `fontSizeXXL` (48), `fontSizeXL` (22), `fontSizeLG` (20), `fontSizeMD` (18), `fontSizeSM` (16), `fontSizeXS` (14), `fontSizeXXS` (13), `fontSizeXXXS` (12)
    - Define static properties for spacing: `spacingLG` (40), `spacingMD` (24), `spacingSM` (12), `spacingXS` (8)
    - Define static properties for dimensions: `captureButtonOuter` (70), `captureButtonInner` (58), `toggleButtonSize` (44)
    - Use `CGFloat` type for all properties; no platform framework imports
    - Add `"DesignConstants.swift"` to the SPM target sources in `Package.swift`
    - _Requirements: 4.1, 4.2, 4.3, 4.9_

  - [x] 3.2 Add explicit `Sendable` conformance to `InterpretationResult`
    - Change declaration to `struct InterpretationResult: Equatable, Sendable`
    - Verify `LuxInterpreter`, `KelvinInterpreter`, and `ComparisonGenerator` remain safe for Sendable (no mutable state, no reference-type properties — no code changes needed, just verify)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 4. Update views with DesignConstants references
  - [x] 4.1 Update `MeasurementCardView` to use DesignConstants
    - Replace hardcoded font sizes (48, 20, 14, 13, 12) with corresponding `DesignConstants` properties
    - Replace hardcoded spacing (8) with `DesignConstants.spacingXS`
    - _Requirements: 4.4_

  - [x] 4.2 Update `TemperatureCardView` to use DesignConstants
    - Replace hardcoded font sizes (48, 18, 14) with corresponding `DesignConstants` properties
    - Replace hardcoded spacing (8) with `DesignConstants.spacingXS`
    - _Requirements: 4.5_

  - [x] 4.3 Update `MeasurementView` to use DesignConstants
    - Replace hardcoded font sizes (22), padding (12, 24, 40), and button dimensions (70, 58, 44) with `DesignConstants` properties
    - _Requirements: 4.6_

  - [x] 4.4 Update `PlaceholderView` to use DesignConstants
    - Replace hardcoded font sizes (24, 16) and spacing (12) with `DesignConstants` properties
    - Note: 24 is not in DesignConstants — use `DesignConstants.spacingMD` (24) for spacing; for the 24pt font, add or use the closest match
    - _Requirements: 4.7_

  - [x] 4.5 Update `CameraStateOverlay` to use DesignConstants
    - Replace hardcoded font size (16) with `DesignConstants.fontSizeSM`
    - _Requirements: 4.8_

- [x] 5. Add locale-aware number formatting to card views
  - [x] 5.1 Add locale-aware formatting to `MeasurementCardView`
    - Replace `String(format: "%.0f", lux)` and `String(format: "%.0f", kelvin)` with `NumberFormatter` using `.decimal` style and `maximumFractionDigits = 0`
    - Create a private static helper or computed property for the formatter
    - _Requirements: 5.1, 5.2, 5.4_

  - [x] 5.2 Add locale-aware formatting to `TemperatureCardView`
    - Replace `String(format: "%.0f", kelvin)` with the same locale-aware `NumberFormatter` approach
    - _Requirements: 5.3, 5.4_

  - [x] 5.3 Write property test for number formatting round-trip
    - **Property 1: Number formatting round-trip**
    - Generate 150+ random non-negative Doubles in [0, 200_000]
    - Format with `NumberFormatter(.decimal, maximumFractionDigits: 0)` using fixed `Locale(identifier: "en_US")`
    - Parse the formatted string back to a Double
    - Assert equality with the original value rounded to zero decimal places
    - Add to `LightMeterTests/NumberFormattingTests.swift` and add file to SPM test target sources
    - **Validates: Requirements 5.5**

- [x] 6. Checkpoint — Verify DesignConstants and formatting
  - Build the project to confirm all DesignConstants references resolve and locale formatting compiles
  - Run `swift test` to ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Add VoiceOver accessibility modifiers
  - [x] 7.1 Add accessibility to `MeasurementCardView`
    - Add `.accessibilityElement(children: .combine)` on the outer VStack
    - Add `.accessibilityLabel` including lux value, "lux", kelvin value, "Kelvin"
    - When `isCaptured`, append interpretation description and comparison text to the label
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 7.2 Add accessibility to `TemperatureCardView`
    - Add `.accessibilityElement(children: .combine)` on the outer VStack
    - Add `.accessibilityLabel` including kelvin value, "Kelvin", description, and tip
    - _Requirements: 1.4, 1.5_

  - [x] 7.3 Add accessibility to `MeasurementView` interactive controls
    - Add `.accessibilityLabel("Capture")` and `.accessibilityHint("Freezes the current light reading")` on the capture button
    - Add `.accessibilityLabel("Switch Camera")` and `.accessibilityHint("Toggles between front and rear cameras")` on the camera toggle button
    - Add `.accessibilityLabel("Back to live mode")` on the back arrow button
    - Add `.accessibilityLabel("Settings")` on the settings gear icon NavigationLink
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 7.4 Add accessibility to `TemperatureView` settings icon
    - Add `.accessibilityLabel("Settings")` on the gear icon NavigationLink
    - _Requirements: 2.5_

  - [x] 7.5 Add accessibility labels to tab items in `ContentView`
    - Add `.accessibilityLabel("Lux measurement")` on tab 0
    - Add `.accessibilityLabel("Color temperature")` on tab 1
    - Add `.accessibilityLabel("Flicker detection")` on tab 2
    - Add `.accessibilityLabel("Saved records")` on tab 3
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [~] 8. Implement per-tab camera session management in ContentView
  - Add `.onChange(of: selectedTab)` handler: call `cameraViewModel.startSession()` for tabs 0/1, call `cameraViewModel.stopSession()` for tabs 2/3
  - Modify the `willEnterForeground` handler to only call `startSession()` when `selectedTab` is 0 or 1
  - Keep the `didEnterBackground` handler stopping the session unconditionally
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 9. Final checkpoint — Full verification
  - Run `swift build` to verify the project compiles without warnings under Swift 6 strict concurrency
  - Run `swift test` to verify all existing and new tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation after each major change group
- Property tests validate universal correctness properties from the design document
- All existing test suites must continue to pass after each refactoring step
