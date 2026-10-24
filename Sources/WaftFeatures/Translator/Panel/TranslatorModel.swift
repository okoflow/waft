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
    @ObservationIgnored private var hasDroppedTranslation = false
    @ObservationIgnored private var translatedInput = ""

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
            detected = nil

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
        settings.settings.translator.knownSource(detected: detected)
    }

    var isShowingDetected: Bool {
        guard detected != nil else { return false }

        return trustedSource == nil
    }

    var effectiveTarget: Language {
        settings.settings.translator.target(forSource: knownSource)
    }

    var isTwoWay: Bool {
        guard settings.settings.translator.translation.twoWayLanguage != nil else { return false }

        return effectiveTarget != target
    }

    var recentLanguages: [Language] {
        settings.settings.translator.recentLanguages
    }

    var dictationKeyTitle: String {
        settings.settings.pushToTalkKey.shortTitle
    }

    var startsDictationByTapping: Bool {
        settings.settings.dictationStart == .tap
    }

    var isLocked: Bool {
        !pro.isUnlocked
    }

    var canSwap: Bool {
        swappedTranslation != nil
    }

    private var trustedSource: Language? {
        settings.settings.translator.trustedSource(detected: detected)
    }

    private var swappedTranslation: Translation? {
        let translator = settings.settings.translator

        guard let from = knownSource else {
            guard let other = translator.translation.twoWayLanguage else { return nil }

            return Translation(target: other, twoWayLanguage: target)
        }
        guard from != effectiveTarget else { return nil }

        return translator.swapped(from: from)
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
        guard let swappedTranslation else { return }

        var translator = settings.settings.translator
        translator.source = nil
        translator.translation = swappedTranslation
        settings.settings.translator = translator

        guard !output.isEmpty, translatedInput == input else {
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
        guard let task else { return }

        task.cancel()
        self.task = nil
        isTranslating = false
        hasDroppedTranslation = true
    }

    func resume() {
        guard hasDroppedTranslation else { return }

        hasDroppedTranslation = false
        translateNow()
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
        task = nil
        hasDroppedTranslation = false

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
        detected = detectedLanguage(of: text)

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
                as: .translate(from: trustedSource, into: into),
                setup: setup,
            )

            guard !Task.isCancelled else { return }

            output = translated
            translatedInput = text
            failure = nil
        } catch {
            guard !Task.isCancelled else { return }

            failure = error.explanation(for: setup.provider)
        }

        task = nil
        isTranslating = false
    }

    private func detectedLanguage(of text: String) -> Language? {
        detector.language(of: text, expecting: settings.settings.translatorDetectionHints)
    }
}
