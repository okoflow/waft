import Foundation
import Observation
import WaftCore

@Observable
final class TryoutModel {
    enum Phase: Equatable {
        case idle
        case running
        case finished(text: String, note: String?)
    }

    private(set) var phase = Phase.idle

    var sample: String

    private let defaultSample: String
    private let processor: TranscriptProcessor
    private let detector: any LanguageDetector
    private let settings: SettingsModel
    private let pro: ProModel

    private var task: Task<Void, Never>?

    init(
        rewriters: Rewriters,
        detector: any LanguageDetector,
        settings: SettingsModel,
        pro: ProModel,
        defaultSample: String,
    ) {
        processor = TranscriptProcessor(rewriters: rewriters)
        self.detector = detector
        self.settings = settings
        self.pro = pro
        self.defaultSample = defaultSample
        sample = defaultSample
    }

    func run(_ mode: Mode) {
        guard let language = spokenLanguage(of: sample), !sample.isBlank else { return }

        let transcript = Transcript(text: sample, language: language, detectionDuration: .zero, decodingDuration: .zero)
        let setup = settings.settings.rewriteSetup(for: mode)
        let allowsAI = pro.isUnlocked
        let processor = processor

        start {
            let processed = await processor.process(
                transcript,
                mode: mode,
                setup: setup,
                vocabulary: .empty,
                allowsAI: allowsAI,
            )

            return .finished(text: processed.text, note: processed.fallback?.message(for: setup.provider))
        }
    }

    func run(task kind: TextTask.Kind) {
        guard !sample.isBlank else { return }
        guard pro.isUnlocked else {
            phase = .finished(text: "", note: String(localized: "Translating and fixing text is part of Waft+."))

            return
        }

        let text = sample
        let source = sourceLanguage(of: text)
        let target = settings.settings.translator.target(forSource: source)
        let task: TextTask = kind == .fix ? .fix : .translate(from: settings.settings.translator.source, into: target)
        let language =
            if let source {
                source
            } else {
                target
            }
        let setup = settings.settings.translatorSetup(for: kind)
        let processor = processor

        start {
            do throws(RewriteError) {
                let reworked = try await processor.rework(text, in: language, as: task, setup: setup)

                return .finished(text: reworked, note: nil)
            } catch {
                return .finished(text: "", note: RewriteFallback(error).reason(for: setup.provider).sentenceCased())
            }
        }
    }

    func reset() {
        task?.cancel()
        task = nil
        phase = .idle

        if sample.isBlank {
            sample = defaultSample
        }
    }

    private func spokenLanguage(of text: String) -> Language? {
        let selection = settings.settings.languages

        if let forced = selection.forcedLanguage {
            return forced
        }

        if let detected = detector.language(of: text), selection.languages.contains(detected) {
            return detected
        }

        return selection.languages.first
    }

    private func sourceLanguage(of text: String) -> Language? {
        guard let source = settings.settings.translator.source else { return detector.language(of: text) }

        return source
    }

    private func start(_ work: @escaping () async -> Phase) {
        task?.cancel()
        phase = .running
        task = Task {
            let finished = await work()

            guard !Task.isCancelled else { return }

            phase = finished
        }
    }
}
