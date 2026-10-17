import Foundation
import os
import WaftCore

struct OpenAIAPI: RewriteAPI {
    private static let endpoint = URL(literal: "https://api.openai.com/v1/responses")

    let service = "OpenAI"
    let apiKeyStore: any ValueStore<String>

    private static func identifier(of model: CloudModel) -> String {
        switch model {
        case .fastest: "gpt-6-luna"
        case .balanced: "gpt-6.1-sol"
        case .smartest: "gpt-6-astra"
        }
    }

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<OpenAIRequest> {
        guard let model = request.cloudModel else { throw .unavailable }

        let headers = try ["authorization": "Bearer \(APIKey.load(from: apiKeyStore))"]
        let body = OpenAIRequest(
            model: Self.identifier(of: model),
            instructions: RewritePrompt.system(for: request),
            input: RewritePrompt.userMessage(for: request),
            maximumOutputTokens: request.outputTokenLimitWithThinking,
        )

        return APICall(url: Self.endpoint, headers: headers, body: body)
    }

    func answer(from data: Data) throws(RewriteError) -> String {
        let response = try decoded(OpenAIResponse.self, from: data)

        switch response.status {
        case "failed":
            logFailure(response.error)

            throw .serviceUnavailable

        case "incomplete":
            throw response.incompleteDetails?.reason == "content_filter" ? .refused : .truncated

        default:
            break
        }

        let content = response.output.filter { $0.type == "message" }.flatMap(\.content)
        guard !content.contains(where: { $0.type == "refusal" }) else { throw .refused }

        let text = content.filter { $0.type == "output_text" }.compactMap(\.text).joined()

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func logFailure(_ error: APIErrorBody.Detail?) {
        guard let error else {
            Logger.network.error("\(service, privacy: .public) failed the response without an error")

            return
        }

        Logger.network.error(
            """
            \(service, privacy: .public) failed the response: \
            \(error.kind, privacy: .public) \(error.redactedMessage, privacy: .private)
            """,
        )
    }
}

private struct OpenAIResponse: Decodable {
    struct IncompleteDetails: Decodable {
        let reason: String?
    }

    enum CodingKeys: String, CodingKey {
        case status
        case incompleteDetails = "incomplete_details"
        case error
        case output
    }

    let status: String?
    let incompleteDetails: IncompleteDetails?
    let error: APIErrorBody.Detail?
    let output: [OpenAIOutputItem]
}

private struct OpenAIOutputItem: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String?
    }

    enum CodingKeys: String, CodingKey {
        case type
        case content
    }

    let type: String
    let content: [Content]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(String.self, forKey: .type)
        content = container.decodeValidElements(.content)
    }
}
