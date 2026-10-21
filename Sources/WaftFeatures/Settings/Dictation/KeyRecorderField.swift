import SwiftUI
import WaftCore

struct KeyRecorderField: View {
    let purpose: RecordingPurpose
    let key: PushToTalkKey?
    let takenKey: PushToTalkKey?
    let recorder: KeyRecorder
    let record: (PushToTalkKey) -> Void

    private var isRecording: Bool {
        recorder.isRecording(purpose)
    }

    private var title: String {
        guard let key else { return String(localized: "None") }

        return key.title
    }

    var body: some View {
        RecorderField(
            title: title,
            isEmpty: key == nil,
            isRecording: isRecording,
            prompt: "Press a key…",
            rejections: recorder.rejections[purpose, default: 0],
            help: isRecording ? Text("Press the key to use, or Esc to cancel") : Text("Click, then press the key to use"),
            label: purpose == .dictation ? Text("Dictation key") : Text("Editing key"),
        ) {
            if isRecording {
                recorder.stop()
            } else {
                recorder.start(purpose, excluding: takenKey, record)
            }
        }
    }
}
