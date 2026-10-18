package import Foundation

package struct TimedSegment: Equatable, Sendable {
    package let text: String

    let start: TimeInterval
    let end: TimeInterval

    package init(start: TimeInterval, end: TimeInterval, text: String) {
        self.start = start
        self.end = end
        self.text = text
    }
}
