import Foundation

package enum ModelProvider: Hashable, Sendable {
    case localServer
    case cloud(CloudProvider)

    package var title: String {
        switch self {
        case .localServer: String(localized: "Local server")
        case let .cloud(provider): provider.title
        }
    }

    package var isCloud: Bool {
        if case .cloud = self {
            true
        } else {
            false
        }
    }

    private var storedName: String {
        switch self {
        case .localServer: "local"
        case let .cloud(provider): provider.rawValue
        }
    }

    private init?(storedName: String) {
        if storedName == "local" {
            self = .localServer

            return
        }

        guard let provider = CloudProvider(rawValue: storedName) else { return nil }

        self = .cloud(provider)
    }
}

extension ModelProvider: Codable {
    package init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let storedName = try container.decode(String.self)
        guard let provider = ModelProvider(storedName: storedName) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown model provider \(storedName)")
        }

        self = provider
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(storedName)
    }
}
