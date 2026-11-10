import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationQueueUsageTests {
    private let settings = SettingsModel.inMemory()

    @Test(arguments: [(Mode.raw, UsageEvent.dictation(.raw)), (.clean, .dictation(.clean))])
    func `reports a delivered dictation under the mode that ran`(mode: Mode, event: UsageEvent) async {
        let queue = queue()
        var usage: [UsageEvent] = []
        queue.onUsage = { usage.append($0) }

        queue.submit(job(mode: mode))

        #expect(await Poll.until(timeout: .seconds(5)) { !usage.isEmpty })
        #expect(usage == [event])
    }

    @Test
    func `reports an edit by voice instead of a dictation`() async {
        let queue = queue()
        var usage: [UsageEvent] = []
        queue.onUsage = { usage.append($0) }

        queue.submit(job(mode: .raw, selection: "Meeting at noon"))

        #expect(await Poll.until(timeout: .seconds(5)) { !usage.isEmpty })
        #expect(usage == [.voiceEdit])
    }

    @Test
    func `reports nothing for a recording without speech`() async {
        let hud = HUDController.offscreen()
        let queue = queue(FakeTranscriber(.success(nil)), hud: hud)
        var usage: [UsageEvent] = []
        queue.onUsage = { usage.append($0) }

        queue.submit(job(mode: .raw))

        #expect(await Poll
            .until(timeout: .seconds(5)) { hud.content == .message(DictationOutcome.noSpeech.message(for: .cloud(.claude))) })
        #expect(usage.isEmpty)
    }

    private func queue(
        _ transcriber: FakeTranscriber = FakeTranscriber(.success(.spoken("Hello world"))),
        hud: HUDController = .offscreen(),
    ) -> DictationQueue {
        DictationQueue(
            transcriber: transcriber,
            rewriters: .all(FakeTextRewriter(.success("Hello, world."))),
            inserter: FakeTextInserter(),
            clipboard: FakeClipboard(),
            history: HistoryModel(store: FakeValueStore<DictationHistory>(), settings: settings, clipboard: FakeClipboard()),
            statistics: StatisticsModel(store: FakeValueStore<DictationStatistics>()),
            hud: hud,
        )
    }

    private func job(mode: Mode, selection: String? = nil) -> DictationJob {
        var settings = Settings(languages: .preferred(by: []))
        settings.mode = mode

        var recording = ActiveRecording(id: RecordingID.none.next, purpose: .dictation, key: .function)
        recording.selection = selection

        return DictationJob(
            samples: [Float](repeating: 0, count: 16000),
            recording: recording,
            target: .notes,
            settings: settings,
            vocabulary: .empty,
            allowsAI: true,
        )
    }
}
