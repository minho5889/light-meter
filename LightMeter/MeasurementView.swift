import SwiftUI

struct MeasurementView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        ZStack {
            // Camera preview or black fallback
            if cameraManager.permissionGranted {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Error / permission states, or measurement overlay
            if !cameraManager.permissionGranted {
                Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if let error = cameraManager.cameraError {
                Text(error)
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                VStack(spacing: 24) {
                    // Lux section
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", cameraManager.lux))
                            .font(.system(size: 72, weight: .thin, design: .monospaced))
                        Text("lux")
                            .font(.system(size: 18))
                        Text(LuxInterpreter.interpret(lux: cameraManager.lux).description)
                            .font(.system(size: 14))
                        Text(LuxInterpreter.interpret(lux: cameraManager.lux).tip)
                            .font(.system(size: 12))
                    }

                    // Kelvin section
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f", cameraManager.colorTemperature))
                            .font(.system(size: 72, weight: .thin, design: .monospaced))
                        Text("K")
                            .font(.system(size: 18))
                        Text(KelvinInterpreter.interpret(kelvin: cameraManager.colorTemperature).description)
                            .font(.system(size: 14))
                        Text(KelvinInterpreter.interpret(kelvin: cameraManager.colorTemperature).tip)
                            .font(.system(size: 12))
                    }
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .padding()
            }
        }
    }
}
