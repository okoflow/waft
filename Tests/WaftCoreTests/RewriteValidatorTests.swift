import Foundation
import Testing
@testable import WaftCore

struct RewriteValidatorTests {
    @Test(arguments: [
        ("So the meeting is on Friday.", "So the meeting is on Friday."),
        ("  So the meeting is on Friday.\n", "So the meeting is on Friday."),
        ("\"So the meeting is on Friday.\"", "So the meeting is on Friday."),
        ("<transcript>\nSo the meeting is on Friday.\n</transcript>", "So the meeting is on Friday."),
        ("<transcript>\"So the meeting is on Friday.\"</transcript>", "So the meeting is on Friday."),
        ("«So the meeting is on Friday.»", "So the meeting is on Friday."),
    ])
    func `unwraps quotes and transcript tags around a cleanup`(answer: String, expected: String) throws {
        #expect(try RewriteValidator.validated(answer, for: .cleanup("um so the meeting is on friday")) == expected)
    }

    @Test(arguments: ["\"hello\" she said \"bye\"", "hello she said bye"])
    func `keeps separate quotations around the answer`(transcript: String) throws {
        let answer = "\"Hello,\" she said, \"bye.\""

        #expect(try RewriteValidator.validated(answer, for: .cleanup(transcript)) == answer)
    }

    @Test(arguments: ["", "   \n", "\" \"", "\"\"", "«»", "<transcript> </transcript>", "<transcript></transcript>"])
    func `rejects an empty cleanup`(answer: String) {
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(answer, for: .cleanup("hello there"))
        }
    }

    @Test(arguments: [(RewriteRequest.cleanup("hi"), 2 * 3 + 60), (.custom("tell him yes friday works"), 600)])
    func `rejects an answer longer than the limit of its request`(request: RewriteRequest, limit: Int) throws {
        #expect(try RewriteValidator.validated(String(repeating: "a", count: limit), for: request).count == limit)
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(String(repeating: "a", count: limit + 1), for: request)
        }
    }

    @Test
    func `allows longer translations from compact scripts`() throws {
        let request = RewriteRequest.cleanup("こんにちは", language: .japanese, target: .english)
        let answer = String(repeating: "a", count: 5 * 5 + 60)

        #expect(try RewriteValidator.validated(answer, for: request) == answer)
    }

    @Test(arguments: [
        ("hello there", Language.english, "Привет всем"),
        ("привет всем", .russian, "Hello everyone"),
        ("こんにちは", .japanese, "Hello there"),
    ])
    func `rejects an answer in another script`(transcript: String, language: Language, answer: String) {
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(answer, for: .cleanup(transcript, language: language))
        }
    }

    @Test(arguments: [
        ("привет всем", Language.english, "Привет всем."),
        ("hello 123", .english, "12:30"),
        ("今日は会議です", .japanese, "今日は会議です。"),
    ])
    func `accepts the script of the transcript or the language`(transcript: String, language: Language, answer: String) throws {
        #expect(try RewriteValidator.validated(answer, for: .cleanup(transcript, language: language)) == answer)
    }

    @Test(arguments: [
        (Language.russian, "Привет всем."),
        (.japanese, "皆さん、こんにちは。"),
        (.german, "Hallo zusammen."),
        (.chinese, "我买了一台新的 MacBook Pro。"),
        (.japanese, "Safariを開いて。"),
        (.korean, "Safari를 열어 줘."),
    ])
    func `expects the script of the translation target`(target: Language, answer: String) throws {
        #expect(try RewriteValidator.validated(answer, for: .cleanup("hello everyone", target: target)) == answer)
    }

    @Test
    func `rejects a translation left in the spoken script`() {
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated("Hello everyone.", for: .cleanup("hello everyone", target: .russian))
        }
    }

    @Test(arguments: [
        ("hello there", Language.english, "Привет всем."),
        ("see you friday", .english, "金曜日に会いましょう。"),
        ("привет всем", .russian, "Hello everyone."),
    ])
    func `accepts a custom answer in any script`(transcript: String, language: Language, answer: String) throws {
        #expect(try RewriteValidator.validated(answer, for: .custom(transcript, language: language)) == answer)
    }

    @Test(arguments: ["", "  ", "\"\"", "<transcript></transcript>"])
    func `rejects an empty custom answer`(answer: String) {
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(answer, for: .custom("hello there"))
        }
    }

    @Test(arguments: [
        ("<text>Shorter.</text>", "Shorter."),
        ("<text>\nShorter.\n</text>", "Shorter."),
        ("<text>\"Shorter.\"</text>", "Shorter."),
        ("\"Shorter.\"", "Shorter."),
        ("Короче.", "Короче."),
    ])
    func `unwraps an edit`(answer: String, expected: String) throws {
        #expect(try RewriteValidator
            .validated(answer, for: .edit("make it shorter", selection: "A much longer text.")) == expected)
    }

    @Test
    func `does not limit the length of an edit`() throws {
        let answer = String(repeating: "word ", count: 500).trimmingCharacters(in: .whitespaces)

        #expect(try RewriteValidator.validated(answer, for: .edit("make it shorter", selection: "word")) == answer)
    }

    @Test(arguments: ["", "  ", "\" \"", "\"\"", "<text> </text>", "<text></text>"])
    func `rejects an empty edit`(answer: String) {
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(answer, for: .edit("make it shorter", selection: "Some text."))
        }
    }
}
