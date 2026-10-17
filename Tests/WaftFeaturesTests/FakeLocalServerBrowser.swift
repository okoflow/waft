import os
import WaftCore

final nonisolated class FakeLocalServerBrowser: LocalServerBrowsing {
    private let served: [String: [String]]
    private let heldURL: String?
    private let queries: AsyncStream<Void>
    private let queryContinuation: AsyncStream<Void>.Continuation
    private let pendingRelease = OSAllocatedUnfairLock<CheckedContinuation<Void, Never>?>(initialState: nil)
    private let answeredURLs = OSAllocatedUnfairLock(initialState: [String]())

    var answered: [String] {
        answeredURLs.withLock { $0 }
    }

    init(_ served: [String: [String]], holding heldURL: String? = nil) {
        self.served = served
        self.heldURL = heldURL
        (queries, queryContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    func release() {
        let continuation = pendingRelease.withLock { pending in
            let continuation = pending
            pending = nil

            return continuation
        }

        continuation?.resume()
    }

    func waitUntilAsked() async {
        var iterator = queries.makeAsyncIterator()
        _ = await iterator.next()
    }

    func models(at server: LocalServer) async throws(RewriteError) -> [String] {
        if server.baseURL == heldURL {
            await withCheckedContinuation { continuation in
                pendingRelease.withLock { $0 = continuation }
                queryContinuation.yield(())
            }
        }

        answeredURLs.withLock { $0.append(server.baseURL) }

        guard let models = served[server.baseURL] else { throw .offline }

        return models
    }
}
