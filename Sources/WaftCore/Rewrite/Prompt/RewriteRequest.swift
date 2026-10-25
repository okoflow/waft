package struct RewriteRequest: Sendable {
    package enum Kind: Sendable {
        case cleanup(instructions: String, target: Language?, vocabulary: [String])
        case custom(instructions: String, vocabulary: [String])
        case edit(selection: String)
        case text(TextTask, instructions: String)
    }

    package let text: String
    package let language: Language
    package let kind: Kind
    package let localServer: LocalServer?
    package let cloudModel: CloudModel?
    package let deadline: Duration

    package var outputTokenBudget: Int {
        switch kind {
        case .cleanup: min(4096, max(512, text.count * 2))
        case .custom: min(4096, max(1024, text.count * 4))
        case let .edit(selection): min(4096, max(1024, selection.count * 2))
        case .text: min(4096, max(1024, text.count * 3))
        }
    }

    package init(
        text: String,
        language: Language,
        kind: Kind,
        localServer: LocalServer?,
        cloudModel: CloudModel?,
        deadline: Duration,
    ) {
        self.text = text
        self.language = language
        self.kind = kind
        self.localServer = localServer
        self.cloudModel = cloudModel
        self.deadline = deadline
    }
}
