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

        let whisper = try await WhisperKit(WhisperKitConfig(
            model: files.variant,
            downloadBase: files.baseDirectory,
            modelFolder: files.folder.path,
            tokenizerFolder: files.baseDirectory,
            verbose: false,
            logLevel: .none,
            load: true,
            download: false,
        ))

        whisper.tokenizer = try LanguageRestrictedTokenizer(restricting: whisper.tokenizer, to: languages)

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

        let options = WhisperDecoding.decodingOptions(
            for: spoken,
            samples: samples,
            prompt: prompt,
            tokenizer: loaded.whisper.tokenizer,
        )

        let results = try await loaded.whisper.transcribe(audioArray: samples, decodeOptions: options)
        guard let text = WhisperDecoding.acceptedText(of: results, language: spoken, prompt: prompt, vocabulary: vocabulary)
        else { return nil }

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
            maxChunkLength: WhisperDecoding.windowSampleCount,
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
        let prompt = WhisperDecoding.filePrompt(for: language, variant: variant)
        let offset = Double(chunk.seekOffsetIndex) / SpeechAudio.sampleRate

        let options = WhisperDecoding.decodingOptions(
            for: language,
            samples: chunk.audioSamples,
            prompt: prompt,
            tokenizer: whisper.tokenizer,
        )

        let results = try await whisper.transcribe(audioArray: chunk.audioSamples, decodeOptions: options)

        let segments = results.flatMap(\.segments).filter(WhisperDecoding.isConfident).compactMap { segment -> TimedSegment? in
            let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }

            let written = text.written(in: variant, keeping: [])

            return TimedSegment(start: offset + Double(segment.start), end: offset + Double(segment.end), text: written)
        }

        let text = segments.map(\.text).joined(separator: " ")
        guard !HallucinationFilter.isHallucination(text, in: language, prompt: prompt) else { return [] }

        return segments
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

    private func waitForTurn() async {
        guard isTranscribing else {
            isTranscribing = true

            return
        }

        await withCheckedContinuation { waiters.append($0) }
    }

    private func finishTurn() {
        guard !waiters.isEmpty else {
            isTranscribing = false

            return
        }

        waiters.removeFirst().resume()
    }
}
