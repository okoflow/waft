import WaftCore

extension RewriteRequest {
    static func cleanup(_ text: String, target: Language? = nil, localServer: LocalServer? = nil) -> RewriteRequest {
        RewriteRequest(
            text: text,
            language: .english,
            kind: .cleanup(instructions: "Clean.", target: target),
            localServer: localServer,
            deadline: .seconds(3),
        )
    }
}
