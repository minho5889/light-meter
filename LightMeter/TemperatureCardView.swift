import SwiftUI

struct TemperatureCardView: View {
    let kelvin: Double
    let interpretationDescription: String
    let interpretationTip: String

    var body: some View {
        VStack(spacing: DesignConstants.spacingXS) {
            // Kelvin reading
            Text(String(format: "%.0f", kelvin))
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
    }
}
