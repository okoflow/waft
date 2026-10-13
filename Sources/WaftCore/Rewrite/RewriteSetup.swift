package struct RewriteSetup: Sendable {
    package let provider: ModelProvider
    package let instructions: String
    package let translation: Translation
    package let localServer: LocalServer

    var serverInUse: LocalServer? {
        provider == .localServer ? localServer : nil
    }

    package init(
        provider: ModelProvider,
        instructions: String,
        translation: Translation = Translation(),
        localServer: LocalServer = LocalServer(),
    ) {
        self.provider = provider
        self.instructions = instructions
        self.translation = translation
        self.localServer = localServer
    }
}
