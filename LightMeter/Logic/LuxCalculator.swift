struct LuxCalculator {
    static let defaultCalibrationConstant: Double = 250
    static let defaultAperture: Double = 1.6  // Fallback; prefer device.lensAperture at runtime

    /// Computes lux (illuminance) from ISO and exposure duration.
    /// Formula: lux = (C * aperture²) / (ISO * exposureDurationInSeconds)
    ///
    /// Uses the ISO 2720 incident-light equation (C = 250 for a flat receptor)
    /// rather than the reflected-light equation (K = 12.5), because we want
    /// illuminance in lux, not luminance in cd/m².
    /// Returns 0.0 if inputs would cause division by zero or negative results.
    static func calculateLux(
        iso: Float,
        exposureDurationInSeconds: Double,
        calibrationConstant: Double = defaultCalibrationConstant,
        aperture: Double = defaultAperture
    ) -> Double {
        guard iso > 0, exposureDurationInSeconds > 0 else {
            return 0.0
        }

        let lux = (calibrationConstant * aperture * aperture) / (Double(iso) * exposureDurationInSeconds)
        return max(lux, 0.0)
    }
}
