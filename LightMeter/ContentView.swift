import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MeasurementView(cameraManager: cameraManager)
                .tabItem {
                    Image(systemName: "sun.max")
                    Text("LUX")
                }
                .tag(0)

            TemperatureView(cameraManager: cameraManager)
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
            cameraManager.requestPermission()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            cameraManager.startSession()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didEnterBackgroundNotification
            )
        ) { _ in
            cameraManager.stopSession()
        }
    }
}
