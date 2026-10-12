import SwiftUI
import WaftCore

extension KeyRecorder {
    func note(for purpose: RecordingPurpose) -> LocalizedStringKey? {
        guard isRecording(purpose) else { return nil }

        if let rejection, rejection.purpose == purpose {
            return rejection.isTaken
                ? "That key is already in use. Choose another one."
                : "That key types text. Press Option, Command, Shift, Control, Fn, or a function key."
        }

        return "Press Option, Command, Shift, or Control on either side, Fn, or a function key. Esc cancels."
    }
}
