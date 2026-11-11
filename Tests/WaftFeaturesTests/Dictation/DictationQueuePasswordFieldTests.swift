import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationQueuePasswordFieldTests {
    private static let passwordField = FocusTarget.app(
        "com.example.passwords",
        element: FakeFocusedElement(selectedText: nil, secureFieldState: .secure),
    )

    private let clipboard = FakeClipboard()
    private let history = HistoryModel.inMemory()
    private let statistics = StatisticsModel(store: FakeValueStore<DictationStatistics>())

    @Test(arguments: [(false, InsertionOutcome.pasted), (true, .pasted), (true, .skipped(.focusChanged))])
    func `keeps a dictation started in a password field out of history and statistics however its text is delivered`(
        pastes: Bool,
        insertion: InsertionOutcome,
    ) async {
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))), inserter: FakeTextInserter(insertion))

        queue.submit(.recorded(target: Self.passwordField) { $0.pastesIntoFocusedField = pastes })
        await queue.waitUntilIdle()

        #expect(queue.latestTranscript == "Hello world")
        #expect(history.history.entries.isEmpty)
        #expect(statistics.statistics.allTime.dictations == 0)
    }

    @Test
    func `keeps a failed dictation started in a password field out of history and statistics on a retry`() async {
        let transcriber = FakeTranscriber(.failure(CocoaError(.fileReadCorruptFile)), .success(.spoken("Hello world")))
        let queue = queue(transcriber)

        queue.submit(.recorded(target: Self.passwordField))

        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })

        queue.retryFailedDictation()
        await queue.waitUntilIdle()

        #expect(clipboard.copied == ["Hello world"])
        #expect(history.history.entries.isEmpty)
        #expect(statistics.statistics.allTime.dictations == 0)
    }

    @Test
    func `keeps a dictation out of history and statistics on a retry after its text stayed out of a password field`() async {
        let transcriber = FakeTranscriber(.success(.spoken("Hello", isIncomplete: true)), .success(.spoken("Hello world")))
        let queue = queue(transcriber, inserter: FakeTextInserter(.skipped(.secureField)))

        queue.submit(.recorded())

        #expect(await Poll.until(timeout: .seconds(5)) { queue.canRetry })

        queue.retryFailedDictation()
        await queue.waitUntilIdle()

        #expect(clipboard.copied == ["Hello", "Hello world"])
        #expect(history.history.entries.isEmpty)
        #expect(statistics.statistics.allTime.dictations == 0)
    }

    private func queue(_ transcriber: FakeTranscriber, inserter: FakeTextInserter = FakeTextInserter()) -> DictationQueue {
        .transcribing(
            with: transcriber,
            hud: .offscreen(),
            inserter: inserter,
            clipboard: clipboard,
            history: history,
            statistics: statistics,
        )
    }
}
