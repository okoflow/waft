import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationRetryTests {
    private let clipboard = FakeClipboard()
    private let inserter = FakeTextInserter()
    private let hud = HUDController.offscreen()

    @Test
    func `offers no retry after a dictation that was recognized`() async {
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))))

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })
        #expect(!queue.canRetry)
    }

    @Test
    func `keeps the audio of a failed transcription and copies its text on a retry`() async {
        let transcriber = FakeTranscriber(.failure(CocoaError(.fileReadCorruptFile)), .success(.spoken("Hello world")))
        let queue = queue(transcriber)

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })

        queue.retryFailedDictation()

        #expect(!queue.canRetry)
        #expect(await Poll.until(timeout: .seconds(5)) { clipboard.copied == ["Hello world"] })
        #expect(transcriber.requests.count == 2)
        #expect(inserter.insertions.isEmpty)
    }

    @Test
    func `offers the retry again when the retry fails too`() async {
        let error = CocoaError(.fileReadCorruptFile)
        let transcriber = FakeTranscriber(.failure(error), .failure(error))
        let queue = queue(transcriber)

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })

        queue.retryFailedDictation()

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.requests.count == 2 })
        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })
    }

    private func queue(_ transcriber: FakeTranscriber) -> DictationQueue {
        .transcribing(with: transcriber, hud: hud, inserter: inserter, clipboard: clipboard)
    }
}
