# Requirements Document

## Introduction

This spec adds lux range interpretation, color temperature interpretation, and a live camera preview background to the Light Meter iOS app. Building on the spec 01 skeleton (which provides raw lux and Kelvin readings), this spec enriches the user experience by translating raw numbers into human-readable environment descriptions and actionable tips, and by replacing the static black background with the live camera feed. The interpretation tables are derived from the product specification's reference data.

## Glossary

- **App**: The iOS Light Meter application
- **Lux_Interpreter**: The component that maps a lux value to an environment description and a user guide tip based on predefined lux ranges
- **Kelvin_Interpreter**: The component that maps a color temperature value in Kelvin to a color tone label (with emoji) and a recommended environment description based on predefined Kelvin ranges
- **Camera_Preview**: The live camera feed rendered as the real-time background of the app using AVCaptureVideoPreviewLayer or an equivalent SwiftUI wrapper
- **Camera_Manager**: The existing component that manages the AVCaptureSession and publishes lux and color temperature values (from spec 01)
- **Measurement_View**: The SwiftUI view that displays lux, color temperature, and their interpretations overlaid on the camera preview
- **Lux_Range**: A contiguous range of lux values associated with a specific environment description and user guide tip
- **Kelvin_Range**: A contiguous range of Kelvin values associated with a specific color tone and recommended environment
- **Interpretation_Result**: A data structure containing a descriptive label and an actionable tip or recommendation string

## Requirements

### Requirement 1: Lux Range Interpretation

**User Story:** As a user, I want to see a description of my environment and an actionable tip based on the current lux reading, so that I can understand what the brightness level means in practical terms.

#### Acceptance Criteria

1. WHEN a lux value is provided, THE Lux_Interpreter SHALL return the environment description and user guide tip corresponding to the matching Lux_Range
2. THE Lux_Interpreter SHALL support the following Lux_Range definitions:
   - 0–10: "Very dark outdoors, full moon night" / "Pre-sleep conditions. Be careful when moving around."
   - 11–100: "Hallways, bathrooms, storage rooms, movie theaters" / "Suitable for passing through. Not appropriate for extended work."
   - 101–200: "Living room relaxation, dining, hotel rooms" / "Optimal for comfortable rest. Good for watching TV."
   - 201–500: "General office work, kitchen cooking, light reading" / "The most standard brightness for daily activities and office work."
   - 501–1,000: "Focused studying, precision handwork, store displays" / "Recommended for study rooms or detailed tasks like sewing."
   - 1,001–2,000: "Bright window (indoors), broadcast studios, operating rooms" / "Very bright. Suitable for video production or professional work."
   - 2,001–10,000: "Cloudy day outdoors, sunset outdoors" / "Good for outdoor activities. Partial shade level for plants."
   - 10,001+: "Direct sunlight on a clear day, noon outdoors" / "Strong sunlight. Protect your eyes and watch for plant burns."
3. THE Lux_Interpreter SHALL accept a Double input and return an Interpretation_Result containing the environment description and user guide tip
4. THE Lux_Interpreter SHALL cover the full non-negative lux range with no gaps between Lux_Range boundaries
5. IF a negative lux value is provided, THEN THE Lux_Interpreter SHALL return the result for the 0–10 range as a safe fallback

### Requirement 2: Color Temperature Interpretation

**User Story:** As a user, I want to see the color tone and recommended environment based on the current Kelvin reading, so that I can understand the quality of light around me.

#### Acceptance Criteria

1. WHEN a Kelvin value is provided, THE Kelvin_Interpreter SHALL return the color tone label and recommended environment corresponding to the matching Kelvin_Range
2. THE Kelvin_Interpreter SHALL support the following Kelvin_Range definitions:
   - Below 2,000K: "Candlelight / Sunset 🔥" / "Psychological calm, pre-sleep, atmospheric cafes"
   - 2,000K–3,499K: "Warm White 💡" / "Bedrooms, living rooms, relaxation spaces"
   - 3,500K–4,999K: "Natural White 🌤" / "Kitchens, dressing rooms, bathrooms"
   - 5,000K–6,499K: "Daylight 📖" / "Study rooms, offices, precision work (improves focus)"
   - 6,500K–9,999K: "Cool White ❄" / "Hospitals, factories, warehouses"
   - 10,000K+: "Blue Sky 🧊" / "Clear day shade, specialized lab environments"
3. THE Kelvin_Interpreter SHALL accept a Double input and return an Interpretation_Result containing the color tone label and recommended environment
4. THE Kelvin_Interpreter SHALL cover the full Kelvin range from the Camera_Manager output range (1,000K to 15,000K) with no gaps between Kelvin_Range boundaries
5. IF a Kelvin value below 1,000 is provided, THEN THE Kelvin_Interpreter SHALL return the result for the "Below 2,000K" range as a safe fallback

### Requirement 3: Live Camera Preview Background

**User Story:** As a user, I want to see the live camera feed as the app background, so that I can see what the camera is pointing at while reading the light measurements.

#### Acceptance Criteria

1. WHEN camera permission is granted and the AVCaptureSession is running, THE Camera_Preview SHALL render the live camera feed as the full-screen background of the App
2. THE Camera_Preview SHALL use AVCaptureVideoPreviewLayer (or an equivalent UIViewRepresentable wrapper) connected to the existing AVCaptureSession from Camera_Manager
3. THE Camera_Preview SHALL fill the entire screen using aspect-fill scaling so that no black bars appear
4. THE Camera_Preview SHALL update in real time at the camera frame rate
5. WHEN the App enters the background, THE Camera_Preview SHALL stop rendering the camera feed
6. WHEN the App returns to the foreground, THE Camera_Preview SHALL resume rendering the camera feed
7. IF camera permission is denied, THEN THE Camera_Preview SHALL display a solid black background as a fallback

### Requirement 4: Measurement Display with Interpretation Overlay

**User Story:** As a user, I want to see the lux and Kelvin readings along with their interpretations overlaid on the live camera preview, so that I can understand my environment at a glance.

#### Acceptance Criteria

1. THE Measurement_View SHALL display the current lux value, the lux environment description, and the lux user guide tip
2. THE Measurement_View SHALL display the current color temperature value, the color tone label, and the recommended environment
3. WHEN new lux or color temperature values are published by Camera_Manager, THE Measurement_View SHALL update the displayed interpretation text in real time
4. THE Measurement_View SHALL render all text with sufficient contrast against the live camera preview background (white text with a dark shadow or semi-transparent backdrop)
5. THE Measurement_View SHALL use fixed font sizes that are not affected by the system Dynamic Type setting to preserve layout stability
6. THE Measurement_View SHALL render the interpretation text below the corresponding raw numeric value

### Requirement 5: Camera_Manager Preview Session Access

**User Story:** As a developer, I want the Camera_Manager to expose its AVCaptureSession, so that the Camera_Preview can connect to the session for rendering the live feed.

#### Acceptance Criteria

1. THE Camera_Manager SHALL expose the AVCaptureSession as a readable property so that Camera_Preview can connect an AVCaptureVideoPreviewLayer to the session
2. THE Camera_Manager SHALL maintain the existing lux and color temperature publishing behavior from spec 01 without modification
3. WHEN the AVCaptureSession is not yet configured, THE Camera_Manager SHALL provide a session object that Camera_Preview can safely reference without crashing

