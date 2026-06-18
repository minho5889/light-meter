import UIKit

/// Lightweight haptic feedback for trendy micro-interactions (tab/scene taps,
/// opening the Coach, switching modes). Kept tiny and centralized so the feel
/// is consistent across the redesign.
@MainActor
enum LMHaptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
