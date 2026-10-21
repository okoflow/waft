import Foundation
import Observation
import os
import WaftCore

@Observable
final class DictationQueue {
    static var transcribingLabel: String {
        String(localized: "Transcribing…")
    }

    private var recentTranscripts = RecentTranscripts()

    @ObservationIgnored private var pendingCount = 0
    @ObservationIgnored private var transcriptExpiry: Task<Void, Never>?

    private let transcriber: any Transcriber
    private let processor: TranscriptProcessor
    private let inserter: any TextInserter
    private let clipboard: any Clipboard
    private let history: HistoryModel
    private let statistics: StatisticsModel
    private let hud: HUDController
    private let continuation: AsyncStream<DictationJob>.Continuation

    var latestTranscript: String? {
        recentTranscripts.latest(at: Date())
    }

    init(
        transcriber: any Transcriber,
        rewriters: Rewriters,
        inserter: any TextInserter,
        clipboard: any Clipboard,
        history: HistoryModel,
        statistics: StatisticsModel,
        hud: HUDController,
    ) {
        self.transcriber = transcriber
        processor = TranscriptProcessor(rewriters: rewriters)
        self.inserter = inserter
        self.clipboard = clipboard
        self.history = history
        self.statistics = statistics
        self.hud = hud

        let (jobs, continuation) = AsyncStream.makeStream(of: DictationJob.self)
        self.continuation = continuation

        Task { [weak self] in
            for await job in jobs {
                await self?.run(job)
            }
        }
    }

    private static func editingLabel(for provider: ModelProvider) -> String {
        guard provider.isCloud else { return String(localized: "Editing on this Mac…") }

        return String(localized: "Editing with \(provider.title)…")
    }

    private static func workingLabel(for job: DictationJob, spoken: Language) -> String {
        if job.mode == .translate {
            return String(localized: "Translating into \(job.setup.translation.target(forSpoken: spoken).inlineName)…")
        }

        guard job.setup.provider.isCloud else { return String(localized: "Cleaning up on this Mac…") }

        return String(localized: "Cleaning up with \(job.setup.provider.title)…")
    }

    private static func describe(_ fallback: RewriteFallback?) -> String {
        guard let fallback else { return "none" }

        return fallback.rawValue
    }

    func submit(_ job: DictationJob) {
        pendingCount += 1

        hud.setWorking(Self.transcribingLabel)

        continuation.yield(job)
    }

    func copyLatestTranscript() {
        guard let latestTranscript else { return }

        clipboard.copy(latestTranscript)
    }

    private func run(_ job: DictationJob) async {
        let outcome = await outcome(of: job)

        pendingCount -= 1

        hud.setWorking(pendingCount > 0 ? Self.transcribingLabel : nil)
        hud.show(outcome.message(for: job.setup.provider))
    }

    private func outcome(of job: DictationJob) async -> DictationOutcome {
        let transcript: Transcript?

        do {
            transcript = try await transcriber.transcribe(
                job.samples,
                in: job.language,
                writing: job.variants,
                vocabulary: job.vocabulary.promptTerms,
            )
        } catch {
            Logger.dictation.error("Transcription failed: \(error.logDescription, privacy: .public)")

            return .failed(error.localizedDescription)
        }

        guard let transcript else {
            Logger.dictation.info("No speech in the recording")

            return .noSpeech
        }

        if let selection = job.selection {
            return await edit(selection, following: transcript, for: job)
        }

        if job.mode.usesAI, job.allowsAI {
            hud.setWorking(
                Self.workingLabel(for: job, spoken: transcript.language),
                cleanup: HUDCleanup(mode: job.modeTitle, transcript: transcript.text),
            )
        }

        let processed = await processor.process(
            transcript,
            mode: job.mode,
            setup: job.setup,
            vocabulary: job.vocabulary,
            allowsAI: job.allowsAI,
        )

        log(transcript, processed, for: job)

        return await deliver(processed, for: job)
    }

    private func edit(_ selection: String, following transcript: Transcript, for job: DictationJob) async -> DictationOutcome {
        let provider = job.setup.provider

        hud.setWorking(Self.editingLabel(for: provider))

        do throws(RewriteError) {
            let edited = try await processor.edit(selection, following: transcript, setup: job.setup)

            return await deliver(ProcessedText(text: edited, mode: job.mode), for: job)
        } catch {
            return .editFailed(RewriteFallback(error).reason(for: provider).sentenceCased())
        }
    }

    private func deliver(_ processed: ProcessedText, for job: DictationJob) async -> DictationOutcome {
        guard !processed.text.isEmpty else { return .noSpeech }

        rememberLatest(processed.text)

        guard job.pastes else { return copy(processed, for: job) }

        switch await inserter.insert(processed.text, into: job.target, releasing: job.key) {
        case .pasted:
            record(processed, for: job)

            return .pasted(processed)

        case .skipped(.secureField):
            return .blockedInPasswordField

        case .skipped:
            return copy(processed, for: job)
        }
    }

    private func copy(_ processed: ProcessedText, for job: DictationJob) -> DictationOutcome {
        clipboard.copy(processed.text)
        record(processed, for: job)

        return .copied(processed)
    }

    private func rememberLatest(_ text: String) {
        recentTranscripts.remember(text, at: Date())

        transcriptExpiry?.cancel()
        transcriptExpiry = Task { [weak self] in
            guard await Task.slept(for: .seconds(RecentTranscripts.lifetime)) else { return }

            self?.recentTranscripts = RecentTranscripts()
        }
    }

    private func record(_ processed: ProcessedText, for job: DictationJob) {
        guard job.selection == nil else { return }

        let entry = DictationHistory.Entry(
            date: Date(),
            text: processed.text,
            mode: processed.mode,
            app: job.target.bundleIdentifier,
        )

        statistics.record(processed.text, seconds: SpeechAudio.duration(of: job.samples))
        history.add(entry)
    }

    private func log(_ transcript: Transcript, _ processed: ProcessedText, for job: DictationJob) {
        Logger.dictation.info(
            """
            Recognized \(transcript.text.count) characters of \(transcript.language.rawValue, privacy: .public) \
            in \(transcript.detectionDuration + transcript.decodingDuration, privacy: .public); \
            mode \(job.mode.storageKey, privacy: .public) ran as \(processed.mode.storageKey, privacy: .public), \
            fallback \(Self.describe(processed.fallback), privacy: .public)
            """,
        )
    }
}
