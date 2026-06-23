//
//  LMActivityGrid.swift
//  LightMeter
//
//  A 2-column grid of frosted "activity" cards for the Check screen.
//  Each card shows a centered 1–2 line label (e.g. "Lecture et Études",
//  "Travail et Focus", "TV et Cinéma", …). Styling matches the Check render:
//  frosted .ultraThinMaterial glass with a soft #FAFAFA tint, 24pt continuous
//  corners, a subtle white hairline, even 12pt gaps and 16pt outer padding.
//
//  Tokens are taken VERBATIM from LMDesign.swift (the `LM` namespace).
//

import SwiftUI

// MARK: - LMActivityGrid

/// Two-column grid of frosted activity cards.
///
/// Pass any list of activity labels; the grid lays them out left→right,
/// top→bottom in two equal-width columns, each rendered as a frosted glass
/// card with a centered, vertically-centered 1–2 line label.
struct LMActivityGrid: View {

    /// Activity labels to display, in reading order.
    let activities: [String]

    /// Optional tap handler, invoked with the tapped activity's label.
    var onSelect: ((String) -> Void)? = nil

    /// Fixed height per card — matches the render's squat, rounded cards.
    private let cardHeight: CGFloat = 64

    /// Two equal, flexible columns with the standard inter-card gap.
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: LM.gap),
            GridItem(.flexible(), spacing: LM.gap),
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: LM.gap) {
            ForEach(Array(activities.enumerated()), id: \.offset) { _, label in
                LMActivityCard(label: label, height: cardHeight) {
                    onSelect?(label)
                }
            }
        }
        .padding(LM.pad)
    }
}

// MARK: - LMActivityCard

/// A single frosted activity card with a centered, multi-line label.
private struct LMActivityCard: View {

    let label: String
    let height: CGFloat
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(LM.font(LM.FontSize.body, .bold))            // FAFAFA Bold 14pt
                .foregroundStyle(LM.readoutText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, LM.gap)
                .padding(.vertical, 8)
                .frame(height: height)
                .lmGlass(cornerRadius: LM.cardRadius, tint: LM.readoutGlass)   // BG #2C2C2C @ 20%
        }
        .buttonStyle(LMPressableButtonStyle())
    }
}

// MARK: - LMPressableButtonStyle

/// Subtle press feedback (scale + opacity) without altering the glass surface.
private struct LMPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("LMActivityGrid") {
    // Representative background standing in for the camera / room photo
    // behind the Check screen, so the frosted glass reads correctly.
    let activities = [
        "Lecture et Études",
        "Travail et Focus",
        "TV et Cinéma",
        "Repas et Social",
        "Sommeil et Détente",
        "Bébé et Puériculture",
        "Rendez-vous et Romantique",
        "Heure du thé Café",
    ]

    return ZStack {
        LinearGradient(
            colors: [
                Color(hex: 0x8A8A86),
                Color(hex: 0xB9A48E),
                Color(hex: 0x6E5A47),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            LMActivityGrid(activities: activities) { selected in
                print("Selected: \(selected)")
            }
            Spacer()
        }
    }
}
