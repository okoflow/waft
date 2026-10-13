package struct Settings: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case mode
        case languages
        case appModes
        case modelProvider
        case localServer
        case instructions
        case translation
        case pushToTalkKey
        case allowsHandsFree = "handsFreeDoubleTap"
        case editKey
        case pastesIntoFocusedField
        case keepsHistory
        case historyRetention
        case historyLimit
        case playsSounds
        case showsMenuBarIcon
        case microphoneID
        case hasCompletedSetup
    }

    package var mode = Mode.light
    package var languages = LanguageSelection(languages: [.english])
    package var appModes = AppModeOverrides()
    package var modelProvider = ModelProvider.cloud(.claude)
    package var localServer = LocalServer()
    package var instructions = ModeInstructions()
    package var translation = Translation()
    package var pushToTalkKey = PushToTalkKey.rightOption
    package var allowsHandsFree = true
    package var editKey: PushToTalkKey?
    package var pastesIntoFocusedField = true
    package var keepsHistory = true
    package var historyRetention = HistoryRetention.month
    package var historyLimit = DictationHistory.defaultLimit
    package var playsSounds = true
    package var showsMenuBarIcon = true
    package var microphoneID: String?
    package var hasCompletedSetup = false

    package init(languages: LanguageSelection) {
        self.languages = languages
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let storedLimit = container.decode(.historyLimit, default: historyLimit)

        mode = container.decode(.mode, default: mode)
        languages = container.decode(.languages, default: languages)
        appModes = container.decode(.appModes, default: appModes)
        modelProvider = container.decode(.modelProvider, default: modelProvider)
        localServer = container.decode(.localServer, default: localServer)
        instructions = container.decode(.instructions, default: instructions)
        translation = container.decode(.translation, default: translation)
        pushToTalkKey = container.decode(.pushToTalkKey, default: pushToTalkKey)
        allowsHandsFree = container.decode(.allowsHandsFree, default: allowsHandsFree)
        editKey = container.decodeIfValid(.editKey)
        pastesIntoFocusedField = container.decode(.pastesIntoFocusedField, default: pastesIntoFocusedField)
        keepsHistory = container.decode(.keepsHistory, default: keepsHistory)
        historyRetention = container.decode(.historyRetention, default: historyRetention)
        historyLimit = DictationHistory.limits.contains(storedLimit) ? storedLimit : historyLimit
        playsSounds = container.decode(.playsSounds, default: playsSounds)
        showsMenuBarIcon = container.decode(.showsMenuBarIcon, default: showsMenuBarIcon)
        microphoneID = container.decodeIfValid(.microphoneID)
        hasCompletedSetup = container.decode(.hasCompletedSetup, default: hasCompletedSetup)
    }

    package func mode(for bundleIdentifier: String?) -> Mode {
        guard let appMode = appModes.mode(for: bundleIdentifier) else { return mode }

        return appMode
    }
}
