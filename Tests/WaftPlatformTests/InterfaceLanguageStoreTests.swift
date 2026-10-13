import Foundation
import Testing
@testable import WaftPlatform

struct InterfaceLanguageStoreTests {
    private static let key = "AppleLanguages"

    @Test
    func `loads the first language of the app's own list`() async throws {
        try await withTemporaryDomain { defaults, store, _ in
            defaults.set(["de", "en"], forKey: Self.key)

            #expect(store.load() == "de")
        }
    }

    @Test
    func `saves the language as the app's only preferred language and lets its text direction follow it`() async throws {
        try await withTemporaryDomain { defaults, store, _ in
            store.save("he")

            #expect(defaults.stringArray(forKey: Self.key) == ["he"])
            #expect(defaults.bool(forKey: "AppleTextDirection"))
            #expect(store.load() == "he")
        }
    }

    @Test
    func `follows the system languages once the language is deleted`() async throws {
        try await withTemporaryDomain { defaults, store, domainName in
            store.save("uk")

            store.delete()

            #expect(store.load() == nil)
            #expect(!store.exists())
            #expect(defaults.persistentDomain(forName: domainName)?["AppleTextDirection"] == nil)
        }
    }

    private func withTemporaryDomain(_ body: (UserDefaults, InterfaceLanguageStore, String) throws -> Void) async throws {
        try await FileManager.withTemporaryDirectory { directory in
            let domainName = directory.appending(path: "defaults").path
            let defaults = try #require(UserDefaults(suiteName: domainName))

            try body(defaults, InterfaceLanguageStore(defaults: defaults, domainName: domainName), domainName)
        }
    }
}
