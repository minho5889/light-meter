@preconcurrency import AVFoundation
import SwiftUI
import Observation

/// Coordinator view model that coordinates between the camera session actor,
/// the frame provider, and decomposed state models.
@Observable
@MainActor
final class CameraViewModel {
    // COORDINATOR MODELS
    public let measurement = MeasurementModel()
    public let flicker = FlickerModel()
    public let recordsStore = RecordsStore()

    // CAMERA SESSION LIFECYCLE & STATE
    public var permissionGranted: Bool = false
    public var cameraError: String? = nil
    public var currentCameraPosition: AVCaptureDevice.Position = .back
    public var sessionReady: Bool = false
    public var activeTab: Int = 0 {
        didSet {
            frameProvider?.updateActiveTab(activeTab)
        }
    }
    public var appLanguage: AppLanguage = .systemLanguage {
        didSet {
            flicker.updateDescription(language: appLanguage)
        }
    }

    private let sessionActor = CameraSessionActor()
    private var frameProvider: CameraFrameProvider!

    /// Exposes the AVCaptureSession for CameraPreviewView.
    nonisolated var session: AVCaptureSession { sessionActor.session }

    /// Exposes the session queue so the preview layer can safely connect.
    nonisolated var sessionQueue: DispatchQueue { sessionActor.sessionQueue }

    init() {
        let savedPositionRaw = UserDefaults.standard.integer(forKey: "com.lightmeter.cameraPosition")
        let savedPosition = AVCaptureDevice.Position(rawValue: savedPositionRaw)
        self.currentCameraPosition = (savedPosition == .back || savedPosition == .front) ? savedPosition! : .back

        let actor = self.sessionActor
        
        // Phase 1: Initialize frameProvider with a dummy callback to satisfy Swift's initialization checks
        self.frameProvider = CameraFrameProvider(sessionActor: actor, onFrameUpdate: { _, _, _ in }, onFlickerUpdate: { _, _ in })
        
        // Phase 2: Initialize frameProvider with real callbacks capturing self safely
        self.frameProvider = CameraFrameProvider(
            sessionActor: actor,
            onFrameUpdate: { [weak self] luxValue, kelvinValue, tintValue in
                Task { @MainActor [weak self] in
                    self?.measurement.update(luxValue: luxValue, kelvinValue: kelvinValue, tintValue: tintValue)
                }
            },
            onFlickerUpdate: { [weak self] result, waveSamples in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.flicker.update(result: result, waveSamples: waveSamples, language: self.appLanguage)
                }
            }
        )

        // Register the error callback asynchronously on the actor
        Task { [weak self, actor] in
            let viewModel = self
            await actor.setOnError { message in
                Task { @MainActor in
                    viewModel?.cameraError = message
                }
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
        measurement.resetSmoothers()
        Task {
            await sessionActor.startSession()
        }
    }

    /// Stops the capture session.
    func stopSession() {
        Task {
            await sessionActor.stopSession()
        }
    }

    /// Toggles between front and rear cameras.
    func toggleCamera() {
        Task {
            if let newPosition = await sessionActor.toggleCamera() {
                self.currentCameraPosition = newPosition
                UserDefaults.standard.set(newPosition.rawValue, forKey: "com.lightmeter.cameraPosition")
                self.measurement.resetSmoothers()
            }
        }
    }

    /// Captures the current frame as a UIImage asynchronously.
    func captureFrameAsync() async -> UIImage? {
        sessionActor.captureFrame()
    }

    // MARK: - Flicker Control Triggers delegates
    func startFlickerCheck() {
        flicker.start(sessionActor: sessionActor, language: appLanguage)
    }

    func stopFlickerCheck() {
        flicker.stop(sessionActor: sessionActor)
    }

    // MARK: - Private
    private func setupSession() {
        let position = currentCameraPosition
        guard let provider = frameProvider else { return }
        
        Task {
            await sessionActor.setupSession(position: position, delegate: provider)
            self.sessionReady = true
        }
    }
}
