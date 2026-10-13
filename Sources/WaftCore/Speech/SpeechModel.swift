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
        case .fast: String(localized: "\(Self.size(of: 630_000_000)) · quickest")
        case .accurate: String(localized: "\(Self.size(of: 3_100_000_000)) · fewer mistakes, \(2)–\(3)× slower")
        }
    }

    private static func size(of bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }

    package func usable(withProUnlocked isUnlocked: Bool) -> SpeechModel {
        guard needsPro, !isUnlocked else { return self }

        return .fast
    }
}
