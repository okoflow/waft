import Foundation
import os
import WaftCore

final nonisolated class FakeValueStore<Value: Sendable>: ValueStore {
    let name = "value"

    private let stored: OSAllocatedUnfairLock<Value?>
    private let isBroken: Bool

    var value: Value? {
        get { stored.withLock { $0 } }
        set { stored.withLock { $0 = newValue } }
    }

    init(_ value: Value? = nil, isBroken: Bool = false) {
        stored = OSAllocatedUnfairLock(initialState: value)
        self.isBroken = isBroken
    }

    func load() throws -> Value? {
        guard !isBroken else { throw CocoaError(.fileReadCorruptFile) }

        return value
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
