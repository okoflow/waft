import Testing
@testable import WaftCore

struct RewritePromptTests {
    @Test
    func `puts the transcript between tags with the spoken language`() {
        let request = RewriteRequest.cleanup("um hello there", language: .german)
        let expected = "Spoken language: German.\n<transcript>\num hello there\n</transcript>"

        #expect(RewritePrompt.userMessage(for: request) == expected)
    }

    @Test(arguments: [(Language.english, "American English"), (.russian, "Russian"), (.japanese, "Japanese")])
    func `names the translation target`(target: Language, name: String) {
        let request = RewriteRequest.cleanup("hola", language: .spanish, target: target)
        let expected = "Spoken language: Spanish.\nTranslate into: \(name).\n<transcript>\nhola\n</transcript>"

        #expect(RewritePrompt.userMessage(for: request) == expected)
    }

    @Test
    func `gives an edit the instruction and the selected text`() {
        let request = RewriteRequest.edit("сделай короче", selection: "A long text.", language: .russian)
        let expected = "Spoken language: Russian.\n<instruction>\nсделай короче\n</instruction>\n<text>\nA long text.\n</text>"

        #expect(RewritePrompt.userMessage(for: request) == expected)
    }

    @Test
    func `starts the cleanup system prompt with the mode instructions`() {
        let system = RewritePrompt.system(for: .cleanup("hi", instructions: "Be brief."))

        #expect(system.hasPrefix("Be brief.\n"))
        #expect(system.contains("<transcript> tags"))
        #expect(!system.contains("<instruction>"))
    }

    @Test
    func `uses the edit system prompt for edits`() {
        let system = RewritePrompt.system(for: .edit("shorter", selection: "Text."))

        #expect(system.contains("<instruction> tags"))
        #expect(!system.contains("<transcript>"))
    }

    @Test
    func `shares the clean instructions among the offline modes`() {
        let clean = RewritePrompt.defaultInstructions(for: .clean)

        #expect(RewritePrompt.defaultInstructions(for: .raw) == clean)
        #expect(RewritePrompt.defaultInstructions(for: .light) == clean)
        #expect(RewritePrompt.defaultInstructions(for: .formal) != clean)
        #expect(RewritePrompt.defaultInstructions(for: .translate).contains("You translate"))
    }
}
