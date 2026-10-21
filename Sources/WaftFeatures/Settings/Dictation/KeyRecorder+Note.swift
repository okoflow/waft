import SwiftUI
import WaftCore

extension KeyRecorder {
    func note(for purpose: RecordingPurpose) -> LocalizedStringKey? {
        guard isRecording(purpose) else { return nil }
        guard let rejection, rejection.purpose == purpose else {
            return "Press Option, Command, Shift, or Control on either side, Fn, or a function key. Esc cancels."
        }
        guard rejection.isTaken else {
            return "That key types text. Press Option, Command, Shift, Control, Fn, or a function key."
        }

        return "That key is already in use. Choose another one."
    }
}
