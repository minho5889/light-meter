import SwiftUI

struct MeasurementView: View {
    var cameraViewModel: CameraViewModel

    @State private var isCaptured: Bool = false
    @State private var frozenFrame: UIImage? = nil
    @State private var capturedLux: Double = 0.0
    @State private var capturedKelvin: Double = 0.0
    @State private var capturedInterpretationDescription: String = ""
    @State private var capturedInterpretationTip: String = ""
    @State private var capturedComparisonText: String = ""

    @AppStorage("showReflectedLightDisclosure") private var showDisclosure = true
    @State private var isShowingCalibration = false

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
            // Transparent background — shared CameraPreviewView lives behind the TabView in ContentView.
            // TransparentBackground clears the UIKit hosting view's opaque background so the preview shows through.
            Color.clear.ignoresSafeArea()
                .background(TransparentBackground())

            // Live mode overlay — always present, hidden when captured
            liveModeContent(safeAreaTop: safeAreaTop)
                .opacity(isCaptured ? 0 : 1)
                .allowsHitTesting(!isCaptured)

            // Captured mode overlay — shown on top when captured
            if isCaptured, let frame = frozenFrame {
                capturedModeContent(frame: frame, safeAreaTop: safeAreaTop)
            }
        }
        .toolbar(isCaptured ? .hidden : .visible, for: .tabBar)
        .sheet(isPresented: $isShowingCalibration) {
            CalibrationView(viewModel: cameraViewModel)
        }
    }

    // MARK: - Live Mode

    private func liveModeContent(safeAreaTop: CGFloat) -> some View {
        VStack {
            Spacer().frame(height: max(8, safeAreaTop + 12))

            MeasurementCardView(
                lux: cameraViewModel.measurement.lux,
                kelvin: cameraViewModel.measurement.colorTemperature,
                isCaptured: false,
                language: cameraViewModel.appLanguage
            )
            .padding(.horizontal)

            VStack(spacing: 12) {
                // Calibrate button
                Button(action: { isShowingCalibration = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                        Text(LocalizedStrings.translate(key: "ui_calibrate_button", language: cameraViewModel.appLanguage))
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                
                // Disclosure Card
                if showDisclosure {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text(LocalizedStrings.translate(key: "ui_reflected_disclosure_title", language: cameraViewModel.appLanguage))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showDisclosure = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.system(size: 16))
                            }
                            .accessibilityLabel("Dismiss disclosure")
                        }
                        
                        Text(LocalizedStrings.translate(key: "ui_reflected_disclosure_desc", language: cameraViewModel.appLanguage))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

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
        ZStack(alignment: .top) {
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
                .padding(.top, safeAreaTop + 16)

                ScrollView(.vertical, showsIndicators: false) {
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
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Actions

    private func capture() {
        let currentLux = cameraViewModel.measurement.lux
        let currentKelvin = cameraViewModel.measurement.colorTemperature

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
            cameraViewModel.recordsStore.saveRecord(lux: currentLux, kelvin: currentKelvin)
            
            isCaptured = true
        }
    }

    private func returnToLiveMode() {
        isCaptured = false
        frozenFrame = nil
    }
}
