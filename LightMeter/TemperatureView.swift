import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    var body: some View {
        NavigationStack {
            CameraStateOverlay(
                permissionGranted: cameraViewModel.permissionGranted,
                cameraError: cameraViewModel.cameraError,
                session: cameraViewModel.session
            ) {
                VStack {
                    HStack {
                        Spacer()
                        NavigationLink(destination: PlaceholderView(title: "Settings", subtitle: "Coming Soon")) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                    }
                    .padding(.horizontal)

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
}
