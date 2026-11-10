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

        let recognition = try WhisperPieces.recognized(in: outcomes)

        #expect(recognition.results == [["Hello"], [], ["there", "friend"]])
        #expect(recognition.isIncomplete)
    }

    @Test
    func `keeps every piece when none failed`() throws {
        let outcomes: [Result<[String], any Error>] = [.success(["Hello"]), .success([])]

        let recognition = try WhisperPieces.recognized(in: outcomes)

        #expect(recognition.results == [["Hello"], []])
        #expect(!recognition.isIncomplete)
        #expect(try WhisperPieces.recognized(in: [Result<[String], any Error>]()).results.isEmpty)
    }

    @Test
    func `reports the failure of a piece when the other pieces gave no text`() throws {
        let outcomes: [Result<[String], any Error>] = [.success([]), .failure(CocoaError(.coderInvalidValue))]

        let recognition = try WhisperPieces.recognized(in: outcomes)

        #expect(try recognition.textOrFailure("Hello") == "Hello")

        #expect(throws: CocoaError(.coderInvalidValue)) {
            try recognition.textOrFailure(nil)
        }
    }

    @Test(arguments: ["Hello", nil])
    func `passes the accepted text on when no piece failed`(text: String?) throws {
        let recognition = WhisperPieces.Recognition(results: [["Hello"]])

        #expect(try recognition.textOrFailure(text) == text)
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
