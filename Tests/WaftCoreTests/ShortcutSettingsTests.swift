import Foundation
import Testing
import WaftCore

struct ShortcutSettingsTests {
    private static let controlOptionK = KeyCombination(keyCode: 40, modifiers: [.control, .option])

    @Test
    func `starts with the default combination of every action`() {
        let shortcuts = ShortcutSettings()

        for action in ShortcutAction.allCases {
            #expect(shortcuts[action] == action.defaultCombination)
        }
    }

    @Test
    func `decodes a cleared shortcut, keeps a stored one, and defaults the missing and broken ones`() throws {
        let json = #"{"translator":null,"modeCycle":{"keyCode":40,"modifiers":3},"fixSelection":{"keyCode":3,"modifiers":4}}"#

        let shortcuts = try JSONDecoder().decode(ShortcutSettings.self, from: Data(json.utf8))

        #expect(shortcuts[.translator] == nil)
        #expect(shortcuts[.modeCycle] == Self.controlOptionK)
        #expect(shortcuts[.translateSelection] == ShortcutAction.translateSelection.defaultCombination)
        #expect(shortcuts[.fixSelection] == ShortcutAction.fixSelection.defaultCombination)
    }

    @Test
    func `keeps a cleared shortcut through an encoding round trip`() throws {
        var shortcuts = ShortcutSettings()
        shortcuts[.translator] = nil
        shortcuts[.fixSelection] = Self.controlOptionK

        let data = try JSONEncoder().encode(shortcuts)

        #expect(try JSONDecoder().decode(ShortcutSettings.self, from: data) == shortcuts)
    }

    @Test
    func `finds the action that uses a combination`() {
        let shortcuts = ShortcutSettings()

        #expect(shortcuts.action(using: ShortcutAction.fixSelection.defaultCombination) == .fixSelection)
        #expect(shortcuts.action(using: Self.controlOptionK) == nil)
    }

    @Test
    func `resets a shortcut only to a default that no other shortcut uses`() {
        var shortcuts = ShortcutSettings()
        shortcuts[.fixSelection] = nil
        shortcuts[.translator] = ShortcutAction.fixSelection.defaultCombination

        #expect(!shortcuts.canReset(.fixSelection))
        #expect(!shortcuts.canReset(.modeCycle))
        #expect(shortcuts.canReset(.translator))

        shortcuts.reset(.fixSelection)

        #expect(shortcuts[.fixSelection] == nil)

        shortcuts.reset(.translator)
        shortcuts.reset(.fixSelection)

        #expect(shortcuts == ShortcutSettings())
    }
}
