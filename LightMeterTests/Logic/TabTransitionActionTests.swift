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
}
