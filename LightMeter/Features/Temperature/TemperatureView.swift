import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .background(TransparentBackground())

                VStack {
                    Spacer().frame(height: max(8, geometry.safeAreaInsets.top))

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
}
