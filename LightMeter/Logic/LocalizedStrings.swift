import Foundation

/// Central pure-logic localization manager providing static UI translations.
public struct LocalizedStrings {
    
    private static let translations: [String: [AppLanguage: String]] = [
        // Tab Titles
        "tab_brightness": [.english: "Brightness", .korean: "밝기", .french: "Luminosité"],
        "tab_temperature": [.english: "Temperature", .korean: "색온도", .french: "Température"],
        "tab_check": [.english: "Check", .korean: "플리커", .french: "Sécurité"],
        "tab_records": [.english: "Records", .korean: "기록", .french: "Historique"],
        // Regular-mode tab labels per Figma (distinct from the Advanced-mode
        // "Temperature"/"Check" above, which ContentView still uses).
        "tab_color_temp": [.english: "Color Temp", .korean: "색온도", .french: "Temp. couleur"],
        "tab_analysis": [.english: "Analysis", .korean: "분석", .french: "Analyse"],
        
        // Static UI Titles & Details
        "ui_user_guide": [.english: "User Guide", .korean: "사용자 가이드", .french: "Guide de l'utilisateur"],
        // Regular-mode brightness card guide label (Figma "Actionable Tip" /
        // "사용자 가이드"); distinct from the Advanced-mode "User Guide" above.
        "ui_actionable_tip": [.english: "Actionable Tip", .korean: "사용자 가이드", .french: "Conseil pratique"],
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
        "ui_records_empty_desc": [.english: "Your captured light readings will automatically appear here.", .korean: "캡처한 밝기 측정 결과가 여기에 자동으로 저장됩니다.", .french: "Vos mesures capturées s'afficheront automatiquement ici."],
        
        // Reflected Light Disclosure
        "ui_reflected_disclosure_title": [.english: "Reflected Light Estimate", .korean: "반사광 측정 정보", .french: "Estimation de la Lumière Réfléchie"],
        "ui_reflected_disclosure_desc": [.english: "This camera measures reflected light from surfaces, which is an estimate. It is not an incident lux measurement.", .korean: "이 카메라는 표면에서 반사된 빛(반사광)을 측정하여 추정치를 제공합니다. 광원에서 직접 닿는 입사광 측정 방식이 아닙니다.", .french: "Cet appareil mesure la lumière réfléchie par les surfaces, ce qui est une estimation, et non une mesure de lux incident."],
        
        // Calibration UI
        "ui_calibrate_title": [.english: "Lux Calibration", .korean: "조도 보정 (캘리브레이션)", .french: "Étalonnage du Lux"],
        "ui_calibrate_current": [.english: "Current Reading", .korean: "현재 측정값", .french: "Lecture Actuelle"],
        "ui_calibrate_known_placeholder": [.english: "e.g. 500", .korean: "예: 500", .french: "ex. 500"],
        "ui_calibrate_enter_known": [.english: "Enter Known Reference Lux Value", .korean: "기준이 될 실제 조도 값 입력", .french: "Saisir la Valeur de Lux de Référence"],
        "ui_calibrate_new_factor": [.english: "New Calibration Factor", .korean: "새로운 보정 배율", .french: "Nouveau Facteur d'Étalonnage"],
        "ui_calibrate_multiplier_fmt": [.english: "%.2fx multiplier", .korean: "%.2f배 배율", .french: "Multiplicateur de %.2fx"],
        "ui_calibrate_apply": [.english: "Apply Calibration", .korean: "보정값 적용", .french: "Appliquer l'Étalonnage"],
        "ui_calibrate_reset": [.english: "Reset to Default (1.0x)", .korean: "기본값(1.0배)으로 초기화", .french: "Réinitialiser par Défaut (1.0x)"],
        "ui_calibrate_cancel": [.english: "Cancel", .korean: "취소", .french: "Annuler"],
        "ui_calibrate_button": [.english: "Calibrate", .korean: "보정하기", .french: "Étalonner"],
        "ui_fc_short": [.english: "fc", .korean: "풋캔들", .french: "fc"],
        "ui_ev_short": [.english: "EV", .korean: "EV", .french: "EV"],
        "ui_equivalent_exposure": [.english: "Equivalent Exposure (ISO 100)", .korean: "동등 노출 설정 (ISO 100)", .french: "Expositions Équivalentes (ISO 100)"],
        "ui_shutter_speed": [.english: "Shutter", .korean: "셔터 속도", .french: "Obturateur"],
        "ui_aperture": [.english: "Aperture", .korean: "조리개", .french: "Ouverture"],
        
        // Accessibility announcements
        "accessibility_capture": [.english: "Capture", .korean: "측정", .french: "Capturer"],
        "accessibility_switch_camera": [.english: "Switch camera", .korean: "카메라 전환", .french: "Changer de caméra"],
        "accessibility_back_live": [.english: "Back to live mode", .korean: "실시간 모드로 돌아가기", .french: "Retour au mode direct"],
        "accessibility_captured_lux": [.english: "Captured %d lux, %d Kelvin", .korean: "캡처됨: %d 룩스, %d 켈빈", .french: "Capturé : %d lux, %d Kelvin"],
        "accessibility_captured_fc": [.english: "Captured %.1f foot-candles, %d Kelvin", .korean: "캡처됨: %.1f 풋캔들, %d 켈빈", .french: "Capturé : %.1f foot-candles, %d Kelvin"],
        "accessibility_captured_ev": [.english: "Captured EV %.1f, %d Kelvin", .korean: "캡처됨: EV %.1f, %d 켈빈", .french: "Capturé : EV %.1f, %d Kelvin"],
        "accessibility_delete_record": [.english: "Delete record %d", .korean: "%d번 기록 삭제", .french: "Supprimer l'enregistrement %d"],
        "accessibility_share_record": [.english: "Share record %d", .korean: "%d번 기록 공유", .french: "Partager l'enregistrement %d"],
        
        // Flicker Accessibility
        "accessibility_flicker_gauge_label": [.english: "Flicker Safety Gauge", .korean: "플리커 안전 계기판", .french: "Jauge de Sécurité Flicker"],
        "accessibility_flicker_percent": [.english: "%.1f percent", .korean: "%.1f 퍼센트", .french: "%.1f pour cent"],
        "accessibility_flicker_frequency": [.english: "%.0f hertz", .korean: "%.0f 헤르츠", .french: "%.0f hertz"],
        "accessibility_flicker_freq_unknown": [.english: "frequency unknown", .korean: "주파수 알 수 없음", .french: "fréquence inconnue"],
        "accessibility_flicker_inactive": [.english: "0 percent, inactive", .korean: "0 퍼센트, 비활성화됨", .french: "0 pour cent, inactif"]
    ]

    /// Translates a given key into the selected language.
    public static func translate(key: String, language: AppLanguage) -> String {
        return translations[key]?[language] ?? key
    }
}
