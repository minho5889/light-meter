import Foundation

/// One entry in the Sunny plant catalog — a houseplant species with its light
/// requirements expressed three ways (PPFD, DLI, and lux) plus the citations
/// the entry was derived from.
///
/// `derivationFlag` is non-empty for ~half the entries where species-level
/// PPFD literature is sparse and the range was derived from a genus/care-class
/// analog. Showing this honestly in-app is part of the brand moat — most plant
/// apps invent numbers and don't say so.
public struct PlantSpecies: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let scientificName: String
    public let koreanName: String
    public let englishName: String
    public let lightCategory: String
    public let ppfd: Range
    public let dli: Range
    public let lux: LuxRangeValue
    public let careNotesEn: String
    public let careNotesKo: String
    public let derivationFlag: String
    public let sources: [Source]

    /// min ≤ optimal ≤ max in PPFD (µmol/m²/s) or DLI (mol/m²/day).
    public struct Range: Codable, Hashable, Sendable {
        public let min: Double
        public let optimal: Double
        public let max: Double
    }

    /// Lux ranges + the light-source assumption used to convert from PPFD.
    public struct LuxRangeValue: Codable, Hashable, Sendable {
        public let min: Double
        public let optimal: Double
        public let max: Double
        /// e.g. "sunlight, factor 54" — the lux↔PPFD relation depends on
        /// spectrum, so this is recorded per-entry rather than assumed.
        public let conversionAssumption: String
    }

    public struct Source: Codable, Hashable, Sendable {
        public let claim: String
        public let sourceUrl: String
        public let sourceType: String
    }

    /// True if `lux` is within this species' optimal band.
    public func isOptimal(lux: Double) -> Bool {
        lux >= self.lux.min && lux <= self.lux.max
    }
}

/// Top-level catalog: versioned + carries dataset-wide metadata so the in-app
/// "honest error bands" page can show users exactly what the numbers do and
/// don't represent.
public struct PlantCatalogFile: Codable, Sendable {
    public let version: String
    public let totalEntries: Int
    public let directlyCited: Int
    public let categoryDerived: Int
    public let plants: [PlantSpecies]
    public let meta: Meta

    public struct Meta: Codable, Sendable {
        public let conversionNote: String
        public let photoperiodAssumption: String
        public let limitations: String
    }
}
