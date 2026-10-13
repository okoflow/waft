import os
import WaftCore

final nonisolated class FakeValueStore<Value: Sendable>: ValueStore {
    let name = "value"

    private let stored: OSAllocatedUnfairLock<Value?>

    var value: Value? {
        stored.withLock { $0 }
    }

    init(_ value: Value? = nil) {
        stored = OSAllocatedUnfairLock(initialState: value)
    }

    func load() -> Value? {
        value
    }

    func save(_ value: Value) {
        stored.withLock { $0 = value }
    }

    func delete() {
        stored.withLock { $0 = nil }
    }

    func exists() -> Bool {
        value != nil
    }
}
