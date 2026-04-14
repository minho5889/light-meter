# Requirements Document

## Introduction

This spec addresses three P1 items from the LightMeter code review (CODE-REVIEW.md items #4, #5, #6). The goal is to refactor the UI architecture by splitting the monolithic `CameraManager`, extracting duplicated permission/error UI into a shared component, and making `TemperatureCardView` a pure display component. These changes enforce the deterministic split (pure logic / effects / glue) and prepare the codebase for the planned Flicker Detection tab.

## Glossary

- **CameraSessionManager**: Effects-layer class responsible for AVCaptureSession lifecycle — input/output setup, start, stop, and camera toggling.
- **CameraFrameProvider**: Effects-layer class that acts as the AVCaptureVideoDataOutputSampleBufferDelegate, stores the latest sample buffer, provides frame capture, and dispatches computed lux and color temperature values.
- **CameraViewModel**: Glue-layer ObservableObject that holds `@Published` properties (lux, colorTemperature, permissionGranted, cameraError, currentCameraPosition) observed by SwiftUI views. Coordinates between CameraSessionManager and CameraFrameProvider.
- **CameraStateOverlay**: Reusable SwiftUI component that handles the permission-denied, camera-error, and live-preview background states in a single place.
- **TemperatureCardView**: SwiftUI view that displays color temperature readings. Must be a pure display component receiving pre-computed strings.
- **MeasurementView**: SwiftUI glue-layer view for the LUX measurement tab.
- **TemperatureView**: SwiftUI glue-layer view for the color temperature tab.
- **Deterministic_Split**: Architectural rule requiring business logic in pure structs, external system access in effects classes, and wiring in glue views with no business logic or direct external calls.

## Requirements

### Requirement 1: Split CameraManager into CameraSessionManager

**User Story:** As a developer, I want camera session lifecycle management isolated in its own class, so that the effects layer follows single-responsibility and is easier to maintain and test.

#### Acceptance Criteria

1. THE CameraSessionManager SHALL manage AVCaptureSession configuration, input setup, and output setup.
2. THE CameraSessionManager SHALL provide methods to start and stop the capture session.
3. THE CameraSessionManager SHALL provide a method to toggle between front and rear cameras.
4. THE CameraSessionManager SHALL expose the AVCaptureSession instance for use by CameraPreviewView.
5. IF the requested camera device is unavailable, THEN THE CameraSessionManager SHALL retain the current camera input without crashing.
6. IF session configuration fails, THEN THE CameraSessionManager SHALL report the error through a callback or published property.

### Requirement 2: Split CameraManager into CameraFrameProvider

**User Story:** As a developer, I want sample buffer delegation and frame capture isolated in their own class, so that frame processing concerns are separated from session lifecycle.

#### Acceptance Criteria

1. THE CameraFrameProvider SHALL act as the AVCaptureVideoDataOutputSampleBufferDelegate.
2. THE CameraFrameProvider SHALL store the latest CMSampleBuffer received from the capture session.
3. WHEN a new sample buffer is received, THE CameraFrameProvider SHALL compute lux using LuxCalculator and color temperature using ColorTemperatureCalculator, passing only primitive values (Double) to the pure-logic layer.
4. THE CameraFrameProvider SHALL provide a method to capture the current frame as a UIImage.
5. IF no sample buffer is available, THEN THE CameraFrameProvider SHALL return nil from the frame capture method.

### Requirement 3: Create CameraViewModel as the Glue-Layer Observable

**User Story:** As a developer, I want a lightweight view model that holds all published camera state, so that SwiftUI views observe a single source of truth without depending on effects-layer classes directly.

#### Acceptance Criteria

1. THE CameraViewModel SHALL be an ObservableObject exposing @Published properties for lux, colorTemperature, permissionGranted, cameraError, and currentCameraPosition.
2. THE CameraViewModel SHALL coordinate between CameraSessionManager and CameraFrameProvider, forwarding state updates to its published properties.
3. THE CameraViewModel SHALL provide a method to request camera permission and initiate session setup upon grant.
4. THE CameraViewModel SHALL provide methods to start the session, stop the session, toggle the camera, and capture a frame.
5. THE CameraViewModel SHALL NOT contain business logic — interpretation and comparison generation remain in the pure-logic layer, invoked by the calling view at capture time.

### Requirement 4: Extract CameraStateOverlay for Shared Permission/Error UI

**User Story:** As a developer, I want a single reusable component for camera permission and error states, so that adding new camera-backed tabs does not duplicate UI code.

#### Acceptance Criteria

1. THE CameraStateOverlay SHALL display the live camera preview background WHEN permission is granted and no error exists.
2. WHEN permission is not granted, THE CameraStateOverlay SHALL display a message instructing the user to enable camera access in Settings.
3. WHEN a camera error exists, THE CameraStateOverlay SHALL display the error message in red text.
4. THE MeasurementView SHALL use CameraStateOverlay instead of inline permission and error handling blocks.
5. THE TemperatureView SHALL use CameraStateOverlay instead of inline permission and error handling blocks.
6. WHEN a new camera-backed tab is added, THE CameraStateOverlay SHALL be reusable without duplicating permission or error UI code.

### Requirement 5: Make TemperatureCardView a Pure Display Component

**User Story:** As a developer, I want TemperatureCardView to receive pre-computed display strings, so that the card contains no business logic and conforms to the deterministic split.

#### Acceptance Criteria

1. THE TemperatureCardView SHALL accept pre-computed interpretation description and tip strings as input properties.
2. THE TemperatureCardView SHALL NOT call KelvinInterpreter or any other business-logic function directly.
3. THE TemperatureView SHALL pre-compute the interpretation result by calling KelvinInterpreter.interpret(kelvin:) and pass the resolved description and tip strings to TemperatureCardView.
4. FOR ALL valid kelvin values, the interpretation strings displayed by TemperatureCardView SHALL match the output of KelvinInterpreter.interpret(kelvin:) as computed by TemperatureView.

### Requirement 6: Preserve Existing Behavior After Refactor

**User Story:** As a user, I want the app to behave identically after the refactor, so that no visible functionality is lost or changed.

#### Acceptance Criteria

1. WHEN the app launches, THE CameraViewModel SHALL request camera permission and start the session upon grant, matching current CameraManager behavior.
2. WHEN the app enters the background, THE CameraViewModel SHALL stop the capture session.
3. WHEN the app returns to the foreground, THE CameraViewModel SHALL restart the capture session.
4. WHEN the capture button is tapped in MeasurementView, THE MeasurementView SHALL freeze the frame and display captured lux, kelvin, interpretation, and comparison values matching current behavior.
5. THE TemperatureView SHALL display live color temperature readings with interpretation text matching current behavior.
6. THE CameraPreviewView SHALL continue to receive the AVCaptureSession and render the live preview without modification.
