package struct Transcript: Equatable, Sendable {
    package let text: String
    package let language: Language
    package let detectionDuration: Duration
    package let decodingDuration: Duration
    package let isIncomplete: Bool

    let variant: WritingVariant?

    package init(
        text: String,
        language: Language,
        detectionDuration: Duration,
        decodingDuration: Duration,
        variant: WritingVariant? = nil,
        isIncomplete: Bool = false,
    ) {
        self.text = text
        self.language = language
        self.variant = variant
        self.detectionDuration = detectionDuration
        self.decodingDuration = decodingDuration
        self.isIncomplete = isIncomplete
    }
}
