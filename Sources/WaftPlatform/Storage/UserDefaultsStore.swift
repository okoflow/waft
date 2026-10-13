import Foundation
import WaftCore

package struct UserDefaultsStore<Value: Codable & Sendable>: ValueStore {
    package let name: String

    private let key: String

    package init(name: String, key: String) {
        self.name = name
        self.key = key
    }

    package func load() throws -> Value? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }

        return try JSONDecoder().decode(Value.self, from: data)
    }

    package func save(_ value: Value) throws {
        try UserDefaults.standard.set(JSONEncoder().encode(value), forKey: key)
    }

    package func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    package func exists() -> Bool {
        UserDefaults.standard.object(forKey: key) != nil
    }
}
