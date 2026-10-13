package import Foundation
import WaftCore

package final class AppModel {
    package let settings: SettingsModel
    package let windows = WindowPresenter()

    let permissions: PermissionMonitor
    let speechModel: SpeechModelController
    let modeSwitcher: ModeSwitcher
    let history: HistoryModel
    let stats: StatsModel
    let vocabulary: VocabularyModel
    let apiKeys: PerProvider<APIKeyModel>
    let localModels: LocalModelsModel
    let frontmostApp: FrontmostAppTracker
    let keyRecorder: KeyRecorder
    let onboarding: OnboardingModel
    let transcription: FileTranscriptionModel
    let pro: ProModel
    let updates: UpdatesModel
    let interfaceLanguage: InterfaceLanguageModel
    let queue: DictationQueue

    private let hud: HUDController
    private let keyMonitor: KeyMonitorController
    private let dictation: DictationController
    private let inserter: any TextInserter
    private let lifecycle: any AppLifecycle

    var status: AppStatus {
        if dictation.isRecording {
            return .recording
        }

        if lacksPermissions {
            return .needsPermission
        }

        guard speechModel.state.canTranscribe else { return .speechModel(speechModel.state) }

        return .ready
    }

    var needsSetup: Bool {
        !settings.settings.hasCompletedSetup || !permissions.allGranted
    }

    private var lacksPermissions: Bool {
        !permissions.allGranted || keyMonitor.status == .unavailable
    }

    package init(dependencies: AppDependencies) {
        settings = Self.makeSettings(dependencies)
        permissions = PermissionMonitor(provider: dependencies.permissions)
        pro = Self.makePro(dependencies)
        speechModel = SpeechModelController(transcriber: dependencies.transcriber, settings: settings, pro: pro)
        hud = HUDController()
        keyRecorder = KeyRecorder()
        stats = StatsModel(store: dependencies.statsStore)
        history = HistoryModel(store: dependencies.historyStore, settings: settings, clipboard: dependencies.clipboard)
        vocabulary = Self.makeVocabulary(dependencies)
        queue = Self.makeQueue(dependencies, history: history, stats: stats, hud: hud)
        keyMonitor = KeyMonitorController(monitor: dependencies.keyEventMonitor)
        dictation = DictationController(
            keyEventMonitor: dependencies.keyEventMonitor,
            recordings: Self.makeRecordings(dependencies, settings: settings, hud: hud),
            settings: settings,
            permissions: permissions,
            speechModel: speechModel,
            vocabulary: vocabulary,
            keyRecorder: keyRecorder,
            pro: pro,
            queue: queue,
        )
        modeSwitcher = ModeSwitcher(shortcut: dependencies.modeShortcut, settings: settings, hud: hud, pro: pro)
        apiKeys = Self.makeAPIKeys(dependencies)
        localModels = LocalModelsModel(browser: dependencies.localServers, settings: settings)
        frontmostApp = FrontmostAppTracker(monitor: dependencies.frontmostAppMonitor)
        onboarding = OnboardingModel(permissions: permissions)
        transcription = Self.makeTranscription(dependencies, speechModel: speechModel, settings: settings, pro: pro)
        updates = UpdatesModel(updater: dependencies.updater)
        interfaceLanguage = InterfaceLanguageModel(store: dependencies.interfaceLanguageStore, lifecycle: dependencies.lifecycle)
        inserter = dependencies.inserter
        lifecycle = dependencies.lifecycle

        windows.model = self
        connectModels()
    }

    private static func makeSettings(_ dependencies: AppDependencies) -> SettingsModel {
        SettingsModel(
            store: dependencies.settingsStore,
            loginItem: dependencies.loginItem,
            audioInputs: dependencies.audioInputs,
        )
    }

    private static func makePro(_ dependencies: AppDependencies) -> ProModel {
        ProModel(
            keyStore: dependencies.licenseStore,
            trialStore: dependencies.trialStore,
            checker: dependencies.licenseChecker,
            urlOpener: dependencies.urlOpener,
        )
    }

    private static func makeVocabulary(_ dependencies: AppDependencies) -> VocabularyModel {
        VocabularyModel(
            store: dependencies.vocabularyStore,
            fileURL: dependencies.vocabularyFile,
            urlOpener: dependencies.urlOpener,
        )
    }

    private static func makeQueue(
        _ dependencies: AppDependencies,
        history: HistoryModel,
        stats: StatsModel,
        hud: HUDController,
    ) -> DictationQueue {
        DictationQueue(
            transcriber: dependencies.transcriber,
            rewriters: dependencies.rewriters,
            inserter: dependencies.inserter,
            clipboard: dependencies.clipboard,
            history: history,
            stats: stats,
            hud: hud,
        )
    }

    private static func makeRecordings(
        _ dependencies: AppDependencies,
        settings: SettingsModel,
        hud: HUDController,
    ) -> RecordingController {
        RecordingController(
            recorder: dependencies.recorder,
            focusTracker: dependencies.focusTracker,
            keyboardState: dependencies.keyboardState,
            sounds: dependencies.sounds,
            settings: settings,
            hud: hud,
        )
    }

    private static func makeAPIKeys(_ dependencies: AppDependencies) -> PerProvider<APIKeyModel> {
        PerProvider(
            claude: APIKeyModel(store: dependencies.apiKeyStores.claude),
            openAI: APIKeyModel(store: dependencies.apiKeyStores.openAI),
        )
    }

    private static func makeTranscription(
        _ dependencies: AppDependencies,
        speechModel: SpeechModelController,
        settings: SettingsModel,
        pro: ProModel,
    ) -> FileTranscriptionModel {
        FileTranscriptionModel(
            transcriber: dependencies.transcriber,
            decoder: dependencies.mediaDecoder,
            speechModel: speechModel,
            settings: settings,
            pro: pro,
            clipboard: dependencies.clipboard,
        )
    }

    package func start() {
        permissions.startMonitoring()
        speechModel.start()
        keyMonitor.start()
        dictation.start()
        modeSwitcher.start()
        frontmostApp.start()
        updates.start()
        hud.makePanel()

        if needsSetup {
            showSetup()
        }
    }

    package func prepareToQuit() async {
        await inserter.waitUntilIdle()
    }

    package func open(_ url: URL) {
        guard let key = ActivationLink.key(in: url) else { return }

        pro.draft = key
        pro.activateDraft()
        windows.showSettings(.pro)
    }

    func showSetup() {
        if settings.settings.hasCompletedSetup {
            onboarding.resume()
        }

        windows.showOnboarding()
    }

    func quit() {
        lifecycle.quit()
    }

    private func connectModels() {
        settings.onLanguagesChange = { [speechModel] in speechModel.reload() }
        settings.onSpeechModelChange = { [speechModel] in speechModel.modelDidChange() }
        settings.onHistoryLimitsChange = { [history] in history.keepWithinLimits() }
        permissions.onChange = { [weak self] in self?.permissionsDidChange() }
        speechModel.onReady = { [weak self] in self?.speechModelDidBecomeReady() }
        onboarding.onFinish = { [weak self] in self?.finishOnboarding() }
        updates.onShowingUpdateChange = { [weak self] in self?.windows.updateActivationPolicy() }
    }

    private func permissionsDidChange() {
        keyMonitor.permissionsDidChange()
        onboarding.permissionsDidChange()
    }

    private func speechModelDidBecomeReady() {
        let key = settings.settings.pushToTalkKey.shortTitle

        hud.show(HUDMessage(kind: .info, title: String(localized: "Ready: hold \(key) and speak")))
    }

    private func finishOnboarding() {
        settings.settings.hasCompletedSetup = true

        windows.closeOnboarding()
    }
}
