import AVFoundation
import SwiftUI

struct CameraStateOverlay<Content: View>: View {
    let permissionGranted: Bool
    let cameraError: String?
    let session: AVCaptureSession
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            // Background layer
            if permissionGranted {
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
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            } else if let error = cameraError {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.system(size: 16))
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
