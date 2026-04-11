---
inclusion: always
---
# Deterministic Split

Separate deterministic logic from side effects. This is the single most important architectural rule for this project.

## Three Layers

### 1. Pure Logic — Deterministic, no external dependencies

- Same inputs always produce same outputs
- No calls to hardware, network, filesystem, or databases
- No access to system clock, random generators, or environment variables
- All non-determinism injected as parameters
- Trivially testable without mocks

### 2. Effects — Thin wrappers around external systems

- Camera, sensors, storage, network, filesystem
- Keep these as thin as possible — minimal logic
- One responsibility per effect function
- These require mocks or real hardware to test

### 3. Glue — Wires pure logic to effects

- No business logic allowed
- No direct external calls allowed
- Parses input → calls pure logic → calls effects → formats output
- In UI apps, this is the view/controller layer

## Rules

- Business logic MUST live in the pure layer
- The pure layer MUST NOT import or depend on platform-specific frameworks for side effects
- Effects MUST NOT contain business logic — they fetch, store, or send data
- Glue MUST NOT contain business logic or direct external calls

## Why This Matters for Cross-Platform

The pure layer is portable. When building the same app on a different platform (iOS → Android, Swift → Kotlin), the pure logic is identical — only the effects layer changes because platform APIs differ. This is the primary reason for enforcing the split.

## Swift / SwiftUI Mapping

| Layer | Swift Pattern | Example |
|-------|--------------|---------|
| Pure Logic | `struct` with `static` methods, no framework imports | `LuxCalculator`, `LuxInterpreter` |
| Effects | `class` using AVFoundation, CoreData, URLSession | `CameraManager` |
| Glue | SwiftUI `View` with `@StateObject` / `@ObservedObject` | `ContentView`, `MeasurementView` |

## Test Expectations

| Layer | Testability | Mocks Required |
|-------|------------|----------------|
| Pure Logic | 100% unit testable, property-based testable | None |
| Effects | Requires mocks or real hardware | Yes |
| Glue | Integration tests or UI tests | Depends |
