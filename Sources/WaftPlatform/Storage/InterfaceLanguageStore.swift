import Foundation
import WaftCore

package struct InterfaceLanguageStore: ValueStore {
    private static let key = "AppleLanguages"

    package let name = "interface language"

    package init() {}

    package func load() -> String? {
        let domain = UserDefaults.standard.persistentDomain(forName: AppIdentity.bundleIdentifier)
        guard let languages = domain?[Self.key] as? [String] else { return nil }

        return languages.first
    }

    package func save(_ value: String) {
        UserDefaults.standard.set([value], forKey: Self.key)
    }

    package func delete() {
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    package func exists() -> Bool {
        load() != nil
    }
}
