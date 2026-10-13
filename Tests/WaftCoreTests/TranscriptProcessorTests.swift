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
        #expect(request.deadline == .seconds(3))
        #expect(request.localServer == nil)
        #expect(RewritePrompt.system(for: request).hasPrefix("Clean."))
    }

    @Test(arguments: [
        (RewriteError.rateLimited, RewriteFallback.rateLimited),
        (.timeout, .timeout),
        (.missingKey, .missingKey),
        (.offline, .offline),
        (.serviceUnavailable, .serviceError),
        (.refused, .unusableAnswer),
    ])
    func `falls back to light when the cloud fails`(error: RewriteError, fallback: RewriteFallback) async {
        let processed = await process("um, see you tomorrow", mode: .formal, answer: .failure(error))

        #expect(processed == ProcessedText(text: "See you tomorrow.", mode: .light, fallback: fallback))
    }

    @Test(arguments: ["Увидимся завтра.", "", String(repeating: "See you tomorrow. ", count: 20)])
    func `falls back to light when the answer is unusable`(answer: String) async {
        let processed = await process("see you tomorrow", mode: .clean, answer: .success(answer))

        #expect(processed == ProcessedText(text: "See you tomorrow.", mode: .light, fallback: .unusableAnswer))
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

    @Test
    func `sends the rewrite to the chosen cloud provider`() async {
        let setup = RewriteSetup(provider: .cloud(.openAI), instructions: "Clean.")
        let processed = await process("hello", mode: .clean, setup: setup, answer: .success("From Claude."))

        #expect(processed == ProcessedText(text: "From OpenAI.", mode: .clean))
    }

    @Test
    func `sends the rewrite with the server to the local server`() async throws {
        let log = RewriteLog()
        let server = LocalServer(baseURL: "http://localhost:1234/v1", model: "qwen")
        let setup = RewriteSetup(provider: .localServer, instructions: "Clean.", localServer: server)
        let processed = await process("hello", mode: .formal, setup: setup, answer: .success("From Claude."), log: log)
        let request = try #require(await log.requests.first)

        #expect(processed == ProcessedText(text: "From the local server.", mode: .formal))
        #expect(request.localServer == server)
        #expect(request.deadline == .seconds(15))
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

    @Test(arguments: [
        (Language.english, "see you tomorrow", "Увидимся завтра."),
        (.russian, "увидимся завтра", "See you tomorrow."),
    ])
    func `translates both ways between two languages`(spoken: Language, text: String, answer: String) async {
        let translation = Translation(target: .english, twoWayLanguage: .russian)
        let setup = RewriteSetup(provider: .cloud(.claude), instructions: "Translate.", translation: translation)
        let processed = await process(text, mode: .translate, language: spoken, setup: setup, answer: .success(answer))

        #expect(processed == ProcessedText(text: answer, mode: .translate))
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
        #expect(request.deadline == .seconds(20))
        #expect(RewritePrompt.userMessage(for: request).contains("<text>\nA rather long sentence.\n</text>"))
    }

    @Test(arguments: [RewriteError.offline, .rejectedKey, .truncated, .timeout])
    func `passes on the rewrite error of an edit`(error: RewriteError) async {
        await #expect(throws: error) {
            try await edit("Text.", following: "shorter", answer: .failure(error))
        }
    }

    @Test
    func `rejects an empty edit`() async {
        await #expect(throws: RewriteError.unreadableResponse) {
            try await edit("Text.", following: "delete it", answer: .success("<text> </text>"))
        }
    }

    @Test
    func `gives a local server more time for an edit`() async throws {
        let log = RewriteLog()
        let setup = RewriteSetup(provider: .localServer, instructions: "Clean.", localServer: LocalServer(model: "llama"))
        let edited = try await edit("Text.", following: "shorter", answer: .failure(.offline), setup: setup, log: log)

        #expect(edited == "From the local server.")
        #expect(await log.requests.first?.deadline == .seconds(45))
    }

    private func process(
        _ text: String,
        mode: Mode,
        language: Language = .english,
        setup: RewriteSetup = Self.setup,
        answer: Result<String, RewriteError> = .success("Unused."),
        vocabulary: Vocabulary = .empty,
        allowsAI: Bool = true,
        log: RewriteLog = RewriteLog(),
    ) async -> ProcessedText {
        let transcript = Transcript(text: text, language: language, detectionDuration: .zero, decodingDuration: .zero)

        return await processor(claude: answer, log: log)
            .process(transcript, mode: mode, setup: setup, vocabulary: vocabulary, allowsAI: allowsAI)
    }

    private func edit(
        _ selection: String,
        following instruction: String,
        answer: Result<String, RewriteError>,
        setup: RewriteSetup = Self.setup,
        log: RewriteLog = RewriteLog(),
    ) async throws(RewriteError) -> String {
        let transcript = Transcript(text: instruction, language: .english, detectionDuration: .zero, decodingDuration: .zero)

        return try await processor(claude: answer, log: log).edit(selection, following: transcript, setup: setup)
    }

    private func processor(claude: Result<String, RewriteError>, log: RewriteLog) -> TranscriptProcessor {
        TranscriptProcessor(rewriters: Rewriters(
            cloud: PerProvider(
                claude: FakeTextRewriter(answer: claude, log: log),
                openAI: FakeTextRewriter(answer: .success("From OpenAI."), log: log),
            ),
            localServer: FakeTextRewriter(answer: .success("From the local server."), log: log),
        ))
    }
}

private struct FakeTextRewriter: TextRewriter {
    let answer: Result<String, RewriteError>
    let log: RewriteLog

    func rewrite(_ request: RewriteRequest) async throws(RewriteError) -> String {
        await log.record(request)

        return try answer.get()
    }
}

private actor RewriteLog {
    private(set) var requests: [RewriteRequest] = []

    func record(_ request: RewriteRequest) {
        requests.append(request)
    }
}
