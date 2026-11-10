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

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        rawDictations = container.decode(.rawDictations, default: rawDictations)
        lightDictations = container.decode(.lightDictations, default: lightDictations)
        cleanDictations = container.decode(.cleanDictations, default: cleanDictations)
        formalDictations = container.decode(.formalDictations, default: formalDictations)
        translateDictations = container.decode(.translateDictations, default: translateDictations)
        customDictations = container.decode(.customDictations, default: customDictations)
        voiceEdits = container.decode(.voiceEdits, default: voiceEdits)
        selectionActions = container.decode(.selectionActions, default: selectionActions)
        translations = container.decode(.translations, default: translations)
        fileTranscriptions = container.decode(.fileTranscriptions, default: fileTranscriptions)
    }

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
