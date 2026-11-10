import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationQuitTests {
    private static let rightOption: Int64 = 61
    private static let rightOptionFlag: UInt64 = 0x40

    private let monitor = FakeKeyEventMonitor()
    private let inserter = FakeTextInserter()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()

    @Test
    func `finishes and delivers a dictation that is still recording when Waft quits`() async {
        let controller = await controller()

        await monitor.send(KeyEvent(
            kind: .modifiersChanged,
            keyCode: Self.rightOption,
            flags: Self.rightOptionFlag,
            isRepeat: false,
            timestamp: Uptime.now,
        ))

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: "Light", isHandsFree: false) })

        await controller.prepareToQuit()

        #expect(!controller.isRecording)
        #expect(await Poll.until(timeout: .seconds(5)) { inserter.insertions.map(\.text) == ["Hello world."] })
    }

    @Test
    func `quits at once when nothing is being recorded`() async {
        let controller = await controller()

        await controller.prepareToQuit()

        #expect(!controller.isRecording)
        #expect(inserter.insertions.isEmpty)
    }

    private func controller() async -> DictationController {
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

        let queue = DictationQueue.transcribing(
            with: FakeTranscriber(.success(.spoken("Hello world"))),
            hud: hud,
            inserter: inserter,
        )

        let controller = await DictationController(
            keyEventMonitor: monitor,
            recordings: recordings,
            settings: settings,
            permissions: PermissionMonitor(provider: FakePermissionProvider([.microphone: .granted, .accessibility: .granted])),
            speechModelController: .make(isReady: true, settings: settings),
            vocabulary: VocabularyModel(
                store: FakeValueStore(Vocabulary.empty),
                fileURL: URL(filePath: "/dev/null"),
                urlOpener: FakeURLOpener(),
            ),
            keyRecorder: KeyRecorder(),
            shortcutRecorder: ShortcutRecorder(settings: settings, shortcuts: .fake(settings: settings)),
            pro: .unlicensed(),
            queue: queue,
        )

        controller.start()

        return controller
    }
}
