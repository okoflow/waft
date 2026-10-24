import Foundation
import Testing
import WaftCore

struct DictationHistoryTests {
    @Test
    func `ignores empty dictations`() {
        var history = DictationHistory()
        history.add(entry("", minutesAgo: 1))
        history.add(entry("Hello.", minutesAgo: 1))

        #expect(history.entries.map(\.text) == ["Hello."])
    }

    @Test
    func `lists the newest entry first`() {
        var history = DictationHistory()
        history.add(entry("First.", minutesAgo: 3))
        history.add(entry("Second.", minutesAgo: 2))

        #expect(history.newestFirst.map(\.text) == ["Second.", "First."])
    }

    @Test(arguments: [
        (HistoryRetention.day, ["Today."]),
        (.week, ["Three days ago.", "Today."]),
        (.month, ["Three weeks ago.", "Three days ago.", "Today."]),
        (.year, ["Two months ago.", "Three weeks ago.", "Three days ago.", "Today."]),
        (.forever, ["Two years ago.", "Two months ago.", "Three weeks ago.", "Three days ago.", "Today."]),
    ])
    func `drops entries older than the retention`(retention: HistoryRetention, kept: [String]) {
        var history = DictationHistory()
        history.add(entry("Two years ago.", minutesAgo: 60 * 24 * 800))
        history.add(entry("Two months ago.", minutesAgo: 60 * 24 * 61))
        history.add(entry("Three weeks ago.", minutesAgo: 60 * 24 * 21))
        history.add(entry("Three days ago.", minutesAgo: 60 * 24 * 3))
        history.add(entry("Today.", minutesAgo: 5))

        history.prune(keeping: retention, limit: 100, now: .fixed)

        #expect(history.entries.map(\.text) == kept)
    }

    @Test(arguments: [(2, ["4", "5"]), (5, ["1", "2", "3", "4", "5"]), (0, [])])
    func `keeps only the newest entries within the limit`(limit: Int, kept: [String]) {
        var history = DictationHistory()

        for number in 1 ... 5 {
            history.add(entry("\(number)", minutesAgo: 10 - Double(number)))
        }

        history.prune(keeping: .forever, limit: limit, now: .fixed)

        #expect(history.entries.map(\.text) == kept)
    }

    @Test
    func `clears every entry`() {
        var history = DictationHistory()
        history.add(entry("Hello.", minutesAgo: 1))

        history.removeAll()

        #expect(history.entries.isEmpty)
    }

    @Test(arguments: [
        ("Short line.", "Short line."),
        ("Two\nlines", "Two lines"),
        ("Windows\r\nlines", "Windows lines"),
        ("Paragraph\u{2029}break", "Paragraph break"),
        (String(repeating: "a", count: 50), String(repeating: "a", count: 50)),
        (String(repeating: "a", count: 51), String(repeating: "a", count: 49) + "…"),
    ])
    func `previews an entry on one short line`(text: String, preview: String) {
        #expect(entry(text, minutesAgo: 0).preview == preview)
    }

    @Test
    func `survives an encoding round trip`() throws {
        var history = DictationHistory()
        history.add(DictationHistory.Entry(date: .fixed, text: "Hello.", mode: .clean, app: "com.apple.mail"))
        history.add(DictationHistory.Entry(date: .fixed, text: "Bye.", mode: .raw, app: nil))
        history.add(DictationHistory.Entry(date: .fixed, text: "Hi there.", mode: .clean, app: nil, transcript: "hi there"))

        let data = try JSONEncoder().encode(history)

        #expect(try JSONDecoder().decode(DictationHistory.self, from: data) == history)
    }

    @Test(arguments: [
        (
            #"{"entries":[{"date":0,"text":"Kept.","mode":"clean"},{"date":0,"text":"Bad.","mode":"bogus"},{"date":0}]}"#,
            ["Kept."],
        ),
        (#"{}"#, []),
    ])
    func `decodes the readable entries`(json: String, kept: [String]) throws {
        let history = try JSONDecoder().decode(DictationHistory.self, from: Data(json.utf8))

        #expect(history.entries.map(\.text) == kept)
    }

    @Test
    func `loads an entry saved before it kept the original transcript`() throws {
        let json = #"{"entries":[{"date":0,"text":"Kept.","mode":"clean","app":"com.apple.mail"}]}"#

        let history = try JSONDecoder().decode(DictationHistory.self, from: Data(json.utf8))

        let entry = try #require(history.entries.first)
        #expect(entry.text == "Kept.")
        #expect(entry.app == "com.apple.mail")
        #expect(entry.transcript == nil)
    }

    @Test(arguments: [("hi there", String?.some("hi there")), ("Hi there.", nil), (nil, nil)])
    func `keeps the original transcript only when the mode changed it`(transcript: String?, kept: String?) {
        let entry = DictationHistory.Entry(date: .fixed, text: "Hi there.", mode: .clean, app: nil, transcript: transcript)

        #expect(entry.transcript == kept)
    }

    private func entry(_ text: String, minutesAgo: Double) -> DictationHistory.Entry {
        DictationHistory.Entry(date: Date.fixed.addingTimeInterval(-minutesAgo * 60), text: text, mode: .light, app: nil)
    }
}
