import Foundation
import os
import WaftCore
@preconcurrency import WhisperKit

enum WhisperPieces {
    private static let silenceFrameDuration = 0.1
    private static let silenceMargin: Float = 2
    private static let quietestSilenceThreshold: Float = 0.001

    static func split(_ samples: [Float], maximumLength: Int) async throws -> [AudioChunk] {
        let silence = EnergyVAD(energyThreshold: silenceThreshold(of: samples))

        return try await VADAudioChunker(windowPadding: 0, vad: silence).chunkAll(
            audioArray: samples,
            maxChunkLength: maximumLength,
            decodeOptions: nil,
        )
    }

    static func silenceThreshold(of samples: [Float]) -> Float {
        let frameLength = Int(SpeechAudio.sampleRate * silenceFrameDuration)

        let levels = stride(from: 0, to: samples.count, by: frameLength).map { start in
            AudioLevel.rootMeanSquare(samples[start ..< min(start + frameLength, samples.count)])
        }.sorted()

        guard !levels.isEmpty else { return quietestSilenceThreshold }

        return max(quietestSilenceThreshold, levels[levels.count / 10] * silenceMargin)
    }

    static func transcribe(
        _ pieces: [[Float]],
        with options: DecodingOptions,
        on whisper: WhisperKit,
    ) async throws -> [[TranscriptionResult]] {
        let outcomes = await whisper.transcribeWithOptions(
            audioArrays: pieces,
            decodeOptionsArray: Array(repeating: options, count: pieces.count),
        )

        return try recognized(in: outcomes)
    }

    static func recognized<Value>(in outcomes: [Result<[Value], any Error>]) throws -> [[Value]] {
        let failures = outcomes.compactMap { outcome -> (any Error)? in
            guard case let .failure(error) = outcome else { return nil }

            return error
        }

        guard let firstFailure = failures.first else { return try outcomes.map { try $0.get() } }
        guard failures.count < outcomes.count else { throw firstFailure }

        Logger.speech.error(
            """
            Couldn't recognize \(failures.count) of \(outcomes.count) pieces and kept the rest: \
            \(firstFailure.logDescription, privacy: .public)
            """,
        )

        return outcomes.map { outcome in
            guard case let .success(results) = outcome else { return [] }

            return results
        }
    }

    static func log(
        _ pieces: [[Float]],
        results: [[TranscriptionResult]],
        promptTokenCount: Int,
        keeping keepsSegment: (TranscriptionSegment) -> Bool,
    ) {
        for (index, (piece, pieceResults)) in zip(pieces, results).enumerated() {
            let number = index + 1
            let seconds = SpeechAudio.duration(of: piece)
            let segments = pieceResults.flatMap(\.segments)
            let droppedCount = segments.count { !keepsSegment($0) }

            if pieceResults.map(\.text).joined().isBlank {
                Logger.speech
                    .notice("Piece \(number) of \(pieces.count), \(seconds, format: .fixed(precision: 1)) s, gave no text")
            }

            if WhisperDecoding.reachesTokenLimit(segments, promptTokenCount: promptTokenCount) {
                Logger.speech.notice(
                    """
                    Piece \(number) of \(pieces.count), \(seconds, format: .fixed(precision: 1)) s, \
                    ran out of decoder tokens before its end
                    """,
                )
            }

            if droppedCount > 0 {
                Logger.speech.notice(
                    """
                    Piece \(number) of \(pieces.count), \(seconds, format: .fixed(precision: 1)) s, \
                    dropped \(droppedCount) of \(segments.count) segments as unsure or made up
                    """,
                )
            }
        }
    }
}
