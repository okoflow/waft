package import Foundation

package struct RecentTranscripts: Sendable {
    package static let lifetime: TimeInterval = 600

    private var last: (text: String, date: Date)?

    package init() {}

    package func latest(at date: Date) -> String? {
        guard let last, date.timeIntervalSince(last.date) <= Self.lifetime else { return nil }

        return last.text
    }

    package mutating func remember(_ text: String, at date: Date) {
        last = (text, date)
    }
}
