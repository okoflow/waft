package struct Transcript: Equatable, Sendable {
    package let text: String
    package let language: Language
    package let duration: Duration
    package let isIncomplete: Bool

    let variant: WritingVariant?

    package init(
        text: String,
        language: Language,
        duration: Duration,
        variant: WritingVariant? = nil,
        isIncomplete: Bool = false,
    ) {
        self.text = text
        self.language = language
        self.variant = variant
        self.duration = duration
        self.isIncomplete = isIncomplete
    }
}
