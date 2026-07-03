//
//  LMTabIcons.swift
//  LightMeter
//
//  Exact tab-bar icon shapes, generated mechanically from the designer's
//  exported Figma SVGs (Temperature_Icon.svg, 260623 sheet) — NOT hand-drawn
//  approximations. The path commands below are a verbatim translation of the
//  SVG path data; the mercury ball (a <circle>) and the mercury column (a
//  round-capped <line>, expressed here as a capsule) are added as filled
//  subpaths. Everything is one nonzero-fill path, so it tints via
//  foregroundStyle like any glyph.
//
//  Source coordinate space: the icon occupies x 55.73…93.34, y 0…62.54 of the
//  exported viewBox; `path(in:)` rescales that box into the given rect,
//  preserving aspect.
//

import SwiftUI

/// The Color-Temp tab's thermometer: outline tube + bulb, filled mercury
/// ball, and mid-height mercury column — exactly as designed.
struct LMColorTempIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        // — Thermometer outline (verbatim from the exported SVG) —
        p.move(to: CGPoint(x: 74.7734, y: 2.2681))
        p.addLine(to: CGPoint(x: 74.7734, y: -0.0000))
        p.addLine(to: CGPoint(x: 74.7733, y: -0.0000))
        p.addLine(to: CGPoint(x: 74.7734, y: 2.2681))
        p.closeSubpath()
        p.move(to: CGPoint(x: 83.0410, y: 29.5522))
        p.addLine(to: CGPoint(x: 80.7729, y: 29.5522))
        p.addLine(to: CGPoint(x: 80.7729, y: 30.8351))
        p.addLine(to: CGPoint(x: 81.8724, y: 31.4961))
        p.addLine(to: CGPoint(x: 83.0410, y: 29.5522))
        p.closeSubpath()
        p.move(to: CGPoint(x: 91.0684, y: 43.7329))
        p.addLine(to: CGPoint(x: 93.3365, y: 43.7330))
        p.addLine(to: CGPoint(x: 93.3365, y: 43.7329))
        p.addLine(to: CGPoint(x: 91.0684, y: 43.7329))
        p.closeSubpath()
        p.move(to: CGPoint(x: 74.5342, y: 60.2671))
        p.addLine(to: CGPoint(x: 74.5341, y: 62.5352))
        p.addLine(to: CGPoint(x: 74.5342, y: 62.5352))
        p.addLine(to: CGPoint(x: 74.5342, y: 60.2671))
        p.closeSubpath()
        p.move(to: CGPoint(x: 58.0000, y: 43.7329))
        p.addLine(to: CGPoint(x: 55.7319, y: 43.7329))
        p.addLine(to: CGPoint(x: 55.7319, y: 43.7330))
        p.addLine(to: CGPoint(x: 58.0000, y: 43.7329))
        p.closeSubpath()
        p.move(to: CGPoint(x: 66.5068, y: 29.2759))
        p.addLine(to: CGPoint(x: 67.6097, y: 31.2578))
        p.addLine(to: CGPoint(x: 68.7749, y: 30.6094))
        p.addLine(to: CGPoint(x: 68.7749, y: 29.2759))
        p.addLine(to: CGPoint(x: 66.5068, y: 29.2759))
        p.closeSubpath()
        p.move(to: CGPoint(x: 74.7734, y: 2.2681))
        p.addLine(to: CGPoint(x: 74.7734, y: 4.5362))
        p.addCurve(to: CGPoint(x: 80.7729, y: 10.5356), control1: CGPoint(x: 78.0867, y: 4.5362), control2: CGPoint(x: 80.7729, y: 7.2224))
        p.addLine(to: CGPoint(x: 83.0410, y: 10.5356))
        p.addLine(to: CGPoint(x: 85.3091, y: 10.5356))
        p.addCurve(to: CGPoint(x: 74.7734, y: -0.0000), control1: CGPoint(x: 85.3091, y: 4.7172), control2: CGPoint(x: 80.5919, y: -0.0000))
        p.addLine(to: CGPoint(x: 74.7734, y: 2.2681))
        p.closeSubpath()
        p.move(to: CGPoint(x: 83.0410, y: 10.5356))
        p.addLine(to: CGPoint(x: 80.7729, y: 10.5356))
        p.addLine(to: CGPoint(x: 80.7729, y: 29.5522))
        p.addLine(to: CGPoint(x: 83.0410, y: 29.5522))
        p.addLine(to: CGPoint(x: 85.3091, y: 29.5522))
        p.addLine(to: CGPoint(x: 85.3091, y: 10.5356))
        p.addLine(to: CGPoint(x: 83.0410, y: 10.5356))
        p.closeSubpath()
        p.move(to: CGPoint(x: 83.0410, y: 29.5522))
        p.addLine(to: CGPoint(x: 81.8724, y: 31.4961))
        p.addCurve(to: CGPoint(x: 88.8003, y: 43.7329), control1: CGPoint(x: 86.0281, y: 33.9945), control2: CGPoint(x: 88.8003, y: 38.5410))
        p.addLine(to: CGPoint(x: 91.0684, y: 43.7329))
        p.addLine(to: CGPoint(x: 93.3365, y: 43.7329))
        p.addCurve(to: CGPoint(x: 84.2096, y: 27.6084), control1: CGPoint(x: 93.3365, y: 36.8838), control2: CGPoint(x: 89.6730, y: 30.8928))
        p.addLine(to: CGPoint(x: 83.0410, y: 29.5522))
        p.closeSubpath()
        p.move(to: CGPoint(x: 91.0684, y: 43.7329))
        p.addLine(to: CGPoint(x: 88.8003, y: 43.7328))
        p.addCurve(to: CGPoint(x: 74.5342, y: 57.9990), control1: CGPoint(x: 88.8000, y: 51.6117), control2: CGPoint(x: 82.4129, y: 57.9990))
        p.addLine(to: CGPoint(x: 74.5342, y: 60.2671))
        p.addLine(to: CGPoint(x: 74.5342, y: 62.5352))
        p.addCurve(to: CGPoint(x: 93.3365, y: 43.7330), control1: CGPoint(x: 84.9183, y: 62.5352), control2: CGPoint(x: 93.3362, y: 54.1169))
        p.addLine(to: CGPoint(x: 91.0684, y: 43.7329))
        p.closeSubpath()
        p.move(to: CGPoint(x: 74.5342, y: 60.2671))
        p.addLine(to: CGPoint(x: 74.5342, y: 57.9990))
        p.addCurve(to: CGPoint(x: 60.2681, y: 43.7328), control1: CGPoint(x: 66.6555, y: 57.9989), control2: CGPoint(x: 60.2683, y: 51.6116))
        p.addLine(to: CGPoint(x: 58.0000, y: 43.7329))
        p.addLine(to: CGPoint(x: 55.7319, y: 43.7330))
        p.addCurve(to: CGPoint(x: 74.5341, y: 62.5352), control1: CGPoint(x: 55.7322, y: 54.1168), control2: CGPoint(x: 64.1502, y: 62.5350))
        p.addLine(to: CGPoint(x: 74.5342, y: 60.2671))
        p.closeSubpath()
        p.move(to: CGPoint(x: 58.0000, y: 43.7329))
        p.addLine(to: CGPoint(x: 60.2681, y: 43.7329))
        p.addCurve(to: CGPoint(x: 67.6097, y: 31.2578), control1: CGPoint(x: 60.2681, y: 38.3711), control2: CGPoint(x: 63.2260, y: 33.6972))
        p.addLine(to: CGPoint(x: 66.5068, y: 29.2759))
        p.addLine(to: CGPoint(x: 65.4039, y: 27.2940))
        p.addCurve(to: CGPoint(x: 55.7319, y: 43.7329), control1: CGPoint(x: 59.6407, y: 30.5011), control2: CGPoint(x: 55.7319, y: 36.6585))
        p.addLine(to: CGPoint(x: 58.0000, y: 43.7329))
        p.closeSubpath()
        p.move(to: CGPoint(x: 66.5068, y: 29.2759))
        p.addLine(to: CGPoint(x: 68.7749, y: 29.2759))
        p.addLine(to: CGPoint(x: 68.7749, y: 10.5356))
        p.addLine(to: CGPoint(x: 66.5068, y: 10.5356))
        p.addLine(to: CGPoint(x: 64.2387, y: 10.5356))
        p.addLine(to: CGPoint(x: 64.2387, y: 29.2759))
        p.addLine(to: CGPoint(x: 66.5068, y: 29.2759))
        p.closeSubpath()
        p.move(to: CGPoint(x: 66.5068, y: 10.5356))
        p.addLine(to: CGPoint(x: 68.7749, y: 10.5356))
        p.addCurve(to: CGPoint(x: 74.7735, y: 4.5362), control1: CGPoint(x: 68.7749, y: 7.2223), control2: CGPoint(x: 71.4606, y: 4.5363))
        p.addLine(to: CGPoint(x: 74.7734, y: 2.2681))
        p.addLine(to: CGPoint(x: 74.7733, y: -0.0000))
        p.addCurve(to: CGPoint(x: 64.2387, y: 10.5356), control1: CGPoint(x: 68.9548, y: 0.0002), control2: CGPoint(x: 64.2387, y: 4.7175))
        p.addLine(to: CGPoint(x: 66.5068, y: 10.5356))
        p.closeSubpath()

        // — Mercury ball (SVG <circle cx=74.5354 cy=44.2625 r=9.1858>) —
        p.addEllipse(in: CGRect(x: 74.5354 - 9.1858, y: 44.2625 - 9.1858,
                                width: 9.1858 * 2, height: 9.1858 * 2))

        // — Mercury column (round-capped line x=74.5352, y 18.5464…36.918,
        //   width 3.67432 → drawn as a capsule) —
        let half = 3.67432 / 2
        p.addRoundedRect(
            in: CGRect(x: 74.5352 - half, y: 18.5464 - half,
                       width: 3.67432, height: (36.918 - 18.5464) + 3.67432),
            cornerSize: CGSize(width: half, height: half))

        // — Fit the source bbox into `rect`, preserving aspect —
        let bbox = CGRect(x: 55.7319, y: 0, width: 37.6046, height: 62.5352)
        let scale = min(rect.width / bbox.width, rect.height / bbox.height)
        let transform = CGAffineTransform(
            translationX: rect.midX - bbox.midX * scale,
            y: rect.midY - bbox.midY * scale
        ).scaledBy(x: scale, y: scale)
        return p.applying(transform)
    }
}

/// The Records tab icon: a thin outer ring around a large filled disc.
/// Ratios measured from the designer's btn_nav.png export (icon 52px):
/// outer ring Ø 52px with a 3px stroke, inner filled disc Ø 35px.
/// SF Symbol "record.circle" is the same idea but its disc is noticeably
/// smaller relative to the ring, so this is drawn directly.
struct LMRecordsIcon: View {
    var size: CGFloat = 18

    var body: some View {
        let ringStroke = size * (3.0 / 52.0)
        let ringCenterline = size - ringStroke   // outer edge = full size
        let disc = size * (35.0 / 52.0)
        ZStack {
            Circle()
                .stroke(lineWidth: ringStroke)
                .frame(width: ringCenterline, height: ringCenterline)
            Circle()
                .frame(width: disc, height: disc)
        }
        .frame(width: size, height: size)
    }
}

#Preview("LMColorTempIcon") {
    ZStack {
        Color(hex: 0x2C2C2C).ignoresSafeArea()
        VStack(spacing: 24) {
            LMColorTempIcon()
                .frame(width: 18, height: 18)
            LMColorTempIcon()
                .frame(width: 60, height: 60)
        }
        .foregroundStyle(.white)
    }
}
