package struct RewriteSetup: Sendable {
    package let provider: ModelProvider
    package let instructions: String

    let translation: Translation
    let writingVariants: WritingVariants

    private let cloudModels: PerProvider<CloudModel>
    private let localServer: LocalServer

    var localServerInUse: LocalServer? {
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

    init(
        provider: ModelProvider,
        instructions: String,
        cloudModels: PerProvider<CloudModel> = CloudModel.defaultChoices,
        translation: Translation = Translation(),
        writingVariants: WritingVariants = WritingVariants(),
        localServer: LocalServer = LocalServer(),
    ) {
        self.provider = provider
        self.instructions = instructions
        self.cloudModels = cloudModels
        self.translation = translation
        self.writingVariants = writingVariants
        self.localServer = localServer
    }
}
