enum RewriteDeadline {
    static func run(
        _ deadline: Duration,
        _ operation: @escaping @Sendable () async throws(RewriteError) -> String,
    ) async throws(RewriteError) -> String {
        let first = await withTaskGroup(of: Result<String, RewriteError>.self) { group in
            group.addTask { await Self.result(of: operation) }
            group.addTask {
                await Task.slept(for: deadline)

                return .failure(.timeout)
            }

            defer { group.cancelAll() }

            guard let first = await group.next() else { preconditionFailure("A deadline races two tasks") }

            return first
        }

        return try first.get()
    }

    private static func result(of operation: () async throws(RewriteError) -> String) async -> Result<String, RewriteError> {
        do throws(RewriteError) {
            return try await .success(operation())
        } catch {
            return .failure(error)
        }
    }
}
