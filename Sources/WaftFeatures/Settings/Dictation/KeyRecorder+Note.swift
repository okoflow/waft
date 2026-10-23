import SwiftUI
import WaftCore

extension KeyRecorder {
    func note(for purpose: RecordingPurpose) -> LocalizedStringKey? {
        guard isRecording(purpose) else { return nil }
        guard let rejection else {
            return "Press Option, Command, Shift, or Control on either side, Fn, or a function key. Esc cancels."
        }

        switch rejection {
        case .typesText:
            return "That key types text. Press Option, Command, Shift, Control, Fn, or a function key."
        case .taken:
            return "That key is already in use. Choose another one."
        }
    }
}
