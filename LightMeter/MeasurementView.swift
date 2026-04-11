import SwiftUI

struct MeasurementView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if !cameraManager.permissionGranted {
                Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if let error = cameraManager.cameraError {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text(String(format: "%.0f", cameraManager.lux))
                            .font(.system(size: 72, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                        Text("lux")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }

                    VStack(spacing: 8) {
                        Text(String(format: "%.0f", cameraManager.colorTemperature))
                            .font(.system(size: 72, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                        Text("K")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
