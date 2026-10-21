import Foundation
import Testing
import WaftCore

struct KeyCombinationTests {
    @Test(arguments: [
        (KeyCombination(keyCode: 17, modifiers: [.command, .shift, .option, .control]), "⌃⌥⇧⌘T"),
        (KeyCombination(keyCode: 6, modifiers: [.option]), "⌥Y"),
        (KeyCombination(keyCode: 96, modifiers: []), "F5"),
        (KeyCombination(keyCode: 49, modifiers: [.control]), "⌃Space"),
        (KeyCombination(keyCode: 126, modifiers: [.command]), "⌘↑"),
        (KeyCombination(keyCode: 36, modifiers: [.command, .shift]), "⇧⌘↩"),
    ])
    @MainActor
    func `names the modifiers in macOS order and the key from the layout`(combination: KeyCombination, title: String) {
        let layout = FakeKeyboardLayout([6: "y", 17: "t"])

        #expect(combination.title(in: layout) == title)
    }

    @Test
    @MainActor
    func `falls back to the key code for a key the layout does not type`() {
        let combination = KeyCombination(keyCode: 10, modifiers: [.control])

        #expect(combination.title(in: FakeKeyboardLayout([10: " "])) == "⌃Key 10")
    }

    @Test(arguments: [
        (KeyCombination(keyCode: 17, modifiers: .control), true),
        (KeyCombination(keyCode: 17, modifiers: .option), true),
        (KeyCombination(keyCode: 17, modifiers: .command), true),
        (KeyCombination(keyCode: 17, modifiers: .shift), false),
        (KeyCombination(keyCode: 17, modifiers: []), false),
        (KeyCombination(keyCode: 96, modifiers: []), true),
        (KeyCombination(keyCode: 122, modifiers: .shift), true),
    ])
    func `requires Command, Control, or Option unless the key is a function key`(
        combination: KeyCombination,
        isAllowed: Bool,
    ) {
        #expect(combination.hasRequiredModifier == isAllowed)
    }

    @Test(arguments: [
        #"{"keyCode":17,"modifiers":4}"#,
        #"{"keyCode":200,"modifiers":3}"#,
        #"{"keyCode":17,"modifiers":64}"#,
        #"{"keyCode":17}"#,
    ])
    func `rejects a stored combination that it cannot register`(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(KeyCombination.self, from: Data(json.utf8))
        }
    }

    @Test
    func `survives an encoding round trip`() throws {
        let combination = KeyCombination(keyCode: 3, modifiers: [.control, .shift, .command])
        let data = try JSONEncoder().encode(combination)

        #expect(try JSONDecoder().decode(KeyCombination.self, from: data) == combination)
    }
}
