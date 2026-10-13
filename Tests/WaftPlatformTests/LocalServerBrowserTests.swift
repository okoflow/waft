import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct LocalServerBrowserTests {
    private static let server = LocalServer(baseURL: "http://localhost:1234/v1")

    @Test
    func `lists the models the server reports at its models path`() async throws {
        let body = Data(#"{"object":"list","data":[{"id":"qwen3","object":"model"},{"id":"gemma3","object":"model"}]}"#.utf8)
        let transport = FakeHTTPTransport(.status(200, body: body))

        let models = try await LocalServerBrowser(transport: transport).models(at: Self.server)

        #expect(models == ["qwen3", "gemma3"])
        #expect(transport.requests.map(\.url?.absoluteString) == ["http://localhost:1234/v1/models"])
    }

    @Test(arguments: [
        (FakeHTTPTransport.Reply.status(204), RewriteError.unavailable),
        (.status(404), .unavailable),
        (.notHTTP, .unavailable),
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
