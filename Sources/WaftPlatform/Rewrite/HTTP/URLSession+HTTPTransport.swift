import Foundation

extension URLSession: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}
