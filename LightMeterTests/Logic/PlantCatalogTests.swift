import Testing
import Foundation
@testable import LightMeter

/// Structural tests for the bundled Korean plant catalog (the moat artifact).
///
/// These tests load the catalog JSON directly from the source tree (rather
/// than Bundle.main, which differs between the app process and the test
/// runner) and assert that every entry meets the integrity contract:
/// citations present, ranges ordered, ids unique. If any of these break, the
/// catalog should not ship.
struct PlantCatalogTests {

    /// Resolve the catalog JSON by walking up from this test file. This works
    /// regardless of where xcodebuild stages the test bundle.
    private static func catalogURL() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 where url.lastPathComponent != "light-meter" && url.path != "/" {
            url.deleteLastPathComponent()
        }
        return url
            .appendingPathComponent("LightMeter")
            .appendingPathComponent("Logic")
            .appendingPathComponent("Resources")
            .appendingPathComponent("plant-catalog-kr-v1.json")
    }

    private static func loadCatalog() throws -> PlantCatalogFile {
        let data = try Data(contentsOf: catalogURL())
        return try JSONDecoder().decode(PlantCatalogFile.self, from: data)
    }

    @Test func decodesCleanly() throws {
        let catalog = try Self.loadCatalog()
        #expect(catalog.plants.count == catalog.totalEntries)
        #expect(catalog.totalEntries > 0)
    }

    @Test func honestAccounting_directlyCitedPlusDerivedEqualsTotal() throws {
        let catalog = try Self.loadCatalog()
        #expect(catalog.directlyCited + catalog.categoryDerived == catalog.totalEntries)
    }

    @Test func everyEntryHasAtLeastOneSourceCitation() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            #expect(!plant.sources.isEmpty, "\(plant.koreanName) (\(plant.scientificName)) has no sources")
        }
    }

    @Test func everySourceUrlIsAbsolute() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            for source in plant.sources {
                #expect(source.sourceUrl.hasPrefix("http"),
                    "\(plant.koreanName) source URL is not absolute: \(source.sourceUrl)")
            }
        }
    }

    @Test func ppfdRangesAreOrdered() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            #expect(plant.ppfd.min <= plant.ppfd.optimal,
                "\(plant.koreanName) PPFD min > optimal")
            #expect(plant.ppfd.optimal <= plant.ppfd.max,
                "\(plant.koreanName) PPFD optimal > max")
        }
    }

    @Test func dliRangesAreOrdered() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            #expect(plant.dli.min <= plant.dli.optimal, "\(plant.koreanName) DLI min > optimal")
            #expect(plant.dli.optimal <= plant.dli.max, "\(plant.koreanName) DLI optimal > max")
        }
    }

    @Test func luxRangesAreOrdered() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            #expect(plant.lux.min <= plant.lux.optimal, "\(plant.koreanName) lux min > optimal")
            #expect(plant.lux.optimal <= plant.lux.max, "\(plant.koreanName) lux optimal > max")
        }
    }

    @Test func idsAreUnique() throws {
        let catalog = try Self.loadCatalog()
        let ids = catalog.plants.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func idsAreKebabCase() throws {
        let catalog = try Self.loadCatalog()
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789-")
        for plant in catalog.plants {
            #expect(plant.id.allSatisfy { allowed.contains($0) },
                "\(plant.koreanName) id is not kebab-case: \(plant.id)")
            #expect(!plant.id.hasPrefix("-") && !plant.id.hasSuffix("-"))
        }
    }

    @Test func luxRangesAreInPhysicallyPlausibleBounds() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            // No houseplant tolerates below 0 lux; full noon sun outdoors caps ~120,000 lux.
            #expect(plant.lux.min >= 0,
                "\(plant.koreanName) lux min negative: \(plant.lux.min)")
            #expect(plant.lux.max <= 120_000,
                "\(plant.koreanName) lux max exceeds full sun: \(plant.lux.max)")
        }
    }

    @Test func careNotesAreLocalizedForKorean() throws {
        let catalog = try Self.loadCatalog()
        for plant in catalog.plants {
            #expect(!plant.careNotesEn.isEmpty)
            #expect(!plant.careNotesKo.isEmpty)
            // Korean note must actually contain at least one Hangul code point —
            // catches accidental English duplication.
            let hasHangul = plant.careNotesKo.unicodeScalars.contains { 0xAC00...0xD7A3 ~= $0.value }
            #expect(hasHangul, "\(plant.koreanName) careNotesKo has no Hangul")
        }
    }

    @Test func lookupById_returnsCorrectEntry() throws {
        let data = try Data(contentsOf: Self.catalogURL())
        let catalog = try PlantCatalog(data: data)
        let monstera = catalog.plant(id: "monstera-deliciosa")
        #expect(monstera != nil)
        #expect(monstera?.scientificName == "Monstera deliciosa")
    }

    @Test func plantsMatchingLux_filtersAndOrdersByDistanceToOptimal() throws {
        let data = try Data(contentsOf: Self.catalogURL())
        let catalog = try PlantCatalog(data: data)
        // Pick a mid-range reading every species' band should bracket somewhere.
        let matches = catalog.plants(matchingLux: 8_000)
        #expect(!matches.isEmpty)
        // Each match's optimal must be at least as close to 8000 as the next one.
        for i in 1..<matches.count {
            let d0 = abs(8_000 - matches[i - 1].lux.optimal)
            let d1 = abs(8_000 - matches[i].lux.optimal)
            #expect(d0 <= d1)
        }
    }

    @Test func plantsMatchingLux_extremeReadingsReturnSensibleResults() throws {
        let data = try Data(contentsOf: Self.catalogURL())
        let catalog = try PlantCatalog(data: data)
        // Very dim (closet-dark) should match the most shade-tolerant species (Chamaedorea, ZZ).
        let dim = catalog.plants(matchingLux: 600)
        #expect(!dim.isEmpty)
        // Full-sun reading should match nothing in a typical houseplant catalog
        // (only Hesperocyparis 'Goldcrest' caps at 81k lux — below 100k).
        let blasted = catalog.plants(matchingLux: 110_000)
        #expect(blasted.isEmpty)
    }
}
