import Foundation
import Observation
import WaftCore

@Observable
final class TranslatorModel {
    static let characterLimit = 5000

    let copyFeedback = CopyFeedback<String>()
    let sourcePicker = LanguagePickerState()
    let targetPicker = LanguagePickerState()

    var input = "" {
        didSet { inputDidChange(from: oldValue) }
    }

    private(set) var output = ""
    private(set) var detected: Language?
    private(set) var isTranslating = false
    private(set) var failure: String?

    @ObservationIgnored private var task: Task<Void, Never>?

    private let processor: TranscriptProcessor
    private let detector: any LanguageDetector
    private let settings: SettingsModel
    private let pro: ProModel
    private let clipboard: any Clipboard
    private let typingPause: Duration

    var source: Language? {
        get { settings.settings.translator.source }
        set {
            settings.settings.translator.source = newValue

            if let newValue {
                settings.settings.translator.remember(newValue)
            }

            translateNow()
        }
    }

    var target: Language {
        get { settings.settings.translator.translation.target }
        set {
            settings.settings.translator.translation.target = newValue
            settings.settings.translator.remember(newValue)

            translateNow()
        }
    }

    var knownSource: Language? {
        guard let source else { return detected }

        return source
    }

    var effectiveTarget: Language {
        settings.settings.translator.target(forSource: knownSource)
    }

    var isTwoWay: Bool {
        effectiveTarget != target
    }

    var recentLanguages: [Language] {
        settings.settings.translator.recentLanguages
    }

    var dictationKeyTitle: String {
        settings.settings.pushToTalkKey.shortTitle
    }

    var isLocked: Bool {
        !pro.isUnlocked
    }

    var canSwap: Bool {
        knownSource != nil
    }

    init(
        rewriters: Rewriters,
        detector: any LanguageDetector,
        settings: SettingsModel,
        pro: ProModel,
        clipboard: any Clipboard,
        typingPause: Duration = .milliseconds(500),
    ) {
        processor = TranscriptProcessor(rewriters: rewriters)
        self.detector = detector
        self.settings = settings
        self.pro = pro
        self.clipboard = clipboard
        self.typingPause = typingPause
    }

    func swapLanguages() {
        guard let from = knownSource else { return }

        let into = effectiveTarget

        settings.settings.translator.source = into

        if settings.settings.translator.target(forSource: into) != from {
            settings.settings.translator.translation.target = from
        }

        guard !output.isEmpty else {
            translateNow()

            return
        }

        input = output
    }

    func clear() {
        input = ""
    }

    func copy(_ text: String) {
        guard !text.isBlank else { return }

        clipboard.copy(text)
        copyFeedback.show(output)
    }

    func stop() {
        task?.cancel()
        isTranslating = false
    }

    private func inputDidChange(from oldValue: String) {
        if input.count > Self.characterLimit {
            input = String(input.prefix(Self.characterLimit))
        }

        guard input != oldValue else { return }

        schedule(after: typingPause)
    }

    private func translateNow() {
        schedule(after: .zero)
    }

    private func schedule(after pause: Duration) {
        task?.cancel()

        let text = input

        guard !text.isBlank, !isLocked else {
            output = ""
            detected = nil
            failure = nil
            isTranslating = false

            return
        }

        task = Task { [weak self] in
            guard await Task.slept(for: pause) else { return }

            await self?.translate(text)
        }
    }

    private func translate(_ text: String) async {
        detected = source == nil ? detector.language(of: text) : nil

        let into = effectiveTarget
        let language =
            if let knownSource {
                knownSource
            } else {
                into
            }
        let setup = settings.settings.translatorSetup(for: .translate)

        isTranslating = true

        do throws(RewriteError) {
            let translated = try await processor.rework(
                text,
                in: language,
                as: .translate(from: source, into: into),
                setup: setup,
            )

            guard !Task.isCancelled else { return }

            output = translated
            failure = nil
        } catch {
            guard !Task.isCancelled else { return }

            failure = RewriteFallback(error).reason(for: setup.provider).sentenceCased()
        }

        isTranslating = false
    }
}
