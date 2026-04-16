@preconcurrency import AVFoundation

/// Effects-layer class responsible for AVCaptureSession lifecycle:
/// session configuration, input/output setup, start, stop, and camera toggling.
final class CameraSessionManager: @unchecked Sendable {
    private nonisolated(unsafe) let captureSession = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private nonisolated(unsafe) var captureDevice: AVCaptureDevice?
    private nonisolated(unsafe) var currentPosition: AVCaptureDevice.Position = .back

    /// Exposes the capture session for CameraPreviewView.
    var session: AVCaptureSession { captureSession }

    /// Called when a session configuration error occurs.
    var onError: (@Sendable (String) -> Void)?

    /// Configures the session with input/output for the given camera position.
    /// Sets the provided delegate on the video data output.
    func setupSession(
        position: AVCaptureDevice.Position,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        completion: (@Sendable () -> Void)? = nil
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.currentPosition = position

            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: position
            ) else {
                self.onError?("Back camera is not available on this device.")
                return
            }

            self.captureDevice = device

            self.captureSession.beginConfiguration()

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    self.onError?("Unable to add camera input to session.")
                    self.captureSession.commitConfiguration()
                    return
                }
                self.captureSession.addInput(input)
            } catch {
                let message = error.localizedDescription
                self.onError?("Camera setup failed: \(message)")
                self.captureSession.commitConfiguration()
                return
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(delegate, queue: self.sessionQueue)

            guard self.captureSession.canAddOutput(output) else {
                self.onError?("Unable to add video output to session.")
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addOutput(output)
            self.captureSession.commitConfiguration()

            self.startSessionOnQueue()
            completion?()
        }
    }

    /// Starts the capture session on the session queue.
    /// Guards against redundant dispatches when the session is already running.
    func startSession() {
        guard !captureSession.isRunning else { return }
        sessionQueue.async { [weak self] in
            self?.startSessionOnQueue()
        }
    }

    /// Stops the capture session on the session queue.
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    /// Toggles between front and rear cameras.
    /// Reports the new position via the completion handler on success.
    func toggleCamera(completion: @escaping @Sendable (AVCaptureDevice.Position) -> Void) {
        let position = currentPosition
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let newPosition: AVCaptureDevice.Position = (position == .back) ? .front : .back

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
                    self.currentPosition = newPosition
                    completion(newPosition)
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

    /// Returns the current capture device (needed by CameraFrameProvider for metadata).
    var device: AVCaptureDevice? { captureDevice }

    // MARK: - Private

    private func startSessionOnQueue() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
}
