import Foundation

package struct PushToTalk: Sendable {
    package enum Event: Equatable, Sendable {
        case keyDown
        case keyUp
        case otherKeyDown
        case escapeDown
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
        case cancelled
        case interrupted
    }

    private enum State {
        case idle
        case holding(since: TimeInterval)
        case handsFree(since: TimeInterval)
    }

    static let minimumHold: TimeInterval = 0.3
    static let maximumHold: TimeInterval = 300

    private static let doubleTapWindow: TimeInterval = 0.4

    var dictationStart = DictationStart.holdOrDoubleTap

    private var state = State.idle
    private var lastTapEnded: TimeInterval?

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

        case (.holding, .escapeDown), (.handsFree, .escapeDown):
            state = .idle

            return .discardRecording(.cancelled)

        case (.holding, .monitorDisabled), (.handsFree, .monitorDisabled):
            state = .idle

            return .discardRecording(.interrupted)

        default:
            return nil
        }
    }

    mutating func reset() {
        state = .idle
    }

    private mutating func release(heldSince since: TimeInterval, at time: TimeInterval) -> Action {
        if dictationStart == .tap {
            state = .handsFree(since: since)

            return .lockHandsFree
        }

        if time - since >= Self.minimumHold {
            state = .idle
            lastTapEnded = nil

            return .finishRecording
        }

        if dictationStart == .holdOrDoubleTap, let lastTapEnded, since - lastTapEnded <= Self.doubleTapWindow {
            state = .handsFree(since: since)
            self.lastTapEnded = nil

            return .lockHandsFree
        }

        state = .idle
        lastTapEnded = time

        return .discardRecording(.tooShort)
    }
}
