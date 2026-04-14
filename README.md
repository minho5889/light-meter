# Sunny Light Meter

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An iOS app that turns your iPhone camera into a real-time light measurement tool. Point your phone at any environment and instantly see brightness (lux), color temperature (Kelvin), and plain-language interpretations of what those numbers mean.

Built for anyone curious about their lighting: photographers checking exposure, parents evaluating nursery lighting, office workers wondering if their desk lamp is bright enough, or plant owners checking sunlight levels.

---

<a id="table-of-contents"></a>
## Table of Contents

1. [Project Status](#1-project-status)
2. [Getting Started](#2-getting-started)
3. [Project Structure](#3-project-structure)
4. [Architecture](#4-architecture)
5. [Documentation](#5-documentation)
6. [Specs](#6-specs)
7. [License](#7-license)

---

## [1. Project Status](#table-of-contents)

| Feature | Tab | Status | Description |
|---------|-----|--------|-------------|
| Live Lux + Kelvin | LUX | ✅ Built | Real-time brightness and color temperature with capture-to-interpret |
| Color Temperature | Temperature | ✅ Built | Live Kelvin reading with color tone label and environment tip |
| Flicker Detection | Check | 🔲 Placeholder | Light safety analysis — planned for React Native Android build |
| Records | Records | 🔲 Placeholder | Saved measurement history — UI shell planned |

---

## [2. Getting Started](#table-of-contents)

### Prerequisites

- macOS with Xcode installed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An iPhone running iOS 17+ (camera features require a physical device)
- A free or paid [Apple Developer account](https://developer.apple.com)

### Setup

```bash
# Clone the repo
git clone https://github.com/minho5889/light-meter.git
cd light-meter

# Generate the Xcode project
xcodegen generate

# Run pure logic tests (no Xcode needed)
swift build
swift test
```

### Run on device

1. Open the project: `open LightMeter.xcodeproj`
2. In Xcode, select the LightMeter target → Signing & Capabilities
3. Set your Team to your Apple Developer account
4. Connect your iPhone via USB, select it as the run destination
5. Press Cmd+R to build and run

First time on the phone: go to Settings → General → VPN & Device Management → trust your developer certificate.

### Run tests in Xcode

```bash
# Regenerate project if you added/moved files
xcodegen generate

# Then in Xcode: Product → Test (Cmd+U)
# Or from terminal for pure logic only:
swift test
```

---

## [3. Project Structure](#table-of-contents)

```
LightMeter/
├── LightMeterApp.swift              # App entry point
├── ContentView.swift                # Tab navigation, camera lifecycle
├── Logic/                           # Pure logic — no side effects, fully testable
│   ├── LuxCalculator.swift
│   ├── LuxInterpreter.swift
│   ├── LuxRange.swift
│   ├── KelvinInterpreter.swift
│   ├── ColorTemperatureCalculator.swift
│   ├── ComparisonGenerator.swift
│   └── InterpretationResult.swift
├── Camera/                          # Effects — thin hardware wrappers
│   ├── CameraSessionManager.swift
│   ├── CameraFrameProvider.swift
│   └── CameraViewModel.swift
├── Features/                        # Feature screens
│   ├── Measurement/
│   └── Temperature/
├── SharedViews/                     # Reusable view components
└── Design/
    └── DesignConstants.swift

LightMeterTests/
├── Logic/                           # 113 tests covering all pure logic
└── Formatting/
```

---

## [4. Architecture](#table-of-contents)

The app follows a three-layer deterministic split:

| Layer | Rule | Examples |
|-------|------|---------|
| Pure Logic | Same inputs → same outputs. No hardware, no frameworks. | `LuxCalculator`, `LuxInterpreter`, `KelvinInterpreter` |
| Effects | Thin wrappers around camera APIs. Minimal logic. | `CameraSessionManager`, `CameraFrameProvider` |
| Glue | Wires logic to effects. No business logic. | `CameraViewModel`, SwiftUI views |

The pure logic layer is 100% unit testable without mocks or devices, and portable to other platforms. See the [Developer Guide](docs/developer-guide.md) for the full module reference and data flow diagrams.

---

## [5. Documentation](#table-of-contents)

Four documents cover everything you need to know. Read them in this order:

### 1. [Light Science Primer](docs/light-science-primer.md)

Start here. Before touching any code, understand what the app actually measures. This doc explains lux, Kelvin, and flicker in plain language — what they are physically, why people care about them, and how a phone camera captures them. It takes 15 minutes and saves hours of confusion later when you encounter the formulas and range tables in the code.

### 2. [Developer Guide](docs/developer-guide.md)

Read this second. It maps the science to the code — which module implements which formula, how data flows from the camera hardware through three layers to the screen, and how the test suite covers each module. It includes the product requirements (lux/Kelvin range tables, capture flow) so you know what the app is supposed to do, and architecture diagrams so you know how it does it.

### 3. [GitHub Guide](docs/github-guide.md)

Read this before making your first commit. It covers the Git workflow for this project — branching, commit message conventions, and pull request process. If you already know Git well, skim the common commands table at the bottom and move on.

### 4. [React Native Handover](docs/react-native-handover.md)

Read this only if you are working on the Android port. It defines the scope, three-tier priorities, week-by-week timeline, and the key technical differences between the iOS camera pipeline and Android's Camera2 API. It assumes you have already read the primer and developer guide.

---

## [6. Specs](#table-of-contents)

Feature specs document the incremental development history of the app. Each spec contains requirements, design decisions, and implementation tasks:

| # | Spec | Status |
|---|------|--------|
| 01 | iOS Light Meter Skeleton | ✅ Done |
| 02 | Lux & Kelvin Interpretation | ✅ Done |
| 03 | Capture Freeze | ✅ Done |
| 04 | Tab Navigation | ✅ Done |
| 05 | Deterministic Split Refactor | ✅ Done |
| 06 | UI Architecture Cleanup | ✅ Done |
| 07 | Code Review Polish | ✅ Done |

---

## [7. License](#table-of-contents)

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
