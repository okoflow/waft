package struct LocalServer: Codable, Equatable, Sendable {
    package static let knownServers: [(name: String, baseURL: String)] = [
        ("Ollama", defaultBaseURL),
        ("LM Studio", "http://localhost:1234/v1"),
        ("llama.cpp or MLX", "http://localhost:8080/v1"),
        ("Jan", "http://localhost:1337/v1"),
    ]

    private static let defaultBaseURL = "http://localhost:11434/v1"

    package var baseURL: String
    package var model: String

    package var isConfigured: Bool {
        !baseURL.isEmpty && !model.isEmpty
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
