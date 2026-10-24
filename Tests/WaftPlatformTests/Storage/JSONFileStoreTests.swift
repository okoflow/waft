import Foundation
import Testing
import WaftPlatform

struct JSONFileStoreTests {
    private static let sample = StoredSample(name: "Waft", link: "https://waft.okoflow.com", count: 3)

    @Test
    func `loads nothing before anything is saved`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let store = JSONFileStore<StoredSample>(name: "sample", url: directory.appending(path: "sample.json"))

            #expect(try store.load() == nil)
            #expect(!store.exists())
        }
    }

    @Test
    func `saves into new owner-only folders as an owner-only file and loads the value back`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "nested/deeper/sample.json")
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)

            try store.save(Self.sample)

            let text = try String(contentsOf: url, encoding: .utf8)
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let folderAttributes = try FileManager.default.attributesOfItem(atPath: url.deletingLastPathComponent().path)
            let leftovers = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)

            #expect(store.exists())
            #expect(attributes[.posixPermissions] as? Int == 0o600)
            #expect(folderAttributes[.posixPermissions] as? Int == 0o700)
            #expect(leftovers == ["sample.json"])
            #expect(try store.load() == Self.sample)
            #expect(text.contains("\"https://waft.okoflow.com\""))
            #expect(text.contains("\n"))
        }
    }

    @Test(arguments: [false, true])
    func `restricts a file and its folder that others could read to their owner`(isSaving: Bool) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let folder = directory.appending(path: "Waft", directoryHint: .isDirectory)
            let url = folder.appending(path: "sample.json")
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)

            try store.save(Self.sample)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder.path)

            if isSaving {
                try store.save(Self.sample)
            } else {
                #expect(try store.load() == Self.sample)
            }

            #expect(try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int == 0o600)
            #expect(try FileManager.default.attributesOfItem(atPath: folder.path)[.posixPermissions] as? Int == 0o700)
        }
    }

    @Test
    func `keeps an owner-only copy of an unreadable file and reports the failure`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "settings.json")
            let copy = directory.appending(path: "settings.unreadable.json")
            let corrupt = Data(#"{"name": "Waft", "count": "#.utf8)
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)

            try corrupt.write(to: url)

            #expect(throws: DecodingError.self) {
                try store.load()
            }
            #expect(try Data(contentsOf: copy) == corrupt)
            #expect(try FileManager.default.attributesOfItem(atPath: copy.path)[.posixPermissions] as? Int == 0o600)
            #expect(try Data(contentsOf: url) == corrupt)

            try store.save(Self.sample)

            #expect(try Data(contentsOf: copy) == corrupt)
        }
    }

    @Test(arguments: [false, true])
    func `attempts both deletions and reports the first failure`(isRecoveryImmutable: Bool) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "history.json")
            let recoveryCopy = directory.appending(path: "history.unreadable.json")
            let store = JSONFileStore<StoredSample>(name: "history", url: url)

            try Data(#"{"name": "#.utf8).write(to: url)

            #expect(throws: DecodingError.self) {
                try store.load()
            }

            let immutableFiles = isRecoveryImmutable ? [url, recoveryCopy] : [url]

            try withImmutableFiles(immutableFiles) {
                #expect(performing: {
                    try store.delete()
                }, throws: { error in
                    let cause = error as NSError

                    return cause.userInfo[NSFilePathErrorKey] as? String == url.path
                })
                #expect(FileManager.default.fileExists(atPath: url.path))
                #expect(FileManager.default.fileExists(atPath: recoveryCopy.path) == isRecoveryImmutable)
            }
        }
    }

    @Test(arguments: [(true, false), (true, true), (false, true)])
    func `deletes the file and its unreadable recovery copy and tolerates deleting twice`(
        hasOriginal: Bool,
        hasRecoveryCopy: Bool,
    ) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "history.json")
            let recoveryCopy = directory.appending(path: "history.unreadable.json")
            let store = JSONFileStore<StoredSample>(name: "history", url: url)

            if hasRecoveryCopy {
                try Data(#"{"name": "#.utf8).write(to: url)

                #expect(throws: DecodingError.self) {
                    try store.load()
                }
                #expect(FileManager.default.fileExists(atPath: recoveryCopy.path))
            } else {
                try store.save(Self.sample)
            }

            if !hasOriginal {
                try FileManager.default.removeItem(at: url)
            }

            try store.delete()

            #expect(!FileManager.default.fileExists(atPath: url.path))
            #expect(!FileManager.default.fileExists(atPath: recoveryCopy.path))
            #expect(try store.load() == nil)
            #expect(throws: Never.self) {
                try store.delete()
            }
        }
    }

    private func withImmutableFiles(_ files: [URL], performing body: () throws -> Void) throws {
        defer {
            for file in files {
                #expect(throws: Never.self) {
                    try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: file.path)
                }
            }
        }

        for file in files {
            try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: file.path)
        }

        try body()
    }
}

private struct StoredSample: Codable, Equatable {
    let name: String
    let link: String
    let count: Int
}
