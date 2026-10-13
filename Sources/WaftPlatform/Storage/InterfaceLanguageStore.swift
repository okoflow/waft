import Foundation
import WaftCore

package struct InterfaceLanguageStore: ValueStore {
    private static let key = "AppleLanguages"
    private static let textDirectionKey = "AppleTextDirection"

    package let name = "interface language"

    private nonisolated(unsafe) let defaults: UserDefaults
    private let domainName: String

    package init() {
        self.init(defaults: .standard, domainName: AppIdentity.bundleIdentifier)
    }

    init(defaults: UserDefaults, domainName: String) {
        self.defaults = defaults
        self.domainName = domainName
    }

    package func load() -> String? {
        let domain = defaults.persistentDomain(forName: domainName)
        guard let languages = domain?[Self.key] as? [String] else { return nil }

        return languages.first
    }

    package func save(_ value: String) {
        defaults.set([value], forKey: Self.key)
        defaults.set(true, forKey: Self.textDirectionKey)
    }

    package func delete() {
        defaults.removeObject(forKey: Self.key)
        defaults.removeObject(forKey: Self.textDirectionKey)
    }

    package func exists() -> Bool {
        load() != nil
    }
}
