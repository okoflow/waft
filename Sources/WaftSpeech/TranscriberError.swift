import Foundation
import WaftCore

enum TranscriberError: LocalizedError {
    case modelMissing(SpeechModel)
    case notLoaded
    case tokenizerMissing
    case languageTokensMissing

    var errorDescription: String? {
        switch self {
        case let .modelMissing(model): String(localized: "The speech model \(model.title) isn't downloaded.")
        case .notLoaded: String(localized: "The speech model isn't loaded.")
        case .tokenizerMissing: String(localized: "The speech model has no tokenizer.")
        case .languageTokensMissing: String(localized: "The speech model doesn't know one of the chosen languages.")
        }
    }
}
