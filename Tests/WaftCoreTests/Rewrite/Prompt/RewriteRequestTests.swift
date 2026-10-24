import Testing
import WaftCore

struct RewriteRequestTests {
    @Test(arguments: [
        (RewriteRequest.cleanup(String(repeating: "a", count: 10)), 512),
        (.cleanup(String(repeating: "a", count: 256)), 512),
        (.cleanup(String(repeating: "a", count: 1000)), 2000),
        (.cleanup(String(repeating: "a", count: 2048)), 4096),
        (.cleanup(String(repeating: "a", count: 5000)), 4096),
        (.custom(String(repeating: "a", count: 10)), 1024),
        (.custom(String(repeating: "a", count: 256)), 1024),
        (.custom(String(repeating: "a", count: 1000)), 4000),
        (.custom(String(repeating: "a", count: 2000)), 4096),
        (.edit(String(repeating: "x", count: 4000), selection: String(repeating: "a", count: 10)), 1024),
        (.edit(String(repeating: "x", count: 4000), selection: String(repeating: "a", count: 1000)), 2000),
        (.edit(String(repeating: "x", count: 4000), selection: String(repeating: "a", count: 3000)), 4096),
        (.text(String(repeating: "a", count: 10), task: .fix), 1024),
        (.text(String(repeating: "a", count: 1000), task: .fix), 3000),
        (.text(String(repeating: "a", count: 2000), task: .fix), 4096),
    ])
    func `budgets output tokens by the kind of request`(request: RewriteRequest, budget: Int) {
        #expect(request.outputTokenBudget == budget)
    }
}
