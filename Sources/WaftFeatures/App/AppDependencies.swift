package import Foundation
package import WaftCore

package struct AppDependencies {
    let recorder: any AudioRecorder
    let audioInputs: any AudioInputProvider
    let transcriber: any Transcriber
    let mediaDecoder: any MediaDecoder
    let rewriters: Rewriters
    let languageDetector: any LanguageDetector
    let localServers: any LocalServerBrowsing
    let keyEventMonitor: any KeyEventMonitor
    let keyboardState: any KeyboardState
    let shortcuts: GlobalShortcuts
    let focusTracker: any FocusTracker
    let frontmostAppMonitor: any FrontmostAppMonitor
    let urlOpener: any URLOpener
    let inserter: any TextInserter
    let clipboard: any Clipboard
    let permissions: any PermissionProvider
    let loginItem: any LoginItem
    let sounds: any FeedbackSoundPlayer
    let outputVolume: any OutputVolume
    let updater: any AppUpdater
    let lifecycle: any AppLifecycle
    let settingsStore: any ValueStore<Settings>
    let vocabularyStore: any ValueStore<Vocabulary>
    let vocabularyFile: URL
    let historyStore: any ValueStore<DictationHistory>
    let statisticsStore: any ValueStore<DictationStatistics>
    let apiKeyStores: PerProvider<any ValueStore<String>>
    let licenseStore: any ValueStore<String>
    let trialStore: any ValueStore<Date>
    let interfaceLanguageStore: any ValueStore<String>
    let licenseChecker: any LicenseSignatureChecking

    package init(
        recorder: any AudioRecorder,
        audioInputs: any AudioInputProvider,
        transcriber: any Transcriber,
        mediaDecoder: any MediaDecoder,
        rewriters: Rewriters,
        languageDetector: any LanguageDetector,
        localServers: any LocalServerBrowsing,
        keyEventMonitor: any KeyEventMonitor,
        keyboardState: any KeyboardState,
        shortcuts: GlobalShortcuts,
        focusTracker: any FocusTracker,
        frontmostAppMonitor: any FrontmostAppMonitor,
        urlOpener: any URLOpener,
        inserter: any TextInserter,
        clipboard: any Clipboard,
        permissions: any PermissionProvider,
        loginItem: any LoginItem,
        sounds: any FeedbackSoundPlayer,
        outputVolume: any OutputVolume,
        updater: any AppUpdater,
        lifecycle: any AppLifecycle,
        settingsStore: any ValueStore<Settings>,
        vocabularyStore: any ValueStore<Vocabulary>,
        vocabularyFile: URL,
        historyStore: any ValueStore<DictationHistory>,
        statisticsStore: any ValueStore<DictationStatistics>,
        apiKeyStores: PerProvider<any ValueStore<String>>,
        licenseStore: any ValueStore<String>,
        trialStore: any ValueStore<Date>,
        interfaceLanguageStore: any ValueStore<String>,
        licenseChecker: any LicenseSignatureChecking,
    ) {
        self.recorder = recorder
        self.audioInputs = audioInputs
        self.transcriber = transcriber
        self.mediaDecoder = mediaDecoder
        self.rewriters = rewriters
        self.languageDetector = languageDetector
        self.localServers = localServers
        self.keyEventMonitor = keyEventMonitor
        self.keyboardState = keyboardState
        self.shortcuts = shortcuts
        self.focusTracker = focusTracker
        self.frontmostAppMonitor = frontmostAppMonitor
        self.urlOpener = urlOpener
        self.inserter = inserter
        self.clipboard = clipboard
        self.permissions = permissions
        self.loginItem = loginItem
        self.sounds = sounds
        self.outputVolume = outputVolume
        self.updater = updater
        self.lifecycle = lifecycle
        self.settingsStore = settingsStore
        self.vocabularyStore = vocabularyStore
        self.vocabularyFile = vocabularyFile
        self.historyStore = historyStore
        self.statisticsStore = statisticsStore
        self.apiKeyStores = apiKeyStores
        self.licenseStore = licenseStore
        self.trialStore = trialStore
        self.interfaceLanguageStore = interfaceLanguageStore
        self.licenseChecker = licenseChecker
    }
}
