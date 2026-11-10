import WaftCore

extension RecordingTrigger {
    nonisolated static let dictation = RecordingTrigger(purpose: .dictation, key: .function, action: .startRecording)
    nonisolated static let edit = RecordingTrigger(purpose: .edit, key: .function, action: .startRecording)
}
