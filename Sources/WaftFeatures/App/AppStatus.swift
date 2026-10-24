import Foundation
import WaftCore

enum AppStatus: Equatable {
    case needsPermission
    case speechModel(SpeechModelState)
    case recording
    case ready

    static func current(
        isRecording: Bool,
        permissionsGranted: Bool,
        keyMonitor: KeyMonitorController.Status,
        speechModel: SpeechModelState,
    ) -> AppStatus {
        if isRecording {
            return .recording
        }

        if lacksPermissions(permissionsGranted: permissionsGranted, keyMonitor: keyMonitor) {
            return .needsPermission
        }

        guard speechModel.canTranscribe else { return .speechModel(speechModel) }

        return .ready
    }

    static func needsSetup(hasCompletedSetup: Bool, permissionsGranted: Bool) -> Bool {
        guard hasCompletedSetup else { return true }

        return !permissionsGranted
    }

    static func readyMessage(in settings: Settings) -> String {
        let key = settings.pushToTalkKey.shortTitle

        return switch settings.dictationStart {
        case .tap: String(localized: "Ready: tap \(key) and speak")
        case .hold, .holdOrDoubleTap: String(localized: "Ready: hold \(key) and speak")
        }
    }

    private static func lacksPermissions(permissionsGranted: Bool, keyMonitor: KeyMonitorController.Status) -> Bool {
        guard permissionsGranted else { return true }

        return keyMonitor == .unavailable
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
