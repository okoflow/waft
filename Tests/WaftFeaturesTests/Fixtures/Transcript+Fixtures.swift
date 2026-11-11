import WaftCore

extension Transcript {
    nonisolated static func spoken(_ text: String, isIncomplete: Bool = false) -> Transcript {
        Transcript(
            text: text,
            language: .english,
            duration: .zero,
            isIncomplete: isIncomplete,
        )
    }
}
