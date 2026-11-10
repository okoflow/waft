@testable import WaftCore

extension RewriteSetup {
    static func fixture(
        provider: ModelProvider,
        instructions: String,
        cloudModels: PerProvider<CloudModel> = CloudModel.defaultChoices,
        translation: Translation = Translation(),
        localServer: LocalServer = LocalServer(),
    ) -> RewriteSetup {
        RewriteSetup(
            provider: provider,
            instructions: instructions,
            cloudModels: cloudModels,
            translation: translation,
            writingVariants: WritingVariants(),
            localServer: localServer,
        )
    }
}
