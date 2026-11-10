import Foundation

package struct PushToTalkKey: Hashable, Codable, RawRepresentable, Sendable {
    package static let function = PushToTalkKey(known: 63)

    package static let modifierKeys = modifierFlags.keys
        .filter { $0 != function.keyCode }
        .sorted()
        .map(PushToTalkKey.init(known:))

    static let rightOption = PushToTalkKey(known: 61)

    private static let modifierFlags: [Int64: UInt64] = [
        54: 0x10,
        55: 0x08,
        56: 0x02,
        60: 0x04,
        58: 0x20,
        61: 0x40,
        59: 0x01,
        62: 0x2000,
        63: 0x800000,
    ]

    package let keyCode: Int64

    package var rawValue: Int64 {
        keyCode
    }

    package var modifierFlag: UInt64? {
        Self.modifierFlags[keyCode]
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
        guard modifierFlags[keyCode] == nil else { return true }

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
        case .modifiersChanged:
            modifierEvent(for: keyEvent)
        case .keyDown:
            keyDownEvent(for: keyEvent)
        case .keyUp:
            isOwnFunctionKey(keyEvent) ? .keyUp : nil
        case .monitorDisabled:
            nil
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
