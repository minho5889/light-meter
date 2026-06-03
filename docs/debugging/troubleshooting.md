# Troubleshooting

Quick answers to common issues when building, deploying, or developing the LightMeter app. Scan for your problem, get the fix, move on.

For deeper investigation narratives, see the post-mortems in this folder:
- [Swift 6 Crash Post-Mortem](swift6-crash-post-mortem.md) — the launch crash caused by `@MainActor` closure isolation
- [Black Screen Post-Mortem](black-screen-post-mortem.md) — the preview layer rendering bug caused by multiple `AVCaptureVideoPreviewLayer` instances

---

<a id="table-of-contents"></a>
## Table of Contents

1. [Xcode and Build](#1-xcode-and-build)
2. [Device and Permissions](#2-device-and-permissions)
3. [Crashes](#3-crashes)
4. [Camera Preview](#4-camera-preview)
5. [Swift Concurrency](#5-swift-concurrency)
6. [AVFoundation](#6-avfoundation)

---

## [1. Xcode and Build](#table-of-contents)

**Q: Xcode shows "LightMeter-Package" in the scheme selector.**
<br>A: You opened the folder instead of the project. Close the workspace and double-click `LightMeter.xcodeproj` directly. The scheme should say "LightMeter" (no "-Package").

**Q: Xcode says "Build Succeeded" but nothing happens on my iPhone.**
<br>A: Make sure your iPhone (not a simulator) is selected as the run destination. If the scheme says "LightMeter-Package", see the answer above.

**Q: Xcode says "Signing for LightMeter requires a development team."**
<br>A: Select the LightMeter target → Signing & Capabilities tab → check "Automatically manage signing" → pick your Apple ID from the Team dropdown. If your Apple ID isn't listed, add it via Xcode → Settings → Accounts.

**Q: Build fails with "No profiles for 'com.xxx.LightMeter' were found."**
<br>A: Change the Bundle Identifier in the Signing & Capabilities tab to something unique, like `com.yourname.LightMeter`. Apple requires unique bundle IDs for device deployment.

**Q: I get "Unable to install — LightMeter" on my phone.**
<br>A: Unlock your phone and try again. If it persists, check that your phone's iOS version meets the project's minimum deployment target (iOS 17+). Also try: Xcode → Product → Clean Build Folder (`Cmd+Shift+K`), then rebuild.

---

## [2. Device and Permissions](#table-of-contents)

**Q: The app says "Untrusted Developer" when I tap it.**
<br>A: iPhone Settings → General → VPN & Device Management → tap your developer profile → Trust. One-time step per Apple ID.

**Q: I don't see anything under VPN & Device Management.**
<br>A: The developer profile only appears after the first install from Xcode. If it's not there, the app may already be trusted — just try opening it.

**Q: The app shows "Camera access is required" even though I tapped Allow.**
<br>A: Kill the app and relaunch. If it persists, go to iPhone Settings → LightMeter → toggle Camera permission off and back on. This can happen if the permission state gets cached incorrectly.

---

## [3. Crashes](#table-of-contents)

**Q: The app crashes on launch with `_dispatch_assert_queue_fail`.**
<br>A: This is a Swift 6 actor isolation crash, not an AVFoundation issue (even though the error message looks identical). A `@MainActor` closure is being called on a background queue. The fix is to use `async/await` instead of callback-based APIs. Check `CameraViewModel` for any callback closures that aren't `@Sendable`. Full details in the [Swift 6 Crash Post-Mortem](swift6-crash-post-mortem.md).

**Q: How do I tell if a `dispatch_assert_queue_fail` crash is AVFoundation or Swift concurrency?**
<br>A: Look at the stack trace frames in Xcode's debug navigator:
- `_swift_task_checkIsolatedSwift` in the frames → Swift concurrency actor isolation
- `AVCaptureSession` or `AVCaptureDevice` frames near the top → AVFoundation queue discipline

The crash message is identical for both. Only the stack frames tell you which.

**Q: The app crashes when I tap the capture button.**
<br>A: `captureFrame()` accesses the latest sample buffer and does `CIContext` image processing. If the buffer has been invalidated by the time the capture runs, it can crash. This is a known area for improvement — the frame capture needs to copy the pixel buffer synchronously on the session queue before processing.

**Q: The app crashes after switching between tabs rapidly.**
<br>A: This was addressed in spec 08. The `onChange` handler uses `TabTransitionAction.resolve(from:to:)` with `previousTab` tracking, so camera↔camera transitions (LUX ↔ Temperature) skip the stop/start cycle entirely. `CameraSessionManager.startSession()` also guards against redundant calls. If you still see issues, it may be from rapid non-camera↔camera transitions overlapping on the session queue — avoid switching tabs while the session is starting up.

---

## [4. Camera Preview](#table-of-contents)

**Q: The camera preview is black but lux/Kelvin values are updating.**
<br>A: This was fixed in spec 09. The root cause was multiple `AVCaptureVideoPreviewLayer` instances competing for the same session — AVFoundation only renders to the last-connected layer. The fix moved to a single shared `CameraPreviewView` in `ContentView`, behind the custom tab content switcher. If you're seeing this after spec 09, check that `MeasurementView` and `TemperatureView` do not create their own `CameraPreviewView` — there should be exactly one instance in the entire app, in `ContentView`. Full details in the [Black Screen Post-Mortem](black-screen-post-mortem.md).

**Q: The camera preview freezes when the app goes to background and comes back.**
<br>A: The app handles this via `willEnterForegroundNotification` and `didEnterBackgroundNotification` in `ContentView`. If the preview still freezes, the session may have been interrupted. Check for `AVCaptureSessionWasInterruptedNotification` and restart the session when `AVCaptureSessionInterruptionEndedNotification` fires.

**Q: The preview shows on the LUX tab but not on the Temperature tab (or vice versa).**
<br>A: Both tabs should be transparent overlays on top of the shared preview in `ContentView`. Check that the tab view's background uses `TransparentBackground()` — this `UIViewRepresentable` clears the opaque `UIHostingController` backgrounds that SwiftUI wrappers insert. Without it, the tab content is opaque and hides the preview behind it.

---

## [5. Swift Concurrency](#table-of-contents)

**Q: I added a new callback-based API call in `CameraViewModel` and it crashes. Why?**
<br>A: `CameraViewModel` is `@MainActor`. Any closure you write inside it inherits main actor isolation. If the API calls your closure on a background queue, Swift 6 will crash. Use the `async/await` version of the API, or define the closure property as `@Sendable` so it doesn't inherit isolation.

**Q: What's the difference between `@Sendable` and `@MainActor` on a closure?**
<br>A: `@MainActor` means "this closure must run on the main thread." `@Sendable` means "this closure can be safely passed across concurrency boundaries" — and critically, it opts out of inheriting actor isolation from the enclosing context. If you have a closure property that will be called from a background queue, type it as `@Sendable`.

**Q: Can I use `DispatchQueue.main.async` to get back to the main thread from a `@Sendable` closure?**
<br>A: Yes. `@Sendable` closures don't inherit actor isolation, so they won't crash when called from background queues. Inside them, `DispatchQueue.main.async` works fine for hopping to the main thread to update `@Published` properties.

**Q: Why does `Task { @MainActor in }` not fix the crash?**
<br>A: Because the `Task` is created inside the outer closure, which is already being checked for actor isolation. The runtime assertion fires on the outer closure before the `Task` is even created. The fix is to avoid the outer closure entirely by using `async/await`.

---

## [6. AVFoundation](#table-of-contents)

**Q: Where should I call `AVCaptureSession.startRunning()`?**
<br>A: Always on a dedicated serial queue, never on the main thread. It's a blocking call that can take hundreds of milliseconds. This project uses `sessionQueue` in `CameraSessionManager`.

**Q: Can I access `AVCaptureDevice` properties (ISO, exposure, white balance) from any thread?**
<br>A: Be careful. Properties like `device.iso`, `device.exposureDuration`, and `device.deviceWhiteBalanceGains` are generally safe to read, but `device.temperatureAndTintValues(for:)` may have internal threading requirements. In this project, these are read in the `captureOutput` delegate callback which runs on the session queue.

**Q: Why does `CameraPreviewView` use `layerClass` override instead of `addSublayer`?**
<br>A: This is Apple's recommended pattern from their AVCam sample code. When `layerClass` returns `AVCaptureVideoPreviewLayer.self`, UIKit creates and manages the preview layer as the view's root layer. This avoids manual sublayer lifecycle management and works correctly with SwiftUI's `UIViewRepresentable`.

**Q: Can I set `previewLayer.session` on the main thread?**
<br>A: Yes, if the session is already created (even if not yet configured). Apple's AVCam sample sets the session on the preview view in `viewDidLoad` on the main thread, before any session configuration happens on the session queue. The preview layer shows black until the session starts running.

**Q: Can I have multiple `AVCaptureVideoPreviewLayer` instances for the same session?**
<br>A: No. Only the most recently connected layer renders frames. All others go permanently black. This is a documented AVFoundation constraint. If you need the preview visible in multiple places, use a single layer and position it behind the views that need it (which is what this project does with the shared `CameraPreviewView` in `ContentView`).
