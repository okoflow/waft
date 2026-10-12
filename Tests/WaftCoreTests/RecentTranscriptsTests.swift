import Foundation
import Testing
import WaftCore

struct RecentTranscriptsTests {
    @Test
    func `has nothing to offer at first`() {
        #expect(RecentTranscripts().latest(at: .fixed) == nil)
    }

    @Test(arguments: [
        (60.0, String?.some("Second.")),
        (RecentTranscripts.lifetime, "Second."),
        (RecentTranscripts.lifetime + 1, nil),
    ])
    func `offers the latest transcript within its lifetime`(age: TimeInterval, expected: String?) {
        var recent = RecentTranscripts()
        recent.remember("First.", at: Date.fixed.addingTimeInterval(-30))
        recent.remember("Second.", at: .fixed)

        #expect(recent.latest(at: Date.fixed.addingTimeInterval(age)) == expected)
    }

    @Test
    func `remembers only the latest transcript`() {
        let read = Date.fixed.addingTimeInterval(RecentTranscripts.lifetime + 100)
        var recent = RecentTranscripts()
        recent.remember("Fresh.", at: read)
        recent.remember("Expired.", at: .fixed)

        #expect(recent.latest(at: read) == nil)
    }
}
