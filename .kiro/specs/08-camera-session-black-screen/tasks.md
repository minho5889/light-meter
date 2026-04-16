# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** — Camera↔Camera Tab Transition Triggers Redundant Session Calls
  - **CRITICAL**: This test MUST FAIL on unfixed code — failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior — it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: Scope the property to concrete camera↔camera transitions: (0→1) and (1→0)
  - Create `LightMeterTests/Logic/TabTransitionActionTests.swift`
  - Create the minimal `TabTransitionAction` pure function in `LightMeter/Logic/TabTransitionAction.swift` that mirrors the CURRENT (buggy) `onChange` logic — i.e., returns `.startSession` for any camera tab and `.stopSession` for any non-camera tab, without considering `previousTab`
  - Write a property-based test: for all `(previousTab, newTab)` where `isBugCondition` holds (both in `{0, 1}` and `previousTab != newTab`), assert `TabTransitionAction.resolve(from: previousTab, to: newTab) == .none`
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS — the unfixed function returns `.startSession` instead of `.none` for camera→camera transitions, confirming the bug exists
  - Document counterexamples found (e.g., `resolve(from: 0, to: 1)` returns `.startSession` instead of `.none`)
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 1.1, 1.4, 2.1, 2.4_

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** — Non-Bug-Condition Transitions Unchanged
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED `TabTransitionAction` for non-bug-condition inputs:
    - `resolve(from: 0, to: 2)` returns `.stopSession` (camera → non-camera)
    - `resolve(from: 2, to: 0)` returns `.startSession` (non-camera → camera)
    - `resolve(from: 2, to: 3)` returns `.none` (non-camera → non-camera)
    - `resolve(from: 0, to: 0)` returns `.none` (same-tab, no-op)
  - Write property-based tests in `LightMeterTests/Logic/TabTransitionActionTests.swift`:
    - For all `(prev, new)` where `prev ∈ {0,1}` and `new ∈ {2,3}`: assert result is `.stopSession`
    - For all `(prev, new)` where `prev ∈ {2,3}` and `new ∈ {0,1}`: assert result is `.startSession`
    - For all `(prev, new)` where `prev ∈ {2,3}` and `new ∈ {2,3}`: assert result is `.none`
    - For all `prev == new`: assert result is `.none`
  - Verify tests pass on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS — confirms baseline behavior to preserve
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2_

- [x] 3. Fix for camera session black screen on tab transitions

  - [x] 3.1 Implement the pure `TabTransitionAction` fix
    - Update `LightMeter/Logic/TabTransitionAction.swift` to implement the correct transition logic:
      - If both `previousTab` and `newTab` are camera tabs (`{0, 1}`) and differ → return `.none`
      - If `previousTab` is a camera tab and `newTab` is not → return `.stopSession`
      - If `previousTab` is not a camera tab and `newTab` is → return `.startSession`
      - Otherwise → return `.none`
    - Add `isCameraTab(_ tab: Int) -> Bool` helper that returns `true` for tabs 0 and 1
    - _Bug_Condition: isBugCondition(input) where previousTab ∈ {0,1} AND newTab ∈ {0,1} AND previousTab ≠ newTab_
    - _Expected_Behavior: resolve(from:to:) returns .none for all bug-condition inputs_
    - _Preservation: Non-bug-condition transitions return same actions as before_
    - _Requirements: 2.1, 2.4, 3.1, 3.2_

  - [x] 3.2 Update `ContentView.swift` onChange handler
    - Add `@State private var previousTab: Int = 0` to `ContentView`
    - Replace the current `onChange(of: selectedTab)` body with:
      - Call `TabTransitionAction.resolve(from: previousTab, to: newTab)`
      - Switch on the result: `.startSession` → `cameraViewModel.startSession()`, `.stopSession` → `cameraViewModel.stopSession()`, `.none` → no-op
      - Set `previousTab = newTab` at the end of the handler
    - _Bug_Condition: Camera↔camera transitions no longer trigger stop/start cycle_
    - _Expected_Behavior: Session remains running continuously during camera↔camera switches_
    - _Preservation: Non-camera transitions still stop/start as before_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2_

  - [x] 3.3 Add `isRunning` guard to `CameraSessionManager.startSession()`
    - In `LightMeter/Camera/CameraSessionManager.swift`, update the public `startSession()` method to check `captureSession.isRunning` before dispatching to the session queue
    - This is defense-in-depth — prevents redundant async dispatches from any call site (foreground handler, etc.)
    - _Requirements: 2.4_

  - [x] 3.4 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** — Camera↔Camera Tab Transition Triggers No Session Calls
    - **IMPORTANT**: Re-run the SAME test from task 1 — do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - _Requirements: 2.1, 2.4_

  - [x] 3.5 Verify preservation tests still pass
    - **Property 2: Preservation** — Non-Bug-Condition Transitions Unchanged
    - **IMPORTANT**: Re-run the SAME tests from task 2 — do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)

- [ ] 4. Checkpoint — Ensure all tests pass
  - Run the full `LightMeterTests` test suite
  - Verify all existing tests (LuxCalculator, LuxInterpreter, KelvinInterpreter, etc.) still pass
  - Verify all new TabTransitionAction tests pass
  - Ensure all tests pass, ask the user if questions arise
