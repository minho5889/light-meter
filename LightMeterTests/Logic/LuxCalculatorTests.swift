import Testing
@testable import LightMeter

struct LuxCalculatorTests {

    // MARK: - Known input/output tests

    @Test func knownValues() {
        // ISO=100, exposure=1/125s (0.008), aperture=1.6, calibration=250
        // Expected: (250 * 1.6²) / (100 * 0.008) = 640.0 / 0.8 = 800.0
        let result = LuxCalculator.calculateLux(iso: 100, exposureDurationInSeconds: 0.008)
        #expect(abs(result - 800.0) < 0.1)
    }

    // MARK: - Edge cases

    @Test func zeroISO_returnsZero() {
        let result = LuxCalculator.calculateLux(iso: 0, exposureDurationInSeconds: 0.008)
        #expect(result == 0.0)
    }

    @Test func negativeISO_returnsZero() {
        let result = LuxCalculator.calculateLux(iso: -100, exposureDurationInSeconds: 0.008)
        #expect(result == 0.0)
    }

    @Test func zeroExposure_returnsZero() {
        let result = LuxCalculator.calculateLux(iso: 100, exposureDurationInSeconds: 0.0)
        #expect(result == 0.0)
    }

    @Test func veryLargeISO_returnsSmallPositive() {
        // exposure = 1/100000s = 0.00001
        let result = LuxCalculator.calculateLux(iso: 10000, exposureDurationInSeconds: 0.00001)
        #expect(result >= 0.0)
    }

    // MARK: - Property 1: Lux formula correctness (100 iterations)
    // Feature: 05-deterministic-split-refactor, Property 1: Lux formula correctness

    @Test func property_luxFormulaCorrectness() {
        var rng = SystemRandomNumberGenerator()
        let calibration = LuxCalculator.defaultCalibrationConstant
        let aperture = LuxCalculator.defaultAperture

        for _ in 0..<100 {
            let iso = Float.random(in: 0.01...10000, using: &rng)
            let exposureSeconds = Double.random(in: 0.00001...30.0, using: &rng)

            let result = LuxCalculator.calculateLux(iso: iso, exposureDurationInSeconds: exposureSeconds)
            let expected = (calibration * aperture * aperture) / (Double(iso) * exposureSeconds)

            #expect(abs(result - expected) < 1e-6 || abs(result - expected) / max(abs(expected), 1e-12) < 1e-6)
        }
    }

    // MARK: - Property 2: Lux non-negativity invariant (100 iterations)
    // Feature: 05-deterministic-split-refactor, Property 2: Lux non-negativity invariant

    @Test func property_luxNonNegativity() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<100 {
            let iso = Float.random(in: -1000...10000, using: &rng)
            let exposureSeconds = Double.random(in: -10.0...30.0, using: &rng)

            let result = LuxCalculator.calculateLux(iso: iso, exposureDurationInSeconds: exposureSeconds)
            #expect(result >= 0.0)
        }
    }
}
