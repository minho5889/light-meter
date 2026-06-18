import Foundation

/// Supported application languages.
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case english = "en"
    case korean = "ko"
    case french = "fr"
    
    /// Detects the system language or falls back to English.
    public static var systemLanguage: AppLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return AppLanguage(rawValue: code) ?? .english
    }

    /// Pick the right string for this language — consolidates the inline
    /// en/ko/fr switches used across the redesign for short, dynamic labels.
    public func tr(_ en: String, _ ko: String, _ fr: String) -> String {
        switch self {
        case .korean:  return ko
        case .french:  return fr
        case .english: return en
        }
    }
}
