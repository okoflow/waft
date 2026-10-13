import Foundation
import os
import WaftCore

extension ValueStore {
    func read() -> Value? {
        do {
            return try load()
        } catch {
            logFailure(to: "read", error)

            return nil
        }
    }

    func read(default empty: Value) -> Value {
        guard let value = read() else { return empty }

        return value
    }

    func write(_ value: Value) {
        do {
            try save(value)
        } catch {
            logFailure(to: "save", error)
        }
    }

    func remove() {
        do {
            try delete()
        } catch {
            logFailure(to: "delete", error)
        }
    }

    private func logFailure(to action: String, _ error: any Error) {
        let cause = error as NSError

        Logger.storage.error(
            """
            Couldn't \(action, privacy: .public) the \(name, privacy: .public): \
            \(cause.domain, privacy: .public) \(cause.code, privacy: .public)
            """,
        )
    }
}
