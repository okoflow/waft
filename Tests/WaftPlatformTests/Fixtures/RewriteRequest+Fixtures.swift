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
            kind: .cleanup(instructions: "Clean.", language: .english, target: target, vocabulary: []),
            localServer: localServer,
            cloudModel: cloudModel,
            deadline: .seconds(3),
        )
    }
}
