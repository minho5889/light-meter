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
    @AppStorage("lm_coach_endpoint") private var coachEndpoint: String = ""
    @Environment(\.dismiss) private var dismiss

    var language: AppLanguage = .systemLanguage
    var onReplayTutorial: () -> Void = {}

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

                Section {
                    Button {
                        onReplayTutorial()
                    } label: {
                        Label(
                            localized(en: "Show the walkthrough", ko: "사용법 둘러보기", fr: "Revoir le guide"),
                            systemImage: "sparkles"
                        )
                        .foregroundStyle(LM.accent)
                    }
                }

                Section {
                    TextField("https://…", text: $coachEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text(localized(en: "AI Coach endpoint", ko: "AI 코치 엔드포인트", fr: "Point de terminaison IA"))
                } footer: {
                    Text(localized(
                        en: "Paste your Bedrock/Claude proxy URL to use the live model. Leave empty for the built-in offline coach.",
                        ko: "Bedrock/Claude 프록시 URL을 붙여넣으면 실제 모델을 사용해요. 비워두면 내장 오프라인 코치가 동작합니다.",
                        fr: "Colle l'URL de ton proxy Bedrock/Claude pour le modèle en direct. Vide = coach hors-ligne intégré."))
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
        .presentationDetents([.medium, .large])
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
