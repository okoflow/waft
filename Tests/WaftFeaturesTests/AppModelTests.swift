import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct AppModelTests {
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
    func `keeps retained settings usable after their connected models are released`() throws {
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

        #expect(settings.settings.languages.languages.contains(.german))
        #expect(settings.settings.speechModel == .accurate)
        #expect(settings.settings.historyLimit == 100)
    }

    @Test(arguments: [(PermissionStatus.granted, AppStatus.speechModel(SpeechModelState())), (.denied, .needsPermission)])
    func `reports missing permissions before the speech model`(accessibility: PermissionStatus, status: AppStatus) {
        let model = AppModel(dependencies: dependencies(permissions: [.microphone: .granted, .accessibility: accessibility]))

        #expect(model.status == status)
    }

    private func dependencies(permissions: [Permission: PermissionStatus] = [:]) -> AppDependencies {
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
            settingsStore: FakeValueStore(Settings(languages: .preferred(by: []))),
            vocabularyStore: FakeValueStore<Vocabulary>(),
            vocabularyFile: URL(filePath: "/tmp/Vocabulary.json"),
            historyStore: FakeValueStore<DictationHistory>(),
            statisticsStore: FakeValueStore<DictationStatistics>(),
            apiKeyStores: PerProvider(claude: FakeValueStore<String>(), openAI: FakeValueStore<String>()),
            licenseStore: FakeValueStore<String>(),
            trialStore: FakeValueStore<Date>(),
            interfaceLanguageStore: FakeValueStore<String>(),
            licenseChecker: FakeLicenseSignatureChecker(signature: Data(), payload: Data()),
        )
    }
}

private final class FakeFrontmostAppMonitor: FrontmostAppMonitor {
    let frontmostApp: RunningApp? = nil
    let activations = AsyncStream<RunningApp> { $0.finish() }

    func start() {}
}
