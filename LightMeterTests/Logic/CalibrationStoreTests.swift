import Testing
import Foundation
@testable import LightMeter

struct CalibrationStoreTests {
    
    @Test func identityByDefault() {
        // Test standard defaults (without stored key) returns 1.0
        let defaults = UserDefaults(suiteName: "CalibrationStoreTestsSuite_identity")!
        defaults.removePersistentDomain(forName: "CalibrationStoreTestsSuite_identity")
        
        let multiplier = CalibrationStore.loadMultiplier(defaults: defaults)
        #expect(multiplier == 1.0)
    }
    
    @Test func correctMultiplierCalculation() {
        // Test basic multiplier calculations
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 100.0, targetLux: 200.0) == 2.0)
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 200.0, targetLux: 100.0) == 0.5)
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 50.0, targetLux: 50.0) == 1.0)
        
        // Zero or near-zero measured lux defaults to 1.0 multiplier
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 0.0, targetLux: 100.0) == 1.0)
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 0.005, targetLux: 100.0) == 1.0)

        // A zero/negative reference target is invalid and must NOT darken readings
        // to the 0.1x floor — it should fall back to identity (no calibration).
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 100.0, targetLux: 0.0) == 1.0)
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 100.0, targetLux: -50.0) == 1.0)
    }
    
    @Test func persistenceRoundTrip() {
        let defaults = UserDefaults(suiteName: "CalibrationStoreTestsSuite_persistence")!
        defaults.removePersistentDomain(forName: "CalibrationStoreTestsSuite_persistence")
        
        // Save multiplier 2.5
        CalibrationStore.saveMultiplier(2.5, defaults: defaults)
        
        // Load and check
        let loaded = CalibrationStore.loadMultiplier(defaults: defaults)
        #expect(loaded == 2.5)
        
        // Clean up
        defaults.removePersistentDomain(forName: "CalibrationStoreTestsSuite_persistence")
    }
    
    @Test func saneClamping() {
        // Test that any value outside [0.1, 10.0] gets clamped
        #expect(CalibrationStore.clampMultiplier(0.05) == 0.1)
        #expect(CalibrationStore.clampMultiplier(-1.5) == 0.1)
        #expect(CalibrationStore.clampMultiplier(15.0) == 10.0)
        #expect(CalibrationStore.clampMultiplier(5.0) == 5.0)
        
        // Test that calculateMultiplier also clamps
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 10.0, targetLux: 200.0) == 10.0)
        #expect(CalibrationStore.calculateMultiplier(measuredLux: 1000.0, targetLux: 10.0) == 0.1)
        
        // Test saveMultiplier clamping
        let defaults = UserDefaults(suiteName: "CalibrationStoreTestsSuite_clamping")!
        defaults.removePersistentDomain(forName: "CalibrationStoreTestsSuite_clamping")
        
        CalibrationStore.saveMultiplier(50.0, defaults: defaults)
        #expect(CalibrationStore.loadMultiplier(defaults: defaults) == 10.0)
        
        CalibrationStore.saveMultiplier(0.02, defaults: defaults)
        #expect(CalibrationStore.loadMultiplier(defaults: defaults) == 0.1)
        
        defaults.removePersistentDomain(forName: "CalibrationStoreTestsSuite_clamping")
    }
}
