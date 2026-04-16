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
        ZStack {
            // Transparent background — shared CameraPreviewView lives behind the TabView in ContentView
            Color.clear.ignoresSafeArea()

            // Live mode overlay — always present, hidden when captured
            liveModeContent
                .opacity(isCaptured ? 0 : 1)
                .allowsHitTesting(!isCaptured)

            // Captured mode overlay — shown on top when captured
            if isCaptured, let frame = frozenFrame {
                capturedModeContent(frame: frame)
            }
        }
        .toolbar(isCaptured ? .hidden : .visible, for: .tabBar)
    }

    // MARK: - Live Mode

    private var liveModeContent: some View {
        VStack {
            Spacer().frame(height: 8)

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

            HStack(spacing: DesignConstants.spacingMD) {
                Button(action: capture) {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: DesignConstants.captureButtonOuter, height: DesignConstants.captureButtonOuter)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: DesignConstants.captureButtonInner, height: DesignConstants.captureButtonInner)
                        )
                }
                .accessibilityLabel("Capture")

                Button(action: { cameraViewModel.toggleCamera() }) {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: DesignConstants.fontSizeXL, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: DesignConstants.toggleButtonSize, height: DesignConstants.toggleButtonSize)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Switch Camera")
            }
            .padding(.bottom, DesignConstants.spacingLG)
        }
    }

    // MARK: - Captured Mode

    private func capturedModeContent(frame: UIImage) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: frame)
                .resizable()
                .aspectRatio(contentMode: .fit)

            VStack {
                HStack {
                    Button(action: returnToLiveMode) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Close")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

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
        }
    }

    // MARK: - Actions

    private func capture() {
        let currentLux = cameraViewModel.lux
        let currentKelvin = cameraViewModel.colorTemperature

        Task {
            guard let frame = await cameraViewModel.captureFrameAsync() else { return }
            frozenFrame = frame
            capturedLux = currentLux
            capturedKelvin = currentKelvin
            let interpretation = LuxInterpreter.interpret(lux: currentLux)
            capturedInterpretationDescription = interpretation.description
            capturedInterpretationTip = interpretation.tip
            capturedComparisonText = ComparisonGenerator.generate(lux: currentLux)
            isCaptured = true
        }
    }

    private func returnToLiveMode() {
        isCaptured = false
        frozenFrame = nil
    }
}
