# Troubleshooting — LightMeter iOS App

A record of the launch crash we hit when deploying to a physical iPhone, how we diagnosed it, and what actually fixed it. Written for the PM and two developers on this project.

---

<a id="table-of-contents"></a>
## Table of Contents

1. [Xcode Setup Issues](#1-xcode-setup-issues)
2. [The Crash](#2-the-crash)
3. [Root Cause — Swift 6 Actor Isolation](#3-root-cause--swift-6-actor-isolation)
4. [The Fix](#4-the-fix)
5. [How We Found It — Investigation Log](#5-how-we-found-it--investigation-log)
6. [Rules for Future Development](#6-rules-for-future-development)
7. [Q&A — Common Issues](#7-qa--common-issues)

---

## [1. Xcode Setup Issues](#table-of-contents)

Two quick setup issues that are unrelated to the crash but worth documenting.

### Wrong scheme — "LightMeter-Package"

If Xcode shows "LightMeter-Package" in the scheme selector, you opened the folder instead of the project. Close the workspace and double-click `LightMeter.xcodeproj` directly. The scheme should say "LightMeter" (no "-Package").

### Untrusted developer on iPhone

First time deploying from a new Apple ID, the phone may block the app. Go to Settings → General → VPN & Device Management → tap your developer profile → Trust. This is a one-time step.

---

## [2. The Crash](#table-of-contents)

### What happened

The app installed on the iPhone but crashed immediately on launch — every single time. Running from Xcode with the debugger showed this:

```
Thread N: EXC_BREAKPOINT (code=1, subcode=0x...)
0 _dispatch_assert_queue_fail
```

With the message:

```
"BUG IN CLIENT OF LIBDISPATCH: Assertion failed: "
"%sBlock was %sexpected to execute on queue [%s (%p)]"
```

### What it looked like

The crash message says "dispatch_assert_queue_fail" — which looks like an AVFoundation threading issue. The app uses `AVCaptureSession`, and Apple's docs are full of warnings about calling session methods on the wrong queue. This led us down a long path of trying to fix AVFoundation queue discipline. That path was wrong.

### What it actually was

A Swift 6 strict concurrency runtime assertion. The crash message is identical because Swift's actor isolation checks use the same underlying `libdispatch` assertion mechanism. The only way to tell the difference is by reading the stack trace frames, not the crash message.

---

## [3. Root Cause — Swift 6 Actor Isolation](#table-of-contents)

### The problem in one sentence

`CameraViewModel` is `@MainActor`. A closure defined inside it inherits main actor isolation. When Apple's privacy framework calls that closure on a background queue, Swift 6's runtime crashes because the closure is not on the main actor.

### The specific code

```swift
@MainActor
final class CameraViewModel: ObservableObject {
    func requestPermission() {
        // This closure inherits @MainActor from the class
        AVCaptureDevice.requestAccess(for: .video) { granted in
            // 💥 Swift runtime asserts: "this closure should be on main actor, but it's not"
            // The crash happens HERE, before any code inside runs
            self.permissionGranted = granted
        }
    }
}
```

`AVCaptureDevice.requestAccess(for:)` calls its completion handler on Apple's internal `com.apple.coremedia.capture.tccserver` queue. Because the closure is defined inside a `@MainActor` class, Swift 6 infers that the closure is main-actor-isolated. When it runs on the TCC queue instead, the runtime assertion fires.

### The stack trace that proved it

```
Frame 3: _swift_task_checkIsolatedSwift       libswift_Concurrency.dylib
Frame 5: closure #1 in CameraViewModel.requestPermission()
Frame 7: __tcc_server_send_request_authorization_block_invoke.96  TCC
Thread:  com.apple.coremedia.capture.tccserver (serial)
```

Frame 3 is the key: `_swift_task_checkIsolatedSwift`. This is Swift's concurrency runtime checking actor isolation — not AVFoundation checking queue discipline.

### Why this is confusing

The crash message (`dispatch_assert_queue_fail`) is identical to what AVFoundation produces when you call session methods on the wrong queue. Without reading the stack frames, it's impossible to distinguish between:

- AVFoundation: "you called `startRunning()` on the wrong queue"
- Swift concurrency: "this `@MainActor` closure is running on a non-main queue"

Both produce the exact same `_dispatch_assert_queue_fail` crash.

---

## [4. The Fix](#table-of-contents)

### Primary fix — use async/await instead of callbacks

Replace the callback-based `requestAccess` with the async/await version:

```swift
// BEFORE — crashes
func requestPermission() {
    AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        self?.permissionGranted = granted  // 💥
    }
}

// AFTER — works
func requestPermission() {
    Task {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        self.permissionGranted = granted  // ✅ back on @MainActor
    }
}
```

The `await` version suspends the current task, waits for the result, then resumes on the correct actor. No closure running on the wrong queue.

### Why wrapping in `DispatchQueue.main.async` didn't work

We tried this:

```swift
AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
    DispatchQueue.main.async {
        self?.permissionGranted = granted
    }
}
```

It still crashed. Swift checks actor isolation on the **outer closure** before its body executes. The `DispatchQueue.main.async` is inside the body — the runtime assertion fires before it ever runs.

### Why `Task { @MainActor in }` didn't work either

Same reason. The `Task` creation happens inside the outer closure, which is already being checked.

### Secondary fix — `@Sendable` closure types

All closure properties called from background queues (`onError`, `onFrameUpdate`, completion handlers) must be typed as `@Sendable`:

```swift
var onError: (@Sendable (String) -> Void)?
```

The `@Sendable` annotation opts the closure out of actor isolation inheritance. Without it, closures assigned from a `@MainActor` context would inherit that isolation and crash when called from background queues.

### Preview layer cleanup

While investigating, we also improved `CameraPreviewView` to use Apple's AVCam pattern (overriding `layerClass` instead of manually creating sublayers). This wasn't related to the crash but is the correct pattern.

---

## [5. How We Found It — Investigation Log](#table-of-contents)

This section documents the wrong turns we took. It's useful for understanding how to debug similar issues and why the obvious fixes didn't work.

### Attempt 1 — `sessionReady` flag

Theory: the preview layer was racing with session configuration.
Action: added a `@Published var sessionReady` flag, only showed the preview after setup completed.
Result: still crashed. The crash had nothing to do with the preview layer.

### Attempt 2 — Set preview session on background queue

Theory: `AVCaptureVideoPreviewLayer.session` must be set on a background queue.
Action: tried `DispatchQueue.global`, then the session queue.
Result: still crashed. Also hit Swift actor isolation build errors when accessing `UIView` properties from background queues.

### Attempt 3 — Separate sample buffer queue

Theory: the session queue was contended between frame delivery and session configuration.
Action: created a dedicated `sampleBufferQueue` for the video output delegate.
Result: still crashed. The queue separation was irrelevant to the actual problem.

### Attempt 4 — Apple's `layerClass` override pattern

Theory: creating `AVCaptureVideoPreviewLayer` as a sublayer was wrong; Apple uses `layerClass` override.
Action: rewrote `CameraPreviewView` with `layerClass` override.
Result: still crashed. Correct pattern, but not the cause.

### The breakthrough — diagnostic elimination test

We removed the camera preview entirely from the UI (just showed a black screen) while keeping the camera session running in the background. **It still crashed.** This proved the preview layer was never the problem.

### The real breakthrough — reading the stack trace

With the preview eliminated, we looked at the stack trace more carefully. Frame 5 showed `closure #1 in CameraViewModel.requestPermission()` and Frame 3 showed `_swift_task_checkIsolatedSwift`. The crash was in the permission request callback, not in any AVFoundation code. Swift's concurrency runtime was asserting actor isolation on a closure that Apple's TCC server was calling on a background queue.

### Lesson

We spent 6+ attempts fixing the wrong thing because the crash message (`dispatch_assert_queue_fail`) looked like an AVFoundation issue. The stack trace told the real story from the beginning — we just weren't reading it carefully enough.

---

## [6. Rules for Future Development](#table-of-contents)

### Swift concurrency rules

1. **Never use callback-based APIs in `@MainActor` classes.** Closures inherit actor isolation. If the API calls the closure on a background queue, Swift 6 will crash. Use `async/await` instead.

2. **Mark closure properties as `@Sendable`** when they'll be called from background queues. This prevents actor isolation inheritance.

3. **Read stack frames, not crash messages.** `_dispatch_assert_queue_fail` can mean either AVFoundation queue discipline or Swift actor isolation. The frames tell you which.

### AVFoundation rules

4. **Never call `startRunning()` on the main thread.** It blocks. Use a dedicated serial queue.

5. **All session configuration on the session queue.** `beginConfiguration`, `addInput`, `addOutput`, `commitConfiguration` — same serial queue.

6. **Use `layerClass` override for preview layers.** Override `layerClass` in a `UIView` subclass. Set the session on the main thread — the preview layer handles an unconfigured session gracefully.

### Debugging rules

7. **Eliminate components to isolate.** Remove the preview, remove the frame processing, remove the session — one at a time. If it still crashes, the removed component wasn't the cause.

8. **Check the thread name in Xcode's debug navigator.** Our crash was on `com.apple.coremedia.capture.tccserver` — that's Apple's privacy/permission framework, not AVFoundation's capture pipeline. The thread name was a clue we missed early on.


---

## [7. Q&A — Common Issues](#table-of-contents)

### Xcode & Build

**Q: Xcode says "Build Succeeded" but nothing happens on my iPhone.**
A: Check the scheme selector in the toolbar. If it says "LightMeter-Package", you opened the folder instead of the `.xcodeproj`. Close the workspace and open `LightMeter.xcodeproj` directly. Also make sure your iPhone (not a simulator) is selected as the run destination.

**Q: Xcode says "Signing for LightMeter requires a development team."**
A: Select the LightMeter target → Signing & Capabilities tab → check "Automatically manage signing" → pick your Apple ID from the Team dropdown. If your Apple ID isn't listed, add it via Xcode → Settings → Accounts.

**Q: Build fails with "No profiles for 'com.xxx.LightMeter' were found."**
A: Change the Bundle Identifier in the Signing & Capabilities tab to something unique, like `com.yourname.LightMeter`. Apple requires unique bundle IDs for device deployment.

**Q: I get "Unable to install — LightMeter" on my phone.**
A: Unlock your phone and try again. If it persists, check that your phone's iOS version meets the project's minimum deployment target. Also try: Xcode → Product → Clean Build Folder (`Cmd+Shift+K`), then rebuild.

---

### Device & Permissions

**Q: The app opens but shows "Camera access is required" even though I tapped Allow.**
A: Kill the app and relaunch. If it persists, go to iPhone Settings → LightMeter → toggle Camera permission off and back on. This can happen if the permission state gets cached incorrectly.

**Q: The app says "Untrusted Developer" when I tap it.**
A: iPhone Settings → General → VPN & Device Management → tap your developer profile → Trust. One-time step per Apple ID.

**Q: I don't see anything under VPN & Device Management.**
A: The developer profile only appears after the first install from Xcode. If it's not there, the app may already be trusted — just try opening it.

**Q: The camera preview is black but lux/kelvin values are updating.**
A: The preview layer might not have connected yet. Give it a second. If it stays black, check that no other app is using the camera (FaceTime, other camera apps). Kill those apps and retry.

---

### Crashes

**Q: The app crashes on launch with `_dispatch_assert_queue_fail`.**
A: This is the exact crash documented in this file. See [Section 3](#3-root-cause--swift-6-actor-isolation). The cause is a `@MainActor` closure being called on a background queue. The fix is to use `async/await` instead of callback-based APIs. Check `CameraViewModel` for any callback closures that aren't `@Sendable`.

**Q: How do I tell if a `dispatch_assert_queue_fail` crash is AVFoundation or Swift concurrency?**
A: Look at the stack trace frames in Xcode's debug navigator:
- If you see `_swift_task_checkIsolatedSwift` → it's Swift concurrency actor isolation.
- If you see `AVCaptureSession` or `AVCaptureDevice` frames near the top → it's AVFoundation queue discipline.
The crash message is identical for both. Only the stack frames tell you which.

**Q: The app crashes when I tap the capture button.**
A: `captureFrame()` accesses the latest sample buffer and does `CIContext` image processing. If the buffer has been invalidated by the time the capture runs, it can crash. This is a known area for improvement — the frame capture needs to copy the pixel buffer synchronously on the session queue before processing.

**Q: The app crashes after switching between tabs rapidly.**
A: The `startSession()` / `stopSession()` calls in `ContentView.onChange(of: selectedTab)` may overlap if you switch tabs faster than the session queue can process. The `sessionReady` guard helps, but rapid toggling can still cause issues. Avoid switching tabs while the session is starting up.

---

### Swift Concurrency

**Q: I added a new callback-based API call in `CameraViewModel` and it crashes. Why?**
A: `CameraViewModel` is `@MainActor`. Any closure you write inside it inherits main actor isolation. If the API calls your closure on a background queue, Swift 6 will crash. Use the `async/await` version of the API, or define the closure property as `@Sendable` so it doesn't inherit isolation.

**Q: What's the difference between `@Sendable` and `@MainActor` on a closure?**
A: `@MainActor` means "this closure must run on the main thread." `@Sendable` means "this closure can be safely passed across concurrency boundaries" — and critically, it **opts out** of inheriting actor isolation from the enclosing context. If you have a closure property that will be called from a background queue, type it as `@Sendable`.

**Q: Can I use `DispatchQueue.main.async` to get back to the main thread from a `@Sendable` closure?**
A: Yes. `@Sendable` closures don't inherit actor isolation, so they won't crash when called from background queues. Inside them, `DispatchQueue.main.async` works fine for hopping to the main thread to update `@Published` properties.

**Q: Why does `Task { @MainActor in }` not fix the crash?**
A: Because the `Task` is created inside the outer closure, which is already being checked for actor isolation. The runtime assertion fires on the outer closure before the `Task` is even created. The fix is to avoid the outer closure entirely by using `async/await`.

---

### AVFoundation & Camera

**Q: Where should I call `AVCaptureSession.startRunning()`?**
A: Always on a dedicated serial queue, never on the main thread. It's a blocking call that can take hundreds of milliseconds. Our project uses `sessionQueue` in `CameraSessionManager`.

**Q: Can I access `AVCaptureDevice` properties (ISO, exposure, white balance) from any thread?**
A: Be careful. Properties like `device.iso`, `device.exposureDuration`, and `device.deviceWhiteBalanceGains` are generally safe to read, but `device.temperatureAndTintValues(for:)` may have internal threading requirements. In our project, these are read in the `captureOutput` delegate callback which runs on the session queue.

**Q: Why does `CameraPreviewView` use `layerClass` override instead of `addSublayer`?**
A: This is Apple's recommended pattern from their AVCam sample code. When `layerClass` returns `AVCaptureVideoPreviewLayer.self`, UIKit creates and manages the preview layer as the view's root layer. This avoids manual sublayer lifecycle management and works correctly with SwiftUI's `UIViewRepresentable`.

**Q: Can I set `previewLayer.session` on the main thread?**
A: Yes, if the session is already created (even if not yet configured). Apple's AVCam sample sets the session on the preview view in `viewDidLoad` on the main thread, before any session configuration happens on the session queue. The preview layer shows black until the session starts running.

**Q: The camera preview freezes when the app goes to background and comes back.**
A: The app handles this via `willEnterForegroundNotification` and `didEnterBackgroundNotification` in `ContentView`. If the preview still freezes, the session may have been interrupted. Check for `AVCaptureSessionWasInterruptedNotification` and restart the session when `AVCaptureSessionInterruptionEndedNotification` fires.
