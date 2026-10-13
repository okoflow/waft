import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct DictationQueueTests {
    private static let hello = ProcessedText(text: "Hello world", mode: .raw)

    private let clipboard = FakeClipboard()
    private let history = HistoryModel(
        store: FakeValueStore<DictationHistory>(),
        settings: .inMemory(),
        clipboard: FakeClipboard(),
    )
    private let stats = StatsModel(store: FakeValueStore<DictationStats>())
    private let hud = HUDController.offscreen()

    @Test
    func `pastes the processed text into the target and records it in history and stats`() async {
        let inserter = FakeTextInserter()
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))), inserter: inserter)
        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })
        #expect(inserter.insertions.map(\.text) == ["Hello world"])
        #expect(inserter.insertions.map(\.app) == ["com.example.notes"])
        #expect(history.history.entries.map(\.text) == ["Hello world"])
        #expect(stats.stats.allTime.words == 2)
        #expect(stats.stats.allTime.seconds == 1)
        #expect(hud.content == shown(.pasted(Self.hello)))
    }

    @Test
    func `copies the text instead of pasting when pasting into the focused field is off`() async {
        let inserter = FakeTextInserter()
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))), inserter: inserter)
        queue.submit(job { $0.pastesIntoFocusedField = false })

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == shown(.copied(Self.hello)) })
        #expect(clipboard.copied == ["Hello world"])
        #expect(inserter.insertions.isEmpty)
        #expect(history.history.entries.map(\.text) == ["Hello world"])
    }

    @Test(arguments: [InsertionSkipReason.noAccessibility, .focusChanged, .keyHeld, .notRead])
    func `copies the text when the inserter skips the paste`(reason: InsertionSkipReason) async {
        let inserter = FakeTextInserter(.skipped(reason))
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))), inserter: inserter)
        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == shown(.copied(Self.hello)) })
        #expect(clipboard.copied == ["Hello world"])
        #expect(history.history.entries.map(\.text) == ["Hello world"])
    }

    @Test
    func `keeps a password field's text out of the clipboard and history but offers it as the latest transcript`() async {
        let inserter = FakeTextInserter(.skipped(.secureField))
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))), inserter: inserter)
        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == shown(.blockedInPasswordField) })
        #expect(clipboard.copied.isEmpty)
        #expect(history.history.entries.isEmpty)
        #expect(stats.stats.allTime.dictations == 0)
        #expect(queue.latestTranscript == "Hello world")
    }

    @Test(arguments: [nil, Transcript.spoken("")])
    func `reports no speech when the transcript is missing or empty`(transcript: Transcript?) async {
        let inserter = FakeTextInserter()
        let queue = queue(FakeTranscriber(.success(transcript)), inserter: inserter)
        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == shown(.noSpeech) })
        #expect(inserter.insertions.isEmpty)
        #expect(history.history.entries.isEmpty)
    }

    @Test
    func `reports a failed transcription with the error's description`() async {
        let error = CocoaError(.fileReadCorruptFile)
        let queue = queue(FakeTranscriber(.failure(error)))
        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == shown(.failed(error.localizedDescription)) })
    }

    @Test
    func `transcribes in the job's forced language with the dictionary's prompt terms`() async {
        let transcriber = FakeTranscriber(.success(.spoken("Hallo Welt", in: .german)))
        let vocabulary = Vocabulary(terms: [Vocabulary.Term(term: "Okoflow", spoken: ["oko flow"])], snippets: [])
        let queue = queue(transcriber)
        queue.submit(job(vocabulary: vocabulary) { $0.languages = .preferred(by: ["de"]).pinning(.german) })

        #expect(await Poll.until(timeout: .seconds(5)) { !transcriber.requests.isEmpty })
        #expect(transcriber.requests == [FakeTranscriber.Request(language: .german, vocabulary: ["Okoflow"])])
    }

    @Test
    func `edits the selection with the spoken instruction and pastes the result without recording it`() async {
        let inserter = FakeTextInserter()
        let rewriter = FakeTextRewriter(.success("Meeting at three"))
        let queue = queue(FakeTranscriber(.success(.spoken("Make it three"))), inserter: inserter, rewriter: rewriter)
        queue.submit(job(selection: "Meeting at noon"))

        #expect(await Poll.until(timeout: .seconds(5)) { !inserter.insertions.isEmpty })
        #expect(rewriter.requests.map(\.text) == ["Make it three"])
        #expect(inserter.insertions.map(\.text) == ["Meeting at three"])
        #expect(history.history.entries.isEmpty)
        #expect(stats.stats.allTime.dictations == 0)
    }

    @Test
    func `reports a failed edit with the rewrite error's reason in sentence case`() async {
        let rewriter = FakeTextRewriter(.failure(.offline))
        let queue = queue(FakeTranscriber(.success(.spoken("Make it three"))), rewriter: rewriter)
        queue.submit(job(selection: "Meeting at noon"))

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == shown(.editFailed("You're offline")) })
    }

    @Test(arguments: [
        (Mode.clean, ModelProvider.cloud(.claude), String?.none, "Cleaning up with Claude…"),
        (.clean, .localServer, nil, "Cleaning up on this Mac…"),
        (.translate, .cloud(.claude), nil, "Translating into English…"),
        (.clean, .cloud(.openAI), "Meeting at noon", "Editing with OpenAI…"),
        (.clean, .localServer, "Meeting at noon", "Editing on this Mac…"),
    ])
    func `shows the working label for the job's mode and provider while it rewrites`(
        mode: Mode,
        provider: ModelProvider,
        selection: String?,
        label: String,
    ) async {
        let rewriter = FakeTextRewriter(.success("Hello world."), holdsRequests: true)
        let job = job(selection: selection) { settings in
            settings.mode = mode
            settings.modelProvider = provider
        }
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))), rewriter: rewriter)
        queue.submit(job)

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .working(label) })

        rewriter.release()
    }

    @Test
    func `runs queued jobs one at a time and shows the transcribing label until the last one finishes`() async {
        let transcriber = FakeTranscriber(.success(.spoken("One")), .success(.spoken("Two")), holdsRequests: true)
        let inserter = FakeTextInserter()
        let hud = HUDController.offscreen { _ in .zero }
        let queue = DictationQueue(
            transcriber: transcriber,
            rewriters: .all(FakeTextRewriter()),
            inserter: inserter,
            clipboard: clipboard,
            history: history,
            stats: stats,
            hud: hud,
        )
        queue.submit(job())
        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { !transcriber.requests.isEmpty })
        #expect(transcriber.requests.count == 1)

        transcriber.release()

        #expect(await Poll.until(timeout: .seconds(5)) { inserter.insertions.count == 1 })
        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == .working(DictationQueue.transcribingLabel) })

        transcriber.release()

        #expect(await Poll.until(timeout: .seconds(5)) { hud.content == nil })
        #expect(inserter.insertions.map(\.text) == ["One", "Two"])
    }

    @Test
    func `copies the latest transcript on request and nothing before the first one`() async {
        let queue = queue(FakeTranscriber(.success(.spoken("Hello world"))))
        queue.copyLatestTranscript()

        #expect(clipboard.copied.isEmpty)

        queue.submit(job())

        #expect(await Poll.until(timeout: .seconds(5)) { queue.latestTranscript == "Hello world" })

        queue.copyLatestTranscript()

        #expect(clipboard.copied == ["Hello world"])
    }

    private func queue(
        _ transcriber: FakeTranscriber,
        inserter: FakeTextInserter = FakeTextInserter(),
        rewriter: FakeTextRewriter = FakeTextRewriter(),
    ) -> DictationQueue {
        DictationQueue(
            transcriber: transcriber,
            rewriters: .all(rewriter),
            inserter: inserter,
            clipboard: clipboard,
            history: history,
            stats: stats,
            hud: hud,
        )
    }

    private func job(
        selection: String? = nil,
        vocabulary: Vocabulary = .empty,
        configure: (inout Settings) -> Void = { _ in },
    ) -> DictationJob {
        var settings = Settings(languages: .preferred(by: []))
        settings.mode = .raw
        configure(&settings)

        var recording = ActiveRecording(id: RecordingID.none.next, purpose: .dictation, key: .function)
        recording.selection = selection

        return DictationJob(
            samples: [Float](repeating: 0, count: 16000),
            recording: recording,
            target: .notes,
            settings: settings,
            vocabulary: vocabulary,
            allowsAI: true,
        )
    }

    private func shown(_ outcome: DictationOutcome) -> HUDContent {
        .message(outcome.message(for: .cloud(.claude)))
    }
}
