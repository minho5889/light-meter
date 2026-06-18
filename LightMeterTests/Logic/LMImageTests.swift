import Testing
import UIKit
@testable import LightMeter

struct LMImageTests {

    private func solidImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    // MARK: - Known value

    @Test func jpegRespectsMaxDimension() {
        let data = LMImage.jpegData(solidImage(width: 4000, height: 3000), maxDimension: 1280, quality: 0.7)
        #expect(data != nil)
        if let data, let out = UIImage(data: data) {
            #expect(max(out.size.width, out.size.height) <= 1281)  // 1280 + rounding slack
        }
    }

    // MARK: - Property: downsample never exceeds the requested max pixel size

    @Test func property_downsampleBounded() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            let w = CGFloat(Int.random(in: 200...3000, using: &rng))
            let h = CGFloat(Int.random(in: 200...3000, using: &rng))
            let maxPixel = CGFloat(Int.random(in: 100...1200, using: &rng))
            guard let data = LMImage.jpegData(solidImage(width: w, height: h), maxDimension: 4000, quality: 0.8) else {
                Issue.record("jpegData returned nil")
                continue
            }
            if let out = LMImage.downsample(data, maxPixel: maxPixel) {
                // UIImage(cgImage:) is scale 1, so size == pixels.
                #expect(max(out.size.width, out.size.height) <= maxPixel + 1)
            }
        }
    }

    // MARK: - Property: a degenerate (zero-size) image is handled, not crashed

    @Test func zeroSizeImageReturnsNil() {
        #expect(LMImage.jpegData(solidImage(width: 0, height: 0), maxDimension: 1280, quality: 0.7) == nil)
    }
}
