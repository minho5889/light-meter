@preconcurrency import AVFoundation
import SwiftUI

/// Glue-layer view model that holds all published camera state.
/// Coordinates between CameraSessionActor and CameraFrameProvider.
/// Views observe this single source of truth.
@MainActor
final class CameraViewModel: ObservableObject {
    @Published var lux: Double = 0.0
    @Published var colorTemperature: Double = 0.0
    @Published var tint: Double = 0.0
    @Published var permissionGranted: Bool = false
    @Published var cameraError: String? = nil
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var sessionReady: Bool = false

    // MARK: - Flicker Detection Published State
    @Published var flickerPercentage: Double = 0.0
    @Published var flickerFrequency: Double = 0.0
    @Published var flickerSafetyLevel: String = "Safe"
    @Published var flickerDescription: String = "Tap start check to analyze."
    @Published var isCheckingFlicker: Bool = false
    @Published var waveData: [Float] = []

    // MARK: - Localization & Records State
    @Published var appLanguage: AppLanguage = .systemLanguage
    @Published var records: [LightRecord] = []

    private let sessionActor = CameraSessionActor()
    private var frameProvider: CameraFrameProvider!
    private var luxSmoother = SignalSmoother(alpha: 0.15)
    private var kelvinSmoother = SignalSmoother(alpha: 0.15)
    private var tintSmoother = SignalSmoother(alpha: 0.15)
    
    private static let recordsKey = "light_meter_records"

    /// Exposes the AVCaptureSession for CameraPreviewView.
    nonisolated var session: AVCaptureSession { sessionActor.session }

    /// Exposes the session queue so the preview layer can safely connect.
    nonisolated var sessionQueue: DispatchQueue { sessionActor.sessionQueue }

    init() {
        let actor = self.sessionActor
        
        // Phase 1: Initialize frameProvider with a dummy callback that has no self captures
        // to satisfy Swift's initialization checks.
        self.frameProvider = CameraFrameProvider(sessionActor: actor, onFrameUpdate: { _, _, _ in }, onFlickerUpdate: { _, _ in })
        
        // Phase 2: Now that self is fully initialized, re-assign the real frameProvider
        // capturing self safely.
        self.frameProvider = CameraFrameProvider(
            sessionActor: actor,
            onFrameUpdate: { [weak self] luxValue, kelvinValue, tintValue in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let smoothedLux = self.luxSmoother.update(luxValue)
                    self.lux = SignalSmoother.roundToTwoSignificantFigures(smoothedLux)
                    self.colorTemperature = self.kelvinSmoother.update(kelvinValue)
                    self.tint = self.tintSmoother.update(tintValue)
                }
            },
            onFlickerUpdate: { [weak self] result, waveSamples in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isCheckingFlicker else { return }
                    self.flickerPercentage = result.percentage
                    self.flickerFrequency = result.frequency
                    self.flickerSafetyLevel = result.safetyLevel
                    if result.description == "No light detected." {
                        self.flickerDescription = LocalizedStrings.translate(key: "ui_no_light", language: self.appLanguage)
                    } else {
                        self.flickerDescription = FlickerInterpreter.description(
                            level: result.safetyLevel,
                            nyquist: result.nyquist,
                            language: self.appLanguage
                        )
                    }
                    self.waveData = waveSamples
                }
            }
        )

        // Register the error callback asynchronously on the actor.
        Task { [weak self, actor] in
            let viewModel = self
            await actor.setOnError { message in
                Task { @MainActor in
                    viewModel?.cameraError = message
                }
            }
        }
        
        // Load records
        loadRecords()
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
        luxSmoother.reset()
        kelvinSmoother.reset()
        tintSmoother.reset()
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
                self.luxSmoother.reset()
                self.kelvinSmoother.reset()
                self.tintSmoother.reset()
            }
        }
    }

    /// Captures the current frame as a UIImage asynchronously.
    func captureFrameAsync() async -> UIImage? {
        await sessionActor.captureFrame()
    }

    // MARK: - Flicker Control Triggers

    /// Starts the real-time light safety check (high-speed sampling & exposure lock).
    func startFlickerCheck() {
        isCheckingFlicker = true
        flickerPercentage = 0.0
        flickerFrequency = 0.0
        flickerSafetyLevel = "Safe"
        flickerDescription = LocalizedStrings.translate(key: "ui_flicker_calibrating", language: appLanguage)
        waveData = []

        Task { [sessionActor] in
            // Lock camera exposure to prevent auto-gain from smoothing oscillations
            await sessionActor.lockCameraExposure(locked: true)
            // Configure highest supported frame rate format (120 or 240 fps)
            await sessionActor.enableHighFrameRateMode(active: true)
        }
    }

    /// Stops the flicker check and returns the camera device to standard 30fps auto mode.
    func stopFlickerCheck() {
        isCheckingFlicker = false
        waveData = []

        Task { [sessionActor] in
            // Unlock exposure and restore auto frame rate
            await sessionActor.lockCameraExposure(locked: false)
            await sessionActor.enableHighFrameRateMode(active: false)
        }
    }

    // MARK: - Records Management

    /// Persists a new light measurement record based on current values and app language.
    func saveRecord(lux: Double, kelvin: Double) {
        let index = LuxRange.rangeIndex(for: lux)
        let chips = Array(ActivityChip.activeChips(for: index))
        let newRecord = LightRecord(lux: lux, kelvin: kelvin, timestamp: Date(), activeChips: chips)
        
        records.insert(newRecord, at: 0)
        saveRecordsToDisk()
    }

    /// Deletes a saved record.
    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        saveRecordsToDisk()
    }

    private func saveRecordsToDisk() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: Self.recordsKey)
        } catch {
            print("Failed to save records: \(error)")
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: Self.recordsKey) else { return }
        do {
            records = try JSONDecoder().decode([LightRecord].self, from: data)
        } catch {
            print("Failed to load records: \(error)")
        }
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
