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
            deadline: .seconds(3),
        )
    }

    static func edit(_ instruction: String, selection: String, language: Language = .english) -> RewriteRequest {
        RewriteRequest(
            text: instruction,
            language: language,
            kind: .edit(selection: selection),
            localServer: nil,
            deadline: .seconds(20),
        )
    }
}
