package protocol LanguageDetector: Sendable {
    func language(of text: String, expecting expected: [Language]) -> Language?
}
