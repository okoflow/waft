import Foundation
import WaftCore
@preconcurrency import WhisperKit

enum WhisperDecoding {
    static let windowSampleCount = 30 * Int(SpeechAudio.sampleRate)

    private static let maximumPromptTokens = 111
    private static let decoderTokenLimit = 223
    private static let prefillTokenCount = 5
    private static let transcriptTokensPerSecond = 8
    private static let shortestChunkSeconds = 10

    static func decodingOptions(for language: Language, promptTokens: [Int]) -> DecodingOptions {
        var options = DecodingOptions()

        options.language = language.rawValue
        options.detectLanguage = false
        options.skipSpecialTokens = true
        options.promptTokens = promptTokens.isEmpty ? nil : promptTokens
        options.firstTokenLogProbThreshold = nil

        return options
    }

    static func chunkSampleCount(promptTokenCount: Int) -> Int {
        let room = decoderTokenLimit - prefillTokenCount - promptTokenCount
        let fittingSeconds = max(shortestChunkSeconds, room / transcriptTokensPerSecond)

        return min(windowSampleCount, fittingSeconds * Int(SpeechAudio.sampleRate))
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
        let text = keptText(of: results, language: language, prompt: prompt, vocabulary: vocabulary)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              !HallucinationFilter.isHallucination(text, in: language, prompt: prompt, vocabulary: vocabulary) else {
            return nil
        }

        return text.capitalizedIfUnstyled(in: language)
    }

    static func keptText(
        of results: [TranscriptionResult],
        language: Language,
        prompt: String?,
        vocabulary: [String],
    ) -> String {
        let segments = results.flatMap(\.segments)
        guard !segments.isEmpty else { return results.map(\.text).joined(separator: " ") }

        let kept = segments.filter { keepsSegment($0, in: language, prompt: prompt, vocabulary: vocabulary) }

        return kept.map(\.text).joined()
    }

    static func keepsSegment(
        _ segment: TranscriptionSegment,
        in language: Language,
        prompt: String?,
        vocabulary: [String],
    ) -> Bool {
        guard isConfident(segment) else { return false }

        return !HallucinationFilter.isHallucination(segment.text, in: language, prompt: prompt, vocabulary: vocabulary)
    }

    static func reachesTokenLimit(_ segments: [TranscriptionSegment], promptTokenCount: Int) -> Bool {
        let prefill = promptTokenCount == 0 ? 0 : promptTokenCount + 1
        let windows = Dictionary(grouping: segments, by: \.seek).values

        return windows.contains { window in
            window.map(\.tokens.count).reduce(0, +) + prefill >= decoderTokenLimit
        }
    }

    static func isConfident(_ segment: TranscriptionSegment) -> Bool {
        HallucinationFilter.keepsSegment(
            averageLogProbability: Double(segment.avgLogprob),
            compressionRatio: Double(segment.compressionRatio),
        )
    }
}
