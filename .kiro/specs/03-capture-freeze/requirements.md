# Requirements Document

## Introduction

This spec adds the Capture & Freeze feature to the Light Meter iOS app, building on the live measurement and interpretation capabilities from specs 01 and 02. The feature introduces three core behaviors: (1) a capture button that freezes the camera feed as a still image and expands the measurement card with interpretation details and a contextual comparison sentence, (2) a camera toggle that switches between front and rear cameras, and (3) a frosted-glass card UI that adapts between a compact live mode and an expanded captured mode. The contextual comparison is a pure function that generates a sentence comparing the captured lux value to adjacent environment ranges.

## Glossary

- **App**: The iOS Light Meter application
- **Capture_Button**: The round button at the bottom of the screen that triggers the capture action, freezing the camera feed and expanding the measurement card
- **Camera_Toggle**: The button adjacent to the Capture_Button that switches the active camera between front and rear positions
- **Frozen_Frame**: A still image captured from the live camera feed at the moment the user taps the Capture_Button, displayed as the full-screen background in captured mode
- **Live_Mode**: The default app state where the camera feed streams in real time and the measurement card shows compact readings
- **Captured_Mode**: The app state entered after tapping the Capture_Button, where the background is a Frozen_Frame and the measurement card is expanded with interpretation details
- **Back_Arrow**: A navigation element displayed in Captured_Mode that returns the app to Live_Mode when tapped
- **Measurement_Card**: The frosted-glass card floating near the top of the screen that displays lux and Kelvin readings, and expands in Captured_Mode to include interpretation and contextual comparison
- **Contextual_Comparison**: A sentence generated from the captured lux value that compares the current environment to adjacent lux ranges (e.g., "Brighter than a movie theater but darker than a living room")
- **Comparison_Generator**: The pure function component that accepts a lux value and returns the Contextual_Comparison sentence
- **Camera_Manager**: The existing component that manages the AVCaptureSession, publishes lux and color temperature values, and provides camera control (from specs 01 and 02)
- **Lux_Interpreter**: The existing component that maps a lux value to an environment description and user guide tip (from spec 02)
- **Kelvin_Interpreter**: The existing component that maps a Kelvin value to a color tone label and recommended environment (from spec 02)
- **Lux_Range**: A contiguous range of lux values associated with a specific environment description, as defined in the product specification

## Requirements

### Requirement 1: Capture Button and Mode Transition

**User Story:** As a user, I want to tap a capture button to freeze the current camera view and see detailed interpretation of my light readings, so that I can study the measurement without the image changing.

#### Acceptance Criteria

1. THE App SHALL display a round Capture_Button at the bottom center of the screen in Live_Mode
2. WHEN the user taps the Capture_Button in Live_Mode, THE App SHALL transition from Live_Mode to Captured_Mode
3. WHEN the App transitions to Captured_Mode, THE Camera_Manager SHALL capture the current camera frame as a Frozen_Frame still image
4. WHILE the App is in Captured_Mode, THE App SHALL display the Frozen_Frame as the full-screen background instead of the live camera feed
5. WHILE the App is in Captured_Mode, THE App SHALL hide the Capture_Button and the Camera_Toggle
6. WHEN the App transitions to Captured_Mode, THE App SHALL display a Back_Arrow in the top-left area of the screen
7. WHEN the user taps the Back_Arrow, THE App SHALL transition from Captured_Mode back to Live_Mode with the live camera feed resumed
8. WHEN the App returns to Live_Mode, THE App SHALL remove the Back_Arrow and restore the Capture_Button and Camera_Toggle

### Requirement 2: Frozen Frame Capture

**User Story:** As a user, I want the camera background to freeze as a still photo when I capture, so that the image stops moving and I can focus on the readings.

#### Acceptance Criteria

1. WHEN a capture is requested, THE Camera_Manager SHALL produce a Frozen_Frame from the current AVCaptureSession video output as a UIImage
2. THE Camera_Manager SHALL produce the Frozen_Frame without interrupting the AVCaptureSession so that resuming Live_Mode does not require session reconfiguration
3. WHILE the App is in Captured_Mode, THE App SHALL display the Frozen_Frame as a static full-screen image with aspect-fill scaling and no black bars
4. IF the camera frame capture fails, THEN THE App SHALL remain in Live_Mode and display no error to the user

### Requirement 3: Camera Toggle

**User Story:** As a user, I want to switch between the front and rear cameras, so that I can measure light from different directions.

#### Acceptance Criteria

1. THE App SHALL display a Camera_Toggle button adjacent to the Capture_Button in Live_Mode
2. WHEN the user taps the Camera_Toggle, THE Camera_Manager SHALL switch the active camera input between the front-facing and rear-facing cameras
3. WHEN the camera input switches, THE Camera_Manager SHALL continue publishing lux and color temperature values from the newly active camera
4. WHEN the camera input switches, THE App SHALL update the live camera preview to show the feed from the newly active camera
5. IF the target camera is not available on the device, THEN THE Camera_Manager SHALL retain the current camera input and publish no error

### Requirement 4: Measurement Card — Live Mode (Compact)

**User Story:** As a user, I want to see my current lux and Kelvin readings in a compact frosted-glass card while in live mode, so that I can monitor light levels at a glance.

#### Acceptance Criteria

1. WHILE the App is in Live_Mode, THE Measurement_Card SHALL display the current color temperature value with a "K" unit label
2. WHILE the App is in Live_Mode, THE Measurement_Card SHALL display the current lux value with a "LUX" unit label in prominent text
3. THE Measurement_Card SHALL use a frosted-glass visual effect (translucent blur material) as its background
4. THE Measurement_Card SHALL be positioned near the top of the screen, floating above the camera preview
5. THE Measurement_Card SHALL use fixed font sizes that are not affected by the system Dynamic Type setting
6. WHEN new lux or color temperature values are published by Camera_Manager, THE Measurement_Card SHALL update the displayed values in real time

### Requirement 5: Measurement Card — Captured Mode (Expanded)

**User Story:** As a user, I want the measurement card to expand after capture to show the environment description, user guide tip, and a contextual comparison, so that I can understand what the light level means.

#### Acceptance Criteria

1. WHEN the App transitions to Captured_Mode, THE Measurement_Card SHALL expand to display additional interpretation content below the lux and Kelvin readings
2. THE expanded Measurement_Card SHALL display a visual divider separating the readings from the interpretation section
3. THE expanded Measurement_Card SHALL display a "User Guide" label below the divider
4. THE expanded Measurement_Card SHALL display the lux environment description and user guide tip from the Lux_Interpreter below the "User Guide" label
5. THE expanded Measurement_Card SHALL display the Contextual_Comparison sentence below the user guide tip
6. WHILE the App is in Captured_Mode, THE Measurement_Card SHALL display the lux and Kelvin values that were captured at the moment of capture, not live-updating values
7. THE expanded Measurement_Card SHALL maintain the frosted-glass visual effect

### Requirement 6: Contextual Comparison Generation

**User Story:** As a user, I want to see a sentence comparing my captured lux level to familiar environments, so that I can intuitively understand the brightness.

#### Acceptance Criteria

1. WHEN a lux value is provided, THE Comparison_Generator SHALL return a Contextual_Comparison sentence comparing the lux value to adjacent Lux_Range environments
2. WHEN the lux value falls within a range that has both a lower and an upper adjacent range, THE Comparison_Generator SHALL produce a sentence in the form "Brighter than [lower range environment] but darker than [upper range environment]"
3. WHEN the lux value falls within the lowest Lux_Range (0–10), THE Comparison_Generator SHALL produce a sentence referencing only the upper adjacent range (e.g., "Darker than [upper range environment]")
4. WHEN the lux value falls within the highest Lux_Range (10,001+), THE Comparison_Generator SHALL produce a sentence referencing only the lower adjacent range (e.g., "Brighter than [lower range environment]")
5. THE Comparison_Generator SHALL accept a Double input and return a String
6. THE Comparison_Generator SHALL use the environment descriptions from the 8 Lux_Range definitions as comparison references
7. FOR ALL valid lux values, THE Comparison_Generator SHALL produce a non-empty Contextual_Comparison string
8. THE Comparison_Generator SHALL be a pure function with no dependencies on platform-specific frameworks
