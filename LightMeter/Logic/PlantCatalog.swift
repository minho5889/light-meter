import Foundation

/// Singleton access to the bundled Sunny plant catalog (KR v1).
///
/// The catalog is the durable moat artifact of the gardening pivot — 30 KR
/// houseplants with peer-reviewed PPFD/DLI ranges and full source citations.
/// It loads once at first access and exposes typed queries (lookup by id,
/// species matching a given lux reading, etc.) — the foundation the
/// plant-fit verdict will be built on top of.
public final class PlantCatalog: Sendable {

    /// Shared instance. Loads the bundled JSON on first access; subsequent
    /// access returns the cached result. Falls back to an empty catalog if
    /// the resource is missing or malformed — Records and live measurement
    /// must keep working even if the catalog ever fails to load.
    public static let shared = PlantCatalog()

    public let file: PlantCatalogFile

    private init() {
        self.file = Self.loadBundled() ?? Self.empty()
    }

    /// All species, in the order the catalog was authored (alphabetical by
    /// Korean name).
    public var plants: [PlantSpecies] { file.plants }

    /// Look up by stable id (kebab-case, e.g. "monstera-deliciosa").
    public func plant(id: String) -> PlantSpecies? {
        plants.first { $0.id == id }
    }

    /// Species whose optimal-lux band contains the given reading — the raw
    /// "what would do well here?" query. Ordered by how centrally the reading
    /// sits in each species' band (closer to optimal = earlier).
    public func plants(matchingLux lux: Double) -> [PlantSpecies] {
        plants
            .filter { $0.isOptimal(lux: lux) }
            .sorted { abs(lux - $0.lux.optimal) < abs(lux - $1.lux.optimal) }
    }

    // MARK: - Loading

    private static func loadBundled() -> PlantCatalogFile? {
        guard let url = Bundle.main.url(forResource: "plant-catalog-kr-v1", withExtension: "json") else {
            print("PlantCatalog: bundled resource not found")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PlantCatalogFile.self, from: data)
        } catch {
            print("PlantCatalog: decode failed — \(error)")
            return nil
        }
    }

    private static func empty() -> PlantCatalogFile {
        PlantCatalogFile(
            version: "0.0.0-empty",
            totalEntries: 0,
            directlyCited: 0,
            categoryDerived: 0,
            plants: [],
            meta: .init(
                conversionNote: "",
                photoperiodAssumption: "",
                limitations: "Catalog unavailable (resource missing or malformed)."
            )
        )
    }

    /// Test-only initializer: decode an explicit JSON blob instead of the
    /// bundled resource. Used by the test suite so tests don't depend on
    /// the host bundle layout.
    init(data: Data) throws {
        self.file = try JSONDecoder().decode(PlantCatalogFile.self, from: data)
    }
}
