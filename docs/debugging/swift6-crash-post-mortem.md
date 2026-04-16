# Swift 6 Actor Isolation Crash — Post-Mortem

A `@MainActor` closure ran on a background queue. Swift 6's runtime killed the app on every launch. The crash message looked like an AVFoundation threading issue, which sent us down the wrong path for six attempts before we read the stack trace properly.

This post-mortem covers what happened, why it was confusing, what fixed it, and the wrong turns we took along the way. The lessons apply to any Swift 6 project using `@MainActor` classes with callback-based Apple APIs.

---

<a id="table-of-contents"></a>
## Table of Contents

1. [The Crash](#1-the-crash)
2. [Root Cause](#2-root-cause)
3. [The Fix](#3-the-fix)
4. [Investigation Log](#4-investigation-log)
5. [Lessons](#5-lessons)
6. [Sources](#6-sources)

---

## [1. The Crash](#table-of-contents)

### Symptoms

The app installed on the iPhone but crashed immediately on launch — every single time. Running from Xcode with the debugger showed:

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

The crash message says `dispatch_assert_queue_fail` — which looks like an AVFoundation threading issue. The app uses `AVCaptureSession`, and Apple's docs are full of warnings about calling session methods on the wrong queue. This led us down a long path of trying to fix AVFoundation queue discipline.

That path was wrong.

### What it actually was

A Swift 6 strict concurrency runtime assertion. The crash message is identical because Swift's actor isolation checks use the same underlying `libdispatch` assertion mechanism. The only way to tell the difference is by reading the stack trace frames, not the crash message.

---

## [2. Root Cause](#table-of-contents)

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

### Why the crash message is misleading

The crash message (`dispatch_assert_queue_fail`) is identical to what AVFoundation produces when you call session methods on the wrong queue. Without reading the stack frames, it's impossible to distinguish between:

- AVFoundation: "you called `startRunning()` on the wrong queue"
- Swift concurrency: "this `@MainActor` closure is running on a non-main queue"

Both produce the exact same `_dispatch_assert_queue_fail` crash. The differentiator is in the stack frames:

- `_swift_task_checkIsolatedSwift` → Swift concurrency actor isolation
- `AVCaptureSession` or `AVCaptureDevice` frames near the top → AVFoundation queue discipline

---

## [3. The Fix](#table-of-contents)

### Primary fix — async/await instead of callbacks

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

### Why `DispatchQueue.main.async` didn't work

```swift
AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
    DispatchQueue.main.async {
        self?.permissionGranted = granted
    }
}
```

Still crashed. Swift checks actor isolation on the outer closure before its body executes. The `DispatchQueue.main.async` is inside the body — the runtime assertion fires before it ever runs.

### Why `Task { @MainActor in }` didn't work either

Same reason. The `Task` creation happens inside the outer closure, which is already being checked. The runtime assertion fires on the outer closure before the `Task` is even created.

### Secondary fix — `@Sendable` closure types

All closure properties called from background queues (`onError`, `onFrameUpdate`, completion handlers) must be typed as `@Sendable`:

```swift
var onError: (@Sendable (String) -> Void)?
```

The `@Sendable` annotation opts the closure out of actor isolation inheritance. Without it, closures assigned from a `@MainActor` context inherit that isolation and crash when called from background queues.

---

## [4. Investigation Log](#table-of-contents)

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

We removed the camera preview entirely from the UI (just showed a black screen) while keeping the camera session running in the background. It still crashed. This proved the preview layer was never the problem.

### The real breakthrough — reading the stack trace

With the preview eliminated, we looked at the stack trace more carefully. Frame 5 showed `closure #1 in CameraViewModel.requestPermission()` and Frame 3 showed `_swift_task_checkIsolatedSwift`. The crash was in the permission request callback, not in any AVFoundation code.

We spent 6+ attempts fixing the wrong thing because the crash message looked like an AVFoundation issue. The stack trace told the real story from the beginning — we just weren't reading it carefully enough.

---

## [5. Lessons](#table-of-contents)

### Swift concurrency

1. Never use callback-based APIs in `@MainActor` classes. Closures inherit actor isolation. If the API calls the closure on a background queue, Swift 6 will crash. Use `async/await` instead.

2. Mark closure properties as `@Sendable` when they'll be called from background queues. This prevents actor isolation inheritance.

3. Read stack frames, not crash messages. `_dispatch_assert_queue_fail` can mean either AVFoundation queue discipline or Swift actor isolation. The frames tell you which.

### AVFoundation

4. Never call `startRunning()` on the main thread. It blocks. Use a dedicated serial queue.

5. All session configuration on the session queue. `beginConfiguration`, `addInput`, `addOutput`, `commitConfiguration` — same serial queue.

6. Use `layerClass` override for preview layers. Override `layerClass` in a `UIView` subclass. Set the session on the main thread — the preview layer handles an unconfigured session gracefully.

### Debugging

7. Eliminate components to isolate. Remove the preview, remove the frame processing, remove the session — one at a time. If it still crashes, the removed component wasn't the cause.

8. Check the thread name in Xcode's debug navigator. Our crash was on `com.apple.coremedia.capture.tccserver` — that's Apple's privacy/permission framework, not AVFoundation's capture pipeline. The thread name was a clue we missed early on.

---

## [6. Sources](#table-of-contents)

<a id="source-1"></a>
**[1]** [Swift Evolution SE-0313 — Improved control over actor isolation](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md)
<br>The Swift Evolution proposal that defines how closures inherit actor isolation from their enclosing context.

<a id="source-2"></a>
**[2]** [AVCam: Building a Camera App — Apple Developer](https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app)
<br>Apple's reference camera app demonstrating correct `layerClass` override pattern and session queue discipline.
