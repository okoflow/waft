import SwiftUI
import WaftCore

extension ShortcutRecorder {
    func note(for action: ShortcutAction) -> LocalizedStringKey? {
        guard isRecording(action) else { return nil }

        switch rejection {
        case .needsModifier:
            return "Add Command, Control, or Option, or press a function key."

        case let .taken(conflict):
            return .verbatim(String(localized: "That shortcut is already used for “\(conflict.title)”. Choose another one."))

        case nil:
            return "Press a key with Command, Control, or Option, or a function key. Esc cancels."
        }
    }
}
