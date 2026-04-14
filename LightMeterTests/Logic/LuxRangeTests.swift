import Testing
@testable import LightMeter

struct LuxRangeTests {

    // MARK: - Helpers

    /// Independent oracle implementing the original if/else chain.
    private func oracleRangeIndex(for lux: Double) -> Int {
        if lux > 10000 { return 7 }
        if lux > 2000 { return 6 }
        if lux > 1000 { return 5 }
        if lux > 500 { return 4 }
        if lux > 200 { return 3 }
        if lux > 100 { return 2 }
        if lux > 10 { return 1 }
        return 0
    }

    // MARK: - Property 2: LuxRange equivalence
    // **Validates: Requirements 6.1, 6.4**
    // Tag: Feature: 07-code-review-polish, Property 2: LuxRange equivalence

    @Test func property_luxRangeEquivalence() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<200 {
            let lux = Double.random(in: 0...200_000, using: &rng)
            let actual = LuxRange.rangeIndex(for: lux)
            let expected = oracleRangeIndex(for: lux)
            #expect(actual == expected, "Mismatch for lux=\(lux): got \(actual), expected \(expected)")
        }
    }

    // MARK: - Unit Tests: Boundary values

    @Test func boundary_0() {
        #expect(LuxRange.rangeIndex(for: 0) == 0)
    }

    @Test func boundary_10() {
        #expect(LuxRange.rangeIndex(for: 10) == 0)
    }

    @Test func boundary_10_001() {
        #expect(LuxRange.rangeIndex(for: 10.001) == 1)
    }

    @Test func boundary_100() {
        #expect(LuxRange.rangeIndex(for: 100) == 1)
    }

    @Test func boundary_100_001() {
        #expect(LuxRange.rangeIndex(for: 100.001) == 2)
    }

    @Test func boundary_200() {
        #expect(LuxRange.rangeIndex(for: 200) == 2)
    }

    @Test func boundary_200_001() {
        #expect(LuxRange.rangeIndex(for: 200.001) == 3)
    }

    @Test func boundary_500() {
        #expect(LuxRange.rangeIndex(for: 500) == 3)
    }

    @Test func boundary_500_001() {
        #expect(LuxRange.rangeIndex(for: 500.001) == 4)
    }

    @Test func boundary_1000() {
        #expect(LuxRange.rangeIndex(for: 1000) == 4)
    }

    @Test func boundary_1000_001() {
        #expect(LuxRange.rangeIndex(for: 1000.001) == 5)
    }

    @Test func boundary_2000() {
        #expect(LuxRange.rangeIndex(for: 2000) == 5)
    }

    @Test func boundary_2000_001() {
        #expect(LuxRange.rangeIndex(for: 2000.001) == 6)
    }

    @Test func boundary_10000() {
        #expect(LuxRange.rangeIndex(for: 10000) == 6)
    }

    @Test func boundary_10000_001() {
        #expect(LuxRange.rangeIndex(for: 10000.001) == 7)
    }

    @Test func negativeLux_mapsToIndex0() {
        #expect(LuxRange.rangeIndex(for: -50) == 0)
        #expect(LuxRange.rangeIndex(for: -0.001) == 0)
        #expect(LuxRange.rangeIndex(for: -100000) == 0)
    }
}
