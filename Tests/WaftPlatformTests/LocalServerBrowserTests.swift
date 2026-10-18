import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct LocalServerBrowserTests {
    private static let server = LocalServer(baseURL: "http://localhost:1234/v1")

    @Test(arguments: [200, 203])
    func `lists the models the server reports at its models path`(status: Int) async throws {
        let body = Data(#"{"object":"list","data":[{"id":"qwen3","object":"model"},{"id":"gemma3","object":"model"}]}"#.utf8)
        let transport = FakeHTTPTransport(.status(status, body: body))

        let models = try await LocalServerBrowser(transport: transport).models(at: Self.server)

        #expect(models == ["qwen3", "gemma3"])
        #expect(transport.requests.map(\.url?.absoluteString) == ["http://localhost:1234/v1/models"])
    }

    @Test(arguments: [
        (FakeHTTPTransport.Reply.status(204), RewriteError.unreadableResponse),
        (.status(300), .serviceUnavailable),
        (.status(401), .rejectedKey),
        (.status(404), .unavailable),
        (.status(500), .serviceUnavailable),
        (.notHTTP, .unreadableResponse),
        (.status(200, body: Data(#"{"models":[]}"#.utf8)), .unreadableResponse),
        (.failure(URLError(.timedOut)), .timeout),
    ])
    func `maps a reply without a model list to a rewrite error`(reply: FakeHTTPTransport.Reply, error: RewriteError) async {
        let browser = LocalServerBrowser(transport: FakeHTTPTransport(reply))

        await #expect(throws: error) {
            try await browser.models(at: Self.server)
        }
    }
}
