import Foundation

package enum Mode: Hashable, Codable, InstructionsSubject {
    case raw
    case light
    case clean
    case formal
    case translate
    case custom(CustomMode.ID)

    package static let builtIn: [Mode] = [.raw, .light, .clean, .formal, .translate]

    private static let customPrefix = "custom:"

    package var usesAI: Bool {
        switch self {
        case .raw, .light:
            false
        case .clean, .formal, .translate, .custom:
            true
        }
    }

    package var title: String {
        switch self {
        case .raw: String(localized: "Raw")
        case .light: String(localized: "Light")
        case .clean: String(localized: "Clean")
        case .formal: String(localized: "Formal")
        case .translate: String(localized: "Translate")
        case .custom: String(localized: "Your mode")
        }
    }

    package var summary: String {
        switch self {
        case .raw: String(localized: "Exactly what was heard.")
        case .light: String(localized: "Drops “um” and “uh” and adds a capital letter and a period.")
        case .clean: String(localized: "Removes fillers and false starts, fixes grammar, keeps your language.")
        case .formal: String(localized: "Like Clean, in a polite business tone.")
        case .translate: String(localized: "Translates what you said into another language.")
        case .custom: String(localized: "Follows your instructions.")
        }
    }

    package var rawValue: String {
        switch self {
        case .raw: "raw"
        case .light: "light"
        case .clean: "clean"
        case .formal: "formal"
        case .translate: "translate"
        case let .custom(id): Self.customPrefix + id.uuidString
        }
    }

    package var defaultInstructions: String {
        RewritePrompt.defaultInstructions(for: self)
    }

    package init?(rawValue: String) {
        if let builtIn = Self.builtIn.first(where: { $0.rawValue == rawValue }) {
            self = builtIn

            return
        }

        guard rawValue.hasPrefix(Self.customPrefix),
              let id = UUID(uuidString: String(rawValue.dropFirst(Self.customPrefix.count)))
        else { return nil }

        self = .custom(id)
    }
}
