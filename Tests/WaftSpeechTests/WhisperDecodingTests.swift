import Testing
import WaftCore
@testable import WaftSpeech
@preconcurrency import WhisperKit

struct WhisperDecodingTests {
    private static let tokenizer = FakeWhisperTokenizer(tokensByText: [" Hallo.": [1, 2, 50300, 3], " lang": Array(0 ..< 250)])

    @Test
    func `decodes in the chosen language with the prompt and without detection`() {
        let options = WhisperDecoding.decodingOptions(for: .german, samples: [0], prompt: "Hallo.", tokenizer: Self.tokenizer)

        #expect(options.language == "de")
        #expect(!options.detectLanguage)
        #expect(options.skipSpecialTokens)
        #expect(options.promptTokens == [1, 2, 3])
        #expect(options.chunkingStrategy == nil)
    }

    @Test(arguments: [(WhisperDecoding.windowSampleCount, false), (WhisperDecoding.windowSampleCount + 1, true)])
    func `splits audio longer than one window by voice activity`(sampleCount: Int, splits: Bool) {
        let samples = [Float](repeating: 0, count: sampleCount)
        let options = WhisperDecoding.decodingOptions(for: .english, samples: samples, prompt: nil, tokenizer: nil)

        #expect(options.chunkingStrategy == (splits ? .vad : nil))
    }

    @Test(arguments: [(String?("Hallo."), FakeWhisperTokenizer?.none), (nil, Self.tokenizer), ("Unknown.", Self.tokenizer)])
    func `sends no prompt tokens without a prompt, a tokenizer, or any tokens`(
        prompt: String?,
        tokenizer: FakeWhisperTokenizer?,
    ) {
        let options = WhisperDecoding.decodingOptions(for: .german, samples: [0], prompt: prompt, tokenizer: tokenizer)

        #expect(options.promptTokens == nil)
    }

    @Test
    func `keeps the last prompt tokens below the special tokens`() {
        #expect(WhisperDecoding.promptTokens(for: "lang", tokenizer: Self.tokenizer) == Array(50 ..< 250))
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

    @Test
    func `keeps the text of the confident segments`() {
        let results = [
            result(" Hello", segments: [
                TranscriptionSegment(text: " Hello", avgLogprob: -0.5),
                TranscriptionSegment(text: " la la la", compressionRatio: 3),
            ]),
            result(" world", segments: [TranscriptionSegment(text: " world", avgLogprob: -0.2)]),
        ]

        #expect(WhisperDecoding.keptText(of: results) == " Hello world")
    }

    @Test
    func `joins the texts of results without segments`() {
        #expect(WhisperDecoding.keptText(of: [result("Hello"), result("world")]) == "Hello world")
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
