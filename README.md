# Sunny Light Meter

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An iOS app that turns your iPhone camera into a real-time light measurement tool — showing brightness (lux) and color temperature (Kelvin) with plain-language interpretations.

## Screenshots

<!-- Add screenshots here after capturing from device -->
| Live Measurement | Captured Reading | Temperature View |
|:---:|:---:|:---:|
| ![Live](screenshots/live.png) | ![Captured](screenshots/captured.png) | ![Temperature](screenshots/temperature.png) |

> To add screenshots: create a `screenshots/` folder and drop in PNG files from your device.

## Try It — TestFlight

You can install the beta on your iPhone without Xcode:

1. Install [TestFlight](https://apps.apple.com/app/testflight/id899247664) from the App Store
2. Tap this invite link: **`[coming soon]`**
3. Accept the invite and install Sunny Light Meter

> **For the developer (distributing via TestFlight):**
>
> 1. Open `LightMeter.xcodeproj` in Xcode
> 2. Select **Product → Archive** (requires a real device or "Any iOS Device" as target)
> 3. In the Organizer window, click **Distribute App → TestFlight Internal Testing**
> 4. Xcode uploads the build to App Store Connect
> 5. Go to [App Store Connect](https://appstoreconnect.apple.com) → your app → **TestFlight** tab
> 6. Add testers by email or create a **public link** anyone can use
> 7. Paste the public link above to replace `[coming soon]`
>
> **Requirements:** An Apple Developer account ($99/year). Free accounts can't use TestFlight.

## Quick Start

```bash
# Pure logic tests (no Xcode needed)
swift build
swift test

# Full app — open in Xcode, select your iPhone, and run
open LightMeter.xcodeproj
```

> Camera features require a physical device. The simulator won't produce real lux/Kelvin readings.

## Documentation

| Document | Description |
|----------|-------------|
| [Light-Meter-Spec-EN.md](Light-Meter-Spec-EN.md) | Full product specification — features, UX, target devices |
| [CODE-REVIEW.md](CODE-REVIEW.md) | Architecture review — P0/P1/P2 issues and fixes |
| [XCODE-TRANSITION-GUIDE.md](XCODE-TRANSITION-GUIDE.md) | How the SPM + Xcode two-world setup works |
| [GITHUB.md](GITHUB.md) | Git/GitHub workflow guide for this project |

## Kiro Specs

Feature specs live in `.kiro/specs/`, each with requirements, design, and tasks:

| # | Spec | Status |
|---|------|--------|
| 01 | [iOS Light Meter Skeleton](.kiro/specs/01-ios-light-meter-skeleton/) | ✅ Done |
| 02 | [Lux & Kelvin Interpretation](.kiro/specs/02-lux-kelvin-interpretation/) | ✅ Done |
| 03 | [Capture Freeze](.kiro/specs/03-capture-freeze/) | ✅ Done |
| 04 | [Tab Navigation](.kiro/specs/04-tab-navigation/) | ✅ Done |
| 05 | [Deterministic Split Refactor](.kiro/specs/05-deterministic-split-refactor/) | ✅ Done |
| 06 | [UI Architecture Cleanup](.kiro/specs/06-ui-architecture-cleanup/) | 🚧 In Progress |

## Project Structure

```
LightMeter/
├── LightMeterApp.swift          # App entry point
├── ContentView.swift            # Main tab container
├── CameraManager.swift          # Camera session + effects layer
├── CameraPreviewView.swift      # Live camera feed
├── LuxCalculator.swift          # Brightness calculation (pure)
├── LuxInterpreter.swift         # Lux → human description (pure)
├── ColorTemperatureCalculator.swift  # Kelvin calculation
├── KelvinInterpreter.swift      # Kelvin → human description (pure)
├── ComparisonGenerator.swift    # Contextual comparisons (pure)
├── MeasurementView.swift        # Lux measurement UI
├── MeasurementCardView.swift    # Measurement card component
├── TemperatureView.swift        # Kelvin display UI
├── TemperatureCardView.swift    # Temperature card component
└── PlaceholderView.swift        # Empty state

LightMeterTests/                 # Unit tests for pure logic layer
```

## Architecture

The app follows a **deterministic split** pattern:

- **Pure layer** — Calculators, interpreters, generators. No platform imports, fully testable via `swift test`.
- **Effects layer** — `CameraManager` handles AVFoundation, device I/O.
- **View layer** — SwiftUI views consume published values from the effects layer.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
