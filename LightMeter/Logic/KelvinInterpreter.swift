import Foundation

/// Pure logic interpreter to map a Kelvin value to its color tone label and recommended environment tips.
public struct KelvinInterpreter {
    
    /// Maps a Kelvin value to its localized color tone and environmental guidelines.
    /// Values below 1000 fall back to the "Below 2,000K" range.
    public static func interpret(kelvin: Double, language: AppLanguage) -> InterpretationResult {
        if kelvin >= 10000 {
            switch language {
            case .english:
                return InterpretationResult(description: "Blue Sky 🧊", tip: "Shade on a clear day, specialized laboratory environments")
            case .korean:
                return InterpretationResult(description: "푸른 하늘색 🧊", tip: "맑은 날의 그늘, 특수한 실험실 환경")
            case .french:
                return InterpretationResult(description: "Ciel Bleu 🧊", tip: "Ombre par temps clair, environnements de laboratoire spécialisés")
            }
        } else if kelvin >= 6500 {
            switch language {
            case .english:
                return InterpretationResult(description: "Cool White ❄", tip: "Hospitals, factories, warehouses")
            case .korean:
                return InterpretationResult(description: "차가운 백색 ❄", tip: "병원, 공장, 보관 창고")
            case .french:
                return InterpretationResult(description: "Blanc Froid ❄", tip: "Hôpitaux, usines, entrepôts")
            }
        } else if kelvin >= 5000 {
            switch language {
            case .english:
                return InterpretationResult(description: "Daylight 📖", tip: "Study rooms, offices, precision work (improves focus)")
            case .korean:
                return InterpretationResult(description: "주광색 (낮빛) 📖", tip: "공부방, 사무실, 정밀 작업 (집중도 향상에 도움)")
            case .french:
                return InterpretationResult(description: "Lumière du Jour 📖", tip: "Salles d'étude, bureaux, travaux de précision (améliore le focus)")
            }
        } else if kelvin >= 3500 {
            switch language {
            case .english:
                return InterpretationResult(description: "Natural White 🌤", tip: "Kitchens, dressing rooms, bathrooms")
            case .korean:
                return InterpretationResult(description: "온백색 (자연 백색) 🌤", tip: "주방, 화장대 앞, 화장실 및 다용도실")
            case .french:
                return InterpretationResult(description: "Blanc Naturel 🌤", tip: "Cuisines, vestiaires, salles de bain")
            }
        } else if kelvin >= 2000 {
            switch language {
            case .english:
                return InterpretationResult(description: "Warm White 💡", tip: "Bedrooms, living rooms, relaxation spaces")
            case .korean:
                return InterpretationResult(description: "전구색 (따뜻한 백색) 💡", tip: "침실, 거실, 안락한 휴식 공간")
            case .french:
                return InterpretationResult(description: "Blanc Chaud 💡", tip: "Chambres, salons, espaces de détente")
            }
        } else {
            switch language {
            case .english:
                return InterpretationResult(description: "Candlelight / Sunset 🔥", tip: "Psychological calm, pre-sleep, atmospheric cafes")
            case .korean:
                return InterpretationResult(description: "촛불/노을색 🔥", tip: "심리적 안정, 수면 직전, 분위기 있는 카페")
            case .french:
                return InterpretationResult(description: "Bougie / Coucher de Soleil 🔥", tip: "Calme psychologique, pré-sommeil, cafés chaleureux")
            }
        }
    }
}
