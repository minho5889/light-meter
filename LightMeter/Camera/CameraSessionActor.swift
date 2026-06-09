@preconcurrency import AVFoundation
import UIKit
import os

struct SendablePixelBuffer: @unchecked Sendable {
    let buffer: CVPixelBuffer
}

/// Effects-layer actor responsible for AVCaptureSession lifecycle:
/// session configuration, input/output setup, start, stop, camera toggling, and frame storage.
actor CameraSessionActor {
    /// Exposes the capture session for preview nonisolatedly as an immutable let constant.
    nonisolated let session = AVCaptureSession()
    
    private var captureDevice: AVCaptureDevice?
    private var currentPosition: AVCaptureDevice.Position = .back
    private nonisolated let latestBufferLock = OSAllocatedUnfairLock<SendablePixelBuffer?>(initialState: nil)
    
    /// Reusable thread-safe ImageProcessor for converting buffer to UIImage.
    private nonisolated let imageProcessor = ImageProcessor()

    /// Private serial dispatch queue for offloading blocking AVCaptureSession operations
    /// (startRunning, stopRunning) off the Swift cooperative pool to prevent deadlock.
    private let hardwareQueue = DispatchQueue(label: "camera.hardware.blocking.queue")

    /// Exposes the session queue for the sample buffer output.
    nonisolated let sessionQueue = DispatchQueue(label: "camera.session.queue")

    /// Called when a session configuration error occurs.
    /// Since callbacks must cross actor boundaries, it is typed as Sendable.
    private var onError: (@Sendable (String) -> Void)?

    /// Sets the error callback.
    func setOnError(_ callback: @escaping @Sendable (String) -> Void) {
        self.onError = callback
    }

    /// Configures the session with input/output for the given camera position.
    func setupSession(
        position: AVCaptureDevice.Position,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate
    ) {
        self.currentPosition = position

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: position
        ) else {
            self.onError?("Back camera is not available on this device.")
            return
        }

        self.captureDevice = device
        self.session.beginConfiguration()

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard self.session.canAddInput(input) else {
                self.onError?("Unable to add camera input to session.")
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)
        } catch {
            let message = error.localizedDescription
            self.onError?("Camera setup failed: \(message)")
            self.session.commitConfiguration()
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        output.setSampleBufferDelegate(delegate, queue: self.sessionQueue)

        guard self.session.canAddOutput(output) else {
            self.onError?("Unable to add video output to session.")
            self.session.commitConfiguration()
            return
        }
        self.session.addOutput(output)
        self.session.commitConfiguration()

        self.startSessionOnQueue()
    }

    /// Starts the capture session on the hardware queue.
    func startSession() {
        guard !session.isRunning else { return }
        hardwareQueue.async { [weak self] in
            Task { [weak self] in
                await self?.startSessionOnQueue()
            }
        }
    }

    /// Stops the capture session on the hardware queue.
    func stopSession() {
        hardwareQueue.async { [weak self] in
            Task { [weak self] in
                await self?.stopSessionOnQueue()
            }
        }
    }

    /// Toggles between front and rear cameras.
    func toggleCamera() -> AVCaptureDevice.Position? {
        let position = currentPosition
        let newPosition: AVCaptureDevice.Position = (position == .back) ? .front : .back

        guard let newDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: newPosition
        ) else {
            return nil
        }

        self.session.beginConfiguration()

        // Remove existing video input
        if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
            self.session.removeInput(currentInput)
        }

        var success = false
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.captureDevice = newDevice
                self.currentPosition = newPosition
                success = true
            }
        } catch {
            // Re-add the previous input if switching fails
            if let previousDevice = self.captureDevice,
               let previousInput = try? AVCaptureDeviceInput(device: previousDevice),
               self.session.canAddInput(previousInput) {
                self.session.addInput(previousInput)
            }
        }

        self.session.commitConfiguration()
        return success ? newPosition : nil
    }

    /// Exposes the current capture device.
    var device: AVCaptureDevice? { captureDevice }

    /// Sets high frame rate (preferring 240fps, falling back to 120fps, then 60fps) if active is true.
    /// Otherwise, resets to standard 30fps.
    func enableHighFrameRateMode(active: Bool) {
        guard let device = captureDevice else { return }
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            if active {
                // Find highest supported frame rate
                var bestFormat: AVCaptureDevice.Format? = nil
                var bestFrameRate: Float64 = 30.0
                
                for format in device.formats {
                    let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    // We want high-speed mode, preferring 720p or 1080p, and avoiding ultra-low resolution
                    guard dimensions.width >= 1280 && dimensions.height >= 720 else { continue }
                    
                    for range in format.videoSupportedFrameRateRanges {
                        if range.maxFrameRate > bestFrameRate {
                            bestFrameRate = range.maxFrameRate
                            bestFormat = format
                        }
                    }
                }
                
                if let targetFormat = bestFormat {
                    device.activeFormat = targetFormat
                    let duration = CMTime(value: 1, timescale: CMTimeScale(bestFrameRate))
                    device.activeVideoMinFrameDuration = duration
                    device.activeVideoMaxFrameDuration = duration
                }
            } else {
                // Reset frame duration range to standard 30fps min limit
                let duration = CMTime(value: 1, timescale: 30)
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
            }
        } catch {
            self.onError?("Failed to lock device for frame rate configuration: \(error.localizedDescription)")
        }
    }

    /// Locks exposure to prevent auto-gain from dampening physical flicker oscillation.
    func lockCameraExposure(locked: Bool) {
        guard let device = captureDevice else { return }
        guard device.isExposureModeSupported(locked ? .locked : .continuousAutoExposure) else { return }
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            device.exposureMode = locked ? .locked : .continuousAutoExposure
        } catch {
            self.onError?("Failed to lock device for exposure configuration: \(error.localizedDescription)")
        }
    }

    // MARK: - Safe Pixel Buffer Storage & Rendering

    /// Safely updates the latest pixel buffer.
    nonisolated func updateLatestPixelBuffer(_ buffer: CVPixelBuffer) {
        let wrapped = SendablePixelBuffer(buffer: buffer)
        latestBufferLock.withLock { $0 = wrapped }
    }

    /// Safely converts the stored buffer to UIImage.
    nonisolated func captureFrame() -> UIImage? {
        let sendable = latestBufferLock.withLock { $0 }
        guard let buffer = sendable?.buffer else { return nil }
        return imageProcessor.convertToUIImage(pixelBuffer: buffer)
    }

    // MARK: - Private Configuration

    private func startSessionOnQueue() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    private func stopSessionOnQueue() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}
