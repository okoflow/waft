import Testing
import WaftCore

struct WritingScriptTests {
    @Test(arguments: [
        ("Привет, world", WritingScript?.some(.cyrillic)),
        ("今日はカタカナ", .kana),
        ("abc где", nil),
        ("ab გამარჯობა", nil),
        ("12:30", nil),
    ])
    func `finds the script of more than half of the letters`(text: String, expected: WritingScript?) {
        #expect(WritingScript.dominant(in: text) == expected)
    }

    @Test(arguments: [("مرحبا بكم", true), ("שלום עולם", true), ("Привет, world", false)])
    func `writes Arabic and Hebrew from right to left`(text: String, isRightToLeft: Bool) throws {
        let script = try #require(WritingScript.dominant(in: text))

        #expect(script.isRightToLeft == isRightToLeft)
    }
}
