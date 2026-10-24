import Foundation
import WaftCore

struct FakeValueStore<Value: Sendable>: ValueStore {
    let name = "value"
    let value: Value?
    let isBroken: Bool

    init(_ value: Value?, isBroken: Bool = false) {
        self.value = value
        self.isBroken = isBroken
    }

    func load() throws -> Value? {
        guard !isBroken else { throw CocoaError(.fileReadNoPermission) }

        return value
    }

    func save(_: Value) {}

    func delete() {}

    func exists() -> Bool {
        value != nil
    }
}
