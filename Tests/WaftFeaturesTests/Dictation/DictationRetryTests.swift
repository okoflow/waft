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

    @Test
    func `pastes the recognized part of a dictation, says that a part is missing, and copies all of it on a retry`() async {
        let transcriber = FakeTranscriber(.success(.spoken("Hello", isIncomplete: true)), .success(.spoken("Hello world")))
        let queue = queue(transcriber)

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })
        #expect(inserter.insertions.map(\.text) == ["Hello"])
        #expect(queue.latestTranscript == "Hello")
        #expect(hud.content == .message(.missingPart))

        queue.retryFailedDictation()

        #expect(!queue.canRetry)
        #expect(await Poll.until(timeout: .seconds(5)) { clipboard.copied == ["Hello world"] })
        #expect(inserter.insertions.count == 1)
    }

    @Test
    func `shows the pasted text after the notice of a missing part`() async {
        let hud = HUDController.offscreen { $0 == .missingPart ? .zero : .seconds(60) }
        let queue = DictationQueue.transcribing(with: FakeTranscriber(.success(.spoken("Hello", isIncomplete: true))), hud: hud)

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(HUDMessage(kind: .pasted, title: "Hello")) })
    }

    @Test
    func `offers the retry again when a part of the retry is missing too`() async {
        let part = Transcript.spoken("Hello", isIncomplete: true)
        let transcriber = FakeTranscriber(.success(part), .success(part))
        let queue = queue(transcriber)

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })

        queue.retryFailedDictation()

        #expect(await Poll.until(timeout: .seconds(5)) { clipboard.copied == ["Hello"] })
        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })
        #expect(inserter.insertions.count == 1)
    }

    @Test
    func `reports a missing part instead of no speech when the recognized part holds no text`() async {
        let queue = queue(FakeTranscriber(.success(.spoken("", isIncomplete: true))))

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .message(.missingPart) })
        #expect(queue.canRetry)
        #expect(inserter.insertions.isEmpty)
        #expect(queue.latestTranscript == nil)
    }

    private func queue(_ transcriber: FakeTranscriber) -> DictationQueue {
        .transcribing(with: transcriber, hud: hud, inserter: inserter, clipboard: clipboard)
    }
}
