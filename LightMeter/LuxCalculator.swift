import CoreMedia

struct LuxCalculator {
    static let defaultCalibrationConstant: Double = 12.5
    static let defaultAperture: Double = 1.6  // iPhone 13 mini wide camera f-number

    /// Computes lux from ISO and exposure duration.
    /// Formula: lux = (calibrationConstant * aperture²) / (ISO * exposureDurationInSeconds)
    /// Returns 0.0 if inputs would cause division by zero or negative results.
    static func calculateLux(
        iso: Float,
        exposureDuration: CMTime,
        calibrationConstant: Double = defaultCalibrationConstant,
        aperture: Double = defaultAperture
    ) -> Double {
        let exposureSeconds = CMTimeGetSeconds(exposureDuration)

        guard iso > 0, exposureSeconds > 0 else {
            return 0.0
        }

        let lux = (calibrationConstant * aperture * aperture) / (Double(iso) * exposureSeconds)
        return max(lux, 0.0)
    }
}
