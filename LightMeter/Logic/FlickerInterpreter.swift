import Foundation

/// Pure logic interpreter to map raw flicker safety ratings to localized strings.
public struct FlickerInterpreter: Sendable {
    
    /// Returns the localized title safety rating based on the safety level name.
    public static func safetyLevelTitle(level: String, language: AppLanguage) -> String {
        switch level {
        case "Very Safe":
            switch language {
            case .english: return "No Flicker Detected"
            case .korean: return "플리커 감지되지 않음"
            case .french: return "Aucun Scintillement Détecté"
            }
        case "Safe":
            switch language {
            case .english: return "Minimal Flicker"
            case .korean: return "미세한 플리커"
            case .french: return "Scintillement Faible"
            }
        case "Caution":
            switch language {
            case .english: return "Moderate Flicker"
            case .korean: return "보통 플리커"
            case .french: return "Scintillement Modéré"
            }
        case "Dangerous":
            switch language {
            case .english: return "High Flicker"
            case .korean: return "높은 플리커"
            case .french: return "Scintillement Élevé"
            }
        case "Very Dangerous":
            switch language {
            case .english: return "Extreme Flicker"
            case .korean: return "심한 플리커"
            case .french: return "Scintillement Extrême"
            }
        default:
            return level
        }
    }

    /// Returns the localized, informational description for the safety level.
    /// Ensures no medical claims are made and dynamically embeds the Nyquist ceiling limit.
    public static func description(level: String, nyquist: Double, language: AppLanguage) -> String {
        let hz = Int(nyquist)
        switch level {
        case "Very Safe":
            switch language {
            case .english:
                return "No flicker detected up to \(hz) Hz. Note: high-frequency PWM/LED flicker above \(hz) Hz cannot be measured by frame-rate sampling. Informational only, not medical advice."
            case .korean:
                return "최대 \(hz) Hz까지 플리커가 감지되지 않았습니다. 참고: \(hz) Hz를 초과하는 고주파 PWM/LED 플리커는 프레임 레이트 샘플링 방식으로 측정할 수 없습니다. 정보 제공용이며 의학적 조언이 아닙니다."
            case .french:
                return "Aucun scintillement détecté jusqu'à \(hz) Hz. Note: le scintillement PWM/LED haute fréquence supérieur à \(hz) Hz ne peut pas être mesuré par échantillonnage. À titre informatif, pas un avis médical."
            }
        case "Safe":
            switch language {
            case .english:
                return "Minimal relative flicker detected. Normal for high-quality lighting. High-frequency flicker above \(hz) Hz is unmeasurable. Informational only, not medical advice."
            case .korean:
                return "미세한 상대적 플리커가 감지되었습니다. 고품질 조명에서 정상적인 수준입니다. \(hz) Hz 초과 고주파 플리커는 측정이 불가합니다. 정보 제공용이며 의학적 조언이 아닙니다."
            case .french:
                return "Scintillement minimal détecté. Normal pour un éclairage de qualité. Le scintillement au-dessus de \(hz) Hz est incommensurable. À titre informatif, pas un avis médical."
            }
        case "Caution":
            switch language {
            case .english:
                return "Moderate relative flicker intensity. Common in some LED lights or dimmed bulbs. Informational only, not medical advice."
            case .korean:
                return "보통 수준의 상대적 플리커 강도입니다. 일부 LED 또는 디밍 전구에서 흔히 나타납니다. 정보 제공용이며 의학적 조언이 아닙니다."
            case .french:
                return "Intensité de scintillement modérée. Courant sur certaines LED ou ampoules à intensité variable. À titre informatif, pas un avis médical."
            }
        case "Dangerous":
            switch language {
            case .english:
                return "High relative flicker intensity. Common in low-quality LED/fluorescent lights. Informational only, not medical advice."
            case .korean:
                return "높은 수준의 상대적 플리커 강도입니다. 저품질 LED 또는 형광등에서 흔히 나타납니다. 정보 제공용이며 의학적 조언이 아닙니다."
            case .french:
                return "Intensité de scintillement élevée. Courant pour des éclairages LED/fluorescents de basse qualité. À titre informatif, pas un avis médical."
            }
        case "Very Dangerous":
            switch language {
            case .english:
                return "Extreme relative flicker intensity. Visible pulsation or unstable power source detected. Informational only, not medical advice."
            case .korean:
                return "극도로 높은 수준의 상대적 플리커 강도입니다. 눈에 보이는 맥동이나 불안정한 전원이 감지되었습니다. 정보 제공용이며 의학적 조언이 아닙니다."
            case .french:
                return "Intensité de scintillement extrême. Pulsation visible ou source d'alimentation instable détectée. À titre informatif, pas un avis médical."
            }
        default:
            return level
        }
    }
}
