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
}
