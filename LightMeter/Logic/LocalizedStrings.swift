import Foundation

/// Central pure-logic localization manager providing static UI translations.
public struct LocalizedStrings {
    
    private static let translations: [String: [AppLanguage: String]] = [
        // Tab Titles
        "tab_brightness": [.english: "Brightness", .korean: "밝기", .french: "Luminosité"],
        "tab_temperature": [.english: "Temperature", .korean: "색온도", .french: "Température"],
        "tab_check": [.english: "Check", .korean: "플리커", .french: "Sécurité"],
        "tab_records": [.english: "Records", .korean: "기록", .french: "Historique"],
        
        // Static UI Titles & Details
        "ui_user_guide": [.english: "User Guide", .korean: "사용자 가이드", .french: "Guide de l'utilisateur"],
        "ui_recommended_activities": [.english: "Recommended Activities", .korean: "권장 환경 및 활동", .french: "Activités Recommandées"],
        "ui_color_tone": [.english: "Color Tone", .korean: "색감", .french: "Teinte de Couleur"],
        "ui_tint": [.english: "Color Tint", .korean: "색조 (Tint)", .french: "Teinte"],
        "ui_flicker": [.english: "Flicker", .korean: "플리커", .french: "Flicker"],
        "ui_back": [.english: "Back", .korean: "Back", .french: "Retour"],
        "ui_close": [.english: "Close", .korean: "닫기", .french: "Fermer"],
        
        // Flicker View labels
        "ui_light_check": [.english: "LIGHT CHECK", .korean: "LIGHT CHECK", .french: "CONTRÔLE LUMINEUX"],
        "ui_analyzing": [.english: "ANALYZING", .korean: "분석중", .french: "ANALYSE EN COURS"],
        "ui_wave_scope": [.english: "WAVE SCOPE", .korean: "WAVE SCOPE", .french: "CANAL D'ONDE"],
        "ui_start_check": [.english: "Start Safety Check", .korean: "시작하기", .french: "Lancer le contrôle"],
        "ui_stop_check": [.english: "Stop Check", .korean: "중지하기", .french: "Arrêter le contrôle"],
        "ui_flicker_ready_desc": [.english: "Point your phone at a light source and tap the button below to start the health and safety checks.", .korean: "핸드폰을 광원 방향으로 향하게 하고 시작 버튼을 누르면 빛 안전성 검사가 시작됩니다.", .french: "Pointez votre téléphone vers une source de lumière et appuyez sur le bouton ci-dessous pour lancer les contrôles de sécurité."],
        "ui_flicker_calibrating": [.english: "Calibrating sensor...", .korean: "센서 보정 중...", .french: "Étalonnage du capteur..."],
        "ui_no_light": [.english: "No light detected.", .korean: "빛이 감지되지 않았습니다.", .french: "Aucune lumière détectée."],
        
        // Records Empty State
        "ui_no_records": [.english: "No records yet", .korean: "저장된 기록이 없습니다", .french: "Aucun historique"],
        "ui_records_empty_desc": [.english: "Your captured light readings will automatically appear here.", .korean: "캡처한 밝기 측정 결과가 여기에 자동으로 저장됩니다.", .french: "Vos mesures capturées s'afficheront automatiquement ici."]
    ]

    /// Translates a given key into the selected language.
    public static func translate(key: String, language: AppLanguage) -> String {
        return translations[key]?[language] ?? key
    }
}
