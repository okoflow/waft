package enum UsageEvent: Equatable, Sendable {
    case dictation(Mode)
    case voiceEdit
    case selectionAction
    case translation
    case fileTranscription
}
