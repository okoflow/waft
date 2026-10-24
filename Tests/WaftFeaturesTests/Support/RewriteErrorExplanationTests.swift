import Testing
import WaftCore
@testable import WaftFeatures

struct RewriteErrorExplanationTests {
    @Test(arguments: [
        (RewriteError.offline, ModelProvider.cloud(.claude), "You're offline"),
        (RewriteError.offline, ModelProvider.localServer, "The local server isn't running"),
        (RewriteError.timeout, ModelProvider.cloud(.claude), "Claude didn't answer in time"),
    ])
    func `explains a rewrite error in a sentence of its own`(error: RewriteError, provider: ModelProvider, explanation: String) {
        #expect(error.explanation(for: provider) == explanation)
    }
}
