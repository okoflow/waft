import WaftCore

extension Transcript {
    nonisolated static func spoken(_ text: String, in language: Language = .english) -> Transcript {
        Transcript(text: text, language: language, detectionDuration: .zero, decodingDuration: .zero)
    }
}
