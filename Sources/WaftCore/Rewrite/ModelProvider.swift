import Foundation

package enum ModelProvider: Hashable, Codable, RawRepresentable, Sendable {
    case localServer
    case cloud(CloudProvider)

    package var title: String {
        switch self {
        case .localServer: String(localized: "Local server")
        case let .cloud(provider): provider.title
        }
    }

    package var isCloud: Bool {
        switch self {
        case .localServer: false
        case .cloud: true
        }
    }

    package var rawValue: String {
        switch self {
        case .localServer: "local"
        case let .cloud(provider): provider.rawValue
        }
    }

    package init?(rawValue storedName: String) {
        if storedName == "local" {
            self = .localServer

            return
        }

        guard let provider = CloudProvider(rawValue: storedName) else { return nil }

        self = .cloud(provider)
    }
}
