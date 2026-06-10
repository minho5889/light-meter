import Foundation
import Observation
import SwiftData

/// Model that isolates database loading/saving, record additions, list removals,
/// history capping, and CSV export. All disk operations are offloaded from the main actor.
@Observable
@MainActor
public final class RecordsStore: Sendable {
    public var records: [LightRecord] = []
    public var hasMorePages: Bool = false
    public var exportURL: URL? = nil

    private let container: ModelContainer
    private static let recordsKey = "light_meter_records"
    private let defaults: UserDefaults
    private let pageSize = 20
    private var currentPage = 0
    private var fetchGeneration = 0

    public init(container: ModelContainer? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        do {
            if let container = container {
                self.container = container
            } else {
                let schema = Schema([LightRecordEntity.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: false)
                self.container = try ModelContainer(for: schema, configurations: [config])
            }
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
        
        performMigrationAndInitialLoad()
    }

    public func loadFirstPage() {
        currentPage = 0
        records = []
        fetchGeneration += 1
        fetchPage(page: 0, generation: fetchGeneration)
    }

    public func loadNextPage() {
        guard hasMorePages else { return }
        fetchPage(page: currentPage + 1, generation: fetchGeneration)
    }

    public func saveRecord(lux: Double, kelvin: Double) {
        let container = self.container
        let index = LuxRange.rangeIndex(for: lux)
        let chips = Array(ActivityChip.activeChips(for: index))
        let newRecord = LightRecord(lux: lux, kelvin: kelvin, timestamp: Date(), activeChips: chips)
        
        Task.detached {
            do {
                let context = ModelContext(container)
                let entity = LightRecordEntity(
                    id: newRecord.id,
                    lux: newRecord.lux,
                    kelvin: newRecord.kelvin,
                    timestamp: newRecord.timestamp,
                    activeChips: newRecord.activeChips
                )
                context.insert(entity)
                try context.save()
                
                try self.enforceHistoryCap(context: context)
                
                await MainActor.run {
                    self.loadFirstPage()
                }
            } catch {
                print("Failed to save record: \(error)")
            }
        }
    }

    public func deleteRecord(id: UUID) {
        let container = self.container
        
        Task.detached {
            do {
                let context = ModelContext(container)
                var fetchDescriptor = FetchDescriptor<LightRecordEntity>()
                fetchDescriptor.predicate = #Predicate { $0.id == id }
                
                if let entity = try context.fetch(fetchDescriptor).first {
                    context.delete(entity)
                    try context.save()
                }
                
                await MainActor.run {
                    self.loadFirstPage()
                }
            } catch {
                print("Failed to delete record: \(error)")
            }
        }
    }

    public func generateCSVExportURL() async -> URL? {
        let container = self.container
        return await Task.detached {
            do {
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
                    let chipsStr = entity.rawActiveChips.joined(separator: ";")
                    
                    csvString += "\(entity.id),\(timestampStr),\(entity.lux),\(entity.kelvin),\"\(chipsStr)\"\n"
                }
                
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("light_meter_history.csv")
                
                try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
                return tempURL
            } catch {
                print("Failed to generate CSV: \(error)")
                return nil
            }
        }.value
    }

    // MARK: - Private Helpers

    private func performMigrationAndInitialLoad() {
        if let legacyData = defaults.data(forKey: Self.recordsKey) {
            do {
                let legacyRecords = try JSONDecoder().decode([LightRecord].self, from: legacyData)
                if !legacyRecords.isEmpty {
                    let container = self.container
                    Task.detached {
                        let context = ModelContext(container)
                        for record in legacyRecords {
                            let entity = LightRecordEntity(
                                id: record.id,
                                lux: record.lux,
                                kelvin: record.kelvin,
                                timestamp: record.timestamp,
                                activeChips: record.activeChips
                            )
                            context.insert(entity)
                        }
                        try? context.save()
                        try? self.enforceHistoryCap(context: context)
                        
                        await MainActor.run {
                            self.defaults.removeObject(forKey: Self.recordsKey)
                            self.loadFirstPage()
                        }
                    }
                    return
                }
            } catch {
                print("Failed to migrate legacy records: \(error)")
            }
        }
        
        loadFirstPage()
    }

    private func fetchPage(page: Int, generation: Int) {
        let container = self.container
        let limit = pageSize
        let offset = page * pageSize

        Task.detached {
            do {
                let context = ModelContext(container)

                let totalCount = try context.fetchCount(FetchDescriptor<LightRecordEntity>())

                var fetchDescriptor = FetchDescriptor<LightRecordEntity>(
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                fetchDescriptor.fetchLimit = limit
                fetchDescriptor.fetchOffset = offset

                let entities = try context.fetch(fetchDescriptor)
                let structRecords = entities.map { $0.toStruct() }

                await MainActor.run {
                    guard self.fetchGeneration == generation else { return }
                    if page == 0 {
                        self.records = structRecords
                    } else {
                        self.records.append(contentsOf: structRecords)
                    }
                    self.currentPage = page
                    self.hasMorePages = self.records.count < totalCount
                    self.updateExportURL()
                }
            } catch {
                print("Failed to fetch page: \(error)")
            }
        }
    }

    nonisolated private func enforceHistoryCap(context: ModelContext) throws {
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

    private func updateExportURL() {
        Task {
            let url = await generateCSVExportURL()
            await MainActor.run {
                self.exportURL = url
            }
        }
    }
}
