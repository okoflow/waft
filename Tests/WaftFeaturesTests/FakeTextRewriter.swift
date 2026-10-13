import os
import WaftCore

final nonisolated class FakeTextRewriter: TextRewriter {
    private struct State {
        var requests: [RewriteRequest] = []
        var isReleased = false
    }

    private let reply: Result<String, RewriteError>
    private let holdsRequests: Bool
    private let state = OSAllocatedUnfairLock(initialState: State())

    var requests: [RewriteRequest] {
        state.withLock { $0.requests }
    }

    init(_ reply: Result<String, RewriteError> = .failure(.unavailable), holdsRequests: Bool = false) {
        self.reply = reply
        self.holdsRequests = holdsRequests
    }

    func release() {
        state.withLock { $0.isReleased = true }
    }

    func rewrite(_ request: RewriteRequest) async throws(RewriteError) -> String {
        state.withLock { $0.requests.append(request) }

        if holdsRequests {
            await Poll.until(timeout: .seconds(5)) { state.withLock { $0.isReleased } }
        }

        return try reply.get()
    }
}
