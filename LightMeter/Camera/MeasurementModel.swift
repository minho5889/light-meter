import Foundation
import Observation

/// Model that isolates variables, signal smoothers, and calibration actions
/// related to lux, Kelvin, and tint.
@Observable
@MainActor
public final class MeasurementModel {
    public var lux: Double = 0.0
    public var colorTemperature: Double = 0.0
    public var tint: Double = 0.0
    public var calibrationMultiplier: Double = 1.0
    public var lastRawLux: Double = 0.0

    private var luxSmoother = SignalSmoother(alpha: 0.15)
    private var kelvinSmoother = SignalSmoother(alpha: 0.15)
    private var tintSmoother = SignalSmoother(alpha: 0.15)

    public init() {
        self.calibrationMultiplier = CalibrationStore.loadMultiplier()
    }

    public func update(luxValue: Double, kelvinValue: Double, tintValue: Double) {
        self.lastRawLux = luxValue
        let calibratedLux = luxValue * self.calibrationMultiplier
        let smoothedLux = self.luxSmoother.update(calibratedLux)
        self.lux = SignalSmoother.roundToTwoSignificantFigures(smoothedLux)
        self.colorTemperature = self.kelvinSmoother.update(kelvinValue)
        self.tint = self.tintSmoother.update(tintValue)
    }

    public func calibrate(to targetLux: Double) {
        let newMultiplier = CalibrationStore.calculateMultiplier(measuredLux: lastRawLux, targetLux: targetLux)
        self.calibrationMultiplier = newMultiplier
        CalibrationStore.saveMultiplier(newMultiplier)
        
        self.luxSmoother.reset()
        let calibratedLux = lastRawLux * newMultiplier
        let smoothedLux = self.luxSmoother.update(calibratedLux)
        self.lux = SignalSmoother.roundToTwoSignificantFigures(smoothedLux)
    }

    public func resetCalibration() {
        self.calibrationMultiplier = 1.0
        CalibrationStore.saveMultiplier(1.0)
        
        self.luxSmoother.reset()
        let calibratedLux = lastRawLux * 1.0
        let smoothedLux = self.luxSmoother.update(calibratedLux)
        self.lux = SignalSmoother.roundToTwoSignificantFigures(smoothedLux)
    }

    public func resetSmoothers() {
        luxSmoother.reset()
        kelvinSmoother.reset()
        tintSmoother.reset()
    }
}
