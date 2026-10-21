import Foundation

package struct PushToTalkKey: Hashable, Codable, RawRepresentable, Sendable {
    private struct Modifier {
        let name: String
        let shortName: String
        let symbol: String
        let flag: UInt64
    }

    package static let function = PushToTalkKey(known: 63)

    static let rightOption = PushToTalkKey(known: 61)

    private static let modifiers: [Int64: Modifier] = [
        54: Modifier(name: String(localized: "Right Command"), shortName: String(localized: "right ⌘"), symbol: "⌘", flag: 0x10),
        55: Modifier(name: String(localized: "Left Command"), shortName: String(localized: "left ⌘"), symbol: "⌘", flag: 0x08),
        56: Modifier(name: String(localized: "Left Shift"), shortName: String(localized: "left ⇧"), symbol: "⇧", flag: 0x02),
        60: Modifier(name: String(localized: "Right Shift"), shortName: String(localized: "right ⇧"), symbol: "⇧", flag: 0x04),
        58: Modifier(name: String(localized: "Left Option"), shortName: String(localized: "left ⌥"), symbol: "⌥", flag: 0x20),
        61: Modifier(name: String(localized: "Right Option"), shortName: String(localized: "right ⌥"), symbol: "⌥", flag: 0x40),
        59: Modifier(name: String(localized: "Left Control"), shortName: String(localized: "left ⌃"), symbol: "⌃", flag: 0x01),
        62: Modifier(
            name: String(localized: "Right Control"),
            shortName: String(localized: "right ⌃"),
            symbol: "⌃",
            flag: 0x2000,
        ),
        63: Modifier(name: String(localized: "Fn"), shortName: "Fn", symbol: "🌐", flag: 0x800000),
    ]

    package let keyCode: Int64

    package var rawValue: Int64 {
        keyCode
    }

    package var modifierFlag: UInt64? {
        Self.modifiers[keyCode]?.flag
    }

    package var title: String {
        guard let modifier = Self.modifiers[keyCode] else { return functionKeyTitle }

        return String(
            localized: "\(modifier.name) (\(modifier.symbol))",
            comment: "A key name and its symbol, such as Right Option (⌥)",
        )
    }

    package var shortTitle: String {
        guard let modifier = Self.modifiers[keyCode] else { return functionKeyTitle }

        return modifier.shortName
    }

    private var functionKeyTitle: String {
        "F\(FunctionKeys.numbers[keyCode, default: 0])"
    }

    package init?(keyCode: Int64) {
        guard Self.isKnown(keyCode) else { return nil }

        self.keyCode = keyCode
    }

    package init?(rawValue keyCode: Int64) {
        self.init(keyCode: keyCode)
    }

    private init(known keyCode: Int64) {
        self.keyCode = keyCode
    }

    private static func isKnown(_ keyCode: Int64) -> Bool {
        guard modifiers[keyCode] == nil else { return true }

        return FunctionKeys.numbers[keyCode] != nil
    }

    package func isHeld(in flags: UInt64) -> Bool {
        guard let modifierFlag else { return false }

        return flags & modifierFlag != 0
    }

    package func isPressed(by keyEvent: KeyEvent) -> Bool {
        guard modifierFlag == nil else { return isHeld(in: keyEvent.flags) }
        guard keyEvent.kind == .keyDown else { return false }

        return keyEvent.keyCode == keyCode
    }

    func event(for keyEvent: KeyEvent) -> PushToTalk.Event? {
        guard !keyEvent.isRepeat else { return nil }

        return switch keyEvent.kind {
        case .monitorDisabled:
            .monitorDisabled
        case .modifiersChanged:
            modifierEvent(for: keyEvent)
        case .keyDown:
            keyDownEvent(for: keyEvent)
        case .keyUp:
            isOwnFunctionKey(keyEvent) ? .keyUp : nil
        }
    }

    private func keyDownEvent(for keyEvent: KeyEvent) -> PushToTalk.Event {
        guard !isOwnFunctionKey(keyEvent) else { return .keyDown }

        return keyEvent.isEscape ? .escapeDown : .otherKeyDown
    }

    private func modifierEvent(for keyEvent: KeyEvent) -> PushToTalk.Event? {
        guard let modifierFlag, keyEvent.keyCode == keyCode else { return nil }

        return keyEvent.flags & modifierFlag != 0 ? .keyDown : .keyUp
    }

    private func isOwnFunctionKey(_ keyEvent: KeyEvent) -> Bool {
        guard modifierFlag == nil else { return false }

        return keyEvent.keyCode == keyCode
    }
}
