import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationControllerTrialTests {
    private static let rightOption: Int64 = 61
    private static let rightOptionFlag: UInt64 = 0x40
    private static let leftOption: Int64 = 58
    private static let leftOptionFlag: UInt64 = 0x20

    private let monitor = FakeKeyEventMonitor()
    private let rewriter = FakeTextRewriter(.success("Hello, world."))
    private let inserter = FakeTextInserter()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()
    private let start = Uptime.now

    @Test
    func `moves to the fast model at the first recording after the trial ends, and still records`() async {
        var now = Date()
        let pro = ProModel.unlicensed(now: { now })
        settings.settings.speechModel = .accurate

        let speechModelController = await SpeechModelController.make(isReady: true, settings: settings, pro: pro)
        let controller = controller(speechModelController, pro: pro)

        now += 4 * 86400

        #expect(speechModelController.chosenModel == .accurate)

        await send(Self.rightOption, flags: Self.rightOptionFlag, at: 0)

        #expect(await Poll.until(timeout: .seconds(5)) { controller.isRecording })
        #expect(speechModelController.chosenModel == .fast)
        #expect(speechModelController.state.canTranscribe)
    }

    @Test(arguments: [(0.0, "Hello, world.", 1), (4.0, "Hello world.", 0)])
    func `dictates in an AI mode during the trial and in Light after it ends`(
        daysSinceStart: Double,
        text: String,
        requestCount: Int,
    ) async {
        var now = Date()
        let pro = ProModel.unlicensed(now: { now })
        settings.settings.mode = .clean

        let controller = await controller(.make(isReady: true, settings: settings, pro: pro), pro: pro)

        now += daysSinceStart * 86400

        await send(Self.rightOption, flags: Self.rightOptionFlag, at: 0)
        await send(Self.rightOption, flags: 0, at: 0.5)

        #expect(await Poll.until(timeout: .seconds(5)) { inserter.insertions.map(\.text) == [text] })
        #expect(rewriter.requests.count == requestCount)
        #expect(!controller.isRecording)
    }

    @Test
    func `starts an edit by voice during the trial`() async {
        let pro = ProModel.unlicensed()
        settings.settings.editKey = PushToTalkKey(keyCode: Self.leftOption)

        let controller = await controller(.make(isReady: true, settings: settings, pro: pro), pro: pro)

        await send(Self.leftOption, flags: Self.leftOptionFlag, at: 0)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: "Edit", isHandsFree: false) })
        #expect(controller.isRecording)
    }

    private func controller(_ speechModelController: SpeechModelController, pro: ProModel) -> DictationController {
        let recordings = RecordingController(
            recorder: FakeAudioRecorder(),
            focusTracker: FakeFocusTracker(.notesWithSelection),
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
        let transcriber = FakeTranscriber(.success(.spoken("hello world")))

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
            queue: .transcribing(with: transcriber, hud: hud, rewriter: rewriter, inserter: inserter),
        )

        controller.start()

        return controller
    }

    private func send(_ keyCode: Int64, flags: UInt64, at offset: TimeInterval) async {
        await monitor.send(KeyEvent(
            kind: .modifiersChanged,
            keyCode: keyCode,
            flags: flags,
            isRepeat: false,
            timestamp: start + offset,
        ))
    }
}
