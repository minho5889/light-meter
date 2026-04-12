# Implementation Plan: Deterministic Split Refactor

## Overview

This plan restores the strict pure/effects/glue separation by removing platform framework imports from calculators, moving hardware-specific conversions into CameraManager, syncing Package.swift, cleaning up MeasurementCardView, and adding the settings gear icon. Tasks 1–3 form an atomic breaking-change set and must be implemented together. Tasks 4–5 update tests to match new signatures. Task 6 syncs SPM. Tasks 7–9 address glue-layer cleanup and UI additions independently.

## Tasks

- [x] 1. Refactor LuxCalculator and ColorTemperatureCalculator to pure interfaces, update CameraManager
  - [x] 1.1 Refactor LuxCalculator to accept plain Double
    - Remove `import CoreMedia` from `LightMeter/LuxCalculator.swift`
    - Rename parameter `exposureDuration: CMTime` to `exposureDurationInSeconds: Double`
    - Remove the internal `CMTimeGetSeconds()` call; use the Double parameter directly
    - Keep the guard clause (`iso > 0, exposureDurationInSeconds > 0`) and formula identical
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [x] 1.2 Refactor ColorTemperatureCalculator to accept plain Double
    - Remove `import AVFoundation` from `LightMeter/ColorTemperatureCalculator.swift`
    - Remove the `calculateColorTemperature(gains:device:)` method entirely
    - Add `static func calculateColorTemperature(rawKelvin: Double) -> Double` that delegates to `clamp()`
    - Keep `clamp()` and constants unchanged
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 1.3 Update CameraManager to perform platform-specific conversions
    - In `captureOutput(_:didOutput:from:)` in `LightMeter/CameraManager.swift`:
      - Extract `let exposureDurationInSeconds = CMTimeGetSeconds(device.exposureDuration)` before calling LuxCalculator
      - Extract `let rawKelvin = Double(device.temperatureAndTintValues(for: gains).temperature)` before calling ColorTemperatureCalculator
      - Call `LuxCalculator.calculateLux(iso: iso, exposureDurationInSeconds: exposureDurationInSeconds)`
      - Call `ColorTemperatureCalculator.calculateColorTemperature(rawKelvin: rawKelvin)`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 2. Update LuxCalculatorTests for pure interface
  - [x] 2.1 Rewrite LuxCalculatorTests to use plain Double inputs
    - Remove `import CoreMedia` from `LightMeterTests/LuxCalculatorTests.swift`
    - Replace all `CMTime` / `CMTimeMake` / `CMTimeMakeWithSeconds` usage with plain `Double` values
    - Update `knownValues()`: use `exposureDurationInSeconds: 0.008` (1/125s) instead of `CMTimeMake(value: 1, timescale: 125)`
    - Update `zeroISO_returnsZero()`, `negativeISO_returnsZero()`, `zeroExposure_returnsZero()`, `veryLargeISO_returnsSmallPositive()` to pass Double exposure values
    - Update `property_luxFormulaCorrectness()`: generate random `exposureSeconds` Double, pass directly to `calculateLux(iso:exposureDurationInSeconds:)`
    - Update `property_luxNonNegativity()`: generate random `exposureSeconds` Double, pass directly
    - _Requirements: 7.1, 7.2, 7.5, 7.6_

  - [x] 2.2 Write property test for lux formula correctness
    - **Property 1: Lux formula correctness**
    - For 100 random positive `iso` (Float 0.01...10000) and `exposureDurationInSeconds` (Double 0.00001...30.0), verify result matches `(calibrationConstant * aperture²) / (Double(iso) * exposureDurationInSeconds)` within relative tolerance 1e-6
    - **Validates: Requirements 1.3, 1.7, 7.5**

  - [x] 2.3 Write property test for lux non-negativity invariant
    - **Property 2: Lux non-negativity invariant**
    - For 100 random `iso` (Float -1000...10000) and `exposureDurationInSeconds` (Double -10.0...30.0), verify result >= 0.0
    - **Validates: Requirements 1.4, 1.5, 1.6, 7.6**

- [x] 3. Update ColorTemperatureCalculatorTests for new method
  - [x] 3.1 Add tests for calculateColorTemperature(rawKelvin:) method
    - Add `calculateColorTemperature_belowMin_returnsMin()` — pass 500.0, expect 1000.0
    - Add `calculateColorTemperature_aboveMax_returnsMax()` — pass 20000.0, expect 15000.0
    - Add `calculateColorTemperature_withinRange_returnsUnchanged()` — pass 5500.0, expect 5500.0
    - Keep all existing `clamp()` unit tests unchanged
    - _Requirements: 7.3, 7.4_

  - [x] 3.2 Write property test for color temperature clamping invariant
    - **Property 3: Color temperature clamping invariant**
    - For 100 random `rawKelvin` (Double -1000...50000), verify `calculateColorTemperature(rawKelvin:)` returns value in [1000.0, 15000.0]
    - **Validates: Requirements 2.2, 2.3, 2.4, 2.6, 7.7**

  - [x] 3.3 Write property test for color temperature identity on in-range values
    - **Property 4: Color temperature identity for in-range values**
    - For 100 random `rawKelvin` (Double 1000.0...15000.0), verify `calculateColorTemperature(rawKelvin:)` returns input unchanged (output == input)
    - **Validates: Requirements 2.5**

- [x] 4. Checkpoint — Verify calculator refactor
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Sync Package.swift with pure logic files
  - Add `"LuxCalculator.swift"` to the SPM target sources list in `Package.swift`
  - Add `"ColorTemperatureCalculator.swift"` to the SPM target sources list in `Package.swift`
  - Add `"LuxCalculatorTests.swift"` to the SPM test target sources list in `Package.swift`
  - Add `"ColorTemperatureCalculatorTests.swift"` to the SPM test target sources list in `Package.swift`
  - Run `swift test` to verify all pure logic tests compile and pass under SPM
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 6. Refactor MeasurementCardView to pure display component
  - Remove inline calls to `LuxInterpreter.interpret(lux:)` and `ComparisonGenerator.generate(lux:)` from `LightMeter/MeasurementCardView.swift`
  - Add parameters `interpretationDescription: String = ""`, `interpretationTip: String = ""`, `comparisonText: String = ""` with empty string defaults
  - In the `isCaptured` block, display the pre-computed `interpretationDescription`, `interpretationTip`, and `comparisonText` strings instead of calling business logic
  - In live mode (`isCaptured == false`), display only lux and Kelvin numeric readings (no interpretation text)
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 7. Update MeasurementView to pre-compute interpretation and add settings gear
  - [x] 7.1 Pre-compute interpretation strings in capture()
    - Add `@State` properties: `capturedInterpretationDescription`, `capturedInterpretationTip`, `capturedComparisonText` (all `String`, default `""`)
    - In `capture()`, call `LuxInterpreter.interpret(lux: capturedLux)` and `ComparisonGenerator.generate(lux: capturedLux)` to populate the state properties
    - Pass the pre-computed strings to `MeasurementCardView` initializer
    - _Requirements: 5.5_

  - [x] 7.2 Add settings gear icon button to MeasurementView
    - Add a gear icon button (SF Symbol `"gearshape"`) in the top-right corner during live mode
    - Hide the gear icon in captured mode (back arrow takes its place)
    - Gear icon navigates to `PlaceholderView(title: "Settings", subtitle: "Coming Soon")`
    - _Requirements: 6.1, 6.3, 6.4, 6.5_

- [ ] 8. Add settings gear icon to TemperatureView
  - Add a gear icon button (SF Symbol `"gearshape"`) in the top-right corner of `LightMeter/TemperatureView.swift`
  - Gear icon navigates to `PlaceholderView(title: "Settings", subtitle: "Coming Soon")`
  - _Requirements: 6.2, 6.3, 6.4_

- [ ] 9. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Tasks 1.1, 1.2, and 1.3 form an atomic breaking-change set — all three must be completed together for the project to compile
- Tasks 2–3 depend on task 1 (tests must match new calculator signatures)
- Task 5 depends on tasks 1–3 (SPM must compile with the refactored pure logic files and updated tests)
- Tasks 6–8 can be done independently of tasks 1–5
- Property tests use `SystemRandomNumberGenerator` with 100+ iteration loops (matching existing codebase pattern)
- After task 5, run `swift test` to verify all pure logic tests pass under SPM
- Each task references specific requirements for traceability
