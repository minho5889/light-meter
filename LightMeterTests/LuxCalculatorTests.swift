import Testing
import CoreMedia
@testable import LightMeter

struct LuxCalculatorTests {

    // MARK: - Known input/output tests

    @Test func knownValues() {
        // ISO=100, exposure=1/125s, aperture=1.6, calibration=12.5
        // Expected: (12.5 * 1.6²) / (100 * 0.008) = 32.0 / 0.8 = 40.0
        let exposure = CMTimeMake(value: 1, timescale: 125)
        let result = LuxCalculator.calculateLux(iso: 100, exposureDuration: exposure)
        #expect(abs(result - 40.0) < 0.1)
    }

    // MARK: - Edge cases

    @Test func zeroISO_returnsZero() {
        let exposure = CMTimeMake(value: 1, timescale: 125)
        let result = LuxCalculator.calculateLux(iso: 0, exposureDuration: exposure)
        #expect(result == 0.0)
    }

    @Test func negativeISO_returnsZero() {
        let exposure = CMTimeMake(value: 1, timescale: 125)
        let result = LuxCalculator.calculateLux(iso: -100, exposureDuration: exposure)
        #expect(result == 0.0)
    }

    @Test func zeroExposure_returnsZero() {
        let exposure = CMTimeMake(value: 0, timescale: 1)
        let result = LuxCalculator.calculateLux(iso: 100, exposureDuration: exposure)
        #expect(result == 0.0)
    }

    @Test func veryLargeISO_returnsSmallPositive() {
        let exposure = CMTimeMake(value: 1, timescale: 100000)
        let result = LuxCalculator.calculateLux(iso: 10000, exposureDuration: exposure)
        #expect(result >= 0.0)
    }

    // MARK: - Property 1: Lux formula correctness (100 iterations)

    @Test func property_luxFormulaCorrectness() {
        var rng = SystemRandomNumberGenerator()
        let calibration = LuxCalculator.defaultCalibrationConstant
        let aperture = LuxCalculator.defaultAperture

        for _ in 0..<100 {
            let iso = Float.random(in: 0.01...10000, using: &rng)
            let exposureSeconds = Double.random(in: 0.00001...30.0, using: &rng)
            let exposure = CMTimeMakeWithSeconds(exposureSeconds, preferredTimescale: 1_000_000)

            let result = LuxCalculator.calculateLux(iso: iso, exposureDuration: exposure)
            let expected = (calibration * aperture * aperture) / (Double(iso) * exposureSeconds)

            #expect(abs(result - expected) < 1e-6 || abs(result - expected) / max(abs(expected), 1e-12) < 1e-6)
        }
    }

    // MARK: - Property 2: Lux non-negativity invariant (100 iterations)

    @Test func property_luxNonNegativity() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<100 {
            let iso = Float.random(in: -1000...10000, using: &rng)
            let exposureSeconds = Double.random(in: -10.0...30.0, using: &rng)
            let exposure = CMTimeMakeWithSeconds(exposureSeconds, preferredTimescale: 1_000_000)

            let result = LuxCalculator.calculateLux(iso: iso, exposureDuration: exposure)
            #expect(result >= 0.0)
        }
    }
}
