package import WaftCore
import Foundation
import Security

package struct KeychainStore: ValueStore {
    private enum KeychainError: LocalizedError, CustomNSError {
        case unexpectedStatus(OSStatus)
        case unreadableItem

        var errorCode: Int {
            switch self {
            case let .unexpectedStatus(status): Int(status)
            case .unreadableItem: Int(errSecDecode)
            }
        }

        var errorDescription: String? {
            switch self {
            case let .unexpectedStatus(status):
                guard let message = SecCopyErrorMessageString(status, nil) else { return "OSStatus \(status)" }

                return message as String

            case .unreadableItem:
                return "The Keychain item isn't UTF-8 text"
            }
        }
    }

    private static let service = AppIdentity.bundleIdentifier

    package let name: String

    private let account: String

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account,
        ]
    }

    package static func license() -> KeychainStore {
        KeychainStore(name: "license key", account: "license-key")
    }

    package static func apiKey(for provider: CloudProvider) -> KeychainStore {
        switch provider {
        case .claude: KeychainStore(name: "Claude API key", account: "anthropic-api-key")
        case .openAI: KeychainStore(name: "OpenAI API key", account: "openai-api-key")
        }
    }

    package func load() throws -> String? {
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

    package func exists() -> Bool {
        var search = query
        search[kSecReturnAttributes as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne

        return SecItemCopyMatching(search as CFDictionary, nil) == errSecSuccess
    }

    package func save(_ value: String) throws {
        let data = Data(value.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            try add(data)
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    package func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard [errSecSuccess, errSecItemNotFound].contains(status) else { throw KeychainError.unexpectedStatus(status) }
    }

    private func add(_ data: Data) throws {
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }
}
