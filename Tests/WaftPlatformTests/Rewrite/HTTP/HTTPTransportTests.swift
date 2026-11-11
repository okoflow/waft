import Foundation
import Testing
import WaftCore
@testable import WaftPlatform

struct HTTPTransportTests {
    private static let request = URLRequest(url: URL(literal: "https://api.example.com/v1/rewrite"))

    @Test(arguments: [200, 400])
    func `replies with the status and data of any HTTP response`(status: Int) async throws {
        let transport = FakeHTTPTransport(.status(status, body: Data("Hello.".utf8)))

        let reply = try await transport.reply(to: Self.request, from: "Fake")

        #expect(reply.status == status)
        #expect(reply.data == Data("Hello.".utf8))
    }

    @Test(arguments: [200, 299])
    func `returns the body of a successful response`(status: Int) async throws {
        let transport = FakeHTTPTransport(.status(status, body: Data("Hello.".utf8)))

        #expect(try await transport.body(for: Self.request, from: "Fake") == Data("Hello.".utf8))
    }

    @Test(arguments: [
        (FakeHTTPTransport.Reply.status(300), RewriteError.serviceUnavailable),
        (.status(401), .rejectedKey),
        (.notHTTP, .unreadableResponse),
        (.failure(URLError(.timedOut)), .timeout),
    ])
    func `maps an unsuccessful reply to a rewrite error`(reply: FakeHTTPTransport.Reply, error: RewriteError) async {
        await #expect(throws: error) {
            try await FakeHTTPTransport(reply).body(for: Self.request, from: "Fake")
        }
    }
}
