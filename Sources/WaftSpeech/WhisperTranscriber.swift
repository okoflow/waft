package import Foundation
package import WaftCore
@preconcurrency internal import WhisperKit
import os

package actor WhisperTranscriber: Transcriber {
    private struct LoadedModel {
        let whisper: WhisperKit
        let languages: [Language]
    }

    private static let windowSampleCount = 30 * Int(SpeechAudio.sampleRate)
    private static let maximumPromptTokens = 200

    private var loaded: LoadedModel?
    private var isTranscribing = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    package nonisolated var modelDirectory: URL {
        SpeechModelFiles.folder
    }

    package init() {}

    private static func acceptedText(of results: [TranscriptionResult], language: Language, prompt: String?) -> String? {
        let segments = results.flatMap(\.segments)
        let kept = segments.isEmpty
            ? results.map(\.text).joined(separator: " ")
            : segments.filter(isConfident).map(\.text).joined()
        let text = kept.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty, !HallucinationFilter.isHallucination(text, in: language, prompt: prompt) else { return nil }

        return text.capitalizedIfUnstyled(in: language)
    }

    private static func isConfident(_ segment: TranscriptionSegment) -> Bool {
        HallucinationFilter.keepsSegment(
            averageLogProbability: Double(segment.avgLogprob),
            compressionRatio: Double(segment.compressionRatio),
        )
    }

    package func isModelInstalled() -> Bool {
        SpeechModelFiles.isInstalled
    }

    package func downloadModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        try FileManager.default.createDirectory(at: SpeechModelFiles.baseDirectory, withIntermediateDirectories: true)

        _ = try await WhisperKit.download(
            variant: SpeechModelFiles.model,
            downloadBase: SpeechModelFiles.baseDirectory,
            from: SpeechModelFiles.repository,
        ) { progress($0.fractionCompleted) }
        _ = try await ModelUtilities.loadTokenizer(for: .largev3, tokenizerFolder: SpeechModelFiles.baseDirectory)

        try SpeechModelFiles.markComplete()
    }

    package func loadModel(for languages: [Language]) async throws -> Duration {
        guard SpeechModelFiles.isInstalled else { throw TranscriberError.modelMissing(SpeechModelFiles.model) }

        loaded = nil

        let start = ContinuousClock.now
        let whisper = try await WhisperKit(configuration())
        whisper.tokenizer = try restrictedTokenizer(of: whisper, to: languages)
        loaded = LoadedModel(whisper: whisper, languages: languages)

        return ContinuousClock.now - start
    }

    package func deleteModel() throws {
        loaded = nil

        try SpeechModelFiles.remove()
    }

    package func transcribe(_ samples: [Float], in language: Language?, vocabulary: [String]) async throws -> Transcript? {
        guard SpeechGate.containsSpeech(samples) else { return nil }
        guard let loaded else { throw TranscriberError.notLoaded }

        await waitForTurn()
        defer { finishTurn() }

        let detectionStart = ContinuousClock.now
        let spoken = try await resolvedLanguage(language, of: samples, with: loaded)

        let decodingStart = ContinuousClock.now
        let prompt = WhisperPrompt.text(for: spoken, vocabulary: vocabulary)
        let options = decodingOptions(for: spoken, samples: samples, prompt: prompt, tokenizer: loaded.whisper.tokenizer)
        let results = try await loaded.whisper.transcribe(audioArray: samples, decodeOptions: options)

        guard let text = Self.acceptedText(of: results, language: spoken, prompt: prompt) else { return nil }

        return Transcript(
            text: text,
            language: spoken,
            detectionDuration: decodingStart - detectionStart,
            decodingDuration: ContinuousClock.now - decodingStart,
        )
    }

    package func transcribeFile(
        _ samples: [Float],
        in language: Language?,
        progress: @Sendable (Double) -> Void,
    ) async throws -> TimedTranscript? {
        guard let loaded else { throw TranscriberError.notLoaded }

        let chunks = try await VADAudioChunker().chunkAll(
            audioArray: samples,
            maxChunkLength: Self.windowSampleCount,
            decodeOptions: nil,
        )
        var spoken = language
        var segments: [TimedSegment] = []

        for (index, chunk) in chunks.enumerated() {
            try Task.checkCancellation()

            if SpeechGate.containsSpeech(chunk.audioSamples) {
                await waitForTurn()
                defer { finishTurn() }

                let chunkLanguage = try await resolvedLanguage(spoken, of: chunk.audioSamples, with: loaded)
                spoken = chunkLanguage
                segments += try await timedSegments(of: chunk, in: chunkLanguage, with: loaded.whisper)
            }

            progress(Double(index + 1) / Double(chunks.count))
        }

        guard let spoken, !segments.isEmpty else { return nil }

        return TimedTranscript(language: spoken, segments: segments)
    }

    private func timedSegments(
        of chunk: AudioChunk,
        in language: Language,
        with whisper: WhisperKit,
    ) async throws -> [TimedSegment] {
        let options = decodingOptions(for: language, samples: chunk.audioSamples, prompt: nil, tokenizer: whisper.tokenizer)
        let results = try await whisper.transcribe(audioArray: chunk.audioSamples, decodeOptions: options)
        let offset = Double(chunk.seekOffsetIndex) / SpeechAudio.sampleRate
        let segments = results.flatMap(\.segments).filter(Self.isConfident).compactMap { segment -> TimedSegment? in
            let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            return TimedSegment(start: offset + Double(segment.start), end: offset + Double(segment.end), text: text)
        }
        let text = segments.map(\.text).joined(separator: " ")

        return HallucinationFilter.isHallucination(text, in: language, prompt: nil) ? [] : segments
    }

    private func configuration() -> WhisperKitConfig {
        WhisperKitConfig(
            model: SpeechModelFiles.model,
            downloadBase: SpeechModelFiles.baseDirectory,
            modelFolder: SpeechModelFiles.folder.path,
            tokenizerFolder: SpeechModelFiles.baseDirectory,
            verbose: false,
            logLevel: .none,
            load: true,
            download: false,
        )
    }

    private func restrictedTokenizer(of whisper: WhisperKit, to languages: [Language]) throws -> any WhisperTokenizer {
        guard let tokenizer = whisper.tokenizer else { throw TranscriberError.tokenizerMissing }

        let tokens = Set(languages.compactMap { tokenizer.convertTokenToId("<|\($0.rawValue)|>") })
        guard !tokens.isEmpty, tokens.count == languages.count else { throw TranscriberError.languageTokensMissing }

        return LanguageRestrictedTokenizer(base: tokenizer, allLanguageTokens: tokens)
    }

    private func resolvedLanguage(_ language: Language?, of samples: [Float], with loaded: LoadedModel) async throws -> Language {
        if let language {
            return language
        }

        let detection = try await loaded.whisper.detectLangauge(audioArray: samples)
        guard let detected = Language(rawValue: detection.language) else {
            let fallback = loaded.languages[0]
            Logger.speech.notice(
                """
                Detected \(detection.language, privacy: .public), which Waft doesn't know; \
                using \(fallback.rawValue, privacy: .public)
                """,
            )

            return fallback
        }

        return detected
    }

    private func decodingOptions(
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
        options.chunkingStrategy = samples.count > Self.windowSampleCount ? .vad : nil

        return options
    }

    private func promptTokens(for prompt: String?, tokenizer: (any WhisperTokenizer)?) -> [Int] {
        guard let prompt, let tokenizer else { return [] }

        let firstSpecialToken = tokenizer.specialTokens.specialTokenBegin
        let tokens = tokenizer.encode(text: " " + prompt).filter { $0 < firstSpecialToken }

        return Array(tokens.suffix(Self.maximumPromptTokens))
    }

    private func waitForTurn() async {
        guard isTranscribing else {
            isTranscribing = true

            return
        }

        await withCheckedContinuation { waiters.append($0) }
    }

    private func finishTurn() {
        if waiters.isEmpty {
            isTranscribing = false
        } else {
            waiters.removeFirst().resume()
        }
    }
}
