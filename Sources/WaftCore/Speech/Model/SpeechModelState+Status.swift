import Foundation

extension SpeechModelState {
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

    private static func percent(_ progress: Double) -> String {
        progress.formatted(.percent.precision(.fractionLength(0)))
    }
}
