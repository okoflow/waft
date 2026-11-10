import Foundation
import Testing
@testable import WaftSpeech

struct WhisperPiecesTests {
    @Test
    func `finds pauses above a steady noise floor`() {
        let noise = [Float](repeating: 0.03, count: 16000)
        let speech = [Float](repeating: 0.2, count: 16000)

        let threshold = WhisperPieces.silenceThreshold(of: noise + speech + noise + speech)

        #expect(threshold > 0.03)
        #expect(threshold < 0.2)
    }

    @Test
    func `keeps a floor under the silence threshold of quiet pauses`() {
        let silence = [Float](repeating: 0, count: 16000)
        let speech = [Float](repeating: 0.2, count: 16000)

        #expect(WhisperPieces.silenceThreshold(of: silence + speech) == 0.001)
        #expect(WhisperPieces.silenceThreshold(of: []) == 0.001)
    }

    @Test
    func `keeps the pieces it recognized next to an empty place for each one that failed`() throws {
        let outcomes: [Result<[String], any Error>] = [
            .success(["Hello"]),
            .failure(CocoaError(.coderInvalidValue)),
            .success(["there", "friend"]),
        ]

        #expect(try WhisperPieces.recognized(in: outcomes) == [["Hello"], [], ["there", "friend"]])
    }

    @Test
    func `keeps every piece when none failed`() throws {
        let outcomes: [Result<[String], any Error>] = [.success(["Hello"]), .success([])]

        #expect(try WhisperPieces.recognized(in: outcomes) == [["Hello"], []])
        #expect(try WhisperPieces.recognized(in: [Result<[String], any Error>]()).isEmpty)
    }

    @Test
    func `reports the first failure when no piece was recognized`() {
        let outcomes: [Result<[String], any Error>] = [
            .failure(CocoaError(.coderInvalidValue)),
            .failure(CocoaError(.coderValueNotFound)),
        ]

        #expect(throws: CocoaError(.coderInvalidValue)) {
            try WhisperPieces.recognized(in: outcomes)
        }
    }
}
