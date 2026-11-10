package struct UsageCounts: Codable, Equatable, Sendable {
    package private(set) var rawDictations = 0
    package private(set) var lightDictations = 0
    package private(set) var cleanDictations = 0
    package private(set) var formalDictations = 0
    package private(set) var translateDictations = 0
    package private(set) var customDictations = 0
    package private(set) var voiceEdits = 0
    package private(set) var selectionActions = 0
    package private(set) var translations = 0
    package private(set) var fileTranscriptions = 0

    package init() {}

    package mutating func count(_ event: UsageEvent) {
        switch event {
        case .dictation(.raw): rawDictations += 1
        case .dictation(.light): lightDictations += 1
        case .dictation(.clean): cleanDictations += 1
        case .dictation(.formal): formalDictations += 1
        case .dictation(.translate): translateDictations += 1
        case .dictation(.custom): customDictations += 1
        case .voiceEdit: voiceEdits += 1
        case .selectionAction: selectionActions += 1
        case .translation: translations += 1
        case .fileTranscription: fileTranscriptions += 1
        }
    }
}
