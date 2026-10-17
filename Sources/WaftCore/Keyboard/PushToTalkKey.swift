import Foundation

package struct PushToTalkKey: Hashable, Sendable {
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

    private static let functionKeys: [Int64: Int] = [
        122: 1,
        120: 2,
        99: 3,
        118: 4,
        96: 5,
        97: 6,
        98: 7,
        100: 8,
        101: 9,
        109: 10,
        103: 11,
        111: 12,
        105: 13,
        107: 14,
        113: 15,
        106: 16,
        64: 17,
        79: 18,
        80: 19,
        90: 20,
    ]

    package let keyCode: Int64

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
        "F\(Self.functionKeys[keyCode, default: 0])"
    }

    package init?(keyCode: Int64) {
        guard Self.modifiers[keyCode] != nil || Self.functionKeys[keyCode] != nil else { return nil }

        self.keyCode = keyCode
    }

    private init(known keyCode: Int64) {
        self.keyCode = keyCode
    }

    package func event(for keyEvent: KeyEvent) -> PushToTalk.Event? {
        guard !keyEvent.isRepeat else { return nil }

        return switch keyEvent.kind {
        case .monitorDisabled:
            .monitorDisabled
        case .modifiersChanged:
            modifierEvent(for: keyEvent)
        case .keyDown:
            isOwnFunctionKey(keyEvent) ? .keyDown : .otherKeyDown
        case .keyUp:
            isOwnFunctionKey(keyEvent) ? .keyUp : nil
        }
    }

    package func isHeld(in flags: UInt64) -> Bool {
        guard let modifierFlag else { return false }

        return flags & modifierFlag != 0
    }

    package func isPressed(by keyEvent: KeyEvent) -> Bool {
        guard modifierFlag == nil else { return isHeld(in: keyEvent.flags) }

        return keyEvent.kind == .keyDown && keyEvent.keyCode == keyCode
    }

    private func modifierEvent(for keyEvent: KeyEvent) -> PushToTalk.Event? {
        guard let modifierFlag, keyEvent.keyCode == keyCode else { return nil }

        return keyEvent.flags & modifierFlag != 0 ? .keyDown : .keyUp
    }

    private func isOwnFunctionKey(_ keyEvent: KeyEvent) -> Bool {
        modifierFlag == nil && keyEvent.keyCode == keyCode
    }
}

extension PushToTalkKey: Codable {
    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let keyCode = try container.decode(Int64.self)
        guard let key = PushToTalkKey(keyCode: keyCode) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported key code \(keyCode)")
        }

        self = key
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyCode)
    }
}
