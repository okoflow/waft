package struct Transcript: Equatable, Sendable {
    package let text: String
    package let language: Language
    package let detectionDuration: Duration
    package let decodingDuration: Duration

    let variant: WritingVariant?

    package init(
        text: String,
        language: Language,
        detectionDuration: Duration,
        decodingDuration: Duration,
        variant: WritingVariant? = nil,
    ) {
        self.text = text
        self.language = language
        self.variant = variant
        self.detectionDuration = detectionDuration
        self.decodingDuration = decodingDuration
    }
}
