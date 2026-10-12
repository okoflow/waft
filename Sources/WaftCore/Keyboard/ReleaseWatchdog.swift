package import Foundation

package struct ReleaseWatchdog: Sendable {
    package enum Verdict: Equatable, Sendable {
        case holding
        case released(since: TimeInterval)
    }

    static let requiredReleasedPolls = 4

    private var releaseStart: TimeInterval?
    private var releasedPolls = 0

    package init() {}

    package mutating func poll(isHeld: Bool, at time: TimeInterval) -> Verdict {
        guard !isHeld else {
            reset()

            return .holding
        }

        if releaseStart == nil {
            releaseStart = time
        }

        releasedPolls += 1

        guard releasedPolls >= Self.requiredReleasedPolls, let releaseStart else { return .holding }

        return .released(since: releaseStart)
    }

    package mutating func reset() {
        releaseStart = nil
        releasedPolls = 0
    }
}
