import Foundation
import Testing
@testable import WaftCore

struct ModeInstructionsTests {
    @Test(arguments: Mode.allCases)
    func `falls back to the default instructions`(mode: Mode) {
        let instructions = ModeInstructions()

        #expect(instructions.text(for: mode) == RewritePrompt.defaultInstructions(for: mode))
        #expect(instructions.editableText(for: mode) == RewritePrompt.defaultInstructions(for: mode))
        #expect(!instructions.isCustomized(mode))
    }

    @Test
    func `uses custom instructions for their mode only`() {
        var instructions = ModeInstructions()
        instructions.set("Write like a pirate.", for: .formal)

        #expect(instructions.text(for: .formal) == "Write like a pirate.")
        #expect(instructions.isCustomized(.formal))
        #expect(instructions.text(for: .clean) == RewritePrompt.defaultInstructions(for: .clean))
    }

    @Test
    func `treats the default text as no customization`() {
        var instructions = ModeInstructions()
        instructions.set("Custom.", for: .clean)
        instructions.set(RewritePrompt.defaultInstructions(for: .clean), for: .clean)

        #expect(!instructions.isCustomized(.clean))
        #expect(instructions == ModeInstructions())
    }

    @Test
    func `keeps blank custom text editable but prompts with the default`() {
        var instructions = ModeInstructions()
        instructions.set("  \n", for: .translate)

        #expect(instructions.isCustomized(.translate))
        #expect(instructions.editableText(for: .translate) == "  \n")
        #expect(instructions.text(for: .translate) == RewritePrompt.defaultInstructions(for: .translate))
    }

    @Test
    func `resets a mode to the default`() {
        var instructions = ModeInstructions()
        instructions.set("Custom.", for: .clean)
        instructions.reset(.clean)

        #expect(!instructions.isCustomized(.clean))
        #expect(instructions.text(for: .clean) == RewritePrompt.defaultInstructions(for: .clean))
    }

    @Test
    func `survives an encoding round trip`() throws {
        var instructions = ModeInstructions()
        instructions.set("Custom.", for: .formal)
        let data = try JSONEncoder().encode(instructions)

        #expect(try JSONDecoder().decode(ModeInstructions.self, from: data) == instructions)
    }
}
