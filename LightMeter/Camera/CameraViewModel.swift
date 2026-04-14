@preconcurrency import AVFoundation
import SwiftUI

/// Glue-layer view model that holds all published camera state.
/// Coordinates between CameraSessionManager and CameraFrameProvider.
/// Views observe this single source of truth.
@MainActor
final class CameraViewModel: ObservableObject {
    @Published var lux: Double = 0.0
    @Published var colorTemperature: Double = 0.0
    @Published var permissionGranted: Bool = false
    @Published var cameraError: String? = nil
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var sessionReady: Bool = false

    private let sessionManager = CameraSessionManager()
    private let frameProvider = CameraFrameProvider()

    /// Exposes the AVCaptureSession for CameraPreviewView.
    nonisolated var session: AVCaptureSession { sessionManager.session }

    /// Exposes the session queue so the preview layer can safely connect.
    nonisolated var sessionQueue: DispatchQueue { sessionManager.sessionQueue }

    init() {
        sessionManager.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.cameraError = message
            }
        }

        frameProvider.onFrameUpdate = { [weak self] luxValue, kelvinValue in
            DispatchQueue.main.async {
                self?.lux = luxValue
                self?.colorTemperature = kelvinValue
            }
        }
    }

    /// Requests camera permission. On grant, sets up the session.
    func requestPermission() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            self.permissionGranted = granted
            if granted {
                self.setupSession()
            }
        }
    }

    /// Starts the capture session.
    func startSession() {
        sessionManager.startSession()
    }

    /// Stops the capture session.
    func stopSession() {
        sessionManager.stopSession()
    }

    /// Toggles between front and rear cameras.
    func toggleCamera() {
        sessionManager.toggleCamera { [weak self] newPosition in
            DispatchQueue.main.async {
                self?.currentCameraPosition = newPosition
                // Update frame provider with the new device so lux/kelvin reads
                // come from the correct camera after switching
                self?.frameProvider.captureDevice = self?.sessionManager.device
            }
        }
    }

    /// Captures the current frame as a UIImage asynchronously.
    func captureFrameAsync() async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [frameProvider] in
                let image = frameProvider.captureFrame()
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Private

    private func setupSession() {
        let position = currentCameraPosition
        sessionManager.setupSession(position: position, delegate: frameProvider) { [weak self] in
            DispatchQueue.main.async {
                self?.frameProvider.captureDevice = self?.sessionManager.device
                self?.sessionReady = true
            }
        }
    }
}
