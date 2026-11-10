import Foundation
import os
import WaftCore

struct ChatCompletionsAPI: RewriteAPI {
    private static let reasoningPattern = #"<think>[\s\S]*?</think>|^(?:(?!<think>)[\s\S])*?</think>"#

    let service = "The local server"

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<ChatCompletionsRequest> {
        try call(for: request, maximumTokens: request.outputTokenLimitWithThinking)
    }

    func call(for request: RewriteRequest, afterStatus status: Int) throws(RewriteError) -> APICall<ChatCompletionsRequest>? {
        guard status == 400 else { return nil }

        Logger.network.notice("\(service, privacy: .public) answered HTTP 400; asking again with the plain token limit")

        return try call(for: request, maximumTokens: request.outputTokenBudget)
    }

    func answer(from data: Data) throws(RewriteError) -> String {
        guard let choice = try decoded(ChatCompletionsResponse.self, from: data).choices.first else { throw .unreadableResponse }

        switch choice.finishReason {
        case "length": throw .truncated
        case "content_filter": throw .refused
        default: break
        }

        guard let content = choice.message.content else { throw .unreadableResponse }

        return content.replacingOccurrences(of: Self.reasoningPattern, with: "", options: .regularExpression)
    }

    private func call(for request: RewriteRequest, maximumTokens: Int) throws(RewriteError) -> APICall<ChatCompletionsRequest> {
        guard let server = request.localServer, server.isConfigured else { throw .unavailable }

        let body = ChatCompletionsRequest(
            model: server.model,
            messages: [.system(RewritePrompt.system(for: request)), .user(RewritePrompt.userMessage(for: request))],
            maximumTokens: maximumTokens,
        )

        return try APICall(url: server.url(appending: "/chat/completions"), headers: [:], body: body)
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
