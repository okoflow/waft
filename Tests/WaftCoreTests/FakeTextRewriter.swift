import WaftCore

struct FakeTextRewriter: TextRewriter {
    let answer: Result<String, RewriteError>
    let log: RewriteLog

    func rewrite(_ request: RewriteRequest) async throws(RewriteError) -> String {
        await log.record(request)

        return try answer.get()
    }
}

actor RewriteLog {
    private(set) var requests: [RewriteRequest] = []

    func record(_ request: RewriteRequest) {
        requests.append(request)
    }
}
