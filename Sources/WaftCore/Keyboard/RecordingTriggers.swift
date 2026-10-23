package import Foundation

package struct RecordingTriggers: Sendable {
    private static let escapeTimeTolerance: TimeInterval = 0.05

    private var dictation = PushToTalk()
    private var edit = PushToTalk()
    private var cancelledAt: TimeInterval?

    package init() {
        edit.dictationStart = .hold
    }

    private static func key(for purpose: RecordingPurpose, in settings: Settings) -> PushToTalkKey? {
        switch purpose {
        case .dictation: settings.pushToTalkKey
        case .edit: settings.editKey == settings.pushToTalkKey ? nil : settings.editKey
        }
    }

    package mutating func handle(_ keyEvent: KeyEvent, settings: Settings) -> [RecordingTrigger] {
        RecordingPurpose.allCases.compactMap { purpose in
            guard let key = Self.key(for: purpose, in: settings),
                  let event = key.event(for: keyEvent),
                  let action = handle(event, for: purpose, at: keyEvent.timestamp, settings: settings)
            else { return nil }

            return RecordingTrigger(purpose: purpose, key: key, action: action)
        }
    }

    package mutating func handle(
        _ event: PushToTalk.Event,
        for purpose: RecordingPurpose,
        at time: TimeInterval,
        settings: Settings,
    ) -> PushToTalk.Action? {
        let action = action(for: event, of: purpose, at: time, settings: settings)

        if action == .discardRecording(.cancelled) {
            cancelledAt = time
        }

        return action
    }

    package func cancelledRecording(byEscapeAt time: TimeInterval) -> Bool {
        guard let cancelledAt else { return false }

        return abs(cancelledAt - time) < Self.escapeTimeTolerance
    }

    package mutating func reset(_ purpose: RecordingPurpose) {
        switch purpose {
        case .dictation: dictation.reset()
        case .edit: edit.reset()
        }
    }

    private mutating func action(
        for event: PushToTalk.Event,
        of purpose: RecordingPurpose,
        at time: TimeInterval,
        settings: Settings,
    ) -> PushToTalk.Action? {
        switch purpose {
        case .dictation:
            dictation.dictationStart = settings.dictationStart

            return dictation.handle(event, at: time)

        case .edit:
            return edit.handle(event, at: time)
        }
    }
}
