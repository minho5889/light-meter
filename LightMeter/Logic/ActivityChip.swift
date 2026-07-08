import Foundation

/// The 8 standard environment activity chips defined in the Figma design.
public enum ActivityChip: String, CaseIterable, Codable, Sendable {
    case readingAndStudy
    case officeAndFocus
    case tvAndMovies
    case diningAndSocial
    case sleepAndComfort
    case babyAndParenting
    case datingAndRomance
    case coffeeAndTeaTime

    /// Gets the localized string name of the activity.
    public func localizedName(language: AppLanguage) -> String {
        switch self {
        case .readingAndStudy:
            switch language {
            case .english: return "Reading & Study"
            case .korean: return "독서 및 학습"
            case .french: return "Lecture et Études"
            }
        case .officeAndFocus:
            switch language {
            case .english: return "Office & Focus"
            case .korean: return "사무 및 집중"
            case .french: return "Travail et Focus"
            }
        case .tvAndMovies:
            switch language {
            case .english: return "TV & Movies"
            case .korean: return "TV 및 영화"
            case .french: return "TV et Cinéma"
            }
        case .diningAndSocial:
            switch language {
            case .english: return "Dining & Social"
            case .korean: return "식사 및 대화"
            case .french: return "Repas et Social"
            }
        case .sleepAndComfort:
            switch language {
            case .english: return "Sleep & Comfort"
            case .korean: return "수면 및 안정"
            case .french: return "Sommeil et Détente"
            }
        case .babyAndParenting:
            switch language {
            case .english: return "Baby & Parenting"
            case .korean: return "아기 및 육아"
            case .french: return "Bébé et Puériculture"
            }
        case .datingAndRomance:
            switch language {
            case .english: return "Dating & Romance"
            case .korean: return "데이트 및 로맨틱"
            case .french: return "Rendez-vous et Romantique"
            }
        case .coffeeAndTeaTime:
            switch language {
            case .english: return "Coffee & Tea Time"
            case .korean: return "커피 및 티타임"
            case .french: return "Heure du thé, Café"
            }
        }
    }

    /// Maps each Lux range index (0-7) to a set of matching active environment chips.
    public static func activeChips(for luxRangeIndex: Int) -> Set<ActivityChip> {
        switch luxRangeIndex {
        case 0:
            return [.sleepAndComfort, .babyAndParenting]
        case 1:
            return [.sleepAndComfort, .babyAndParenting]
        case 2:
            return [.tvAndMovies, .diningAndSocial]
        case 3:
            return [.coffeeAndTeaTime, .datingAndRomance]
        case 4:
            return [.readingAndStudy, .officeAndFocus]
        case 5:
            return [.officeAndFocus]
        case 6:
            return [.coffeeAndTeaTime]
        case 7:
            return []
        default:
            return []
        }
    }

    /// The lux-range indices (0–7) where this activity is a good match —
    /// the inverse of `activeChips(for:)`, derived from it so the two can
    /// never drift apart.
    public var suitableLuxIndices: [Int] {
        (0...7).filter { Self.activeChips(for: $0).contains(self) }
    }

    /// Recommended correlated color temperature (Kelvin) for the activity.
    /// Ranges follow common interior-lighting guidance (EN 12464-1 /
    /// residential CCT recommendations): warm (<3000K) for rest and intimate
    /// settings, neutral for care tasks and screens, cool (4000K+) for
    /// focus/task work.
    public var suitableKelvin: ClosedRange<Double> {
        switch self {
        case .readingAndStudy:  return 4000...6500
        case .officeAndFocus:   return 4000...6500
        case .tvAndMovies:      return 2700...4500
        case .diningAndSocial:  return 2200...3500
        case .sleepAndComfort:  return 1800...3000
        case .babyAndParenting: return 2700...4000
        case .datingAndRomance: return 1800...3000
        case .coffeeAndTeaTime: return 2200...3800
        }
    }
}
