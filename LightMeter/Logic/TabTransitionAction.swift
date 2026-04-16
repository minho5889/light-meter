/// Pure function that determines the camera session action for a tab transition.
/// This encodes the CURRENT (buggy) onChange logic: it only looks at `newTab`,
/// ignoring `previousTab` entirely — returning `.startSession` for any camera
/// tab and `.stopSession` for any non-camera tab.
struct TabTransitionAction {
    enum Action: Equatable, CustomStringConvertible {
        case startSession
        case stopSession
        case none

        var description: String {
            switch self {
            case .startSession: return ".startSession"
            case .stopSession: return ".stopSession"
            case .none: return ".none"
            }
        }
    }

    /// Resolves the session action for a tab transition.
    /// Current (buggy) logic: only considers `newTab`, ignores `previousTab`.
    static func resolve(from previousTab: Int, to newTab: Int) -> Action {
        if newTab == 0 || newTab == 1 {
            return .startSession
        } else {
            return .stopSession
        }
    }
}
