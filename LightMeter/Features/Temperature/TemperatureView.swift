import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    var body: some View {
        ZStack {
            // Camera preview — always in the view tree
            CameraPreviewView(session: cameraViewModel.session)
                .ignoresSafeArea()

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
