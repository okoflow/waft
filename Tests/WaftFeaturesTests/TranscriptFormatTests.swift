import Testing
import WaftCore
@testable import WaftFeatures

struct TranscriptFormatTests {
    private nonisolated static let transcript = TimedTranscript(
        language: .english,
        segments: [TimedSegment(start: 0, end: 1.5, text: "Hello there.")],
    )

    @Test(arguments: [
        (TranscriptFormat.text, "txt", "Hello there.\n"),
        (.subtitles, "srt", "1\n00:00:00,000 --> 00:00:01,500\nHello there.\n"),
    ])
    func `saves the transcript as text or as subtitles`(format: TranscriptFormat, fileExtension: String, contents: String) {
        #expect(format.fileExtension == fileExtension)
        #expect(format.contents(of: Self.transcript) == contents)
    }
}
