import SwiftUI

struct TemperatureCardView: View {
    let kelvin: Double

    private var interpretation: InterpretationResult {
        KelvinInterpreter.interpret(kelvin: kelvin)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Kelvin reading
            Text(String(format: "%.0f", kelvin))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
            Text("K")
                .font(.system(size: 14))

            Divider()

            // Color tone label
            Text(interpretation.description)
                .font(.system(size: 18, weight: .semibold))

            // Recommended environment
            Text(interpretation.tip)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
