package struct RewriteRequest: Sendable {
    package enum Kind: Sendable {
        case cleanup(instructions: String, language: Language, target: Language?, vocabulary: [String])
        case custom(instructions: String, language: Language, vocabulary: [String])
        case edit(selection: String, language: Language)
        case text(TextTask, instructions: String)
    }

    package let text: String
    package let kind: Kind
    package let localServer: LocalServer?
    package let cloudModel: CloudModel?
    package let deadline: Duration

    package var outputTokenBudget: Int {
        switch kind {
        case .cleanup: min(4096, max(512, text.count * 2))
        case .custom: min(4096, max(1024, text.count * 4))
        case let .edit(selection, _): min(4096, max(1024, selection.count * 2))
        case .text: min(4096, max(1024, text.count * 3))
        }
    }

    package init(
        text: String,
        kind: Kind,
        localServer: LocalServer?,
        cloudModel: CloudModel?,
        deadline: Duration,
    ) {
        self.text = text
        self.kind = kind
        self.localServer = localServer
        self.cloudModel = cloudModel
        self.deadline = deadline
    }
}
