import WaftCore

extension Transcript {
    nonisolated static func spoken(_ text: String, isIncomplete: Bool = false) -> Transcript {
        Transcript(
            text: text,
            language: .english,
            detectionDuration: .zero,
            decodingDuration: .zero,
            isIncomplete: isIncomplete,
        )
    }
}
