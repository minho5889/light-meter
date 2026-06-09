import SwiftUI

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0

    /// Camera tabs show the shared preview; non-camera tabs don't.
    private var isCameraTab: Bool { selectedTab == 0 || selectedTab == 1 || selectedTab == 2 }

    var body: some View {
        ZStack {
            // Shared single CameraPreviewView — behind our custom View Switched layers.
            // Only present when permission is granted AND on a camera tab.
            if cameraViewModel.permissionGranted, isCameraTab {
                CameraPreviewView(session: cameraViewModel.session)
                    .ignoresSafeArea()
            } else if !cameraViewModel.permissionGranted {
                // Permission-denied background
                Color.black.ignoresSafeArea()
            }

            // Tab content view switcher (replacing native TabView entirely for pixel-perfect overlays)
            Group {
                switch selectedTab {
                case 0:
                    MeasurementView(cameraViewModel: cameraViewModel)
                case 1:
                    TemperatureView(cameraViewModel: cameraViewModel)
                case 2:
                    FlickerCheckView(viewModel: cameraViewModel)
                case 3:
                    RecordsView(cameraViewModel: cameraViewModel)
                default:
                    MeasurementView(cameraViewModel: cameraViewModel)
                }
            }
            .ignoresSafeArea(.all, edges: .top)

            // Custom Floating Capsule Segmented Tab Bar Overlay
            if cameraViewModel.permissionGranted {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        tabItemButton(index: 0, systemIcon: "sun.max.fill", key: "tab_brightness")
                        tabItemButton(index: 1, systemIcon: "thermometer.medium", key: "tab_temperature")
                        tabItemButton(index: 2, systemIcon: "checkmark.shield.fill", key: "tab_check")
                        tabItemButton(index: 3, systemIcon: "list.clipboard.fill", key: "tab_records")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12) // Float slightly above safety guide
                }
            }

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
            cameraViewModel.activeTab = newTab
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

    // MARK: - Custom Tab Button Helper

    private func tabItemButton(index: Int, systemIcon: String, key: String) -> some View {
        let isSelected = selectedTab == index
        let label = LocalizedStrings.translate(key: key, language: cameraViewModel.appLanguage)
        
        return Button(action: {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: systemIcon)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .frame(height: 22)
                
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.6))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white : Color.clear)
            )
            .animation(.easeIn(duration: 0.15), value: isSelected)
        }
    }
}
