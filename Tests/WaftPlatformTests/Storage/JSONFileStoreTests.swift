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

    @Test(arguments: [
        ".history.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp",
        ".history.unreadable.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp",
        ".5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp",
    ])
    func `removes a temporary file that an interrupted save of its file left`(leftover: String) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let store = JSONFileStore<StoredSample>(name: "history", url: directory.appending(path: "history.json"))
            let file = directory.appending(path: leftover)

            try temporaryFile(at: file, age: 3600)
            try store.save(Self.sample)

            #expect(!FileManager.default.fileExists(atPath: file.path))
            #expect(try store.load() == Self.sample)
        }
    }

    @Test(arguments: [
        (".history.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp", TimeInterval(0)),
        (".settings.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp", 3600),
        (".history.json.backup.tmp", 3600),
        (".history.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp.txt", 3600),
        ("history.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp", 3600),
    ])
    func `keeps a temporary file that a save may still write or another file owns`(
        other: String,
        age: TimeInterval,
    ) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let store = JSONFileStore<StoredSample>(name: "history", url: directory.appending(path: "history.json"))
            let file = directory.appending(path: other)

            try temporaryFile(at: file, age: age)
            try store.save(Self.sample)

            #expect(FileManager.default.fileExists(atPath: file.path))
        }
    }

    @Test
    func `deletes the temporary files of its file whatever their age and leaves another file's`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let store = JSONFileStore<StoredSample>(name: "history", url: directory.appending(path: "history.json"))
            let own = directory.appending(path: ".history.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp")
            let foreign = directory.appending(path: ".settings.json.5B0E6F0C-9C1B-4E55-8E7A-0D1F6C2A9B34.tmp")

            try store.save(Self.sample)
            try temporaryFile(at: own, age: 0)
            try temporaryFile(at: foreign, age: 0)
            try store.delete()

            #expect(!FileManager.default.fileExists(atPath: own.path))
            #expect(FileManager.default.fileExists(atPath: foreign.path))
        }
    }

    private func temporaryFile(at file: URL, age: TimeInterval) throws {
        try Data("secret".utf8).write(to: file)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -age)], ofItemAtPath: file.path)
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
