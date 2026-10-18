import Foundation
import Testing
import WaftCore

struct TranscriptProcessorTests {
    private static let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Clean.")

    @Test
    func `pastes the raw transcript in raw mode`() async {
        let log = RewriteLog()
        let processed = await process("um hello there", mode: .raw, log: log)

        #expect(processed == ProcessedText(text: "um hello there", mode: .raw))
        #expect(await log.requests.isEmpty)
    }

    @Test
    func `applies the offline rules and voice commands in light mode`() async {
        let processed = await process("um, hello, new line, world", mode: .light)

        #expect(processed == ProcessedText(text: "Hello\nWorld.", mode: .light))
    }

    @Test(arguments: [Mode.raw, .light, .clean, .translate])
    func `pastes a snippet spoken on its own without rewriting`(mode: Mode) async {
        let log = RewriteLog()
        let vocabulary = Vocabulary(terms: [], snippets: [Vocabulary.Snippet(trigger: "my address", text: "1 Infinite Loop")])
        let processed = await process("My address.", mode: mode, vocabulary: vocabulary, log: log)

        #expect(processed == ProcessedText(text: "1 Infinite Loop", mode: .raw))
        #expect(await log.requests.isEmpty)
    }

    @Test
    func `corrects terms before and after the rewrite`() async {
        let log = RewriteLog()
        let vocabulary = Vocabulary(
            terms: [Vocabulary.Term(term: "Kubernetes", spoken: ["cube or netties", "kubernetis"])],
            snippets: [],
        )

        let processed = await process(
            "we use cube or netties",
            mode: .clean,
            answer: .success("We use kubernetis."),
            vocabulary: vocabulary,
            log: log,
        )

        #expect(processed == ProcessedText(text: "We use Kubernetes.", mode: .clean))
        #expect(await log.requests.first?.text == "we use Kubernetes")
    }

    @Test
    func `expands snippets inside the processed text`() async {
        let vocabulary = Vocabulary(terms: [], snippets: [Vocabulary.Snippet(trigger: "brb", text: "be right back")])
        let processed = await process("ok brb", mode: .light, vocabulary: vocabulary)

        #expect(processed.text == "Ok be right back.")
    }

    @Test(arguments: [(Mode.clean, "So the meeting is on Friday."), (.custom(UUID()), "Итак, встреча в пятницу.")])
    func `uses the cloud answer for an AI mode, in any script for a custom one`(mode: Mode, answer: String) async throws {
        let log = RewriteLog()
        let processed = await process("um so the meeting is on friday", mode: mode, answer: .success(answer), log: log)
        let request = try #require(await log.requests.first)

        #expect(processed == ProcessedText(text: answer, mode: mode))
        #expect(request.deadline == .seconds(6))
        #expect(request.localServer == nil)
        #expect(RewritePrompt.system(for: request).hasPrefix("Clean."))
    }

    @Test(arguments: [
        ("um, see you tomorrow", Mode.formal, Result<String, RewriteError>.failure(.timeout), RewriteFallback.timeout),
        ("see you tomorrow", .clean, .success(""), .unusableAnswer),
    ])
    func `falls back to light when the cloud fails or its answer is unusable`(
        text: String,
        mode: Mode,
        answer: Result<String, RewriteError>,
        fallback: RewriteFallback,
    ) async {
        let processed = await process(text, mode: mode, answer: answer)

        #expect(processed == ProcessedText(text: "See you tomorrow.", mode: .light, fallback: fallback))
    }

    @Test(arguments: [Mode.clean, .translate, .custom(UUID())])
    func `skips the AI model when nothing but hesitations was said`(mode: Mode) async {
        let log = RewriteLog()
        let processed = await process("um, uh", mode: mode, log: log)

        #expect(processed == ProcessedText(text: "", mode: .light))
        #expect(await log.requests.isEmpty)
    }

    @Test(arguments: [
        (Mode.light, ProcessedText(text: "See you tomorrow.", mode: .light)),
        (.translate, ProcessedText(text: "See you tomorrow.", mode: .light, fallback: .needsPro)),
        (.custom(UUID()), ProcessedText(text: "See you tomorrow.", mode: .light, fallback: .needsPro)),
    ])
    func `asks for Pro only in the AI modes without AI access`(mode: Mode, expected: ProcessedText) async {
        let log = RewriteLog()
        let processed = await process("see you tomorrow", mode: mode, allowsAI: false, log: log)

        #expect(processed == expected)
        #expect(await log.requests.isEmpty)
    }

    @Test(arguments: [
        (CloudModel.fastest, Duration.seconds(4), Duration.seconds(20)),
        (.balanced, .seconds(6), .seconds(30)),
        (.smartest, .seconds(10), .seconds(45)),
    ])
    func `sends the model chosen for the provider and waits longer for a slower one`(
        model: CloudModel,
        deadline: Duration,
        editDeadline: Duration,
    ) async throws {
        let log = RewriteLog()
        let setup = RewriteSetup(
            provider: .cloud(.openAI),
            instructions: "Clean.",
            cloudModels: PerProvider(claude: .fastest, openAI: model),
        )

        let processed = await process("hello", mode: .clean, setup: setup, log: log)
        _ = try await edit("Text.", following: "shorter", answer: .success("Short."), setup: setup, log: log)
        let requests = await log.requests

        #expect(processed == ProcessedText(text: "From OpenAI.", mode: .clean))
        #expect(requests.map(\.cloudModel) == [model, model])
        #expect(requests.map(\.deadline) == [deadline, editDeadline])
    }

    @Test
    func `sends the rewrite with the server to the local server and gives an edit more time`() async throws {
        let log = RewriteLog()
        let server = LocalServer(baseURL: "http://localhost:1234/v1", model: "qwen")
        let setup = RewriteSetup(provider: .localServer, instructions: "Clean.", localServer: server)
        let processed = await process("hello", mode: .formal, setup: setup, answer: .success("From Claude."), log: log)
        let edited = try await edit("Text.", following: "shorter", answer: .failure(.offline), setup: setup, log: log)
        let requests = await log.requests

        #expect(processed == ProcessedText(text: "From the local server.", mode: .formal))
        #expect(edited == "From the local server.")
        #expect(requests.map(\.localServer) == [server, server])
        #expect(requests.map(\.cloudModel) == [nil, nil])
        #expect(requests.map(\.deadline) == [.seconds(15), .seconds(45)])
    }

    @Test
    func `asks for the translation target`() async throws {
        let log = RewriteLog()
        let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Translate.", translation: Translation(target: .german))
        let processed = await process(
            "see you tomorrow",
            mode: .translate,
            setup: setup,
            answer: .success("Bis morgen."),
            log: log,
        )

        let request = try #require(await log.requests.first)

        #expect(processed == ProcessedText(text: "Bis morgen.", mode: .translate))
        #expect(RewritePrompt.userMessage(for: request).contains("Translate into: German."))
    }

    @Test(arguments: [Mode.clean, .formal, .custom(UUID())])
    func `does not translate outside translate mode`(mode: Mode) async throws {
        let log = RewriteLog()
        let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Clean.", translation: Translation(target: .german))
        _ = await process("hello", mode: mode, setup: setup, answer: .success("Hello."), log: log)
        let request = try #require(await log.requests.first)

        #expect(!RewritePrompt.userMessage(for: request).contains("Translate into"))
    }

    @Test
    func `returns the edited text`() async throws {
        let log = RewriteLog()
        let edited = try await edit(
            "A rather long sentence.",
            following: "make it shorter",
            answer: .success("<text>\nShort.\n</text>"),
            log: log,
        )

        let request = try #require(await log.requests.first)

        #expect(edited == "Short.")
        #expect(request.text == "make it shorter")
        #expect(request.deadline == .seconds(30))
        #expect(RewritePrompt.userMessage(for: request).contains("<text>\nA rather long sentence.\n</text>"))
    }

    @Test(arguments: [
        (Result<String, RewriteError>.failure(.offline), RewriteError.offline),
        (.failure(.rejectedKey), .rejectedKey),
        (.success("<text> </text>"), .unreadableResponse),
    ])
    func `passes on the rewrite error of an edit and rejects an empty one`(
        answer: Result<String, RewriteError>,
        error: RewriteError,
    ) async {
        await #expect(throws: error) {
            try await edit("Text.", following: "shorter", answer: answer)
        }
    }
}

extension TranscriptProcessorTests {
    private func process(
        _ text: String,
        mode: Mode,
        setup: RewriteSetup = Self.setup,
        answer: Result<String, RewriteError> = .success("Unused."),
        vocabulary: Vocabulary = .empty,
        allowsAI: Bool = true,
        log: RewriteLog = RewriteLog(),
    ) async -> ProcessedText {
        await TranscriptProcessor.answering(answer, log: log)
            .process(.spoken(text), mode: mode, setup: setup, vocabulary: vocabulary, allowsAI: allowsAI)
    }

    private func edit(
        _ selection: String,
        following instruction: String,
        answer: Result<String, RewriteError>,
        setup: RewriteSetup = Self.setup,
        log: RewriteLog = RewriteLog(),
    ) async throws(RewriteError) -> String {
        try await TranscriptProcessor.answering(answer, log: log).edit(selection, following: .spoken(instruction), setup: setup)
    }
}
