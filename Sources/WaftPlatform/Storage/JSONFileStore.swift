package import Foundation
import Darwin
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

    private static func removeTemporary(_ file: URL) {
        guard FileManager.default.fileExists(atPath: file.path) else { return }

        do {
            try FileManager.default.removeItem(at: file)
        } catch {
            let cause = error as NSError
            Logger.storage.error(
                "Couldn't remove a temporary file: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)",
            )
        }
    }

    private static func lastPOSIXError() -> any Error {
        guard let code = POSIXErrorCode(rawValue: errno) else { return CocoaError(.fileWriteUnknown) }

        return POSIXError(code)
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
        try write(encoder.encode(value), to: url)
    }

    package func exists() -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    package func delete() throws {
        var firstFailure: (any Error)?

        for file in [url, unreadableCopy] where FileManager.default.fileExists(atPath: file.path) {
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                if firstFailure == nil {
                    firstFailure = error
                }
            }
        }

        if let firstFailure {
            throw firstFailure
        }
    }

    private func keepUnreadableCopy(of data: Data) {
        do {
            try write(data, to: unreadableCopy)
        } catch {
            let cause = error as NSError
            Logger.storage.error(
                "Couldn't keep a copy of an unreadable file: \(cause.domain, privacy: .public) \(cause.code, privacy: .public)",
            )
        }
    }

    private func write(_ data: Data, to file: URL) throws {
        guard isPrivate else {
            try data.write(to: file, options: .atomic)

            return
        }

        let temporary = file.deletingLastPathComponent().appending(path: ".\(UUID().uuidString).tmp")
        let descriptor = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL, 0o600)
        guard descriptor >= 0 else { throw Self.lastPOSIXError() }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)

        do {
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()

            guard rename(temporary.path, file.path) == 0 else { throw Self.lastPOSIXError() }
        } catch {
            Self.removeTemporary(temporary)

            throw error
        }
    }
}
