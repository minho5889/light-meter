//
//  LMDesign.swift
//  LightMeter
//
//  Design-system namespace for the "Light Meter" redesign.
//
//  Tokens are derived 1:1 from the Figma spec (/tmp/figma_spec.json):
//    palette, gradients, cornerRadii, blurs, textStyles.
//
//  Typography note: the Figma design uses "Inter" (weights 400/500/600/700).
//  Inter is not a system font on iOS, so as a faithful substitute we use the
//  SF Rounded system face (.system(... design: .rounded)). To match the design
//  exactly, bundle the Inter .otf/.ttf files, register them in Info.plist under
//  `UIAppFonts`, and swap `LM.font(...)` to return `.custom("Inter", ...)`.
//
//  Pixel sizes in the spec are @3x. Point sizes used here are spec_px / 3
//  (e.g. display 150px → 50pt, h1 ~54px → 18pt, h2 48px → 16pt, etc.).
//

import SwiftUI

// MARK: - LM Namespace

/// Design-system namespace for the Light Meter redesign (iOS 17+).
enum LM {

    // MARK: Palette

    /// Primary text — `#4C4C4C`.
    static let textPrimary = Color(hex: 0x4C4C4C)
    /// Secondary text — `#656565`.
    static let textSecondary = Color(hex: 0x656565)

    /// Strong frosted glass tint — `#FAFAFA` @ 0.7.
    static let glassTintStrong = Color(hex: 0xFAFAFA, alpha: 0.7)
    /// Medium frosted glass tint — `#FAFAFA` @ 0.5.
    static let glassTintMed = Color(hex: 0xFAFAFA, alpha: 0.5)
    /// Soft frosted glass tint — `#FAFAFA` @ 0.3.
    static let glassTintSoft = Color(hex: 0xFAFAFA, alpha: 0.3)

    /// Subtle white hairline / inner stroke — `#FFFFFF` low alpha.
    static let hairline = Color(hex: 0xFFFFFF, alpha: 0.25)

    /// Top stop of the records gradient — `#FAFAFA`.
    static let recordBgTop = Color(hex: 0xFAFAFA)
    /// Bottom stop of the records gradient — `#B5B5B5`.
    static let recordBgBottom = Color(hex: 0xB5B5B5)

    /// Destructive / delete tint — `#A43333` @ 0.2.
    static let deleteTint = Color(hex: 0xA43333, alpha: 0.2)

    // MARK: Readout card (Figma spec)

    /// Readout card glass fill — Figma "BG #2C2C2C @ 20%": a dark frosted tint
    /// laid over the camera so the near-white text reads.
    static let readoutGlass = Color(hex: 0x2C2C2C, alpha: 0.20)
    /// Readout card text — Figma "#FAFAFA" (near-white) for all card copy.
    static let readoutText = Color(hex: 0xFAFAFA)
    /// Big lux number — "#FAFAFA + Gradation": a subtle top→bottom sheen.
    static let readoutNumberGradient = LinearGradient(
        colors: [Color(hex: 0xFAFAFA), Color(hex: 0xFAFAFA, alpha: 0.70)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: Gradients

    /// `GRADIENT_LINEAR:#FAFAFA>#B5B5B5` — records card background (top → bottom).
    static let recordsGradient = LinearGradient(
        colors: [recordBgTop, recordBgBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    /// `GRADIENT_LINEAR:#FFFFFF@0.0>#000000` — scrim from clear white to black.
    static let scrimGradient = LinearGradient(
        colors: [Color(hex: 0xFFFFFF, alpha: 0.0), Color(hex: 0x000000)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: Material

    /// Frosted material used behind glass surfaces.
    static let glass: Material = .ultraThinMaterial

    // MARK: Corner Radii

    /// Card / panel corner radius (spec `24.0`).
    static let cardRadius: CGFloat = 24
    /// Pill / capsule control corner radius (spec `~28`).
    static let pillRadius: CGFloat = 28
    /// Large circular button diameter (shutter / FAB).
    static let buttonCircle: CGFloat = 72

    // MARK: Spacing

    /// Standard content padding.
    static let pad: CGFloat = 16
    /// Standard gap between elements.
    static let gap: CGFloat = 12

    // MARK: Typography

    /// Inter (the typeface the Figma design uses), bundled in
    /// `LightMeter/Redesign/Fonts/`. The static OTFs are registered via
    /// `UIAppFonts` in Info.plist. PostScript names: `Inter-Regular`,
    /// `Inter-Medium`, `Inter-SemiBold`, `Inter-Bold`. Falls back to the system
    /// face if a weight is not registered (e.g. CJK glyphs use the system font).
    /// - Parameters:
    ///   - size: Point size.
    ///   - weight: Font weight (default `.regular`).
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black:    name = "Inter-Bold"
        case .semibold:                name = "Inter-SemiBold"
        case .medium:                  name = "Inter-Medium"
        default:                       name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }

    /// Named type sizes (spec @3px / 3).
    enum FontSize {
        /// Hero readout (e.g. "120"). 150px → 50pt.
        static let display: CGFloat = 50
        /// Section heading. 54px → 18pt.
        static let h1: CGFloat = 18
        /// Sub heading. 48px → 16pt.
        static let h2: CGFloat = 16
        /// Body text. 42px → 14pt.
        static let body: CGFloat = 14
        /// Caption. 36px → 12pt.
        static let caption: CGFloat = 12
        /// Micro label. 33px → 11pt.
        static let micro: CGFloat = 11
    }
}

// MARK: - Color(hex:) Helper

extension Color {
    /// Initialize from a 24-bit RGB hex value (e.g. `0x4C4C4C`).
    /// - Parameters:
    ///   - hex: 24-bit `0xRRGGBB` value.
    ///   - alpha: Opacity in `0...1` (default `1`).
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - LMGlass ViewModifier

/// Frosted-glass surface: `.ultraThinMaterial` + soft white tint, clipped to a
/// rounded rectangle, with a subtle white hairline stroke.
struct LMGlass: ViewModifier {
    var cornerRadius: CGFloat = LM.cardRadius
    /// Tint laid over the material (default: medium `#FAFAFA` @ 0.5).
    var tint: Color = LM.glassTintMed

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background {
                shape
                    .fill(LM.glass)
                    .overlay { shape.fill(tint) }
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(LM.hairline, lineWidth: 1)
            }
            // Soft float so glass reads over any camera scene and lifts off the
            // records gradient, matching the Figma's elevated cards.
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 5)
    }
}

extension View {
    /// Apply the standard Light Meter frosted-glass treatment.
    /// - Parameters:
    ///   - cornerRadius: Corner radius (default `LM.cardRadius`).
    ///   - tint: Overlay tint (default `LM.glassTintMed`).
    func lmGlass(
        cornerRadius: CGFloat = LM.cardRadius,
        tint: Color = LM.glassTintMed
    ) -> some View {
        modifier(LMGlass(cornerRadius: cornerRadius, tint: tint))
    }
}

// MARK: - Preview

#Preview("LM Tokens") {
    ZStack {
        LM.recordsGradient.ignoresSafeArea()
        VStack(spacing: LM.gap) {
            VStack(alignment: .leading, spacing: 4) {
                Text("120")
                    .font(LM.font(LM.FontSize.display, .bold))
                    .foregroundStyle(LM.textPrimary)
                Text("3,800K")
                    .font(LM.font(LM.FontSize.h2))
                    .foregroundStyle(LM.textSecondary)
            }
            .padding(LM.pad)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lmGlass()

            HStack(spacing: LM.gap) {
                Text("Brightness")
                    .font(LM.font(LM.FontSize.caption, .medium))
                    .foregroundStyle(LM.textPrimary)
                    .padding(.horizontal, LM.pad)
                    .padding(.vertical, LM.gap)
                    .lmGlass(cornerRadius: LM.pillRadius)

                Text("Delete")
                    .font(LM.font(LM.FontSize.caption, .medium))
                    .foregroundStyle(LM.textPrimary)
                    .padding(.horizontal, LM.pad)
                    .padding(.vertical, LM.gap)
                    .lmGlass(cornerRadius: LM.pillRadius, tint: LM.deleteTint)
            }
        }
        .padding(LM.pad)
    }
}
