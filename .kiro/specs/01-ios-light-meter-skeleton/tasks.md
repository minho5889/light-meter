# Implementation Plan: iOS Light Meter Skeleton

## Overview

Incrementally build a minimal iOS light meter app using SwiftUI and AVFoundation. Start with pure calculation logic (testable without hardware), then build the camera layer, then the UI, and finally wire everything together with lifecycle management.

## Tasks

- [x] 1. Create Xcode project structure and core calculation types
  - [x] 1.1 Create the Swift package/project with an iOS app target and a test target
    - Set up the Xcode project named `LightMeter` with deployment target iOS 16+
    - Add `import AVFoundation` and `import SwiftUI` to appropriate files
    - _Requirements: 2.1, 5.4_

  - [x] 1.2 Implement `LuxCalculator` with the lux formula
    - Create `LuxCalculator.swift` with the static `calculateLux(iso:exposureDuration:calibrationConstant:aperture:)` method
    - Formula: `lux = (calibrationConstant * aperture²) / (ISO * exposureDurationInSeconds)`
    - Return `0.0` when ISO <= 0, exposure duration <= 0, or result would be negative
    - Use default constants: `calibrationConstant = 12.5`, `defaultAperture = 1.8`
    - _Requirements: 3.2, 3.4_

  - [x] 1.3 Write property test for LuxCalculator — Property 1: Lux formula correctness
    - **Property 1: Lux formula correctness**
    - Generate random valid ISO (0.01...10000) and random valid exposure duration (1/100000...30 seconds)
    - Verify output matches `(calibrationConstant * aperture²) / (ISO * exposureDurationInSeconds)` within epsilon 1e-6
    - Minimum 100 iterations
    - **Validates: Requirements 3.2**

  - [x] 1.4 Write property test for LuxCalculator — Property 2: Lux non-negativity invariant
    - **Property 2: Lux non-negativity invariant**
    - Generate random ISO values including 0, negative, and positive floats
    - Generate random exposure durations including 0, negative, and positive values
    - Verify `calculateLux` always returns >= 0.0
    - Minimum 100 iterations
    - **Validates: Requirements 3.4**

  - [x] 1.5 Implement `ColorTemperatureCalculator` with clamping logic
    - Create `ColorTemperatureCalculator.swift` with static `calculateColorTemperature(gains:device:)` method
    - Use `AVCaptureDevice.temperatureAndTintValues(for:)` to convert gains to Kelvin
    - Clamp output to `[1000, 15000]` range
    - Define `minKelvin = 1000.0` and `maxKelvin = 15000.0` constants
    - _Requirements: 4.2, 4.4_

  - [x] 1.6 Write property test for ColorTemperatureCalculator — Property 3: Color temperature clamping invariant
    - **Property 3: Color temperature clamping invariant**
    - Generate random raw Kelvin values across a wide range (e.g., -1000...50000)
    - Verify the clamping function always returns a value in [1000, 15000]
    - Minimum 100 iterations
    - **Validates: Requirements 4.4**

  - [x] 1.7 Write unit tests for LuxCalculator and ColorTemperatureCalculator
    - Test known input/output pair for lux (e.g., ISO=100, exposure=1/125s)
    - Test edge cases: ISO=0 → 0.0, exposure=0 → 0.0, very large ISO → small non-negative lux
    - Test color temperature clamping: below 1000 → 1000, above 15000 → 15000, within range → unchanged
    - _Requirements: 3.2, 3.4, 4.4_

- [x] 2. Checkpoint — Verify calculation logic
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Implement CameraManager with AVCaptureSession
  - [x] 3.1 Create `CameraManager` as an `ObservableObject` with published properties
    - Define `@Published var lux: Double = 0.0`, `colorTemperature: Double = 0.0`, `cameraError: String? = nil`, `permissionGranted: Bool = false`
    - Create a private `AVCaptureSession` and a dedicated serial `DispatchQueue` for the session
    - _Requirements: 2.1, 5.3_

  - [x] 3.2 Implement `requestPermission()` for camera access
    - Use `AVCaptureDevice.requestAccess(for: .video)` to request permission
    - Update `permissionGranted` on the main thread based on the result
    - _Requirements: 1.1, 1.3_

  - [x] 3.3 Implement `setupSession()` to configure AVCaptureSession
    - Get the back camera via `AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)`
    - Create `AVCaptureDeviceInput` and add to session
    - Create `AVCaptureVideoDataOutput`, set sample buffer delegate to `self`, and add to session
    - Set `cameraError` if back camera is unavailable or configuration fails
    - _Requirements: 2.1, 2.2, 2.4_

  - [x] 3.4 Implement `startSession()` and `stopSession()` methods
    - `startSession()`: run `captureSession.startRunning()` on the session queue
    - `stopSession()`: run `captureSession.stopRunning()` on the session queue
    - _Requirements: 2.3, 6.1, 6.2, 6.3_

  - [x] 3.5 Implement `AVCaptureVideoDataOutputSampleBufferDelegate` callback
    - In `captureOutput(_:didOutput:from:)`, read `captureDevice.iso`, `captureDevice.exposureDuration`, and `captureDevice.deviceWhiteBalanceGains`
    - Call `LuxCalculator.calculateLux(...)` and `ColorTemperatureCalculator.calculateColorTemperature(...)`
    - Publish results to `lux` and `colorTemperature` on the main thread
    - _Requirements: 3.1, 3.3, 4.1, 4.3_

- [x] 4. Implement SwiftUI views
  - [x] 4.1 Create `MeasurementView` displaying lux and color temperature
    - Accept `CameraManager` as an `@ObservedObject`
    - Display lux value with "lux" label
    - Display color temperature value with "K" label
    - Show a permission-required message when `permissionGranted` is false
    - Show an error message when `cameraError` is non-nil
    - _Requirements: 1.3, 5.1, 5.2, 5.4_

  - [x] 4.2 Create `ContentView` with lifecycle management
    - Create `CameraManager` as a `@StateObject`
    - Present `MeasurementView` with the camera manager
    - On `.onAppear`, call `cameraManager.requestPermission()`
    - Subscribe to `UIApplication.willEnterForegroundNotification` → `startSession()`
    - Subscribe to `UIApplication.didEnterBackgroundNotification` → `stopSession()`
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 4.3 Create `LightMeterApp` entry point
    - Define `@main struct LightMeterApp: App` with a `WindowGroup` containing `ContentView`
    - _Requirements: 1.1_

  - [x] 4.4 Write unit tests for MeasurementView
    - Test that lux value renders with "lux" label
    - Test that color temperature renders with "K" label
    - Test that permission message shows when `permissionGranted` is false
    - Test that error message shows when `cameraError` is set
    - _Requirements: 1.3, 5.1, 5.2_

- [x] 5. Add Info.plist camera usage description
  - Add `NSCameraUsageDescription` key with a user-facing explanation string to Info.plist
  - _Requirements: 1.2_

- [x] 6. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate the three correctness properties from the design document
- Integration/on-device tests are excluded from this plan as they require physical hardware and cannot be automated by a coding agent
