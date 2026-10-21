import Foundation
import Testing
@testable import WaftCore

struct TranslatorInstructionsTests {
    @Test(arguments: TextTask.Kind.allCases)
    func `falls back to the default instructions`(kind: TextTask.Kind) {
        let instructions = EditableInstructions<TextTask.Kind>()

        #expect(instructions.text(for: kind) == RewritePrompt.defaultTextInstructions(for: kind))
        #expect(instructions.editableText(for: kind) == RewritePrompt.defaultTextInstructions(for: kind))
        #expect(!instructions.isCustomized(kind))
    }

    @Test
    func `uses custom instructions for their task only`() {
        var instructions = EditableInstructions<TextTask.Kind>()
        instructions.set("Translate like a pirate.", for: .translate)

        #expect(instructions.text(for: .translate) == "Translate like a pirate.")
        #expect(instructions.isCustomized(.translate))
        #expect(instructions.text(for: .fix) == RewritePrompt.defaultTextInstructions(for: .fix))
    }

    @Test
    func `treats the default text as no customization`() {
        var instructions = EditableInstructions<TextTask.Kind>()
        instructions.set("Custom.", for: .fix)
        instructions.set(RewritePrompt.defaultTextInstructions(for: .fix), for: .fix)

        #expect(!instructions.isCustomized(.fix))
        #expect(instructions == EditableInstructions<TextTask.Kind>())
    }

    @Test
    func `keeps blank custom text editable but prompts with the default`() {
        var instructions = EditableInstructions<TextTask.Kind>()
        instructions.set("  \n", for: .translate)

        #expect(instructions.isCustomized(.translate))
        #expect(instructions.editableText(for: .translate) == "  \n")
        #expect(instructions.text(for: .translate) == RewritePrompt.defaultTextInstructions(for: .translate))
    }

    @Test
    func `resets a task to the default`() {
        var instructions = EditableInstructions<TextTask.Kind>()
        instructions.set("Custom.", for: .translate)

        instructions.reset(.translate)

        #expect(!instructions.isCustomized(.translate))
        #expect(instructions.text(for: .translate) == RewritePrompt.defaultTextInstructions(for: .translate))
    }

    @Test
    func `decodes the stored format`() throws {
        let json = #"{"custom":{"fix":"Fix only the typos."}}"#

        let instructions = try JSONDecoder().decode(EditableInstructions<TextTask.Kind>.self, from: Data(json.utf8))

        #expect(instructions.text(for: .fix) == "Fix only the typos.")
    }
}
