import Foundation

package enum SettingsPane: CaseIterable {
    case overview
    case dictation
    case dictionary
    case writing
    case aiModels
    case history
    case general
    case pro
    case about

    var title: String {
        switch self {
        case .overview: String(localized: "Overview")
        case .general: String(localized: "General")
        case .dictation: String(localized: "Dictation")
        case .writing: String(localized: "Writing")
        case .aiModels: String(localized: "AI Models")
        case .dictionary: String(localized: "Dictionary")
        case .history: String(localized: "History")
        case .pro: String(localized: "Waft+")
        case .about: String(localized: "About")
        }
    }

    var needsWaftPlus: Bool {
        self == .aiModels
    }

    var symbolName: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .general: "gearshape.fill"
        case .dictation: "mic.fill"
        case .writing: "slider.horizontal.3"
        case .aiModels: "cpu.fill"
        case .dictionary: "book.closed.fill"
        case .history: "clock.fill"
        case .pro: "crown.fill"
        case .about: "info.circle.fill"
        }
    }

    var tint: TileTint {
        switch self {
        case .overview: .green
        case .general, .about: .gray
        case .dictation: .red
        case .writing: .teal
        case .aiModels: .purple
        case .dictionary: .orange
        case .history: .indigo
        case .pro: .purple
        }
    }
}
