import WaftCore

nonisolated struct FakeLanguageDetector: LanguageDetector {
    var language: Language?

    func language(of _: String) -> Language? {
        language
    }
}
