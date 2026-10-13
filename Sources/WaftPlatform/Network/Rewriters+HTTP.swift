package import WaftCore
import Foundation

extension Rewriters {
    package static func http(apiKeys: PerProvider<any ValueStore<String>>) -> Rewriters {
        let session = URLSession(configuration: .ephemeral)

        return Rewriters(
            cloud: PerProvider(
                claude: HTTPRewriter(api: AnthropicAPI(apiKeyStore: apiKeys.claude), session: session),
                openAI: HTTPRewriter(api: OpenAIAPI(apiKeyStore: apiKeys.openAI), session: session),
            ),
            localServer: HTTPRewriter(api: ChatCompletionsAPI(), session: session),
        )
    }
}
