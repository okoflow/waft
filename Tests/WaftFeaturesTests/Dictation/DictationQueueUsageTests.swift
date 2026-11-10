import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationQueueUsageTests {
    @Test(arguments: [(Mode.raw, UsageEvent.dictation(.raw)), (.clean, .dictation(.clean))])
    func `reports a delivered dictation under the mode that ran`(mode: Mode, event: UsageEvent) async {
        let queue = queue()
        var usage: [UsageEvent] = []
        queue.onUsage = { usage.append($0) }

        queue.submit(.recorded { $0.mode = mode })

        #expect(await Poll.until(timeout: .seconds(5)) { !usage.isEmpty })
        #expect(usage == [event])
    }

    @Test
    func `reports an edit by voice instead of a dictation`() async {
        let queue = queue()
        var usage: [UsageEvent] = []
        queue.onUsage = { usage.append($0) }

        queue.submit(.recorded(selection: "Meeting at noon"))

        #expect(await Poll.until(timeout: .seconds(5)) { !usage.isEmpty })
        #expect(usage == [.voiceEdit])
    }

    @Test
    func `reports nothing for a recording without speech`() async {
        let hud = HUDController.offscreen()
        let queue = queue(FakeTranscriber(.success(nil)), hud: hud)
        var usage: [UsageEvent] = []
        queue.onUsage = { usage.append($0) }

        queue.submit(.recorded())

        #expect(await Poll
            .until(timeout: .seconds(5)) { hud.content == .message(DictationOutcome.noSpeech.message(for: .cloud(.claude))) })
        #expect(usage.isEmpty)
    }

    private func queue(
        _ transcriber: FakeTranscriber = FakeTranscriber(.success(.spoken("Hello world"))),
        hud: HUDController = .offscreen(),
    ) -> DictationQueue {
        .transcribing(with: transcriber, hud: hud, rewriter: FakeTextRewriter(.success("Hello, world.")))
    }
}
