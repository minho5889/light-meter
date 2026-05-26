@preconcurrency import CoreImage
import UIKit
import VideoToolbox

/// Thread-safe image processor that encapsulates CIContext rendering.
/// Reuses a single CIContext for optimal memory and GPU execution.
final class ImageProcessor: @unchecked Sendable {
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Converts a CVPixelBuffer into a UIImage safely.
    func convertToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }
}
