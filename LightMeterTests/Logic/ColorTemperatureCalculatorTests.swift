import Testing
@testable import LightMeter

struct ColorTemperatureCalculatorTests {

    // MARK: - Clamping unit tests

    @Test func clamp_belowMin_returnsMin() {
        let result = ColorTemperatureCalculator.clamp(500.0)
        #expect(result == 1000.0)
    }

    @Test func clamp_aboveMax_returnsMax() {
        let result = ColorTemperatureCalculator.clamp(20000.0)
        #expect(result == 15000.0)
    }

    @Test func clamp_withinRange_returnsUnchanged() {
        let result = ColorTemperatureCalculator.clamp(5500.0)
        #expect(result == 5500.0)
    }

    @Test func clamp_atMin_returnsMin() {
        let result = ColorTemperatureCalculator.clamp(1000.0)
        #expect(result == 1000.0)
    }

    @Test func clamp_atMax_returnsMax() {
        let result = ColorTemperatureCalculator.clamp(15000.0)
        #expect(result == 15000.0)
    }

    // MARK: - calculateColorTemperature(rawKelvin:) unit tests

    @Test func calculateColorTemperature_belowMin_returnsMin() {
        let result = ColorTemperatureCalculator.calculateColorTemperature(rawKelvin: 500.0)
        #expect(result == 1000.0)
    }

    @Test func calculateColorTemperature_aboveMax_returnsMax() {
        let result = ColorTemperatureCalculator.calculateColorTemperature(rawKelvin: 20000.0)
        #expect(result == 15000.0)
    }

    @Test func calculateColorTemperature_withinRange_returnsUnchanged() {
        let result = ColorTemperatureCalculator.calculateColorTemperature(rawKelvin: 5500.0)
        #expect(result == 5500.0)
    }

    // MARK: - Property 3: Color temperature clamping invariant (100 iterations)
    // Feature: 05-deterministic-split-refactor, Property 3: Color temperature clamping invariant

    @Test func property_clampingInvariant() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<100 {
            let rawKelvin = Double.random(in: -1000...50000, using: &rng)
            let result = ColorTemperatureCalculator.calculateColorTemperature(rawKelvin: rawKelvin)
            #expect(result >= 1000.0)
            #expect(result <= 15000.0)
        }
    }

    // MARK: - Property 4: Color temperature identity for in-range values (100 iterations)
    // Feature: 05-deterministic-split-refactor, Property 4: Color temperature identity for in-range values

    @Test func property_identityForInRangeValues() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<100 {
            let rawKelvin = Double.random(in: 1000.0...15000.0, using: &rng)
            let result = ColorTemperatureCalculator.calculateColorTemperature(rawKelvin: rawKelvin)
            #expect(result == rawKelvin)
        }
    }
}
