import Testing
@testable import LightMeter

struct TabTransitionActionTests {

    // MARK: - Helpers

    /// Returns true when both tabs are camera tabs and differ — the bug condition.
    private func isBugCondition(previousTab: Int, newTab: Int) -> Bool {
        let cameraTabs: Set<Int> = [0, 1]
        return cameraTabs.contains(previousTab)
            && cameraTabs.contains(newTab)
            && previousTab != newTab
    }

    // MARK: - Property 1: Bug Condition Exploration
    // Camera↔Camera Tab Transition Triggers Redundant Session Calls
    //
    // For all (previousTab, newTab) where isBugCondition holds,
    // the EXPECTED behavior is .none — the session should keep running.
    //
    // On UNFIXED code this test MUST FAIL because the buggy resolve()
    // returns .startSession for any camera tab, ignoring previousTab.

    @Test func property_bugCondition_cameraToCamera_shouldBeNone() {
        // Enumerate all bug-condition pairs: (0→1) and (1→0)
        let bugConditionPairs: [(Int, Int)] = [
            (0, 1),
            (1, 0),
        ]

        for (prev, new) in bugConditionPairs {
            #expect(isBugCondition(previousTab: prev, newTab: new),
                    "Pair (\(prev), \(new)) should satisfy isBugCondition")

            let result = TabTransitionAction.resolve(from: prev, to: new)
            #expect(result == .none,
                    "resolve(from: \(prev), to: \(new)) returned \(result) but expected .none — bug condition violated")
        }
    }

    // MARK: - Property-based exploration (randomized)
    // Generates 100 random bug-condition inputs to surface counterexamples.

    @Test func property_bugCondition_randomized() {
        var rng = SystemRandomNumberGenerator()
        let cameraTabs = [0, 1]

        for _ in 0..<100 {
            let prev = cameraTabs.randomElement(using: &rng)!
            var new = cameraTabs.randomElement(using: &rng)!
            // Ensure previousTab != newTab so isBugCondition holds
            while new == prev {
                new = cameraTabs.randomElement(using: &rng)!
            }

            #expect(isBugCondition(previousTab: prev, newTab: new))

            let result = TabTransitionAction.resolve(from: prev, to: new)
            #expect(result == .none,
                    "resolve(from: \(prev), to: \(new)) returned \(result) but expected .none")
        }
    }

    // MARK: - Property 2: Preservation
    // Non-Bug-Condition Transitions Unchanged
    //
    // These tests capture the CORRECT baseline behavior for all transitions
    // where the bug condition does NOT hold. They must pass on UNFIXED code
    // and continue to pass after the fix is applied (no regressions).

    // 2a: Camera → Non-camera → .stopSession
    @Test func property_preservation_cameraToNonCamera_shouldStopSession() {
        let cameraTabs = [0, 1]
        let nonCameraTabs = [2, 3]

        for prev in cameraTabs {
            for new in nonCameraTabs {
                #expect(!isBugCondition(previousTab: prev, newTab: new),
                        "Pair (\(prev), \(new)) should NOT satisfy isBugCondition")

                let result = TabTransitionAction.resolve(from: prev, to: new)
                #expect(result == .stopSession,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .stopSession")
            }
        }
    }

    // 2b: Non-camera → Camera → .startSession
    @Test func property_preservation_nonCameraToCamera_shouldStartSession() {
        let cameraTabs = [0, 1]
        let nonCameraTabs = [2, 3]

        for prev in nonCameraTabs {
            for new in cameraTabs {
                #expect(!isBugCondition(previousTab: prev, newTab: new),
                        "Pair (\(prev), \(new)) should NOT satisfy isBugCondition")

                let result = TabTransitionAction.resolve(from: prev, to: new)
                #expect(result == .startSession,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .startSession")
            }
        }
    }

    // 2c: Non-camera → Non-camera → .none
    @Test func property_preservation_nonCameraToNonCamera_shouldBeNone() {
        let nonCameraTabs = [2, 3]

        for prev in nonCameraTabs {
            for new in nonCameraTabs {
                #expect(!isBugCondition(previousTab: prev, newTab: new),
                        "Pair (\(prev), \(new)) should NOT satisfy isBugCondition")

                let result = TabTransitionAction.resolve(from: prev, to: new)
                #expect(result == .none,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .none")
            }
        }
    }

    // 2d: Same-tab transitions → .none
    @Test func property_preservation_sameTab_shouldBeNone() {
        let allTabs = [0, 1, 2, 3]

        for tab in allTabs {
            let result = TabTransitionAction.resolve(from: tab, to: tab)
            #expect(result == .none,
                    "resolve(from: \(tab), to: \(tab)) returned \(result) but expected .none — same-tab should be no-op")
        }
    }

    // 2e: Randomized preservation — generates random non-bug-condition pairs
    // and verifies the correct action for each category.
    @Test func property_preservation_randomized() {
        var rng = SystemRandomNumberGenerator()
        let allTabs = [0, 1, 2, 3]

        for _ in 0..<200 {
            let prev = allTabs.randomElement(using: &rng)!
            let new = allTabs.randomElement(using: &rng)!

            // Skip bug-condition pairs — those are covered by Property 1
            guard !isBugCondition(previousTab: prev, newTab: new) else { continue }

            let prevIsCamera = (prev == 0 || prev == 1)
            let newIsCamera = (new == 0 || new == 1)
            let result = TabTransitionAction.resolve(from: prev, to: new)

            if prev == new {
                #expect(result == .none,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .none for same-tab")
            } else if prevIsCamera && !newIsCamera {
                #expect(result == .stopSession,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .stopSession")
            } else if !prevIsCamera && newIsCamera {
                #expect(result == .startSession,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .startSession")
            } else {
                #expect(result == .none,
                        "resolve(from: \(prev), to: \(new)) returned \(result) but expected .none")
            }
        }
    }
}
