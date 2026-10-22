import AppKit
import Observation
import WaftCore

@Observable
final class ShortcutRecorder {
    enum Rejection: Equatable {
        case needsModifier
        case taken(ShortcutConflict)
    }

    private static let modifierFlags: [(NSEvent.ModifierFlags, KeyCombination.Modifiers)] = [
        (.control, .control),
        (.option, .option),
        (.shift, .shift),
        (.command, .command),
    ]

    private(set) var action: ShortcutAction?
    private(set) var rejection: Rejection?
    private(set) var rejections: [ShortcutAction: Int] = [:]

    @ObservationIgnored private var monitor: Any?

    private let settings: SettingsModel
    private let shortcuts: GlobalShortcutController

    var isRecording: Bool {
        action != nil
    }

    init(settings: SettingsModel, shortcuts: GlobalShortcutController) {
        self.settings = settings
        self.shortcuts = shortcuts
    }

    private static func modifiers(of flags: NSEvent.ModifierFlags) -> KeyCombination.Modifiers {
        modifierFlags.reduce(into: []) { modifiers, pair in
            if flags.contains(pair.0) {
                modifiers.insert(pair.1)
            }
        }
    }

    func start(_ action: ShortcutAction) {
        stop()

        self.action = action
        rejection = nil
        shortcuts.suspend()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)

            return nil
        }
    }

    func stop() {
        guard isRecording else { return }

        if let monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = nil
        action = nil
        shortcuts.resume()
    }

    func isRecording(_ action: ShortcutAction) -> Bool {
        self.action == action
    }

    func clear(_ action: ShortcutAction) {
        stop()

        settings.settings.shortcuts[action] = nil
    }

    func reset(_ action: ShortcutAction) {
        stop()

        settings.settings.shortcuts.reset(action)
    }

    func handle(_ event: NSEvent) {
        guard let action, event.type == .keyDown else { return }
        guard !event.isEscape else {
            stop()

            return
        }

        let combination = KeyCombination(keyCode: Int64(event.keyCode), modifiers: Self.modifiers(of: event.modifierFlags))
        guard combination.hasRequiredModifier else {
            reject(.needsModifier, for: action)

            return
        }

        if let conflict = settings.settings.conflict(with: combination, recording: action) {
            reject(.taken(conflict), for: action)

            return
        }

        settings.settings.shortcuts[action] = combination
        stop()
    }

    private func reject(_ rejection: Rejection, for action: ShortcutAction) {
        self.rejection = rejection
        rejections[action, default: 0] += 1
    }
}
