# Requirements Document

## Introduction

This spec addresses architectural violations found during code review (CODE-REVIEW.md items P0 #1–#3 and P1 #6–#7). The pure logic layer currently imports platform-specific frameworks (AVFoundation, CoreMedia), breaking the deterministic split. Additionally, a glue-layer view invokes business logic directly, and the product spec's settings gear icon is missing from the UI. This refactor restores the strict pure/effects/glue separation, enables SPM-based testing for all calculators, and adds the settings button placeholder.

## Glossary

- **Pure_Layer**: The deterministic logic layer. Structs with static methods, no framework imports, same inputs always produce same outputs.
- **Effects_Layer**: Thin wrappers around external systems (AVFoundation, CoreMedia). In this project, `CameraManager` is the effects layer.
- **Glue_Layer**: SwiftUI views that wire the Pure_Layer to the Effects_Layer. No business logic or direct external calls allowed.
- **LuxCalculator**: Pure_Layer struct that computes lux from ISO, exposure duration, calibration constant, and aperture.
- **ColorTemperatureCalculator**: Pure_Layer struct that clamps a raw Kelvin value to the valid display range [1000, 15000].
- **CameraManager**: Effects_Layer class that manages the AVCaptureSession and reads hardware metadata (ISO, exposure duration, white balance gains).
- **MeasurementCardView**: Glue_Layer SwiftUI view that displays lux and Kelvin readings in a frosted-glass card.
- **MeasurementView**: Glue_Layer SwiftUI view that hosts the camera preview and MeasurementCardView.
- **SPM_Target**: The Swift Package Manager library target defined in `Package.swift` that compiles pure logic files for cross-platform testing.
- **SPM_Test_Target**: The Swift Package Manager test target defined in `Package.swift` that runs unit tests against the SPM_Target.
- **PlaceholderView**: An existing reusable SwiftUI view that displays a title and subtitle on a black background, used for unimplemented screens.
- **ContentView**: The root Glue_Layer view containing the TabView and app lifecycle hooks.

## Requirements

### Requirement 1: Remove CoreMedia dependency from LuxCalculator

**User Story:** As a developer, I want LuxCalculator to accept plain Double inputs instead of CMTime, so that the pure logic layer has zero platform framework imports and can be tested via SPM without linking CoreMedia.

#### Acceptance Criteria

1. THE LuxCalculator SHALL accept `exposureDurationInSeconds` as a `Double` parameter instead of a `CMTime` parameter.
2. THE LuxCalculator SHALL NOT import CoreMedia or any other platform-specific framework.
3. WHEN `exposureDurationInSeconds` is greater than zero and `iso` is greater than zero, THE LuxCalculator SHALL return `(calibrationConstant * aperture * aperture) / (Double(iso) * exposureDurationInSeconds)`.
4. WHEN `exposureDurationInSeconds` is less than or equal to zero, THE LuxCalculator SHALL return 0.0.
5. WHEN `iso` is less than or equal to zero, THE LuxCalculator SHALL return 0.0.
6. THE LuxCalculator SHALL return a value greater than or equal to 0.0 for all input combinations.
7. FOR ALL valid positive `iso` and `exposureDurationInSeconds` inputs, computing lux then verifying against the formula SHALL produce equivalent results within a relative tolerance of 1e-6 (formula correctness round-trip).

### Requirement 2: Remove AVFoundation dependency from ColorTemperatureCalculator

**User Story:** As a developer, I want ColorTemperatureCalculator to accept a plain Double Kelvin value instead of AVCaptureDevice and WhiteBalanceGains, so that the pure logic layer has zero platform framework imports.

#### Acceptance Criteria

1. THE ColorTemperatureCalculator SHALL NOT import AVFoundation or any other platform-specific framework.
2. THE ColorTemperatureCalculator SHALL expose a `calculateColorTemperature(rawKelvin: Double)` method that clamps the input to the valid range [1000, 15000].
3. WHEN `rawKelvin` is less than 1000.0, THE ColorTemperatureCalculator SHALL return 1000.0.
4. WHEN `rawKelvin` is greater than 15000.0, THE ColorTemperatureCalculator SHALL return 15000.0.
5. WHEN `rawKelvin` is between 1000.0 and 15000.0 inclusive, THE ColorTemperatureCalculator SHALL return the input value unchanged.
6. FOR ALL Double inputs, THE ColorTemperatureCalculator SHALL return a value in the range [1000.0, 15000.0] (clamping invariant).

### Requirement 3: Move platform-specific calls to CameraManager

**User Story:** As a developer, I want CameraManager to perform all platform-specific conversions (CMTimeGetSeconds, device.temperatureAndTintValues) before calling pure logic functions, so that the effects layer is the sole owner of framework dependencies.

#### Acceptance Criteria

1. WHEN a new sample buffer arrives, THE CameraManager SHALL call `CMTimeGetSeconds()` on the device exposure duration and pass the resulting Double to LuxCalculator.
2. WHEN a new sample buffer arrives, THE CameraManager SHALL call `device.temperatureAndTintValues(for:)` on the white balance gains and pass the resulting temperature Double to ColorTemperatureCalculator.
3. THE CameraManager SHALL remain the only source file that imports AVFoundation and CoreMedia for camera-related operations.
4. WHEN LuxCalculator is invoked by CameraManager, THE CameraManager SHALL pass `exposureDurationInSeconds` as a Double value.
5. WHEN ColorTemperatureCalculator is invoked by CameraManager, THE CameraManager SHALL pass `rawKelvin` as a Double value.

### Requirement 4: Sync Package.swift with pure logic files

**User Story:** As a developer, I want Package.swift to include all pure logic source files and their tests, so that `swift test` exercises the full calculator test suite.

#### Acceptance Criteria

1. THE SPM_Target SHALL include `LuxCalculator.swift` in its sources list.
2. THE SPM_Target SHALL include `ColorTemperatureCalculator.swift` in its sources list.
3. THE SPM_Test_Target SHALL include `LuxCalculatorTests.swift` in its sources list.
4. THE SPM_Test_Target SHALL include `ColorTemperatureCalculatorTests.swift` in its sources list.
5. WHEN `swift test` is executed, THE SPM_Test_Target SHALL compile and run without importing CoreMedia or AVFoundation.
6. WHEN `swift test` is executed, THE SPM_Test_Target SHALL execute all LuxCalculator and ColorTemperatureCalculator test cases.

### Requirement 5: Remove business logic from MeasurementCardView

**User Story:** As a developer, I want MeasurementCardView to be a pure display component that receives pre-computed strings, so that the glue layer does not invoke business logic in the rendering path.

#### Acceptance Criteria

1. THE MeasurementCardView SHALL NOT call LuxInterpreter or ComparisonGenerator directly.
2. THE MeasurementCardView SHALL accept pre-computed interpretation description, tip, and comparison strings as parameters.
3. WHEN `isCaptured` is true, THE MeasurementCardView SHALL display the pre-computed description, tip, and comparison strings.
4. WHEN `isCaptured` is false, THE MeasurementCardView SHALL display only the lux and Kelvin numeric readings without interpretation text.
5. THE MeasurementView SHALL call LuxInterpreter and ComparisonGenerator to compute interpretation results before passing them to MeasurementCardView.

### Requirement 6: Add settings button placeholder

**User Story:** As a user, I want to see a settings gear icon in the top-right corner of camera-backed views, so that the UI matches the product specification and provides a navigation path to future settings.

#### Acceptance Criteria

1. THE MeasurementView SHALL display a gear icon button in the top-right corner during live mode.
2. THE TemperatureView SHALL display a gear icon button in the top-right corner.
3. WHEN the gear icon button is tapped, THE Glue_Layer SHALL navigate to a settings PlaceholderView with the title "Settings" and subtitle "Coming Soon".
4. THE settings PlaceholderView SHALL reuse the existing PlaceholderView component.
5. WHEN the user is in captured mode on MeasurementView, THE MeasurementView SHALL hide the gear icon button and display the back arrow instead.

### Requirement 7: Update calculator tests for pure interfaces

**User Story:** As a developer, I want all calculator tests to use plain Double inputs instead of CMTime or AVCaptureDevice, so that the test suite validates the pure interface and runs under SPM without platform dependencies.

#### Acceptance Criteria

1. THE LuxCalculatorTests SHALL pass `exposureDurationInSeconds` as a Double to LuxCalculator instead of constructing CMTime values.
2. THE LuxCalculatorTests SHALL NOT import CoreMedia.
3. THE ColorTemperatureCalculatorTests SHALL test the `calculateColorTemperature(rawKelvin:)` method with Double inputs.
4. THE ColorTemperatureCalculatorTests SHALL NOT import AVFoundation.
5. FOR ALL random positive `iso` (Float in 0.01...10000) and `exposureDurationInSeconds` (Double in 0.00001...30.0), THE LuxCalculator SHALL produce a result matching the formula `(calibrationConstant * aperture²) / (Double(iso) * exposureDurationInSeconds)` within relative tolerance 1e-6 (property-based formula correctness).
6. FOR ALL random `iso` (Float in -1000...10000) and `exposureDurationInSeconds` (Double in -10.0...30.0), THE LuxCalculator SHALL return a value greater than or equal to 0.0 (property-based non-negativity invariant).
7. FOR ALL random `rawKelvin` (Double in -1000...50000), THE ColorTemperatureCalculator SHALL return a value in the range [1000.0, 15000.0] (property-based clamping invariant).
