# Implementation Plan: UI Architecture Cleanup

## Overview

Refactor the monolithic `CameraManager` into three focused components (`CameraSessionManager`, `CameraFrameProvider`, `CameraViewModel`), extract a shared `CameraStateOverlay`, and make `TemperatureCardView` a pure display component. Each task builds incrementally — new files are created first, then views are migrated one at a time, and finally the old `CameraManager` is removed. New Swift files must be added to the Xcode project (`project.pbxproj`).

## Tasks

- [ ] 1. Create CameraSessionManager (effects layer)
  - Create `LightMeter/CameraSessionManager.swift` as a `final class`
  - Extract AVCaptureSession lifecycle from `CameraManager`: session configuration, input/output setup, start, stop
  - Implement `toggleCamera(completion:)` with `@Sendable` completion handler
  - Expose `session` property for `CameraPreviewView`
  - Expose `onError: (@Sendable (String) -> Void)?` callback for error reporting
  - Use `nonisolated(unsafe)` for AVFoundation properties accessed from the session queue (matching current pattern)
  - Add the new file to the Xcode project's LightMeter target in `project.pbxproj`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [ ] 2. Create CameraFrameProvider (effects layer)
  - Create `LightMeter/CameraFrameProvider.swift` as a `final class: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate`
  - Extract sample buffer delegation from `CameraManager`: `captureOutput(_:didOutput:from:)` implementation
  - Store latest `CMSampleBuffer`, implement `captureFrame() -> UIImage?`
  - Compute lux via `LuxCalculator.calculateLux` and kelvin via `ColorTemperatureCalculator.calculateColorTemperature` inside `captureOutput`, forwarding results through `onFrameUpdate: (@Sendable (Double, Double) -> Void)?`
  - Expose `captureDevice: AVCaptureDevice?` property (set externally by CameraViewModel)
  - Add the new file to the Xcode project's LightMeter target in `project.pbxproj`
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 3. Create CameraViewModel (glue layer)
  - Create `LightMeter/CameraViewModel.swift` as `@MainActor final class CameraViewModel: ObservableObject`
  - Declare `@Published` properties: `lux`, `colorTemperature`, `permissionGranted`, `cameraError`, `currentCameraPosition`
  - Instantiate `CameraSessionManager` and `CameraFrameProvider` internally
  - Wire `sessionManager.onError` to set `cameraError` via `Task { @MainActor in ... }`
  - Wire `frameProvider.onFrameUpdate` to update `lux` and `colorTemperature` via `Task { @MainActor in ... }`
  - Implement `requestPermission()`, `startSession()`, `stopSession()`, `toggleCamera()`, `captureFrame()`
  - In `setupSession`, pass `frameProvider` as the delegate to `sessionManager.setupSession(position:delegate:)`, then set `frameProvider.captureDevice`
  - Expose `nonisolated var session: AVCaptureSession` delegating to `sessionManager.session`
  - Expose `nonisolated func captureFrame() -> UIImage?` delegating to `frameProvider.captureFrame()`
  - Add the new file to the Xcode project's LightMeter target in `project.pbxproj`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 4. Checkpoint — Verify new components compile
  - Ensure the project builds successfully with the three new files alongside the existing `CameraManager.swift` (no views changed yet)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Create CameraStateOverlay and make TemperatureCardView pure
  - [ ] 5.1 Create CameraStateOverlay shared view
    - Create `LightMeter/CameraStateOverlay.swift` as a generic `View` with `@ViewBuilder` content
    - Accept `permissionGranted: Bool`, `cameraError: String?`, `session: AVCaptureSession`
    - Render `CameraPreviewView` background when permitted, black when not, permission message when denied, red error text when error exists, and `content()` when all clear
    - Add the new file to the Xcode project's LightMeter target in `project.pbxproj`
    - _Requirements: 4.1, 4.2, 4.3, 4.6_
  - [ ] 5.2 Make TemperatureCardView a pure display component
    - Replace the `private var interpretation` computed property with two new input properties: `interpretationDescription: String` and `interpretationTip: String`
    - Remove the `KelvinInterpreter.interpret(kelvin:)` call from the view body
    - Update the body to use the new string properties directly
    - _Requirements: 5.1, 5.2_

- [ ] 6. Migrate views to CameraViewModel and CameraStateOverlay
  - [ ] 6.1 Migrate ContentView
    - Replace `@StateObject private var cameraManager = CameraManager()` with `@StateObject private var cameraViewModel = CameraViewModel()`
    - Pass `cameraViewModel` to `MeasurementView` and `TemperatureView`
    - Update lifecycle hooks (`onAppear`, foreground/background notifications) to call `cameraViewModel` methods
    - _Requirements: 6.1, 6.2, 6.3_
  - [ ] 6.2 Migrate MeasurementView
    - Replace `@ObservedObject var cameraManager: CameraManager` with `@ObservedObject var cameraViewModel: CameraViewModel`
    - Use `CameraStateOverlay` for background/permission/error states instead of inline checks
    - Update `capture()` to use `cameraViewModel.captureFrame()`, `cameraViewModel.lux`, `cameraViewModel.colorTemperature`
    - Keep `LuxInterpreter.interpret(lux:)` and `ComparisonGenerator.generate(lux:)` calls at capture time (unchanged behavior)
    - Handle the frozen-frame overlay for captured mode (CameraStateOverlay handles live mode background only)
    - _Requirements: 4.4, 6.4_
  - [ ] 6.3 Migrate TemperatureView
    - Replace `@ObservedObject var cameraManager: CameraManager` with `@ObservedObject var cameraViewModel: CameraViewModel`
    - Use `CameraStateOverlay` for background/permission/error states instead of inline checks
    - Compute `KelvinInterpreter.interpret(kelvin: cameraViewModel.colorTemperature)` in the view and pass `description` and `tip` strings to `TemperatureCardView`
    - _Requirements: 4.5, 5.3, 6.5_

- [ ] 7. Delete CameraManager and clean up Xcode project
  - Delete `LightMeter/CameraManager.swift`
  - Remove the `CameraManager.swift` file reference and build phase entry from `project.pbxproj`
  - Verify no remaining references to `CameraManager` in the codebase
  - _Requirements: 6.6 (CameraPreviewView unchanged), 1.1–3.5 (migration complete)_

- [ ] 8. Checkpoint — Full build and test verification
  - Ensure the project builds successfully without `CameraManager.swift`
  - Ensure all existing tests pass (pure logic tests are unaffected by the refactor)
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 9. Add property test for kelvin interpretation consistency
  - Add a new test to `LightMeterTests/KelvinInterpreterTests.swift`
  - **Property 1: Kelvin interpretation consistency**
  - For 150+ random kelvin values in [1000, 15000], verify `KelvinInterpreter.interpret(kelvin:)` returns non-empty `description` and non-empty `tip`, and calling it twice with the same input produces the same output
  - **Validates: Requirements 5.4**

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- New Swift files must be added to `project.pbxproj` (PBXFileReference, PBXGroup, PBXBuildFile, PBXSourcesBuildPhase) for the LightMeter target
- No changes needed to `Package.swift` — new files are effects/glue layer, not pure logic
- The existing `KelvinInterpreterTests` already has property-based range mapping tests; task 9 adds the specific consistency property from the design
- Commit convention: `[S06_TXX_category]: one-liner summary`
