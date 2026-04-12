import AVFoundation
import SwiftUI
import CoreImage

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var lux: Double = 0.0
    @Published var colorTemperature: Double = 0.0
    @Published var cameraError: String? = nil
    @Published var permissionGranted: Bool = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back

    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    private nonisolated(unsafe) let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private nonisolated(unsafe) var captureDevice: AVCaptureDevice?
    private nonisolated(unsafe) var latestSampleBuffer: CMSampleBuffer?

    /// Exposes the capture session for CameraPreviewView to connect.
    nonisolated var session: AVCaptureSession { captureSession }

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

    func setupSession() {
        let position = currentCameraPosition
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: position
            ) else {
                Task { @MainActor in
                    self.cameraError = "Back camera is not available on this device."
                }
                return
            }

            self.captureDevice = device

            self.captureSession.beginConfiguration()

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    Task { @MainActor in
                        self.cameraError = "Unable to add camera input to session."
                    }
                    self.captureSession.commitConfiguration()
                    return
                }
                self.captureSession.addInput(input)
            } catch {
                let message = error.localizedDescription
                Task { @MainActor in
                    self.cameraError = "Camera setup failed: \(message)"
                }
                self.captureSession.commitConfiguration()
                return
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.sessionQueue)

            guard self.captureSession.canAddOutput(output) else {
                Task { @MainActor in
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

    /// Returns a UIImage from the latest video sample buffer, or nil if unavailable.
    nonisolated func captureFrame() -> UIImage? {
        guard let sampleBuffer = latestSampleBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    /// Switches the active camera input between front and rear.
    /// If the target camera is unavailable, retains the current input silently.
    func toggleCamera() {
        let currentPosition = currentCameraPosition
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back

            guard let newDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: newPosition
            ) else {
                return
            }

            self.captureSession.beginConfiguration()

            // Remove existing video input
            if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.captureDevice = newDevice
                    Task { @MainActor in
                        self.currentCameraPosition = newPosition
                    }
                }
            } catch {
                // Re-add the previous input if switching fails
                if let previousDevice = self.captureDevice,
                   let previousInput = try? AVCaptureDeviceInput(device: previousDevice),
                   self.captureSession.canAddInput(previousInput) {
                    self.captureSession.addInput(previousInput)
                }
            }

            self.captureSession.commitConfiguration()
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
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        latestSampleBuffer = sampleBuffer

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

        Task { @MainActor [weak self] in
            self?.lux = luxValue
            self?.colorTemperature = kelvinValue
        }
    }
}
