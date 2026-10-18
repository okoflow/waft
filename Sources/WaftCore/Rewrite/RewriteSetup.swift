package struct RewriteSetup: Sendable {
    package let provider: ModelProvider
    package let instructions: String
    package let translation: Translation

    private let cloudModels: PerProvider<CloudModel>
    private let localServer: LocalServer

    var serverInUse: LocalServer? {
        provider == .localServer ? localServer : nil
    }

    var cloudModelInUse: CloudModel? {
        guard case let .cloud(provider) = provider else { return nil }

        return cloudModels[provider]
    }

    var deadline: Duration {
        switch provider {
        case .localServer: .seconds(15)
        case let .cloud(provider): cloudModels[provider].deadline
        }
    }

    var editDeadline: Duration {
        switch provider {
        case .localServer: .seconds(45)
        case let .cloud(provider): cloudModels[provider].editDeadline
        }
    }

    package init(
        provider: ModelProvider,
        instructions: String,
        cloudModels: PerProvider<CloudModel> = CloudModel.defaultChoices,
        translation: Translation = Translation(),
        localServer: LocalServer = LocalServer(),
    ) {
        self.provider = provider
        self.instructions = instructions
        self.cloudModels = cloudModels
        self.translation = translation
        self.localServer = localServer
    }
}
