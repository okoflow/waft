import Foundation
import WaftCore

enum DictationOutcome {
    case pasted(ProcessedText)
    case copied(ProcessedText)
    case blockedInPasswordField
    case noSpeech
    case failed(String)
    case editFailed(String)

    func message(for provider: ModelProvider) -> HUDMessage {
        switch self {
        case let .pasted(processed):
            HUDMessage(kind: .pasted, title: processed.text, detail: processed.fallback?.message(for: provider))

        case let .copied(processed):
            .copied(processed.text, note: processed.fallback?.message(for: provider))

        case .blockedInPasswordField:
            HUDMessage(
                kind: .warning,
                title: String(localized: "Not pasted into a password field"),
                detail: String(localized: "Choose Copy Last Dictation in the Waft menu."),
            )

        case .noSpeech:
            HUDMessage(kind: .information, title: String(localized: "Didn't catch that"))

        case let .failed(reason):
            HUDMessage(kind: .warning, title: String(localized: "Transcription failed"), detail: reason)

        case let .editFailed(reason):
            HUDMessage(kind: .warning, title: String(localized: "Couldn't edit the text"), detail: reason)
        }
    }
}
