import SwiftUI

struct MeasurementView: View {
    @ObservedObject var cameraViewModel: CameraViewModel

    @State private var isCaptured: Bool = false
    @State private var frozenFrame: UIImage? = nil
    @State private var capturedLux: Double = 0.0
    @State private var capturedKelvin: Double = 0.0
    @State private var capturedInterpretationDescription: String = ""
    @State private var capturedInterpretationTip: String = ""
    @State private var capturedComparisonText: String = ""

    var body: some View {
        NavigationStack {
        ZStack {
            if isCaptured, let frame = frozenFrame {
                // Captured mode: frozen frame background
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                // Overlay content for captured mode
                VStack {
                    HStack {
                        Button(action: returnToLiveMode) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    MeasurementCardView(
                        lux: capturedLux,
                        kelvin: capturedKelvin,
                        isCaptured: true,
                        interpretationDescription: capturedInterpretationDescription,
                        interpretationTip: capturedInterpretationTip,
                        comparisonText: capturedComparisonText
                    )
                    .padding(.horizontal)

                    Spacer()
                }
            } else {
                // Live mode: use CameraStateOverlay for background/permission/error
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

                        MeasurementCardView(
                            lux: cameraViewModel.lux,
                            kelvin: cameraViewModel.colorTemperature,
                            isCaptured: false,
                            interpretationDescription: "",
                            interpretationTip: "",
                            comparisonText: ""
                        )
                        .padding(.horizontal)

                        Spacer()

                        HStack(spacing: 24) {
                            Button(action: capture) {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 58, height: 58)
                                    )
                            }

                            Button(action: { cameraViewModel.toggleCamera() }) {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        }
        .toolbar(isCaptured ? .hidden : .visible, for: .tabBar)
        .onDisappear {
            if isCaptured {
                returnToLiveMode()
            }
        }
    }

    private func capture() {
        guard let frame = cameraViewModel.captureFrame() else { return }
        frozenFrame = frame
        capturedLux = cameraViewModel.lux
        capturedKelvin = cameraViewModel.colorTemperature
        let interpretation = LuxInterpreter.interpret(lux: capturedLux)
        capturedInterpretationDescription = interpretation.description
        capturedInterpretationTip = interpretation.tip
        capturedComparisonText = ComparisonGenerator.generate(lux: capturedLux)
        isCaptured = true
    }

    private func returnToLiveMode() {
        isCaptured = false
        frozenFrame = nil
    }
}
