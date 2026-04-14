import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        // Apple's AVCam pattern: set session on main thread.
        // The preview layer handles an unconfigured session gracefully —
        // it shows nothing until the session starts running.
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        // No-op: layout is handled by layoutSubviews via layerClass override
    }
}

/// UIView whose backing layer is AVCaptureVideoPreviewLayer.
/// This is the pattern Apple uses in their AVCam sample code.
class VideoPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
