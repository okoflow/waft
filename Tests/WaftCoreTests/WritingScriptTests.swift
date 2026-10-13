import Testing
@testable import WaftCore

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
}
