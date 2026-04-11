import Testing
@testable import LightMeter

struct KelvinInterpreterTests {

    // MARK: - Property 2: Kelvin range mapping correctness (100+ iterations)

    @Test func property_kelvinRangeMappingCorrectness() {
        var rng = SystemRandomNumberGenerator()

        // Independent oracle: compute expected result from kelvin value
        func expectedResult(for kelvin: Double) -> InterpretationResult {
            if kelvin >= 10000 {
                return InterpretationResult(
                    description: "Blue Sky 🧊",
                    tip: "Clear day shade, specialized lab environments"
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
            let result = KelvinInterpreter.interpret(kelvin: kelvin)
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
            let result = KelvinInterpreter.interpret(kelvin: kelvin)
            #expect(result == candlelight, "Kelvin=\(kelvin) below 1000 should map to Below 2,000K range")
        }
    }

    // MARK: - Representative value per range

    @Test func range_candlelight() {
        let r = KelvinInterpreter.interpret(kelvin: 1500)
        #expect(r.description == "Candlelight / Sunset 🔥")
        #expect(r.tip == "Psychological calm, pre-sleep, atmospheric cafes")
    }

    @Test func range_warmWhite() {
        let r = KelvinInterpreter.interpret(kelvin: 2700)
        #expect(r.description == "Warm White 💡")
        #expect(r.tip == "Bedrooms, living rooms, relaxation spaces")
    }

    @Test func range_naturalWhite() {
        let r = KelvinInterpreter.interpret(kelvin: 4000)
        #expect(r.description == "Natural White 🌤")
        #expect(r.tip == "Kitchens, dressing rooms, bathrooms")
    }

    @Test func range_daylight() {
        let r = KelvinInterpreter.interpret(kelvin: 5500)
        #expect(r.description == "Daylight 📖")
        #expect(r.tip == "Study rooms, offices, precision work (improves focus)")
    }

    @Test func range_coolWhite() {
        let r = KelvinInterpreter.interpret(kelvin: 8000)
        #expect(r.description == "Cool White ❄")
        #expect(r.tip == "Hospitals, factories, warehouses")
    }

    @Test func range_blueSky() {
        let r = KelvinInterpreter.interpret(kelvin: 12000)
        #expect(r.description == "Blue Sky 🧊")
        #expect(r.tip == "Clear day shade, specialized lab environments")
    }

    // MARK: - Boundary values

    @Test func boundary_1000() {
        let r = KelvinInterpreter.interpret(kelvin: 1000)
        #expect(r.description == "Candlelight / Sunset 🔥")
    }

    @Test func boundary_1999() {
        let r = KelvinInterpreter.interpret(kelvin: 1999)
        #expect(r.description == "Candlelight / Sunset 🔥")
    }

    @Test func boundary_2000() {
        let r = KelvinInterpreter.interpret(kelvin: 2000)
        #expect(r.description == "Warm White 💡")
    }

    @Test func boundary_3499() {
        let r = KelvinInterpreter.interpret(kelvin: 3499)
        #expect(r.description == "Warm White 💡")
    }

    @Test func boundary_3500() {
        let r = KelvinInterpreter.interpret(kelvin: 3500)
        #expect(r.description == "Natural White 🌤")
    }

    @Test func boundary_4999() {
        let r = KelvinInterpreter.interpret(kelvin: 4999)
        #expect(r.description == "Natural White 🌤")
    }

    @Test func boundary_5000() {
        let r = KelvinInterpreter.interpret(kelvin: 5000)
        #expect(r.description == "Daylight 📖")
    }

    @Test func boundary_6499() {
        let r = KelvinInterpreter.interpret(kelvin: 6499)
        #expect(r.description == "Daylight 📖")
    }

    @Test func boundary_6500() {
        let r = KelvinInterpreter.interpret(kelvin: 6500)
        #expect(r.description == "Cool White ❄")
    }

    @Test func boundary_9999() {
        let r = KelvinInterpreter.interpret(kelvin: 9999)
        #expect(r.description == "Cool White ❄")
    }

    @Test func boundary_10000() {
        let r = KelvinInterpreter.interpret(kelvin: 10000)
        #expect(r.description == "Blue Sky 🧊")
    }

    @Test func boundary_15000() {
        let r = KelvinInterpreter.interpret(kelvin: 15000)
        #expect(r.description == "Blue Sky 🧊")
    }

    // MARK: - Below 1000 fallback

    @Test func belowThousand_returnsCandlelightRange() {
        let r = KelvinInterpreter.interpret(kelvin: 500)
        #expect(r.description == "Candlelight / Sunset 🔥")
        #expect(r.tip == "Psychological calm, pre-sleep, atmospheric cafes")
    }
}
