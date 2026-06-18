//
//  LMImage.swift
//  LightMeter
//
//  Image helpers for record snapshots: downscale-to-JPEG when a capture is
//  saved, and a memory-friendly downsampled decode for list thumbnails.
//

import UIKit
import ImageIO

enum LMImage {
    /// Resize `image` so its largest side is at most `maxDimension`, then encode
    /// as JPEG. Keeps stored snapshots small (~a couple hundred KB).
    static func jpegData(_ image: UIImage, maxDimension: CGFloat = 1280, quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: quality)
    }

    /// Decode `data` into a UIImage downsampled so its largest side ≈ `maxPixel`,
    /// keeping memory low for list cards.
    static func downsample(_ data: Data, maxPixel: CGFloat) -> UIImage? {
        let srcOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let src = CGImageSourceCreateWithData(data as CFData, srcOptions) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }
}
