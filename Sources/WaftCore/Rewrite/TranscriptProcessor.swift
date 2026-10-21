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
            setup.writingVariants.variant(for: setup.translation.target(forSpoken: transcript.language))

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
        try await rewrite(
            instruction.text,
            in: instruction.language,
            as: .edit(selection: selection),
            setup: setup,
            deadline: setup.editDeadline,
        )
    }

    package func rework(
        _ text: String,
        in language: Language,
        as task: TextTask,
        setup: RewriteSetup,
    ) async throws(RewriteError) -> String {
        let kind = RewriteRequest.Kind.text(task, instructions: setup.instructions)

        let reworked = try await rewrite(text, in: language, as: kind, setup: setup, deadline: setup.editDeadline)

        guard case let .translate(_, target) = task else { return reworked }

        return reworked.written(in: setup.writingVariants.variant(for: target), keeping: [])
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
            return ProcessedText(text: light(text, language: language), mode: .light)

        case .clean, .formal, .translate, .custom:
            let lightened = light(text, language: language)
            guard !lightened.isBlank else { return ProcessedText(text: lightened, mode: .light) }
            guard allowsAI else { return ProcessedText(text: lightened, mode: .light, fallback: .needsPro) }

            do throws(RewriteError) {
                let kind = Self.kind(for: mode, language: language, setup: setup)

                let rewritten = try await rewrite(text, in: language, as: kind, setup: setup, deadline: setup.deadline)

                return ProcessedText(text: rewritten, mode: mode)
            } catch {
                return ProcessedText(text: lightened, mode: .light, fallback: RewriteFallback(error))
            }
        }
    }

    private func light(_ text: String, language: Language) -> String {
        VoiceCommands.apply(LightModeRules.apply(text, language: language), language: language)
    }

    private func rewrite(
        _ text: String,
        in language: Language,
        as kind: RewriteRequest.Kind,
        setup: RewriteSetup,
        deadline: Duration,
    ) async throws(RewriteError) -> String {
        let request = RewriteRequest(
            text: text,
            language: language,
            kind: kind,
            localServer: setup.serverInUse,
            cloudModel: setup.cloudModelInUse,
            deadline: deadline,
        )

        let rewriter = rewriters[setup.provider]

        let answer = try await RewriteDeadline.run(request.deadline) { () async throws(RewriteError) -> String in
            try await rewriter.rewrite(request)
        }

        return try RewriteValidator.validated(answer, for: request)
    }
}
