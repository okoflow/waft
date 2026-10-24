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

    @Test(arguments: [
        (RewriteFallback.offline, ModelProvider.localServer, "the local server isn't running"),
        (.offline, .cloud(.openAI), "you're offline"),
        (.unavailable, .localServer, "choose a local server and model in Settings › AI Models"),
        (.unavailable, .cloud(.claude), "Claude isn't available"),
        (.missingKey, .cloud(.openAI), "add your OpenAI API key in Settings › AI Models"),
        (.rejectedKey, .cloud(.openAI), "OpenAI rejected the API key"),
        (.serviceError, .cloud(.openAI), "OpenAI returned an error"),
        (.unusableAnswer, .cloud(.openAI), "OpenAI's answer couldn't be used"),
        (.needsPro, .cloud(.openAI), "AI modes need Waft+"),
    ])
    func `explains a fallback by provider`(fallback: RewriteFallback, provider: ModelProvider, reason: String) {
        #expect(fallback.reason(for: provider) == reason)
    }

    @Test(arguments: [(ModelProvider.cloud(.claude), "Claude"), (.cloud(.openAI), "OpenAI")])
    func `names the provider in the reason`(provider: ModelProvider, name: String) {
        #expect(RewriteFallback.timeout.reason(for: provider) == "\(name) didn't answer in time")
        #expect(RewriteFallback.rateLimited.message(for: provider) == "Used Light mode: \(name) is rate-limiting requests")
    }
}
