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
    func `sends the prompt with little thinking and room for it`() throws {
        let request = RewriteRequest.cleanup("um hello", target: .german)
        let body = try Self.api.call(for: request).body.jsonObject()
        let messages = try #require(body["messages"] as? [[String: String]])

        #expect(body["max_tokens"] as? Int == request.outputTokenBudget + 4096)
        #expect(body["thinking"] == nil)
        #expect((body["output_config"] as? [String: String])?["effort"] == "low")
        #expect(body["system"] as? String == RewritePrompt.system(for: request))
        #expect(messages == [["role": "user", "content": RewritePrompt.userMessage(for: request)]])
    }

    @Test(arguments: [
        (CloudModel.fastest, "claude-haiku-5-5"),
        (.balanced, "claude-sonnet-5-5"),
        (.smartest, "claude-opus-5-5"),
    ])
    func `calls the chosen model`(model: CloudModel, identifier: String) throws {
        let body = try Self.api.call(for: .cleanup("hello", cloudModel: model)).body.jsonObject()

        #expect(body["model"] as? String == identifier)
    }

    @Test
    func `needs a cloud model`() {
        #expect(throws: RewriteError.unavailable) {
            try Self.api.call(for: .cleanup("hello", cloudModel: nil))
        }
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
