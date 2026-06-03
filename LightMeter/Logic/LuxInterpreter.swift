import Foundation

/// Pure logic interpreter to map a calculated lux value to localized environment descriptions and tips.
public struct LuxInterpreter {
    
    // Raw database entries for English
    private static let enResults: [InterpretationResult] = [
        InterpretationResult(description: "Very dark outdoors, full moon night", tip: "Pre-sleep conditions. Be careful when moving around."),
        InterpretationResult(description: "Hallways, bathrooms, movie theaters", tip: "Suitable for passing through. Not appropriate for extended work."),
        InterpretationResult(description: "Living room relaxation, dining, hotel rooms", tip: "Optimal for comfortable rest. Good for watching TV."),
        InterpretationResult(description: "General office work, kitchen cooking, light reading", tip: "The most standard brightness for daily activities and office work."),
        InterpretationResult(description: "Focused studying, precision handwork, store displays", tip: "Recommended for study rooms or detailed tasks like sewing."),
        InterpretationResult(description: "Bright window (indoors), broadcast studios, operating rooms", tip: "Very bright. Suitable for video production or professional work."),
        InterpretationResult(description: "Cloudy day outdoors, sunset outdoors", tip: "Good for outdoor activities. Partial shade level for plants."),
        InterpretationResult(description: "Direct sunlight on a clear day, noon outdoors", tip: "Strong sunlight. Protect your eyes and watch for plant burns.")
    ]

    // Raw database entries for Korean
    private static let koResults: [InterpretationResult] = [
        InterpretationResult(description: "매우 어두운 실외, 보름달 밤", tip: "수면 직전 환경입니다. 이동 시 발밑을 조심하세요."),
        InterpretationResult(description: "복도, 화장실, 창고, 영화 상영관", tip: "통행 및 일시 체류에 적당하며, 장시간 작업에는 부적합합니다."),
        InterpretationResult(description: "거실 휴식, 식사, 호텔 객실", tip: "편안한 휴식에 최적입니다. TV 시청 시 적당해요."),
        InterpretationResult(description: "일반 사무 업무, 부엌 조리, 가벼운 독서", tip: "일상 생활 및 사무 업무를 하기에 가장 표준적인 밝기입니다."),
        InterpretationResult(description: "집중적인 독서 및 공부, 세밀한 수작업, 매장 진열", tip: "공부방이나 바느질 등 정밀한 작업을 할 때 권장되는 밝기입니다."),
        InterpretationResult(description: "창가(실내), 방송 스튜디오, 수술실", tip: "매우 밝은 환경입니다. 촬영용 조명이나 정밀 전문 작업에 적당합니다."),
        InterpretationResult(description: "흐린 날의 실외, 일몰 직전의 야외", tip: "야외 활동을 하기에 적합한 밝기이며, 식물에게는 반그늘 수준입니다."),
        InterpretationResult(description: "맑은 날 직사광선, 정오의 야외", tip: "강한 햇빛입니다. 눈을 보호하고 식물 화상을 주의하세요.")
    ]

    // Raw database entries for French
    private static let frResults: [InterpretationResult] = [
        InterpretationResult(description: "Nuit noire à l'extérieur, pleine lune", tip: "Conditions de pré-sommeil. Attention en vous déplaçant."),
        InterpretationResult(description: "Couloirs, toilettes, salles de cinéma", tip: "Adapté pour le passage. Non recommandé pour un travail prolongé."),
        InterpretationResult(description: "Salon et repas, détente, chambres d'hôtel", tip: "Optimal pour se détendre. Bon pour regarder la télévision."),
        InterpretationResult(description: "Travail de bureau général, cuisine, lecture légère", tip: "La luminosité la plus standard pour le quotidien et le bureau."),
        InterpretationResult(description: "Études intenses, travaux de précision, vitrines", tip: "Recommandé pour les études ou tâches minutieuses comme la couture."),
        InterpretationResult(description: "Près d'une fenêtre ensoleillée, studios, blocs opératoires", tip: "Très lumineux. Adapté pour la production vidéo ou travail pro."),
        InterpretationResult(description: "Extérieur par temps nuageux, coucher de soleil", tip: "Idéal pour les activités extérieures. Niveau mi-ombre pour plantes."),
        InterpretationResult(description: "Soleil direct par temps clair, midi en extérieur", tip: "Soleil intense. Protégez vos yeux et attention aux brûlures de plantes.")
    ]

    /// Maps a lux value to its environment description and user guide tip in the designated language.
    /// Negative values fall back to the 0–10 range.
    public static func interpret(lux: Double, language: AppLanguage) -> InterpretationResult {
        let index = LuxRange.rangeIndex(for: lux)
        switch language {
        case .english:
            return enResults[index]
        case .korean:
            return koResults[index]
        case .french:
            return frResults[index]
        }
    }
}
