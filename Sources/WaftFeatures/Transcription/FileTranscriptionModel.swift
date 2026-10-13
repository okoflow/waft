import Foundation
import Observation
import WaftCore

@Observable
final class FileTranscriptionModel {
    enum Phase: Equatable {
        case idle
        case reading(URL)
        case transcribing(URL, Double)
        case finished(URL, TimedTranscript)
        case failed(URL, String)
    }

    let copyFeedback = CopyFeedback<URL>()

    private(set) var phase = Phase.idle
    var isDropTargeted = false

    private var chosenLanguage: Language?

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var run = 0

    private let transcriber: any Transcriber
    private let decoder: any MediaDecoder
    private let speechModelController: SpeechModelController
    private let settings: SettingsModel
    private let pro: ProModel
    private let clipboard: any Clipboard

    var language: Language? {
        get {
            guard let chosenLanguage, languages.contains(chosenLanguage) else { return nil }

            return chosenLanguage
        }

        set { chosenLanguage = newValue }
    }

    var isLocked: Bool {
        !pro.isUnlocked
    }

    var acceptsFiles: Bool {
        !isLocked && !isWorking
    }

    var languages: [Language] {
        settings.settings.languages.languages
    }

    var notReadyMessage: String? {
        speechModelController.state.notReadyMessage
    }

    private var isWorking: Bool {
        switch phase {
        case .reading, .transcribing: true
        case .idle, .finished, .failed: false
        }
    }

    init(
        transcriber: any Transcriber,
        decoder: any MediaDecoder,
        speechModelController: SpeechModelController,
        settings: SettingsModel,
        pro: ProModel,
        clipboard: any Clipboard,
    ) {
        self.transcriber = transcriber
        self.decoder = decoder
        self.speechModelController = speechModelController
        self.settings = settings
        self.pro = pro
        self.clipboard = clipboard
    }

    private static func result(_ transcript: TimedTranscript?, of file: URL) -> Phase {
        guard let transcript else { return .failed(file, String(localized: "There's no speech in this file.")) }

        return .finished(file, transcript)
    }

    func transcribe(_ file: URL) {
        guard !isLocked else { return }

        cancel()

        if let notReadyMessage {
            phase = .failed(file, notReadyMessage)

            return
        }

        let current = run

        phase = .reading(file)
        task = Task { [weak self, transcriber, decoder, language] in
            do {
                let samples = try await decoder.samples(of: file)
                self?.enter(.transcribing(file, 0), in: current)

                let transcript = try await transcriber.transcribeFile(samples, in: language) { progress in
                    Task { @MainActor in self?.update(progress, in: current) }
                }

                self?.enter(Self.result(transcript, of: file), in: current)
            } catch {
                self?.enter(.failed(file, error.localizedDescription), in: current)
            }
        }
    }

    func reset() {
        cancel()
        phase = .idle
    }

    func cancel() {
        run += 1
        task?.cancel()
        task = nil

        if isWorking {
            phase = .idle
        }
    }

    func copyText() {
        guard case let .finished(file, transcript) = phase else { return }

        clipboard.copy(transcript.text)
        copyFeedback.show(file)
    }

    private func enter(_ next: Phase, in current: Int) {
        guard current == run else { return }

        phase = next
    }

    private func update(_ progress: Double, in current: Int) {
        guard case let .transcribing(file, _) = phase else { return }

        enter(.transcribing(file, progress), in: current)
    }
}
