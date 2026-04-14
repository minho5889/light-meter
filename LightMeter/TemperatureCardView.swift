import SwiftUI

struct TemperatureCardView: View {
    let kelvin: Double
    let interpretationDescription: String
    let interpretationTip: String

    var body: some View {
        VStack(spacing: 8) {
            // Kelvin reading
            Text(String(format: "%.0f", kelvin))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            Text("K")
                .font(.system(size: 14))

            Divider()

            // Color tone label
            Text(interpretationDescription)
                .font(.system(size: 18, weight: .semibold))

            // Recommended environment
            Text(interpretationTip)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
