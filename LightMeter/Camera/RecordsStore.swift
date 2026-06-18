import Foundation
import Observation
import SwiftData

/// Background serial actor managing SwiftData database context reads and writes.
actor RecordsDatabaseWorker {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func saveRecord(id: UUID, lux: Double, kelvin: Double, timestamp: Date, photoData: Data?) throws {
        let context = ModelContext(container)
        let entity = LightRecordEntity(
            id: id,
            lux: lux,
            kelvin: kelvin,
            timestamp: timestamp,
            photoData: photoData
        )
        context.insert(entity)
        try context.save()
        try enforceHistoryCap(context: context)
    }

    func deleteRecord(id: UUID) throws {
        let context = ModelContext(container)
        var fetchDescriptor = FetchDescriptor<LightRecordEntity>()
        fetchDescriptor.predicate = #Predicate { $0.id == id }
        
        if let entity = try context.fetch(fetchDescriptor).first {
            context.delete(entity)
            try context.save()
        }
    }

    func migrateLegacyRecords(_ legacyRecords: [LightRecord]) throws {
        let context = ModelContext(container)
        for record in legacyRecords {
            let entity = LightRecordEntity(
                id: record.id,
                lux: record.lux,
                kelvin: record.kelvin,
                timestamp: record.timestamp,
                photoData: record.photoData
            )
            context.insert(entity)
        }
        try context.save()
        try enforceHistoryCap(context: context)
    }

    func fetchPage(limit: Int, offset: Int) throws -> (records: [LightRecord], totalCount: Int) {
        let context = ModelContext(container)
        let totalCount = try context.fetchCount(FetchDescriptor<LightRecordEntity>())
        
        var fetchDescriptor = FetchDescriptor<LightRecordEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = limit
        fetchDescriptor.fetchOffset = offset
        
        let entities = try context.fetch(fetchDescriptor)
        let records = entities.map { $0.toStruct() }
        return (records, totalCount)
    }

    func generateCSVExportURL() throws -> URL? {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<LightRecordEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let entities = try context.fetch(fetchDescriptor)
        
        var csvString = "ID,Timestamp,Lux,Kelvin,Environment Chips\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for entity in entities {
            let timestampStr = dateFormatter.string(from: entity.timestamp)
            let chips = ActivityChip.activeChips(for: LuxRange.rangeIndex(for: entity.lux)).map { $0.rawValue }
            let chipsStr = chips.joined(separator: ";")
            csvString += "\(entity.id),\(timestampStr),\(entity.lux),\(entity.kelvin),\"\(chipsStr)\"\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("light_meter_history.csv")
        
        try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    private func enforceHistoryCap(context: ModelContext) throws {
        let fetchDescriptor = FetchDescriptor<LightRecordEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let allRecords = try context.fetch(fetchDescriptor)
        if allRecords.count > 100 {
            let recordsToDelete = allRecords[100...]
            for record in recordsToDelete {
                context.delete(record)
            }
            try context.save()
        }
    }
}

/// Model that isolates database loading/saving, record additions, list removals,
/// history capping, and CSV export. All disk operations are offloaded from the main actor.
@Observable
@MainActor
public final class RecordsStore: Sendable {
    public var records: [LightRecord] = []
    public var hasMorePages: Bool = false
    public var exportURL: URL? = nil
    public var activeFetchTask: Task<Void, Never>? = nil

    private let container: ModelContainer
    private let worker: RecordsDatabaseWorker
    private static let recordsKey = "light_meter_records"
    private let defaults: UserDefaults
    private let pageSize = 20
    private var currentPage = 0

    public init(container: ModelContainer? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        let schema = Schema([LightRecordEntity.self])
        let activeContainer: ModelContainer
        if let container = container {
            activeContainer = container
        } else {
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: false)
                activeContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                // The on-disk store failed to open (e.g. a migration or corruption
                // issue). History is non-critical, recomputable utility data, so we
                // fall back to an in-memory store rather than crash on launch.
                print("Persistent ModelContainer unavailable, falling back to in-memory: \(error)")
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                // A bare in-memory container can't realistically fail; if it somehow
                // does, there is no safe degraded mode left, so trapping is correct.
                activeContainer = try! ModelContainer(for: schema, configurations: [memoryConfig])
            }
        }
        self.container = activeContainer
        self.worker = RecordsDatabaseWorker(container: activeContainer)
        
        performMigrationAndInitialLoad()
    }

    public func loadFirstPage() {
        currentPage = 0
        records = []
        fetchPage(page: 0)
    }

    public func loadNextPage() {
        guard hasMorePages else { return }
        fetchPage(page: currentPage + 1)
    }

    @discardableResult
    public func saveRecord(lux: Double, kelvin: Double, photoData: Data? = nil) -> Task<Void, Never> {
        let id = UUID()
        let timestamp = Date()

        return Task {
            do {
                try await worker.saveRecord(id: id, lux: lux, kelvin: kelvin, timestamp: timestamp, photoData: photoData)
                self.loadFirstPage()
                await activeFetchTask?.value
            } catch {
                print("Failed to save record: \(error)")
            }
        }
    }

    @discardableResult
    public func deleteRecord(id: UUID) -> Task<Void, Never> {
        return Task {
            do {
                try await worker.deleteRecord(id: id)
                self.loadFirstPage()
                await activeFetchTask?.value
            } catch {
                print("Failed to delete record: \(error)")
            }
        }
    }

    public func generateCSVExportURL() async -> URL? {
        do {
            return try await worker.generateCSVExportURL()
        } catch {
            print("Failed to generate CSV: \(error)")
            return nil
        }
    }

    // MARK: - Private Helpers

    private func performMigrationAndInitialLoad() {
        if let legacyData = defaults.data(forKey: Self.recordsKey) {
            do {
                let legacyRecords = try JSONDecoder().decode([LightRecord].self, from: legacyData)
                if !legacyRecords.isEmpty {
                    Task {
                        do {
                            try await worker.migrateLegacyRecords(legacyRecords)
                            self.defaults.removeObject(forKey: Self.recordsKey)
                        } catch {
                            print("Failed to migrate legacy records: \(error)")
                        }
                        self.loadFirstPage()
                    }
                    return
                }
            } catch {
                print("Failed to migrate legacy records: \(error)")
            }
        }
        
        loadFirstPage()
    }

    private func fetchPage(page: Int) {
        let limit = pageSize
        let offset = page * pageSize
        
        activeFetchTask = Task {
            do {
                let result = try await worker.fetchPage(limit: limit, offset: offset)
                
                if page == 0 {
                    self.records = result.records
                } else {
                    self.records.append(contentsOf: result.records)
                }
                self.currentPage = page
                self.hasMorePages = self.records.count < result.totalCount
                self.updateExportURL()
            } catch {
                print("Failed to fetch page: \(error)")
            }
        }
    }

    private func updateExportURL() {
        Task {
            let url = await generateCSVExportURL()
            self.exportURL = url
        }
    }
}
