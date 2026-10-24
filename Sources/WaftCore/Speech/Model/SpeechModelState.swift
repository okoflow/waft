import Foundation

package struct SpeechModelState: Equatable, Sendable {
    package enum Phase: Equatable, Sendable {
        case notInstalled
        case downloading(progress: Double)
        case loading
        case ready
        case failed(reason: String, during: Step)
    }

    package enum Step: Sendable {
        case download
        case load
    }

    package enum Event: Sendable {
        case started(SpeechModel, isInstalled: Bool)
        case chosen(SpeechModel, isInstalled: Bool)
        case downloadProgressed(SpeechModel, Double)
        case downloaded(SpeechModel)
        case loaded(SpeechModel)
        case failed(SpeechModel, String)
        case retryRequested
        case reloadRequested
    }

    package enum Effect: Equatable, Sendable {
        case cancelDownload
        case deleteModel(SpeechModel)
        case download(SpeechModel)
        case load(SpeechModel)
    }

    private struct Choice: Equatable, Sendable {
        let model: SpeechModel
        let isInstalled: Bool
    }

    package private(set) var phase = Phase.notInstalled

    private var model = SpeechModel.fast
    private var servingModel: SpeechModel?
    private var pendingChoice: Choice?
    private var hasRetriedLoad = false
    private var needsReload = false

    package var isReady: Bool {
        phase == .ready
    }

    package var canTranscribe: Bool {
        guard !isReady else { return true }

        return servingModel != nil
    }

    package var canRetry: Bool {
        guard case .failed = phase else { return false }

        return true
    }

    package var progress: Double? {
        guard case let .downloading(progress) = phase else { return nil }

        return progress
    }

    package var statusText: String {
        switch phase {
        case .notInstalled, .loading: String(localized: "Preparing the speech model…")
        case let .downloading(progress): String(localized: "Downloading the speech model… \(Self.percent(progress))")
        case .ready: String(localized: "Ready")
        case let .failed(reason, _): String(localized: "Speech model failed: \(reason)")
        }
    }

    package var notReadyMessage: String? {
        guard !canTranscribe else { return nil }

        switch phase {
        case .ready: return nil
        case .notInstalled: return String(localized: "The speech model isn't ready yet.")
        case .downloading: return statusText
        case .loading: return String(localized: "Preparing the speech model, about a minute the first time…")
        case .failed: return String(localized: "The speech model isn't available. Retry from the menu.")
        }
    }

    package init() {}

    private static func percent(_ progress: Double) -> String {
        progress.formatted(.percent.precision(.fractionLength(0)))
    }

    package mutating func handle(_ event: Event) -> [Effect] {
        switch (phase, event) {
        case let (.notInstalled, .started(model, isInstalled)):
            return prepare(Choice(model: model, isInstalled: isInstalled))

        case let (_, .chosen(model, isInstalled)):
            return choose(Choice(model: model, isInstalled: isInstalled))

        case let (.downloading(current), .downloadProgressed(downloading, progress)) where downloading == model:
            phase = .downloading(progress: min(1, max(current, progress)))

            return []

        case let (.downloading, .downloaded(downloaded)) where downloaded == model:
            phase = .loading

            return [.load(model)]

        case let (.loading, .loaded(loaded)) where loaded == model:
            return finishLoading()

        case let (.downloading, .failed(failed, reason)) where failed == model:
            phase = .failed(reason: reason, during: .download)

            return []

        case let (.loading, .failed(failed, reason)) where failed == model:
            return failLoading(reason)

        case let (.failed(_, step), .retryRequested):
            return retry(after: step)

        case (.ready, .reloadRequested):
            phase = .loading

            return [.load(model)]

        case (.loading, .reloadRequested):
            needsReload = true

            return []

        case (.downloading, .reloadRequested), (.failed, .reloadRequested):
            guard let servingModel, servingModel != model else { return [] }

            return [.load(servingModel)]

        default:
            return []
        }
    }

    private mutating func choose(_ choice: Choice) -> [Effect] {
        guard choice.model != model else {
            pendingChoice = nil

            return []
        }

        switch phase {
        case .notInstalled:
            return []

        case .loading:
            pendingChoice = choice

            return []

        case .downloading:
            return [.cancelDownload, .deleteModel(model)] + prepare(choice)

        case .ready, .failed:
            return prepare(choice)
        }
    }

    private mutating func prepare(_ choice: Choice) -> [Effect] {
        model = choice.model
        pendingChoice = nil
        hasRetriedLoad = false
        needsReload = false

        guard choice.isInstalled else {
            phase = .downloading(progress: 0)

            return [.download(model)]
        }

        phase = .loading

        return [.load(model)]
    }

    private mutating func finishLoading() -> [Effect] {
        hasRetriedLoad = false
        servingModel = model

        if let pendingChoice {
            return prepare(pendingChoice)
        }

        guard !needsReload else {
            needsReload = false

            return [.load(model)]
        }

        phase = .ready

        return SpeechModel.allCases.filter { $0 != model }.map(Effect.deleteModel)
    }

    private mutating func failLoading(_ reason: String) -> [Effect] {
        if let pendingChoice {
            return prepare(pendingChoice)
        }

        needsReload = false
        phase = .failed(reason: reason, during: .load)

        return []
    }

    private mutating func retry(after step: Step) -> [Effect] {
        switch step {
        case .download:
            phase = .downloading(progress: 0)

            return [.download(model)]

        case .load where !hasRetriedLoad:
            hasRetriedLoad = true
            phase = .loading

            return [.load(model)]

        case .load:
            hasRetriedLoad = false
            phase = .downloading(progress: 0)

            if servingModel == model {
                servingModel = nil
            }

            return [.deleteModel(model), .download(model)]
        }
    }
}
