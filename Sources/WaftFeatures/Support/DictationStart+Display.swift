import SwiftUI
import WaftCore

extension DictationStart {
    var title: LocalizedStringKey {
        switch self {
        case .hold: "Hold"
        case .tap: "Tap"
        case .holdOrDoubleTap: "Hold or double-tap"
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .hold: "Talk while holding the key"
        case .tap: "Tap to start and stop"
        case .holdOrDoubleTap: "Double-tap for hands-free"
        }
    }
}
