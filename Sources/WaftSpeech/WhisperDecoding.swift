import Foundation
import WaftCore
@preconcurrency import WhisperKit

enum WhisperDecoding {
    static let windowSampleCount = 30 * Int(SpeechAudio.sampleRate)

    private static let maximumPromptTokens = 200

    static func decodingOptions(
        for language: Language,
        samples: [Float],
        prompt: String?,
        tokenizer: (any WhisperTokenizer)?,
    ) -> DecodingOptions {
        let tokens = promptTokens(for: prompt, tokenizer: tokenizer)

        var options = DecodingOptions()

        options.language = language.rawValue
        options.detectLanguage = false
        options.skipSpecialTokens = true
        options.promptTokens = tokens.isEmpty ? nil : tokens
        options.chunkingStrategy = samples.count > windowSampleCount ? .vad : nil

        return options
    }

    static func promptTokens(for prompt: String?, tokenizer: (any WhisperTokenizer)?) -> [Int] {
        guard let prompt, let tokenizer else { return [] }

        let firstSpecialToken = tokenizer.specialTokens.specialTokenBegin

        let tokens = tokenizer.encode(text: " " + prompt).filter { $0 < firstSpecialToken }

        return Array(tokens.suffix(maximumPromptTokens))
    }

    static func filePrompt(for language: Language, variant: WritingVariant?) -> String? {
        guard let variant else { return nil }

        return WhisperPrompt.text(for: language, variant: variant, vocabulary: [])
    }

    static func acceptedText(
        of results: [TranscriptionResult],
        language: Language,
        prompt: String?,
        vocabulary: [String],
    ) -> String? {
        let text = keptText(of: results).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              !HallucinationFilter.isHallucination(text, in: language, prompt: prompt, vocabulary: vocabulary) else {
            return nil
        }

        return text.capitalizedIfUnstyled(in: language)
    }

    static func keptText(of results: [TranscriptionResult]) -> String {
        let segments = results.flatMap(\.segments)
        guard !segments.isEmpty else { return results.map(\.text).joined(separator: " ") }

        return segments.filter(isConfident).map(\.text).joined()
    }

    static func isConfident(_ segment: TranscriptionSegment) -> Bool {
        HallucinationFilter.keepsSegment(
            averageLogProbability: Double(segment.avgLogprob),
            compressionRatio: Double(segment.compressionRatio),
        )
    }
}
