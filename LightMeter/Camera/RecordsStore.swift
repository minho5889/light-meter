import Foundation
import Observation

/// Model that isolates JSON loading/saving, record additions, and list removals.
@Observable
@MainActor
public final class RecordsStore {
    public var records: [LightRecord] = []
    private static let recordsKey = "light_meter_records"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadRecords()
    }

    public func saveRecord(lux: Double, kelvin: Double) {
        let index = LuxRange.rangeIndex(for: lux)
        let chips = Array(ActivityChip.activeChips(for: index))
        let newRecord = LightRecord(lux: lux, kelvin: kelvin, timestamp: Date(), activeChips: chips)
        
        records.insert(newRecord, at: 0)
        saveRecordsToDisk()
    }

    public func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        saveRecordsToDisk()
    }

    public func saveRecordsToDisk() {
        do {
            let data = try JSONEncoder().encode(records)
            defaults.set(data, forKey: Self.recordsKey)
        } catch {
            print("Failed to save records: \(error)")
        }
    }

    public func loadRecords() {
        guard let data = defaults.data(forKey: Self.recordsKey) else { return }
        do {
            records = try JSONDecoder().decode([LightRecord].self, from: data)
        } catch {
            print("Failed to load records: \(error)")
        }
    }
}
