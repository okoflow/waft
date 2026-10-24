import WaftCore

extension RewriteRequest {
    static func cleanup(
        _ text: String,
        target: Language? = nil,
        localServer: LocalServer? = nil,
        cloudModel: CloudModel? = .balanced,
    ) -> RewriteRequest {
        RewriteRequest(
            text: text,
            language: .english,
            kind: .cleanup(instructions: "Clean.", target: target),
            localServer: localServer,
            cloudModel: cloudModel,
            deadline: .seconds(3),
        )
    }
}
