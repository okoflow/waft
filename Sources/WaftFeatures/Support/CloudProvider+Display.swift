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

    func name(of model: CloudModel) -> String {
        switch (self, model) {
        case (.claude, .fastest): "Haiku 5.5"
        case (.claude, .balanced): "Sonnet 5.5"
        case (.claude, .smartest): "Opus 5.5"
        case (.openAI, .fastest): "GPT-6 Luna"
        case (.openAI, .balanced): "GPT-6.1 Sol"
        case (.openAI, .smartest): "GPT-6 Astra"
        }
    }
}
