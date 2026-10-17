package import Foundation

package protocol Transcriber: Sendable {
    func modelDirectory(for model: SpeechModel) -> URL
    func isModelInstalled(_ model: SpeechModel) async -> Bool
    func downloadModel(_ model: SpeechModel, progress: @escaping @Sendable (Double) -> Void) async throws
    func loadModel(_ model: SpeechModel, for languages: [Language]) async throws -> Duration
    func deleteModel(_ model: SpeechModel) async throws
    func transcribe(
        _ samples: [Float],
        in language: Language?,
        writing variants: WritingVariants,
        vocabulary: [String],
    ) async throws -> Transcript?
    func transcribeFile(
        _ samples: [Float],
        in language: Language?,
        writing variants: WritingVariants,
        progress: @escaping @Sendable (Double) -> Void,
    ) async throws -> TimedTranscript?
}
