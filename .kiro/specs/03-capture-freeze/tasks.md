# Implementation Plan: Capture & Freeze

## Overview

Incrementally add capture-and-freeze functionality following the deterministic-split pattern: pure logic first (ComparisonGenerator), then effects layer (CameraManager additions), then glue layer (MeasurementView refactor + MeasurementCardView). Property-based tests validate the three correctness properties from the design document. Each layer is checkpointed before moving to the next.

## Tasks

- [x] 1. Implement ComparisonGenerator (pure logic layer)
  - [x] 1.1 Create `ComparisonGenerator` with contextual comparison sentence generation
    - Create `LightMeter/ComparisonGenerator.swift` as a `struct` with `static func generate(lux: Double) -> String`
    - Define an internal array of 8 range tuples matching the design document's short environment labels (e.g., "very dark outdoors", "hallways and movie theaters", "a living room", "an office", "a study room", "a bright window indoors", "a cloudy day outdoors", "direct sunlight")
    - Use the same 8 lux range boundaries as `LuxInterpreter` (0–10, 11–100, 101–200, 201–500, 501–1000, 1001–2000, 2001–10000, 10001+)
    - Implement range lookup: find index `i` for the lux value, negative values → index 0
    - Sentence generation: index 0 → "Darker than \(ranges[1])", index 7 → "Brighter than \(ranges[6])", middle → "Brighter than \(ranges[i-1]) but darker than \(ranges[i+1])"
    - No platform framework imports — pure function only
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

  - [x] 1.2 Write property test for ComparisonGenerator — Property 1: Comparison sentence completeness
    - **Property 1: Comparison sentence completeness**
    - Generate 100+ random `Double` values across [-1000, 200000]
    - For each value, call `ComparisonGenerator.generate(lux:)` and verify the result is a non-empty `String`
    - **Validates: Requirements 6.5, 6.7**

  - [x] 1.3 Write property test for ComparisonGenerator — Property 2: Comparison sentence correctness
    - **Property 2: Comparison sentence correctness**
    - Generate 100+ random `Double` values across [-1000, 200000]
    - For each value, independently compute the expected range index using the 8 lux boundaries
    - Verify: lowest range (index 0) references only upper adjacent, highest range (index 7) references only lower adjacent, middle ranges reference both adjacent environments
    - Verify the returned sentence contains the correct adjacent environment labels
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.6**

  - [x] 1.4 Write property test for ComparisonGenerator — Property 3: Comparison range consistency
    - **Property 3: Comparison range consistency**
    - Generate 100+ random `Double` values across [-1000, 200000]
    - For each value, verify that the range identified by `ComparisonGenerator` (via the sentence content) matches the range identified by `LuxInterpreter.interpret(lux:)` for the same value
    - Both must use the same 8-range boundaries — the comparison sentence's adjacent environments must be consistent with the interpreter's range placement
    - **Validates: Requirements 6.1, 6.6**

  - [x] 1.5 Write unit tests for ComparisonGenerator
    - Test one representative value per range (5, 50, 150, 350, 750, 1500, 5000, 50000) with exact sentence string matching
    - Test boundary values (0, 10, 11, 100, 101, 200, 201, 500, 501, 1000, 1001, 2000, 2001, 10000, 10001)
    - Test negative value produces the lowest-range sentence ("Darker than hallways and movie theaters")
    - Test lowest range (index 0) sentence format: "Darker than ..."
    - Test highest range (index 7) sentence format: "Brighter than ..."
    - Test middle range sentence format: "Brighter than ... but darker than ..."
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.7_

- [x] 2. Checkpoint — Verify pure logic layer
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Add CameraManager effects (captureFrame + toggleCamera)
  - [x] 3.1 Add `latestSampleBuffer` storage and `captureFrame()` method to `CameraManager`
    - Add a private `latestSampleBuffer: CMSampleBuffer?` property to `CameraManager`
    - Update the `captureOutput` delegate method to store the latest sample buffer on each frame
    - Implement `captureFrame() -> UIImage?` that converts `latestSampleBuffer` to a `UIImage` via `CIImage` → `CGImage` → `UIImage`, returning `nil` if no buffer is available
    - _Requirements: 2.1, 2.2, 2.4_

  - [x] 3.2 Add `currentCameraPosition` property and `toggleCamera()` method to `CameraManager`
    - Add `@Published var currentCameraPosition: AVCaptureDevice.Position = .back`
    - Implement `toggleCamera()` that runs on `sessionQueue`: calls `beginConfiguration()`, removes current input, creates new `AVCaptureDeviceInput` for the opposite position, adds it, calls `commitConfiguration()`, updates `currentCameraPosition` on main thread
    - If the target camera is unavailable, retain current input silently (no error published)
    - Update `setupSession()` to use `currentCameraPosition` instead of hardcoding `.back`
    - _Requirements: 3.2, 3.3, 3.4, 3.5_

- [ ] 4. Checkpoint — Verify effects layer compiles
  - Ensure the project compiles with no errors, ask the user if questions arise.

- [ ] 5. Create MeasurementCardView and refactor MeasurementView (glue layer)
  - [ ] 5.1 Create `MeasurementCardView` with compact/expanded modes
    - Create `LightMeter/MeasurementCardView.swift` accepting `lux: Double`, `kelvin: Double`, `isCaptured: Bool`
    - Compact mode (live): display Kelvin value + "K" label, lux value + "LUX" label with frosted-glass background (`.ultraThinMaterial`)
    - Expanded mode (captured): add a `Divider`, "User Guide" label, lux interpretation description and tip from `LuxInterpreter`, and contextual comparison from `ComparisonGenerator`
    - Use fixed font sizes (`.system(size: N)`) — no Dynamic Type
    - Apply `.cornerRadius(16)` and white foreground color
    - _Requirements: 4.1, 4.2, 4.3, 4.5, 5.1, 5.2, 5.3, 5.4, 5.5, 5.7_

  - [ ] 5.2 Refactor `MeasurementView` with live/captured mode state and controls
    - Add `@State` properties: `isCaptured: Bool`, `frozenFrame: UIImage?`, `capturedLux: Double`, `capturedKelvin: Double`
    - Background: show `CameraPreviewView` in live mode, `Image(uiImage: frozenFrame)` with `.resizable().aspectRatio(contentMode: .fill).ignoresSafeArea()` in captured mode, `Color.black` fallback when no permission
    - Add capture button (round, bottom center) and camera toggle button (adjacent) — visible only in live mode
    - Add back arrow (top-left) — visible only in captured mode
    - Implement `capture()`: call `cameraManager.captureFrame()`, guard against nil, snapshot lux/Kelvin values, set `isCaptured = true`
    - Implement `returnToLiveMode()`: set `isCaptured = false`, clear `frozenFrame`
    - Wire `MeasurementCardView` with captured values in captured mode, live values in live mode
    - Pass `cameraManager.toggleCamera()` to the camera toggle button action
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 2.3, 3.1, 4.4, 4.6, 5.6_

- [ ] 6. Final checkpoint — Ensure all tests pass and project compiles
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Pure logic (task 1) has zero platform dependencies per the deterministic-split steering doc
- Property tests validate the three correctness properties from the design document
- Unit tests validate specific examples, boundary values, and sentence format patterns
- Effects layer tasks (task 3) are thin AVFoundation wrappers — tested on-device only
- Integration/on-device tests are excluded as they require physical hardware
