struct ColorTemperatureCalculator {
    static let minKelvin: Double = 1000.0
    static let maxKelvin: Double = 15000.0

    /// Clamps a raw Kelvin value to the valid display range [1000, 15000].
    static func calculateColorTemperature(rawKelvin: Double) -> Double {
        return clamp(rawKelvin)
    }

    /// Clamps a raw Kelvin value to the valid range [1000, 15000].
    static func clamp(_ kelvin: Double) -> Double {
        return min(max(kelvin, minKelvin), maxKelvin)
    }
}
