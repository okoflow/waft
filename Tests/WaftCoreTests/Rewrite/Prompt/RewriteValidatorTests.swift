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
        ("\"<transcript>So the meeting is on Friday.</transcript>\"", "So the meeting is on Friday."),
        ("«So the meeting is on Friday.»", "So the meeting is on Friday."),
        ("«\"So the meeting is on Friday.\"»", "So the meeting is on Friday."),
    ])
    func `unwraps quotes and transcript tags around a cleanup`(answer: String, expected: String) throws {
        #expect(try RewriteValidator.validated(answer, for: .cleanup("um so the meeting is on friday")) == expected)
    }

    @Test(arguments: ["\"hello\" she said \"bye\"", "hello she said bye"])
    func `keeps separate quotations around the answer`(transcript: String) throws {
        let answer = "\"Hello,\" she said, \"bye.\""

        #expect(try RewriteValidator.validated(answer, for: .cleanup(transcript)) == answer)
    }

    @Test(arguments: [
        (RewriteRequest.cleanup("hi"), 2 * 3 + 60),
        (.custom("tell him yes friday works"), 600),
        (.text("Hi.", task: .fix), 3 * 5 + 200),
    ])
    func `rejects an answer longer than the limit of its request`(request: RewriteRequest, limit: Int) throws {
        #expect(try RewriteValidator.validated(String(repeating: "a", count: limit), for: request).count == limit)
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(String(repeating: "a", count: limit + 1), for: request)
        }
    }

    @Test(arguments: [
        (RewriteRequest.cleanup(String(repeating: "a", count: 200)), 80),
        (.cleanup(String(repeating: "a", count: 501)), 201),
    ])
    func `rejects a cleanup that lost most of a long transcript`(request: RewriteRequest, minimum: Int) throws {
        #expect(try RewriteValidator.validated(String(repeating: "a", count: minimum), for: request).count == minimum)
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(String(repeating: "a", count: minimum - 1), for: request)
        }
    }

    @Test(arguments: [
        RewriteRequest.cleanup(String(repeating: "a", count: 199)),
        .cleanup(String(repeating: "a", count: 400), target: .german),
        .custom(String(repeating: "a", count: 400)),
        .text(String(repeating: "a", count: 400), task: .fix),
    ])
    func `accepts a short answer to a short transcript, a translation, or another task`(request: RewriteRequest) throws {
        #expect(try RewriteValidator.validated("Done.", for: request) == "Done.")
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

    @Test(arguments: [
        ("<text>Shorter.</text>", "Shorter."),
        ("<text>\nShorter.\n</text>", "Shorter."),
        ("<text>\"Shorter.\"</text>", "Shorter."),
        ("\"Shorter.\"", "Shorter."),
        ("\"<text>Shorter.</text>\"", "Shorter."),
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

    @Test(arguments: [("<text>\nHallo.\n</text>", "Hallo."), ("«Hallo.»", "Hallo."), ("Hallo.", "Hallo.")])
    func `unwraps the answer to a text task`(answer: String, expected: String) throws {
        let request = RewriteRequest.text("Hello.", task: .translate(from: nil, into: .german))

        #expect(try RewriteValidator.validated(answer, for: request) == expected)
    }

    @Test(arguments: [
        (RewriteRequest.cleanup("hello there"), ""),
        (.cleanup("hello there"), "   \n"),
        (.cleanup("hello there"), "\" \""),
        (.cleanup("hello there"), "\"\""),
        (.cleanup("hello there"), "«»"),
        (.cleanup("hello there"), "<transcript> </transcript>"),
        (.cleanup("hello there"), "<transcript></transcript>"),
        (.custom("hello there"), ""),
        (.custom("hello there"), "  "),
        (.custom("hello there"), "\"\""),
        (.custom("hello there"), "<transcript></transcript>"),
        (.edit("make it shorter", selection: "Some text."), ""),
        (.edit("make it shorter", selection: "Some text."), "  "),
        (.edit("make it shorter", selection: "Some text."), "\" \""),
        (.edit("make it shorter", selection: "Some text."), "\"\""),
        (.edit("make it shorter", selection: "Some text."), "<text> </text>"),
        (.edit("make it shorter", selection: "Some text."), "<text></text>"),
        (.text("Hi.", task: .fix), ""),
        (.text("Hi.", task: .fix), "  "),
        (.text("Hi.", task: .fix), "\" \""),
        (.text("Hi.", task: .fix), "\"\""),
        (.text("Hi.", task: .fix), "<text> </text>"),
        (.text("Hi.", task: .fix), "<text></text>"),
    ])
    func `rejects an empty answer to any request`(request: RewriteRequest, answer: String) {
        #expect(throws: RewriteError.unreadableResponse) {
            try RewriteValidator.validated(answer, for: request)
        }
    }
}
