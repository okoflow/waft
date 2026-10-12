import Testing
import WaftCore

struct InsertionSpacingTests {
    @Test(arguments: [
        ("hello", Character?.none, "hello"),
        ("  hello \n", nil, "hello"),
        ("hello", "a", " hello"),
        ("hello", ".", " hello"),
        ("hello", "!", " hello"),
        ("", "a", ""),
        ("   ", "a", ""),
    ])
    func `adds a space after a word`(text: String, previous: Character?, expected: String) {
        #expect(InsertionSpacing.prepared(text, after: previous) == expected)
    }

    @Test(arguments: [" ", "\n", "\t", "(", "[", "{", "<", "\"", "'", "‘", "“", "«", "„", "/"] as [Character])
    func `adds no space after whitespace or an opening mark`(previous: Character) {
        #expect(InsertionSpacing.prepared("hello", after: previous) == "hello")
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
