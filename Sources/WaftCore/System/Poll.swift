package enum Poll {
    @discardableResult
    package static func until(
        timeout: Duration,
        every interval: Duration = .milliseconds(20),
        _ condition: () -> Bool,
    ) async -> Bool {
        let deadline = ContinuousClock.now + timeout

        while !condition() {
            guard ContinuousClock.now < deadline, await Task.slept(for: interval) else { return false }
        }

        return true
    }
}
