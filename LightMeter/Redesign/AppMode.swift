//
//  AppMode.swift
//  LightMeter
//
//  The app's top-level experience mode. Lets a light/casual user stay in a
//  simplified "Regular" UI (the Figma redesign) while power users can opt into
//  "Advanced" — the full original app (calibration, EV / f-stops / fc, flicker
//  analysis, etc.). Switching modes is additive: neither experience is removed.
//

import Foundation

/// Which experience the app presents at the root.
enum AppMode: String, CaseIterable, Identifiable {
    /// Simplified, one-glance metering for light users. The default.
    case regular
    /// The full-featured original app.
    case advanced

    var id: String { rawValue }

    /// Localized short title for pickers/toggles.
    func title(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.regular, .korean):  return "일반 모드"
        case (.advanced, .korean): return "고급 모드"
        case (.regular, .french):  return "Mode simple"
        case (.advanced, .french): return "Mode avancé"
        case (.regular, _):        return "Regular"
        case (.advanced, _):       return "Advanced"
        }
    }

    /// Localized one-line description of what the mode offers.
    func subtitle(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.regular, .korean):  return "간편한 빛 측정"
        case (.advanced, .korean): return "보정 · EV · 플리커 등 전체 기능"
        case (.regular, .french):  return "Mesure simple en un coup d'œil"
        case (.advanced, .french): return "Calibration, EV, flicker…"
        case (.regular, _):        return "Simple, one-glance metering"
        case (.advanced, _):       return "Calibration, EV, flicker & more"
        }
    }
}

/// Shared `@AppStorage` key for the selected app mode.
enum AppModeStorage {
    static let key = "appMode"
}
