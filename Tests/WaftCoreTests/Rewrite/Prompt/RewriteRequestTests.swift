import Testing
import WaftCore

struct RewriteRequestTests {
    @Test(arguments: [(10, 512), (256, 512), (1000, 2000), (2048, 4096), (5000, 4096)])
    func `budgets twice the length of a cleanup within its limits`(length: Int, budget: Int) {
        #expect(RewriteRequest.cleanup(text(length)).outputTokenBudget == budget)
    }

    @Test(arguments: [(10, 1024), (256, 1024), (1000, 4000), (2000, 4096)])
    func `budgets four times the length of a custom mode's transcript within its limits`(length: Int, budget: Int) {
        #expect(RewriteRequest.custom(text(length)).outputTokenBudget == budget)
    }

    @Test(arguments: [(10, 1024), (1000, 2000), (3000, 4096)])
    func `budgets twice the length of an edit's selection within its limits`(length: Int, budget: Int) {
        #expect(RewriteRequest.edit(text(4000), selection: text(length)).outputTokenBudget == budget)
    }

    @Test(arguments: [(10, 1024), (1000, 3000), (2000, 4096)])
    func `budgets three times the length of a text task within its limits`(length: Int, budget: Int) {
        #expect(RewriteRequest.text(text(length), task: .fix).outputTokenBudget == budget)
    }

    private func text(_ length: Int) -> String {
        String(repeating: "a", count: length)
    }
}
