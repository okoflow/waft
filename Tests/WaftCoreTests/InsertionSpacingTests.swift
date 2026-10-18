import Testing
import WaftCore

struct InsertionSpacingTests {
    @Test(arguments: ["a", ".", "!"] as [Character])
    func `adds a space after a word or punctuation`(previous: Character) {
        #expect(InsertionSpacing.prepared("hello", after: previous) == " hello")
    }

    @Test(arguments: [nil, " ", "\n", "\t", "(", "[", "{", "<", "\"", "'", "‘", "“", "«", "„", "/"] as [Character?])
    func `adds no space at the start, after whitespace, or after an opening mark`(previous: Character?) {
        #expect(InsertionSpacing.prepared("hello", after: previous) == "hello")
    }

    @Test(arguments: [(Character?.none, "hello"), ("a", " hello")])
    func `trims the spaces around the text`(previous: Character?, expected: String) {
        #expect(InsertionSpacing.prepared(" \thello  ", after: previous) == expected)
    }

    @Test(arguments: [("Dear John.\n\n", " Dear John.\n\n"), ("\nHello", "\nHello"), ("\n", "\n")])
    func `keeps the line breaks that voice commands add at either end`(text: String, expected: String) {
        #expect(InsertionSpacing.prepared(text, after: "a") == expected)
    }

    @Test(arguments: ["", "   "])
    func `inserts nothing for blank text`(text: String) {
        #expect(InsertionSpacing.prepared(text, after: "a").isEmpty)
    }

    @Test(arguments: [
        ("世界", Character("a")),
        ("こんにちは", "あ"),
        ("hello", "。"),
        ("hello", "，"),
        ("カタカナ", "x"),
        ("漢字", "字"),
    ])
    func `adds no space next to scripts written without spaces`(text: String, previous: Character) {
        #expect(InsertionSpacing.prepared(text, after: previous) == text)
    }

    @Test(arguments: [("안녕하세요", Character("a")), ("привет", "."), ("مرحبا", "x")])
    func `adds a space before spaced scripts`(text: String, previous: Character) {
        #expect(InsertionSpacing.prepared(text, after: previous) == " " + text)
    }
}
