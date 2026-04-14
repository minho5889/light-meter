# When and How to Move to Xcode

## Where You Are Now

Right now, your project is a **Swift Package** — a folder with a `Package.swift` file that tells Swift how to compile your code. You build with `swift build` and test with `swift test` from the terminal. This works great for the pure logic layer (calculators, interpreters, generators) and their tests.

But here's the catch: **you can't actually run the app on your iPhone this way.** The `swift build` command compiles code, but it doesn't produce an installable iOS app. To get the app onto your phone, you need Xcode.

## What Xcode Actually Does

Think of Xcode as the bridge between your code and your iPhone. It handles things that `swift build` can't:

- **App bundling** — packages your code into an `.app` file that iOS understands
- **Code signing** — cryptographically signs the app so your iPhone trusts it
- **Device deployment** — installs the app onto your physical iPhone over USB
- **Simulator** — runs a virtual iPhone on your Mac (useful, but your app needs a real camera)
- **Asset management** — app icons, launch screens, and other resources
- **Entitlements** — permissions like camera access that iOS enforces

## The Two-World Setup

Your project will live in both worlds for a while:

| What | Tool | When |
|------|------|------|
| Write code | Kiro | Always |
| Run pure logic tests | `swift test` in terminal | Every spec |
| Build-check code compiles | `swift build` in terminal | Every spec |
| Run the app on your iPhone | Xcode | When you want to see it working |
| Test camera features | Xcode + iPhone | Camera doesn't work in simulator |

You don't need to choose one or the other. Keep writing code in Kiro, keep running tests from the terminal, and open Xcode only when you want to deploy to your phone.

## When to Make the Transition

You should set up Xcode when you hit any of these milestones:

### Milestone 1: "I want to see the app on my phone" (do this first)

This is the most natural trigger. After spec 04 (tab navigation), you'll have a full four-tab app with live camera, capture, and temperature views. That's a great point to see it running for real.

**What you'll need to do:**
1. Open Xcode (it's already on your Mac if you've been running `swift build`)
2. Create a new Xcode project (iOS App, SwiftUI)
3. Move your Swift files into the Xcode project
4. Set up a free Apple Developer account (see below)
5. Connect your iPhone 13 mini via USB
6. Hit the play button

### Milestone 2: "I need the simulator for UI iteration"

The iOS Simulator runs a virtual iPhone on your Mac. It's useful for checking layouts, tab navigation, and UI flows without plugging in your phone. It won't work for camera features (the simulator has no real camera), but it's great for everything else.

This becomes valuable around the Records spec, where you'll be building list views, swipe-to-delete, and detail screens — all testable without a camera.

### Milestone 3: "I need app icons, launch screen, or App Store submission"

This is the full Xcode project setup — asset catalogs, app icons, launch screen storyboards, App Store metadata. You won't need this until much later, if ever.

## Apple Developer Account

You need an Apple account to run apps on your iPhone. There are two tiers:

**Free Apple Developer Account (start here)**
- Sign up at [developer.apple.com](https://developer.apple.com) with your Apple ID
- Lets you run apps on your own devices
- Apps expire after 7 days (you just re-deploy from Xcode)
- Limited to 3 apps on your phone at a time
- No App Store publishing
- Cost: $0

**Paid Apple Developer Program**
- $99/year
- Apps don't expire on your device
- Can publish to the App Store
- You don't need this unless you want to ship to the App Store

For development and testing, the free account is all you need.

## Step-by-Step: First Xcode Setup

When you're ready (after spec 04 is a good time), here's what to do:

### 1. Get a free developer account
- Go to [developer.apple.com](https://developer.apple.com)
- Sign in with your Apple ID (or create one)
- Accept the developer agreement

### 2. Open Xcode
- Open Xcode from your Applications folder
- If it asks to install additional components, say yes

### 3. Create the Xcode project
- File → New → Project
- Choose "App" under iOS
- Product Name: `LightMeter`
- Team: select your Apple ID
- Organization Identifier: something like `com.yourname` (this is just a namespace)
- Interface: SwiftUI
- Language: Swift
- Uncheck "Include Tests" (we already have our own)

### 4. Replace the generated files with your code
- Delete the auto-generated `ContentView.swift` and `LightMeterApp.swift` from the Xcode project
- Drag all your Swift files from the `LightMeter/` folder into the Xcode project navigator
- Make sure "Copy items if needed" is checked
- Add `Info.plist` to the project

### 5. Connect your iPhone
- Plug in your iPhone 13 mini via USB/Lightning cable
- Trust the computer on your phone when prompted
- In Xcode's top toolbar, select your iPhone as the run destination (instead of a simulator)

### 6. Run
- Click the play button (or press Cmd+R)
- First time: Xcode will ask to sign the app — select your Apple ID team
- First time on phone: go to Settings → General → VPN & Device Management → trust your developer certificate
- The app should launch on your phone

### 7. After the first setup
- You can keep editing code in Kiro
- When you want to test on your phone, open Xcode and hit play — it picks up file changes automatically
- Tests can still run from the terminal with `swift test`

## What Changes in the Project Structure

When you create the Xcode project, you'll get a `.xcodeproj` file (or `.xcworkspace`). This is when XcodeBuildMCP becomes useful — it can build and test through Xcode's build system instead of `swift build`.

Your `Package.swift` will still exist for the pure logic targets and tests. The Xcode project will reference the same source files but add the app-specific configuration (code signing, entitlements, asset catalog) that a Swift Package can't express.

## Summary

| Question | Answer |
|----------|--------|
| Can I keep using `swift test` forever? | Yes, for pure logic tests |
| Do I need Xcode right now? | No — your tests and builds work fine |
| When should I set up Xcode? | When you want to see the app on your iPhone |
| Do I need to pay Apple? | No — free account works for development |
| Will my code change? | No — same Swift files, just opened in Xcode too |
| Best time to do this? | After spec 04 (tab navigation) is complete |
