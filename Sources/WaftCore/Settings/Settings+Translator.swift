extension Settings {
    package var expectedTranslatorLanguages: [Language] {
        let pinned = [translator.source, translator.translation.twoWayLanguage].compactMap(\.self)

        let candidates = pinned + [translator.translation.target] + languages.languages + translator.recentLanguages

        var seen: Set<Language> = []

        return candidates.filter { seen.insert($0).inserted }
    }

    package var translatorDetectionHints: [Language] {
        guard let source = translator.source else { return expectedTranslatorLanguages }

        return [source]
    }

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
