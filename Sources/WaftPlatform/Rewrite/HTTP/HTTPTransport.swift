import Foundation
import WaftCore

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension HTTPTransport {
    func body(for request: URLRequest, from service: String) async throws(RewriteError) -> Data {
        try await reply(to: request, from: service).body(from: service)
    }

    func reply(to request: URLRequest, from service: String) async throws(RewriteError) -> HTTPReply {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await self.data(for: request)
        } catch {
            throw .failedRequest(error, to: service)
        }

        guard let http = response as? HTTPURLResponse else { throw .unreadableResponse }

        return HTTPReply(status: http.statusCode, data: data)
    }
}
