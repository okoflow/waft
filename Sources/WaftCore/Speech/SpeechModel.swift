import Foundation

package enum SpeechModel: String, CaseIterable, Codable, Sendable {
    case fast
    case accurate

    package var needsPro: Bool {
        switch self {
        case .fast: false
        case .accurate: true
        }
    }

    package var title: String {
        switch self {
        case .fast: String(localized: "Fast")
        case .accurate: String(localized: "Accurate")
        }
    }

    package var summary: String {
        switch self {
        case .fast: String(localized: "Whisper large-v3 turbo · 630 MB · quickest")
        case .accurate: String(localized: "Whisper large-v3 · 3.1 GB · fewer mistakes outside English, about 3× slower")
        }
    }

    package func usable(withProUnlocked isUnlocked: Bool) -> SpeechModel {
        guard needsPro, !isUnlocked else { return self }

        return .fast
    }
}
