import Accelerate
import Foundation

/// Data structure representing the calculated safety and metrics of light flicker.
struct FlickerResult: Sendable, Equatable {
    let percentage: Double
    let frequency: Double
    let safetyLevel: String
    let description: String
}

/// Pure-logic, thread-safe signal processor designed to analyze real-time luminance samples.
/// Utilizes Apple's high-performance Accelerate Framework (vDSP) to perform Fast Fourier Transforms (FFT).
final class FlickerAnalyzer: Sendable {
    static let bufferSize = 256
    private static let log2n = 8 // log2(256)

    /// Analyzes a window of luminance samples and returns the calculated flicker percentage, frequency, and safety rating.
    /// - Parameters:
    ///   - samples: 256 floating-point luminance measurements.
    ///   - sampleRate: The capture frame rate (e.g., 240.0, 120.0, or 60.0).
    /// - Returns: A descriptive FlickerResult, or nil if samples are invalid.
    static func analyze(samples: [Float], sampleRate: Float) -> FlickerResult? {
        guard samples.count == bufferSize else { return nil }

        // 1. Compute average brightness (DC component)
        let dcComponent = vDSP.mean(samples)
        guard dcComponent > 0.01 else {
            return FlickerResult(
                percentage: 0.0,
                frequency: 0.0,
                safetyLevel: "Safe",
                description: "No light detected."
            )
        }

        // 2. Apply Hann Windowing to reduce spectral leakage
        var window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))

        var windowedSamples = [Float](repeating: 0, count: bufferSize)
        vDSP.multiply(samples, window, result: &windowedSamples)

        // 3. Prepare FFT split complex structures and run forward FFT
        guard let fft = vDSP.FFT(log2n: vDSP_Length(log2n), radix: .radix2, ofType: DSPSplitComplex.self) else {
            return nil
        }

        var real = [Float](repeating: 0, count: bufferSize / 2)
        var imag = [Float](repeating: 0, count: bufferSize / 2)

        real.withUnsafeMutableBufferPointer { rPtr in
            imag.withUnsafeMutableBufferPointer { iPtr in
                var splitComplex = DSPSplitComplex(realp: rPtr.baseAddress!, imagp: iPtr.baseAddress!)

                // Re-bind the windowed samples as a complex structure to feed into ctoz
                windowedSamples.withUnsafeBufferPointer { samplesPtr in
                    samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
                    }
                }

                // Execute Forward FFT
                fft.forward(input: splitComplex, output: &splitComplex)
            }
        }

        // 4. Compute magnitudinal spectrum
        var magnitudes = [Float](repeating: 0, count: bufferSize / 2)
        real.withUnsafeBufferPointer { rPtr in
            imag.withUnsafeBufferPointer { iPtr in
                var splitComplex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: rPtr.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: iPtr.baseAddress!)
                )
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSize / 2))
            }
        }

        // Compute square root to get true amplitude magnitudes
        var magnitudesSqrt = [Float](repeating: 0, count: bufferSize / 2)
        vForce.sqrt(magnitudes, result: &magnitudesSqrt)

        // 5. Find the dominant peak in the frequency spectrum (skipping low-frequency DC offset bins 0-2)
        var maxMagnitude: Float = 0.0
        var maxIndex: vDSP_Length = 0
        let minBin = 3
        let maxBin = bufferSize / 2

        for i in minBin..<maxBin {
            let mag = magnitudesSqrt[i]
            if mag > maxMagnitude {
                maxMagnitude = mag
                maxIndex = vDSP_Length(i)
            }
        }

        // Calculate frequency: binIndex * (sampleRate / N)
        let frequency = Double(maxIndex) * Double(sampleRate) / Double(bufferSize)

        // Calculate amplitude of the peak.
        // The Hann window scales down amplitude by 0.5, so we compensate by multiplying by 2.
        // The real-to-complex FFT scaling factor is 2/N, so combined factor is 4/N.
        let peakAmplitude = (Double(maxMagnitude) * 4.0) / Double(bufferSize)

        // Compute Flicker Percentage (AC Amplitude / DC Component) * 100
        var flickerPercentage = (peakAmplitude / Double(dcComponent)) * 100.0

        // If the peak magnitude is negligible compared to the total DC brightness, there is no flicker.
        if maxMagnitude < 0.02 * dcComponent {
            flickerPercentage = 0.0
        }

        let clampedPercentage = max(0.0, min(100.0, flickerPercentage))
        return mapSafety(percentage: clampedPercentage, frequency: frequency)
    }

    private static func mapSafety(percentage: Double, frequency: Double) -> FlickerResult {
        if percentage <= 3.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Very Safe",
                description: "Minimal eye fatigue. Sunlight level or high-quality lighting."
            )
        } else if percentage <= 10.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Safe",
                description: "Safe for standard use. Sensitive individuals may feel mild dryness."
            )
        } else if percentage <= 30.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Caution",
                description: "Moderate flicker. May cause mild eye strain or headaches over time."
            )
        } else if percentage <= 60.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Dangerous",
                description: "Severe flicker. High risk of headaches, visual fatigue, and dizziness."
            )
        } else {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Very Dangerous",
                description: "Critical flicker. Visible pulsation. Highly strenuous for eyes."
            )
        }
    }
}
