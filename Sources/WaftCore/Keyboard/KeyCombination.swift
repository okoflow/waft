import Foundation

package struct KeyCombination: Hashable, Sendable {
    package struct Modifiers: OptionSet, Hashable, Sendable {
        package static let control = Modifiers(rawValue: 1 << 0)
        package static let option = Modifiers(rawValue: 1 << 1)
        package static let shift = Modifiers(rawValue: 1 << 2)
        package static let command = Modifiers(rawValue: 1 << 3)

        static let all: Modifiers = [.control, .option, .shift, .command]
        static let required: Modifiers = [.control, .option, .command]

        package let rawValue: Int

        package init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    private static let symbols: [(Modifiers, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
    private static let highestKeyCode: Int64 = 127

    private static let keyNames: [Int64: String] = [
        36: "↩",
        48: "⇥",
        51: "⌫",
        71: "⌧",
        76: "⌤",
        115: "↖",
        116: "⇞",
        117: "⌦",
        119: "↘",
        121: "⇟",
        123: "←",
        124: "→",
        125: "↓",
        126: "↑",
    ]

    package let keyCode: Int64
    package let modifiers: Modifiers

    package var functionKeyNumber: Int? {
        FunctionKeys.numbers[keyCode]
    }

    package var hasRequiredModifier: Bool {
        guard functionKeyNumber == nil else { return true }

        return !modifiers.isDisjoint(with: Modifiers.required)
    }

    package var modifierSymbols: String {
        Self.symbols.filter { modifiers.contains($0.0) }.map(\.1).joined()
    }

    var fixedKeyName: String? {
        if let number = functionKeyNumber {
            return "F\(number)"
        }

        if keyCode == 49 {
            return String(localized: "Space", comment: "The name of the space bar in a keyboard shortcut")
        }

        return Self.keyNames[keyCode]
    }

    package init(keyCode: Int64, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    @MainActor
    package func title(in layout: any KeyboardLayout) -> String {
        "\(modifierSymbols)\(keyName(in: layout))"
    }

    @MainActor
    private func keyName(in layout: any KeyboardLayout) -> String {
        if let fixedKeyName {
            return fixedKeyName
        }

        guard let character = layout.character(forKeyCode: keyCode), !character.isBlank else {
            return String(localized: "Key \(keyCode)", comment: "A key without a printable name in a keyboard shortcut")
        }

        return character.uppercased()
    }
}

extension KeyCombination: Codable {
    private enum CodingKeys: String, CodingKey {
        case keyCode
        case modifiers
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let keyCode = try container.decode(Int64.self, forKey: .keyCode)
        let modifiers = try Modifiers(rawValue: container.decode(Int.self, forKey: .modifiers))

        let combination = KeyCombination(keyCode: keyCode, modifiers: modifiers)

        guard (0 ... Self.highestKeyCode).contains(keyCode),
              Modifiers.all.isSuperset(of: modifiers),
              combination.hasRequiredModifier
        else {
            throw DecodingError.dataCorruptedError(forKey: .keyCode, in: container, debugDescription: "Unsupported shortcut")
        }

        self = combination
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifiers.rawValue, forKey: .modifiers)
    }
}
