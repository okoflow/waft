import Testing
@testable import WaftCore

struct VoiceCommandsTests {
    @Test(arguments: [
        ("first line, new line, second line", Language.english, "first line\nSecond line"),
        ("Hello. New line. World", .english, "Hello.\nWorld"),
        ("one, newline, two", .english, "one\nTwo"),
        ("one, next line, two", .english, "one\nTwo"),
        ("hello, new paragraph, world", .english, "hello.\n\nWorld"),
        ("Done! Next paragraph. Then more", .english, "Done!\n\nThen more"),
        ("the end, new line", .english, "the end\n"),
        ("newline", .english, "\n"),
        ("привет, новая строка, как дела", .russian, "привет\nКак дела"),
        ("привет, с новой строки, как дела", .russian, "привет\nКак дела"),
        ("итак, новый абзац, начнём", .russian, "итак.\n\nНачнём"),
        ("итак, С нового абзаца, начнём", .russian, "итак.\n\nНачнём"),
        ("你好，换行，世界", .chinese, "你好\n世界"),
    ])
    func `turns spoken commands into line breaks`(text: String, language: Language, expected: String) {
        #expect(VoiceCommands.apply(text, language: language) == expected)
    }

    @Test(arguments: ["a new line of products", "we need a new paragraph here"])
    func `keeps command words that are not set off by pauses`(text: String) {
        #expect(VoiceCommands.apply(text, language: .english) == text)
    }

    @Test
    func `leaves languages without commands untouched`() {
        let text = "γεια, new line, κόσμε"

        #expect(VoiceCommands.apply(text, language: .greek) == text)
    }

    @Test
    func `uses the full stop of the language before a paragraph`() {
        #expect(VoiceCommands.apply("你好，新段落，世界", language: .chinese) == "你好。\n\n世界")
    }
}
