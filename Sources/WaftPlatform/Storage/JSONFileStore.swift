package import Foundation
import os
import WaftCore

package struct JSONFileStore<Value: Codable & Sendable>: ValueStore {
    package let name: String

    private let url: URL

    private let isPrivate: Bool

    private var unreadableCopy: URL {
        url.deletingPathExtension().appendingPathExtension("unreadable.json")
    }

    package init(name: String, url: URL, isPrivate: Bool = false) {
        self.name = name
        self.url = url
        self.isPrivate = isPrivate
    }

    package func load() throws -> Value? {
        guard exists() else { return nil }

        let data = try Data(contentsOf: url)

        do {
            return try JSONDecoder().decode(Value.self, from: data)
        } catch {
            keepUnreadableCopy(of: data)

            throw error
        }
    }

    package func save(_ value: Value) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(value).write(to: url, options: .atomic)
        try restrictIfPrivate(url)
    }

    package func exists() -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    package func delete() throws {
        guard exists() else { return }

        try FileManager.default.removeItem(at: url)
    }

    private func keepUnreadableCopy(of data: Data) {
        do {
            try data.write(to: unreadableCopy, options: .atomic)
            try restrictIfPrivate(unreadableCopy)
        } catch {
            let cause = error as NSError
            Logger.storage.error(
                "Couldn't keep a copy of an unreadable file: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)",
            )
        }
    }

    private func restrictIfPrivate(_ file: URL) throws {
        guard isPrivate else { return }

        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
    }
}
