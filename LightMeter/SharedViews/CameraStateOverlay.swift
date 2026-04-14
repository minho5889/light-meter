import AVFoundation
import SwiftUI

struct CameraStateOverlay<Content: View>: View {
    let permissionGranted: Bool
    let cameraError: String?
    let session: AVCaptureSession
    let sessionReady: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Background layer
            if permissionGranted && sessionReady {
                CameraPreviewView(session: session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // State overlay
            if !permissionGranted {
                VStack {
                    Spacer()
                    Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                        .font(.system(size: DesignConstants.fontSizeSM))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else if let error = cameraError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.system(size: DesignConstants.fontSizeSM))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else {
                content()
            }
        }
    }
}
