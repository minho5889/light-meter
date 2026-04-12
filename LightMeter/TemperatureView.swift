import SwiftUI

struct TemperatureView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        NavigationStack {
        ZStack {
            // Background: live camera or black fallback
            if cameraManager.permissionGranted {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                // Top bar: gear icon in top-right
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

                if !cameraManager.permissionGranted {
                    Spacer()
                    Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    TemperatureCardView(kelvin: cameraManager.colorTemperature)
                        .padding(.horizontal)

                    Spacer()
                }
            }
        }
        }
    }
}
