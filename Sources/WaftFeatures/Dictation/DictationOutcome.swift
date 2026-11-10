import Foundation
import WaftCore

enum DictationOutcome {
    case delivered(TextDelivery.Outcome, ProcessedText)
    case noSpeech
    case failed(String)
    case partFailed
    case editFailed(String)

    func message(for provider: ModelProvider) -> HUDMessage {
        switch self {
        case let .delivered(delivery, processed):
            delivery.message(showing: processed.text, detail: processed.fallback?.message(for: provider))

        case .noSpeech:
            HUDMessage(kind: .information, title: String(localized: "Didn't catch that"))

        case let .failed(reason):
            HUDMessage(kind: .warning, title: String(localized: "Transcription failed"), detail: reason)

        case .partFailed:
            .missingPart

        case let .editFailed(reason):
            HUDMessage(kind: .warning, title: String(localized: "Couldn't edit the text"), detail: reason)
        }
    }
}
