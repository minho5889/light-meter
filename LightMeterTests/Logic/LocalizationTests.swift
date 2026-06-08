import Testing
@testable import LightMeter

struct LocalizationTests {

    @Test func translations_english() {
        #expect(LocalizedStrings.translate(key: "tab_brightness", language: .english) == "Brightness")
        #expect(LocalizedStrings.translate(key: "tab_temperature", language: .english) == "Temperature")
        #expect(LocalizedStrings.translate(key: "ui_user_guide", language: .english) == "User Guide")
        #expect(LocalizedStrings.translate(key: "ui_no_records", language: .english) == "No records yet")
        #expect(LocalizedStrings.translate(key: "ui_tint", language: .english) == "Color Tint")
    }

    @Test func translations_korean() {
        #expect(LocalizedStrings.translate(key: "tab_brightness", language: .korean) == "밝기")
        #expect(LocalizedStrings.translate(key: "tab_temperature", language: .korean) == "색온도")
        #expect(LocalizedStrings.translate(key: "ui_user_guide", language: .korean) == "사용자 가이드")
        #expect(LocalizedStrings.translate(key: "ui_no_records", language: .korean) == "저장된 기록이 없습니다")
        #expect(LocalizedStrings.translate(key: "ui_tint", language: .korean) == "색조 (Tint)")
    }

    @Test func translations_french() {
        #expect(LocalizedStrings.translate(key: "tab_brightness", language: .french) == "Luminosité")
        #expect(LocalizedStrings.translate(key: "tab_temperature", language: .french) == "Température")
        #expect(LocalizedStrings.translate(key: "ui_user_guide", language: .french) == "Guide de l'utilisateur")
        #expect(LocalizedStrings.translate(key: "ui_no_records", language: .french) == "Aucun historique")
        #expect(LocalizedStrings.translate(key: "ui_tint", language: .french) == "Teinte")
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
}
