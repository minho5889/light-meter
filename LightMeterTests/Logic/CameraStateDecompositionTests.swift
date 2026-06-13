import Testing
import Foundation
import SwiftData
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

    @Test func testRecordsStoreAddAndDelete() async throws {
        let defaults = UserDefaults(suiteName: "RecordsStoreTestsSuite")!
        defaults.removePersistentDomain(forName: "RecordsStoreTestsSuite")

        let schema = Schema([LightRecordEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let store = RecordsStore(container: container, defaults: defaults)
        
        // Wait briefly for initial load
        await store.activeFetchTask?.value
        #expect(store.records.isEmpty)
        
        await store.saveRecord(lux: 200.0, kelvin: 4000.0).value
        
        #expect(store.records.count == 1)
        #expect(store.records[0].lux == 200.0)
        #expect(store.records[0].kelvin == 4000.0)

        let recordId = store.records[0].id
        await store.deleteRecord(id: recordId).value
        
        #expect(store.records.isEmpty)
        defaults.removePersistentDomain(forName: "RecordsStoreTestsSuite")
    }

    @Test func testSwiftDataMigration() async throws {
        let defaults = UserDefaults(suiteName: "MigrationTestsSuite")!
        defaults.removePersistentDomain(forName: "MigrationTestsSuite")

        // 1. Write legacy JSON data to defaults
        let legacyRecord = LightRecord(lux: 350.0, kelvin: 4500.0, activeChips: [.readingAndStudy])
        let legacyData = try JSONEncoder().encode([legacyRecord])
        defaults.set(legacyData, forKey: "light_meter_records")

        let schema = Schema([LightRecordEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        // 2. Instantiate store, triggering migration
        let store = RecordsStore(container: container, defaults: defaults)

        // 3. Wait for migration to complete
        for _ in 0..<100 {
            if store.records.count == 1 { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(store.records.count == 1)
        #expect(store.records[0].lux == 350.0)
        #expect(store.records[0].kelvin == 4500.0)
        
        // Verify defaults has been cleared
        #expect(defaults.data(forKey: "light_meter_records") == nil)

        defaults.removePersistentDomain(forName: "MigrationTestsSuite")
    }

    @Test func testHistoryCap() async throws {
        let defaults = UserDefaults(suiteName: "CapTestsSuite")!
        defaults.removePersistentDomain(forName: "CapTestsSuite")

        let schema = Schema([LightRecordEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let store = RecordsStore(container: container, defaults: defaults)
        await store.activeFetchTask?.value
        
        // Save 105 records sequentially
        for i in 1...105 {
            await store.saveRecord(lux: Double(i), kelvin: 5000.0).value
        }

        // Fetch everything from context directly to confirm the database cap is exactly 100
        let context = ModelContext(container)
        let totalCount = try context.fetchCount(FetchDescriptor<LightRecordEntity>())
        #expect(totalCount == 100)

        // Make sure the 5 oldest records (values 1 to 5) were deleted and we kept the latest (6 to 105)
        let entities = try context.fetch(FetchDescriptor<LightRecordEntity>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)]))
        let minLux = entities.map { $0.lux }.min() ?? 0.0
        #expect(minLux == 6.0)

        defaults.removePersistentDomain(forName: "CapTestsSuite")
    }

    @Test func testPaging() async throws {
        let defaults = UserDefaults(suiteName: "PagingTestsSuite")!
        defaults.removePersistentDomain(forName: "PagingTestsSuite")

        let schema = Schema([LightRecordEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let store = RecordsStore(container: container, defaults: defaults)
        await store.activeFetchTask?.value

        // Save 45 records sequentially
        for i in 1...45 {
            await store.saveRecord(lux: Double(i), kelvin: 4000.0).value
        }

        #expect(store.records.count == 20)
        #expect(store.hasMorePages == true)

        // Load next page (page 1, adds 20, total 40)
        store.loadNextPage()
        await store.activeFetchTask?.value

        #expect(store.records.count == 40)
        #expect(store.hasMorePages == true)

        // Load next page (page 2, adds 5, total 45)
        store.loadNextPage()
        await store.activeFetchTask?.value

        #expect(store.records.count == 45)
        #expect(store.hasMorePages == false)

        defaults.removePersistentDomain(forName: "PagingTestsSuite")
    }

    @Test func testCSVExport() async throws {
        let defaults = UserDefaults(suiteName: "CSVTestsSuite")!
        defaults.removePersistentDomain(forName: "CSVTestsSuite")

        let schema = Schema([LightRecordEntity.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        let store = RecordsStore(container: container, defaults: defaults)
        await store.saveRecord(lux: 100.0, kelvin: 5000.0).value

        let csvURL = try await #require(store.generateCSVExportURL())
        let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
        
        #expect(csvContent.contains("Timestamp,Lux,Kelvin"))
        #expect(csvContent.contains("100.0,5000.0"))

        defaults.removePersistentDomain(forName: "CSVTestsSuite")
    }
}
