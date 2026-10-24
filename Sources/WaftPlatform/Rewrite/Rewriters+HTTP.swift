package import WaftCore
import Foundation

extension Rewriters {
    package static func http(apiKeys: PerProvider<any ValueStore<String>>) -> Rewriters {
        let session = URLSession(configuration: .ephemeral)

        return Rewriters(
            cloud: PerProvider(
                claude: HTTPRewriter(api: AnthropicAPI(apiKeyStore: apiKeys.claude), transport: session),
                openAI: HTTPRewriter(api: OpenAIAPI(apiKeyStore: apiKeys.openAI), transport: session),
            ),
            localServer: HTTPRewriter(api: ChatCompletionsAPI(), transport: session),
        )
    }
}
