import Observation
import os
import WaftCore

@Observable
final class GlobalShortcutController {
    private(set) var unavailable: Set<ShortcutAction> = []

    @ObservationIgnored private var handlers: [ShortcutAction: @MainActor () -> Void] = [:]
    @ObservationIgnored private var attempted: [ShortcutAction: KeyCombination] = [:]
    @ObservationIgnored private var isSuspended = false

    private let shortcuts: GlobalShortcuts
    private let settings: SettingsModel

    var layout: any KeyboardLayout {
        shortcuts.layout
    }

    init(shortcuts: GlobalShortcuts, settings: SettingsModel) {
        self.shortcuts = shortcuts
        self.settings = settings
    }

    func handle(_ action: ShortcutAction, with handler: @escaping @MainActor () -> Void) {
        handlers[action] = handler

        update(action)
    }

    func suspend() {
        isSuspended = true

        updateAll()
    }

    func resume() {
        isSuspended = false

        updateAll()
    }

    func settingsDidChange() {
        updateAll()
    }

    func combination(for action: ShortcutAction) -> KeyCombination? {
        guard !unavailable.contains(action) else { return nil }

        return settings.settings.shortcuts[action]
    }

    func title(for action: ShortcutAction) -> String? {
        guard let combination = combination(for: action) else { return nil }

        return combination.title(in: layout)
    }

    private func updateAll() {
        for action in ShortcutAction.allCases {
            update(action)
        }
    }

    private func update(_ action: ShortcutAction) {
        guard let handler = handlers[action] else { return }

        let wanted = wantedCombination(for: action)
        guard wanted != attempted[action] else { return }

        let shortcut = shortcuts[action]

        shortcut.unregister()
        attempted[action] = wanted

        guard let wanted else {
            if !isSuspended {
                unavailable.remove(action)
            }

            return
        }
        guard shortcut.register(wanted, action: handler) else {
            Logger.settings.error("Couldn't register the \(action.rawValue, privacy: .public) shortcut")
            unavailable.insert(action)

            return
        }

        unavailable.remove(action)
    }

    private func wantedCombination(for action: ShortcutAction) -> KeyCombination? {
        guard !isSuspended else { return nil }

        return settings.settings.shortcuts[action]
    }
}
