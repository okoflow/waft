import WaftCore

@MainActor
extension RewriteError {
    func explanation(for provider: ModelProvider) -> String {
        RewriteFallback(self).reason(for: provider).sentenceCased()
    }
}
