# Implementation Plan

- [x] 1. Move CameraPreviewView to ContentView as a shared single instance
  - In `LightMeter/ContentView.swift`, wrap the existing `TabView` in a `ZStack`
  - Add a single `CameraPreviewView(session: cameraViewModel.session)` behind the `TabView`, gated on `cameraViewModel.permissionGranted` and `selectedTab` being a camera tab (0 or 1)
  - Ensure the `TabView` background is transparent so the preview shows through on camera tabs
  - Non-camera tabs (2, 3) should show their placeholder content with an opaque background — the preview should not bleed through
  - The permission-denied overlay ("Camera access is required") should still display when `permissionGranted` is false
  - Verify the `onChange`, `onAppear`, `onReceive` handlers are unaffected
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.8_

- [x] 2. Remove CameraPreviewView from MeasurementView
  - In `LightMeter/Features/Measurement/MeasurementView.swift`, remove the `CameraPreviewView(session:)` line
  - Make the root background transparent (`Color.clear` or remove the opaque background) so the shared preview behind the `TabView` is visible
  - Keep all overlay content (MeasurementCardView, capture button, camera toggle button) unchanged
  - Keep the captured-mode flow (frozen frame overlay) unchanged — it should overlay opaquely on top when active
  - Verify the `liveModeContent` and `capturedModeContent` still render correctly
  - _Requirements: 2.2, 2.5, 3.5, 3.9_

- [x] 3. Remove CameraPreviewView from TemperatureView
  - In `LightMeter/Features/Temperature/TemperatureView.swift`, remove the `CameraPreviewView(session:)` line
  - Make the root background transparent so the shared preview is visible
  - Keep the TemperatureCardView overlay unchanged
  - _Requirements: 2.3, 2.5, 3.9_

- [x] 4. Run existing test suite and verify no regressions
  - Run the full `LightMeterTests` test suite
  - All `TabTransitionActionTests` from spec 08 must pass
  - All `LuxCalculatorTests`, `LuxInterpreterTests`, `KelvinInterpreterTests`, `ColorTemperatureCalculatorTests`, `ComparisonGeneratorTests`, `LuxRangeTests`, `NumberFormattingTests` must pass
  - No new test code is needed — this is a view-layer architectural change that is validated by on-device testing
  - _Requirements: 3.10_

- [ ] 5. On-device testing checkpoint
  - Build and deploy to a physical iPhone
  - Execute all four on-device testing objectives from the bugfix requirements:
    - **Test 1 — Fresh launch preview**: Delete app → install → grant permission → Lux tab shows live preview within ~2s
    - **Test 2 — Camera tab switching round-trip**: Lux ↔ Temperature ×5 rapid — preview continuously visible
    - **Test 3 — Non-camera tab round-trip**: Lux → Records → Lux → Temperature → Check → Temperature — preview recovers each time
    - **Test 4 — Capture flow**: Capture → Close → tab switch → capture again — no black screen
  - Report results to the user for each test
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.5_
