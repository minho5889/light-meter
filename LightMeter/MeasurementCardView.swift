import SwiftUI

struct MeasurementCardView: View {
    let lux: Double
    let kelvin: Double
    let isCaptured: Bool
    var interpretationDescription: String = ""
    var interpretationTip: String = ""
    var comparisonText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            // Kelvin reading
            Text(String(format: "%.0f", kelvin))
                .font(.system(size: 20, weight: .medium))
            Text("K")
                .font(.system(size: 12))

            // Lux reading
            Text(String(format: "%.0f", lux))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            Text("LUX")
                .font(.system(size: 14))

            // Expanded content (captured mode only)
            if isCaptured {
                Divider()

                Text("User Guide")
                    .font(.system(size: 14, weight: .semibold))

                Text(interpretationDescription)
                    .font(.system(size: 13))

                Text(interpretationTip)
                    .font(.system(size: 12))

                Text(comparisonText)
                    .font(.system(size: 12))
                    .italic()
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
