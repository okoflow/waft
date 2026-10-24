import Foundation
import Testing
import WaftCore

struct TimedTranscriptTests {
    @Test
    func `joins close segments and starts a paragraph after a long pause`() {
        let transcript = TimedTranscript(language: .english, segments: [
            TimedSegment(start: 0, end: 2, text: "Hello there."),
            TimedSegment(start: 3.5, end: 5, text: "How are you?"),
            TimedSegment(start: 7, end: 9, text: "New topic."),
            TimedSegment(start: 9.5, end: 10, text: "Still here."),
        ])

        #expect(transcript.text == "Hello there. How are you?\n\nNew topic. Still here.")
        #expect(transcript.duration == 10)
    }

    @Test
    func `joins segments without spaces in compact scripts`() {
        let transcript = TimedTranscript(language: .chinese, segments: [
            TimedSegment(start: 0, end: 1, text: "你好。"),
            TimedSegment(start: 1.2, end: 2, text: "再见。"),
        ])

        #expect(transcript.text == "你好。再见。")
    }

    @Test
    func `is empty without segments`() {
        let transcript = TimedTranscript(language: .english, segments: [])

        #expect(transcript.text.isEmpty)
        #expect(transcript.duration == 0)
    }
}
