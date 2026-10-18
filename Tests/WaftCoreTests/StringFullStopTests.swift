import Testing
@testable import WaftCore

struct StringFullStopTests {
    @Test(arguments: [
        ("Hello", Language.english, "Hello."),
        ("Room 42", .english, "Room 42."),
        ("Hello!", .english, "Hello!"),
        ("Hello,", .english, "Hello,"),
        ("", .english, ""),
        ("你好", .chinese, "你好。"),
        ("नमस्ते", .hindi, "नमस्ते।"),
        ("سلام", .urdu, "سلام۔"),
        ("مرحبا", .arabic, "مرحبا."),
        ("สวัสดี", .thai, "สวัสดี"),
    ])
    func `ends text that stops on a letter or digit with the full stop of its language`(
        text: String,
        language: Language,
        expected: String,
    ) {
        #expect(text.endingWithFullStop(in: language) == expected)
    }
}
