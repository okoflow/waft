package import WaftCore
import Foundation
import os

package struct SecretFileStore: ValueStore {
    package let name: String

    private let file: any ValueStore<String>
    private let keychain: any ValueStore<String>

    init(name: String, file: any ValueStore<String>, keychain: any ValueStore<String>) {
        self.name = name
        self.file = file
        self.keychain = keychain
    }

    package static func license() -> SecretFileStore {
        stored(in: "license-key.json", movingFrom: .license())
    }

    package static func apiKey(for provider: CloudProvider) -> SecretFileStore {
        switch provider {
        case .claude: stored(in: "anthropic-api-key.json", movingFrom: .apiKey(for: .claude))
        case .openAI: stored(in: "openai-api-key.json", movingFrom: .apiKey(for: .openAI))
        }
    }

    private static func stored(in fileName: String, movingFrom keychain: KeychainStore) -> SecretFileStore {
        let url = AppIdentity.supportDirectory.appending(path: fileName)

        return SecretFileStore(
            name: keychain.name,
            file: JSONFileStore<String>(name: keychain.name, url: url),
            keychain: keychain,
        )
    }

    package func load() throws -> String? {
        guard !file.exists() else { return try file.load() }
        guard keychain.exists() else { return nil }

        return moveFromKeychain()
    }

    package func save(_ value: String) throws {
        try file.save(value)

        guard keychain.exists() else { return }

        deleteFromKeychain()
    }

    package func delete() throws {
        var failures: [any Error] = []

        for store in [file, keychain] {
            do {
                try store.delete()
            } catch {
                failures.append(error)
            }
        }

        guard let firstFailure = failures.first else { return }

        throw firstFailure
    }

    package func exists() -> Bool {
        guard !file.exists() else { return true }

        return keychain.exists()
    }

    private func moveFromKeychain() -> String? {
        let value: String?

        do {
            value = try keychain.load()
        } catch {
            Logger.storage.error(
                "Couldn't read the \(name, privacy: .public) from the keychain: \(error.logDescription, privacy: .public)",
            )

            return nil
        }

        guard let value else { return nil }

        do {
            try file.save(value)
        } catch {
            Logger.storage.error(
                "Couldn't move the \(name, privacy: .public) to its file: \(error.logDescription, privacy: .public)",
            )

            return value
        }

        deleteFromKeychain()
        Logger.storage.info("Moved the \(name, privacy: .public) from the keychain to its file")

        return value
    }

    private func deleteFromKeychain() {
        do {
            try keychain.delete()
        } catch {
            Logger.storage.error(
                "Couldn't delete the \(name, privacy: .public) from the keychain: \(error.logDescription, privacy: .public)",
            )
        }
    }
}
