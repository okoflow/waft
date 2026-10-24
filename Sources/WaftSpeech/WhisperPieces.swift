import Foundation
import os
import WaftCore
@preconcurrency import WhisperKit

enum WhisperPieces {
    static func split(_ samples: [Float], maximumLength: Int) async throws -> [AudioChunk] {
        let silence = EnergyVAD(energyThreshold: WhisperDecoding.silenceThreshold(of: samples))

        return try await VADAudioChunker(windowPadding: 0, vad: silence).chunkAll(
            audioArray: samples,
            maxChunkLength: maximumLength,
            decodeOptions: nil,
        )
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

        return try outcomes.map { try $0.get() }
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

            if pieceResults.map(\.text).joined().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
