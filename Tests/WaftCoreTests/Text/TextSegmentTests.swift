import Testing
@testable import WaftCore

struct TextSegmentTests {
    private static func word(_ text: String) -> TextSegment {
        TextSegment(text: text, isWord: true)
    }

    private static func separator(_ text: String) -> TextSegment {
        TextSegment(text: text, isWord: false)
    }

    @Test(arguments: [
        ("hello, world", [word("hello"), separator(", "), word("world")]),
        ("नमस्ते दोस्तों", [word("नमस्ते"), separator(" "), word("दोस्तों")]),
    ])
    func `splits text into words and separators`(text: String, segments: [TextSegment]) {
        #expect(TextSegment.split(text) == segments)
    }

    @Test(arguments: ["don't", "well-known", "5-year", "צה״ל"])
    func `keeps a joiner between letters inside a word`(text: String) {
        #expect(TextSegment.split(text) == [Self.word(text)])
    }

    @Test(arguments: [
        ("'quoted'", [separator("'"), word("quoted"), separator("'")]),
        ("year-5", [word("year"), separator("-"), word("5")]),
        ("-dash", [separator("-"), word("dash")]),
    ])
    func `separates a joiner at the edge of a word`(text: String, segments: [TextSegment]) {
        #expect(TextSegment.split(text) == segments)
    }

    @Test
    func `lists the words of a text in their compared form`() {
        #expect(TextSegment.words(of: "Ёлка, NEW-line!", in: .russian) == ["елка", "new-line"])
    }
}
