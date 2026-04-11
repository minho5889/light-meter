import Testing
@testable import LightMeter

struct LuxInterpreterTests {

    // MARK: - Property 1: Lux range mapping correctness (100+ iterations)

    @Test func property_luxRangeMappingCorrectness() {
        var rng = SystemRandomNumberGenerator()

        // Independent oracle: compute expected result from lux value
        func expectedResult(for lux: Double) -> InterpretationResult {
            if lux > 10000 {
                return InterpretationResult(
                    description: "Direct sunlight on a clear day, noon outdoors",
                    tip: "Strong sunlight. Protect your eyes and watch for plant burns."
                )
            } else if lux > 2000 {
                return InterpretationResult(
                    description: "Cloudy day outdoors, sunset outdoors",
                    tip: "Good for outdoor activities. Partial shade level for plants."
                )
            } else if lux > 1000 {
                return InterpretationResult(
                    description: "Bright window (indoors), broadcast studios, operating rooms",
                    tip: "Very bright. Suitable for video production or professional work."
                )
            } else if lux > 500 {
                return InterpretationResult(
                    description: "Focused studying, precision handwork, store displays",
                    tip: "Recommended for study rooms or detailed tasks like sewing."
                )
            } else if lux > 200 {
                return InterpretationResult(
                    description: "General office work, kitchen cooking, light reading",
                    tip: "The most standard brightness for daily activities and office work."
                )
            } else if lux > 100 {
                return InterpretationResult(
                    description: "Living room relaxation, dining, hotel rooms",
                    tip: "Optimal for comfortable rest. Good for watching TV."
                )
            } else if lux > 10 {
                return InterpretationResult(
                    description: "Hallways, bathrooms, storage rooms, movie theaters",
                    tip: "Suitable for passing through. Not appropriate for extended work."
                )
            } else {
                return InterpretationResult(
                    description: "Very dark outdoors, full moon night",
                    tip: "Pre-sleep conditions. Be careful when moving around."
                )
            }
        }

        for _ in 0..<150 {
            let lux = Double.random(in: -1000...200000, using: &rng)
            let result = LuxInterpreter.interpret(lux: lux)
            let expected = expectedResult(for: lux)
            #expect(result == expected, "Mismatch for lux=\(lux)")
        }
    }

    @Test func property_negativeValuesAlwaysReturnDarkRange() {
        var rng = SystemRandomNumberGenerator()
        let darkRange = InterpretationResult(
            description: "Very dark outdoors, full moon night",
            tip: "Pre-sleep conditions. Be careful when moving around."
        )

        for _ in 0..<100 {
            let lux = Double.random(in: -100000 ... -0.001, using: &rng)
            let result = LuxInterpreter.interpret(lux: lux)
            #expect(result == darkRange, "Negative lux=\(lux) should map to 0–10 range")
        }
    }

    // MARK: - Representative value per range

    @Test func range_veryDark() {
        let r = LuxInterpreter.interpret(lux: 5)
        #expect(r.description == "Very dark outdoors, full moon night")
        #expect(r.tip == "Pre-sleep conditions. Be careful when moving around.")
    }

    @Test func range_hallways() {
        let r = LuxInterpreter.interpret(lux: 50)
        #expect(r.description == "Hallways, bathrooms, storage rooms, movie theaters")
        #expect(r.tip == "Suitable for passing through. Not appropriate for extended work.")
    }

    @Test func range_livingRoom() {
        let r = LuxInterpreter.interpret(lux: 150)
        #expect(r.description == "Living room relaxation, dining, hotel rooms")
        #expect(r.tip == "Optimal for comfortable rest. Good for watching TV.")
    }

    @Test func range_office() {
        let r = LuxInterpreter.interpret(lux: 350)
        #expect(r.description == "General office work, kitchen cooking, light reading")
        #expect(r.tip == "The most standard brightness for daily activities and office work.")
    }

    @Test func range_studying() {
        let r = LuxInterpreter.interpret(lux: 750)
        #expect(r.description == "Focused studying, precision handwork, store displays")
        #expect(r.tip == "Recommended for study rooms or detailed tasks like sewing.")
    }

    @Test func range_brightWindow() {
        let r = LuxInterpreter.interpret(lux: 1500)
        #expect(r.description == "Bright window (indoors), broadcast studios, operating rooms")
        #expect(r.tip == "Very bright. Suitable for video production or professional work.")
    }

    @Test func range_cloudyDay() {
        let r = LuxInterpreter.interpret(lux: 5000)
        #expect(r.description == "Cloudy day outdoors, sunset outdoors")
        #expect(r.tip == "Good for outdoor activities. Partial shade level for plants.")
    }

    @Test func range_directSunlight() {
        let r = LuxInterpreter.interpret(lux: 50000)
        #expect(r.description == "Direct sunlight on a clear day, noon outdoors")
        #expect(r.tip == "Strong sunlight. Protect your eyes and watch for plant burns.")
    }

    // MARK: - Boundary values

    @Test func boundary_0() {
        let r = LuxInterpreter.interpret(lux: 0)
        #expect(r.description == "Very dark outdoors, full moon night")
    }

    @Test func boundary_10() {
        let r = LuxInterpreter.interpret(lux: 10)
        #expect(r.description == "Very dark outdoors, full moon night")
    }

    @Test func boundary_11() {
        let r = LuxInterpreter.interpret(lux: 11)
        #expect(r.description == "Hallways, bathrooms, storage rooms, movie theaters")
    }

    @Test func boundary_100() {
        let r = LuxInterpreter.interpret(lux: 100)
        #expect(r.description == "Hallways, bathrooms, storage rooms, movie theaters")
    }

    @Test func boundary_101() {
        let r = LuxInterpreter.interpret(lux: 101)
        #expect(r.description == "Living room relaxation, dining, hotel rooms")
    }

    @Test func boundary_200() {
        let r = LuxInterpreter.interpret(lux: 200)
        #expect(r.description == "Living room relaxation, dining, hotel rooms")
    }

    @Test func boundary_201() {
        let r = LuxInterpreter.interpret(lux: 201)
        #expect(r.description == "General office work, kitchen cooking, light reading")
    }

    @Test func boundary_500() {
        let r = LuxInterpreter.interpret(lux: 500)
        #expect(r.description == "General office work, kitchen cooking, light reading")
    }

    @Test func boundary_501() {
        let r = LuxInterpreter.interpret(lux: 501)
        #expect(r.description == "Focused studying, precision handwork, store displays")
    }

    @Test func boundary_1000() {
        let r = LuxInterpreter.interpret(lux: 1000)
        #expect(r.description == "Focused studying, precision handwork, store displays")
    }

    @Test func boundary_1001() {
        let r = LuxInterpreter.interpret(lux: 1001)
        #expect(r.description == "Bright window (indoors), broadcast studios, operating rooms")
    }

    @Test func boundary_2000() {
        let r = LuxInterpreter.interpret(lux: 2000)
        #expect(r.description == "Bright window (indoors), broadcast studios, operating rooms")
    }

    @Test func boundary_2001() {
        let r = LuxInterpreter.interpret(lux: 2001)
        #expect(r.description == "Cloudy day outdoors, sunset outdoors")
    }

    @Test func boundary_10000() {
        let r = LuxInterpreter.interpret(lux: 10000)
        #expect(r.description == "Cloudy day outdoors, sunset outdoors")
    }

    @Test func boundary_10001() {
        let r = LuxInterpreter.interpret(lux: 10001)
        #expect(r.description == "Direct sunlight on a clear day, noon outdoors")
    }

    // MARK: - Negative value fallback

    @Test func negativeValue_returnsDarkRange() {
        let r = LuxInterpreter.interpret(lux: -50)
        #expect(r.description == "Very dark outdoors, full moon night")
        #expect(r.tip == "Pre-sleep conditions. Be careful when moving around.")
    }
}
