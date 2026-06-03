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
        GeometryReader { geometry in
            ZStack {
                // Transparent background — shared CameraPreviewView lives behind the TabView in ContentView.
                // TransparentBackground clears the UIKit hosting view's opaque background so the preview shows through.
                Color.clear.ignoresSafeArea()
                    .background(TransparentBackground())

                // Live mode overlay — always present, hidden when captured
                liveModeContent(safeAreaTop: geometry.safeAreaInsets.top)
                    .opacity(isCaptured ? 0 : 1)
                    .allowsHitTesting(!isCaptured)

                // Captured mode overlay — shown on top when captured
                if isCaptured, let frame = frozenFrame {
                    capturedModeContent(frame: frame, safeAreaTop: geometry.safeAreaInsets.top)
                }
            }
        }
        .toolbar(isCaptured ? .hidden : .visible, for: .tabBar)
    }

    // MARK: - Live Mode

    private func liveModeContent(safeAreaTop: CGFloat) -> some View {
        VStack {
            Spacer().frame(height: max(8, safeAreaTop))

            MeasurementCardView(
                lux: cameraViewModel.lux,
                kelvin: cameraViewModel.colorTemperature,
                isCaptured: false,
                language: cameraViewModel.appLanguage
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
            .padding(.bottom, 96) // Padded up to clear the custom capsule floating tab bar
        }
    }

    // MARK: - Captured Mode

    private func capturedModeContent(frame: UIImage, safeAreaTop: CGFloat) -> some View {
        ZStack {
            Image(uiImage: frame)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Top control: Figma-style Back chevron button
                HStack {
                    Button(action: returnToLiveMode) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            Text(LocalizedStrings.translate(key: "ui_back", language: cameraViewModel.appLanguage))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .accessibilityLabel("Back to live mode")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, max(12, safeAreaTop))

                MeasurementCardView(
                    lux: capturedLux,
                    kelvin: capturedKelvin,
                    isCaptured: true,
                    language: cameraViewModel.appLanguage,
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
            let interpretation = LuxInterpreter.interpret(lux: currentLux, language: cameraViewModel.appLanguage)
            capturedInterpretationDescription = interpretation.description
            capturedInterpretationTip = interpretation.tip
            capturedComparisonText = ComparisonGenerator.generate(lux: currentLux)
            
            // Automatically save to Records history
            cameraViewModel.saveRecord(lux: currentLux, kelvin: currentKelvin)
            
            isCaptured = true
        }
    }

    private func returnToLiveMode() {
        isCaptured = false
        frozenFrame = nil
    }
}
