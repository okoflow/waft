import Foundation

package struct LocalServer: Codable, Equatable, Sendable {
    package static let knownServers: [(name: String, baseURL: String)] = [
        ("Ollama", defaultBaseURL),
        ("LM Studio", "http://localhost:1234/v1"),
        ("llama.cpp or MLX", "http://localhost:8080/v1"),
        ("Jan", "http://localhost:1337/v1"),
    ]

    private static let defaultBaseURL = "http://localhost:11434/v1"
    private static let loopbackHosts: Set = ["localhost", "127.0.0.1", "::1", "[::1]", "0.0.0.0"]

    package var baseURL: String
    package var model: String

    package var isConfigured: Bool {
        [baseURL, model].allSatisfy { !$0.isEmpty }
    }

    package var isOnThisMac: Bool {
        let address = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let host = URLComponents(string: address)?.host?.lowercased(),
              !Self.loopbackHosts.contains(host) else { return true }

        return host.hasSuffix(".localhost")
    }

    package init(baseURL: String = defaultBaseURL, model: String = "") {
        self.baseURL = baseURL
        self.model = model
    }

    package init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let defaults = LocalServer()

        baseURL = container.decode(.baseURL, default: defaults.baseURL)
        model = container.decode(.model, default: defaults.model)
    }
}
