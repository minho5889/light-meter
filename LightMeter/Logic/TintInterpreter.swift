import Foundation

/// Pure logic interpreter to map a white balance tint value to a green/neutral/magenta description and tips.
public struct TintInterpreter: Sendable {
    public static let greenThreshold: Double = -10.0
    public static let magentaThreshold: Double = 10.0

    /// Maps a tint value to its localized color tint description and guidelines.
    public static func interpret(tint: Double, language: AppLanguage) -> InterpretationResult {
        if tint > magentaThreshold {
            switch language {
            case .english:
                return InterpretationResult(description: "Magenta Tint 🟣", tip: "Magenta or reddish-cast lighting. Common in some LED lights.")
            case .korean:
                return InterpretationResult(description: "자줏빛 (마젠타) 🟣", tip: "자줏빛이나 붉은 조명입니다. 일부 LED 등에서 자주 보입니다.")
            case .french:
                return InterpretationResult(description: "Teinte Magenta 🟣", tip: "Éclairage magenta ou rougeâtre. Courant sur certaines LED.")
            }
        } else if tint < greenThreshold {
            switch language {
            case .english:
                return InterpretationResult(description: "Green Tint 🟢", tip: "Fluorescent or green-cast lighting. Can look sickly.")
            case .korean:
                return InterpretationResult(description: "초록빛 (그린) 🟢", tip: "형광등이나 녹색조 조명입니다. 피부톤이 아파 보일 수 있습니다.")
            case .french:
                return InterpretationResult(description: "Teinte Verte 🟢", tip: "Éclairage fluorescent ou verdâtre. Peut donner un teint terne.")
            }
        } else {
            switch language {
            case .english:
                return InterpretationResult(description: "Neutral ⚪", tip: "Balanced tint. Excellent color rendering.")
            case .korean:
                return InterpretationResult(description: "보통 (중립) ⚪", tip: "균형 잡힌 색조입니다. 우수한 색 재현력.")
            case .french:
                return InterpretationResult(description: "Neutre ⚪", tip: "Teinte équilibrée. Excellent rendu des couleurs.")
            }
        }
    }
}
