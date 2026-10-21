import Foundation
import WaftCore

extension ShortcutAction {
    var title: String {
        switch self {
        case .modeCycle: String(localized: "Switch to the next mode")
        case .translator: String(localized: "Open the translator")
        case .translateSelection: String(localized: "Translate selected text")
        case .fixSelection: String(localized: "Fix selected text")
        }
    }
}

extension ShortcutConflict {
    var title: String {
        switch self {
        case let .shortcut(action): action.title
        case .key(.dictation): String(localized: "Dictation key")
        case .key(.edit): String(localized: "Editing key")
        }
    }
}
