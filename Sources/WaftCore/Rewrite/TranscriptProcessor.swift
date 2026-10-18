package struct TranscriptProcessor: Sendable {
    private let rewriters: Rewriters

    package init(rewriters: Rewriters) {
        self.rewriters = rewriters
    }

    private static func kind(for mode: Mode, language: Language, setup: RewriteSetup) -> RewriteRequest.Kind {
        switch mode {
        case .custom:
            .custom(instructions: setup.instructions)
        case .translate:
            .cleanup(instructions: setup.instructions, target: setup.translation.target(forSpoken: language))
        case .raw, .light, .clean, .formal:
            .cleanup(instructions: setup.instructions, target: nil)
        }
    }

    private static func writingVariant(
        of transcript: Transcript,
        after processed: ProcessedText,
        setup: RewriteSetup,
    ) -> WritingVariant? {
        switch processed.mode {
        case .custom:
            nil

        case .translate:
            setup.translation.target(forSpoken: transcript.language) == transcript.language ? transcript.variant : nil

        case .raw, .light, .clean, .formal:
            transcript.variant
        }
    }

    package func process(
        _ transcript: Transcript,
        mode: Mode,
        setup: RewriteSetup,
        vocabulary: Vocabulary,
        allowsAI: Bool,
    ) async -> ProcessedText {
        let language = transcript.language
        let corrected = vocabulary.correcting(transcript.text, language: language)

        if let snippet = vocabulary.snippet(matchingWhole: corrected, language: language) {
            return ProcessedText(text: snippet, mode: .raw)
        }

        let processed = await apply(mode, to: corrected, language: language, setup: setup, allowsAI: allowsAI)
        let variant = Self.writingVariant(of: transcript, after: processed, setup: setup)
        let written = processed.text.written(in: variant, keeping: vocabulary.promptTerms)
        let recorrected = vocabulary.correcting(written, language: language)
        let finished = vocabulary.expandingSnippets(in: recorrected, language: language)

        return ProcessedText(text: finished, mode: processed.mode, fallback: processed.fallback)
    }

    package func edit(
        _ selection: String,
        following instruction: Transcript,
        setup: RewriteSetup,
    ) async throws(RewriteError) -> String {
        let request = RewriteRequest(
            text: instruction.text,
            language: instruction.language,
            kind: .edit(selection: selection),
            localServer: setup.serverInUse,
            cloudModel: setup.cloudModelInUse,
            deadline: setup.editDeadline,
        )

        return try await rewrite(request, with: setup.provider)
    }

    private func apply(
        _ mode: Mode,
        to text: String,
        language: Language,
        setup: RewriteSetup,
        allowsAI: Bool,
    ) async -> ProcessedText {
        switch mode {
        case .raw:
            return ProcessedText(text: text, mode: .raw)

        case .light:
            return light(text, language: language)

        case .clean, .formal, .translate, .custom:
            let lightened = light(text, language: language)
            guard !lightened.text.isBlank else { return lightened }
            guard allowsAI else { return light(text, language: language, fallback: .needsPro) }

            return await cleanUp(text, mode: mode, language: language, setup: setup)
        }
    }

    private func cleanUp(_ text: String, mode: Mode, language: Language, setup: RewriteSetup) async -> ProcessedText {
        let request = RewriteRequest(
            text: text,
            language: language,
            kind: Self.kind(for: mode, language: language, setup: setup),
            localServer: setup.serverInUse,
            cloudModel: setup.cloudModelInUse,
            deadline: setup.deadline,
        )

        do throws(RewriteError) {
            let rewritten = try await rewrite(request, with: setup.provider)

            return ProcessedText(text: rewritten, mode: mode)
        } catch {
            return light(text, language: language, fallback: RewriteFallback(error))
        }
    }

    private func light(_ text: String, language: Language, fallback: RewriteFallback? = nil) -> ProcessedText {
        let cleaned = VoiceCommands.apply(LightModeRules.apply(text, language: language), language: language)

        return ProcessedText(text: cleaned, mode: .light, fallback: fallback)
    }

    private func rewrite(_ request: RewriteRequest, with provider: ModelProvider) async throws(RewriteError) -> String {
        let rewriter = rewriters[provider]
        let answer = try await RewriteDeadline.run(request.deadline) { () async throws(RewriteError) -> String in
            try await rewriter.rewrite(request)
        }

        return try RewriteValidator.validated(answer, for: request)
    }
}
