import Foundation

/// A pure, Sendable exponential moving-average smoother for signal values.
public struct SignalSmoother: Sendable {
    private let alpha: Double
    private var lastValue: Double?

    public init(alpha: Double) {
        // Clamp alpha to [0, 1] to ensure stability
        self.alpha = min(max(alpha, 0.0), 1.0)
        self.lastValue = nil
    }

    public mutating func reset() {
        self.lastValue = nil
    }

    public mutating func update(_ value: Double) -> Double {
        guard let last = lastValue else {
            lastValue = value
            return value
        }
        let smoothed = alpha * value + (1.0 - alpha) * last
        lastValue = smoothed
        return smoothed
    }

    /// Rounds a double value to ~2 significant figures (an estimate, not a precise number).
    public static func roundToTwoSignificantFigures(_ value: Double) -> Double {
        guard value != 0 else { return 0.0 }
        let sign = value < 0 ? -1.0 : 1.0
        let absValue = abs(value)
        let orderOfMagnitude = ceil(log10(absValue))
        let power = 2.0 - orderOfMagnitude
        let factor = pow(10.0, power)
        return sign * (absValue * factor).rounded() / factor
    }
}
