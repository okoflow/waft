extension Settings {
    package func conflict(with combination: KeyCombination, recording action: ShortcutAction) -> ShortcutConflict? {
        if let other = shortcuts.action(using: combination), other != action {
            return .shortcut(other)
        }

        if combination.keyCode == pushToTalkKey.keyCode {
            return .key(.dictation)
        }

        guard let editKey, combination.keyCode == editKey.keyCode else { return nil }

        return .key(.edit)
    }

    package func conflict(with key: PushToTalkKey, recording purpose: RecordingPurpose) -> ShortcutConflict? {
        if let other = recordingPurpose(of: key), other != purpose {
            return .key(other)
        }

        guard let action = shortcuts.action(usingKeyCode: key.keyCode) else { return nil }

        return .shortcut(action)
    }

    private func recordingPurpose(of key: PushToTalkKey) -> RecordingPurpose? {
        if key == pushToTalkKey {
            return .dictation
        }

        guard key == editKey else { return nil }

        return .edit
    }
}
