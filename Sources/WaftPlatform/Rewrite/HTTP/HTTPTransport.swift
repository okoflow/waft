import Foundation
import os
import WaftCore

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension HTTPTransport {
    func body(for request: URLRequest, from service: String) async throws(RewriteError) -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await self.data(for: request)
        } catch {
            throw .failedRequest(error, to: service)
        }

        guard let http = response as? HTTPURLResponse else { throw .unreadableResponse }

        let status = http.statusCode
        guard (200 ..< 300).contains(status) else {
            Logger.network.error("\(service, privacy: .public) answered HTTP \(status, privacy: .public)")

            throw RewriteError(httpStatus: status)
        }

        return data
    }
}
