import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    private var safeAreaTop: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        return keyWindow?.safeAreaInsets.top ?? 47
    }

    var body: some View {
        ZStack {
            Color.clear
                .background(TransparentBackground())

            VStack {
                Spacer().frame(height: max(8, safeAreaTop + 12))

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
