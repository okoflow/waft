extension Task where Success == Never, Failure == Never {
    @discardableResult
    package static func slept(for duration: Duration) async -> Bool {
        do {
            try await sleep(for: duration)
        } catch {
            return false
        }

        return true
    }
}
