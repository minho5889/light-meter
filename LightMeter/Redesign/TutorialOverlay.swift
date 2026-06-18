//
//  TutorialOverlay.swift
//  LightMeter
//
//  A "hand-drawn" spotlight onboarding walkthrough for Regular mode. It feels
//  like someone annotated the screen with a marker:
//    • dims the whole screen, punching a bright spotlight over one element,
//    • draws a minimal, slightly hand-drawn marker circle around it,
//    • sketches a hand-drawn arrow from the floating note TO that element, so
//      the note and the element sit at opposite ends of the arrow,
//    • the note itself floats free (no card) — a handwritten heading, the body
//      typed in, plus Skip / Next and progress dots.
//
//  The note is placed a comfortable distance from the element on whichever side
//  has more room, centered on the element's x, so the connecting arrow stays
//  short and clearly runs from the text to the element.
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

/// Reports the floating note's rendered size so it can be positioned and the
/// arrow anchored to it.
private struct NoteSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero { value = next }
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

/// A minimal, lightly hand-drawn marker loop around a rect — close to a clean
/// ellipse with just a hint of pen tremor and a short overshoot, built from
/// deterministic sines so the trim-reveal stays stable across redraws.
private struct HandLoop: Shape {
    /// Radians swept past a full turn, for a small marker overshoot.
    var overshoot: CGFloat = 0.32
    /// Varies the wobble phase per step so each loop looks individually drawn.
    var seed: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let rx = rect.width / 2, ry = rect.height / 2
        let start: CGFloat = -.pi * 0.55
        let sweep: CGFloat = .pi * 2 + overshoot
        let steps = 148
        let s1 = seed * 1.3 + 0.7
        let s2 = seed * 2.1 + 2.3
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = start + sweep * t
            // Subtle pen tremor (small amplitudes → reads tidy, not scribbly).
            let w = 1 + 0.020 * sin(a * 2.4 + s1) + 0.012 * sin(a * 4.7 + s2)
            let dx = 0.009 * rx * sin(a * 1.2 + s1)
            let dy = 0.009 * ry * cos(a * 1.5 + s2)
            let pt = CGPoint(x: cx + dx + rx * w * cos(a),
                             y: cy + dy + ry * w * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

/// A clean hand-drawn arrow from `from` to `to`: a gently bowed, barely
/// trembling shaft with a tidy two-barb arrowhead at the tip. Shaft is laid
/// down first and the head last, so `.trim(0, progress)` reveals it like a
/// quick pen sketch.
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
        let bow = min(13, len * 0.09)              // gentle hand-drawn curve
        let steps = 44
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let env = sin(t * .pi)                 // 0 at both ends, 1 in middle
            let off = bow * env + 1.2 * sin(t * 5.5 + seed) * env
            let pt = CGPoint(x: from.x + dx * t + px * off,
                             y: from.y + dy * t + py * off)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        // Arrowhead: two tidy barbs splaying back from the tip.
        let headLen = min(17, max(12, len * 0.16))
        let spread: CGFloat = 0.40
        let backAngle = atan2(-uy, -ux)
        let b1 = CGPoint(x: to.x + headLen * cos(backAngle + spread),
                         y: to.y + headLen * sin(backAngle + spread))
        let b2 = CGPoint(x: to.x + headLen * cos(backAngle - spread),
                         y: to.y + headLen * sin(backAngle - spread))
        p.move(to: b1); p.addLine(to: to); p.addLine(to: b2)
        return p
    }
}

/// A quick hand-drawn underline swoosh, sized to sit under a word: mostly flat
/// with a little tremor, a slight downward drift, and an upward flick at the end.
private struct HandUnderline: Shape {
    var seed: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let startX: CGFloat = -5
        let endX = rect.width + 7
        let yMid = rect.midY
        let steps = 44
        let s = seed * 1.7 + 0.4
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = startX + (endX - startX) * t
            let y = yMid
                + 1.4 * sin(t * 3.3 + s)               // gentle tremor
                + 1.0 * t                              // slight downward drift
                - 3.0 * max(0, (t - 0.85) / 0.15)      // flick up at the end
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
            else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    @State private var penProgress: CGFloat = 0
    @State private var arrowProgress: CGFloat = 0
    @State private var underlineProgress: CGFloat = 0
    @State private var focusPop: CGFloat = 0.85
    @State private var typed = 0
    @State private var noteSize: CGSize = .zero

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

                    // Minimal hand-drawn marker circle around the element.
                    markerLoop(rect: rect)

                    // Arrow from the floating note to the element (note ↔ element
                    // at opposite ends). Drawn once the note's size is known.
                    if noteSize != .zero {
                        pointingArrow(target: rect, screen: geo.size)
                    }

                    // Floating note (no card): heading, body, controls.
                    floatingNote(step: step, screen: geo.size, target: rect)
                }
                .task(id: step.id) { await runStepAnimation(step) }
                .onPreferenceChange(NoteSizeKey.self) { noteSize = $0 }
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
        CGSize(width: max(14, rect.width * 0.05), height: max(14, rect.height * 0.09))
    }

    private func markerLoop(rect: CGRect) -> some View {
        let pad = loopPadding(rect)
        return HandLoop(seed: CGFloat(index))
            .trim(from: 0, to: penProgress)
            .stroke(LM.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: rect.width + pad.width * 2, height: rect.height + pad.height * 2)
            .scaleEffect(focusPop)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: LM.accent.opacity(0.45), radius: 4)
            .allowsHitTesting(false)
    }

    /// Where the floating note sits and which side of the element it's on.
    private func noteLayout(target: CGRect, screen: CGSize)
        -> (center: CGPoint, frame: CGRect, placeBelow: Bool) {
        let pad = loopPadding(target)
        let placeBelow = (screen.height - target.maxY) >= target.minY   // roomier side
        let w = noteSize.width, h = noteSize.height
        let gap: CGFloat = 80
        let topSafe: CGFloat = 64, bottomSafe: CGFloat = 80, side: CGFloat = 24
        var cy = placeBelow ? target.maxY + pad.height + gap + h / 2
                            : target.minY - pad.height - gap - h / 2
        cy = min(max(cy, topSafe + h / 2), screen.height - bottomSafe - h / 2)
        let cx = min(max(target.midX, side + w / 2), screen.width - side - w / 2)
        return (CGPoint(x: cx, y: cy),
                CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h),
                placeBelow)
    }

    private func pointingArrow(target: CGRect, screen: CGSize) -> some View {
        let pad = loopPadding(target)
        let layout = noteLayout(target: target, screen: screen)
        let nf = layout.frame
        // Leave the note from the point on its edge closest to the element.
        let tailX = min(max(target.midX, nf.minX + 24), nf.maxX - 24)
        let tail: CGPoint
        let head: CGPoint
        if layout.placeBelow {
            tail = CGPoint(x: tailX, y: nf.minY - 8)
            head = CGPoint(x: target.midX, y: target.maxY + pad.height + 12)
        } else {
            tail = CGPoint(x: tailX, y: nf.maxY + 8)
            head = CGPoint(x: target.midX, y: target.minY - pad.height - 12)
        }
        return HandArrow(from: tail, to: head, seed: CGFloat(index) * 1.7)
            .trim(from: 0, to: arrowProgress)
            .stroke(LM.accent, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            .shadow(color: LM.accent.opacity(0.45), radius: 4)
            .allowsHitTesting(false)
    }

    // MARK: floating note

    /// Handwriting face for the heading, by script. Bradley Hand renders Latin
    /// beautifully but has no Hangul, so Korean headings use the bundled Nanum
    /// Pen Script (a Korean pen face); it reads lighter, so it's sized up a touch.
    private func handwrittenFont(for text: String) -> Font {
        if text.unicodeScalars.contains(where: { isHangul($0) }) {
            return .custom("NanumPen-Regular", size: LM.FontSize.h1 + 16)
        }
        return .custom("Bradley Hand", size: LM.FontSize.h1 + 8).weight(.bold)
    }

    private func isHangul(_ s: Unicode.Scalar) -> Bool {
        switch s.value {
        case 0xAC00...0xD7A3,   // Hangul syllables
             0x1100...0x11FF,   // Jamo
             0x3130...0x318F:   // compatibility Jamo
            return true
        default:
            return false
        }
    }

    private func floatingNote(step: TutorialStep, screen: CGSize, target: CGRect) -> some View {
        let layout = noteLayout(target: target, screen: screen)
        return noteBlock(step)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: NoteSizeKey.self, value: g.size)
                }
            )
            .position(layout.center)
            .opacity(noteSize == .zero ? 0 : 1)   // hide until measured (avoids a position jump)
    }

    private func noteBlock(_ step: TutorialStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(step.title)
                .font(handwrittenFont(for: step.title))
                .foregroundStyle(LM.accent)
                .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                .fixedSize()
                .overlay(alignment: .bottomLeading) {
                    HandUnderline(seed: CGFloat(index))
                        .trim(from: 0, to: underlineProgress)
                        .stroke(LM.accent,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .frame(height: 6)
                        .offset(y: 8)
                        .allowsHitTesting(false)
                }

            // Reserve the full body's height (invisible sizer) so the note size
            // — and therefore the arrow tail — stays put while the text types in.
            Text(step.body)
                .font(LM.font(LM.FontSize.body, .medium))
                .opacity(0)
                .fixedSize(horizontal: false, vertical: true)
                .overlay(alignment: .topLeading) {
                    Text(String(step.body.prefix(typed)))
                        .font(LM.font(LM.FontSize.body, .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.55), radius: 3)
                        .fixedSize(horizontal: false, vertical: true)
                }

            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? LM.accent : Color.white.opacity(0.35))
                            .frame(width: i == index ? 16 : 6, height: 6)
                    }
                }
                Spacer(minLength: 12)
                Button(action: finish) {
                    Text("Skip")
                        .font(LM.font(LM.FontSize.caption, .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.5), radius: 2)
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
        .frame(width: 296, alignment: .leading)
    }

    // MARK: animation & nav

    private func runStepAnimation(_ step: TutorialStep) async {
        penProgress = 0
        arrowProgress = 0
        underlineProgress = 0
        focusPop = 0.85
        typed = 0
        // Respect Reduce Motion: present the finished annotation without the
        // draw-on / typewriter motion.
        if reduceMotion {
            focusPop = 1.0
            penProgress = 1.0
            arrowProgress = 1.0
            underlineProgress = 1.0
            typed = step.body.count
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { focusPop = 1.0 }
        // Draw the circle, then the arrow from the note to it.
        withAnimation(.easeInOut(duration: 0.55).delay(0.12)) { penProgress = 1.0 }
        withAnimation(.easeOut(duration: 0.45).delay(0.55)) { arrowProgress = 1.0 }
        // Underline the heading, then write the note in.
        withAnimation(.easeOut(duration: 0.3).delay(0.95)) { underlineProgress = 1.0 }
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
