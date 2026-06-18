import Foundation
import SwiftData

/// SwiftData model representing a saved light measurement capture.
@Model
public final class LightRecordEntity {
    @Attribute(.unique) public var id: UUID
    public var lux: Double
    public var kelvin: Double
    public var timestamp: Date
    public var rawActiveChips: [String]
    /// The captured snapshot (downscaled JPEG). Stored as an external file so the
    /// store DB stays lean; cleaned up automatically when the record is deleted.
    @Attribute(.externalStorage) public var photoData: Data?

    public init(id: UUID = UUID(), lux: Double, kelvin: Double, timestamp: Date = Date(), activeChips: [ActivityChip], photoData: Data? = nil) {
        self.id = id
        self.lux = lux
        self.kelvin = kelvin
        self.timestamp = timestamp
        self.rawActiveChips = activeChips.map { $0.rawValue }
        self.photoData = photoData
    }

    public func toStruct() -> LightRecord {
        let chips = rawActiveChips.compactMap { ActivityChip(rawValue: $0) }
        return LightRecord(id: id, lux: lux, kelvin: kelvin, timestamp: timestamp, activeChips: chips, photoData: photoData)
    }
}
