@preconcurrency import AVFoundation
import CoreImage
import UIKit

/// Effects-layer class responsible for sample buffer delegation,
/// latest buffer storage, frame capture, and lux/kelvin computation dispatch.
final class CameraFrameProvider: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    /// Stores the latest sample buffer for frame capture.
    private nonisolated(unsafe) var latestSampleBuffer: CMSampleBuffer?

    /// Reference to the capture device for reading ISO, exposure, white balance.
    /// Set by CameraViewModel after session setup.
    nonisolated(unsafe) var captureDevice: AVCaptureDevice?

    /// Called with (lux, colorTemperature) on each frame.
    var onFrameUpdate: (@Sendable (Double, Double) -> Void)?

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        latestSampleBuffer = sampleBuffer

        guard let device = captureDevice else { return }

        let iso = device.iso
        let exposureDurationInSeconds = CMTimeGetSeconds(device.exposureDuration)
        let gains = device.deviceWhiteBalanceGains
        let rawKelvin = Double(device.temperatureAndTintValues(for: gains).temperature)

        let luxValue = LuxCalculator.calculateLux(
            iso: iso,
            exposureDurationInSeconds: exposureDurationInSeconds
        )

        let kelvinValue = ColorTemperatureCalculator.calculateColorTemperature(
            rawKelvin: rawKelvin
        )

        onFrameUpdate?(luxValue, kelvinValue)
    }

    // MARK: - Frame Capture

    /// Returns a UIImage from the latest sample buffer, or nil if unavailable.
    func captureFrame() -> UIImage? {
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
}
