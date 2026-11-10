import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct RecordingFailureTests {
    private static let first = RecordingID.none.next
    private nonisolated static let dictation = RecordingTrigger(purpose: .dictation, key: .function, action: .startRecording)
    private nonisolated static let edit = RecordingTrigger(purpose: .edit, key: .function, action: .startRecording)

    private let recorder = FakeAudioRecorder()

    private let focusTracker = FakeFocusTracker(.app(
        "com.example.notes",
        element: FakeFocusedElement(selectedText: "Meeting at noon"),
    ))

    private let hud = HUDController.offscreen()

    @Test
    func `shows the failure and stops the recorder when the recording fails before any audio`() async {
        var deliveryCount = 0
        let recorder = FakeAudioRecorder(samples: [])
        let recordings = model(recorder: recorder)
        recordings.onFinish = { _, _, _ in deliveryCount += 1 }

        recordings.begin(Self.dictation)
        recorder.send(.failed(Self.first, .deviceUnavailable))

        #expect(await Poll.until(timeout: .seconds(5)) {
            hud.content == .message(.recordingFailed(RecordingFailure.deviceUnavailable.message))
        })
        #expect(recorder.releaseTimes == [nil])
        #expect(!recordings.isRecording)
        #expect(deliveryCount == 0)
    }

    @Test
    func `delivers the audio captured before a dictation's recording failed`() async {
        var delivery: (app: String?, samples: [Float])?
        let recordings = model()
        recordings.onFinish = { _, target, samples in delivery = (target.bundleIdentifier, samples) }

        recordings.begin(Self.dictation)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: "Light", isHandsFree: false) })

        recorder.send(.failed(Self.first, .stoppedAfterDeviceChange))

        #expect(await Poll.until(timeout: .seconds(5)) { delivery != nil })
        #expect(delivery?.app == "com.example.notes")
        #expect(delivery?.samples == [0.1, 0.2])
        #expect(hud.content == .message(.recordingCutShort(RecordingFailure.stoppedAfterDeviceChange.message)))
        #expect(!recordings.isRecording)
    }

    @Test
    func `drops the audio of an edit whose recording failed`() async {
        var deliveryCount = 0
        let recordings = model()
        recordings.onFinish = { _, _, _ in deliveryCount += 1 }

        recordings.begin(Self.edit)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .listening(badge: "Edit", isHandsFree: false) })

        recorder.send(.failed(Self.first, .formatChanged))

        #expect(await Poll.until(timeout: .seconds(5)) {
            hud.content == .message(.recordingFailed(RecordingFailure.formatChanged.message))
        })
        #expect(deliveryCount == 0)
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

    private func model() -> RecordingController {
        model(recorder: recorder)
    }

    private func model(recorder: FakeAudioRecorder) -> RecordingController {
        let recordings = RecordingController(
            recorder: recorder,
            focusTracker: focusTracker,
            keyboardState: FakeKeyboardState(holdsKeys: true),
            sounds: FakeFeedbackSoundPlayer(),
            otherSounds: OtherSoundsLowering(outputVolume: FakeOutputVolume(), delay: .zero),
            settings: .inMemory(),
            hud: hud,
            hudDelay: .zero,
            watchdogInterval: 60,
        )

        recordings.start()

        return recordings
    }
}
