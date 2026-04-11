# Implementation Plan: Lux & Kelvin Interpretation + Live Camera Preview

## Overview

Incrementally add lux/Kelvin interpretation logic (pure layer), a camera preview wrapper (effects layer), and updated UI (glue layer) on top of the spec 01 skeleton. Pure interpreters are built and tested first, then the camera preview bridge, then the view is updated to wire everything together.

## Tasks

- [x] 1. Create InterpretationResult value type and LuxInterpreter
  - [x] 1.1 Create `InterpretationResult` struct and `LuxInterpreter` with 8-range mapping
    - Create `LightMeter/InterpretationResult.swift` with an `Equatable` struct containing `description: String` and `tip: String`
    - Create `LightMeter/LuxInterpreter.swift` with `static func interpret(lux: Double) -> InterpretationResult`
    - Implement chained if-else mapping lux to the 8 ranges from the design document
    - Negative values fall back to the 0–10 range; no platform framework imports
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 1.2 Write property test for LuxInterpreter — Property 1: Lux range mapping correctness
    - **Property 1: Lux range mapping correctness**
    - Generate 100+ random `Double` values across [-1000, 200000]
    - For each value, call `LuxInterpreter.interpret(lux:)` and independently compute the expected range
    - Verify returned `InterpretationResult` matches the expected description and tip
    - Verify negative values always return the 0–10 range result
    - **Validates: Requirements 1.1, 1.4, 1.5**

  - [x] 1.3 Write unit tests for LuxInterpreter
    - Test one representative value per range (5, 50, 150, 350, 750, 1500, 5000, 50000) with exact string matching
    - Test boundary values (0, 10, 11, 100, 101, 200, 201, 500, 501, 1000, 1001, 2000, 2001, 10000, 10001)
    - Test negative value returns 0–10 range result
    - _Requirements: 1.1, 1.2, 1.5_

- [x] 2. Create KelvinInterpreter
  - [x] 2.1 Implement `KelvinInterpreter` with 6-range mapping
    - Create `LightMeter/KelvinInterpreter.swift` with `static func interpret(kelvin: Double) -> InterpretationResult`
    - Implement chained if-else mapping Kelvin to the 6 ranges from the design document (with emoji in description)
    - Values below 1000 fall back to the "Below 2,000K" range; no platform framework imports
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 2.2 Write property test for KelvinInterpreter — Property 2: Kelvin range mapping correctness
    - **Property 2: Kelvin range mapping correctness**
    - Generate 100+ random `Double` values across [0, 20000]
    - For each value, call `KelvinInterpreter.interpret(kelvin:)` and independently compute the expected range
    - Verify returned `InterpretationResult` matches the expected description and tip
    - Verify values below 1000 return the "Below 2,000K" range result
    - **Validates: Requirements 2.1, 2.4, 2.5**

  - [x] 2.3 Write unit tests for KelvinInterpreter
    - Test one representative value per range (1500, 2700, 4000, 5500, 8000, 12000) with exact string matching
    - Test boundary values (1000, 1999, 2000, 3499, 3500, 4999, 5000, 6499, 6500, 9999, 10000, 15000)
    - Test value below 1000 returns "Below 2,000K" range result
    - _Requirements: 2.1, 2.2, 2.5_

- [x] 3. Checkpoint — Verify pure interpreter logic
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Add camera preview and expose session
  - [x] 4.1 Expose `session` property on `CameraManager`
    - Add a computed read-only property `var session: AVCaptureSession { captureSession }` to `CameraManager`
    - No changes to existing published properties or session lifecycle methods
    - _Requirements: 5.1, 5.2, 5.3_

  - [x] 4.2 Create `CameraPreviewView` as a `UIViewRepresentable`
    - Create `LightMeter/CameraPreviewView.swift` accepting an `AVCaptureSession`
    - In `makeUIView`, create a `UIView`, add an `AVCaptureVideoPreviewLayer` with `.resizeAspectFill` gravity
    - In `updateUIView`, update the preview layer frame to match the view bounds
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 5. Update MeasurementView with interpretation overlay and camera preview
  - [x] 5.1 Replace black background with `CameraPreviewView` and add interpretation text
    - When `permissionGranted` is true, use `CameraPreviewView(session: cameraManager.session)` as the ZStack background instead of `Color.black`
    - When `permissionGranted` is false, keep `Color.black` as fallback
    - Add lux interpretation text (description + tip) below the lux value/label
    - Add Kelvin interpretation text (color tone + recommended environment) below the Kelvin value/label
    - Call `LuxInterpreter.interpret(lux:)` and `KelvinInterpreter.interpret(kelvin:)` inline in the view
    - Use white text with `.shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)` for contrast
    - Use fixed `.font(.system(size: N))` for all text — no Dynamic Type
    - _Requirements: 3.1, 3.7, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 6. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate the two correctness properties from the design document
- Pure interpreters (tasks 1–2) have zero platform dependencies per the deterministic split steering doc
- Integration/on-device tests are excluded as they require physical hardware
