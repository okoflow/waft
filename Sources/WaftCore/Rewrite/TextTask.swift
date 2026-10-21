import Foundation

package enum TextTask: Equatable, Sendable {
    case fix
    case translate(from: Language?, into: Language)

    package enum Kind: String, CaseIterable, Sendable {
        case translate
        case fix

        package var title: String {
            switch self {
            case .translate: String(localized: "Translation")
            case .fix: String(localized: "Fixing")
            }
        }

        package var summary: String {
            switch self {
            case .translate: String(localized: "The translator and the shortcut that translates selected text.")
            case .fix: String(localized: "The shortcut that fixes selected text.")
            }
        }
    }

    package var kind: Kind {
        switch self {
        case .fix: .fix
        case .translate: .translate
        }
    }
}
