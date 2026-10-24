import Foundation
import Testing
import WaftCore

struct SubtitleFormatterTests {
    @Test(arguments: [(3725.5, "01:02:05,500"), (59.9994, "00:00:59,999"), (59.9996, "00:01:00,000"), (-3, "00:00:00,000")])
    func `formats hours, minutes, seconds, and milliseconds`(time: TimeInterval, timestamp: String) {
        let output = srt(segment(time, time + 1, "Hi."))

        #expect(output.contains("\n\(timestamp) --> "))
    }

    @Test
    func `separates cues with a blank line`() {
        let output = srt(segment(0, 1, "One."), segment(1.5, 2.5, "Two."))

        #expect(output == "1\n00:00:00,000 --> 00:00:01,000\nOne.\n\n2\n00:00:01,500 --> 00:00:02,500\nTwo.\n")
    }

    @Test
    func `splits a long cue into two balanced lines`() throws {
        let text = "Meet me at the station at noon, and bring the tickets for both of us"

        let cue = try #require(cues(of: srt(segment(0, 4, text))).first)

        #expect(cue.lines.count == 2)
        #expect(cue.lines.allSatisfy { $0.count <= 42 })
        #expect(cue.lines.joined(separator: " ") == text)
        #expect(cue.lines.first?.last == ",")
    }

    @Test
    func `splits a line after an Arabic comma`() throws {
        let text = "نلتقي عند المحطة القديمة ظهرا، ثم نمشي معا إلى النهر لنتناول الغداء"

        let output = SubtitleFormatter.srt(TimedTranscript(language: .arabic, segments: [segment(0, 4, text)]))

        let cue = try #require(cues(of: output).first)

        #expect(cue.lines.first?.last == "،")
    }

    @Test
    func `prefers a split where both lines fit`() throws {
        let text = "We will meet at the old station, then walk to the river and have lunch by the bridge"

        let cue = try #require(cues(of: srt(segment(0, 5, text))).first)

        #expect(cue.lines == ["We will meet at the old station, then walk", "to the river and have lunch by the bridge"])
    }

    @Test
    func `splits a long segment into cues with rising times`() {
        let text = Array(repeating: "Every word here is short, and the sentence keeps going on and on.", count: 4)
            .joined(separator: " ")

        let cues = cues(of: srt(segment(10, 30, text)))

        #expect(cues.count > 1)
        #expect(cues.map(\.index) == Array(1 ... cues.count))
        #expect(zip(cues, cues.dropFirst()).allSatisfy { $0.end == $1.start })
        #expect(cues.allSatisfy { $0.start < $0.end })
        #expect(cues.flatMap(\.lines).allSatisfy { $0.count <= 42 })
        #expect(cues.flatMap(\.lines).joined(separator: " ") == text)
        #expect(cues.first?.start == 10)
        #expect(cues.last?.end == 30)
    }

    @Test
    func `keeps overlapping segments from going back in time`() {
        let cues = cues(of: srt(segment(0, 3, "First."), segment(2, 5, "Second."), segment(4, 4.5, "Third.")))

        #expect(cues.map(\.start) == [0, 3, 5])
        #expect(cues.map(\.end) == [3, 5, 5])
    }

    @Test
    func `breaks compact scripts into short lines without spaces`() throws {
        let text = "今日はとても良い天気ですね、散歩に行きましょう"

        let output = SubtitleFormatter.srt(TimedTranscript(language: .japanese, segments: [segment(0, 3, text)]))

        let cue = try #require(cues(of: output).first)

        #expect(cue.lines.count == 2)
        #expect(cue.lines.allSatisfy { $0.count <= 18 })
        #expect(cue.lines.joined() == text)
    }

    @Test
    func `keeps a word longer than a line on one line`() {
        let url = "https://example.com/" + String(repeating: "segment/", count: 12)

        #expect(srt(segment(0, 2, url)) == "1\n00:00:00,000 --> 00:00:02,000\n\(url)\n")
    }

    @Test
    func `skips a segment without text`() {
        let output = srt(segment(0, 1, "One."), segment(1, 2, ""), segment(2, 3, "Two."))

        #expect(output == "1\n00:00:00,000 --> 00:00:01,000\nOne.\n\n2\n00:00:02,000 --> 00:00:03,000\nTwo.\n")
    }

    @Test
    func `writes nothing for an empty transcript`() {
        #expect(srt().isEmpty)
    }

    private func srt(_ segments: TimedSegment...) -> String {
        SubtitleFormatter.srt(TimedTranscript(language: .english, segments: segments))
    }

    private func segment(_ start: TimeInterval, _ end: TimeInterval, _ text: String) -> TimedSegment {
        TimedSegment(start: start, end: end, text: text)
    }

    private func cues(of srt: String) -> [SubtitleCue] {
        srt.components(separatedBy: "\n\n").compactMap(SubtitleCue.init)
    }
}

private struct SubtitleCue {
    let index: Int
    let start: TimeInterval
    let end: TimeInterval
    let lines: [String]

    init?(_ block: String) {
        let rows = block.split(separator: "\n").map(String.init)

        let times = rows.dropFirst().first?.components(separatedBy: " --> ").compactMap(Self.seconds)
        guard rows.count >= 3, let index = Int(rows[0]), let times, times.count == 2 else { return nil }

        self.index = index
        start = times[0]
        end = times[1]
        lines = Array(rows.dropFirst(2))
    }

    private static func seconds(_ timestamp: String) -> TimeInterval? {
        let parts = timestamp.split(whereSeparator: { [":", ","].contains($0) }).compactMap { Double($0) }
        guard parts.count == 4 else { return nil }

        return parts[0] * 3600 + parts[1] * 60 + parts[2] + parts[3] / 1000
    }
}
