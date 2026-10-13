import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct ChatCompletionsAPITests {
    private static let api = ChatCompletionsAPI()

    @Test(arguments: [LocalServer?.none, LocalServer(model: ""), LocalServer(baseURL: "", model: "qwen")])
    func `needs a configured local server`(server: LocalServer?) {
        #expect(throws: RewriteError.unavailable) {
            try Self.api.call(for: .cleanup("hello", localServer: server))
        }
    }

    @Test
    func `calls the chat completions endpoint of the server`() throws {
        let request = RewriteRequest.cleanup(
            "hello",
            localServer: LocalServer(baseURL: "http://localhost:1234/v1/", model: "qwen"),
        )
        let call = try Self.api.call(for: request)
        let body = try call.body.jsonObject()
        let messages = try #require(body["messages"] as? [[String: String]])

        #expect(call.url.absoluteString == "http://localhost:1234/v1/chat/completions")
        #expect(call.headers.isEmpty)
        #expect(body["model"] as? String == "qwen")
        #expect(body["temperature"] as? Double == 0.2)
        #expect(body["stream"] as? Bool == false)
        #expect(body["max_tokens"] as? Int == request.outputTokenBudget)
        #expect(messages == [
            ["role": "system", "content": RewritePrompt.system(for: request)],
            ["role": "user", "content": RewritePrompt.userMessage(for: request)],
        ])
    }

    @Test(arguments: [
        (#"{"choices":[{"message":{"content":"  Hello.\n"},"finish_reason":"stop"}]}"#, "Hello."),
        (#"{"choices":[{"message":{"content":"<think>The user wants...</think>\nHello."}}]}"#, "Hello."),
        (#"{"choices":[{"message":{"content":"<think>\nline one\nline two\n</think>Hi <think>x</think>there."}}]}"#, "Hi there."),
        (#"{"choices":[{"message":{"content":"Keep <thinking> tags."}}]}"#, "Keep <thinking> tags."),
    ])
    func `reads the message and drops reasoning`(json: String, expected: String) throws {
        #expect(try Self.api.answer(from: Data(json.utf8)) == expected)
    }

    @Test(arguments: [
        (#"{"choices":[{"message":{"content":"See you"},"finish_reason":"length"}]}"#, RewriteError.truncated),
        (#"{"choices":[{"message":{"content":""},"finish_reason":"content_filter"}]}"#, .refused),
        (#"{"choices":[]}"#, .unreadableResponse),
        (#"{"choices":[{"message":{"content":null},"finish_reason":"stop"}]}"#, .unreadableResponse),
        (#"{"error":"model not loaded"}"#, .unreadableResponse),
    ])
    func `rejects unusable answers`(json: String, error: RewriteError) {
        #expect(throws: error) {
            try Self.api.answer(from: Data(json.utf8))
        }
    }
}
