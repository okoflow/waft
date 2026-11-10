import Foundation
import os
@testable import WaftPlatform

final class FakeHTTPTransport: HTTPTransport {
    enum Reply {
        case status(Int, body: Data = Data())
        case notHTTP
        case failure(URLError)
    }

    private let replies: [Reply]
    private let sent = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])

    var requests: [URLRequest] {
        sent.withLock { $0 }
    }

    init(_ firstReply: Reply, _ laterReplies: Reply...) {
        replies = [firstReply] + laterReplies
    }

    func data(for request: URLRequest) throws -> (Data, URLResponse) {
        let earlierRequestCount = sent.withLock { requests in
            requests.append(request)

            return requests.count - 1
        }

        guard let url = request.url else { throw URLError(.badURL) }

        switch replies[min(earlierRequestCount, replies.count - 1)] {
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
