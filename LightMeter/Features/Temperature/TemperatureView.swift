import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    var body: some View {
        ZStack {
            Color.clear
                .background(TransparentBackground())

            // Content overlay
            VStack {
                Spacer().frame(height: 8)

                TemperatureCardView(
                    kelvin: cameraViewModel.colorTemperature,
                    interpretationDescription: KelvinInterpreter.interpret(kelvin: cameraViewModel.colorTemperature).description,
                    interpretationTip: KelvinInterpreter.interpret(kelvin: cameraViewModel.colorTemperature).tip
                )
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}
