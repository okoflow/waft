package import Foundation
import Darwin
import os
import WaftCore

package struct JSONFileStore<Value: Codable & Sendable>: ValueStore {
    private static var staleTemporaryAge: TimeInterval {
        60
    }

    private static var temporarySuffix: String {
        ".tmp"
    }

    private static var legacyTemporaryPrefix: String {
        "."
    }

    package let name: String

    private let url: URL

    private var folder: URL {
        url.deletingLastPathComponent()
    }

    private var unreadableCopy: URL {
        url.deletingPathExtension().appendingPathExtension("unreadable.json")
    }

    private var temporaryPrefixes: [String] {
        [url, unreadableCopy].map(Self.temporaryPrefix) + [Self.legacyTemporaryPrefix]
    }

    package init(name: String, url: URL) {
        self.name = name
        self.url = url
    }

    private static func removeTemporary(_ file: URL) {
        do {
            try FileManager.default.removeItem(at: file)
        } catch {
            Logger.storage.error("Couldn't remove a temporary file: \(error.logDescription, privacy: .public)")
        }
    }

    private static func temporaryPrefix(of file: URL) -> String {
        ".\(file.lastPathComponent)."
    }

    private static func isOlder(_ file: URL, than age: TimeInterval) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
            guard let modified = attributes[.modificationDate] as? Date else { return false }

            return modified.timeIntervalSinceNow <= -age
        } catch {
            Logger.storage.error("Couldn't read the age of a temporary file: \(error.logDescription, privacy: .public)")

            return false
        }
    }

    private static func lastPOSIXError() -> any Error {
        guard let code = POSIXErrorCode(rawValue: errno) else { return CocoaError(.fileWriteUnknown) }

        return POSIXError(code)
    }

    package func load() throws -> Value? {
        guard exists() else { return nil }

        restrictToOwner()

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

        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700],
        )
        restrict(folder, to: 0o700)
        removeTemporaryFiles(olderThan: Self.staleTemporaryAge)
        try write(encoder.encode(value), to: url)
    }

    package func exists() -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    package func delete() throws {
        removeTemporaryFiles(olderThan: 0)

        var failures: [any Error] = []

        for file in [url, unreadableCopy] where FileManager.default.fileExists(atPath: file.path) {
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                failures.append(error)
            }
        }

        guard let firstFailure = failures.first else { return }

        throw firstFailure
    }

    private func restrictToOwner() {
        restrict(folder, to: 0o700)
        restrict(url, to: 0o600)
    }

    private func restrict(_ item: URL, to permissions: mode_t) {
        guard chmod(item.path, permissions) != 0 else { return }

        let error = Self.lastPOSIXError()
        let itemName = item.lastPathComponent

        Logger.storage.error(
            "Couldn't restrict \(itemName, privacy: .public) to its owner: \(error.logDescription, privacy: .public)",
        )
    }

    private func keepUnreadableCopy(of data: Data) {
        do {
            try write(data, to: unreadableCopy)
        } catch {
            Logger.storage.error("Couldn't keep a copy of an unreadable file: \(error.logDescription, privacy: .public)")
        }
    }

    private func removeTemporaryFiles(olderThan age: TimeInterval) {
        let names: [String]

        do {
            names = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return
        } catch {
            Logger.storage.error("Couldn't look for temporary files: \(error.logDescription, privacy: .public)")

            return
        }

        for name in names where isTemporary(name) {
            let file = folder.appending(path: name)
            guard Self.isOlder(file, than: age) else { continue }

            Self.removeTemporary(file)
        }
    }

    private func isTemporary(_ name: String) -> Bool {
        guard name.hasSuffix(Self.temporarySuffix) else { return false }

        return temporaryPrefixes.contains { prefix in
            guard name.hasPrefix(prefix) else { return false }

            let identifier = name.dropFirst(prefix.count).dropLast(Self.temporarySuffix.count)

            return UUID(uuidString: String(identifier)) != nil
        }
    }

    private func write(_ data: Data, to file: URL) throws {
        let temporaryName = Self.temporaryPrefix(of: file) + UUID().uuidString + Self.temporarySuffix
        let temporary = file.deletingLastPathComponent().appending(path: temporaryName)
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
