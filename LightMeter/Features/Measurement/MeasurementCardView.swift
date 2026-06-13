import SwiftUI

struct MeasurementCardView: View {
    let lux: Double
    let kelvin: Double
    let isCaptured: Bool
    let language: AppLanguage
    let selectedUnit: MeasurementUnit
    var interpretationDescription: String = ""
    var interpretationTip: String = ""
    var comparisonText: String = ""

    @ScaledMetric(relativeTo: .largeTitle) private var displayValueSize: CGFloat = 40

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
                // Main layout: converted value with superscript label
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(displayValueString)
                        .font(.system(size: displayValueSize, weight: .bold, design: .rounded))
                    Text(unitLabelString)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Kelvin layout + secondary readouts row
                HStack(spacing: 12) {
                    Text("\(Self.formatValue(kelvin))K")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("•")
                        .font(.system(.subheadline))
                        .foregroundColor(.white.opacity(0.3))
                    
                    HStack(spacing: 8) {
                        if selectedUnit != .lux {
                            Text("\(Self.formatValue(lux)) lx")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        if selectedUnit != .footCandle {
                            let fc = ExposureValueCalculator.calculateFootCandles(lux: lux)
                            Text(String(format: "%.1f fc", fc))
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        if selectedUnit != .ev {
                            let ev = ExposureValueCalculator.calculateEV(lux: lux)
                            Text(String(format: "EV %.1f", ev))
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .padding(.horizontal, 4)

            // Captured Detail Card Sections
            if isCaptured {
                Divider()
                    .background(Color.white.opacity(0.12))

                // Section 1: User Guide (사용자 가이드)
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.translate(key: "ui_user_guide", language: language))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.0)
                    
                    Text(interpretationDescription)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    
                    Text(interpretationTip)
                        .font(.system(.footnote, design: .rounded))
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
                        .font(.system(.caption, design: .rounded).weight(.bold))
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
                                .font(.system(.caption, design: .rounded).weight(.medium))
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

    private var displayValueString: String {
        switch selectedUnit {
        case .lux:
            return Self.formatValue(lux)
        case .footCandle:
            let fc = ExposureValueCalculator.calculateFootCandles(lux: lux)
            return String(format: "%.1f", fc)
        case .ev:
            let ev = ExposureValueCalculator.calculateEV(lux: lux)
            return String(format: "%.1f", ev)
        }
    }

    private var unitLabelString: String {
        switch selectedUnit {
        case .lux:
            return "LUX"
        case .footCandle:
            return LocalizedStrings.translate(key: "ui_fc_short", language: language).uppercased()
        case .ev:
            return "EV"
        }
    }

    private var accessibilityDescription: String {
        let mainVal: String
        switch selectedUnit {
        case .lux:
            mainVal = "\(Self.formatValue(lux)) lux"
        case .footCandle:
            let fc = ExposureValueCalculator.calculateFootCandles(lux: lux)
            mainVal = String(format: "%.1f foot-candles", fc)
        case .ev:
            let ev = ExposureValueCalculator.calculateEV(lux: lux)
            mainVal = String(format: "EV %.1f", ev)
        }
        var label = "\(mainVal), \(Self.formatValue(kelvin)) Kelvin"
        if isCaptured {
            label += ", \(interpretationDescription), \(comparisonText)"
            if !activeChips.isEmpty {
                let chipsNames = activeChips.map { $0.localizedName(language: language) }.joined(separator: ", ")
                let recommendedFor = language == .korean ? "권장 활동: \(chipsNames)" : (language == .french ? "Recommandé pour : \(chipsNames)" : "Recommended for: \(chipsNames)")
                label += ", \(recommendedFor)"
            }
        }
        return label
    }
}
