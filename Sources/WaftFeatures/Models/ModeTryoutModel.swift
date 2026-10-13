import Foundation
import Observation
import WaftCore

@Observable
final class ModeTryoutModel {
    enum Phase: Equatable {
        case idle
        case running
        case finished(ProcessedText)
    }

    private static var defaultSample: String {
        String(localized: "um so I think we should uh meet on Friday")
    }

    private(set) var phase = Phase.idle

    var sample = ModeTryoutModel.defaultSample

    private let processor: TranscriptProcessor
    private let settings: SettingsModel
    private let pro: ProModel

    private var task: Task<Void, Never>?

    init(rewriters: Rewriters, settings: SettingsModel, pro: ProModel) {
        processor = TranscriptProcessor(rewriters: rewriters)
        self.settings = settings
        self.pro = pro
    }

    func run(_ mode: Mode) {
        guard let language = settings.settings.languages.languages.first, !sample.isBlank else { return }

        let transcript = Transcript(text: sample, language: language, detectionDuration: .zero, decodingDuration: .zero)
        let setup = settings.settings.rewriteSetup(for: mode)
        let allowsAI = pro.isUnlocked
        let processor = processor

        task?.cancel()
        phase = .running
        task = Task {
            let processed = await processor.process(
                transcript,
                mode: mode,
                setup: setup,
                vocabulary: .empty,
                allowsAI: allowsAI,
            )

            guard !Task.isCancelled else { return }

            phase = .finished(processed)
        }
    }

    func reset() {
        task?.cancel()
        task = nil
        phase = .idle

        if sample.isBlank {
            sample = Self.defaultSample
        }
    }
}
