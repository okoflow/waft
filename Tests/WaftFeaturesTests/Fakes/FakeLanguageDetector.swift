import WaftCore

nonisolated struct FakeLanguageDetector: LanguageDetector {
    var language: Language?
    var languagesByText: [String: Language] = [:]

    func language(of text: String, expecting _: [Language]) -> Language? {
        guard let detected = languagesByText[text] else { return language }

        return detected
    }
}
