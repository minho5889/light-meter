import Foundation

/// Pure logic interpreter to map raw flicker safety ratings to localized strings.
public struct FlickerInterpreter {
    
    /// Returns the localized title safety rating based on the safety level name.
    public static func safetyLevelTitle(level: String, language: AppLanguage) -> String {
        switch level {
        case "Very Safe":
            switch language {
            case .english: return "Very Safe"
            case .korean: return "매우 안전"
            case .french: return "Très Sûr"
            }
        case "Safe":
            switch language {
            case .english: return "Safe"
            case .korean: return "안전"
            case .french: return "Sûr"
            }
        case "Caution":
            switch language {
            case .english: return "Caution"
            case .korean: return "주의"
            case .french: return "Attention"
            }
        case "Dangerous":
            switch language {
            case .english: return "Dangerous"
            case .korean: return "위험"
            case .french: return "Dangereux"
            }
        case "Very Dangerous":
            switch language {
            case .english: return "Very Dangerous"
            case .korean: return "매우 위험"
            case .french: return "Très Dangereux"
            }
        default:
            return level
        }
    }
}
