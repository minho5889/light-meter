/// Pure function that determines the camera session action for a tab transition.
/// Camera↔camera transitions return `.none` (session already running).
/// Camera→non-camera returns `.stopSession`. Non-camera→camera returns `.startSession`.
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

    /// Returns true if the given tab index requires the camera.
    static func isCameraTab(_ tab: Int) -> Bool {
        tab == 0 || tab == 1 || tab == 2
    }

    /// Resolves the session action for a tab transition.
    static func resolve(from previousTab: Int, to newTab: Int) -> Action {
        guard previousTab != newTab else { return .none }

        let prevIsCamera = isCameraTab(previousTab)
        let newIsCamera = isCameraTab(newTab)

        if prevIsCamera && !newIsCamera {
            return .stopSession
        } else if !prevIsCamera && newIsCamera {
            return .startSession
        } else {
            return .none
        }
    }
}
