import Foundation
import Testing
@testable import WaftCore

struct EditableInstructionsTests {
    @Test(arguments: Mode.builtIn)
    func `falls back to the default instructions of a mode`(mode: Mode) {
        let instructions = EditableInstructions<Mode>()

        #expect(instructions.text(for: mode) == RewritePrompt.defaultInstructions(for: mode))
        #expect(instructions.editableText(for: mode) == RewritePrompt.defaultInstructions(for: mode))
        #expect(!instructions.isCustomized(mode))
    }

    @Test(arguments: TextTask.Kind.allCases)
    func `falls back to the default instructions of a text task`(kind: TextTask.Kind) {
        let instructions = EditableInstructions<TextTask.Kind>()

        #expect(instructions.text(for: kind) == RewritePrompt.defaultTextInstructions(for: kind))
        #expect(instructions.editableText(for: kind) == RewritePrompt.defaultTextInstructions(for: kind))
        #expect(!instructions.isCustomized(kind))
    }

    @Test
    func `uses custom instructions for their subject only`() {
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
    func `resets a subject to the default`() {
        var instructions = EditableInstructions<Mode>()
        instructions.set("Custom.", for: .clean)

        instructions.reset(.clean)

        #expect(!instructions.isCustomized(.clean))
        #expect(instructions.text(for: .clean) == RewritePrompt.defaultInstructions(for: .clean))
    }

    @Test
    func `decodes the stored instructions of modes and text tasks`() throws {
        let modes = Data(#"{"custom":{"formal":"Write like a pirate."}}"#.utf8)
        let textTasks = Data(#"{"custom":{"fix":"Fix only the typos."}}"#.utf8)

        let modeInstructions = try JSONDecoder().decode(EditableInstructions<Mode>.self, from: modes)
        let textTaskInstructions = try JSONDecoder().decode(EditableInstructions<TextTask.Kind>.self, from: textTasks)

        #expect(modeInstructions.text(for: .formal) == "Write like a pirate.")
        #expect(textTaskInstructions.text(for: .fix) == "Fix only the typos.")
    }
}
