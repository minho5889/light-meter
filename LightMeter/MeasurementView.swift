import SwiftUI

struct MeasurementView: View {
    @ObservedObject var cameraManager: CameraManager

    @State private var isCaptured: Bool = false
    @State private var frozenFrame: UIImage? = nil
    @State private var capturedLux: Double = 0.0
    @State private var capturedKelvin: Double = 0.0

    var body: some View {
        ZStack {
            // Background layer
            if isCaptured, let frame = frozenFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else if cameraManager.permissionGranted {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Overlay content
            VStack {
                // Back arrow (captured mode only)
                if isCaptured {
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
                }

                // Error / permission states
                if !cameraManager.permissionGranted {
                    Spacer()
                    Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if let error = cameraManager.cameraError {
                    Spacer()
                    Text(error)
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    // Measurement card
                    MeasurementCardView(
                        lux: isCaptured ? capturedLux : cameraManager.lux,
                        kelvin: isCaptured ? capturedKelvin : cameraManager.colorTemperature,
                        isCaptured: isCaptured
                    )
                    .padding(.horizontal)

                    Spacer()

                    // Bottom controls (live mode only)
                    if !isCaptured {
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

                            Button(action: { cameraManager.toggleCamera() }) {
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

    private func capture() {
        guard let frame = cameraManager.captureFrame() else { return }
        frozenFrame = frame
        capturedLux = cameraManager.lux
        capturedKelvin = cameraManager.colorTemperature
        isCaptured = true
    }

    private func returnToLiveMode() {
        isCaptured = false
        frozenFrame = nil
    }
}
