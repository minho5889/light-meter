import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    var body: some View {
        ZStack {
            Color.clear
                .background(TransparentBackground())

            VStack {
                Spacer().frame(height: 8)

                TemperatureCardView(
                    kelvin: cameraViewModel.colorTemperature,
                    interpretationDescription: KelvinInterpreter.interpret(
                        kelvin: cameraViewModel.colorTemperature,
                        language: cameraViewModel.appLanguage
                    ).description,
                    interpretationTip: KelvinInterpreter.interpret(
                        kelvin: cameraViewModel.colorTemperature,
                        language: cameraViewModel.appLanguage
                    ).tip
                )
                .padding(.horizontal)

                Spacer()
            }
            .padding(.bottom, 96) // Clear bottom tab bar capsule
        }
    }
}
