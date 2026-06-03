# Building LightMeter for Android

Welcome to the project. You're building an Android version of a light meter app using React Native. The iOS version in this repo is your reference — same features, same logic, just adapted for Android and React Native.

The app points the camera at a scene and tells you how bright the light is (lux), what color it is (Kelvin), and whether it flickers. Don't worry if that sounds like a lot — the first two are surprisingly simple once the camera is set up, and the science is covered in the [Light Science Primer](docs/light-science-primer.md) whenever you need it.

This guide is a map, not a script. It's here to help you find your way through the codebase and make good decisions. Feel free to adapt the approach to whatever works best for you.

---

<a id="table-of-contents"></a>
## Table of Contents

1. [Team Overview](#team-overview)
2. [The Architecture (Worth Understanding Early)](#the-architecture-worth-understanding-early)
3. [Getting Camera Data — The Trickiest Part](#getting-camera-data--the-trickiest-part)
4. [What to Build](#what-to-build)
5. [Suggested Pace](#suggested-pace)
6. [Not in Scope](#not-in-scope)
7. [Appendix: React Native Reference](#appendix-react-native-reference)
8. [Sources](#sources)

---

## [Team Overview](#table-of-contents)

Two developers, roughly three weeks.

- **Lead developer** — project setup, camera pipeline, the main tabs (LUX and Temperature), records shell, and general integration
- **Support developer** — flicker detection, which is a self-contained feature involving a native module and its own UI tab

The one shared dependency is the camera pipeline. The lead sets it up, and the support developer builds on top of it for flicker analysis. It's worth syncing on this early so you're not blocked later.

---

## [The Architecture (Worth Understanding Early)](#table-of-contents)

The iOS codebase follows a pattern called "functional core, imperative shell" [[1]](#source-1) [[2]](#source-2) — you'll see it called the "deterministic split" in the codebase and steering docs. The full breakdown of how this maps to the file tree is in the [Developer Guide](docs/developer-guide.md), but here's the short version:

- **Pure logic** — deterministic functions with no side effects. Same input always gives the same output. In React Native, these become TypeScript modules in something like `src/logic/`.
- **Effects** — thin wrappers around hardware (camera, sensors). No business logic here. In React Native, this is your native modules or library wrappers.
- **Glue** — wires the other two together. React components, hooks, context. No business logic, no direct platform calls.

The reason this matters for you: the entire pure logic layer ports from Swift to TypeScript with zero changes to the algorithms. Same formulas, same thresholds, same output strings. You're only rewriting the camera access code and the UI.

---

## [Getting Camera Data — The Trickiest Part](#table-of-contents)

This is probably the most challenging piece of the project, so it's worth understanding upfront. Everything else builds on top of it.

The app needs three values from the camera on every frame:

- **ISO** — sensor sensitivity, used to calculate lux
- **Exposure duration** — how long the sensor was open, also used for lux
- **White balance gains** — used to estimate color temperature (Kelvin)

On iOS, these are just properties you read from the camera device. On Android, they come from `CaptureResult` metadata attached to each frame [[3]](#source-3).

The catch: `react-native-vision-camera` [[4]](#source-4) doesn't expose this metadata to JavaScript out of the box. The recommended approach is to write a small Kotlin frame processor plugin [[5]](#source-5) that reads the metadata and passes it back to JavaScript. It's a focused piece of native code — not a huge lift, but it is the part most likely to take longer than expected.

A few things that might help:

- Samsung Galaxy S24/S25 flagships support full Camera2 metadata [[3]](#source-3), so you won't hit capability issues on the target devices
- For color temperature, Android doesn't have a built-in conversion like iOS does. You'll compute an approximate Kelvin from the red/blue gain ratio — a lookup table or McCamy's formula [[6]](#source-6) works fine. It doesn't need to be precise since the app classifies into broad ranges
- The lux formula uses the lens aperture as a constant. iPhone is f/1.6, Galaxy S24 is f/1.7, Galaxy S25 is f/1.9. The calculator already accepts this as a parameter

If this part feels stuck, that's a good time to reach out. It's the highest-risk item and it's better to surface problems early.

---

## [What to Build](#table-of-contents)

Roughly in priority order. The first group is the core — the app doesn't really work without it. The second group rounds it out. The third is stretch goals if things go smoothly.

### Core (aim for week 1–2)

- [ ] React Native project setup with camera access on Android [[4]](#source-4)
- [ ] Live camera preview on screen
- [ ] Per-frame metadata extraction (ISO, exposure, white balance) via native plugin [[5]](#source-5)
- [ ] Port the 8 pure logic files from `Logic/` to TypeScript (see appendix for the list)
- [ ] Unit tests for the ported logic — boundary values, representative values, ideally property-based tests with something like `fast-check` [[7]](#source-7)
- [ ] **LUX tab** — live mode with camera preview and a translucent card showing real-time lux and Kelvin, plus a camera toggle button for switching front/rear cameras. Capture mode that freezes the frame, autosaves the record, and expands the card to show interpretation, tip, a 2-column activity grid, and comparison sentence. Close button to return to live mode
- [ ] **Temperature tab** — live mode only. Camera preview with a card showing Kelvin, color tone, and environment tip
- [ ] **Tab navigation** — four tabs (LUX, Temperature, Check, Records) using a custom floating capsule segmented tab switcher. Camera runs on the first two tabs, stops on the other two. Switching between two camera tabs should not stop/start the session — use the `TabTransitionAction` logic to skip redundant cycles. Camera pauses when the app goes to background

### Should get done (week 2–3)

- [ ] **Flicker detection** *(support developer)* — analyze light flicker from the camera feed using FFT-based luminance analysis. The native module computes the raw flicker percentage; the classification into safety levels happens in TypeScript. The Check tab shows flicker %, safety level, description, and a color-coded indicator
- [ ] **Records tab** — persistent captured records. List of saved measurements, swipe-to-delete, tap for detail view, empty state
- [ ] **Number formatting** — locale-aware with thousands separators (`Intl.NumberFormat`)

### Stretch goals

- [ ] Camera toggle (front/rear)
- [ ] Permission and error state UI (shared component for camera tabs)
- [ ] Design polish — blur effects [[9]](#source-9), consistent spacing, accessibility labels
- [ ] Settings placeholder (gear icon → "Coming Soon" screen)

### A note on flicker detection

This is the most technically interesting part of the project. It is fully implemented in the iOS reference application in this repository, which provides a high-performance native blueprint utilizing 240fps capture and Apple's Accelerate framework vDSP FFT. The science and detection approach are covered in detail in the [Light Science Primer](docs/light-science-primer.md) (the "Flicker: The Hard One" section). Here's what matters for your Android implementation:

This will almost certainly need to run in a native module (Kotlin) for performance. `react-native-vision-camera` supports custom frame processor plugins [[10]](#source-10) for exactly this kind of thing. On the native side, JTransforms [[11]](#source-11) is a good FFT library option.

The flicker safety thresholds in the app are informed by IEEE 1789 [[12]](#source-12), which recommends a limit of ~8–10% flicker at 100–120Hz for comfortable viewing. The classification logic (flicker % → safety level like "Safe" or "Dangerous") is pure logic and belongs in TypeScript with unit tests.

Take your time with this one. It's research-heavy at first, and that's expected.

---

## [Suggested Pace](#table-of-contents)

This is a rough guide, not a deadline. Adjust based on what you're learning as you go.

### Week 1 — Get numbers on screen

The goal is to point the phone at a lamp and see a lux value update in real time. If you get there by end of week 1, everything else is manageable.

**Lead developer:**
- [ ] Project setup and dependencies
- [ ] Camera preview running on a Samsung device
- [ ] Frame metadata extraction working — this is the risky part, start here
- [ ] Pure logic ported to TypeScript with passing tests
- [ ] Basic LUX tab showing live values

**Support developer:**
- [ ] Research flicker detection approaches [[12]](#source-12) [[13]](#source-13)
- [ ] Native module skeleton for the frame processor plugin [[5]](#source-5)
- [ ] Mean luminance computation working per frame
- [ ] Start building the rolling buffer + FFT pipeline [[11]](#source-11)

### Week 2 — Build out the tabs

**Lead developer:**
- [ ] Capture mode on the LUX tab
- [ ] Temperature tab
- [ ] Tab navigation with camera lifecycle
- [ ] Number formatting
- [ ] Records tab shell

**Support developer:**
- [ ] End-to-end flicker percentage computation
- [ ] Classification logic in TypeScript with tests
- [ ] Check tab UI

### Week 3 — Polish and wrap up

**Lead developer:**
- [ ] Camera toggle, permission states, design polish
- [ ] Integration testing on Samsung device
- [ ] Any remaining items from week 2

**Support developer:**
- [ ] Flicker accuracy tuning on real lights
- [ ] Edge cases (no flicker, camera switching, background/foreground)
- [ ] Document the flicker detection approach

---

## [Not in Scope](#table-of-contents)

Just so it's clear — these are explicitly off the table for this engagement:

- iOS support (Android only)
- Real data persistence [Implemented in iOS reference app using UserDefaults]
- Play Store submission
- Settings screen (placeholder only)
- Localization [Implemented in iOS reference app using AppLanguage/LocalizedStrings]
- Background processing
- Cloud sync or accounts

---

## [Appendix: React Native Reference](#table-of-contents)

For the full iOS codebase map, module reference, data flow diagrams, and test suite details, see the [Developer Guide](docs/developer-guide.md). This section only covers what's specific to the React Native port.

### Files to port (pure logic → TypeScript)

All 12 files in `Logic/`. The algorithms are identical — you're translating syntax, not logic.

- `LuxCalculator` — `lux = (250 × aperture²) / (ISO × exposure)`. Returns 0 for invalid inputs.
- `ColorTemperatureCalculator` — clamps raw Kelvin to [1000, 15000]
- `LuxInterpreter` — lux → 1 of 8 ranges → `{ description, tip }` (with localization parameters)
- `KelvinInterpreter` — Kelvin → 1 of 6 ranges → `{ description, tip }` (with localization parameters)
- `ComparisonGenerator` — "Brighter than X but darker than Y"
- `LuxRange` — `rangeIndex(lux)` → 0–7, shared by interpreter and comparison generator
- `InterpretationResult` — TypeScript interface: `{ description: string, tip: string }`
- `TabTransitionAction` — `resolve(from, to)` → `.startSession`, `.stopSession`, or `.none`. Determines camera session action for tab transitions — camera↔camera transitions return `.none` to avoid unnecessary stop/start cycles. Also provides `isCameraTab(tab)` helper.
- `AppLanguage` — maps locales (`en`, `ko`, `fr`) and handles system language detection.
- `LocalizedStrings` — dictionary mapping UI keys to translations for English, Korean, and French.
- `FlickerInterpreter` — maps raw safety level strings to localized titles.
- `ActivityChip` — defines standard activities and matches active ones per Lux range.

### Platform differences

- **Camera API:** iOS uses AVFoundation; Android uses Camera2 [[3]](#source-3) via react-native-vision-camera [[4]](#source-4)
- **Color temperature:** iOS has a built-in conversion; Android requires manual computation from white balance gains [[6]](#source-6)
- **Blur effects:** iOS is one line (`.ultraThinMaterial`); Android needs `@react-native-community/blur` [[9]](#source-9) or a semi-transparent overlay
- **Tab navigation:** `@react-navigation/bottom-tabs` [[8]](#source-8)
- **State management:** React hooks work fine; Zustand or Jotai if you want something more structured
- **Testing:** Jest or Vitest [[14]](#source-14) for unit tests; `fast-check` [[7]](#source-7) for property-based tests

---

If anything here is unclear or you run into a wall — especially with the camera metadata extraction — please reach out. It's genuinely the hardest part of the project, and it's much better to surface issues early than to push through alone.

---

## [Sources](#table-of-contents)

<a id="source-1"></a>
**[1]** [Boundaries — destroyallsoftware.com](https://www.destroyallsoftware.com/talks/boundaries)
<br>Gary Bernhardt's talk introducing the "functional core, imperative shell" pattern — the architectural foundation for this project (referred to as the "deterministic split" in the codebase).

<a id="source-2"></a>
**[2]** [Functional Core, Imperative Shell — functional-architecture.org](https://functional-architecture.org/functional_core_imperative_shell)
<br>Written reference for the pattern. Covers how the pure core handles logic while the imperative shell orchestrates side effects.

<a id="source-3"></a>
**[3]** [CaptureResult — Android Developers](https://developer.android.com/reference/android/hardware/camera2/CaptureResult)
<br>Android API reference for per-frame camera metadata including `SENSOR_SENSITIVITY`, `SENSOR_EXPOSURE_TIME`, and `COLOR_CORRECTION_GAINS`.

<a id="source-4"></a>
**[4]** [React Native Vision Camera — Getting Started — react-native-vision-camera.com](https://react-native-vision-camera.com/docs/guides)
<br>The main camera library for this project. Covers setup, permissions, and basic usage on Android.

<a id="source-5"></a>
**[5]** [Creating Frame Processor Plugins (Android/Kotlin) — react-native-vision-camera.com](https://react-native-vision-camera.com/docs/guides/frame-processors-plugins-android)
<br>Step-by-step guide for writing a native Kotlin plugin that reads frame data and returns values to JavaScript.

<a id="source-6"></a>
**[6]** [Correlated Color Temperature — Wikipedia](https://en.wikipedia.org/wiki/Correlated_color_temperature)
<br>Background on McCamy's formula for computing Kelvin from chromaticity coordinates, relevant to the Android color temperature conversion.

<a id="source-7"></a>
**[7]** [fast-check — GitHub](https://github.com/dubzzz/fast-check)
<br>Property-based testing framework for TypeScript and JavaScript. Generates random inputs to verify properties that should always hold true.

<a id="source-8"></a>
**[8]** [Bottom Tabs Navigator — reactnavigation.org](https://reactnavigation.org/docs/bottom-tab-navigator/)
<br>The standard React Native library for bottom tab navigation. Covers setup, customization, and hiding tabs.

<a id="source-9"></a>
**[9]** [@react-native-community/blur — GitHub](https://github.com/Kureev/react-native-blur)
<br>Blur and vibrancy effects for Android and iOS. Useful for frosted card overlays on measurement screens.

<a id="source-10"></a>
**[10]** [Frame Processors — react-native-vision-camera.com](https://react-native-vision-camera.com/docs/guides/frame-processors)
<br>How VisionCamera lets you run JavaScript or native code on every camera frame in real time.

<a id="source-11"></a>
**[11]** [JTransforms — GitHub](https://github.com/wendykierp/JTransforms)
<br>Open source, multithreaded FFT library written in pure Java. Works on Android for the flicker detection native module.

<a id="source-12"></a>
**[12]** [IEEE 1789-2015 — ieee.org](https://standards.ieee.org/standard/1789-2015.html)
<br>Industry standard for recommended practices on modulating current in LED lighting to limit flicker health risks.

<a id="source-13"></a>
**[13]** [Lighting Ergonomics: Flicker — CCOHS](https://www.ccohs.ca/oshanswers/ergonomics/lighting_flicker.html)
<br>Plain-language overview of flicker causes, health effects, and frequency thresholds from the Canadian occupational health authority.

<a id="source-14"></a>
**[14]** [Vitest — vitest.dev](https://vitest.dev/)
<br>A fast, modern test runner that works well with TypeScript projects. A good alternative to Jest.

<a id="source-15"></a>
**[15]** [VisionCamera GitHub Repository — github.com](https://github.com/mrousavy/react-native-vision-camera)
<br>Source code, issues, and community examples for the VisionCamera library. Useful when the official docs don't cover an edge case.

Content was rephrased for compliance with licensing restrictions.
