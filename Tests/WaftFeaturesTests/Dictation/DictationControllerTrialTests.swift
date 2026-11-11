import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationControllerTrialTests {
    private static let rightOption: Int64 = 61
    private static let rightOptionFlag: UInt64 = 0x40

    private let monitor = FakeKeyEventMonitor()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()

    @Test
    func `moves to the fast model at the first recording after the trial ends, and still records`() async {
        var now = Date()
        let pro = ProModel.unlicensed(now: { now })
        settings.settings.speechModel = .accurate

        let speechModelController = await SpeechModelController.make(isReady: true, settings: settings, pro: pro)
        let controller = controller(speechModelController, pro: pro)

        now += 4 * 86400

        #expect(speechModelController.chosenModel == .accurate)

        await monitor.send(KeyEvent(
            kind: .modifiersChanged,
            keyCode: Self.rightOption,
            flags: Self.rightOptionFlag,
            isRepeat: false,
            timestamp: Uptime.now,
        ))

        #expect(await Poll.until(timeout: .seconds(5)) { controller.isRecording })
        #expect(speechModelController.chosenModel == .fast)
        #expect(speechModelController.state.canTranscribe)
    }

    private func controller(_ speechModelController: SpeechModelController, pro: ProModel) -> DictationController {
        let recordings = RecordingController(
            recorder: FakeAudioRecorder(),
            focusTracker: FakeFocusTracker(),
            keyboardState: FakeKeyboardState(holdsKeys: true),
            sounds: FakeFeedbackSoundPlayer(),
            otherSounds: OtherSoundsLowering(outputVolume: FakeOutputVolume()),
            settings: settings,
            hud: hud,
            hudDelay: .zero,
            watchdogInterval: 60,
        )

        let permissions = FakePermissionProvider([.microphone: .granted, .accessibility: .granted])
        let vocabularyStore = FakeValueStore(Vocabulary.empty)

        let controller = DictationController(
            keyEventMonitor: monitor,
            recordings: recordings,
            settings: settings,
            permissions: PermissionMonitor(provider: permissions),
            speechModelController: speechModelController,
            vocabulary: VocabularyModel(store: vocabularyStore, fileURL: URL(filePath: "/dev/null"), urlOpener: FakeURLOpener()),
            keyRecorder: KeyRecorder(),
            shortcutRecorder: ShortcutRecorder(settings: settings, shortcuts: .fake(settings: settings)),
            pro: pro,
            queue: .transcribing(with: FakeTranscriber(), hud: hud),
        )

        controller.start()

        return controller
    }
}
