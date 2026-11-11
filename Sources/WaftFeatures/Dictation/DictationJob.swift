import WaftCore

struct DictationJob {
    let samples: [Float]
    let language: Language?
    let variants: WritingVariants
    let mode: Mode
    let setup: RewriteSetup
    let vocabulary: Vocabulary
    let target: FocusTarget
    let selection: String?
    let key: PushToTalkKey
    private(set) var pastes: Bool
    private(set) var isForPasswordField: Bool
    private(set) var record: DictationRecord?
    let allowsAI: Bool

    init(
        samples: [Float],
        recording: ActiveRecording,
        target: FocusTarget,
        settings: Settings,
        vocabulary: Vocabulary,
        allowsAI: Bool,
    ) {
        let mode = settings.mode(for: target.bundleIdentifier)

        self.samples = samples
        language = settings.languages.forcedLanguage
        variants = settings.writingVariants
        self.mode = mode
        setup = settings.rewriteSetup(for: mode)
        self.vocabulary = vocabulary
        self.target = target
        selection = recording.selection
        key = recording.key
        pastes = settings.pastesIntoFocusedField
        isForPasswordField = target.isSecureField
        self.allowsAI = allowsAI
    }

    func copyingInsteadOfPasting() -> DictationJob {
        var job = self
        job.pastes = false

        return job
    }

    func forPasswordField() -> DictationJob {
        var job = self
        job.isForPasswordField = true

        return job
    }

    func recorded(as record: DictationRecord) -> DictationJob {
        var job = self
        job.record = record

        return job
    }
}
