extension Settings {
    package func translatorSetup(for kind: TextTask.Kind) -> RewriteSetup {
        RewriteSetup(
            provider: modelProvider,
            instructions: translator.instructions.text(for: kind),
            cloudModels: PerProvider { _ in translator.cloudModel },
            translation: translator.translation,
            writingVariants: writingVariants,
            localServer: localServer,
        )
    }
}
