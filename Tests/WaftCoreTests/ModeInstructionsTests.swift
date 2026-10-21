import Foundation
import Testing
@testable import WaftCore

struct ModeInstructionsTests {
    @Test(arguments: Mode.builtIn)
    func `falls back to the default instructions`(mode: Mode) {
        let instructions = EditableInstructions<Mode>()

        #expect(instructions.text(for: mode) == RewritePrompt.defaultInstructions(for: mode))
        #expect(instructions.editableText(for: mode) == RewritePrompt.defaultInstructions(for: mode))
        #expect(!instructions.isCustomized(mode))
    }

    @Test
    func `uses custom instructions for their mode only`() {
        var instructions = EditableInstructions<Mode>()
        instructions.set("Write like a pirate.", for: .formal)

        #expect(instructions.text(for: .formal) == "Write like a pirate.")
        #expect(instructions.isCustomized(.formal))
        #expect(instructions.text(for: .clean) == RewritePrompt.defaultInstructions(for: .clean))
    }

    @Test
    func `treats the default text as no customization`() {
        var instructions = EditableInstructions<Mode>()
        instructions.set("Custom.", for: .clean)
        instructions.set(RewritePrompt.defaultInstructions(for: .clean), for: .clean)

        #expect(!instructions.isCustomized(.clean))
        #expect(instructions == EditableInstructions<Mode>())
    }

    @Test
    func `keeps blank custom text editable but prompts with the default`() {
        var instructions = EditableInstructions<Mode>()
        instructions.set("  \n", for: .translate)

        #expect(instructions.isCustomized(.translate))
        #expect(instructions.editableText(for: .translate) == "  \n")
        #expect(instructions.text(for: .translate) == RewritePrompt.defaultInstructions(for: .translate))
    }

    @Test
    func `resets a mode to the default`() {
        var instructions = EditableInstructions<Mode>()
        instructions.set("Custom.", for: .clean)

        instructions.reset(.clean)

        #expect(!instructions.isCustomized(.clean))
        #expect(instructions.text(for: .clean) == RewritePrompt.defaultInstructions(for: .clean))
    }

    @Test
    func `decodes the stored format`() throws {
        let json = #"{"custom":{"formal":"Write like a pirate."}}"#

        let instructions = try JSONDecoder().decode(EditableInstructions<Mode>.self, from: Data(json.utf8))

        #expect(instructions.text(for: .formal) == "Write like a pirate.")
    }
}
