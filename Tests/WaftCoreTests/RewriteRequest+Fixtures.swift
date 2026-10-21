import WaftCore

extension RewriteRequest {
    static func cleanup(
        _ text: String,
        language: Language = .english,
        target: Language? = nil,
        instructions: String = "Clean.",
    ) -> RewriteRequest {
        RewriteRequest(
            text: text,
            language: language,
            kind: .cleanup(instructions: instructions, target: target),
            localServer: nil,
            cloudModel: .balanced,
            deadline: .seconds(3),
        )
    }

    static func custom(_ text: String, language: Language = .english, instructions: String = "Reply.") -> RewriteRequest {
        RewriteRequest(
            text: text,
            language: language,
            kind: .custom(instructions: instructions),
            localServer: nil,
            cloudModel: .balanced,
            deadline: .seconds(3),
        )
    }

    static func edit(_ instruction: String, selection: String, language: Language = .english) -> RewriteRequest {
        RewriteRequest(
            text: instruction,
            language: language,
            kind: .edit(selection: selection),
            localServer: nil,
            cloudModel: .balanced,
            deadline: .seconds(20),
        )
    }

    static func text(_ text: String, task: TextTask, rephrases: Bool = false) -> RewriteRequest {
        RewriteRequest(
            text: text,
            language: .english,
            kind: .text(task, rephrases: rephrases),
            localServer: nil,
            cloudModel: .balanced,
            deadline: .seconds(20),
        )
    }
}
