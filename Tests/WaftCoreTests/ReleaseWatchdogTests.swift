import Foundation
import Testing
@testable import WaftCore

struct ReleaseWatchdogTests {
    @Test
    func `reports holding while the key is down`() {
        var watchdog = ReleaseWatchdog()

        #expect(watchdog.poll(isHeld: true, at: 1) == .holding)
    }

    @Test
    func `waits for several released polls before reporting a release`() {
        var watchdog = ReleaseWatchdog()
        let verdicts = (0 ..< ReleaseWatchdog.requiredReleasedPolls).map { poll in
            watchdog.poll(isHeld: false, at: 10 + Double(poll))
        }

        #expect(verdicts == Array(repeating: .holding, count: ReleaseWatchdog.requiredReleasedPolls - 1) + [.released(since: 10)])
    }

    @Test
    func `keeps the first release time on later polls`() {
        var watchdog = watchdog(releasedAt: (0 ..< ReleaseWatchdog.requiredReleasedPolls).map { 5 + Double($0) })

        #expect(watchdog.poll(isHeld: false, at: 20) == .released(since: 5))
    }

    @Test
    func `starts counting again after the key is seen held`() {
        var watchdog = watchdog(releasedAt: [1, 2, 3])

        #expect(watchdog.poll(isHeld: true, at: 4) == .holding)
        #expect(watchdog.poll(isHeld: false, at: 5) == .holding)
    }

    @Test
    func `forgets released polls on reset`() {
        var watchdog = watchdog(releasedAt: [1, 2, 3])
        watchdog.reset()
        let verdicts = [7.0, 8, 9, 10].map { watchdog.poll(isHeld: false, at: $0) }

        #expect(verdicts == [.holding, .holding, .holding, .released(since: 7)])
    }

    private func watchdog(releasedAt times: [TimeInterval]) -> ReleaseWatchdog {
        var watchdog = ReleaseWatchdog()

        for time in times {
            _ = watchdog.poll(isHeld: false, at: time)
        }

        return watchdog
    }
}
