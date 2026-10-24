import Testing
import WaftCore
@testable import WaftSpeech
@preconcurrency import WhisperKit

struct WhisperDecodingTests {
    private static let tokenizer = FakeWhisperTokenizer(tokensByText: [" Hallo.": [1, 2, 50300, 3], " lang": Array(0 ..< 250)])

    @Test
    func `decodes in the chosen language with the prompt and without detection`() {
        let options = WhisperDecoding.decodingOptions(for: .german, promptTokens: [1, 2, 3])

        #expect(options.language == "de")
        #expect(!options.detectLanguage)
        #expect(options.skipSpecialTokens)
        #expect(options.promptTokens == [1, 2, 3])
        #expect(options.chunkingStrategy == nil)
    }

    @Test
    func `decodes a chunk that starts mid-word instead of giving up on its first token`() {
        let options = WhisperDecoding.decodingOptions(for: .russian, promptTokens: [])

        #expect(options.firstTokenLogProbThreshold == nil)
    }

    @Test(arguments: [(0, 27), (22, 24), (90, 16), (111, 13)])
    func `sizes chunks so the transcript fits after the prompt`(promptTokenCount: Int, seconds: Int) {
        #expect(WhisperDecoding.chunkSampleCount(promptTokenCount: promptTokenCount) == seconds * 16000)
    }

    @Test
    func `sends no prompt without prompt tokens`() {
        #expect(WhisperDecoding.decodingOptions(for: .german, promptTokens: []).promptTokens == nil)
    }

    @Test(arguments: [(String?("Hallo."), FakeWhisperTokenizer?.none), (nil, Self.tokenizer), ("Unknown.", Self.tokenizer)])
    func `finds no prompt tokens without a prompt, a tokenizer, or any tokens`(
        prompt: String?,
        tokenizer: FakeWhisperTokenizer?,
    ) {
        #expect(WhisperDecoding.promptTokens(for: prompt, tokenizer: tokenizer).isEmpty)
    }

    @Test(arguments: [("Hallo.", [1, 2, 3]), ("lang", Array(139 ..< 250))])
    func `keeps the last prompt tokens below the special tokens`(prompt: String, tokens: [Int]) {
        #expect(WhisperDecoding.promptTokens(for: prompt, tokenizer: Self.tokenizer) == tokens)
    }

    @Test
    func `prompts a file only for a chosen script`() {
        #expect(WhisperDecoding.filePrompt(for: .chinese, variant: nil) == nil)
        #expect(WhisperDecoding.filePrompt(for: .chinese, variant: .traditional) == "你好！這是一段示例文本，包含逗號和句號。")
    }

    @Test(arguments: [(-1.0, 2.0, true), (-1.75, 1.0, false), (-0.5, 2.5, false)])
    func `trusts a segment with enough probability and little repetition`(
        averageLogProbability: Float,
        compressionRatio: Float,
        isConfident: Bool,
    ) {
        let segment = TranscriptionSegment(avgLogprob: averageLogProbability, compressionRatio: compressionRatio)

        #expect(WhisperDecoding.isConfident(segment) == isConfident)
    }

    @Test(arguments: [(112, 111, true), (145, 22, false), (222, 0, false), (223, 0, true)])
    func `notices a window that filled the decoder before its end`(
        tokenCount: Int,
        promptTokenCount: Int,
        reachesLimit: Bool,
    ) {
        let segments = [
            TranscriptionSegment(seek: 0, tokens: Array(repeating: 1, count: tokenCount - 10)),
            TranscriptionSegment(seek: 0, tokens: Array(repeating: 1, count: 10)),
            TranscriptionSegment(seek: 480_000, tokens: Array(repeating: 1, count: 40)),
        ]

        #expect(WhisperDecoding.reachesTokenLimit(segments, promptTokenCount: promptTokenCount) == reachesLimit)
    }

    @Test
    func `keeps the text of the confident segments`() {
        let results = [
            result(" Hello", segments: [
                TranscriptionSegment(text: " Hello", avgLogprob: -0.5),
                TranscriptionSegment(text: " la la la", compressionRatio: 3),
            ]),
            result(" world", segments: [TranscriptionSegment(text: " world", avgLogprob: -0.2)]),
        ]

        #expect(WhisperDecoding.keptText(of: results, language: .english, prompt: nil, vocabulary: []) == " Hello world")
    }

    @Test
    func `drops an echo of the prompt and a stock phrase between real segments`() {
        let prompt = "Hello! This is an example sentence, with commas and periods."
        let results = [
            result(" Ship it", segments: [TranscriptionSegment(text: " Ship it today.")]),
            result(" Hello", segments: [TranscriptionSegment(text: " This is an example sentence, with commas and periods.")]),
            result(" Thanks", segments: [TranscriptionSegment(text: " Thanks for watching!")]),
            result(" Waft", segments: [TranscriptionSegment(text: " Waft.")]),
            result(" Then", segments: [TranscriptionSegment(text: " Then tell the team.")]),
        ]

        let text = WhisperDecoding.keptText(of: results, language: .english, prompt: prompt, vocabulary: ["Waft"])

        #expect(text == " Ship it today. Waft. Then tell the team.")
    }

    @Test
    func `joins the texts of results without segments`() {
        let text = WhisperDecoding.keptText(
            of: [result("Hello"), result("world")],
            language: .english,
            prompt: nil,
            vocabulary: [],
        )

        #expect(text == "Hello world")
    }

    @Test(arguments: [
        ("  hello there  ", String?.some("Hello there")),
        ("I said hi.", "I said hi."),
        ("   ", nil),
        ("Thanks for watching!", nil),
        ("[Music]", nil),
    ])
    func `accepts trimmed speech and rejects silence and hallucinations`(text: String, expected: String?) {
        #expect(WhisperDecoding.acceptedText(of: [result(text)], language: .english, prompt: nil, vocabulary: []) == expected)
    }

    private func result(_ text: String, segments: [TranscriptionSegment] = []) -> TranscriptionResult {
        TranscriptionResult(text: text, segments: segments, language: "en", timings: TranscriptionTimings())
    }
}
