import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct AnthropicAPITests {
    private static let api = AnthropicAPI(apiKeyStore: FakeValueStore("sk-ant-test"))

    @Test
    func `calls the messages endpoint with the key and version`() throws {
        let call = try Self.api.call(for: .cleanup("um hello"))

        #expect(call.url.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(call.headers == ["x-api-key": "sk-ant-test", "anthropic-version": "2023-06-01"])
    }

    @Test
    func `sends the prompt without thinking`() throws {
        let request = RewriteRequest.cleanup("um hello", target: .german)
        let body = try Self.api.call(for: request).body.jsonObject()
        let messages = try #require(body["messages"] as? [[String: String]])
        let model = try #require(body["model"] as? String)

        #expect(model.hasPrefix("claude-"))
        #expect(body["max_tokens"] as? Int == request.outputTokenBudget)
        #expect((body["thinking"] as? [String: String])?["type"] == "disabled")
        #expect(body["system"] as? String == RewritePrompt.system(for: request))
        #expect(messages == [["role": "user", "content": RewritePrompt.userMessage(for: request)]])
    }

    @Test(arguments: [FakeValueStore<String>(nil), FakeValueStore(""), FakeValueStore("sk-ant-test", isBroken: true)])
    func `needs an API key`(store: FakeValueStore<String>) {
        #expect(throws: RewriteError.missingKey) {
            try AnthropicAPI(apiKeyStore: store).call(for: .cleanup("hello"))
        }
    }

    @Test(arguments: [
        (#"{"content":[{"type":"text","text":"  Hello there.\n"}],"stop_reason":"end_turn"}"#, "Hello there."),
        (
            #"{"content":[{"type":"thinking","thinking":"hm"},{"type":"text","text":"Hello"},{"type":"text","text":" there."}]}"#,
            "Hello there.",
        ),
        (#"{"content":[],"stop_reason":"end_turn"}"#, ""),
    ])
    func `reads the text blocks of an answer`(json: String, expected: String) throws {
        #expect(try Self.api.answer(from: Data(json.utf8)) == expected)
    }

    @Test(arguments: [
        (#"{"content":[{"type":"text","text":"See you"}],"stop_reason":"max_tokens"}"#, RewriteError.truncated),
        (#"{"content":[],"stop_reason":"refusal"}"#, .refused),
        (#"{"type":"error"}"#, .unreadableResponse),
        ("<html>Bad gateway</html>", .unreadableResponse),
    ])
    func `rejects unusable answers`(json: String, error: RewriteError) {
        #expect(throws: error) {
            try Self.api.answer(from: Data(json.utf8))
        }
    }
}
