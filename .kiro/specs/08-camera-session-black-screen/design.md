# Camera Session Black Screen Bugfix Design

<a id="table-of-contents"></a>

## Table of Contents

- [Overview](#overview)
- [Glossary](#glossary)
- [Bug Details](#bug-details)
- [Expected Behavior](#expected-behavior)
- [Hypothesized Root Cause](#hypothesized-root-cause)
- [Correctness Properties](#correctness-properties)
- [Fix Implementation](#fix-implementation)
- [Testing Strategy](#testing-strategy)

## [Overview](#table-of-contents)

The camera preview shows a black screen when switching between tabs because the `onChange(of: selectedTab)` handler in `ContentView.swift` unconditionally calls `startSession()` whenever a camera tab is selected — even when the session is already running from another camera tab. This causes an unnecessary `stopRunning()` / `startRunning()` cycle on the session queue, which blocks for ~7 seconds and can permanently disconnect the `AVCaptureVideoPreviewLayer` rendering pipeline.

The fix introduces previous-tab tracking in `ContentView` so the handler can distinguish camera↔camera transitions (skip stop/start) from non-camera↔camera transitions (stop or start as needed). A secondary `isRunning` guard in `CameraSessionManager.startSession()` prevents redundant `startRunning()` calls from any call site.

## [Glossary](#table-of-contents)

- **Bug_Condition (C)**: A tab transition where both the previous and new tabs are camera tabs (0 or 1), causing an unnecessary session stop/start cycle
- **Property (P)**: The session remains running continuously during camera↔camera transitions with no interruption to the preview layer
- **Preservation**: Existing stop-on-leave and start-on-enter behavior for non-camera↔camera transitions, plus background/foreground lifecycle, must remain unchanged
- **Camera tab**: Tab 0 (Lux) or tab 1 (Temperature) — both require `AVCaptureSession`
- **Non-camera tab**: Tab 2 (Flicker Detection) or tab 3 (Records) — neither requires `AVCaptureSession`
- **`onChange` handler**: The `.onChange(of: selectedTab)` modifier in `ContentView.swift` that manages session lifecycle on tab switches
- **`CameraSessionManager`**: Effects-layer class in `LightMeter/Camera/CameraSessionManager.swift` responsible for `AVCaptureSession` lifecycle
- **`CameraViewModel`**: Glue-layer view model in `LightMeter/Camera/CameraViewModel.swift` that coordinates between `CameraSessionManager` and views

## [Bug Details](#table-of-contents)

### Bug Condition

The bug manifests when the user switches between two camera tabs (tab 0 ↔ tab 1). The `onChange(of: selectedTab)` handler sees the new tab is a camera tab and calls `startSession()`, but it does not check whether the session is already running from the previous camera tab. Meanwhile, the handler also implicitly allows a stop/start cycle because it doesn't track the previous tab to know the transition is camera→camera.

Additionally, `CameraSessionManager.startSession()` dispatches `startSessionOnQueue()` unconditionally — while `startSessionOnQueue()` has an `isRunning` guard, the public `startSession()` method does not, meaning redundant async dispatches still occur.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type TabTransition { previousTab: Int, newTab: Int }
  OUTPUT: boolean

  LET cameraTabs = {0, 1}

  RETURN input.previousTab IN cameraTabs
         AND input.newTab IN cameraTabs
         AND input.previousTab != input.newTab
END FUNCTION
```

### Examples

- **Lux → Temperature (tab 0 → 1)**: Session is running. Handler calls `startSession()` again, which dispatches `startRunning()` on the session queue. The session may briefly stop and restart, causing a ~7s black screen with frozen lux/kelvin values.
- **Temperature → Lux (tab 1 → 0)**: Same as above — unnecessary session cycle, black screen.
- **Non-camera → Lux (tab 2 → 0)**: Session was stopped. Handler calls `startSession()`. After `startRunning()`, the `AVCaptureVideoPreviewLayer` can fail to reconnect, causing an indefinite black screen even though frames are processed.
- **Lux → Records → Lux (tab 0 → 3 → 0)**: Session stops on 0→3, starts on 3→0. The preview layer may not reconnect after the stop/start cycle.

## [Expected Behavior](#table-of-contents)

### Preservation Requirements

**Unchanged Behaviors:**
- Switching from a camera tab (0 or 1) to a non-camera tab (2 or 3) must continue to stop the `AVCaptureSession` to conserve battery and CPU
- Switching from a non-camera tab (2 or 3) to a camera tab (0 or 1) must continue to start the `AVCaptureSession` if it is not already running
- App entering background must continue to stop the session
- App returning to foreground must continue to start the session
- Photo capture on the Lux tab must continue to work without stopping the session
- Initial app launch must continue to show the preview after normal ~2s startup
- Camera toggle (front ↔ rear) must continue to work without stopping the session

**Scope:**
All tab transitions where the bug condition does NOT hold (i.e., at least one of the tabs is a non-camera tab) should behave exactly as they do today. The background/foreground lifecycle handlers are not modified.

## [Hypothesized Root Cause](#table-of-contents)

Based on the bug description and code analysis, the root causes are:

1. **Missing previous-tab tracking in `ContentView.onChange`**: The handler receives only the new tab value. It has no way to know whether the previous tab was also a camera tab, so it cannot skip the stop/start cycle for camera↔camera transitions. The current logic:
   ```swift
   .onChange(of: selectedTab) { _, newTab in
       if newTab == 0 || newTab == 1 {
           cameraViewModel.startSession()
       } else {
           cameraViewModel.stopSession()
       }
   }
   ```
   This calls `startSession()` even when transitioning from tab 0 → tab 1, where the session is already running.

2. **No `isRunning` guard on `CameraSessionManager.startSession()`**: The public method dispatches to the session queue unconditionally. While `startSessionOnQueue()` checks `isRunning`, the async dispatch itself is unnecessary overhead and can race with other session queue work.

3. **`AVCaptureVideoPreviewLayer` disconnection after stop/start**: When `stopRunning()` is called followed by `startRunning()`, the preview layer's internal rendering pipeline can fail to reconnect. This is a known AVFoundation behavior — the layer may show black even though the session is running and frames are being delivered to the `AVCaptureVideoDataOutput`. Avoiding the unnecessary stop/start eliminates this failure mode entirely for camera↔camera transitions.

## [Correctness Properties](#table-of-contents)

Property 1: Bug Condition — Session continuity during camera↔camera tab switches

_For any_ tab transition where both the previous tab and the new tab are camera tabs (isBugCondition returns true), the fixed `onChange` handler SHALL NOT call `stopSession()` or `startSession()`, keeping the `AVCaptureSession` running continuously with no interruption to the preview layer or frame processing.

**Validates: Requirements 2.1, 2.4**

Property 2: Preservation — Correct stop/start for non-camera↔camera transitions

_For any_ tab transition where at least one tab is a non-camera tab (isBugCondition returns false), the fixed `onChange` handler SHALL produce the same session lifecycle calls as the original handler: `stopSession()` when leaving a camera tab for a non-camera tab, and `startSession()` when entering a camera tab from a non-camera tab.

**Validates: Requirements 3.1, 3.2**

## [Fix Implementation](#table-of-contents)

### Changes Required

Assuming our root cause analysis is correct:

**File**: `LightMeter/ContentView.swift`

**Function**: `.onChange(of: selectedTab)` handler

**Specific Changes**:
1. **Add `previousTab` state**: Add a `@State private var previousTab: Int = 0` property to `ContentView` to track the last selected tab.
2. **Classify tabs with a helper**: Add a local `isCameraTab(_ tab: Int) -> Bool` function that returns `true` for tabs 0 and 1.
3. **Conditional stop/start logic**: Replace the current unconditional `startSession()` / `stopSession()` with:
   - If both `previousTab` and `newTab` are camera tabs → do nothing (session already running)
   - If `previousTab` is a camera tab and `newTab` is not → call `stopSession()`
   - If `previousTab` is not a camera tab and `newTab` is → call `startSession()`
   - If neither is a camera tab → do nothing
4. **Update `previousTab`**: Set `previousTab = newTab` at the end of the handler.

**File**: `LightMeter/Camera/CameraSessionManager.swift`

**Function**: `startSession()`

**Specific Changes**:
5. **Add `isRunning` guard**: Wrap the `startSession()` body so it checks `captureSession.isRunning` before dispatching to the session queue, preventing redundant async work. This is a defense-in-depth measure — the `onChange` fix is the primary guard.

## [Testing Strategy](#table-of-contents)

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that mock `CameraViewModel` (or spy on `CameraSessionManager`) and simulate tab transitions by invoking the `onChange` logic. Run these tests on the UNFIXED code to observe that `startSession()` is called unnecessarily during camera↔camera transitions.

**Test Cases**:
1. **Lux → Temperature (0 → 1)**: Verify `startSession()` is called on unfixed code (will demonstrate the bug)
2. **Temperature → Lux (1 → 0)**: Verify `startSession()` is called on unfixed code (will demonstrate the bug)
3. **Non-camera → Lux (2 → 0)**: Verify `startSession()` is called (correct behavior, baseline)
4. **Lux → Records (0 → 3)**: Verify `stopSession()` is called (correct behavior, baseline)

**Expected Counterexamples**:
- `startSession()` is invoked when transitioning from tab 0 → tab 1 and tab 1 → tab 0, even though the session is already running
- No distinction is made between camera→camera and non-camera→camera transitions

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := onChangeHandler_fixed(input.previousTab, input.newTab)
  ASSERT stopSession NOT called
  ASSERT startSession NOT called
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT onChangeHandler_original(input) = onChangeHandler_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many tab transition combinations automatically across the input domain {0, 1, 2, 3}
- It catches edge cases like same-tab transitions (e.g., tab 2 → tab 2)
- It provides strong guarantees that non-camera transitions behave identically

**Test Plan**: Extract the tab-transition decision logic into a pure function (`TabTransitionAction`) that takes `(previousTab, newTab)` and returns an action enum (`.none`, `.startSession`, `.stopSession`). This pure function is trivially testable without mocks. Observe behavior on UNFIXED code first, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Camera → Non-camera Preservation**: For all transitions from {0,1} to {2,3}, verify `stopSession()` is called — same as original
2. **Non-camera → Camera Preservation**: For all transitions from {2,3} to {0,1}, verify `startSession()` is called — same as original
3. **Non-camera → Non-camera Preservation**: For all transitions from {2,3} to {2,3}, verify neither `stopSession()` nor `startSession()` is called — same as original
4. **Same-tab Preservation**: For all transitions where `previousTab == newTab`, verify no session lifecycle calls

### Unit Tests

- Test the pure `TabTransitionAction` function for all 16 combinations of (previousTab, newTab) in {0, 1, 2, 3}
- Test `CameraSessionManager.startSession()` `isRunning` guard with a mock session
- Test that `previousTab` state is updated correctly after each transition

### Property-Based Tests

- Generate random `(previousTab, newTab)` pairs from {0, 1, 2, 3} and verify the pure transition function returns the correct action
- Generate random sequences of tab transitions and verify session lifecycle invariants hold across the sequence (e.g., no double-stop, no double-start)
- Generate random tab transitions and verify that for non-bug-condition inputs, the fixed logic matches the original logic exactly

### Integration Tests

- Test full tab switching flow in SwiftUI with a mock `CameraViewModel` to verify `startSession()` / `stopSession()` calls
- Test background/foreground lifecycle handlers are unaffected by the fix
- Test that `previousTab` state initializes correctly on app launch (tab 0 selected, session started via `onAppear`)
