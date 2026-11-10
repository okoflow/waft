package enum RecordingEvent: Sendable {
    case started(RecordingID)
    case failed(RecordingID, RecordingFailure)
}
