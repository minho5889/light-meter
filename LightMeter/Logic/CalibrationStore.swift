import Foundation

/// Pure logic store to manage and calculate the calibration multiplier for lux measurements.
public struct CalibrationStore: Sendable {
    private static let key = "light_meter_calibration_multiplier"
    
    /// Loads the stored multiplier from UserDefaults. Defaults to 1.0.
    public static func loadMultiplier(defaults: UserDefaults = .standard) -> Double {
        let value = defaults.double(forKey: key)
        return value > 0 ? value : 1.0
    }
    
    /// Saves the multiplier to UserDefaults, enforcing safety clamping.
    public static func saveMultiplier(_ multiplier: Double, defaults: UserDefaults = .standard) {
        let clamped = clampMultiplier(multiplier)
        defaults.set(clamped, forKey: key)
    }
    
    /// Calculates a new multiplier from a known reference/target lux value and the current measured lux.
    /// Clamps the resulting multiplier to a safe range [0.1, 10.0].
    public static func calculateMultiplier(measuredLux: Double, targetLux: Double) -> Double {
        guard measuredLux > 0.01 else { return 1.0 }
        let rawMultiplier = targetLux / measuredLux
        return clampMultiplier(rawMultiplier)
    }
    
    /// Clamps a multiplier to a safe range [0.1, 10.0] to prevent extreme division/multiplication or negative values.
    public static func clampMultiplier(_ multiplier: Double) -> Double {
        return max(0.1, min(multiplier, 10.0))
    }
}
