import AppKit
import WaftCore

extension NSEvent {
    private static let shortcutModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    var isEscape: Bool {
        Int64(keyCode) == KeyEvent.escapeKeyCode
    }

    var isPlainEscape: Bool {
        guard isEscape else { return false }

        return modifierFlags.isDisjoint(with: Self.shortcutModifiers)
    }
}
