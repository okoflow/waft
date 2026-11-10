import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct KeyCombinationKeyboardShortcutTests {
    @Test(arguments: [
        (KeyCombination(keyCode: 17, modifiers: [.control, .option]), Character("t"), EventModifiers([.control, .option])),
        (
            KeyCombination(keyCode: 126, modifiers: [.command, .shift]),
            KeyEquivalent.upArrow.character,
            EventModifiers([.command, .shift]),
        ),
        (KeyCombination(keyCode: 96, modifiers: []), Character("\u{F708}"), EventModifiers()),
    ])
    func `turns a combination into the menu's key equivalent`(
        combination: KeyCombination,
        character: Character,
        modifiers: EventModifiers,
    ) throws {
        let shortcut = try #require(combination.keyboardShortcut(in: FakeKeyboardLayout()))

        #expect(shortcut.key.character == character)
        #expect(shortcut.modifiers == modifiers)
    }

    @Test(arguments: [[Int64: String](), [17: "\u{10}"]])
    func `has no key equivalent for a key the layout does not type`(characters: [Int64: String]) {
        let combination = KeyCombination(keyCode: 17, modifiers: [.control, .option])

        #expect(combination.keyboardShortcut(in: FakeKeyboardLayout(characters)) == nil)
    }
}
