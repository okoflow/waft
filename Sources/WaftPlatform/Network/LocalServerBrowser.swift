package import WaftCore
import Foundation

package struct LocalServerBrowser: LocalServerBrowsing {
    private static let timeout: TimeInterval = 1.5
    private static let service = "The local server"

    private let transport: any HTTPTransport

    package init() {
        self.init(transport: URLSession(configuration: .ephemeral))
    }

    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    package func models(at server: LocalServer) async throws(RewriteError) -> [String] {
        let request = try URLRequest(url: server.url(appending: "/models"), timeoutInterval: Self.timeout)
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw .failedRequest(error, to: Self.service)
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw .unavailable }

        return try ResponseDecoder.decode(LocalModelList.self, from: data, sentBy: Self.service).data.map(\.id)
    }
}

private struct LocalModelList: Decodable {
    struct Model: Decodable {
        let id: String
    }

    let data: [Model]
}
