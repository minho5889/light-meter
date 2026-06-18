import Foundation
import SwiftData

/// SwiftData model representing a saved light measurement capture.
///
/// Activity chips are intentionally **not** stored: they are a pure function of
/// `lux` (`ActivityChip.activeChips(for:)`), so persisting them was redundant and
/// triggered a noisy CoreData array-materialization fault for the `[String]`
/// attribute. They are recomputed on read in `toStruct()`, yielding identical
/// results to what was previously saved.
@Model
public final class LightRecordEntity {
    @Attribute(.unique) public var id: UUID
    public var lux: Double
    public var kelvin: Double
    public var timestamp: Date
    /// The captured snapshot (downscaled JPEG). Stored as an external file so the
    /// store DB stays lean; cleaned up automatically when the record is deleted.
    @Attribute(.externalStorage) public var photoData: Data?

    public init(id: UUID = UUID(), lux: Double, kelvin: Double, timestamp: Date = Date(), photoData: Data? = nil) {
        self.id = id
        self.lux = lux
        self.kelvin = kelvin
        self.timestamp = timestamp
        self.photoData = photoData
    }

    public func toStruct() -> LightRecord {
        let chips = Array(ActivityChip.activeChips(for: LuxRange.rangeIndex(for: lux)))
        return LightRecord(id: id, lux: lux, kelvin: kelvin, timestamp: timestamp, activeChips: chips, photoData: photoData)
    }
}
