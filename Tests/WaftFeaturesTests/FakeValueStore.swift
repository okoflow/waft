import Foundation
import os
import WaftCore

final nonisolated class FakeValueStore<Value: Sendable>: ValueStore {
    let name = "value"

    private let stored: OSAllocatedUnfairLock<Value?>
    private let isBroken: Bool
    private let failsSaving: Bool
    private let failsDeleting: Bool

    var value: Value? {
        get { stored.withLock { $0 } }
        set { stored.withLock { $0 = newValue } }
    }

    init(_ value: Value? = nil, isBroken: Bool = false, failsSaving: Bool = false, failsDeleting: Bool = false) {
        stored = OSAllocatedUnfairLock(initialState: value)
        self.isBroken = isBroken
        self.failsSaving = failsSaving
        self.failsDeleting = failsDeleting
    }

    func load() throws -> Value? {
        guard !isBroken else { throw CocoaError(.fileReadCorruptFile) }

        return value
    }

    func save(_ value: Value) throws {
        guard !failsSaving else { throw CocoaError(.fileWriteNoPermission) }

        stored.withLock { $0 = value }
    }

    func delete() throws {
        guard !failsDeleting else { throw CocoaError(.fileWriteNoPermission) }

        stored.withLock { $0 = nil }
    }

    func exists() -> Bool {
        value != nil
    }
}
