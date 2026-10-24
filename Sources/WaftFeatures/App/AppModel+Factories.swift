import Foundation
import WaftCore

extension AppModel {
    static func makeSettings(_ dependencies: AppDependencies) -> SettingsModel {
        SettingsModel(
            store: dependencies.settingsStore,
            loginItem: dependencies.loginItem,
            audioInputs: dependencies.audioInputs,
        )
    }

    static func makePro(_ dependencies: AppDependencies) -> ProModel {
        ProModel(
            keyStore: dependencies.licenseStore,
            trialStore: dependencies.trialStore,
            checker: dependencies.licenseChecker,
            urlOpener: dependencies.urlOpener,
        )
    }

    static func makeSpeechModelController(
        _ dependencies: AppDependencies,
        settings: SettingsModel,
        pro: ProModel,
    ) -> SpeechModelController {
        SpeechModelController(
            transcriber: dependencies.transcriber,
            settings: settings,
            pro: pro,
            urlOpener: dependencies.urlOpener,
        )
    }

    static func makeVocabulary(_ dependencies: AppDependencies) -> VocabularyModel {
        VocabularyModel(
            store: dependencies.vocabularyStore,
            fileURL: dependencies.vocabularyFile,
            urlOpener: dependencies.urlOpener,
        )
    }

    static func makeQueue(
        _ dependencies: AppDependencies,
        history: HistoryModel,
        statistics: StatisticsModel,
        hud: HUDController,
    ) -> DictationQueue {
        DictationQueue(
            transcriber: dependencies.transcriber,
            rewriters: dependencies.rewriters,
            inserter: dependencies.inserter,
            clipboard: dependencies.clipboard,
            history: history,
            statistics: statistics,
            hud: hud,
        )
    }

    static func makeRecordings(
        _ dependencies: AppDependencies,
        settings: SettingsModel,
        hud: HUDController,
    ) -> RecordingController {
        RecordingController(
            recorder: dependencies.recorder,
            focusTracker: dependencies.focusTracker,
            keyboardState: dependencies.keyboardState,
            sounds: dependencies.sounds,
            otherSounds: OtherSoundsLowering(outputVolume: dependencies.outputVolume),
            settings: settings,
            hud: hud,
        )
    }

    static func makeTryout(
        _ dependencies: AppDependencies,
        settings: SettingsModel,
        pro: ProModel,
        defaultSample: String,
    ) -> TryoutModel {
        TryoutModel(
            rewriters: dependencies.rewriters,
            detector: dependencies.languageDetector,
            settings: settings,
            pro: pro,
            defaultSample: defaultSample,
        )
    }

    static func makeAPIKeys(_ dependencies: AppDependencies) -> PerProvider<APIKeyModel> {
        PerProvider { APIKeyModel(store: dependencies.apiKeyStores[$0]) }
    }

    static func makeTranslator(_ dependencies: AppDependencies, settings: SettingsModel, pro: ProModel) -> TranslatorModel {
        TranslatorModel(
            rewriters: dependencies.rewriters,
            detector: dependencies.languageDetector,
            settings: settings,
            pro: pro,
            clipboard: dependencies.clipboard,
        )
    }

    static func makeTranslatorShortcuts(
        _ dependencies: AppDependencies,
        _ shortcuts: GlobalShortcutController,
        settings: SettingsModel,
        pro: ProModel,
        hud: HUDController,
    ) -> TranslatorShortcuts {
        let actions = SelectionActions(
            rewriters: dependencies.rewriters,
            detector: dependencies.languageDetector,
            focusTracker: dependencies.focusTracker,
            keyboardState: dependencies.keyboardState,
            inserter: dependencies.inserter,
            clipboard: dependencies.clipboard,
            settings: settings,
            pro: pro,
            hud: hud,
        )

        return TranslatorShortcuts(shortcuts: shortcuts, selectionActions: actions)
    }

    static func makeTranscription(
        _ dependencies: AppDependencies,
        controller speechModelController: SpeechModelController,
        settings: SettingsModel,
        pro: ProModel,
    ) -> FileTranscriptionModel {
        FileTranscriptionModel(
            transcriber: dependencies.transcriber,
            decoder: dependencies.mediaDecoder,
            speechModelController: speechModelController,
            settings: settings,
            pro: pro,
            clipboard: dependencies.clipboard,
        )
    }
}
