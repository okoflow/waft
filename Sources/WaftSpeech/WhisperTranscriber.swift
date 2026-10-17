package import Foundation
package import WaftCore
import os
@preconcurrency import WhisperKit

package actor WhisperTranscriber: Transcriber {
    private struct LoadedModel {
        let model: SpeechModel
        let whisper: WhisperKit
        let languages: [Language]
    }

    private static let windowSampleCount = 30 * Int(SpeechAudio.sampleRate)
    private static let maximumPromptTokens = 200

    private var loaded: LoadedModel?
    private var isTranscribing = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    package init() {}

    package nonisolated func modelDirectory(for model: SpeechModel) -> URL {
        SpeechModelFiles(model).folder
    }

    package func isModelInstalled(_ model: SpeechModel) -> Bool {
        SpeechModelFiles(model).isInstalled
    }

    package func downloadModel(_ model: SpeechModel, progress: @escaping @Sendable (Double) -> Void) async throws {
        let files = SpeechModelFiles(model)
        try FileManager.default.createDirectory(at: files.baseDirectory, withIntermediateDirectories: true)

        _ = try await WhisperKit.download(
            variant: files.variant,
            downloadBase: files.baseDirectory,
            from: SpeechModelFiles.repository,
        ) { progress($0.fractionCompleted) }
        _ = try await ModelUtilities.loadTokenizer(for: .largev3, tokenizerFolder: files.baseDirectory)

        try files.markComplete()
    }

    package func loadModel(_ model: SpeechModel, for languages: [Language]) async throws -> Duration {
        let files = SpeechModelFiles(model)
        guard files.isInstalled else { throw TranscriberError.modelMissing(model) }

        let start = ContinuousClock.now
        let whisper = try await WhisperKit(configuration(for: files))
        whisper.tokenizer = try restrictedTokenizer(of: whisper, to: languages)
        loaded = LoadedModel(model: model, whisper: whisper, languages: languages)

        return ContinuousClock.now - start
    }

    package func deleteModel(_ model: SpeechModel) throws {
        if loaded?.model == model {
            loaded = nil
        }

        try SpeechModelFiles(model).remove()
    }

    package func transcribe(
        _ samples: [Float],
        in language: Language?,
        writing variants: WritingVariants,
        vocabulary: [String],
    ) async throws -> Transcript? {
        guard SpeechGate.containsSpeech(samples) else { return nil }
        guard let loaded else { throw TranscriberError.notLoaded }

        await waitForTurn()
        defer { finishTurn() }

        let detectionStart = ContinuousClock.now
        let spoken = try await resolvedLanguage(language, of: samples, with: loaded)
        let variant = variants.variant(for: spoken)

        let decodingStart = ContinuousClock.now
        let prompt = WhisperPrompt.text(for: spoken, variant: variant, vocabulary: vocabulary)
        let options = decodingOptions(for: spoken, samples: samples, prompt: prompt, tokenizer: loaded.whisper.tokenizer)
        let results = try await loaded.whisper.transcribe(audioArray: samples, decodeOptions: options)
        guard let text = Self.acceptedText(of: results, language: spoken, prompt: prompt) else { return nil }

        return Transcript(
            text: text.written(in: variant, keeping: vocabulary),
            language: spoken,
            detectionDuration: decodingStart - detectionStart,
            decodingDuration: ContinuousClock.now - decodingStart,
            variant: variant,
        )
    }

    package func transcribeFile(
        _ samples: [Float],
        in language: Language?,
        writing variants: WritingVariants,
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
                segments += try await timedSegments(
                    of: chunk,
                    in: chunkLanguage,
                    variant: variants.variant(for: chunkLanguage),
                    with: loaded.whisper,
                )
            }

            progress(Double(index + 1) / Double(chunks.count))
        }

        guard let spoken, !segments.isEmpty else { return nil }

        return TimedTranscript(language: spoken, segments: segments)
    }

    private func timedSegments(
        of chunk: AudioChunk,
        in language: Language,
        variant: WritingVariant?,
        with whisper: WhisperKit,
    ) async throws -> [TimedSegment] {
        let prompt = variant == nil ? nil : WhisperPrompt.text(for: language, variant: variant, vocabulary: [])
        let options = decodingOptions(for: language, samples: chunk.audioSamples, prompt: prompt, tokenizer: whisper.tokenizer)
        let results = try await whisper.transcribe(audioArray: chunk.audioSamples, decodeOptions: options)
        let offset = Double(chunk.seekOffsetIndex) / SpeechAudio.sampleRate
        let segments = results.flatMap(\.segments).filter(Self.isConfident).compactMap { segment -> TimedSegment? in
            let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            let written = text.written(in: variant, keeping: [])

            return TimedSegment(start: offset + Double(segment.start), end: offset + Double(segment.end), text: written)
        }
        let text = segments.map(\.text).joined(separator: " ")

        return HallucinationFilter.isHallucination(text, in: language, prompt: prompt) ? [] : segments
    }

    private func configuration(for files: SpeechModelFiles) -> WhisperKitConfig {
        WhisperKitConfig(
            model: files.variant,
            downloadBase: files.baseDirectory,
            modelFolder: files.folder.path,
            tokenizerFolder: files.baseDirectory,
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

extension WhisperTranscriber {
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
}
