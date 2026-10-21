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

    @discardableResult
    func write(_ value: Value) -> Bool {
        do {
            try save(value)

            return true
        } catch {
            logFailure(to: "save", error)

            return false
        }
    }

    @discardableResult
    func remove() -> Bool {
        do {
            try delete()

            return true
        } catch {
            logFailure(to: "delete", error)

            return false
        }
    }

    private func logFailure(to action: String, _ error: any Error) {
        Logger.storage.error(
            "Couldn't \(action, privacy: .public) the \(name, privacy: .public): \(error.logDescription, privacy: .public)",
        )
    }
}
