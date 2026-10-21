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

    private var help: Text {
        guard isRecording else { return Text("Click, then press the key to use") }

        return Text("Press the key to use, or Esc to cancel")
    }

    var body: some View {
        RecorderField(
            title: key?.title,
            isRecording: isRecording,
            prompt: "Press a key…",
            rejections: recorder.rejections[purpose, default: 0],
            help: help,
            label: Text(purpose.title),
        ) {
            if isRecording {
                recorder.stop()
            } else {
                recorder.start(purpose, excluding: takenKey, record)
            }
        }
    }
}
