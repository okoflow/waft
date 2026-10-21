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
    func `saves into new folders and loads the value back`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "nested/deeper/sample.json")
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)

            try store.save(Self.sample)
            let text = try String(contentsOf: url, encoding: .utf8)

            #expect(store.exists())
            #expect(try store.load() == Self.sample)
            #expect(text.contains("\"https://waft.okoflow.com\""))
            #expect(text.contains("\n"))
        }
    }

    @Test
    func `keeps a file restricted to its owner after an overwrite`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "sample.json")
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)
            try store.save(Self.sample)

            try store.save(Self.sample)
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

            #expect(attributes[.posixPermissions] as? Int == 0o600)
        }
    }

    @Test
    func `restricts a file that others could read to its owner when it saves over it`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "dictionary.json")
            try Data("{}".utf8).write(to: url)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
            let store = JSONFileStore<StoredSample>(name: "dictionary", url: url)

            try store.save(Self.sample)
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

            #expect(attributes[.posixPermissions] as? Int == 0o600)
        }
    }

    @Test
    func `restricts a file that others could read to its owner when it loads it`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "dictionary.json")
            let store = JSONFileStore<StoredSample>(name: "dictionary", url: url)
            try store.save(Self.sample)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)

            #expect(try store.load() == Self.sample)
            #expect(try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int == 0o600)
        }
    }

    @Test
    func `writes a new file restricted to its owner and leaves no temporary file`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "nested/history.json")
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)
            try store.save(Self.sample)

            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let leftovers = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)

            #expect(attributes[.posixPermissions] as? Int == 0o600)
            #expect(leftovers == ["history.json"])
            #expect(try store.load() == Self.sample)
        }
    }

    @Test
    func `restricts the copy of an unreadable file to its owner`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "history.json")
            try Data(#"{"name": "#.utf8).write(to: url)
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)

            #expect(throws: DecodingError.self) {
                try store.load()
            }

            let copy = directory.appending(path: "history.unreadable.json")
            let attributes = try FileManager.default.attributesOfItem(atPath: copy.path)

            #expect(attributes[.posixPermissions] as? Int == 0o600)
        }
    }

    @Test
    func `keeps a copy of an unreadable file and reports the failure`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "settings.json")
            let corrupt = Data(#"{"name": "Waft", "count": "#.utf8)
            try corrupt.write(to: url)
            let store = JSONFileStore<StoredSample>(name: "sample", url: url)

            #expect(throws: DecodingError.self) {
                try store.load()
            }
            #expect(try Data(contentsOf: directory.appending(path: "settings.unreadable.json")) == corrupt)
            #expect(try Data(contentsOf: url) == corrupt)

            try store.save(Self.sample)

            #expect(try Data(contentsOf: directory.appending(path: "settings.unreadable.json")) == corrupt)
        }
    }

    @Test(arguments: [false, true])
    func `deletes an unreadable recovery copy with or without its original`(isOriginalMissing: Bool) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "history.json")
            let recoveryCopy = directory.appending(path: "history.unreadable.json")
            try Data(#"{"name": "#.utf8).write(to: url)
            let store = JSONFileStore<StoredSample>(name: "history", url: url)

            #expect(throws: DecodingError.self) {
                try store.load()
            }
            #expect(FileManager.default.fileExists(atPath: recoveryCopy.path))

            if isOriginalMissing {
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

    @Test(arguments: [false, true])
    func `attempts both deletions and reports the first failure`(isRecoveryImmutable: Bool) async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "history.json")
            let recoveryCopy = directory.appending(path: "history.unreadable.json")
            try Data(#"{"name": "#.utf8).write(to: url)
            let store = JSONFileStore<StoredSample>(name: "history", url: url)

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

    @Test
    func `deletes the file and tolerates deleting twice`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let store = JSONFileStore<StoredSample>(name: "sample", url: directory.appending(path: "sample.json"))
            try store.save(Self.sample)

            try store.delete()

            #expect(!store.exists())
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
