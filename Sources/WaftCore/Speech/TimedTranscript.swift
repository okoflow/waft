package import Foundation

package struct TimedTranscript: Equatable, Sendable {
    private static let paragraphPause: TimeInterval = 2

    package let language: Language

    let segments: [TimedSegment]

    package var duration: TimeInterval {
        guard let last = segments.last else { return 0 }

        return last.end
    }

    package var text: String {
        var paragraphs: [[String]] = []
        var previousEnd: TimeInterval?

        for segment in segments {
            if let previousEnd, segment.start - previousEnd < Self.paragraphPause {
                paragraphs[paragraphs.count - 1].append(segment.text)
            } else {
                paragraphs.append([segment.text])
            }

            previousEnd = segment.end
        }

        let separator = language.wordSeparator

        return paragraphs.map { $0.joined(separator: separator) }.joined(separator: "\n\n")
    }

    package init(language: Language, segments: [TimedSegment]) {
        self.language = language
        self.segments = segments
    }
}
