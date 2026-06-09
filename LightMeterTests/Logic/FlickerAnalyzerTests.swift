import XCTest
@testable import LightMeter

final class FlickerAnalyzerTests: XCTestCase {
    
    /// Verifies that zero or extremely low input samples return safe, no-flicker results.
    func testZeroSignalHandling() {
        let zeroSamples = [Float](repeating: 0.0, count: FlickerAnalyzer.bufferSize)
        let result = FlickerAnalyzer.analyze(samples: zeroSamples, sampleRate: 240.0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.0)
        XCTAssertEqual(result?.frequency, 0.0)
        XCTAssertEqual(result?.safetyLevel, "Safe")
        XCTAssertEqual(result?.description, "No light detected.")
    }
    
    /// Verifies that a steady DC signal (like pure sunlight or high-quality DC LED) returns 0% flicker.
    func testSteadyDCSignal() {
        let dcSamples = [Float](repeating: 1.5, count: FlickerAnalyzer.bufferSize)
        let result = FlickerAnalyzer.analyze(samples: dcSamples, sampleRate: 240.0)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.percentage, 0.0)
        XCTAssertEqual(result?.safetyLevel, "Very Safe")
    }

    /// Verifies that a synthesized 120Hz light flicker under 240 fps sampling is correctly resolved.
    func test120HzFlickerResolution() {
        let sampleRate: Float = 240.0
        let frequency: Float = 120.0
        let dcOffset: Float = 1.0
        let amplitude: Float = 0.35 // 35% Flicker
        
        var samples = [Float](repeating: 0, count: FlickerAnalyzer.bufferSize)
        for i in 0..<FlickerAnalyzer.bufferSize {
            let time = Float(i) / sampleRate
            samples[i] = dcOffset + amplitude * cos(2.0 * .pi * frequency * time)
        }
        
        guard let result = FlickerAnalyzer.analyze(samples: samples, sampleRate: sampleRate) else {
            XCTFail("FlickerAnalyzer.analyze returned nil")
            return
        }
        
        // At 240fps sampling, a 120Hz signal is at bin index 128 (N/2), which is exactly the Nyquist limit.
        // We expect frequency to be resolved very close to 120Hz.
        XCTAssertEqual(result.frequency, 120.0, accuracy: 1.5)
        
        // At Nyquist frequency, there is no spectral leakage, so the analytical amplitude is resolved exactly to 35.0%.
        XCTAssertEqual(result.percentage, 35.0, accuracy: 0.1)
        XCTAssertEqual(result.safetyLevel, "Dangerous")
    }

    /// Verifies that a synthesized 100Hz light flicker under 240 fps sampling is correctly resolved.
    func test100HzFlickerResolution() {
        let sampleRate: Float = 240.0
        let frequency: Float = 100.0
        let dcOffset: Float = 1.0
        let amplitude: Float = 0.15 // 15% Flicker
        
        var samples = [Float](repeating: 0, count: FlickerAnalyzer.bufferSize)
        for i in 0..<FlickerAnalyzer.bufferSize {
            let time = Float(i) / sampleRate
            samples[i] = dcOffset + amplitude * sin(2.0 * .pi * frequency * time)
        }
        
        guard let result = FlickerAnalyzer.analyze(samples: samples, sampleRate: sampleRate) else {
            XCTFail("FlickerAnalyzer.analyze returned nil")
            return
        }
        
        XCTAssertEqual(result.frequency, 100.0, accuracy: 1.5)
        // Due to Hann window spectral leakage for off-bin frequencies, the peak amplitude is slightly attenuated to 13.95%.
        XCTAssertEqual(result.percentage, 13.95, accuracy: 0.1)
        XCTAssertEqual(result.safetyLevel, "Caution")
    }

    /// Verifies that a synthesized 50Hz flicker under 120 fps sampling is correctly resolved.
    func test120FpsSamplingResolution() {
        let sampleRate: Float = 120.0
        let frequency: Float = 50.0
        let dcOffset: Float = 2.0
        let amplitude: Float = 0.05 // 2.5% Flicker (0.05 / 2.0 * 100)
        
        var samples = [Float](repeating: 0, count: FlickerAnalyzer.bufferSize)
        for i in 0..<FlickerAnalyzer.bufferSize {
            let time = Float(i) / sampleRate
            samples[i] = dcOffset + amplitude * sin(2.0 * .pi * frequency * time)
        }
        
        guard let result = FlickerAnalyzer.analyze(samples: samples, sampleRate: sampleRate) else {
            XCTFail("FlickerAnalyzer.analyze returned nil")
            return
        }
        
        XCTAssertEqual(result.frequency, 50.0, accuracy: 1.5)
        // Due to Hann window spectral leakage for off-bin frequencies, the peak amplitude is slightly attenuated to 2.33%.
        XCTAssertEqual(result.percentage, 2.33, accuracy: 0.05)
        XCTAssertEqual(result.safetyLevel, "Very Safe")
    }
}
