import WaftCore

extension Transcript {
    static func spoken(_ text: String, in language: Language = .english, variant: WritingVariant? = nil) -> Transcript {
        Transcript(text: text, language: language, detectionDuration: .zero, decodingDuration: .zero, variant: variant)
    }
}
