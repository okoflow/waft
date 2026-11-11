import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct AppModelTests {
    private nonisolated static let licensePayload = Data(#"{"email":"ann@example.com"}"#.utf8)
    private nonisolated static let licenseSignature = Data([1, 2, 3])

    @Test
    func `releases the unstarted app and its connected models`() {
        var model: AppModel? = AppModel(dependencies: dependencies())
        weak let releasedApp = model
        weak let releasedSettings = model?.settings
        weak let releasedPro = model?.pro
        weak let releasedController = model?.speechModelController
        weak let releasedHistory = model?.history

        model = nil

        #expect(releasedApp == nil)
        #expect(releasedSettings == nil)
        #expect(releasedPro == nil)
        #expect(releasedController == nil)
        #expect(releasedHistory == nil)
    }

    @Test
    func `changes retained settings without reaching the released models`() throws {
        var model: AppModel? = AppModel(dependencies: dependencies())
        let settings = try #require(model?.settings)
        weak let releasedApp = model
        weak let releasedPro = model?.pro
        weak let releasedController = model?.speechModelController
        weak let releasedHistory = model?.history

        model = nil

        #expect(releasedApp == nil)
        #expect(releasedPro == nil)
        #expect(releasedController == nil)
        #expect(releasedHistory == nil)

        settings.settings.languages = .preferred(by: ["de"])
        settings.settings.speechModel = .accurate
        settings.settings.historyLimit = 100
    }

    @Test(arguments: [(PermissionStatus.granted, AppStatus.speechModel(SpeechModelState())), (.denied, .needsPermission)])
    func `reports missing permissions before the speech model`(accessibility: PermissionStatus, status: AppStatus) {
        let model = AppModel(dependencies: dependencies(permissions: [.microphone: .granted, .accessibility: accessibility]))

        #expect(model.status == status)
    }

    @Test
    func `deletes the usage log as soon as sharing is turned off`() {
        var settings = Settings(languages: .preferred(by: []))
        settings.usageSharing = .allowed
        let usageStore = FakeValueStore(UsageLog(installation: UUID()))
        let model = AppModel(dependencies: dependencies(settings: settings, usageStore: usageStore))

        model.settings.sharesUsage = false

        #expect(usageStore.value == nil)
    }

    @Test
    func `returns to the accurate speech model when a license is activated after the trial`() {
        var settings = Settings(languages: .preferred(by: []))
        settings.speechModel = .accurate
        let model = AppModel(dependencies: dependencies(settings: settings, trialStore: FakeValueStore(Date.distantPast)))

        #expect(model.speechModelController.chosenModel == .fast)

        model.pro.draft = "WFT1.\(Self.licensePayload.base64EncodedString()).\(Self.licenseSignature.base64EncodedString())"
        model.pro.activateDraft()

        #expect(model.speechModelController.chosenModel == .accurate)
    }

    private func dependencies(
        permissions: [Permission: PermissionStatus] = [:],
        settings: Settings = Settings(languages: .preferred(by: [])),
        usageStore: FakeValueStore<UsageLog> = FakeValueStore<UsageLog>(),
        trialStore: FakeValueStore<Date> = FakeValueStore<Date>(),
    ) -> AppDependencies {
        AppDependencies(
            recorder: FakeAudioRecorder(),
            audioInputs: FakeAudioInputProvider(),
            transcriber: FakeTranscriber(),
            mediaDecoder: FakeMediaDecoder(),
            rewriters: .all(FakeTextRewriter()),
            languageDetector: FakeLanguageDetector(),
            localServers: FakeLocalServerBrowser([:]),
            keyEventMonitor: FakeKeyEventMonitor(),
            keyboardState: FakeKeyboardState(holdsKeys: false),
            shortcuts: .fake(),
            focusTracker: FakeFocusTracker(),
            frontmostAppMonitor: FakeFrontmostAppMonitor(),
            urlOpener: FakeURLOpener(),
            inserter: FakeTextInserter(),
            clipboard: FakeClipboard(),
            permissions: FakePermissionProvider(permissions),
            loginItem: FakeLoginItem(),
            sounds: FakeFeedbackSoundPlayer(),
            outputVolume: FakeOutputVolume(),
            updater: FakeAppUpdater(),
            lifecycle: FakeAppLifecycle(),
            settingsStore: FakeValueStore(settings),
            vocabularyStore: FakeValueStore<Vocabulary>(),
            vocabularyFile: URL(filePath: "/tmp/Vocabulary.json"),
            historyStore: FakeValueStore<DictationHistory>(),
            statisticsStore: FakeValueStore<DictationStatistics>(),
            usageStore: usageStore,
            usageSender: FakeUsageReportSender(),
            apiKeyStores: PerProvider(claude: FakeValueStore<String>(), openAI: FakeValueStore<String>()),
            licenseStore: FakeValueStore<String>(),
            trialStore: trialStore,
            interfaceLanguageStore: FakeValueStore<String>(),
            licenseChecker: FakeLicenseSignatureChecker(signature: Self.licenseSignature, payload: Self.licensePayload),
        )
    }
}

private final class FakeFrontmostAppMonitor: FrontmostAppMonitor {
    let frontmostApp: RunningApp? = nil
    let activations = AsyncStream<RunningApp> { $0.finish() }

    func start() {}
}
