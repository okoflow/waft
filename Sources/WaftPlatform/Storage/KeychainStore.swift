import Foundation
import Security
import WaftCore

struct KeychainStore: LegacySecretStore {
    private enum KeychainError: CustomNSError {
        case unexpectedStatus(OSStatus)
        case unreadableItem

        var errorCode: Int {
            switch self {
            case let .unexpectedStatus(status): Int(status)
            case .unreadableItem: Int(errSecDecode)
            }
        }
    }

    private static let service = AppIdentity.bundleIdentifier

    let name: String

    private let account: String

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
        ]
    }

    static func license() -> KeychainStore {
        KeychainStore(name: "license key", account: "license-key")
    }

    static func apiKey(for provider: CloudProvider) -> KeychainStore {
        switch provider {
        case .claude: KeychainStore(name: "Claude API key", account: "anthropic-api-key")
        case .openAI: KeychainStore(name: "OpenAI API key", account: "openai-api-key")
        }
    }

    func load() throws -> String? {
        var search = query
        search[kSecReturnData as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(search as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        guard let data = item as? Data, let text = String(data: data, encoding: .utf8) else { throw KeychainError.unreadableItem }

        return text
    }

    func exists() -> Bool {
        var search = query
        search[kSecReturnAttributes as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne

        return SecItemCopyMatching(search as CFDictionary, nil) == errSecSuccess
    }

    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard [errSecSuccess, errSecItemNotFound].contains(status) else { throw KeychainError.unexpectedStatus(status) }
    }
}
