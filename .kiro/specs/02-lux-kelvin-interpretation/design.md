# Design Document: Lux & Kelvin Interpretation + Live Camera Preview

## Overview

This design adds three capabilities to the Light Meter app on top of the spec 01 skeleton:

1. **LuxInterpreter** — a pure function that maps a lux value to an environment description and actionable tip across 8 predefined ranges.
2. **KelvinInterpreter** — a pure function that maps a Kelvin value to a color tone label (with emoji) and recommended environment across 6 predefined ranges.
3. **Live camera preview** — replaces the black background with the real-time camera feed using `AVCaptureVideoPreviewLayer` wrapped in a `UIViewRepresentable`.
4. **Updated MeasurementView** — overlays raw numbers plus interpretation text on the camera preview with contrast handling (shadow/backdrop) and fixed font sizes.

### Key Design Decisions

- **Pure interpreter functions**: `LuxInterpreter` and `KelvinInterpreter` are stateless structs with static methods. No dependencies on AVFoundation or UIKit. This makes them trivially testable with property-based tests.
- **UIViewRepresentable for preview**: SwiftUI has no native `AVCaptureVideoPreviewLayer` wrapper. A thin `UIViewRepresentable` (`CameraPreviewView`) bridges UIKit's `AVCaptureVideoPreviewLayer` into SwiftUI. This is the standard iOS pattern.
- **Session exposure via public property**: `CameraManager` exposes its `AVCaptureSession` as a read-only property so `CameraPreviewView` can connect without duplicating session logic.
- **Fixed font sizes**: All text uses `.font(.system(size: N))` to prevent Dynamic Type from breaking the overlay layout, per the product spec's font scaling rules.
- **Interpretation as value type**: `InterpretationResult` is a simple struct with `description` and `tip` strings, returned by both interpreters.

## Architecture

```mermaid
graph TD
    A[LightMeterApp] --> B[ContentView]
    B --> C[MeasurementView]
    C --> D[CameraPreviewView<br/>UIViewRepresentable]
    D --> E[AVCaptureVideoPreviewLayer]
    E --> F[AVCaptureSession]

    B --> G[CameraManager<br/>ObservableObject]
    G --> F
    G -->|@Published lux| C
    G -->|@Published colorTemperature| C
    G -->|session property| D

    C --> H[LuxInterpreter]
    C --> I[KelvinInterpreter]
    H -->|InterpretationResult| C
    I -->|InterpretationResult| C
```

### Data Flow

1. `CameraManager` configures and runs `AVCaptureSession` (unchanged from spec 01).
2. `CameraManager` exposes `session` as a public read-only `AVCaptureSession` property.
3. `CameraPreviewView` connects an `AVCaptureVideoPreviewLayer` to that session, rendering the live feed full-screen.
4. On each frame, `CameraManager` publishes updated `lux` and `colorTemperature` values.
5. `MeasurementView` calls `LuxInterpreter.interpret(lux:)` and `KelvinInterpreter.interpret(kelvin:)` to get `InterpretationResult` values.
6. The view overlays raw numbers + interpretation text on the camera preview.

## Components and Interfaces

### InterpretationResult

A value type returned by both interpreters.

```swift
struct InterpretationResult: Equatable {
    let description: String
    let tip: String
}
```

### LuxInterpreter

Pure function mapping lux → environment description + tip.

```swift
struct LuxInterpreter {
    /// Maps a lux value to its environment description and user guide tip.
    /// Negative values fall back to the 0–10 range.
    static func interpret(lux: Double) -> InterpretationResult
}
```

Range table (8 ranges, no gaps):

| Range | Description | Tip |
|-------|-------------|-----|
| 0–10 | Very dark outdoors, full moon night | Pre-sleep conditions. Be careful when moving around. |
| 11–100 | Hallways, bathrooms, storage rooms, movie theaters | Suitable for passing through. Not appropriate for extended work. |
| 101–200 | Living room relaxation, dining, hotel rooms | Optimal for comfortable rest. Good for watching TV. |
| 201–500 | General office work, kitchen cooking, light reading | The most standard brightness for daily activities and office work. |
| 501–1,000 | Focused studying, precision handwork, store displays | Recommended for study rooms or detailed tasks like sewing. |
| 1,001–2,000 | Bright window (indoors), broadcast studios, operating rooms | Very bright. Suitable for video production or professional work. |
| 2,001–10,000 | Cloudy day outdoors, sunset outdoors | Good for outdoor activities. Partial shade level for plants. |
| 10,001+ | Direct sunlight on a clear day, noon outdoors | Strong sunlight. Protect your eyes and watch for plant burns. |

Implementation: a simple `switch` or chained `if-else` on the lux value. Values < 0 map to the 0–10 range.

### KelvinInterpreter

Pure function mapping Kelvin → color tone label + recommended environment.

```swift
struct KelvinInterpreter {
    /// Maps a Kelvin value to its color tone label and recommended environment.
    /// Values below 1000 fall back to the "Below 2,000K" range.
    static func interpret(kelvin: Double) -> InterpretationResult
}
```

Range table (6 ranges, no gaps across [1000, 15000]):

| Range | Color Tone | Recommended Environment |
|-------|-----------|------------------------|
| Below 2,000K | Candlelight / Sunset 🔥 | Psychological calm, pre-sleep, atmospheric cafes |
| 2,000K–3,499K | Warm White 💡 | Bedrooms, living rooms, relaxation spaces |
| 3,500K–4,999K | Natural White 🌤 | Kitchens, dressing rooms, bathrooms |
| 5,000K–6,499K | Daylight 📖 | Study rooms, offices, precision work (improves focus) |
| 6,500K–9,999K | Cool White ❄ | Hospitals, factories, warehouses |
| 10,000K+ | Blue Sky 🧊 | Clear day shade, specialized lab environments |

Implementation: chained `if-else` on the kelvin value. Values < 1000 map to "Below 2,000K".

### CameraPreviewView

A `UIViewRepresentable` that wraps `AVCaptureVideoPreviewLayer`.

```swift
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}
```

### CameraManager (modified)

Adds a public read-only accessor for the capture session. All existing behavior is preserved.

```swift
class CameraManager: NSObject, ObservableObject {
    // ... existing @Published properties unchanged ...

    /// Exposes the capture session for CameraPreviewView to connect.
    var session: AVCaptureSession { captureSession }

    // ... rest unchanged ...
}
```

### MeasurementView (updated)

Replaces the black `ZStack` background with `CameraPreviewView`. Overlays raw values + interpretation text with contrast handling.

```swift
struct MeasurementView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        ZStack {
            // Camera preview or black fallback
            if cameraManager.permissionGranted {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Error / permission states, or measurement overlay
            if !cameraManager.permissionGranted {
                // permission message (unchanged)
            } else if let error = cameraManager.cameraError {
                // error message (unchanged)
            } else {
                VStack(spacing: 24) {
                    // Lux section
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", cameraManager.lux))
                            .font(.system(size: 72, weight: .thin, design: .monospaced))
                        Text("lux")
                            .font(.system(size: 18))
                        Text(LuxInterpreter.interpret(lux: cameraManager.lux).description)
                            .font(.system(size: 14))
                        Text(LuxInterpreter.interpret(lux: cameraManager.lux).tip)
                            .font(.system(size: 12))
                    }
                    // Kelvin section
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", cameraManager.colorTemperature))
                            .font(.system(size: 72, weight: .thin, design: .monospaced))
                        Text("K")
                            .font(.system(size: 18))
                        Text(KelvinInterpreter.interpret(kelvin: cameraManager.colorTemperature).description)
                            .font(.system(size: 14))
                        Text(KelvinInterpreter.interpret(kelvin: cameraManager.colorTemperature).tip)
                            .font(.system(size: 12))
                    }
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .padding()
            }
        }
    }
}
```

## Data Models

### InterpretationResult

| Field | Type | Description |
|-------|------|-------------|
| `description` | `String` | Environment description or color tone label |
| `tip` | `String` | Actionable user guide tip or recommended environment |

### LuxInterpreter Range Data (compile-time constant)

| Index | Lower Bound | Upper Bound | Description | Tip |
|-------|-------------|-------------|-------------|-----|
| 0 | 0 | 10 | Very dark outdoors, full moon night | Pre-sleep conditions. Be careful when moving around. |
| 1 | 11 | 100 | Hallways, bathrooms, storage rooms, movie theaters | Suitable for passing through. Not appropriate for extended work. |
| 2 | 101 | 200 | Living room relaxation, dining, hotel rooms | Optimal for comfortable rest. Good for watching TV. |
| 3 | 201 | 500 | General office work, kitchen cooking, light reading | The most standard brightness for daily activities and office work. |
| 4 | 501 | 1000 | Focused studying, precision handwork, store displays | Recommended for study rooms or detailed tasks like sewing. |
| 5 | 1001 | 2000 | Bright window (indoors), broadcast studios, operating rooms | Very bright. Suitable for video production or professional work. |
| 6 | 2001 | 10000 | Cloudy day outdoors, sunset outdoors | Good for outdoor activities. Partial shade level for plants. |
| 7 | 10001 | ∞ | Direct sunlight on a clear day, noon outdoors | Strong sunlight. Protect your eyes and watch for plant burns. |

### KelvinInterpreter Range Data (compile-time constant)

| Index | Lower Bound | Upper Bound | Color Tone | Recommended Environment |
|-------|-------------|-------------|-----------|------------------------|
| 0 | 0 | 1999 | Candlelight / Sunset 🔥 | Psychological calm, pre-sleep, atmospheric cafes |
| 1 | 2000 | 3499 | Warm White 💡 | Bedrooms, living rooms, relaxation spaces |
| 2 | 3500 | 4999 | Natural White 🌤 | Kitchens, dressing rooms, bathrooms |
| 3 | 5000 | 6499 | Daylight 📖 | Study rooms, offices, precision work (improves focus) |
| 4 | 6500 | 9999 | Cool White ❄ | Hospitals, factories, warehouses |
| 5 | 10000 | ∞ | Blue Sky 🧊 | Clear day shade, specialized lab environments |

### CameraManager Published State (additions)

| Property | Type | Description |
|----------|------|-------------|
| `session` | `AVCaptureSession` (read-only) | Exposed for `CameraPreviewView` to connect |

All existing published properties (`lux`, `colorTemperature`, `cameraError`, `permissionGranted`) remain unchanged.


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Lux range mapping correctness

*For any* Double value (including negative, zero, and arbitrarily large positive values), `LuxInterpreter.interpret(lux:)` SHALL return an `InterpretationResult` whose `description` and `tip` match exactly the predefined range that contains that value. Negative values SHALL map to the 0–10 range. The 8 ranges SHALL cover the entire non-negative number line with no gaps.

**Validates: Requirements 1.1, 1.4, 1.5**

### Property 2: Kelvin range mapping correctness

*For any* Double value (including values below 1,000 and above 15,000), `KelvinInterpreter.interpret(kelvin:)` SHALL return an `InterpretationResult` whose `description` and `tip` match exactly the predefined range that contains that value. Values below 1,000 SHALL map to the "Below 2,000K" range. The 6 ranges SHALL cover the entire number line with no gaps.

**Validates: Requirements 2.1, 2.4, 2.5**

## Error Handling

| Scenario | Component | Behavior |
|----------|-----------|----------|
| Negative lux value | LuxInterpreter | Returns the 0–10 range result (safe fallback). No crash. |
| Kelvin below 1,000 | KelvinInterpreter | Returns the "Below 2,000K" range result (safe fallback). No crash. |
| Extremely large lux value (e.g., 1,000,000) | LuxInterpreter | Returns the 10,001+ range result. No overflow. |
| Extremely large Kelvin value | KelvinInterpreter | Returns the 10,000K+ range result. No overflow. |
| NaN or infinity lux | LuxInterpreter | Falls through to the 0–10 range (comparison with NaN is false). |
| NaN or infinity Kelvin | KelvinInterpreter | Falls through to the "Below 2,000K" range. |
| Camera permission denied | MeasurementView | Shows black background + permission message (unchanged from spec 01). Camera preview not rendered. |
| Camera error | MeasurementView | Shows error message overlaid on black background (unchanged from spec 01). |
| Session not yet configured | CameraManager.session | Returns the AVCaptureSession instance (created at init). CameraPreviewView can safely reference it — the preview layer simply shows nothing until the session starts. |

## Testing Strategy

### Unit Tests

Unit tests verify specific examples, edge cases, and exact string content.

**LuxInterpreter:**
- 8 example tests, one per range, at representative values (5, 50, 150, 350, 750, 1500, 5000, 50000)
- Verify exact `description` and `tip` strings for each range
- Edge case: boundary values (0, 10, 11, 100, 101, 200, 201, 500, 501, 1000, 1001, 2000, 2001, 10000, 10001)
- Edge case: negative value returns 0–10 range result

**KelvinInterpreter:**
- 6 example tests, one per range, at representative values (1500, 2700, 4000, 5500, 8000, 12000)
- Verify exact `description` and `tip` strings for each range
- Edge case: boundary values (1000, 1999, 2000, 3499, 3500, 4999, 5000, 6499, 6500, 9999, 10000, 15000)
- Edge case: value below 1000 returns "Below 2,000K" range result

**MeasurementView (UI verification):**
- Permission denied → black background + permission message
- Error state → error message displayed
- Normal state → lux value, lux description, lux tip, Kelvin value, color tone, recommended environment all present

### Property-Based Tests

Property-based tests use Swift Testing (`import Testing`) with random generation and 100+ iterations per property, following the same pattern established in spec 01.

**Configuration:**
- Minimum 100 iterations per property test
- Random generation using `SystemRandomNumberGenerator`
- Each test references its design document property

**Property tests to implement:**

1. **Feature: 02-lux-kelvin-interpretation, Property 1: Lux range mapping correctness**
   - Generate 100 random `Double` values across the range [-1000, 200000]
   - For each value, call `LuxInterpreter.interpret(lux:)` and compute the expected range based on the value
   - Verify the returned `InterpretationResult` matches the expected range's description and tip
   - Verify negative values always return the 0–10 range result
   - Tag: `Feature: 02-lux-kelvin-interpretation, Property 1: Lux range mapping correctness`

2. **Feature: 02-lux-kelvin-interpretation, Property 2: Kelvin range mapping correctness**
   - Generate 100 random `Double` values across the range [0, 20000]
   - For each value, call `KelvinInterpreter.interpret(kelvin:)` and compute the expected range based on the value
   - Verify the returned `InterpretationResult` matches the expected range's description and tip
   - Verify values below 1000 always return the "Below 2,000K" range result
   - Tag: `Feature: 02-lux-kelvin-interpretation, Property 2: Kelvin range mapping correctness`

### Integration Tests (On-Device)

These require a physical iPhone and cannot be automated in CI:

- Camera preview renders live feed as full-screen background with aspect-fill (no black bars)
- Interpretation text updates in real time as lighting conditions change
- Text is readable against the camera preview (contrast verification)
- Preview stops/resumes correctly on background/foreground transitions
- Session property is accessible before and after configuration without crash
