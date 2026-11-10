import WaftCore

extension Transcript {
    nonisolated static func spoken(_ text: String) -> Transcript {
        Transcript(text: text, language: .english, detectionDuration: .zero, decodingDuration: .zero)
    }
}
