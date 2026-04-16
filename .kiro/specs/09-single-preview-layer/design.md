# Single Preview Layer — Design

<a id="table-of-contents"></a>

## Table of Contents

- [Overview](#overview)
- [Root Cause](#root-cause)
- [Fix Strategy](#fix-strategy)
- [Affected Files](#affected-files)
- [Correctness Properties](#correctness-properties)
- [On-Device Testing Objectives](#on-device-testing-objectives)

## [Overview](#table-of-contents)

The camera preview is black because multiple `AVCaptureVideoPreviewLayer` instances are connected to the same `AVCaptureSession`. AVFoundation only renders to the last-connected layer — all others go permanently black. The fix moves the single `CameraPreviewView` to `ContentView` (behind the `TabView`) and converts `MeasurementView` and `TemperatureView` into transparent overlays that no longer create their own preview layers.

## [Root Cause](#table-of-contents)

### The problem

`MeasurementView` and `TemperatureView` each embed their own `CameraPreviewView(session:)`. Each `CameraPreviewView` creates a `VideoPreviewUIView` whose `layerClass` is `AVCaptureVideoPreviewLayer`, and assigns the session in `makeUIView`.

SwiftUI's `TabView` eagerly creates all tab content and keeps it alive. On launch, both tab bodies are evaluated, creating two `VideoPreviewUIView` instances with two `AVCaptureVideoPreviewLayer` instances, both pointing to the same `AVCaptureSession`.

AVFoundation's constraint: only the most recently connected `AVCaptureVideoPreviewLayer` renders frames for a given session. The other goes permanently black. Which layer "wins" depends on SwiftUI's internal view creation order, which is non-deterministic.

### Why frames still arrive

`AVCaptureVideoDataOutput` (used by `CameraFrameProvider`) is independent of the preview layer. It receives every frame regardless of how many preview layers exist. This is why lux/kelvin values update while the preview is black.

### Why spec 08 didn't fix it

Spec 08 fixed session lifecycle (stop/start cycles on tab switches). The session was never the problem — it was running correctly the entire time. The problem is the preview layer architecture.

## [Fix Strategy](#table-of-contents)

### Option A — Single preview at ContentView level

Move the `CameraPreviewView` out of individual tab views and into `ContentView`, positioned behind the `TabView` in a `ZStack`. Tab content views become transparent overlays.

### Architecture before (broken)

```
ContentView
└── TabView
    ├── MeasurementView
    │   ├── CameraPreviewView ← AVCaptureVideoPreviewLayer #1
    │   └── measurement overlay
    ├── TemperatureView
    │   ├── CameraPreviewView ← AVCaptureVideoPreviewLayer #2
    │   └── temperature overlay
    ├── PlaceholderView (Check)
    └── PlaceholderView (Records)
```

Two preview layers → one is always black.

### Architecture after (fixed)

```
ContentView
├── CameraPreviewView ← single AVCaptureVideoPreviewLayer (behind TabView)
└── TabView
    ├── MeasurementView (transparent overlay, no preview layer)
    ├── TemperatureView (transparent overlay, no preview layer)
    ├── PlaceholderView (Check)
    └── PlaceholderView (Records)
```

One preview layer → always renders.

### Key design decisions

1. The `CameraPreviewView` is placed in a `ZStack` behind the `TabView` in `ContentView`. It is only present when `permissionGranted` is true and the selected tab is a camera tab (0 or 1).

2. `MeasurementView` and `TemperatureView` remove their `CameraPreviewView` entirely. Their root becomes a transparent `ZStack` (or `Color.clear`) with their overlay content on top.

3. The `TabView` background must be transparent so the shared preview shows through. SwiftUI's default `TabView` has an opaque background — this needs to be cleared.

4. Non-camera tabs (2, 3) should NOT show the camera preview. The shared preview visibility is gated on `selectedTab` being a camera tab.

5. The captured-mode flow in `MeasurementView` (frozen frame overlay) continues to work because it overlays a `UIImage` on top of everything — the shared preview behind it is simply hidden by the opaque captured overlay.

## [Affected Files](#table-of-contents)

| File | Change |
|------|--------|
| `LightMeter/ContentView.swift` | Add shared `CameraPreviewView` behind `TabView` in a `ZStack`. Gate visibility on permission + camera tab. |
| `LightMeter/Features/Measurement/MeasurementView.swift` | Remove `CameraPreviewView`. Make root background transparent. |
| `LightMeter/Features/Temperature/TemperatureView.swift` | Remove `CameraPreviewView`. Make root background transparent. |
| `LightMeter/SharedViews/CameraStateOverlay.swift` | Review — currently unused by the two camera views, but verify it doesn't create extra preview layers if reintroduced. |

### Files NOT changed

| File | Reason |
|------|--------|
| `CameraPreviewView.swift` | The view itself is correct — `layerClass` override pattern is fine. The problem was creating multiple instances. |
| `CameraSessionManager.swift` | Session lifecycle is correct after spec 08. |
| `CameraFrameProvider.swift` | Frame delivery is unaffected. |
| `CameraViewModel.swift` | No changes needed — it already exposes `session` and `permissionGranted`. |
| `TabTransitionAction.swift` | Tab transition logic from spec 08 is correct and unchanged. |

## [Correctness Properties](#table-of-contents)

### Property 1 — Single preview layer invariant

At any point in the app's lifecycle, there SHALL be at most one `AVCaptureVideoPreviewLayer` with a non-nil `.session` property. This is enforced structurally by having exactly one `CameraPreviewView` in the view hierarchy.

### Property 2 — Preview visibility on camera tabs

When `permissionGranted` is true and `selectedTab` is a camera tab (0 or 1), the single `CameraPreviewView` SHALL be in the view hierarchy and visible.

### Property 3 — Preview hidden on non-camera tabs

When `selectedTab` is a non-camera tab (2 or 3), the camera preview SHALL NOT be visible. The placeholder content should be fully opaque.

### Property 4 — Overlay transparency

`MeasurementView` and `TemperatureView` SHALL have transparent backgrounds so the shared preview layer behind the `TabView` is visible through them.

### Property 5 — Preservation

All existing behavior from spec 08 (tab transition logic, session lifecycle, capture flow, camera toggle, background/foreground handling) SHALL remain unchanged.

## [On-Device Testing Objectives](#table-of-contents)

Four manual tests to run on a physical iPhone. These are the acceptance criteria for this fix.

### Test 1 — Fresh launch preview

Delete app → install → grant permission → Lux tab shows live preview within ~2s. NOT black.

### Test 2 — Camera tab switching round-trip

Lux → Temperature → Lux → Temperature (×5 rapid). Preview continuously visible on every switch. No black flash.

### Test 3 — Non-camera tab round-trip

Lux → Records → Lux → Temperature → Check → Temperature. Every return to a camera tab shows live preview within ~2s.

### Test 4 — Capture flow

Lux tab → capture → frozen frame + interpretation → Close → live preview resumes → switch to Temperature → switch back → capture again. No black screen at any point.
