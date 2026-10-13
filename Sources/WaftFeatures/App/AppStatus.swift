import Foundation
import WaftCore

enum AppStatus: Equatable {
    case needsPermission
    case speechModel(SpeechModelState)
    case recording
    case ready

    var symbolName: String {
        switch self {
        case .needsPermission: "mic.slash"
        case let .speechModel(state): Self.symbolName(for: state.phase)
        case .recording: "mic.fill"
        case .ready: "mic"
        }
    }

    static func readyMessage(in settings: Settings) -> String {
        let key = settings.pushToTalkKey.shortTitle

        return settings.dictationStart == .tap
            ? String(localized: "Ready: tap \(key) and speak")
            : String(localized: "Ready: hold \(key) and speak")
    }

    private static func symbolName(for phase: SpeechModelState.Phase) -> String {
        switch phase {
        case .notInstalled, .loading: "hourglass"
        case .downloading: "arrow.down.circle"
        case .failed: "mic.badge.xmark"
        case .ready: "mic"
        }
    }

    func title(in settings: Settings) -> String {
        let key = settings.pushToTalkKey

        return switch self {
        case .needsPermission: String(localized: "Setup needed")
        case let .speechModel(state) where state.canRetry: String(localized: "Speech model failed")
        case let .speechModel(state): state.statusText
        case .recording: String(localized: "Listening…")
        case .ready where settings.dictationStart == .tap: String(localized: "Tap \(key.shortTitle) to dictate")
        case .ready: String(localized: "Hold \(key.shortTitle) to dictate")
        }
    }
}
