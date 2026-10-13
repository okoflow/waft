import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationControllerTests {
    private static let rightOption: Int64 = 61
    private static let rightOptionFlag: UInt64 = 0x40
    private static let leftOption: Int64 = 58
    private static let leftOptionFlag: UInt64 = 0x20

    private static let microphoneDenied = HUDMessage(
        kind: .information,
        title: "Waft can't use the microphone. Allow it in Settings › General.",
    )

    private let monitor = FakeKeyEventMonitor()
    private let recorder = FakeAudioRecorder()
    private let transcriber = FakeTranscriber(.success(.spoken("Hello world")))
    private let inserter = FakeTextInserter()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()
    private let vocabularyStore = FakeValueStore(Vocabulary.empty)
    private let keyRecorder = KeyRecorder()
    private let start = Uptime.now

    private static func permissions(microphone: PermissionStatus, answer: PermissionStatus = .granted) -> PermissionMonitor {
        let provider = FakePermissionProvider([.microphone: microphone, .accessibility: .granted], answers: [.microphone: answer])

        return PermissionMonitor(provider: provider)
    }

    @Test
    func `starts a recording when the dictation key goes down`() async {
        let controller = await controller()
        await pressDictationKey(at: 0)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.startedDevices.isEmpty })
        #expect(controller.isRecording)
    }

    @Test
    func `submits the recording to the queue when the key is released after the minimum hold`() async {
        let controller = await controller()
        await pressDictationKey(at: 0)
        await releaseDictationKey(at: 0.5)

        #expect(await Poll.until(timeout: .seconds(5)) { !transcriber.requests.isEmpty })
        #expect(recorder.releaseTimes == [start + 0.5])
        #expect(!controller.isRecording)
    }

    @Test
    func `discards a recording released before the minimum hold without submitting it`() async {
        let controller = await controller()
        await pressDictationKey(at: 0)
        await releaseDictationKey(at: 0.1)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.releaseTimes.isEmpty })
        #expect(recorder.releaseTimes == [nil])
        #expect(transcriber.requests.isEmpty)
        #expect(!controller.isRecording)
    }

    @Test
    func `refuses to record while the speech model is not ready and shows its message`() async throws {
        let message = try #require(SpeechModelState().notReadyMessage)
        let refusal = HUDMessage(kind: .information, title: message)
        let controller = await controller(isSpeechModelReady: false)
        await pressDictationKey(at: 0)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(refusal) })
        #expect(!controller.isRecording)
    }

    @Test
    func `refuses to record when the microphone is denied`() async {
        let controller = await controller(permissions: Self.permissions(microphone: .denied))
        await pressDictationKey(at: 0)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(Self.microphoneDenied) })
        #expect(!controller.isRecording)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `refuses editing by voice without Pro`() async {
        settings.settings.editKey = PushToTalkKey(keyCode: Self.leftOption)
        let controller = await controller(pro: .unlicensed(trialStarted: .distantPast))
        await send(Self.leftOption, flags: Self.leftOptionFlag, at: 0)

        #expect(await Poll.until(timeout: .seconds(5)) {
            hud.content == .message(HUDMessage(kind: .information, title: "Editing by voice is part of Waft Pro."))
        })
        #expect(!controller.isRecording)
    }

    @Test
    func `ignores key events while the key recorder records a new key`() async {
        let controller = await controller()
        keyRecorder.start(.dictation, excluding: nil) { _ in }
        await pressDictationKey(at: 0)
        await releaseDictationKey(at: 0.5)

        #expect(!controller.isRecording)
        #expect(recorder.startedDevices.isEmpty)
    }

    @Test
    func `ignores the edit key while a dictation is recording`() async {
        settings.settings.editKey = PushToTalkKey(keyCode: Self.leftOption)
        let controller = await controller()
        await pressDictationKey(at: 0)
        await send(Self.leftOption, flags: Self.rightOptionFlag | Self.leftOptionFlag, at: 0.1)
        await send(Self.leftOption, flags: Self.rightOptionFlag, at: 0.6)
        await releaseDictationKey(at: 1)

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })
        #expect(recorder.startedDevices.count == 1)
        #expect(recorder.releaseTimes == [start + 1])
        #expect(!controller.isRecording)
    }

    @Test
    func `locks a dictation hands-free on a double tap`() async {
        let controller = await controller()
        await pressDictationKey(at: 0)
        await releaseDictationKey(at: 0.1)
        await pressDictationKey(at: 0.2)
        await releaseDictationKey(at: 0.3)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: nil, isHandsFree: true) })
        #expect(controller.isRecording)
    }

    @Test
    func `starts a recording on the tap after a refused one`() async {
        settings.settings.dictationStart = .tap
        let permissions = Self.permissions(microphone: .denied, answer: .granted)
        let controller = await controller(permissions: permissions)
        await pressDictationKey(at: 0)
        await releaseDictationKey(at: 0.1)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(Self.microphoneDenied) })

        await permissions.request(.microphone)
        await pressDictationKey(at: 1)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.startedDevices.isEmpty })
        #expect(controller.isRecording)
    }

    @Test
    func `finishes a recording whose key-up never arrives`() async {
        let controller = await controller(keyboardState: FakeKeyboardState(holdsKeys: false), watchdogInterval: 0)
        await pressDictationKey(at: -1)

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })
        #expect(!controller.isRecording)
    }

    @Test
    func `reloads the dictionary from disk for each dictation`() async {
        let controller = await controller()
        vocabularyStore.value = Vocabulary(terms: [Vocabulary.Term(term: "Okoflow", spoken: ["oko flow"])], snippets: [])
        await pressDictationKey(at: 0)
        await releaseDictationKey(at: 0.5)

        #expect(await Poll.until(timeout: .seconds(5)) { !transcriber.requests.isEmpty })
        #expect(transcriber.requests.map(\.vocabulary) == [["Okoflow"]])
        #expect(!controller.isRecording)
    }

    private func controller(
        isSpeechModelReady: Bool = true,
        permissions: PermissionMonitor = DictationControllerTests.permissions(microphone: .granted),
        pro: ProModel = .unlicensed(),
        keyboardState: FakeKeyboardState = FakeKeyboardState(holdsKeys: true),
        watchdogInterval: TimeInterval = 60,
    ) async -> DictationController {
        let speechModelController = isSpeechModelReady
            ? await SpeechModelController.ready(settings: settings)
            : SpeechModelController(transcriber: transcriber, settings: settings, pro: pro)
        let recordings = RecordingController(
            recorder: recorder,
            focusTracker: FakeFocusTracker(),
            keyboardState: keyboardState,
            sounds: FakeFeedbackSoundPlayer(),
            settings: settings,
            hud: hud,
            hudDelay: .zero,
            watchdogInterval: watchdogInterval,
        )
        let controller = DictationController(
            keyEventMonitor: monitor,
            recordings: recordings,
            settings: settings,
            permissions: permissions,
            speechModelController: speechModelController,
            vocabulary: VocabularyModel(store: vocabularyStore, fileURL: URL(filePath: "/dev/null"), urlOpener: FakeURLOpener()),
            keyRecorder: keyRecorder,
            pro: pro,
            queue: queue(),
        )

        controller.start()

        return controller
    }

    private func queue() -> DictationQueue {
        DictationQueue(
            transcriber: transcriber,
            rewriters: .all(FakeTextRewriter()),
            inserter: inserter,
            clipboard: FakeClipboard(),
            history: HistoryModel(store: FakeValueStore<DictationHistory>(), settings: settings, clipboard: FakeClipboard()),
            statistics: StatisticsModel(store: FakeValueStore<DictationStatistics>()),
            hud: hud,
        )
    }

    private func pressDictationKey(at offset: TimeInterval) async {
        await send(Self.rightOption, flags: Self.rightOptionFlag, at: offset)
    }

    private func releaseDictationKey(at offset: TimeInterval) async {
        await send(Self.rightOption, flags: 0, at: offset)
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
