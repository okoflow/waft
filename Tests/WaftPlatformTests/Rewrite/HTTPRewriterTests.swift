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

    @Test
    func `returns the answer the API reads from the response`() async throws {
        let transport = FakeHTTPTransport(.status(200, body: Data("Hello.".utf8)))
        let rewriter = HTTPRewriter(api: FakeRewriteAPI(key: "sk-test"), transport: transport)

        #expect(try await rewriter.rewrite(.cleanup("hello")) == "Hello.")
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
