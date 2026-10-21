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
}
