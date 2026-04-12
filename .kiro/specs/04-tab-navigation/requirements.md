# Requirements Document

## Introduction

This spec adds bottom tab navigation to the Light Meter iOS app, building on the live measurement (spec 01), interpretation (spec 02), and capture-freeze (spec 03) capabilities. The feature introduces a four-tab layout (LUX, Temperature, Check, Records) that provides the structural skeleton for all remaining app features. The LUX tab hosts the existing measurement and capture flow. The Temperature tab provides a dedicated color-temperature-focused view with the live camera background, Kelvin reading, and Kelvin interpretation. The Check and Records tabs are placeholder stubs for future specs (Flicker Detection and Records System). The tab bar is visible in all modes except when the LUX tab is in captured mode, where it is hidden to provide a full-screen frozen-frame experience.

## Glossary

- **App**: The iOS Light Meter application
- **Tab_Bar**: The bottom tab bar providing navigation between the four main sections of the app
- **LUX_Tab**: The first tab, hosting the existing live measurement and capture-freeze flow (MeasurementView)
- **Temperature_Tab**: The second tab, displaying a dedicated color temperature view with live camera background, Kelvin reading, and Kelvin interpretation
- **Check_Tab**: The third tab, reserved for future Flicker Detection functionality; displays a placeholder view in this spec
- **Records_Tab**: The fourth tab, reserved for future Records System functionality; displays a placeholder view in this spec
- **Temperature_View**: The SwiftUI view displayed in the Temperature_Tab, showing the live camera feed background with a frosted-glass card containing the Kelvin reading, color tone label, and recommended environment
- **Camera_Manager**: The existing component that manages the AVCaptureSession, publishes lux and color temperature values, and provides camera control (from specs 01–03)
- **Kelvin_Interpreter**: The existing component that maps a Kelvin value to a color tone label and recommended environment (from spec 02)
- **Camera_Preview**: The live camera feed rendered as the background using CameraPreviewView (from spec 02)

## Requirements

### Requirement 1: Bottom Tab Bar

**User Story:** As a user, I want a bottom tab bar so that I can navigate between the different sections of the app.

#### Acceptance Criteria

1. THE App SHALL display a Tab_Bar at the bottom of the screen with exactly four tabs
2. THE Tab_Bar SHALL display the tabs in the following order from left to right: LUX_Tab, Temperature_Tab, Check_Tab, Records_Tab
3. EACH tab SHALL display an icon and a text label
4. THE LUX_Tab SHALL use a "sun.max" SF Symbol icon and the label "LUX"
5. THE Temperature_Tab SHALL use a "thermometer.medium" SF Symbol icon and the label "Temperature"
6. THE Check_Tab SHALL use a "checkmark.shield" SF Symbol icon and the label "Check"
7. THE Records_Tab SHALL use a "list.clipboard" SF Symbol icon and the label "Records"
8. WHEN the App launches, THE Tab_Bar SHALL select the LUX_Tab by default
9. THE Tab_Bar SHALL use fixed font sizes that are not affected by the system Dynamic Type setting

### Requirement 2: LUX Tab Content

**User Story:** As a user, I want the LUX tab to contain the existing measurement and capture experience, so that the core functionality is preserved within the new navigation structure.

#### Acceptance Criteria

1. WHEN the LUX_Tab is selected, THE App SHALL display the existing MeasurementView with all live measurement, capture, and camera toggle functionality from specs 01–03
2. THE LUX_Tab content SHALL behave identically to the current app experience — live camera preview, measurement card, capture button, camera toggle, frozen frame capture, expanded card, and back arrow
3. WHEN the LUX_Tab is in captured mode (frozen frame displayed), THE Tab_Bar SHALL be hidden to provide a full-screen experience
4. WHEN the user taps the back arrow to return to live mode, THE Tab_Bar SHALL reappear

### Requirement 3: Temperature Tab

**User Story:** As a user, I want a dedicated Temperature tab that shows the color temperature reading with its interpretation on the live camera background, so that I can focus on understanding the color quality of light.

#### Acceptance Criteria

1. WHEN the Temperature_Tab is selected, THE App SHALL display the Temperature_View
2. THE Temperature_View SHALL display the live camera feed as the full-screen background using the existing Camera_Preview component
3. THE Temperature_View SHALL display a frosted-glass card (`.ultraThinMaterial` background with `.cornerRadius(16)`) near the top of the screen
4. THE frosted-glass card SHALL display the current color temperature value with a "K" unit label
5. THE frosted-glass card SHALL display the color tone label from the Kelvin_Interpreter (e.g., "Warm White 💡")
6. THE frosted-glass card SHALL display the recommended environment from the Kelvin_Interpreter (e.g., "Bedrooms, living rooms, relaxation spaces")
7. WHEN new color temperature values are published by Camera_Manager, THE Temperature_View SHALL update the displayed values and interpretation in real time
8. THE Temperature_View SHALL use fixed font sizes that are not affected by the system Dynamic Type setting
9. IF camera permission is denied, THEN THE Temperature_View SHALL display a solid black background with a message indicating camera access is required

### Requirement 4: Check Tab Placeholder

**User Story:** As a user, I want to see the Check tab in the navigation so that I know flicker detection is a planned feature.

#### Acceptance Criteria

1. WHEN the Check_Tab is selected, THE App SHALL display a placeholder view
2. THE placeholder view SHALL display the text "Flicker Detection" as a title
3. THE placeholder view SHALL display the text "Coming Soon" below the title
4. THE placeholder view SHALL use a dark background consistent with the app's visual style

### Requirement 5: Records Tab Placeholder

**User Story:** As a user, I want to see the Records tab in the navigation so that I know measurement history is a planned feature.

#### Acceptance Criteria

1. WHEN the Records_Tab is selected, THE App SHALL display a placeholder view
2. THE placeholder view SHALL display the text "Records" as a title
3. THE placeholder view SHALL display the text "Coming Soon" below the title
4. THE placeholder view SHALL use a dark background consistent with the app's visual style

### Requirement 6: Shared Camera Session

**User Story:** As a developer, I want a single CameraManager instance shared across all tabs, so that the camera session is not duplicated and tab switches are seamless.

#### Acceptance Criteria

1. THE App SHALL create a single CameraManager instance that is shared across all tabs
2. WHEN the user switches between tabs, THE Camera_Manager SHALL continue running the AVCaptureSession without stopping or restarting it
3. WHEN the user switches from the LUX_Tab in captured mode to another tab and back, THE LUX_Tab SHALL return to live mode (captured state is not preserved across tab switches)
4. THE existing app lifecycle management (foreground/background session start/stop) SHALL continue to function correctly with the tab-based layout
