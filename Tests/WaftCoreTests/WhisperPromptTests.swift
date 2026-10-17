import Testing
@testable import WaftCore

struct WhisperPromptTests {
    @Test
    func `starts with a sentence in the style of the language`() throws {
        let style = try #require(WhisperPrompt.text(for: .english, variant: nil, vocabulary: []))
        let prompt = try #require(WhisperPrompt.text(for: .english, variant: nil, vocabulary: ["Waft", "Kubernetes"]))

        #expect(prompt == style + " Waft, Kubernetes.")
    }

    @Test(arguments: [
        (Language.chinese, WritingVariant.simplified, "这是"),
        (.chinese, .traditional, "這是"),
        (.serbian, .latin, "Zdravo"),
        (.serbian, .cyrillic, "Здраво"),
    ])
    func `writes the style sentence in the chosen script`(language: Language, variant: WritingVariant, opening: String) throws {
        let prompt = try #require(WhisperPrompt.text(for: language, variant: variant, vocabulary: []))

        #expect(prompt.contains(opening))
    }

    @Test(arguments: [Language.japanese, .korean, .thai, .serbian])
    func `has no style sentence for some languages`(language: Language) {
        #expect(WhisperPrompt.text(for: language, variant: nil, vocabulary: []) == nil)
        #expect(WhisperPrompt.text(for: language, variant: nil, vocabulary: ["Waft"]) == "Waft.")
    }

    @Test
    func `skips blank terms and trims the rest`() {
        #expect(WhisperPrompt.text(for: .korean, variant: nil, vocabulary: ["  Waft ", "", " \n", "Okoflow"]) == "Waft, Okoflow.")
    }

    @Test
    func `stops the glossary at the length limit`() throws {
        let term = String(repeating: "a", count: 60)
        let text = try #require(WhisperPrompt.text(for: .japanese, variant: nil, vocabulary: [term, term, term, term, "short"]))

        #expect(text == [term, term, term].joined(separator: ", ") + ".")
        #expect(text.count - 1 <= WhisperPrompt.maximumGlossaryLength)
    }

    @Test
    func `keeps a glossary of exactly the limit`() {
        let term = String(repeating: "b", count: WhisperPrompt.maximumGlossaryLength)

        #expect(WhisperPrompt.text(for: .thai, variant: nil, vocabulary: [term]) == term + ".")
        #expect(WhisperPrompt.text(for: .thai, variant: nil, vocabulary: [term + "b"]) == nil)
    }
}
