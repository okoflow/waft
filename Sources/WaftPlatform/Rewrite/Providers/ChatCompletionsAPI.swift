import Foundation
import WaftCore

struct ChatCompletionsAPI: RewriteAPI {
    private static let reasoningPattern = #"<think>[\s\S]*?</think>|^(?:(?!<think>)[\s\S])*?</think>"#

    let service = "The local server"

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<ChatCompletionsRequest> {
        guard let server = request.localServer, server.isConfigured else { throw .unavailable }

        let body = ChatCompletionsRequest(
            model: server.model,
            messages: [.system(RewritePrompt.system(for: request)), .user(RewritePrompt.userMessage(for: request))],
            maximumTokens: request.outputTokenBudget,
        )

        return try APICall(url: server.url(appending: "/chat/completions"), headers: [:], body: body)
    }

    func answer(from data: Data) throws(RewriteError) -> String {
        guard let choice = try decoded(ChatCompletionsResponse.self, from: data).choices.first else { throw .unreadableResponse }

        switch choice.finishReason {
        case "length": throw .truncated
        case "content_filter": throw .refused
        default: break
        }

        guard let content = choice.message.content else { throw .unreadableResponse }

        let answer = content.replacingOccurrences(of: Self.reasoningPattern, with: "", options: .regularExpression)

        return answer.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChatCompletionsResponse: Decodable {
    let choices: [ChatCompletionChoice]
}

private struct ChatCompletionChoice: Decodable {
    struct Message: Decodable {
        let content: String?
    }

    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }

    let message: Message
    let finishReason: String?
}
