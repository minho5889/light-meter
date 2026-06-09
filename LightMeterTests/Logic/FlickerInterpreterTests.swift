import Testing
@testable import LightMeter

struct FlickerInterpreterTests {

    @Test func safetyLevels_english() {
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Safe", language: .english) == "No Flicker Detected")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Safe", language: .english) == "Minimal Flicker")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Caution", language: .english) == "Moderate Flicker")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Dangerous", language: .english) == "High Flicker")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Dangerous", language: .english) == "Extreme Flicker")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Unknown", language: .english) == "Unknown")
    }

    @Test func safetyLevels_korean() {
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Safe", language: .korean) == "플리커 감지되지 않음")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Safe", language: .korean) == "미세한 플리커")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Caution", language: .korean) == "보통 플리커")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Dangerous", language: .korean) == "높은 플리커")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Dangerous", language: .korean) == "심한 플리커")
    }

    @Test func safetyLevels_french() {
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Safe", language: .french) == "Aucun Scintillement Détecté")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Safe", language: .french) == "Scintillement Faible")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Caution", language: .french) == "Scintillement Modéré")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Dangerous", language: .french) == "Scintillement Élevé")
        #expect(FlickerInterpreter.safetyLevelTitle(level: "Very Dangerous", language: .french) == "Scintillement Extrême")
    }

    @Test func descriptionNyquistAndDisclaimer() {
        let levels = ["Very Safe", "Safe", "Caution", "Dangerous", "Very Dangerous"]
        let languages: [AppLanguage] = [.english, .korean, .french]
        let nyquist = 120.0

        for level in levels {
            for lang in languages {
                let desc = FlickerInterpreter.description(level: level, nyquist: nyquist, language: lang)
                
                // Assert it contains the Nyquist ceiling number when applicable
                if level == "Very Safe" || level == "Safe" {
                    #expect(desc.contains("120"), "Description for \(level) in \(lang) must contain Nyquist frequency '120'")
                }
                
                // Assert it contains the informational disclaimer
                switch lang {
                case .english:
                    #expect(desc.contains("medical advice"), "English description must contain disclaimer")
                case .korean:
                    #expect(desc.contains("의학적 조언"), "Korean description must contain disclaimer")
                case .french:
                    #expect(desc.contains("avis médical"), "French description must contain disclaimer")
                }
            }
        }
    }

    @Test func safetyDescriptions_containNoBannedMedicalTerms() {
        let levels = ["Very Safe", "Safe", "Caution", "Dangerous", "Very Dangerous"]
        let languages: [AppLanguage] = [.english, .korean, .french]
        
        let bannedTerms = [
            "headache", "dizziness", "strain", "fatigue", "risk",
            "두통", "어지러", "피로", "위험",
            "maux", "tête", "fatigue", "vertige", "risque", "détérioration"
        ]

        for level in levels {
            for lang in languages {
                let desc = FlickerInterpreter.description(level: level, nyquist: 120.0, language: lang).lowercased()
                
                for term in bannedTerms {
                    #expect(!desc.contains(term.lowercased()), "Banned term '\(term)' found in description for \(level) in \(lang): \(desc)")
                }
            }
        }
    }
}
