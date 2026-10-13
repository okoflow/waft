package struct RewriteRequest: Sendable {
    package enum Kind: Sendable {
        case cleanup(instructions: String, target: Language?)
        case custom(instructions: String)
        case edit(selection: String)
    }

    package let text: String
    package let language: Language
    package let kind: Kind
    package let localServer: LocalServer?
    package let deadline: Duration

    package var outputTokenBudget: Int {
        switch kind {
        case .cleanup: min(4096, max(512, text.count * 2))
        case .custom: min(4096, max(1024, text.count * 4))
        case let .edit(selection): min(4096, max(1024, selection.count * 2))
        }
    }

    package init(text: String, language: Language, kind: Kind, localServer: LocalServer?, deadline: Duration) {
        self.text = text
        self.language = language
        self.kind = kind
        self.localServer = localServer
        self.deadline = deadline
    }
}
