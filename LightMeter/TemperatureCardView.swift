import SwiftUI

struct TemperatureCardView: View {
    let kelvin: Double
    let interpretationDescription: String
    let interpretationTip: String

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
                .font(.system(size: DesignConstants.fontSizeXXL, weight: .bold, design: .monospaced))
            Text("K")
                .font(.system(size: DesignConstants.fontSizeXS))

            Divider()

            // Color tone label
            Text(interpretationDescription)
                .font(.system(size: DesignConstants.fontSizeMD, weight: .semibold))

            // Recommended environment
            Text(interpretationTip)
                .font(.system(size: DesignConstants.fontSizeXS))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Self.formatValue(kelvin)) Kelvin, \(interpretationDescription), \(interpretationTip)")
    }
}
