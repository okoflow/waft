import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct ChatCompletionsAPITests {
    private static let api = ChatCompletionsAPI()
    private static let server = LocalServer(baseURL: "http://localhost:1234/v1/", model: "qwen")
    private static let answer = Data(#"{"choices":[{"message":{"content":"Hello."},"finish_reason":"stop"}]}"#.utf8)

    private static func jsonBody(of request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)

        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test(arguments: [LocalServer?.none, LocalServer(model: ""), LocalServer(baseURL: "", model: "qwen")])
    func `needs a configured local server`(server: LocalServer?) {
        #expect(throws: RewriteError.unavailable) {
            try Self.api.call(for: .cleanup("hello", localServer: server))
        }
    }

    @Test
    func `calls the chat completions endpoint of the server`() throws {
        let call = try Self.api.call(for: .cleanup("hello", localServer: Self.server))

        #expect(call.url.absoluteString == "http://localhost:1234/v1/chat/completions")
        #expect(call.headers.isEmpty)
    }

    @Test
    func `sends the prompt to the model of the server`() throws {
        let request = RewriteRequest.cleanup("hello", localServer: Self.server)
        let body = try Self.api.call(for: request).body.jsonObject()
        let messages = try #require(body["messages"] as? [[String: String]])

        #expect(body["model"] as? String == "qwen")
        #expect(body["temperature"] as? Double == 0.2)
        #expect(body["stream"] as? Bool == false)
        #expect(body["max_tokens"] as? Int == request.outputTokenBudget + 4096)
        #expect(messages == [
            ["role": "system", "content": RewritePrompt.system(for: request)],
            ["role": "user", "content": RewritePrompt.userMessage(for: request)],
        ])
    }

    @Test
    func `sends the request again with the plain token budget when the server answers 400`() async throws {
        let request = RewriteRequest.cleanup("hello", localServer: Self.server)
        let transport = FakeHTTPTransport(.status(400), .status(200, body: Self.answer))
        let rewriter = HTTPRewriter(api: Self.api, transport: transport)

        let answer = try await rewriter.rewrite(request)

        let bodies = try transport.requests.map(Self.jsonBody)
        let otherFields = Set(bodies.map { NSDictionary(dictionary: $0.filter { $0.key != "max_tokens" }) })

        #expect(answer == "Hello.")
        #expect(Set(transport.requests.map(\.url?.absoluteString)) == ["http://localhost:1234/v1/chat/completions"])
        #expect(bodies.map { $0["max_tokens"] as? Int } == [request.outputTokenBudget + 4096, request.outputTokenBudget])
        #expect(otherFields.count == 1)
    }

    @Test
    func `fails when the server answers 400 to the plain token budget too`() async {
        let transport = FakeHTTPTransport(.status(400))
        let rewriter = HTTPRewriter(api: Self.api, transport: transport)

        await #expect(throws: RewriteError.serviceUnavailable) {
            try await rewriter.rewrite(.cleanup("hello", localServer: Self.server))
        }

        #expect(transport.requests.count == 2)
    }

    @Test
    func `sends the request once when the server fails with another status`() async {
        let transport = FakeHTTPTransport(.status(500), .status(200, body: Self.answer))
        let rewriter = HTTPRewriter(api: Self.api, transport: transport)

        await #expect(throws: RewriteError.serviceUnavailable) {
            try await rewriter.rewrite(.cleanup("hello", localServer: Self.server))
        }

        #expect(transport.requests.count == 1)
    }

    @Test
    func `sends the request once when the server answers`() async throws {
        let transport = FakeHTTPTransport(.status(200, body: Self.answer), .status(400))
        let rewriter = HTTPRewriter(api: Self.api, transport: transport)

        #expect(try await rewriter.rewrite(.cleanup("hello", localServer: Self.server)) == "Hello.")
        #expect(transport.requests.count == 1)
    }

    @Test(arguments: [
        (#"{"choices":[{"message":{"content":"Hello."},"finish_reason":"stop"}]}"#, "Hello."),
        (#"{"choices":[{"message":{"content":"<think>The user wants...</think>\nHello."}}]}"#, "\nHello."),
        (#"{"choices":[{"message":{"content":"<think>\nline one\nline two\n</think>Hi <think>x</think>there."}}]}"#, "Hi there."),
        (#"{"choices":[{"message":{"content":"The user wants a clean version.\n</think>\n\nHello."}}]}"#, "\n\nHello."),
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
