import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var lux: Double = 0.0
    @Published var colorTemperature: Double = 0.0
    @Published var cameraError: String? = nil
    @Published var permissionGranted: Bool = false

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var captureDevice: AVCaptureDevice?

    /// Exposes the capture session for CameraPreviewView to connect.
    var session: AVCaptureSession { captureSession }

    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if granted {
                    self?.setupSession()
                }
            }
        }
    }

    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back
            ) else {
                DispatchQueue.main.async {
                    self.cameraError = "Back camera is not available on this device."
                }
                return
            }

            self.captureDevice = device

            self.captureSession.beginConfiguration()

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    DispatchQueue.main.async {
                        self.cameraError = "Unable to add camera input to session."
                    }
                    self.captureSession.commitConfiguration()
                    return
                }
                self.captureSession.addInput(input)
            } catch {
                DispatchQueue.main.async {
                    self.cameraError = "Camera setup failed: \(error.localizedDescription)"
                }
                self.captureSession.commitConfiguration()
                return
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.sessionQueue)

            guard self.captureSession.canAddOutput(output) else {
                DispatchQueue.main.async {
                    self.cameraError = "Unable to add video output to session."
                }
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addOutput(output)
            self.captureSession.commitConfiguration()

            self.startSession()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let device = captureDevice else { return }

        let iso = device.iso
        let exposureDuration = device.exposureDuration
        let gains = device.deviceWhiteBalanceGains

        let luxValue = LuxCalculator.calculateLux(
            iso: iso,
            exposureDuration: exposureDuration
        )

        let kelvinValue = ColorTemperatureCalculator.calculateColorTemperature(
            gains: gains,
            device: device
        )

        DispatchQueue.main.async { [weak self] in
            self?.lux = luxValue
            self?.colorTemperature = kelvinValue
        }
    }
}
