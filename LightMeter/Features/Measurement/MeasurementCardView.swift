import SwiftUI

struct MeasurementCardView: View {
    let lux: Double
    let kelvin: Double
    let isCaptured: Bool
    var interpretationDescription: String = ""
    var interpretationTip: String = ""
    var comparisonText: String = ""

    /// Formats a Double as a locale-aware integer string with thousands separators.
    private static func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    var body: some View {
        VStack(spacing: DesignConstants.spacingXS) {
            // Kelvin reading
            Text(Self.formatValue(kelvin))
                .font(.system(size: DesignConstants.fontSizeLG, weight: .medium))
            Text("K")
                .font(.system(size: DesignConstants.fontSizeXXXS))

            // Lux reading
            Text(Self.formatValue(lux))
                .font(.system(size: DesignConstants.fontSizeXXL, weight: .bold, design: .monospaced))
            Text("LUX")
                .font(.system(size: DesignConstants.fontSizeXS))

            // Expanded content (captured mode only)
            if isCaptured {
                Divider()

                Text("User Guide")
                    .font(.system(size: DesignConstants.fontSizeXS, weight: .semibold))

                Text(interpretationDescription)
                    .font(.system(size: DesignConstants.fontSizeXXS))

                Text(interpretationTip)
                    .font(.system(size: DesignConstants.fontSizeXXXS))

                Text(comparisonText)
                    .font(.system(size: DesignConstants.fontSizeXXXS))
                    .italic()
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
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
