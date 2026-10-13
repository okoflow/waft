import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct OpenAIAPITests {
    private static let api = OpenAIAPI(apiKeyStore: FakeValueStore("sk-test"))

    @Test
    func `calls the responses endpoint with a bearer token`() throws {
        let call = try Self.api.call(for: .cleanup("hello"))

        #expect(call.url.absoluteString == "https://api.openai.com/v1/responses")
        #expect(call.headers == ["authorization": "Bearer sk-test"])
    }

    @Test
    func `sends the prompt with little reasoning and room for it, without storing it`() throws {
        let request = RewriteRequest.cleanup("um hello")
        let body = try Self.api.call(for: request).body.jsonObject()

        #expect(body["model"] is String)
        #expect(body["instructions"] as? String == RewritePrompt.system(for: request))
        #expect(body["input"] as? String == RewritePrompt.userMessage(for: request))
        #expect(body["max_output_tokens"] as? Int == request.outputTokenBudget + 4096)
        #expect(body["store"] as? Bool == false)
        #expect((body["reasoning"] as? [String: String])?["effort"] == "low")
    }

    @Test(arguments: [FakeValueStore<String>(nil), FakeValueStore(""), FakeValueStore("sk-test", isBroken: true)])
    func `needs an API key`(store: FakeValueStore<String>) {
        #expect(throws: RewriteError.missingKey) {
            try OpenAIAPI(apiKeyStore: store).call(for: .cleanup("hello"))
        }
    }

    @Test(arguments: [
        (
            #"{"output":[{"type":"reasoning"},{"type":"message","content":[{"type":"output_text","text":" Hi. "}]}]}"#,
            "Hi.",
        ),
        (
            #"{"output":[{"type":"message","content":[{"type":"output_text","text":"A"},{"type":"output_text","text":"B"}]}]}"#,
            "AB",
        ),
        (#"{"output":[{"type":"message","content":[{"type":"output_text","text":"Hi."},{"text":"No type."}]}]}"#, "Hi."),
        (#"{"status":"completed","output":[]}"#, ""),
    ])
    func `reads the output text of an answer`(json: String, expected: String) throws {
        #expect(try Self.api.answer(from: Data(json.utf8)) == expected)
    }

    @Test(arguments: [
        (#"{"status":"incomplete","incomplete_details":{"reason":"max_output_tokens"},"output":[]}"#, RewriteError.truncated),
        (#"{"status":"incomplete","incomplete_details":{"reason":"content_filter"},"output":[]}"#, .refused),
        (#"{"status":"incomplete","output":[]}"#, .truncated),
        (#"{"status":"failed","output":[]}"#, .serviceUnavailable),
        (#"{"status":"failed","error":{"code":"server_error","message":"Try again."},"output":[]}"#, .serviceUnavailable),
        (#"{"output":[{"type":"message","content":[{"type":"refusal","refusal":"No."}]}]}"#, .refused),
        (#"{"status":"completed"}"#, .unreadableResponse),
        ("not json", .unreadableResponse),
    ])
    func `rejects unusable answers`(json: String, error: RewriteError) {
        #expect(throws: error) {
            try Self.api.answer(from: Data(json.utf8))
        }
    }
}
