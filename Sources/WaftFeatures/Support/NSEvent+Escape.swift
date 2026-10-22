import AppKit

extension NSEvent {
    private static let escapeKeyCode: UInt16 = 53
    private static let shortcutModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    var isEscape: Bool {
        keyCode == Self.escapeKeyCode
    }

    var isPlainEscape: Bool {
        guard isEscape else { return false }

        return modifierFlags.isDisjoint(with: Self.shortcutModifiers)
    }
}
