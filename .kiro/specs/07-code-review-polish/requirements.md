# Requirements Document

## Introduction

This spec addresses six remaining items from the LightMeter code review (docs/code-review.md): P1 #7 (accessibility), P2 #8 (magic numbers), P2 #10 (number formatting), P2 #11 (shared lux ranges), P2 #12 (camera session per-tab management), and P3 #13 (explicit Sendable conformance). These are polish and cleanup changes that improve accessibility, maintainability, locale correctness, battery efficiency, and Swift 6 concurrency safety without altering visible measurement behavior.

## Glossary

- **DesignConstants**: A pure-logic enum with static properties that centralizes all hardcoded font sizes, spacing values, and component dimensions used across SwiftUI views.
- **LuxRange**: A shared pure-logic construct (enum or function) that maps a lux value to a zero-based range index using the canonical thresholds (10, 100, 200, 500, 1000, 2000, 10000). Consumed by both LuxInterpreter and ComparisonGenerator.
- **MeasurementCardView**: SwiftUI view that displays lux and kelvin readings with optional expanded interpretation content in captured mode.
- **TemperatureCardView**: SwiftUI view that displays color temperature readings with interpretation description and tip.
- **CameraStateOverlay**: Reusable SwiftUI component that handles permission-denied, camera-error, and live-preview background states.
- **ContentView**: Root SwiftUI view containing the TabView and camera session lifecycle management.
- **CameraViewModel**: Glue-layer ObservableObject that coordinates CameraSessionManager and CameraFrameProvider, exposing published camera state to views.
- **InterpretationResult**: Pure-logic value type holding a description string and a tip string, returned by LuxInterpreter and KelvinInterpreter.
- **LuxInterpreter**: Pure-logic struct that maps a lux value to an InterpretationResult using eight environment ranges.
- **KelvinInterpreter**: Pure-logic struct that maps a Kelvin value to an InterpretationResult using six color tone ranges.
- **ComparisonGenerator**: Pure-logic struct that produces a contextual comparison sentence for a given lux value.
- **VoiceOver**: Apple's built-in screen reader for iOS. Reads accessibility labels, values, and hints aloud to visually impaired users.
- **Sendable**: A Swift protocol indicating a type can be safely transferred across concurrency domains. Required for strict concurrency checking in Swift 6.

## Requirements

### Requirement 1: VoiceOver Accessibility for Measurement Cards

**User Story:** As a visually impaired user, I want the measurement cards to announce lux and kelvin readings with meaningful labels, so that I can understand light conditions through VoiceOver.

#### Acceptance Criteria

1. THE MeasurementCardView SHALL use `.accessibilityElement(children: .combine)` on its card container so VoiceOver treats the card as a single focusable element.
2. THE MeasurementCardView SHALL provide an `.accessibilityLabel` that includes the lux value, the unit "lux", the kelvin value, and the unit "Kelvin".
3. WHEN the card is in captured mode, THE MeasurementCardView SHALL append the interpretation description and comparison text to the accessibility label.
4. THE TemperatureCardView SHALL use `.accessibilityElement(children: .combine)` on its card container so VoiceOver treats the card as a single focusable element.
5. THE TemperatureCardView SHALL provide an `.accessibilityLabel` that includes the kelvin value, the unit "Kelvin", the color tone description, and the recommended environment tip.

### Requirement 2: VoiceOver Accessibility for Interactive Controls

**User Story:** As a visually impaired user, I want buttons and navigation elements to have descriptive accessibility labels and hints, so that I can operate the app through VoiceOver.

#### Acceptance Criteria

1. THE capture button in MeasurementView SHALL have an `.accessibilityLabel` of "Capture" and an `.accessibilityHint` describing that it freezes the current reading.
2. THE camera toggle button in MeasurementView SHALL have an `.accessibilityLabel` of "Switch Camera" and an `.accessibilityHint` describing that it toggles between front and rear cameras.
3. THE back button in MeasurementView captured mode SHALL have an `.accessibilityLabel` of "Back to live mode".
4. THE settings gear icon in MeasurementView SHALL have an `.accessibilityLabel` of "Settings".
5. THE settings gear icon in TemperatureView SHALL have an `.accessibilityLabel` of "Settings".

### Requirement 3: VoiceOver Accessibility for Tab Items

**User Story:** As a visually impaired user, I want each tab in the tab bar to have a clear accessibility label, so that I can navigate between tabs using VoiceOver.

#### Acceptance Criteria

1. THE LUX tab item in ContentView SHALL have an `.accessibilityLabel` of "Lux measurement".
2. THE Temperature tab item in ContentView SHALL have an `.accessibilityLabel` of "Color temperature".
3. THE Check tab item in ContentView SHALL have an `.accessibilityLabel` of "Flicker detection".
4. THE Records tab item in ContentView SHALL have an `.accessibilityLabel` of "Saved records".

### Requirement 4: Extract Hardcoded Values into DesignConstants

**User Story:** As a developer, I want all hardcoded font sizes, padding values, and component dimensions centralized in a single DesignConstants enum, so that changing the design language requires editing one file instead of every view.

#### Acceptance Criteria

1. THE DesignConstants enum SHALL define static properties for all font sizes currently hardcoded in views: 48, 22, 20, 18, 16, 14, 13, and 12.
2. THE DesignConstants enum SHALL define static properties for all padding and spacing values currently hardcoded in views: 40, 24, 12, and 8.
3. THE DesignConstants enum SHALL define static properties for all component dimensions currently hardcoded in views: 70, 58, and 44.
4. THE MeasurementCardView SHALL reference DesignConstants properties instead of hardcoded numeric literals for font sizes, spacing, and dimensions.
5. THE TemperatureCardView SHALL reference DesignConstants properties instead of hardcoded numeric literals for font sizes and spacing.
6. THE MeasurementView SHALL reference DesignConstants properties instead of hardcoded numeric literals for font sizes, padding, and button dimensions.
7. THE PlaceholderView SHALL reference DesignConstants properties instead of hardcoded numeric literals for font sizes and spacing.
8. THE CameraStateOverlay SHALL reference DesignConstants properties instead of hardcoded numeric literals for font sizes.
9. THE DesignConstants enum SHALL reside in the pure-logic layer with no platform framework imports.

### Requirement 5: Locale-Aware Number Formatting

**User Story:** As a user, I want lux and kelvin values displayed with locale-appropriate thousands separators, so that large numbers are readable and match the product spec mockups (e.g., "100,000 LUX", "3,800K").

#### Acceptance Criteria

1. WHEN displaying a lux value, THE MeasurementCardView SHALL format the value using locale-aware formatting that includes thousands separators and zero decimal places.
2. WHEN displaying a kelvin value, THE MeasurementCardView SHALL format the value using locale-aware formatting that includes thousands separators and zero decimal places.
3. WHEN displaying a kelvin value, THE TemperatureCardView SHALL format the value using locale-aware formatting that includes thousands separators and zero decimal places.
4. THE locale-aware formatting SHALL use `NumberFormatter` with `.decimal` style or SwiftUI `Text(value, format: .number)` to respect the device locale.
5. FOR ALL non-negative Double values, formatting then parsing the formatted string SHALL produce a value equal to the original value rounded to zero decimal places (round-trip property).

### Requirement 6: Shared LuxRange for DRY Lux Thresholds

**User Story:** As a developer, I want the lux threshold logic shared between LuxInterpreter and ComparisonGenerator, so that threshold changes are made in one place and both consumers stay in sync.

#### Acceptance Criteria

1. THE LuxRange construct SHALL define a single `rangeIndex(for:)` function that maps a lux value to a zero-based index using thresholds 10, 100, 200, 500, 1000, 2000, and 10000.
2. THE LuxInterpreter SHALL use the shared LuxRange `rangeIndex(for:)` function instead of its own inline if/else threshold chain.
3. THE ComparisonGenerator SHALL use the shared LuxRange `rangeIndex(for:)` function instead of its own private `rangeIndex(for:)` method.
4. FOR ALL non-negative lux values, the shared `rangeIndex(for:)` function SHALL return the same index that the current LuxInterpreter.interpret and ComparisonGenerator.rangeIndex produce for that value.
5. THE LuxRange construct SHALL reside in the pure-logic layer with no platform framework imports.
6. THE LuxRange construct SHALL be included in the SPM target sources in Package.swift.

### Requirement 7: Camera Session Per-Tab Management

**User Story:** As a user, I want the camera session stopped when I switch to non-camera tabs, so that the app conserves battery by not running the camera unnecessarily.

#### Acceptance Criteria

1. WHEN the selected tab changes to tab 0 (LUX) or tab 1 (Temperature), THE ContentView SHALL start the camera session via CameraViewModel.
2. WHEN the selected tab changes to tab 2 (Check) or tab 3 (Records), THE ContentView SHALL stop the camera session via CameraViewModel.
3. WHEN the app returns to the foreground while on tab 0 or tab 1, THE ContentView SHALL start the camera session.
4. WHEN the app returns to the foreground while on tab 2 or tab 3, THE ContentView SHALL NOT start the camera session.
5. WHEN the app enters the background, THE ContentView SHALL stop the camera session regardless of the selected tab.

### Requirement 8: Explicit Sendable Conformance on Pure Logic Types

**User Story:** As a developer, I want explicit Sendable conformance on pure-logic value types, so that concurrency safety intent is documented and regressions are caught by the Swift 6 compiler.

#### Acceptance Criteria

1. THE InterpretationResult struct SHALL explicitly conform to the Sendable protocol.
2. THE LuxInterpreter struct SHALL remain safe for Sendable conformance (no mutable state, no reference-type properties).
3. THE KelvinInterpreter struct SHALL remain safe for Sendable conformance (no mutable state, no reference-type properties).
4. THE ComparisonGenerator struct SHALL remain safe for Sendable conformance (no mutable state, no reference-type properties).
5. THE project SHALL compile without warnings under Swift 6 strict concurrency checking after adding explicit Sendable conformance.
