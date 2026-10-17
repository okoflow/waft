import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct RecordingControllerTests {
    private static let first = RecordingID.none.next
    private static let second = first.next
    private nonisolated static let dictation = RecordingTrigger(purpose: .dictation, key: .function, action: .startRecording)
    private nonisolated static let edit = RecordingTrigger(purpose: .edit, key: .function, action: .startRecording)
    private nonisolated static let emailReply = CustomMode(name: "Email reply", instructions: "Reply.")

    private let recorder = FakeAudioRecorder()

    private let focusTracker = FakeFocusTracker(.app(
        "com.example.notes",
        element: FakeFocusedElement(selectedText: "Meeting at noon"),
    ))

    private let sounds = FakeFeedbackSoundPlayer()
    private let settings = SettingsModel.inMemory()
    private let hud = HUDController.offscreen()

    @Test
    func `begins recording from the microphone chosen in settings`() async {
        settings.settings.microphoneID = "usb-microphone"
        let recordings = model()
        recordings.begin(Self.dictation)

        #expect(recordings.isRecording)
        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.startedDevices.isEmpty })
        #expect(recorder.startedDevices == ["usb-microphone"])
    }

    @Test(arguments: [(true, [FeedbackSound.recordingStarted, .recordingFinished]), (false, [])])
    func `plays the start and finish sounds only while sounds are on`(playsSounds: Bool, played: [FeedbackSound]) async {
        settings.settings.playsSounds = playsSounds
        let recordings = model()
        recordings.begin(Self.dictation)
        recorder.send(.started(Self.first, deviceName: "Built-in Microphone"))

        #expect(await Poll.until(timeout: .seconds(5)) { sounds.played == Array(played.dropLast()) })

        recordings.finish(releasedAt: 2)

        #expect(sounds.played == played)
    }

    @Test
    func `ignores recorder events for an earlier recording`() async {
        let recordings = model()
        recordings.begin(Self.dictation)
        recordings.discard(because: .tooShort)
        recordings.begin(Self.dictation)
        recorder.send(.started(Self.first, deviceName: "Built-in Microphone"))
        recorder.send(.failed(Self.first, .deviceUnavailable))
        recorder.send(.started(Self.second, deviceName: "Built-in Microphone"))

        #expect(await Poll.until(timeout: .seconds(5)) { sounds.played == [.recordingStarted] })
        #expect(recordings.isRecording)
        #expect(hud.content == .listening(badge: nil, isHandsFree: false))
    }

    @Test
    func `shows the failure and stops the recorder when the recording fails`() async {
        let recordings = model()
        recordings.begin(Self.dictation)
        recorder.send(.failed(Self.first, .deviceUnavailable))

        #expect(await Poll.until(timeout: .seconds(5)) { recorder.releaseTimes == [nil] })
        #expect(hud.content == .message(.recordingFailed(RecordingFailure.deviceUnavailable.message)))
        #expect(!recordings.isRecording)
    }

    @Test
    func `hands the HUD to the transcribing label and delivers the samples from the captured focus on finish`() async {
        var delivery: (app: String?, samples: [Float])?
        let recordings = model()
        recordings.onFinish = { _, target, samples in delivery = (target.bundleIdentifier, samples) }
        recordings.begin(Self.dictation)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: nil, isHandsFree: false) })

        focusTracker.focus = .app("com.example.mail")
        recordings.finish(releasedAt: 2)

        #expect(hud.content == .working(DictationQueue.transcribingLabel))
        #expect(await Poll.until(timeout: .seconds(5)) { delivery != nil })
        #expect(delivery?.app == "com.example.notes")
        #expect(delivery?.samples == [0.1, 0.2])
        #expect(recorder.releaseTimes == [2])
    }

    @Test(arguments: [
        (RecordingFailure.formatChanged, RecordingFailure.formatChanged.message),
        (nil, "No audio was captured."),
    ] as [(RecordingFailure?, String)])
    func `reports missing audio with the recorder's failure or a generic message`(
        failure: RecordingFailure?,
        detail: String,
    ) async {
        var deliveryCount = 0
        let recordings = model(recorder: FakeAudioRecorder(samples: [], failure: failure))
        recordings.onFinish = { _, _, _ in deliveryCount += 1 }
        recordings.begin(Self.dictation)
        recordings.finish(releasedAt: 2)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(.recordingFailed(detail)) })
        #expect(deliveryCount == 0)
    }

    @Test
    func `hides the listening HUD and stops the recorder without a release time on discard`() async {
        let recordings = model()
        recordings.begin(Self.dictation)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: nil, isHandsFree: false) })

        recordings.discard(because: .otherKeyPressed)

        #expect(hud.content == nil)
        #expect(!recordings.isRecording)
        #expect(await Poll.until(timeout: .seconds(5)) { recorder.releaseTimes == [nil] })
    }

    @Test
    func `refuses a trigger with its reason and ends it silently`() {
        let recordings = model()
        recordings.refuse(Self.dictation, because: "The speech model isn't ready yet")

        #expect(!recordings.isRecording)
        #expect(hud.content == .message(HUDMessage(kind: .information, title: "The speech model isn't ready yet")))

        recordings.finish(releasedAt: 2)

        #expect(recordings.recording == nil)
        #expect(sounds.played.isEmpty)
    }

    @Test(arguments: [0, 0.1] as [TimeInterval])
    func `rejects an edit without selected text even after a slow focus lookup`(focusLookup: TimeInterval) async {
        let message = HUDMessage(kind: .information, title: "Select the text to edit, then hold the key and say what to change.")
        focusTracker.focus = .app("com.example.notes", element: FakeFocusedElement(selectedText: nil))
        focusTracker.lookupDuration = focusLookup
        let recordings = model(recorder: recorder, hudDelay: .milliseconds(10))
        recordings.begin(Self.edit)

        #expect(await Poll.until(timeout: .seconds(5)) { recorder.releaseTimes == [nil] })
        #expect(!recordings.isRecording)
        #expect(hud.content == .message(message))
    }

    @Test
    func `keeps the selected text for an edit`() async {
        let recordings = model()
        recordings.begin(Self.edit)

        #expect(await Poll.until(timeout: .seconds(5)) { recordings.recording?.selection == "Meeting at noon" })
        #expect(recordings.isRecording)
    }

    @Test(arguments: [
        (Self.dictation, Mode?.none, String?.none),
        (Self.dictation, .clean, "Clean"),
        (Self.dictation, .custom(Self.emailReply.id), "Email reply"),
        (Self.edit, .clean, "Edit"),
    ])
    func `shows the listening HUD with the target app's mode as its badge`(
        trigger: RecordingTrigger,
        appMode: Mode?,
        badge: String?,
    ) async {
        settings.settings.customModes = [Self.emailReply]
        settings.settings.appModes.set(appMode, for: "com.example.notes")
        let recordings = model()
        recordings.begin(trigger)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: badge, isHandsFree: false) })
    }

    @Test
    func `skips the listening HUD for a recording that ends before the delay`() async {
        let recordings = model()
        recordings.begin(Self.dictation)
        recordings.discard(because: .tooShort)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.releaseTimes.isEmpty })
        #expect(hud.content == nil)
    }

    @Test
    func `shows the listening HUD hands-free for a recording locked before it appears`() async {
        let recordings = model()
        recordings.begin(Self.dictation)
        recordings.lockHandsFree()

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: nil, isHandsFree: true) })
    }

    @Test
    func `reports a key-up from the first released poll when the key-up event never arrives`() async throws {
        var polls: [(event: PushToTalk.Event, time: TimeInterval)] = []
        let recordings = model(recorder: recorder, keyboardState: FakeKeyboardState(holdsKeys: false), watchdogInterval: 0)
        recordings.onPoll = { polls.append(($0, $1)) }
        recordings.begin(Self.dictation)

        #expect(await Poll.until(timeout: .seconds(5)) { polls.contains { $0.event == .keyUp } })

        recordings.discard(because: .interrupted)

        let keyUp = try #require(polls.first { $0.event == .keyUp })

        #expect(polls.prefix(3).map(\.event) == [.tick, .tick, .tick])
        #expect(keyUp.time == polls.first?.time)
    }

    @Test
    func `keeps a hands-free recording going without the key held`() async {
        var events: [PushToTalk.Event] = []
        let recordings = model(recorder: recorder, keyboardState: FakeKeyboardState(holdsKeys: false), watchdogInterval: 0)
        recordings.onPoll = { event, _ in events.append(event) }
        recordings.begin(Self.dictation)
        recordings.lockHandsFree()

        #expect(await Poll.until(timeout: .seconds(5)) { events.count >= 8 })

        recordings.discard(because: .interrupted)

        #expect(!events.contains(.keyUp))
    }
}

extension RecordingControllerTests {
    private func model() -> RecordingController {
        model(recorder: recorder)
    }

    private func model(
        recorder: FakeAudioRecorder,
        keyboardState: FakeKeyboardState = FakeKeyboardState(holdsKeys: true),
        hudDelay: Duration = .zero,
        watchdogInterval: TimeInterval = 60,
    ) -> RecordingController {
        let recordings = RecordingController(
            recorder: recorder,
            focusTracker: focusTracker,
            keyboardState: keyboardState,
            sounds: sounds,
            otherSounds: OtherSoundsLowering(outputVolume: FakeOutputVolume(), delay: .zero),
            settings: settings,
            hud: hud,
            hudDelay: hudDelay,
            watchdogInterval: watchdogInterval,
        )

        recordings.start()

        return recordings
    }
}

private nonisolated struct FakeFocusedElement: FocusedElement {
    let selectedText: String?
    let isSecureTextField = false
    let characterBeforeCaret: Character? = nil

    func compare(with _: any FocusedElement) -> FocusComparison {
        .unknown
    }
}
