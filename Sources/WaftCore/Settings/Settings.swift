package struct Settings: Codable, Equatable, Sendable {
    private enum LegacyCodingKeys: String, CodingKey {
        case allowsHandsFree = "handsFreeDoubleTap"
    }

    private enum CodingKeys: String, CodingKey {
        case mode
        case customModes
        case languages
        case writingVariants
        case speechModel
        case appModes
        case modelProvider
        case cloudModels
        case localServer
        case instructions
        case translation
        case translator
        case pushToTalkKey
        case dictationStart
        case editKey
        case pastesIntoFocusedField
        case keepsHistory
        case historyRetention
        case historyLimit
        case playsSounds
        case lowersOtherSounds
        case showsMenuBarIcon
        case microphoneID
        case hasCompletedSetup
    }

    package var mode = Mode.light
    package var customModes: [CustomMode] = []
    package var languages = LanguageSelection(languages: [.english])
    package var writingVariants = WritingVariants()
    package var speechModel = SpeechModel.fast
    package var appModes = AppModeOverrides()
    package var modelProvider = ModelProvider.cloud(.claude)
    package var cloudModels = CloudModel.defaultChoices
    package var localServer = LocalServer()
    package var instructions = ModeInstructions()
    package var translation = Translation()
    package var translator = TranslatorSettings()
    package var pushToTalkKey = PushToTalkKey.rightOption
    package var dictationStart = DictationStart.holdOrDoubleTap
    package var editKey: PushToTalkKey?
    package var pastesIntoFocusedField = true
    package var keepsHistory = true
    package var historyRetention = HistoryRetention.month
    package var historyLimit = DictationHistory.defaultLimit
    package var playsSounds = true
    package var lowersOtherSounds = true
    package var showsMenuBarIcon = true
    package var microphoneID: String?
    package var hasCompletedSetup = false

    package init(languages: LanguageSelection) {
        self.languages = languages
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let storedLimit = container.decode(.historyLimit, default: historyLimit)
        let allowedHandsFree = legacy.decode(.allowsHandsFree, default: true)

        customModes = container.decodeValidElements(.customModes)
        mode = container.decode(.mode, default: mode)
        languages = container.decode(.languages, default: languages)
        writingVariants = container.decode(.writingVariants, default: writingVariants)
        speechModel = container.decode(.speechModel, default: speechModel)
        appModes = container.decode(.appModes, default: appModes)
        modelProvider = container.decode(.modelProvider, default: modelProvider)
        cloudModels = container.decode(.cloudModels, default: cloudModels)
        localServer = container.decode(.localServer, default: localServer)
        instructions = container.decode(.instructions, default: instructions)
        translation = container.decode(.translation, default: translation)
        translator = container.decode(.translator, default: TranslatorSettings(translation: translation))
        pushToTalkKey = container.decode(.pushToTalkKey, default: pushToTalkKey)
        dictationStart = container.decode(.dictationStart, default: allowedHandsFree ? .holdOrDoubleTap : .hold)
        editKey = container.decodeIfValid(.editKey)
        pastesIntoFocusedField = container.decode(.pastesIntoFocusedField, default: pastesIntoFocusedField)
        keepsHistory = container.decode(.keepsHistory, default: keepsHistory)
        historyRetention = container.decode(.historyRetention, default: historyRetention)
        historyLimit = DictationHistory.limits.contains(storedLimit) ? storedLimit : historyLimit
        playsSounds = container.decode(.playsSounds, default: playsSounds)
        lowersOtherSounds = container.decode(.lowersOtherSounds, default: lowersOtherSounds)
        showsMenuBarIcon = container.decode(.showsMenuBarIcon, default: showsMenuBarIcon)
        microphoneID = container.decodeIfValid(.microphoneID)
        hasCompletedSetup = container.decode(.hasCompletedSetup, default: hasCompletedSetup)

        dropMissingCustomModes()
    }

    package func mode(for bundleIdentifier: String?) -> Mode {
        guard let appMode = appModes.mode(for: bundleIdentifier) else { return mode }

        return appMode
    }
}
