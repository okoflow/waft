import Foundation

package struct PushToTalk: Sendable {
    package enum Event: Equatable, Sendable {
        case keyDown
        case keyUp
        case otherKeyDown
        case monitorDisabled
        case tick
    }

    package enum Action: Equatable, Sendable {
        case startRecording
        case lockHandsFree
        case finishRecording
        case discardRecording(DiscardReason)
    }

    package enum DiscardReason: String, Sendable {
        case tooShort
        case otherKeyPressed
        case interrupted
    }

    private enum State: Equatable {
        case idle
        case holding(since: TimeInterval)
        case handsFree(since: TimeInterval)
    }

    static let minimumHold: TimeInterval = 0.3
    static let maximumHold: TimeInterval = 300

    private static let doubleTapWindow: TimeInterval = 0.4

    var allowsHandsFree = true

    private var state = State.idle
    private var lastTapEnded: TimeInterval?

    init() {}

    mutating func handle(_ event: Event, at time: TimeInterval) -> Action? {
        switch (state, event) {
        case (.idle, .keyDown):
            state = .holding(since: time)

            return .startRecording

        case let (.holding(since), .keyUp):
            return release(heldSince: since, at: time)

        case (.handsFree, .keyDown):
            state = .idle

            return .finishRecording

        case let (.holding(since), .tick) where time - since >= Self.maximumHold,
             let (.handsFree(since), .tick) where time - since >= Self.maximumHold:
            state = .idle

            return .finishRecording

        case (.holding, .otherKeyDown):
            state = .idle

            return .discardRecording(.otherKeyPressed)

        case (.holding, .monitorDisabled), (.handsFree, .monitorDisabled):
            state = .idle

            return .discardRecording(.interrupted)

        default:
            return nil
        }
    }

    private mutating func release(heldSince since: TimeInterval, at time: TimeInterval) -> Action {
        if time - since >= Self.minimumHold {
            state = .idle
            lastTapEnded = nil

            return .finishRecording
        }

        if allowsHandsFree, let lastTapEnded, since - lastTapEnded <= Self.doubleTapWindow {
            state = .handsFree(since: since)
            self.lastTapEnded = nil

            return .lockHandsFree
        }

        state = .idle
        lastTapEnded = time

        return .discardRecording(.tooShort)
    }
}
