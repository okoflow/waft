import Foundation
import Testing
@testable import WaftPlatform

struct InterfaceLanguageStoreTests {
    private static let key = "AppleLanguages"

    @Test
    func `loads the first language of the app's own list`() async throws {
        try await withTemporaryDomain { defaults, store in
            defaults.set(["de", "en"], forKey: Self.key)

            #expect(store.load() == "de")
        }
    }

    @Test
    func `saves the language as the app's only preferred language`() async throws {
        try await withTemporaryDomain { defaults, store in
            store.save("uk")

            #expect(defaults.stringArray(forKey: Self.key) == ["uk"])
            #expect(store.load() == "uk")
        }
    }

    @Test
    func `follows the system languages once the language is deleted`() async throws {
        try await withTemporaryDomain { _, store in
            store.save("uk")

            store.delete()

            #expect(store.load() == nil)
            #expect(!store.exists())
        }
    }

    private func withTemporaryDomain(_ body: (UserDefaults, InterfaceLanguageStore) throws -> Void) async throws {
        try await FileManager.withTemporaryDirectory { directory in
            let domainName = directory.appending(path: "defaults").path
            let defaults = try #require(UserDefaults(suiteName: domainName))

            try body(defaults, InterfaceLanguageStore(defaults: defaults, domainName: domainName))
        }
    }
}
