import WaftCore

extension RewriteRequest {
    private static let thinkingTokens = 4096

    var outputTokenLimitWithThinking: Int {
        outputTokenBudget + Self.thinkingTokens
    }
}
