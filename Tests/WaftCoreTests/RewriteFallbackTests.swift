import Testing
import WaftCore

struct RewriteFallbackTests {
    @Test(arguments: [
        (RewriteError.missingKey, RewriteFallback.missingKey),
        (.unavailable, .unavailable),
        (.offline, .offline),
        (.timeout, .timeout),
        (.rejectedKey, .rejectedKey),
        (.rateLimited, .rateLimited),
        (.serviceUnavailable, .serviceError),
        (.unreadableResponse, .unusableAnswer),
        (.truncated, .unusableAnswer),
        (.refused, .unusableAnswer),
    ])
    func `maps each rewrite error to a fallback`(error: RewriteError, fallback: RewriteFallback) {
        #expect(RewriteFallback(error) == fallback)
    }

    @Test(arguments: [(ModelProvider.localServer, "the local server isn't running"), (.cloud(.openAI), "you're offline")])
    func `explains being offline by provider`(provider: ModelProvider, reason: String) {
        #expect(RewriteFallback.offline.reason(for: provider) == reason)
    }

    @Test(arguments: [(ModelProvider.cloud(.claude), "Claude"), (.cloud(.openAI), "OpenAI")])
    func `names the provider in the reason`(provider: ModelProvider, name: String) {
        #expect(RewriteFallback.timeout.reason(for: provider) == "\(name) didn't answer in time")
        #expect(RewriteFallback.rateLimited.message(for: provider) == "Used Light mode: \(name) is rate-limiting requests")
    }

    @Test(arguments: [
        (ModelProvider.localServer, "choose a local server and model in Settings › AI Models"),
        (.cloud(.claude), "Claude isn't available"),
    ])
    func `points an unavailable local server to the settings`(provider: ModelProvider, reason: String) {
        #expect(RewriteFallback.unavailable.reason(for: provider) == reason)
    }
}
