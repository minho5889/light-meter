import SwiftUI

struct MeasurementCardView: View {
    let lux: Double
    let kelvin: Double
    let isCaptured: Bool
    let language: AppLanguage
    var interpretationDescription: String = ""
    var interpretationTip: String = ""
    var comparisonText: String = ""

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Formats a Double as a locale-aware integer string with thousands separators.
    private static func formatValue(_ value: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private var activeChips: Set<ActivityChip> {
        let index = LuxRange.rangeIndex(for: lux)
        return ActivityChip.activeChips(for: index)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Left-Aligned Readings
            VStack(alignment: .leading, spacing: 4) {
                // Lux layout: 120 LUX (with smaller superscript LUX)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Self.formatValue(lux))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("LUX")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Kelvin layout: 3,800K below it
                Text("\(Self.formatValue(kelvin))K")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 4)

            // Captured Detail Card Sections
            if isCaptured {
                Divider()
                    .background(Color.white.opacity(0.12))

                // Section 1: User Guide (사용자 가이드)
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.translate(key: "ui_user_guide", language: language))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.0)
                    
                    Text(interpretationDescription)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(interpretationTip)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

                // Section 2: Recommended Activities (권장 환경 및 활동)
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStrings.translate(key: "ui_recommended_activities", language: language))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.0)

                    // 2-column Grid displaying all 8 standard ActivityChips
                    let columns = [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ]

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(ActivityChip.allCases, id: \.self) { chip in
                            let isActive = activeChips.contains(chip)
                            
                            Text(chip.localizedName(language: language))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(isActive ? .black : .white.opacity(0.6))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(isActive ? Color.white : Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isActive ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .animation(.easeIn(duration: 0.2), value: isActive)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .foregroundColor(.white)
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var label = "\(Self.formatValue(lux)) lux, \(Self.formatValue(kelvin)) Kelvin"
        if isCaptured {
            label += ", \(interpretationDescription), \(comparisonText)"
        }
        return label
    }
}
