import AVFoundation

struct ColorTemperatureCalculator {
    static let minKelvin: Double = 1000.0
    static let maxKelvin: Double = 15000.0

    /// Converts white balance gains to color temperature in Kelvin.
    /// Uses AVCaptureDevice.temperatureAndTintValues(for:) internally.
    /// Clamps result to [1000, 15000] range.
    static func calculateColorTemperature(
        gains: AVCaptureDevice.WhiteBalanceGains,
        device: AVCaptureDevice
    ) -> Double {
        let temperatureAndTint = device.temperatureAndTintValues(for: gains)
        let kelvin = Double(temperatureAndTint.temperature)
        return clamp(kelvin)
    }

    /// Clamps a raw Kelvin value to the valid range [1000, 15000].
    static func clamp(_ kelvin: Double) -> Double {
        return min(max(kelvin, minKelvin), maxKelvin)
    }
}
