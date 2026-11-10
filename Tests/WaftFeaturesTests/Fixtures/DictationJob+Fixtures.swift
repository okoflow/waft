import WaftCore
@testable import WaftFeatures

extension DictationJob {
    static func recorded(
        selection: String? = nil,
        vocabulary: Vocabulary = .empty,
        configure: (inout Settings) -> Void = { _ in },
    ) -> DictationJob {
        var settings = Settings(languages: .preferred(by: []))
        settings.mode = .raw
        configure(&settings)

        var recording = ActiveRecording(id: .first, purpose: .dictation, key: .function)
        recording.selection = selection

        return DictationJob(
            samples: [Float](repeating: 0, count: 16000),
            recording: recording,
            target: .notes,
            settings: settings,
            vocabulary: vocabulary,
            allowsAI: true,
        )
    }
}
