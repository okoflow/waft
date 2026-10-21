import WaftCore

extension RewriteRequest {
    static func cleanup(
        _ text: String,
        language: Language = .english,
        target: Language? = nil,
        instructions: String = "Clean.",
    ) -> RewriteRequest {
        fixture(text, language: language, kind: .cleanup(instructions: instructions, target: target), deadline: .seconds(3))
    }

    static func custom(_ text: String, language: Language = .english, instructions: String = "Reply.") -> RewriteRequest {
        fixture(text, language: language, kind: .custom(instructions: instructions), deadline: .seconds(3))
    }

    static func edit(_ instruction: String, selection: String, language: Language = .english) -> RewriteRequest {
        fixture(instruction, language: language, kind: .edit(selection: selection), deadline: .seconds(20))
    }

    static func text(_ text: String, task: TextTask, instructions: String = "Work on the text.") -> RewriteRequest {
        fixture(text, language: .english, kind: .text(task, instructions: instructions), deadline: .seconds(20))
    }

    private static func fixture(_ text: String, language: Language, kind: Kind, deadline: Duration) -> RewriteRequest {
        RewriteRequest(text: text, language: language, kind: kind, localServer: nil, cloudModel: .balanced, deadline: deadline)
    }
}
