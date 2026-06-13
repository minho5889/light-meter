import SwiftUI

struct TemperatureCardView: View {
    let kelvin: Double
    let interpretationDescription: String
    let interpretationTip: String
    let tintDescription: String
    let tintTip: String
    let language: AppLanguage

    @ScaledMetric(relativeTo: .largeTitle) private var readingSize: CGFloat = 40

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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Left-Aligned Kelvin Layout
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(Self.formatValue(kelvin))
                        .font(.system(size: readingSize, weight: .bold, design: .rounded))
                    Text("K")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 4)

            Divider()
                .background(Color.white.opacity(0.12))

            // Teinte details
            VStack(alignment: .leading, spacing: 8) {
                Text(interpretationDescription)
                    .font(.system(.body, design: .rounded).weight(.bold))
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

            Divider()
                .background(Color.white.opacity(0.12))

            // Tint Section
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStrings.translate(key: "ui_tint", language: language))
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.0)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(tintDescription)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    
                    Text(tintTip)
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
        .accessibilityLabel("\(Self.formatValue(kelvin)) Kelvin, \(interpretationDescription), \(interpretationTip), \(LocalizedStrings.translate(key: "ui_tint", language: language)): \(tintDescription), \(tintTip)")
    }
}
