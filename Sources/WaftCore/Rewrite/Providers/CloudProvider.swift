package enum CloudProvider: String, CaseIterable, Sendable {
    case claude
    case openAI = "openai"

    package var title: String {
        switch self {
        case .claude: "Claude"
        case .openAI: "OpenAI"
        }
    }
}
