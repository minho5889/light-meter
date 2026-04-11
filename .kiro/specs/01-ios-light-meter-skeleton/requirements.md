# Requirements Document

## Introduction

A minimal iOS light meter app that measures Lux (illuminance) and Color Temperature (Kelvin) using the back camera. This is a skeleton/MVP intended to be tested on a physical iPhone device. The app uses AVFoundation to capture camera metadata (ISO, exposure duration, white balance gains) and derives real-time light measurements displayed in a SwiftUI interfac

## Glossary

- **App**: The iOS light meter application
- **Camera_Manager**: The component responsible for setting up and managing the AVCaptureSession, capturing video frames, and extracting camera metadata from the back camera
- **Lux_Calculator**: The component that computes illuminance (lux) from camera ISO and exposure duration values
- **Color_Temp_Calculator**: The component that derives color temperature in Kelvin from the camera white balance gains using AVCaptureDevice.temperatureAndTintValues(for:)
- **Measurement_View**: The SwiftUI view that displays real-time lux and color temperature readings
- **Lux**: A unit of illuminance measuring the intensity of light as perceived by the human eye
- **Color_Temperature**: The temperature of light measured in Kelvin, indicating the warmth or coolness of a light source
- **Back_Camera**: The rear-facing camera of the iPhone, accessed via AVCaptureDevice with position .back

## Requirements

### Requirement 1: Camera Permission

**User Story:** As a user, I want the app to request camera access, so that the app can use the back camera to measure light.

#### Acceptance Criteria

1. WHEN the App launches for the first time, THE App SHALL request camera permission from the user via the system permission dialog
2. THE App SHALL include an NSCameraUsageDescription entry in Info.plist explaining why camera access is needed
3. IF the user denies camera permission, THEN THE Measurement_View SHALL display a message indicating that camera access is required

### Requirement 2: Camera Session Setup

**User Story:** As a user, I want the app to use the back camera, so that I can measure the light in the environment I point the camera at.

#### Acceptance Criteria

1. WHEN camera permission is granted, THE Camera_Manager SHALL configure an AVCaptureSession using the back camera as the input device
2. THE Camera_Manager SHALL configure an AVCaptureVideoDataOutput to receive video frames
3. WHEN the AVCaptureSession is configured, THE Camera_Manager SHALL start the capture session on a background thread
4. IF the back camera is unavailable, THEN THE Camera_Manager SHALL report an error to the Measurement_View

### Requirement 3: Lux Calculation

**User Story:** As a user, I want to see the current illuminance in lux, so that I can measure the brightness of my environment.

#### Acceptance Criteria

1. WHEN a video frame is captured, THE Camera_Manager SHALL extract the ISO and exposure duration values from the AVCaptureDevice
2. WHEN ISO and exposure duration values are available, THE Lux_Calculator SHALL compute the lux value using the formula: lux = (calibrationConstant * aperture^2) / (ISO * exposureDurationInSeconds)
3. THE Lux_Calculator SHALL update the lux reading at the frame capture rate
4. THE Lux_Calculator SHALL produce a non-negative lux value for all valid ISO and exposure duration inputs

### Requirement 4: Color Temperature Calculation

**User Story:** As a user, I want to see the color temperature in Kelvin, so that I can understand the warmth or coolness of the ambient light.

#### Acceptance Criteria

1. WHEN a video frame is captured, THE Camera_Manager SHALL extract the white balance gains from the AVCaptureDevice using deviceWhiteBalanceGains
2. WHEN white balance gains are available, THE Color_Temp_Calculator SHALL convert the gains to a Kelvin value using AVCaptureDevice.temperatureAndTintValues(for:)
3. THE Color_Temp_Calculator SHALL update the color temperature reading at the frame capture rate
4. THE Color_Temp_Calculator SHALL produce a color temperature value within the range of 1000K to 15000K for valid white balance gains

### Requirement 5: Real-Time Display

**User Story:** As a user, I want to see lux and color temperature values updating in real time, so that I can observe changes as I move the device.

#### Acceptance Criteria

1. THE Measurement_View SHALL display the current lux value with a label indicating the unit (lux)
2. THE Measurement_View SHALL display the current color temperature value with a label indicating the unit (K)
3. WHEN new lux and color temperature values are calculated, THE Measurement_View SHALL update the displayed values in real time
4. THE Measurement_View SHALL render using SwiftUI

### Requirement 6: App Lifecycle Management

**User Story:** As a user, I want the camera session to start and stop appropriately, so that the app does not consume resources when not in use.

#### Acceptance Criteria

1. WHEN the App enters the foreground, THE Camera_Manager SHALL start the AVCaptureSession
2. WHEN the App enters the background, THE Camera_Manager SHALL stop the AVCaptureSession
3. WHEN the AVCaptureSession is stopped, THE Camera_Manager SHALL release camera resources
