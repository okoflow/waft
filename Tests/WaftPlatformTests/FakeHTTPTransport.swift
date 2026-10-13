import Foundation
import os
@testable import WaftPlatform

final class FakeHTTPTransport: HTTPTransport {
    enum Reply {
        case status(Int, body: Data = Data())
        case notHTTP
        case failure(URLError)
    }

    private let reply: Reply
    private let sent = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])

    var requests: [URLRequest] {
        sent.withLock { $0 }
    }

    init(_ reply: Reply) {
        self.reply = reply
    }

    func data(for request: URLRequest) throws -> (Data, URLResponse) {
        sent.withLock { $0.append(request) }

        guard let url = request.url else { throw URLError(.badURL) }

        switch reply {
        case let .status(status, body):
            guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
                throw URLError(.badServerResponse)
            }

            return (body, response)

        case .notHTTP:
            return (Data(), URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))

        case let .failure(error):
            throw error
        }
    }
}
