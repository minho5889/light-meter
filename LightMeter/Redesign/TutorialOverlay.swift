//
//  TutorialOverlay.swift
//  LightMeter
//
//  A "hand-drawn" spotlight onboarding walkthrough for Regular mode. It feels
//  like someone is annotating the screen with a marker:
//    • dims the whole screen, punching a bright spotlight over one element,
//    • scribbles a slightly wobbly marker loop around it (overshooting like a
//      real pen circle), then sketches a hand-drawn arrow pointing at it,
//    • writes the note in on a glass caption card — the heading in a
//      handwriting face, the body typed out — with Next / Skip / progress dots.
//
//  Usage: tag elements with `.tutorialAnchor(.readout)` etc., then host
//  `TutorialOverlay` via `.overlayPreferenceValue(TutorialAnchorKey.self)`.
//

import SwiftUI

// MARK: - Targets

/// The UI elements the walkthrough can spotlight.
enum TutorialTarget: Hashable {
    case readout, capture, tabs, settings
}

// MARK: - Anchor plumbing

/// Collects each tagged element's bounds so the overlay can position the
/// spotlight precisely.
struct TutorialAnchorKey: PreferenceKey {
    static let defaultValue: [TutorialTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TutorialTarget: Anchor<CGRect>],
                       nextValue: () -> [TutorialTarget: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    /// Register this view as a tutorial spotlight target.
    func tutorialAnchor(_ target: TutorialTarget) -> some View {
        anchorPreference(key: TutorialAnchorKey.self, value: .bounds) { [target: $0] }
    }
}

// MARK: - Step model

enum SpotlightShape { case circle, roundedRect }

struct TutorialStep: Identifiable {
    let id = UUID()
    let target: TutorialTarget
    let title: String
    let body: String
    let shape: SpotlightShape
    /// Extra padding around the element for the spotlight/pen.
    var inset: CGFloat = 10
}

// MARK: - Hand-drawn marker shapes

/// A wobbly marker loop that circles a rect. Built from many short segments
/// whose radius is perturbed by layered sines (deterministic, so the line is
/// stable across redraws) and that overshoot the start by ~half a turn, so it
/// reads as a quick hand-drawn pen circle rather than a perfect ellipse.
private struct HandLoop: Shape {
    /// Radians swept past a full turn, for the marker overshoot.
    var overshoot: CGFloat = 0.55
    /// Varies the wobble phase per step so each loop looks individually drawn.
    var seed: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let rx = rect.width / 2, ry = rect.height / 2
        let start: CGFloat = -.pi * 0.62          // begin up and to the left
        let sweep: CGFloat = .pi * 2 + overshoot
        let steps = 168
        let s1 = seed * 1.3 + 0.7
        let s2 = seed * 2.1 + 2.3
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = start + sweep * t
            // Pen tremor: two incommensurate sines → organic, non-repeating wobble.
            let w = 1 + 0.05 * sin(a * 2.7 + s1) + 0.03 * sin(a * 5.1 + s2)
            // A touch of center drift so it isn't a clean concentric loop.
            let dx = 0.018 * rx * sin(a * 1.3 + s1)
            let dy = 0.018 * ry * cos(a * 1.7 + s2)
            let pt = CGPoint(x: cx + dx + rx * w * cos(a),
                             y: cy + dy + ry * w * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

/// A hand-drawn arrow from `from` to `to`: a gently bowed, lightly trembling
/// shaft with a two-barb arrowhead at the tip. The shaft is laid down first and
/// the head last, so a `.trim(0, progress)` reveals it as if sketched by hand.
private struct HandArrow: Shape {
    var from: CGPoint
    var to: CGPoint
    var seed: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let dx = to.x - from.x, dy = to.y - from.y
        let len = max(1, sqrt(dx * dx + dy * dy))
        let ux = dx / len, uy = dy / len          // unit vector along the shaft
        let px = -uy, py = ux                      // unit perpendicular
        let bow = min(22, len * 0.20)              // hand-drawn curve
        let steps = 52
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let env = sin(t * .pi)                 // 0 at both ends, 1 in middle
            let off = bow * env + 2.2 * sin(t * 7 + seed) * env
            let pt = CGPoint(x: from.x + dx * t + px * off,
                             y: from.y + dy * t + py * off)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        // Arrowhead: two barbs splaying back from the tip.
        let headLen = max(13, len * 0.18)
        let spread: CGFloat = 0.42
        let backAngle = atan2(-uy, -ux)
        let b1 = CGPoint(x: to.x + headLen * cos(backAngle + spread),
                         y: to.y + headLen * sin(backAngle + spread))
        let b2 = CGPoint(x: to.x + headLen * cos(backAngle - spread),
                         y: to.y + headLen * sin(backAngle - spread))
        p.move(to: b1); p.addLine(to: to); p.addLine(to: b2)
        return p
    }
}

// MARK: - reverse mask helper

private extension View {
    /// Cuts the masked shape OUT of the view (used to punch the spotlight hole).
    func punchOut<M: View>(@ViewBuilder _ mask: () -> M) -> some View {
        self.mask {
            Rectangle()
                .overlay { mask().blendMode(.destinationOut) }
                .compositingGroup()
        }
    }
}

// MARK: - Overlay

struct TutorialOverlay: View {
    let steps: [TutorialStep]
    /// Resolved on-screen frames for each target.
    let anchors: [TutorialTarget: CGRect]
    @Binding var isActive: Bool
    var startIndex: Int = 0

    @State private var index = 0
    @State private var penProgress: CGFloat = 0
    @State private var arrowProgress: CGFloat = 0
    @State private var focusPop: CGFloat = 0.85
    @State private var typed = 0

    private var step: TutorialStep? { steps.indices.contains(index) ? steps[index] : nil }
    private var rect: CGRect? { step.flatMap { anchors[$0.target] } }

    var body: some View {
        GeometryReader { geo in
            if let step, let rect = rect?.insetBy(dx: -step.inset, dy: -step.inset) {
                ZStack {
                    // Dimmed scrim with the spotlight punched out.
                    Color.black.opacity(0.74)
                        .ignoresSafeArea()
                        .punchOut {
                            spotlightShape(step.shape, rect: rect, radius: step.inset + 16)
                                .scaleEffect(focusPop)
                                .position(x: rect.midX, y: rect.midY)
                        }
                        .onTapGesture { advance() }

                    // Hand-drawn marker loop around the element + pointing arrow.
                    markerLoop(rect: rect)
                    pointingArrow(rect: rect, screen: geo.size)

                    // Caption + controls, placed clear of the spotlight.
                    captionCard(step: step, screen: geo.size, target: rect)
                }
                .task(id: step.id) { await runStepAnimation(step) }
            }
        }
        .transition(.opacity)
        .onAppear { if startIndex != 0 { index = startIndex } }
    }

    // MARK: spotlight, marker & arrow

    @ViewBuilder
    private func spotlightShape(_ shape: SpotlightShape, rect: CGRect, radius: CGFloat) -> some View {
        switch shape {
        case .circle:
            Circle().frame(width: max(rect.width, rect.height), height: max(rect.width, rect.height))
        case .roundedRect:
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .frame(width: rect.width, height: rect.height)
        }
    }

    /// Padding of the marker loop beyond the (already inset) target rect.
    private func loopPadding(_ rect: CGRect) -> CGSize {
        CGSize(width: max(16, rect.width * 0.06), height: max(16, rect.height * 0.10))
    }

    private func markerLoop(rect: CGRect) -> some View {
        let pad = loopPadding(rect)
        let loop = HandLoop(seed: CGFloat(index)).trim(from: 0, to: penProgress)
        return ZStack {
            // Soft ink bleed under the crisp stroke.
            loop.stroke(LM.accent.opacity(0.30),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            loop.stroke(LM.accent,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: rect.width + pad.width * 2, height: rect.height + pad.height * 2)
        .scaleEffect(focusPop)
        .position(x: rect.midX, y: rect.midY)
        .shadow(color: LM.accent.opacity(0.45), radius: 5)
        .allowsHitTesting(false)
    }

    private func pointingArrow(rect: CGRect, screen: CGSize) -> some View {
        let pad = loopPadding(rect)
        let captionBelow = rect.midY < screen.height * 0.5     // note sits opposite the target
        let side: CGFloat = rect.midX <= screen.width * 0.5 ? 1 : -1
        let tipX = rect.midX + side * min(rect.width * 0.22, 60)
        let edge = captionBelow ? rect.maxY + pad.height : rect.minY - pad.height
        let dir: CGFloat = captionBelow ? 1 : -1               // toward the caption
        let tip = CGPoint(x: tipX, y: edge + dir * 20)
        let tail = CGPoint(x: tipX + side * 46, y: edge + dir * 100)
        let arrow = HandArrow(from: tail, to: tip, seed: CGFloat(index) * 1.7)
            .trim(from: 0, to: arrowProgress)
        return ZStack {
            arrow.stroke(LM.accent.opacity(0.30),
                         style: StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round))
            arrow.stroke(LM.accent,
                         style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        .shadow(color: LM.accent.opacity(0.4), radius: 4)
        .allowsHitTesting(false)
    }

    // MARK: caption

    private func captionCard(step: TutorialStep, screen: CGSize, target: CGRect) -> some View {
        // Put the caption on the opposite half from the spotlight so they don't overlap.
        let targetInTopHalf = target.midY < screen.height * 0.5
        return VStack {
            if targetInTopHalf { Spacer() }
            VStack(alignment: .leading, spacing: 10) {
                Text(step.title)
                    .font(.custom("Bradley Hand", size: LM.FontSize.h1 + 8).weight(.bold))
                    .foregroundStyle(LM.accent)
                Text(String(step.body.prefix(typed)))
                    .font(LM.font(LM.FontSize.body, .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 44, alignment: .topLeading)

                HStack(spacing: 14) {
                    // progress dots
                    HStack(spacing: 6) {
                        ForEach(steps.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == index ? LM.accent : Color.white.opacity(0.3))
                                .frame(width: i == index ? 16 : 6, height: 6)
                        }
                    }
                    Spacer()
                    Button(action: finish) {
                        Text("Skip")
                            .font(LM.font(LM.FontSize.caption, .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Button(action: advance) {
                        Text(index == steps.count - 1 ? "Done" : "Next")
                            .font(LM.font(LM.FontSize.body, .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(LM.accent))
                    }
                }
                .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.12), lineWidth: 1))
            )
            .padding(.horizontal, 18)
            .padding(targetInTopHalf ? .bottom : .top, 28)
            if !targetInTopHalf { Spacer() }
        }
    }

    // MARK: animation & nav

    private func runStepAnimation(_ step: TutorialStep) async {
        penProgress = 0
        arrowProgress = 0
        focusPop = 0.85
        typed = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { focusPop = 1.0 }
        // Scribble the loop, then sketch the arrow pointing at it.
        withAnimation(.easeInOut(duration: 0.6).delay(0.12)) { penProgress = 1.0 }
        withAnimation(.easeOut(duration: 0.4).delay(0.62)) { arrowProgress = 1.0 }
        // Write the note in.
        try? await Task.sleep(nanoseconds: 850_000_000)
        for i in 0...step.body.count {
            if Task.isCancelled { return }
            typed = i
            try? await Task.sleep(nanoseconds: 16_000_000)
        }
    }

    private func advance() {
        if index >= steps.count - 1 { finish(); return }
        withAnimation(.easeInOut(duration: 0.25)) { index += 1 }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.3)) { isActive = false }
    }
}
