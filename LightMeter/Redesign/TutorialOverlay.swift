//
//  TutorialOverlay.swift
//  LightMeter
//
//  A trendy "spotlight" onboarding walkthrough for Regular mode:
//    • dims the whole screen, punching a bright spotlight over one element,
//    • draws an animated marker/pen stroke around it (the "pen write-up"),
//    • types the description in on a glass caption card,
//    • pops the highlighted element into focus, with Next / Skip / progress dots.
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

// MARK: - Pen stroke shape

/// A slightly hand-drawn marker stroke that loops around a rect (oval for
/// circle targets, rounded box for rect targets), with a small overshoot so it
/// reads as a quick pen circle.
private struct PenStroke: Shape {
    let shape: SpotlightShape
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch shape {
        case .circle:
            // Start at top, loop around ~370° for a marker-circle overshoot.
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let r = max(rect.width, rect.height) / 2
            p.addArc(center: c, radius: r,
                     startAngle: .degrees(-95), endAngle: .degrees(275),
                     clockwise: false)
        case .roundedRect:
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
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

    @State private var index = 0
    @State private var penProgress: CGFloat = 0
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

                    // Animated pen/marker stroke around the element.
                    penStroke(step, rect: rect)

                    // Caption + controls, placed clear of the spotlight.
                    captionCard(step: step, screen: geo.size, target: rect)
                }
                .task(id: step.id) { await runStepAnimation(step) }
            }
        }
        .transition(.opacity)
        .onAppear { if startIndex != 0 { index = startIndex } }
    }

    // MARK: spotlight & pen

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

    private func penStroke(_ step: TutorialStep, rect: CGRect) -> some View {
        PenStroke(shape: step.shape, cornerRadius: step.inset + 18)
            .trim(from: 0, to: penProgress)
            .stroke(LM.accent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
            .frame(width: rect.width + 14, height: rect.height + 14)
            .scaleEffect(focusPop)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: LM.accent.opacity(0.5), radius: 6)
            .allowsHitTesting(false)
    }

    // MARK: caption

    private func captionCard(step: TutorialStep, screen: CGSize, target: CGRect) -> some View {
        // Put the card on the opposite side of the screen from the target.
        // Put the caption on the opposite half from the spotlight so they don't overlap.
        let targetInTopHalf = target.midY < screen.height * 0.5
        return VStack {
            if targetInTopHalf { Spacer() }
            VStack(alignment: .leading, spacing: 10) {
                Text(step.title)
                    .font(LM.font(LM.FontSize.h1, .bold))
                    .foregroundStyle(.white)
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
        focusPop = 0.85
        typed = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { focusPop = 1.0 }
        withAnimation(.easeInOut(duration: 0.7).delay(0.15)) { penProgress = 1.0 }
        // typewriter
        try? await Task.sleep(nanoseconds: 350_000_000)
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
