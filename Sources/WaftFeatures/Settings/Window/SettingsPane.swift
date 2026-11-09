import Foundation

package enum SettingsPane: CaseIterable {
    case overview
    case history
    case dictation
    case dictionary
    case writing
    case translator
    case aiModels
    case general
    case pro
    case about

    var title: String {
        switch self {
        case .overview: String(localized: "Overview")
        case .history: String(localized: "History")
        case .dictation: String(localized: "Dictation")
        case .dictionary: String(localized: "Dictionary")
        case .writing: String(localized: "Writing")
        case .translator: String(localized: "Translator")
        case .aiModels: String(localized: "AI Models")
        case .general: String(localized: "General")
        case .pro: String(localized: "Waft+")
        case .about: String(localized: "About")
        }
    }

    var needsWaftPlus: Bool {
        [.aiModels, .translator].contains(self)
    }

    var symbolName: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .history: "clock.fill"
        case .dictation: "mic.fill"
        case .dictionary: "book.closed.fill"
        case .writing: "slider.horizontal.3"
        case .translator: "character.bubble.fill"
        case .aiModels: "cpu.fill"
        case .general: "gearshape.fill"
        case .pro: "crown.fill"
        case .about: "info.circle.fill"
        }
    }

    var tint: TileTint {
        switch self {
        case .overview: .green
        case .history: .indigo
        case .dictation: .red
        case .dictionary: .orange
        case .writing: .teal
        case .translator: .blue
        case .aiModels: .purple
        case .general, .about: .gray
        case .pro: .purple
        }
    }
}
