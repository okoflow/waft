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

    private static func symbolName(for phase: SpeechModelState.Phase) -> String {
        switch phase {
        case .notInstalled, .loading: "hourglass"
        case .downloading: "arrow.down.circle"
        case .failed: "mic.badge.xmark"
        case .ready: "mic"
        }
    }

    func title(key: PushToTalkKey) -> String {
        switch self {
        case .needsPermission: String(localized: "Setup needed")
        case let .speechModel(state) where state.canRetry: String(localized: "Speech model failed")
        case let .speechModel(state): state.statusText
        case .recording: String(localized: "Listening…")
        case .ready: String(localized: "Hold \(key.shortTitle) to dictate")
        }
    }
}
