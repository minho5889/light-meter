import SwiftUI

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
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
        .onAppear {
            cameraViewModel.requestPermission()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 0 || newTab == 1 {
                cameraViewModel.startSession()
            } else {
                cameraViewModel.stopSession()
            }
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
