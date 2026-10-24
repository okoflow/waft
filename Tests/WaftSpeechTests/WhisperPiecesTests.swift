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
}
