import Testing
@testable import LightMeter

struct LocalizationTests {

    @Test func translations_english() {
        #expect(LocalizedStrings.translate(key: "tab_brightness", language: .english) == "Brightness")
        #expect(LocalizedStrings.translate(key: "tab_temperature", language: .english) == "Temperature")
        #expect(LocalizedStrings.translate(key: "ui_user_guide", language: .english) == "User Guide")
        #expect(LocalizedStrings.translate(key: "ui_no_records", language: .english) == "No records yet")
        #expect(LocalizedStrings.translate(key: "ui_tint", language: .english) == "Color Tint")
        #expect(LocalizedStrings.translate(key: "ui_reflected_disclosure_title", language: .english) == "Reflected Light Estimate")
        #expect(LocalizedStrings.translate(key: "ui_calibrate_button", language: .english) == "Calibrate")
    }

    @Test func translations_korean() {
        #expect(LocalizedStrings.translate(key: "tab_brightness", language: .korean) == "밝기")
        #expect(LocalizedStrings.translate(key: "tab_temperature", language: .korean) == "색온도")
        #expect(LocalizedStrings.translate(key: "ui_user_guide", language: .korean) == "사용자 가이드")
        #expect(LocalizedStrings.translate(key: "ui_no_records", language: .korean) == "저장된 기록이 없습니다")
        #expect(LocalizedStrings.translate(key: "ui_tint", language: .korean) == "색조 (Tint)")
        #expect(LocalizedStrings.translate(key: "ui_reflected_disclosure_title", language: .korean) == "반사광 측정 정보")
        #expect(LocalizedStrings.translate(key: "ui_calibrate_button", language: .korean) == "보정하기")
    }

    @Test func translations_french() {
        #expect(LocalizedStrings.translate(key: "tab_brightness", language: .french) == "Luminosité")
        #expect(LocalizedStrings.translate(key: "tab_temperature", language: .french) == "Température")
        #expect(LocalizedStrings.translate(key: "ui_user_guide", language: .french) == "Guide de l'utilisateur")
        #expect(LocalizedStrings.translate(key: "ui_no_records", language: .french) == "Aucun historique")
        #expect(LocalizedStrings.translate(key: "ui_tint", language: .french) == "Teinte")
        #expect(LocalizedStrings.translate(key: "ui_reflected_disclosure_title", language: .french) == "Estimation de la Lumière Réfléchie")
        #expect(LocalizedStrings.translate(key: "ui_calibrate_button", language: .french) == "Étalonner")
    }

    @Test func fallback_returnsKey() {
        #expect(LocalizedStrings.translate(key: "unknown_key_xyz", language: .english) == "unknown_key_xyz")
    }

    @Test func activityChips_names() {
        #expect(ActivityChip.readingAndStudy.localizedName(language: .english) == "Reading & Study")
        #expect(ActivityChip.readingAndStudy.localizedName(language: .korean) == "독서 및 학습")
        #expect(ActivityChip.readingAndStudy.localizedName(language: .french) == "Lecture et Études")

        #expect(ActivityChip.coffeeAndTeaTime.localizedName(language: .english) == "Coffee & Tea Time")
        #expect(ActivityChip.coffeeAndTeaTime.localizedName(language: .korean) == "커피 및 티타임")
        #expect(ActivityChip.coffeeAndTeaTime.localizedName(language: .french) == "Heure du thé, Café")
    }

    @Test func activityChips_mappings() {
        #expect(ActivityChip.activeChips(for: 0) == [.sleepAndComfort, .babyAndParenting])
        #expect(ActivityChip.activeChips(for: 2) == [.tvAndMovies, .diningAndSocial])
        #expect(ActivityChip.activeChips(for: 4) == [.readingAndStudy, .officeAndFocus])
        #expect(ActivityChip.activeChips(for: 7).isEmpty)
        #expect(ActivityChip.activeChips(for: 100).isEmpty)
    }

    @Test func activityChips_suitableLuxIndices_isExactInverseOfActiveChips() {
        // Every chip's suitable indices must round-trip through activeChips(for:).
        for chip in ActivityChip.allCases {
            let indices = chip.suitableLuxIndices
            #expect(!indices.isEmpty, "\(chip) has no suitable lux range")
            for i in 0...7 {
                #expect(indices.contains(i) == ActivityChip.activeChips(for: i).contains(chip))
            }
        }
        // Spot checks against the canonical table.
        #expect(ActivityChip.sleepAndComfort.suitableLuxIndices == [0, 1])
        #expect(ActivityChip.officeAndFocus.suitableLuxIndices == [4, 5])
        #expect(ActivityChip.coffeeAndTeaTime.suitableLuxIndices == [3, 6])
    }

    @Test func activityChips_suitableKelvin_rangesAreSane() {
        for chip in ActivityChip.allCases {
            let range = chip.suitableKelvin
            #expect(range.lowerBound >= 1000 && range.upperBound <= 10000,
                "\(chip) CCT range outside plausible interior lighting bounds")
            #expect(range.lowerBound < range.upperBound)
        }
        // The Figma 04_Check_2 example: 3,800 K suits TV & Movies.
        #expect(ActivityChip.tvAndMovies.suitableKelvin.contains(3800))
    }
}
