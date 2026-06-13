import Testing
import Foundation
@testable import LightMeter

struct ExposureValueCalculatorTests {

    @Test func testEVCalculation() {
        // EV = log2(lux / 2.5)
        #expect(ExposureValueCalculator.calculateEV(lux: 2.5) == 0.0)
        #expect(ExposureValueCalculator.calculateEV(lux: 5.0) == 1.0)
        #expect(ExposureValueCalculator.calculateEV(lux: 10.0) == 2.0)
        #expect(ExposureValueCalculator.calculateEV(lux: 80.0) == 5.0)
        
        // Zero or negative lux boundary handling
        #expect(ExposureValueCalculator.calculateEV(lux: 0.0) == -5.0)
        #expect(ExposureValueCalculator.calculateEV(lux: -100.0) == -5.0)
        #expect(ExposureValueCalculator.calculateEV(lux: 0.0005) == -5.0)
    }

    @Test func testFootCandleCalculation() {
        // fc = lux / 10.764
        #expect(abs(ExposureValueCalculator.calculateFootCandles(lux: 10.764) - 1.0) < 0.0001)
        #expect(abs(ExposureValueCalculator.calculateFootCandles(lux: 107.64) - 10.0) < 0.0001)
        
        // Zero and negative lux boundaries
        #expect(ExposureValueCalculator.calculateFootCandles(lux: 0.0) == 0.0)
        #expect(ExposureValueCalculator.calculateFootCandles(lux: -50.0) == 0.0)
    }

    @Test func testShutterSpeedFormatting() {
        #expect(ExposureValueCalculator.formatShutterSpeed(1.5) == "2s")
        #expect(ExposureValueCalculator.formatShutterSpeed(1.0) == "1s")
        #expect(ExposureValueCalculator.formatShutterSpeed(0.5) == "1/2s")
        #expect(ExposureValueCalculator.formatShutterSpeed(1.0 / 125.0) == "1/125s")
        #expect(ExposureValueCalculator.formatShutterSpeed(1.0 / 8000.0) == "1/8000s")
        #expect(ExposureValueCalculator.formatShutterSpeed(0.0) == "1s") // boundary fallback
    }

    @Test func testEquivalentExposureSettings() {
        let ev = 0.0
        let settings = ExposureValueCalculator.equivalentExposureSettings(ev: ev)
        
        // At EV 0 (ISO 100):
        // f/1.0 -> t = 1^2 / 1 = 1s
        // f/2.0 -> t = 2^2 / 1 = 4s
        // f/4.0 -> t = 4^2 / 1 = 16s
        #expect(settings.count == 10)
        
        let settingF1 = settings.first { $0.fStop == 1.0 }
        #expect(settingF1?.shutterSpeedString == "1s")
        
        let settingF2 = settings.first { $0.fStop == 2.0 }
        #expect(settingF2?.shutterSpeedString == "4s")
        
        let settingF4 = settings.first { $0.fStop == 4.0 }
        #expect(settingF4?.shutterSpeedString == "16s")

        // At EV 15 (ISO 100):
        // f/16.0 -> t = 16^2 / 2^15 = 256 / 32768 = 1/128s
        let ev15 = 15.0
        let settings15 = ExposureValueCalculator.equivalentExposureSettings(ev: ev15)
        let settingF16 = settings15.first { $0.fStop == 16.0 }
        #expect(settingF16?.shutterSpeedString == "1/128s")
    }
}
