import Testing
@testable import LightMeter

struct KelvinInterpreterTests {

    // MARK: - Property 2: Kelvin range mapping correctness (100+ iterations)

    @Test func property_kelvinRangeMappingCorrectness() {
        var rng = SystemRandomNumberGenerator()

        // Independent oracle: compute expected result from kelvin value for English
        func expectedResult(for kelvin: Double) -> InterpretationResult {
            if kelvin >= 10000 {
                return InterpretationResult(
                    description: "Blue Sky 🧊",
                    tip: "Shade on a clear day, specialized laboratory environments"
                )
            } else if kelvin >= 6500 {
                return InterpretationResult(
                    description: "Cool White ❄",
                    tip: "Hospitals, factories, warehouses"
                )
            } else if kelvin >= 5000 {
                return InterpretationResult(
                    description: "Daylight 📖",
                    tip: "Study rooms, offices, precision work (improves focus)"
                )
            } else if kelvin >= 3500 {
                return InterpretationResult(
                    description: "Natural White 🌤",
                    tip: "Kitchens, dressing rooms, bathrooms"
                )
            } else if kelvin >= 2000 {
                return InterpretationResult(
                    description: "Warm White 💡",
                    tip: "Bedrooms, living rooms, relaxation spaces"
                )
            } else {
                return InterpretationResult(
                    description: "Candlelight / Sunset 🔥",
                    tip: "Psychological calm, pre-sleep, atmospheric cafes"
                )
            }
        }

        for _ in 0..<150 {
            let kelvin = Double.random(in: 0...20000, using: &rng)
            let result = KelvinInterpreter.interpret(kelvin: kelvin, language: .english)
            let expected = expectedResult(for: kelvin)
            #expect(result == expected, "Mismatch for kelvin=\(kelvin)")
        }
    }

    @Test func property_belowThousandAlwaysReturnsCandlelight() {
        var rng = SystemRandomNumberGenerator()
        let candlelight = InterpretationResult(
            description: "Candlelight / Sunset 🔥",
            tip: "Psychological calm, pre-sleep, atmospheric cafes"
        )

        for _ in 0..<100 {
            let kelvin = Double.random(in: -1000..<1000, using: &rng)
            let result = KelvinInterpreter.interpret(kelvin: kelvin, language: .english)
            #expect(result == candlelight, "Kelvin=\(kelvin) below 1000 should map to Below 2,000K range")
        }
    }

    // MARK: - Property 1: Kelvin interpretation consistency (150+ iterations)

    @Test func property_kelvinInterpretationConsistency() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<200 {
            let kelvin = Double.random(in: 1000...15000, using: &rng)
            let result1 = KelvinInterpreter.interpret(kelvin: kelvin, language: .english)
            let result2 = KelvinInterpreter.interpret(kelvin: kelvin, language: .english)

            #expect(!result1.description.isEmpty, "Empty description for kelvin=\(kelvin)")
            #expect(!result1.tip.isEmpty, "Empty tip for kelvin=\(kelvin)")
            #expect(result1 == result2, "Non-deterministic result for kelvin=\(kelvin)")
        }
    }

    // MARK: - Representative value per range

    @Test func range_candlelight() {
        let r = KelvinInterpreter.interpret(kelvin: 1500, language: .english)
        #expect(r.description == "Candlelight / Sunset 🔥")
        #expect(r.tip == "Psychological calm, pre-sleep, atmospheric cafes")
    }

    @Test func range_warmWhite() {
        let r = KelvinInterpreter.interpret(kelvin: 2700, language: .english)
        #expect(r.description == "Warm White 💡")
        #expect(r.tip == "Bedrooms, living rooms, relaxation spaces")
    }

    @Test func range_naturalWhite() {
        let r = KelvinInterpreter.interpret(kelvin: 4000, language: .english)
        #expect(r.description == "Natural White 🌤")
        #expect(r.tip == "Kitchens, dressing rooms, bathrooms")
    }

    @Test func range_daylight() {
        let r = KelvinInterpreter.interpret(kelvin: 5500, language: .english)
        #expect(r.description == "Daylight 📖")
        #expect(r.tip == "Study rooms, offices, precision work (improves focus)")
    }

    @Test func range_coolWhite() {
        let r = KelvinInterpreter.interpret(kelvin: 8000, language: .english)
        #expect(r.description == "Cool White ❄")
        #expect(r.tip == "Hospitals, factories, warehouses")
    }

    @Test func range_blueSky() {
        let r = KelvinInterpreter.interpret(kelvin: 12000, language: .english)
        #expect(r.description == "Blue Sky 🧊")
        #expect(r.tip == "Shade on a clear day, specialized laboratory environments")
    }

    // MARK: - Boundary values

    @Test func boundary_1000() {
        let r = KelvinInterpreter.interpret(kelvin: 1000, language: .english)
        #expect(r.description == "Candlelight / Sunset 🔥")
    }

    @Test func boundary_1999() {
        let r = KelvinInterpreter.interpret(kelvin: 1999, language: .english)
        #expect(r.description == "Candlelight / Sunset 🔥")
    }

    @Test func boundary_2000() {
        let r = KelvinInterpreter.interpret(kelvin: 2000, language: .english)
        #expect(r.description == "Warm White 💡")
    }

    @Test func boundary_3499() {
        let r = KelvinInterpreter.interpret(kelvin: 3499, language: .english)
        #expect(r.description == "Warm White 💡")
    }

    @Test func boundary_3500() {
        let r = KelvinInterpreter.interpret(kelvin: 3500, language: .english)
        #expect(r.description == "Natural White 🌤")
    }

    @Test func boundary_4999() {
        let r = KelvinInterpreter.interpret(kelvin: 4999, language: .english)
        #expect(r.description == "Natural White 🌤")
    }

    @Test func boundary_5000() {
        let r = KelvinInterpreter.interpret(kelvin: 5000, language: .english)
        #expect(r.description == "Daylight 📖")
    }

    @Test func boundary_6499() {
        let r = KelvinInterpreter.interpret(kelvin: 6499, language: .english)
        #expect(r.description == "Daylight 📖")
    }

    @Test func boundary_6500() {
        let r = KelvinInterpreter.interpret(kelvin: 6500, language: .english)
        #expect(r.description == "Cool White ❄")
    }

    @Test func boundary_9999() {
        let r = KelvinInterpreter.interpret(kelvin: 9999, language: .english)
        #expect(r.description == "Cool White ❄")
    }

    @Test func boundary_10000() {
        let r = KelvinInterpreter.interpret(kelvin: 10000, language: .english)
        #expect(r.description == "Blue Sky 🧊")
    }

    @Test func boundary_15000() {
        let r = KelvinInterpreter.interpret(kelvin: 15000, language: .english)
        #expect(r.description == "Blue Sky 🧊")
    }

    // MARK: - Below 1000 fallback

    @Test func belowThousand_returnsCandlelightRange() {
        let r = KelvinInterpreter.interpret(kelvin: 500, language: .english)
        #expect(r.description == "Candlelight / Sunset 🔥")
        #expect(r.tip == "Psychological calm, pre-sleep, atmospheric cafes")
    }

    // MARK: - Localized mappings (Korean and French)

    @Test func localization_korean() {
        let r = KelvinInterpreter.interpret(kelvin: 2700, language: .korean)
        #expect(r.description == "전구색 (따뜻한 백색) 💡")
        #expect(r.tip == "침실, 거실, 안락한 휴식 공간")
    }

    @Test func localization_french() {
        let r = KelvinInterpreter.interpret(kelvin: 2700, language: .french)
        #expect(r.description == "Blanc Chaud 💡")
        #expect(r.tip == "Chambres, salons, espaces de détente")
    }
}
