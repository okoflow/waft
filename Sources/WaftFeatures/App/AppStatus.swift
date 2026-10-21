import Foundation
import WaftCore

enum AppStatus: Equatable {
    case needsPermission
    case speechModel(SpeechModelState)
    case recording
    case ready

    static func readyMessage(in settings: Settings) -> String {
        let key = settings.pushToTalkKey.shortTitle

        return switch settings.dictationStart {
        case .tap: String(localized: "Ready: tap \(key) and speak")
        case .hold, .holdOrDoubleTap: String(localized: "Ready: hold \(key) and speak")
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
