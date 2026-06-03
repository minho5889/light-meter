import Foundation

/// Model representing a saved light measurement capture.
public struct LightRecord: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public let lux: Double
    public let kelvin: Double
    public let timestamp: Date
    public let activeChips: [ActivityChip]

    public init(id: UUID = UUID(), lux: Double, kelvin: Double, timestamp: Date = Date(), activeChips: [ActivityChip]) {
        self.id = id
        self.lux = lux
        self.kelvin = kelvin
        self.timestamp = timestamp
        self.activeChips = activeChips
    }

    enum CodingKeys: String, CodingKey {
        case id, lux, kelvin, timestamp, activeChips
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.lux = try container.decode(Double.self, forKey: .lux)
        self.kelvin = try container.decode(Double.self, forKey: .kelvin)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Attempt to decode as [ActivityChip], fallback to mapping legacy [String] values to ActivityChip
        if let chips = try? container.decode([ActivityChip].self, forKey: .activeChips) {
            self.activeChips = chips
        } else if let _ = try? container.decode([String].self, forKey: .activeChips) {
            // Map legacy string array by looking up the current lux range's active chips
            let index = LuxRange.rangeIndex(for: lux)
            self.activeChips = Array(ActivityChip.activeChips(for: index))
        } else {
            self.activeChips = []
        }
    }
}
