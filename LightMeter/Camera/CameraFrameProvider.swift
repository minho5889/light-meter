@preconcurrency import AVFoundation
import CoreImage
import UIKit

/// Effects-layer class responsible for sample buffer delegation, Y-plane luminance extraction,
/// and coordination of real-time flicker and light calculations.
final class CameraFrameProvider: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, Sendable {
    private let sessionActor: CameraSessionActor
    private let onFrameUpdate: @Sendable (Double, Double) -> Void
    private let onFlickerUpdate: @Sendable (FlickerResult, [Float]) -> Void

    // Rolling sample buffer and frame counter, accessed strictly on the serial delegate queue.
    private nonisolated(unsafe) var rollingSamples: [Float] = []
    private nonisolated(unsafe) var frameCounter = 0

    init(
        sessionActor: CameraSessionActor,
        onFrameUpdate: @escaping @Sendable (Double, Double) -> Void,
        onFlickerUpdate: @escaping @Sendable (FlickerResult, [Float]) -> Void
    ) {
        self.sessionActor = sessionActor
        self.onFrameUpdate = onFrameUpdate
        self.onFlickerUpdate = onFlickerUpdate
        super.init()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 1. Securely transfer ownership of the pixel buffer to the session actor for standard captures
        Task { [sessionActor] in
            await sessionActor.updateLatestPixelBuffer(pixelBuffer)
        }

        // 2. Extract standard exposure metadata for Lux and Kelvin calculations
        guard let deviceInput = connection.inputPorts.first?.input as? AVCaptureDeviceInput else {
            return
        }
        let device = deviceInput.device

        let iso = device.iso
        let exposureDurationInSeconds = CMTimeGetSeconds(device.exposureDuration)
        let aperture = Double(device.lensAperture)
        let gains = device.deviceWhiteBalanceGains
        let rawKelvin = Double(device.temperatureAndTintValues(for: gains).temperature)

        let luxValue = LuxCalculator.calculateLux(
            iso: iso,
            exposureDurationInSeconds: exposureDurationInSeconds,
            aperture: aperture
        )

        let kelvinValue = ColorTemperatureCalculator.calculateColorTemperature(
            rawKelvin: rawKelvin
        )

        onFrameUpdate(luxValue, kelvinValue)

        // 3. Extract Y-plane (Luminance) of the central 128x128 window for real-time light flicker check
        guard CVPixelBufferIsPlanar(pixelBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let yBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)

        // Center 128x128 Region of Interest (ROI)
        let roiWidth = 128
        let roiHeight = 128
        let startX = max(0, (width - roiWidth) / 2)
        let startY = max(0, (height - roiHeight) / 2)

        var sum: UInt64 = 0
        let yPointer = yBaseAddress.assumingMemoryBound(to: UInt8.self)

        for y in 0..<roiHeight {
            let rowStart = (startY + y) * bytesPerRow + startX
            for x in 0..<roiWidth {
                sum += UInt64(yPointer[rowStart + x])
            }
        }

        // Standardize Y brightness [0, 255] as a normalized float [0.0, 1.0]
        let averageLuminance = Float(sum) / Float(roiWidth * roiHeight * 255)

        // 4. Feed rolling buffer and run the FFT digital signal analysis
        rollingSamples.append(averageLuminance)
        if rollingSamples.count > FlickerAnalyzer.bufferSize {
            rollingSamples.removeFirst()
        }

        frameCounter += 1

        // Perform frequency analysis once the buffer is full, throttled to 8Hz updates at 240fps
        // (every 30 frames) to minimize CPU load while keeping UI animations perfectly fluid.
        if rollingSamples.count == FlickerAnalyzer.bufferSize && frameCounter % 30 == 0 {
            let activeSamples = rollingSamples
            
            // Read active hardware frame rate dynamically
            let minDuration = device.activeVideoMinFrameDuration
            let sampleRate = Float(minDuration.timescale) / Float(minDuration.value)
            
            if let result = FlickerAnalyzer.analyze(samples: activeSamples, sampleRate: sampleRate) {
                // Slice the last 60 samples to represent the real-time oscilloscope wave
                let waveSamples = Array(activeSamples.suffix(60))
                onFlickerUpdate(result, waveSamples)
            }
        }
    }
}
