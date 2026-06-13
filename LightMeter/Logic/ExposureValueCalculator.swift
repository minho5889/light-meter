import Foundation

/// Supported measurement units in the application.
public enum MeasurementUnit: String, CaseIterable, Codable, Sendable {
    case lux
    case footCandle
    case ev
}

/// Helper structure representing a combined aperture and shutter speed setting.
public struct ExposureSetting: Equatable, Sendable {
    public let fStop: Double
    public let shutterSpeedString: String
}

/// Pure-logic calculator for Exposure Value (EV), foot-candles, and photographer aperture/shutter combinations.
public struct ExposureValueCalculator {
    
    /// Computes EV at ISO 100: log2(lux / 2.5)
    public static func calculateEV(lux: Double) -> Double {
        guard lux > 0.001 else { return -5.0 } // Safe lower clamp to avoid -infinity
        return log2(lux / 2.5)
    }

    /// Computes Foot-candles: lux / 10.764
    public static func calculateFootCandles(lux: Double) -> Double {
        guard lux > 0 else { return 0.0 }
        return lux / 10.764
    }

    /// Calculates standard equivalent shutter speeds for a given EV at ISO 100
    public static func equivalentExposureSettings(ev: Double) -> [ExposureSetting] {
        let fStops = [1.0, 1.4, 2.0, 2.8, 4.0, 5.6, 8.0, 11.0, 16.0, 22.0]
        let power = pow(2.0, ev)
        guard power > 0, !power.isInfinite, !power.isNaN else { return [] }

        return fStops.map { fStop in
            let t = (fStop * fStop) / power
            let speedStr = formatShutterSpeed(t)
            return ExposureSetting(fStop: fStop, shutterSpeedString: speedStr)
        }
    }

    /// Formats exposure duration t into standard photographer shutter speed string
    public static func formatShutterSpeed(_ t: Double) -> String {
        guard t > 0.0, !t.isNaN, !t.isInfinite else { return "1s" }
        if t >= 0.99 {
            let rounded = round(t)
            guard !rounded.isInfinite, !rounded.isNaN, rounded <= Double(Int.max) else { return "1s" }
            return "\(Int(rounded))s"
        } else {
            let denom = round(1.0 / t)
            guard !denom.isInfinite, !denom.isNaN, denom <= Double(Int.max) else { return "1s" }
            if denom >= 1.0 {
                return "1/\(Int(denom))s"
            } else {
                return "1s"
            }
        }
    }
}
