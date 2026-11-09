import WaftCore

extension RewriteRequest {
    static func cleanup(
        _ text: String,
        language: Language = .english,
        target: Language? = nil,
        instructions: String = "Clean.",
        vocabulary: [String] = [],
    ) -> RewriteRequest {
        let kind = RewriteRequest.Kind.cleanup(
            instructions: instructions,
            language: language,
            target: target,
            vocabulary: vocabulary,
        )

        return fixture(text, kind: kind, deadline: .seconds(3))
    }

    static func custom(
        _ text: String,
        language: Language = .english,
        instructions: String = "Reply.",
        vocabulary: [String] = [],
    ) -> RewriteRequest {
        fixture(
            text,
            kind: .custom(instructions: instructions, language: language, vocabulary: vocabulary),
            deadline: .seconds(3),
        )
    }

    static func edit(_ instruction: String, selection: String, language: Language = .english) -> RewriteRequest {
        fixture(instruction, kind: .edit(selection: selection, language: language), deadline: .seconds(20))
    }

    static func text(_ text: String, task: TextTask, instructions: String = "Work on the text.") -> RewriteRequest {
        fixture(text, kind: .text(task, instructions: instructions), deadline: .seconds(20))
    }

    private static func fixture(_ text: String, kind: Kind, deadline: Duration) -> RewriteRequest {
        RewriteRequest(text: text, kind: kind, localServer: nil, cloudModel: .balanced, deadline: deadline)
    }
}
