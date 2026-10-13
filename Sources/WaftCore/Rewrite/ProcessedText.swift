package struct ProcessedText: Equatable, Sendable {
    package let text: String
    package let mode: Mode
    package let fallback: RewriteFallback?

    package init(text: String, mode: Mode, fallback: RewriteFallback? = nil) {
        self.text = text
        self.mode = mode
        self.fallback = fallback
    }
}
