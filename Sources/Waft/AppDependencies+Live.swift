import Foundation
import WaftCore
import WaftFeatures
import WaftPlatform
import WaftSpeech

extension AppDependencies {
    static func live() -> AppDependencies {
        let focusTracker = AccessibilityFocusTracker()
        let keyboardState = SystemKeyboardState()
        let apiKeyStores = PerProvider<any ValueStore<String>> { SecretFileStore.apiKey(for: $0) }

        let vocabularyFile = supportFile("dictionary.json")

        return AppDependencies(
            recorder: AudioEngineRecorder(),
            audioInputs: CoreAudioInputs(),
            transcriber: WhisperTranscriber(),
            mediaDecoder: MediaAudioReader(),
            rewriters: .http(apiKeys: apiKeyStores),
            languageDetector: NaturalLanguageDetector(),
            localServers: LocalServerBrowser(),
            keyEventMonitor: KeyEventTap(),
            keyboardState: keyboardState,
            shortcuts: GlobalShortcuts(layout: CurrentKeyboardLayout()) { _ in CarbonHotKey() },
            focusTracker: focusTracker,
            frontmostAppMonitor: WorkspaceAppMonitor(),
            urlOpener: WorkspaceURLOpener(),
            inserter: PasteboardInserter(focusTracker: focusTracker, keyboardState: keyboardState),
            clipboard: SystemClipboard(),
            permissions: SystemPermissions(),
            loginItem: MainAppLoginItem(),
            sounds: SystemSoundPlayer(),
            outputVolume: CoreAudioOutputVolume(),
            updater: SparkleUpdater(),
            lifecycle: SystemAppLifecycle(),
            settingsStore: UserDefaultsStore<Settings>(name: "settings", key: "settings"),
            vocabularyStore: JSONFileStore<Vocabulary>(name: "dictionary", url: vocabularyFile),
            vocabularyFile: vocabularyFile,
            historyStore: JSONFileStore<DictationHistory>(name: "history", url: supportFile("history.json")),
            statisticsStore: JSONFileStore<DictationStatistics>(name: "statistics", url: supportFile("stats.json")),
            usageStore: JSONFileStore<UsageLog>(name: "usage log", url: supportFile("usage.json")),
            usageSender: HTTPUsageReportSender(),
            apiKeyStores: apiKeyStores,
            licenseStore: SecretFileStore.license(),
            trialStore: UserDefaultsStore<Date>(name: "trial start", key: "trialStarted"),
            interfaceLanguageStore: InterfaceLanguageStore(),
            licenseChecker: Ed25519SignatureChecker(),
        )
    }

    private static func supportFile(_ name: String) -> URL {
        AppIdentity.supportDirectory.appending(path: name)
    }
}
