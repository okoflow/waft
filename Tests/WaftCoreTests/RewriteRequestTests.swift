import Testing
import WaftCore

struct RewriteRequestTests {
    @Test(arguments: [(10, 512), (256, 512), (1000, 2000), (2048, 4096), (5000, 4096)])
    func `budgets output tokens for a cleanup from the transcript`(length: Int, budget: Int) {
        #expect(RewriteRequest.cleanup(String(repeating: "a", count: length)).outputTokenBudget == budget)
    }

    @Test(arguments: [(10, 1024), (256, 1024), (1000, 4000), (2000, 4096)])
    func `budgets more output tokens for a custom mode from the transcript`(length: Int, budget: Int) {
        #expect(RewriteRequest.custom(String(repeating: "a", count: length)).outputTokenBudget == budget)
    }

    @Test(arguments: [(10, 1024), (1000, 2000), (3000, 4096)])
    func `budgets output tokens for an edit from the selection`(length: Int, budget: Int) {
        let request = RewriteRequest.edit(
            String(repeating: "x", count: 4000),
            selection: String(repeating: "a", count: length),
        )

        #expect(request.outputTokenBudget == budget)
    }

    @Test(arguments: [(10, 1024), (1000, 3000), (2000, 4096)])
    func `budgets output tokens for a text task from the text`(length: Int, budget: Int) {
        #expect(RewriteRequest.text(String(repeating: "a", count: length), task: .fix).outputTokenBudget == budget)
    }
}
