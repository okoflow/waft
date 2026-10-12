import Foundation
import WaftCore

extension CloudProvider {
    var company: String {
        switch self {
        case .claude: "Anthropic"
        case .openAI: "OpenAI"
        }
    }

    var consoleURL: URL {
        switch self {
        case .claude: URL(literal: "https://console.anthropic.com/settings/keys")
        case .openAI: URL(literal: "https://platform.openai.com/settings/organization/api-keys")
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .claude: "sk-ant-…"
        case .openAI: "sk-proj-…"
        }
    }
}
