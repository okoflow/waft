import Foundation

extension PushToTalkKey {
    private struct ModifierName {
        let name: String
        let shortName: String
        let symbol: String
    }

    private static let modifierNames: [Int64: ModifierName] = [
        54: ModifierName(name: String(localized: "Right Command"), shortName: String(localized: "right ⌘"), symbol: "⌘"),
        55: ModifierName(name: String(localized: "Left Command"), shortName: String(localized: "left ⌘"), symbol: "⌘"),
        56: ModifierName(name: String(localized: "Left Shift"), shortName: String(localized: "left ⇧"), symbol: "⇧"),
        60: ModifierName(name: String(localized: "Right Shift"), shortName: String(localized: "right ⇧"), symbol: "⇧"),
        58: ModifierName(name: String(localized: "Left Option"), shortName: String(localized: "left ⌥"), symbol: "⌥"),
        61: ModifierName(name: String(localized: "Right Option"), shortName: String(localized: "right ⌥"), symbol: "⌥"),
        59: ModifierName(name: String(localized: "Left Control"), shortName: String(localized: "left ⌃"), symbol: "⌃"),
        62: ModifierName(name: String(localized: "Right Control"), shortName: String(localized: "right ⌃"), symbol: "⌃"),
        63: ModifierName(name: String(localized: "Fn"), shortName: "Fn", symbol: "🌐"),
    ]

    package var title: String {
        guard let modifier = Self.modifierNames[keyCode] else { return functionKeyTitle }

        return String(
            localized: "\(modifier.name) (\(modifier.symbol))",
            comment: "A key name and its symbol, such as Right Option (⌥)",
        )
    }

    package var shortTitle: String {
        guard let modifier = Self.modifierNames[keyCode] else { return functionKeyTitle }

        return modifier.shortName
    }

    private var functionKeyTitle: String {
        guard let title = FunctionKeys.title(forKeyCode: keyCode) else {
            return String(localized: "Key \(keyCode)", comment: "A key without a printable name in a keyboard shortcut")
        }

        return title
    }
}
