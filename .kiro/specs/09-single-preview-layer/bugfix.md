# Bugfix Requirements Document

## Introduction

The camera preview shows a persistent black screen on device despite the `AVCaptureSession` running correctly and delivering frames to `CameraFrameProvider`. Spec 08 fixed unnecessary session stop/start cycles but did not resolve the black screen. The root cause is an architectural problem: both `MeasurementView` and `TemperatureView` each create their own `CameraPreviewView`, resulting in multiple `AVCaptureVideoPreviewLayer` instances connected to the same session. AVFoundation only renders frames to the last-connected preview layer — all others go permanently black.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the app launches and the camera session starts THEN the camera preview is black from the very first frame, even though lux and kelvin values update correctly

1.2 WHEN `MeasurementView` (tab 0) and `TemperatureView` (tab 1) are both created by SwiftUI's `TabView` THEN two separate `VideoPreviewUIView` instances are created, each with its own `AVCaptureVideoPreviewLayer`, both assigned the same `AVCaptureSession`

1.3 WHEN two `AVCaptureVideoPreviewLayer` instances are connected to the same `AVCaptureSession` THEN only the last-connected layer renders frames — the other renders black permanently

1.4 WHEN the user switches between the Lux tab and the Temperature tab THEN the visible tab's preview layer may or may not be the one that "won" the connection race, resulting in non-deterministic black screen behavior

### Expected Behavior (Correct)

2.1 WHEN the app launches and the camera session starts THEN the camera preview SHALL display live video within the normal ~2-second AVCaptureSession startup time

2.2 WHEN the user is on the Lux tab (tab 0) THEN the live camera preview SHALL be visible behind the measurement overlay

2.3 WHEN the user is on the Temperature tab (tab 1) THEN the live camera preview SHALL be visible behind the temperature overlay

2.4 WHEN the user switches between the Lux tab and the Temperature tab THEN the camera preview SHALL remain continuously visible with no black flash or interruption

2.5 THERE SHALL be exactly one `AVCaptureVideoPreviewLayer` instance connected to the `AVCaptureSession` at any time

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the user switches from a camera tab (tab 0 or 1) to a non-camera tab (tab 2 or 3) THEN the system SHALL CONTINUE TO stop the AVCaptureSession to conserve resources

3.2 WHEN the user switches from a non-camera tab back to a camera tab THEN the system SHALL CONTINUE TO start the AVCaptureSession

3.3 WHEN the app enters the background THEN the system SHALL CONTINUE TO stop the AVCaptureSession

3.4 WHEN the app returns to the foreground THEN the system SHALL CONTINUE TO start the AVCaptureSession

3.5 WHEN the user captures a photo on the Lux tab THEN the capture flow (freeze frame, show interpretation, return to live) SHALL CONTINUE TO work identically

3.6 WHEN the user toggles between front and rear cameras THEN the camera switch SHALL CONTINUE TO work without stopping the session

3.7 WHEN the app lacks camera permission THEN the permission prompt overlay SHALL CONTINUE TO display instead of the camera preview

3.8 WHEN the user is on a non-camera tab (tab 2 or 3) THEN no camera preview SHALL be visible — only the placeholder content

3.9 Lux and kelvin values SHALL CONTINUE TO update in real time on both camera tabs

3.10 The `TabTransitionAction` pure function and all existing tests from spec 08 SHALL CONTINUE TO pass

## On-Device Testing Objectives

These are manual tests to perform on a physical iPhone after implementing the fix. Each objective targets a specific failure mode that the black screen bug exhibited.

### Test 1 — Fresh launch preview

**Goal**: Confirm the preview renders on first launch, not black.

**Steps**:
1. Delete the app from the device (clean install)
2. Build and run from Xcode onto the device
3. Grant camera permission when prompted
4. Observe the Lux tab (tab 0)

**Pass criteria**: Live camera preview is visible within ~2 seconds of granting permission. Lux and kelvin values update. The preview is NOT black.

### Test 2 — Camera tab switching round-trip

**Goal**: Confirm the preview survives Lux ↔ Temperature tab switches without going black.

**Steps**:
1. Start on the Lux tab (tab 0) — confirm preview is live
2. Switch to the Temperature tab (tab 1) — confirm preview is live
3. Switch back to the Lux tab (tab 0) — confirm preview is live
4. Repeat steps 2–3 five more times rapidly

**Pass criteria**: The camera preview is continuously visible on every switch. No black flash, no frozen frame, no delay. Lux and kelvin values update on both tabs throughout.

### Test 3 — Non-camera tab round-trip

**Goal**: Confirm the preview recovers after visiting a non-camera tab (session stop/start cycle).

**Steps**:
1. Start on the Lux tab (tab 0) — confirm preview is live
2. Switch to the Records tab (tab 3) — preview should disappear (session stops)
3. Switch back to the Lux tab (tab 0) — preview should reappear
4. Switch to the Temperature tab (tab 1) — preview should be live
5. Switch to the Check tab (tab 2) — preview should disappear
6. Switch back to the Temperature tab (tab 1) — preview should reappear

**Pass criteria**: Every return to a camera tab shows a live preview within ~2 seconds. No permanent black screen. Lux and kelvin values resume updating.

### Test 4 — Capture flow on Lux tab

**Goal**: Confirm the capture freeze/unfreeze flow still works with the new single-preview architecture.

**Steps**:
1. Start on the Lux tab (tab 0) — confirm preview is live
2. Tap the capture button — screen should freeze with the captured frame and show interpretation
3. Tap "Close" to return to live mode — preview should resume immediately
4. Switch to the Temperature tab (tab 1) — preview should be live
5. Switch back to the Lux tab (tab 0) — preview should be live
6. Capture again — should work identically

**Pass criteria**: Capture freezes the frame correctly. Returning to live mode shows the preview instantly. Tab switching after capture works. No black screen at any point.
