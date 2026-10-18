import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct HTTPRewriterTests {
    @Test
    func `posts the call of the API as JSON with the deadline as the timeout`() async throws {
        let transport = FakeHTTPTransport(.status(200))
        let rewriter = HTTPRewriter(api: FakeRewriteAPI(key: "sk-test"), transport: transport)

        _ = try await rewriter.rewrite(.cleanup("hello"))
        let request = try #require(transport.requests.first)

        #expect(request.url?.absoluteString == "https://api.example.com/v1/rewrite")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test")
        #expect(request.httpBody == Data(#"{"input":"hello","model":"fake"}"#.utf8))
        #expect(request.timeoutInterval == 3)
    }

    @Test(arguments: [200, 299])
    func `returns the answer the API reads from a successful response`(status: Int) async throws {
        let transport = FakeHTTPTransport(.status(status, body: Data("Hello.".utf8)))
        let rewriter = HTTPRewriter(api: FakeRewriteAPI(key: "sk-test"), transport: transport)

        #expect(try await rewriter.rewrite(.cleanup("hello")) == "Hello.")
    }

    @Test(arguments: [
        (FakeHTTPTransport.Reply.status(300), RewriteError.serviceUnavailable),
        (.notHTTP, .unreadableResponse),
        (.failure(URLError(.timedOut)), .timeout),
    ])
    func `maps an unsuccessful reply to a rewrite error`(reply: FakeHTTPTransport.Reply, error: RewriteError) async {
        let rewriter = HTTPRewriter(api: FakeRewriteAPI(key: "sk-test"), transport: FakeHTTPTransport(reply))

        await #expect(throws: error) {
            try await rewriter.rewrite(.cleanup("hello"))
        }
    }

    @Test(arguments: [
        #"{"error":{"message":"private dictated text","type":"private clipboard text","code":"Bearer private-token"}}"#,
        #"{"error":{"message":false,"type":[],"code":{}}}"#,
        "private dictated text",
    ])
    func `maps a failure by its status regardless of server diagnostics`(body: String) async {
        let transport = FakeHTTPTransport(.status(401, body: Data(body.utf8)))
        let rewriter = HTTPRewriter(api: FakeRewriteAPI(key: "sk-test"), transport: transport)

        await #expect(throws: RewriteError.rejectedKey) {
            try await rewriter.rewrite(.cleanup("private dictated text"))
        }
    }

    @Test
    func `sends nothing when the API cannot build the call`() async {
        let transport = FakeHTTPTransport(.status(200))
        let rewriter = HTTPRewriter(api: FakeRewriteAPI(key: nil), transport: transport)

        await #expect(throws: RewriteError.missingKey) {
            try await rewriter.rewrite(.cleanup("hello"))
        }

        #expect(transport.requests.isEmpty)
    }
}

private struct FakeRewriteAPI: RewriteAPI {
    let service = "Fake"
    let key: String?

    func call(for request: RewriteRequest) throws(RewriteError) -> APICall<[String: String]> {
        guard let key else { throw .missingKey }

        return APICall(
            url: URL(literal: "https://api.example.com/v1/rewrite"),
            headers: ["x-api-key": key],
            body: ["model": "fake", "input": request.text],
        )
    }

    func answer(from data: Data) throws(RewriteError) -> String {
        guard let answer = String(bytes: data, encoding: .utf8) else { throw .unreadableResponse }

        return answer
    }
}
