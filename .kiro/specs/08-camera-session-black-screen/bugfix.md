# Bugfix Requirements Document

## Introduction

The camera preview shows a black screen when switching between tabs in the light meter app. The root cause is unnecessary `AVCaptureSession.stopRunning()` / `startRunning()` cycling in the `onChange(of: selectedTab)` handler in `ContentView.swift`. The session is stopped and restarted even when switching between two tabs that both require the camera (Lux ↔ Temperature), causing 2–7+ second blackouts. Additionally, after a stop/start cycle, the `AVCaptureVideoPreviewLayer` can fail to reconnect its rendering pipeline, resulting in an indefinite black screen even though frames are being processed.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the user switches from the Lux tab (tab 0) to the Temperature tab (tab 1) THEN the system stops and restarts the AVCaptureSession, causing a ~7-second black screen with frozen lux and kelvin values

1.2 WHEN the user switches from a non-camera tab (tab 2 or 3) back to the Lux tab (tab 0) THEN the system shows an indefinite black screen on the preview layer, even though lux and kelvin values continue updating from processed frames

1.3 WHEN the user switches from the Temperature tab (tab 1) to a non-camera tab (tab 2 or 3) and then back to the Temperature tab (tab 1) THEN the system shows an indefinite black screen on the preview layer, even though frames are being processed

1.4 WHEN the user switches from the Lux tab (tab 0) to the Temperature tab (tab 1) THEN the system unnecessarily calls `stopRunning()` followed by `startRunning()` on the session queue, blocking the queue for ~7 seconds

### Expected Behavior (Correct)

2.1 WHEN the user switches from the Lux tab (tab 0) to the Temperature tab (tab 1) THEN the system SHALL keep the AVCaptureSession running continuously with no interruption to the preview layer or frame processing

2.2 WHEN the user switches from a non-camera tab (tab 2 or 3) back to the Lux tab (tab 0) THEN the system SHALL display the live camera preview without any black screen, with lux and kelvin values updating normally

2.3 WHEN the user switches from a non-camera tab (tab 2 or 3) back to the Temperature tab (tab 1) THEN the system SHALL display the live camera preview without any black screen, with kelvin values updating normally

2.4 WHEN the user switches between two camera tabs (tab 0 ↔ tab 1) THEN the system SHALL NOT call `stopRunning()` or `startRunning()` on the AVCaptureSession, since both tabs require the camera

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the user switches from a camera tab (tab 0 or 1) to a non-camera tab (tab 2 or 3) THEN the system SHALL CONTINUE TO stop the AVCaptureSession to conserve resources

3.2 WHEN the user switches from a non-camera tab (tab 2 or 3) to a camera tab (tab 0 or 1) THEN the system SHALL CONTINUE TO start the AVCaptureSession if it is not already running

3.3 WHEN the app enters the background THEN the system SHALL CONTINUE TO stop the AVCaptureSession

3.4 WHEN the app returns to the foreground THEN the system SHALL CONTINUE TO start the AVCaptureSession

3.5 WHEN the user captures a photo on the Lux tab and returns to live mode THEN the system SHALL CONTINUE TO show the live preview instantly without any black screen (session never stops during capture)

3.6 WHEN the app first launches THEN the system SHALL CONTINUE TO show the live preview after the normal ~2-second AVCaptureSession startup time

3.7 WHEN the user toggles between front and rear cameras THEN the system SHALL CONTINUE TO switch cameras without stopping the session

3.8 WHEN the app lacks camera permission THEN the system SHALL CONTINUE TO show the permission prompt overlay instead of the camera preview
