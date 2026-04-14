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

    private let sessionManager = CameraSessionManager()
    private let frameProvider = CameraFrameProvider()

    /// Exposes the AVCaptureSession for CameraPreviewView.
    nonisolated var session: AVCaptureSession { sessionManager.session }

    init() {
        sessionManager.onError = { [weak self] message in
            Task { @MainActor in
                self?.cameraError = message
            }
        }

        frameProvider.onFrameUpdate = { [weak self] luxValue, kelvinValue in
            Task { @MainActor in
                self?.lux = luxValue
                self?.colorTemperature = kelvinValue
            }
        }
    }

    /// Requests camera permission. On grant, sets up the session.
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.permissionGranted = granted
                if granted {
                    self?.setupSession()
                }
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
            Task { @MainActor in
                self?.currentCameraPosition = newPosition
            }
        }
    }

    /// Captures the current frame as a UIImage.
    nonisolated func captureFrame() -> UIImage? {
        frameProvider.captureFrame()
    }

    // MARK: - Private

    private func setupSession() {
        let position = currentCameraPosition
        sessionManager.setupSession(position: position, delegate: frameProvider)
        frameProvider.captureDevice = sessionManager.device
    }
}
