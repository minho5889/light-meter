import Testing
@testable import LightMeter

struct FlickerInterpreterTests {

    @Test func safetyLevels_english() {
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Safe", language: .english) == "Very Safe")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Safe", language: .english) == "Safe")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Caution", language: .english) == "Caution")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Dangerous", language: .english) == "Dangerous")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Dangerous", language: .english) == "Very Dangerous")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Unknown", language: .english) == "Unknown")
    }

    @Test func safetyLevels_korean() {
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Safe", language: .korean) == "매우 안전")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Safe", language: .korean) == "안전")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Caution", language: .korean) == "주의")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Dangerous", language: .korean) == "위험")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Dangerous", language: .korean) == "매우 위험")
    }

    @Test func safetyLevels_french() {
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Safe", language: .french) == "Très Sûr")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Safe", language: .french) == "Sûr")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Caution", language: .french) == "Attention")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Dangerous", language: .french) == "Dangereux")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Dangerous", language: .french) == "Très Dangereux")
    }
}
