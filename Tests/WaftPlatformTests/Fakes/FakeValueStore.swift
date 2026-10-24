import Foundation
import os
import WaftCore

final class FakeValueStore<Value: Sendable>: ValueStore {
    enum Operation: Equatable {
        case load
        case save
        case delete
        case exists
    }

    private struct State {
        var value: Value?
        var operations: [Operation] = []
    }

    let name = "value"

    private let state: OSAllocatedUnfairLock<State>
    private let isBroken: Bool
    private let failsSaving: Bool
    private let failsDeleting: Bool

    var value: Value? {
        state.withLock { $0.value }
    }

    var operations: [Operation] {
        state.withLock { $0.operations }
    }

    init(_ value: Value?, isBroken: Bool = false, failsSaving: Bool = false, failsDeleting: Bool = false) {
        state = OSAllocatedUnfairLock(initialState: State(value: value))
        self.isBroken = isBroken
        self.failsSaving = failsSaving
        self.failsDeleting = failsDeleting
    }

    func load() throws -> Value? {
        record(.load)

        guard !isBroken else { throw CocoaError(.fileReadNoPermission) }

        return value
    }

    func save(_ value: Value) throws {
        record(.save)

        guard !failsSaving else { throw CocoaError(.fileWriteNoPermission) }

        state.withLock { $0.value = value }
    }

    func delete() throws {
        record(.delete)

        guard !failsDeleting else { throw CocoaError(.fileWriteNoPermission) }

        state.withLock { $0.value = nil }
    }

    func exists() -> Bool {
        record(.exists)

        return value != nil
    }

    private func record(_ operation: Operation) {
        state.withLock { $0.operations.append(operation) }
    }
}
