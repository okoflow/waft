import WaftCore

extension RewriteRequest {
    static func cleanup(
        _ text: String,
        language: Language = .english,
        target: Language? = nil,
        instructions: String = "Clean.",
        localServer: LocalServer? = nil,
    ) -> RewriteRequest {
        RewriteRequest(
            text: text,
            language: language,
            kind: .cleanup(instructions: instructions, target: target),
            localServer: localServer,
            deadline: .seconds(3),
        )
    }
}
