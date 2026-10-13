import Foundation
import WaftCore

struct AnthropicAPI: RewriteAPI {
    private static let endpoint = URL(literal: "https://api.anthropic.com/v1/messages")
    private static let apiVersion = "2023-06-01"
    private static let model = "claude-haiku-5-5"

    let service = "Claude"
    let apiKeyStore: any ValueStore<String>

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<AnthropicRequest> {
        let headers = try ["x-api-key": APIKey.load(from: apiKeyStore), "anthropic-version": Self.apiVersion]
        let body = AnthropicRequest(
            model: Self.model,
            maximumTokens: request.outputTokenLimitWithThinking,
            system: RewritePrompt.system(for: request),
            messages: [.user(RewritePrompt.userMessage(for: request))],
        )

        return APICall(url: Self.endpoint, headers: headers, body: body)
    }

    func answer(from data: Data) throws(RewriteError) -> String {
        let response = try decoded(AnthropicResponse.self, from: data)

        switch response.stopReason {
        case "max_tokens": throw .truncated
        case "refusal": throw .refused
        default: break
        }

        let text = response.content.filter { $0.type == "text" }.compactMap(\.text).joined()

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct AnthropicResponse: Decodable {
    struct Block: Decodable {
        let type: String
        let text: String?
    }

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }

    let content: [Block]
    let stopReason: String?
}
