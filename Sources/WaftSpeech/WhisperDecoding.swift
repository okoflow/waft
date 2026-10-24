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
    private static let silenceFrameDuration = 0.1
    private static let silenceMargin: Float = 2
    private static let quietestSilenceThreshold: Float = 0.001

    static func decodingOptions(
        for language: Language,
        prompt: String?,
        tokenizer: (any WhisperTokenizer)?,
    ) -> DecodingOptions {
        let tokens = promptTokens(for: prompt, tokenizer: tokenizer)

        var options = DecodingOptions()

        options.language = language.rawValue
        options.detectLanguage = false
        options.skipSpecialTokens = true
        options.promptTokens = tokens.isEmpty ? nil : tokens
        options.firstTokenLogProbThreshold = nil

        return options
    }

    static func chunkSampleCount(promptTokenCount: Int) -> Int {
        let room = decoderTokenLimit - prefillTokenCount - promptTokenCount
        let fittingSeconds = max(shortestChunkSeconds, room / transcriptTokensPerSecond)

        return min(windowSampleCount, fittingSeconds * Int(SpeechAudio.sampleRate))
    }

    static func silenceThreshold(of samples: [Float]) -> Float {
        let frameLength = Int(SpeechAudio.sampleRate * silenceFrameDuration)

        let levels = stride(from: 0, to: samples.count, by: frameLength).map { start in
            AudioLevel.rootMeanSquare(samples[start ..< min(start + frameLength, samples.count)])
        }.sorted()
        guard !levels.isEmpty else { return quietestSilenceThreshold }

        return max(quietestSilenceThreshold, levels[levels.count / 10] * silenceMargin)
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
