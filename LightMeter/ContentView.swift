import SwiftUI

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0

    /// Camera tabs show the shared preview; non-camera tabs don't.
    private var isCameraTab: Bool { selectedTab == 0 || selectedTab == 1 }

    var body: some View {
        ZStack {
            // Shared single CameraPreviewView — behind the TabView.
            // Only present when permission is granted AND on a camera tab.
            if cameraViewModel.permissionGranted, isCameraTab {
                CameraPreviewView(session: cameraViewModel.session)
                    .ignoresSafeArea()
            } else if !cameraViewModel.permissionGranted {
                // Permission-denied background + overlay
                Color.black.ignoresSafeArea()
            }

            TabView(selection: $selectedTab) {
                MeasurementView(cameraViewModel: cameraViewModel)
                    .tabItem {
                        Image(systemName: "sun.max")
                        Text("LUX")
                    }
                    .tag(0)

                TemperatureView(cameraViewModel: cameraViewModel)
                    .tabItem {
                        Image(systemName: "thermometer.medium")
                        Text("Temperature")
                    }
                    .tag(1)

                PlaceholderView(title: "Flicker Detection", subtitle: "Coming Soon")
                    .tabItem {
                        Image(systemName: "checkmark.shield")
                        Text("Check")
                    }
                    .tag(2)

                PlaceholderView(title: "Records", subtitle: "Coming Soon")
                    .tabItem {
                        Image(systemName: "list.clipboard")
                        Text("Records")
                    }
                    .tag(3)
            }
            .toolbarBackground(.hidden, for: .tabBar)

            // Permission-denied overlay — shown on top when camera access is missing
            if !cameraViewModel.permissionGranted {
                VStack {
                    Spacer()
                    Text("Camera access is required to measure light.\nPlease enable it in Settings.")
                        .font(.system(size: DesignConstants.fontSizeSM))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            }
        }
        .onAppear {
            cameraViewModel.requestPermission()
        }
        .onChange(of: selectedTab) { _, newTab in
            switch TabTransitionAction.resolve(from: previousTab, to: newTab) {
            case .startSession:
                cameraViewModel.startSession()
            case .stopSession:
                cameraViewModel.stopSession()
            case .none:
                break
            }
            previousTab = newTab
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            cameraViewModel.startSession()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didEnterBackgroundNotification
            )
        ) { _ in
            cameraViewModel.stopSession()
        }
    }
}
