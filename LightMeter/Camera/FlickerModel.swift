import Foundation
import Observation
import AVFoundation

/// Model that isolates flicker safety checking, percentage, frequency,
/// risk rating calculations, and wave scopes.
@Observable
@MainActor
final class FlickerModel {
    var flickerPercentage: Double = 0.0
    var flickerFrequency: Double = 0.0
    var flickerSafetyLevel: String = "Safe"
    var flickerDescription: String = "Tap start check to analyze."
    var isCheckingFlicker: Bool = false
    var waveData: [Float] = []

    init() {}

    func start(sessionActor: CameraSessionActor, language: AppLanguage) {
        isCheckingFlicker = true
        flickerPercentage = 0.0
        flickerFrequency = 0.0
        flickerSafetyLevel = "Safe"
        flickerDescription = LocalizedStrings.translate(key: "ui_flicker_calibrating", language: language)
        waveData = []

        Task {
            await sessionActor.lockCameraExposure(locked: true)
            await sessionActor.enableHighFrameRateMode(active: true)
        }
    }

    func stop(sessionActor: CameraSessionActor) {
        isCheckingFlicker = false
        waveData = []

        Task {
            await sessionActor.lockCameraExposure(locked: false)
            await sessionActor.enableHighFrameRateMode(active: false)
        }
    }

    func update(result: FlickerResult, waveSamples: [Float], language: AppLanguage) {
        guard isCheckingFlicker else { return }
        self.flickerPercentage = result.percentage
        self.flickerFrequency = result.frequency
        self.flickerSafetyLevel = result.safetyLevel
        if result.description == "No light detected." {
            self.flickerDescription = LocalizedStrings.translate(key: "ui_no_light", language: language)
        } else {
            self.flickerDescription = FlickerInterpreter.description(
                level: result.safetyLevel,
                nyquist: result.nyquist,
                language: language
            )
        }
        self.waveData = waveSamples
    }

    func updateDescription(language: AppLanguage) {
        if !isCheckingFlicker {
            flickerDescription = LocalizedStrings.translate(key: "ui_flicker_ready_desc", language: language)
        }
    }
}
