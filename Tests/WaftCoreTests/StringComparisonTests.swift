import Testing
@testable import WaftCore

struct StringComparisonTests {
    @Test(arguments: [
        ("\u{015E}coală", Language.romanian, "\u{0219}coală"),
        ("مَرْحَبًا", .arabic, "مرحبا"),
        ("مـرحبا", .arabic, "مرحبا"),
        ("שָׁלוֹם", .hebrew, "שלום"),
        ("नमस्ते", .hindi, "नमसते"),
        ("İSTANBUL", .turkish, "istanbul"),
    ])
    func `folds letters by the rules of the language`(text: String, language: Language, expected: String) {
        #expect(text.folded(in: language) == expected)
    }

    @Test(arguments: ["مَرْحَبًا", "שָׁלוֹם", "नमस्ते"])
    func `keeps optional marks outside their language`(text: String) {
        #expect(text.folded(in: .english) == text)
    }

    @Test(arguments: [
        ("Thanks — for   watching!!", Language.english, "thanks for watching"),
        ("$5 + 3%", .english, "5 3"),
        ("ご視聴 ありがとう。", .japanese, "ご視聴ありがとう"),
    ])
    func `ignores punctuation, symbols, and extra spaces when comparing`(text: String, language: Language, expected: String) {
        #expect(text.normalizedForComparison(in: language) == expected)
    }

    @Test
    func `treats ё as е in a word`() {
        #expect("Ёлка".normalizedWord(in: .russian) == "елка")
    }
}
