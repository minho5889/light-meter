import Accelerate
import Foundation

/// Data structure representing the calculated safety and metrics of light flicker.
public struct FlickerResult: Sendable, Equatable {
    public let percentage: Double
    public let frequency: Double
    public let safetyLevel: String
    public let description: String
    public let nyquist: Double

    public init(percentage: Double, frequency: Double, safetyLevel: String, description: String, nyquist: Double) {
        self.percentage = percentage
        self.frequency = frequency
        self.safetyLevel = safetyLevel
        self.description = description
        self.nyquist = nyquist
    }
}

/// Pure-logic, thread-safe signal processor designed to analyze real-time luminance samples.
/// Utilizes Apple's high-performance Accelerate Framework (vDSP) to perform Fast Fourier Transforms (FFT).
public final class FlickerAnalyzer: Sendable {
    public static let bufferSize = 256
    private static let log2n = 8 // log2(256)

    /// Analyzes a window of luminance samples and returns the calculated flicker percentage, frequency, and safety rating.
    /// - Parameters:
    ///   - samples: 256 floating-point luminance measurements.
    ///   - sampleRate: The capture frame rate (e.g., 240.0, 120.0, or 60.0).
    /// - Returns: A descriptive FlickerResult, or nil if samples are invalid.
    public static func analyze(samples: [Float], sampleRate: Float) -> FlickerResult? {
        guard samples.count == bufferSize else { return nil }

        // 1. Compute average brightness (DC component)
        let dcComponent = vDSP.mean(samples)
        guard dcComponent > 0.01 else {
            return FlickerResult(
                percentage: 0.0,
                frequency: 0.0,
                safetyLevel: "Safe",
                description: "No light detected.",
                nyquist: Double(sampleRate) / 2.0
            )
        }

        // 2. Apply Hann Windowing to reduce spectral leakage
        var window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))

        var windowedSamples = [Float](repeating: 0, count: bufferSize)
        vDSP.multiply(samples, window, result: &windowedSamples)

        // 3. Create real FFT setup
        guard let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2n), FFTRadix(kFFTRadix2)) else {
            return nil
        }
        defer {
            vDSP_destroy_fftsetup(fftSetup)
        }

        var real = [Float](repeating: 0, count: bufferSize / 2)
        var imag = [Float](repeating: 0, count: bufferSize / 2)

        // Bind and pack into split complex structure
        real.withUnsafeMutableBufferPointer { rPtr in
            imag.withUnsafeMutableBufferPointer { iPtr in
                var splitComplex = DSPSplitComplex(realp: rPtr.baseAddress!, imagp: iPtr.baseAddress!)
                windowedSamples.withUnsafeBufferPointer { samplesPtr in
                    samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: bufferSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(bufferSize / 2))
                    }
                }
                // Execute Forward Real FFT
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, vDSP_Length(log2n), FFTDirection(kFFTDirection_Forward))
            }
        }

        // 4. Compute magnitudes
        // For real FFT:
        // - DC component at real[0]
        // - Nyquist component at imag[0]
        // - Bins 1 to N/2 - 1 have real part in real[i], imaginary part in imag[i]
        var magnitudes = [Float](repeating: 0, count: bufferSize / 2 + 1)
        magnitudes[0] = real[0] * real[0]
        magnitudes[bufferSize / 2] = imag[0] * imag[0]
        for i in 1..<(bufferSize / 2) {
            magnitudes[i] = real[i] * real[i] + imag[i] * imag[i]
        }

        var magnitudesSqrt = [Float](repeating: 0, count: bufferSize / 2 + 1)
        vForce.sqrt(magnitudes, result: &magnitudesSqrt)

        // 5. Find the dominant peak in the frequency spectrum (skipping low-frequency DC offset bins 0-2)
        var maxMagnitude: Float = 0.0
        var maxIndex = 0
        let minBin = 3
        let maxBin = bufferSize / 2 // Include the Nyquist limit

        for i in minBin...maxBin {
            let mag = magnitudesSqrt[i]
            if mag > maxMagnitude {
                maxMagnitude = mag
                maxIndex = i
            }
        }

        // Calculate frequency: binIndex * (sampleRate / N)
        let frequency = Double(maxIndex) * Double(sampleRate) / Double(bufferSize)

        // Calculate amplitude of the peak.
        // Scale peak amplitude depending on whether it is Nyquist or a standard bin.
        // Analytical derivation of peak amplitude from real-FFT magnitude:
        // 1. Accelerate's forward real FFT (vDSP_fft_zrip) scales output by 2.0 internally.
        // 2. The normalized Hann window (vDSP_HANN_NORM) scales the signal gain by sqrt(2/3) ≈ 0.816496.
        //    To recover original amplitude, we divide by this coherent gain, multiplying by 1 / sqrt(2/3) = sqrt(1.5) ≈ 1.22474.
        // 3. Positive bin doubling applies a factor of 2.0 for standard bins (since positive and negative energy is combined),
        //    whereas Nyquist has no separate negative counterpart, so its factor is 1.0.
        // 4. Finally, normal DFT scaling divides by N.
        // Combining these factors:
        // - Standard bins: amplitude = (magnitude / 2.0) * 2.0 (doubling) * sqrt(1.5) (Hann) / N = magnitude * sqrt(1.5) / N
        // - Nyquist bin: amplitude = (magnitude / 2.0) * 1.0 (no doubling) * sqrt(1.5) (Hann) / N = magnitude * sqrt(1.5) / (2.0 * N)
        // We write this compactly using scalingFactor (2.0 for standard, 1.0 for Nyquist) multiplied by sqrt(1.5) / (2.0 * N).
        let scalingFactor = (maxIndex == bufferSize / 2) ? 1.0 : 2.0
        let peakAmplitude = (Double(maxMagnitude) * scalingFactor * sqrt(1.5)) / (2.0 * Double(bufferSize))

        // Compute Flicker Percentage (AC Amplitude / DC Component) * 100
        var flickerPercentage = (peakAmplitude / Double(dcComponent)) * 100.0

        // If the peak magnitude is negligible compared to the total DC brightness, there is no flicker.
        if maxMagnitude < 0.02 * dcComponent {
            flickerPercentage = 0.0
        }

        let clampedPercentage = max(0.0, min(100.0, flickerPercentage))
        let nyquist = Double(sampleRate) / 2.0
        return mapSafety(percentage: clampedPercentage, frequency: frequency, nyquist: nyquist)
    }

    private static func mapSafety(percentage: Double, frequency: Double, nyquist: Double) -> FlickerResult {
        let hz = Int(nyquist)
        if percentage <= 3.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Very Safe",
                description: "No flicker detected up to \(hz) Hz. Note: high-frequency PWM/LED flicker above \(hz) Hz cannot be measured by frame-rate sampling. Informational only, not medical advice.",
                nyquist: nyquist
            )
        } else if percentage <= 10.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Safe",
                description: "Minimal relative flicker detected. Normal for high-quality lighting. High-frequency flicker above \(hz) Hz is unmeasurable. Informational only, not medical advice.",
                nyquist: nyquist
            )
        } else if percentage <= 30.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Caution",
                description: "Moderate relative flicker intensity. Common in some LED lights or dimmed bulbs. Informational only, not medical advice.",
                nyquist: nyquist
            )
        } else if percentage <= 60.0 {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Dangerous",
                description: "High relative flicker intensity. Common in low-quality LED/fluorescent lights. Informational only, not medical advice.",
                nyquist: nyquist
            )
        } else {
            return FlickerResult(
                percentage: percentage,
                frequency: frequency,
                safetyLevel: "Very Dangerous",
                description: "Extreme relative flicker intensity. Visible pulsation or unstable power source detected. Informational only, not medical advice.",
                nyquist: nyquist
            )
        }
    }
}
