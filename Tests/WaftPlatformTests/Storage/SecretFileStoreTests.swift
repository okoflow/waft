import Foundation
import Testing
@testable import WaftPlatform

struct SecretFileStoreTests {
    private static let secret = "sk-ant-test"

    @Test
    func `moves a keychain value into the empty file and deletes the keychain item`() throws {
        let file = FakeValueStore<String>(nil)
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        #expect(try store.load() == Self.secret)
        #expect(file.value == Self.secret)
        #expect(keychain.value == nil)
        #expect(keychain.operations == [.exists, .load, .delete])
    }

    @Test
    func `moves a keychain value into an owner-only file in an owner-only folder`() async throws {
        try await FileManager.withTemporaryDirectory { directory throws in
            let url = directory.appending(path: "Waft/anthropic-api-key.json")
            let keychain = FakeValueStore<String>(Self.secret)
            let store = SecretFileStore(
                name: "Claude API key",
                file: JSONFileStore<String>(name: "Claude API key", url: url),
                keychain: keychain,
            )

            #expect(try store.load() == Self.secret)

            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let folderAttributes = try FileManager.default.attributesOfItem(atPath: url.deletingLastPathComponent().path)

            #expect(fileAttributes[.posixPermissions] as? Int == 0o600)
            #expect(folderAttributes[.posixPermissions] as? Int == 0o700)
            #expect(try JSONFileStore<String>(name: "Claude API key", url: url).load() == Self.secret)
            #expect(keychain.value == nil)
        }
    }

    @Test
    func `keeps the file value and leaves the keychain alone when both have one`() throws {
        let file = FakeValueStore("sk-ant-file")
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        #expect(try store.load() == "sk-ant-file")
        #expect(store.exists())
        #expect(keychain.value == Self.secret)
        #expect(keychain.operations.isEmpty)
    }

    @Test
    func `leaves the keychain item and the file empty when the keychain read is denied`() throws {
        let file = FakeValueStore<String>(nil)
        let keychain = FakeValueStore<String>(Self.secret, isBroken: true)
        let store = store(file: file, keychain: keychain)

        #expect(try store.load() == nil)
        #expect(file.value == nil)
        #expect(file.operations == [.exists])
        #expect(keychain.value == Self.secret)
        #expect(keychain.operations == [.exists, .load])
    }

    @Test
    func `returns the keychain value and keeps the item when the file can't be written`() throws {
        let file = FakeValueStore<String>(nil, failsSaving: true)
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        #expect(try store.load() == Self.secret)
        #expect(file.value == nil)
        #expect(keychain.value == Self.secret)
        #expect(keychain.operations == [.exists, .load])
    }

    @Test
    func `never touches the keychain once the value lives in the file`() throws {
        let file = FakeValueStore<String>(nil)
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        #expect(try store.load() == Self.secret)

        let operationsAfterMove = keychain.operations

        for _ in 1 ... 3 {
            #expect(try store.load() == Self.secret)
            #expect(store.exists())
        }

        #expect(keychain.operations == operationsAfterMove)
    }

    @Test
    func `loads nothing without reading the keychain when neither has a value`() throws {
        let keychain = FakeValueStore<String>(nil)
        let store = store(file: FakeValueStore<String>(nil), keychain: keychain)

        #expect(try store.load() == nil)
        #expect(!store.exists())
        #expect(!keychain.operations.contains(.load))
    }

    @Test(arguments: [
        (nil, nil, false),
        ("sk-ant-file", nil, true),
        (nil, "sk-ant-test", true),
        ("sk-ant-file", "sk-ant-test", true),
    ])
    func `exists when the file or the keychain has a value`(fileValue: String?, keychainValue: String?, exists: Bool) {
        let store = store(file: FakeValueStore(fileValue), keychain: FakeValueStore(keychainValue))

        #expect(store.exists() == exists)
    }

    @Test
    func `saves into the file and deletes an older keychain item`() throws {
        let file = FakeValueStore<String>(nil)
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        try store.save("sk-ant-new")

        #expect(file.value == "sk-ant-new")
        #expect(keychain.value == nil)
        #expect(!keychain.operations.contains(.save))
    }

    @Test
    func `deletes both the file and the keychain item`() throws {
        let file = FakeValueStore("sk-ant-file")
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        try store.delete()

        #expect(file.value == nil)
        #expect(keychain.value == nil)
        #expect(!store.exists())
        #expect(try store.load() == nil)
    }

    @Test
    func `attempts both deletions and reports the failure`() {
        let file = FakeValueStore("sk-ant-file", failsDeleting: true)
        let keychain = FakeValueStore<String>(Self.secret)
        let store = store(file: file, keychain: keychain)

        #expect(throws: CocoaError.self) {
            try store.delete()
        }
        #expect(file.value == "sk-ant-file")
        #expect(keychain.value == nil)
    }

    private func store(file: FakeValueStore<String>, keychain: FakeValueStore<String>) -> SecretFileStore {
        SecretFileStore(name: "Claude API key", file: file, keychain: keychain)
    }
}
