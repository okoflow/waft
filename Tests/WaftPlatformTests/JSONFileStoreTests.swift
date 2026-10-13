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
    func `keeps a private file restricted to its owner after an overwrite`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "sample.json")
            let store = JSONFileStore<StoredSample>(name: "sample", url: url, isPrivate: true)
            try store.save(Self.sample)

            try store.save(Self.sample)
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

            #expect(attributes[.posixPermissions] as? Int == 0o600)
        }
    }

    @Test
    func `restricts the copy of an unreadable private file to its owner`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "history.json")
            try Data(#"{"name": "#.utf8).write(to: url)
            let store = JSONFileStore<StoredSample>(name: "sample", url: url, isPrivate: true)

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
}

private struct StoredSample: Codable, Equatable {
    let name: String
    let link: String
    let count: Int
}
