import Testing
import Foundation
@testable import LightMeter

@MainActor
struct CameraStateDecompositionTests {

    @Test func testMeasurementModelCalibration() {
        let model = MeasurementModel()
        model.calibrationMultiplier = 1.0

        // Test basic update
        model.update(luxValue: 100.0, kelvinValue: 5000.0, tintValue: 0.0)
        #expect(model.lastRawLux == 100.0)
        
        // Calibrate to 150.0 target
        model.calibrate(to: 150.0)
        #expect(model.calibrationMultiplier == 1.5)
        
        // Reset calibration
        model.resetCalibration()
        #expect(model.calibrationMultiplier == 1.0)
    }

    @Test func testRecordsStoreAddAndDelete() {
        let defaults = UserDefaults(suiteName: "RecordsStoreTestsSuite")!
        defaults.removePersistentDomain(forName: "RecordsStoreTestsSuite")

        let store = RecordsStore(defaults: defaults)
        #expect(store.records.isEmpty)
        
        store.saveRecord(lux: 200.0, kelvin: 4000.0)
        #expect(store.records.count == 1)
        #expect(store.records[0].lux == 200.0)
        #expect(store.records[0].kelvin == 4000.0)

        let recordId = store.records[0].id
        store.deleteRecord(id: recordId)
        #expect(store.records.isEmpty)

        defaults.removePersistentDomain(forName: "RecordsStoreTestsSuite")
    }
}
