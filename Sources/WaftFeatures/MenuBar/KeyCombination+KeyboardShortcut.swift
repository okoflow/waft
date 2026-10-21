import SwiftUI
import WaftCore

extension KeyCombination {
    private static let firstFunctionKey: UInt32 = 0xF704

    private static let keyEquivalents: [Int64: KeyEquivalent] = [
        36: .return,
        48: .tab,
        49: .space,
        51: .delete,
        71: .clear,
        115: .home,
        116: .pageUp,
        117: .deleteForward,
        119: .end,
        121: .pageDown,
        123: .leftArrow,
        124: .rightArrow,
        125: .downArrow,
        126: .upArrow,
    ]

    private var eventModifiers: EventModifiers {
        let pairs: [(Modifiers, EventModifiers)] = [
            (.control, .control),
            (.option, .option),
            (.shift, .shift),
            (.command, .command),
        ]

        return pairs.reduce(into: []) { result, pair in
            if modifiers.contains(pair.0) {
                result.insert(pair.1)
            }
        }
    }

    private static func isPrintable(_ character: Character) -> Bool {
        [character.isLetter, character.isNumber, character.isPunctuation, character.isSymbol].contains(true)
    }

    func keyboardShortcut(in layout: any KeyboardLayout) -> KeyboardShortcut? {
        guard let key = keyEquivalent(in: layout) else { return nil }

        return KeyboardShortcut(key, modifiers: eventModifiers)
    }

    private func keyEquivalent(in layout: any KeyboardLayout) -> KeyEquivalent? {
        if let key = Self.keyEquivalents[keyCode] {
            return key
        }

        if let number = functionKeyNumber, let scalar = Unicode.Scalar(Self.firstFunctionKey + UInt32(number - 1)) {
            return KeyEquivalent(Character(scalar))
        }

        guard let text = layout.character(forKeyCode: keyCode), text.count == 1, let character = text.first,
              Self.isPrintable(character) else { return nil }

        return KeyEquivalent(character)
    }
}
