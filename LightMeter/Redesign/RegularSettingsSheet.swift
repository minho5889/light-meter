//
//  RegularSettingsSheet.swift
//  LightMeter
//
//  Settings sheet for Regular mode. Its main job is the mode switch: a light
//  user can flip to Advanced mode here, which unlocks calibration, EV / f-stop
//  readouts, flicker analysis and the rest of the original app.
//

import SwiftUI

struct RegularSettingsSheet: View {
    @AppStorage(AppModeStorage.key) private var modeRaw: String = AppMode.regular.rawValue
    @Environment(\.dismiss) private var dismiss

    var language: AppLanguage = .systemLanguage

    private var modeBinding: Binding<AppMode> {
        Binding(
            get: { AppMode(rawValue: modeRaw) ?? .regular },
            set: { modeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: modeBinding) {
                        ForEach(AppMode.allCases) { mode in
                            Text(mode.title(language)).tag(mode)
                        }
                    } label: {
                        Text(localized(en: "Mode", ko: "모드", fr: "Mode"))
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text(localized(en: "Experience", ko: "사용 모드", fr: "Expérience"))
                } footer: {
                    Text(modeBinding.wrappedValue.subtitle(language))
                }
            }
            .navigationTitle(localized(en: "Settings", ko: "설정", fr: "Réglages"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localized(en: "Done", ko: "완료", fr: "OK")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func localized(en: String, ko: String, fr: String) -> String {
        switch language {
        case .korean: return ko
        case .french: return fr
        case .english: return en
        }
    }
}

#Preview {
    RegularSettingsSheet()
}
