import Foundation
import WaftCore
import WaftFeatures
import WaftPlatform
import WaftSpeech

extension AppDependencies {
    static func live() -> AppDependencies {
        let focusTracker = AccessibilityFocusTracker()
        let keyboardState = SystemKeyboardState()
        let apiKeyStores = PerProvider<any ValueStore<String>>(
            claude: KeychainStore.apiKey(for: .claude),
            openAI: KeychainStore.apiKey(for: .openAI),
        )
        let vocabularyFile = AppIdentity.supportDirectory.appending(path: "dictionary.json")
        let historyFile = AppIdentity.supportDirectory.appending(path: "history.json")
        let statsFile = AppIdentity.supportDirectory.appending(path: "stats.json")

        return AppDependencies(
            recorder: AudioEngineRecorder(),
            audioInputs: CoreAudioInputs(),
            transcriber: WhisperTranscriber(),
            mediaDecoder: MediaAudioReader(),
            rewriters: .http(apiKeys: apiKeyStores),
            localServers: LocalServerBrowser(),
            keyEventMonitor: KeyEventTap(),
            keyboardState: keyboardState,
            modeShortcut: CarbonHotKey.modeCycle(),
            focusTracker: focusTracker,
            frontmostAppMonitor: WorkspaceAppMonitor(),
            urlOpener: WorkspaceURLOpener(),
            inserter: PasteboardInserter(focusTracker: focusTracker, keyboardState: keyboardState),
            clipboard: SystemClipboard(),
            permissions: SystemPermissions(),
            loginItem: MainAppLoginItem(),
            sounds: SystemSoundPlayer(),
            updater: SparkleUpdater(),
            lifecycle: SystemAppLifecycle(),
            settingsStore: UserDefaultsStore<Settings>(name: "settings", key: "settings"),
            vocabularyStore: JSONFileStore<Vocabulary>(name: "dictionary", url: vocabularyFile),
            vocabularyFile: vocabularyFile,
            historyStore: JSONFileStore<DictationHistory>(name: "history", url: historyFile, isPrivate: true),
            statsStore: JSONFileStore<DictationStats>(name: "stats", url: statsFile),
            apiKeyStores: apiKeyStores,
            licenseStore: KeychainStore.license(),
            trialStore: UserDefaultsStore<Date>(name: "trial start", key: "trialStarted"),
            interfaceLanguageStore: InterfaceLanguageStore(),
            licenseChecker: Ed25519SignatureChecker(),
        )
    }
}
