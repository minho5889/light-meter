import CoreGraphics
import SwiftUI

enum DesignConstants {
    // Font sizes
    static let fontSizeXXL: CGFloat = 48
    static let fontSizeXL: CGFloat = 22
    static let fontSizeTitle: CGFloat = 24
    static let fontSizeLG: CGFloat = 20
    static let fontSizeMD: CGFloat = 18
    static let fontSizeSM: CGFloat = 16
    static let fontSizeXS: CGFloat = 14
    static let fontSizeXXS: CGFloat = 13
    static let fontSizeXXXS: CGFloat = 12

    // Dynamic Type-scalable fonts
    static let fontXXL: Font = .system(.largeTitle, design: .rounded).weight(.bold)
    static let fontXL: Font = .system(.title2, design: .default).weight(.medium)
    static let fontTitle: Font = .system(.title2, design: .default).weight(.bold)
    static let fontLG: Font = .system(.title3, design: .default).weight(.bold)
    static let fontMD: Font = .system(.headline, design: .default)
    static let fontSM: Font = .system(.body, design: .default)
    static let fontXS: Font = .system(.subheadline, design: .default)
    static let fontXXS: Font = .system(.footnote, design: .default)
    static let fontXXXS: Font = .system(.caption, design: .default)

    // Spacing
    static let spacingLG: CGFloat = 40
    static let spacingMD: CGFloat = 24
    static let spacingSM: CGFloat = 12
    static let spacingXS: CGFloat = 8

    // Component dimensions
    static let captureButtonOuter: CGFloat = 70
    static let captureButtonInner: CGFloat = 58
    static let toggleButtonSize: CGFloat = 44
}

