import SwiftUI

struct MeasurementCardView: View {
    let lux: Double
    let kelvin: Double
    let isCaptured: Bool
    var interpretationDescription: String = ""
    var interpretationTip: String = ""
    var comparisonText: String = ""

    var body: some View {
        VStack(spacing: DesignConstants.spacingXS) {
            // Kelvin reading
            Text(String(format: "%.0f", kelvin))
                .font(.system(size: DesignConstants.fontSizeLG, weight: .medium))
            Text("K")
                .font(.system(size: DesignConstants.fontSizeXXXS))

            // Lux reading
            Text(String(format: "%.0f", lux))
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
    }
}
