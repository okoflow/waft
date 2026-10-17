import Foundation
import Testing
@testable import WaftPlatform

struct APIErrorBodyTests {
    @Test(arguments: [
        (
            #"{"error":{"message":"Bad key: sk-proj-AbC_12-3***xyz.","type":"invalid_request_error","code":"invalid_api_key"}}"#,
            "invalid_request_error invalid_api_key",
            "Bad key: sk-….",
        ),
        (#"{"error":{"message":"Keys sk-abc and sk-def are invalid","type":"auth"}}"#, "auth", "Keys sk-… and sk-… are invalid"),
        (#"{"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}"#, "overloaded_error", "Overloaded"),
        (
            #"{"error":{"code":500,"message":"Context size exceeded","type":"server_error"}}"#,
            "server_error 500",
            "Context size exceeded",
        ),
        (#"{"error":{"message":"Model not found"}}"#, "untyped", "Model not found"),
    ])
    func `reads the kind and the message without secrets`(json: String, kind: String, message: String) throws {
        let detail = try #require(APIErrorBody.detail(in: Data(json.utf8)))

        #expect(detail.kind == kind)
        #expect(detail.redactedMessage == message)
    }

    @Test(arguments: ["", "<html>502 Bad Gateway</html>", #"{"error":"oops"}"#, #"{}"#])
    func `has no details for other bodies`(body: String) {
        #expect(APIErrorBody.detail(in: Data(body.utf8)) == nil)
    }
}
