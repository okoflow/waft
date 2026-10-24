import Foundation

package enum CloudModel: String, CaseIterable, Codable, Sendable {
    case fastest
    case balanced
    case smartest

    static let defaultChoices = PerProvider(claude: CloudModel.balanced, openAI: .balanced)

    package var summary: String {
        switch self {
        case .fastest: String(localized: "The quickest and cheapest.")
        case .balanced: String(localized: "Makes fewer mistakes and is still quick.")
        case .smartest: String(localized: "Makes the fewest mistakes, but is slower and pricier.")
        }
    }

    var deadline: Duration {
        switch self {
        case .fastest: .seconds(4)
        case .balanced: .seconds(6)
        case .smartest: .seconds(10)
        }
    }

    var editDeadline: Duration {
        switch self {
        case .fastest: .seconds(20)
        case .balanced: .seconds(30)
        case .smartest: .seconds(45)
        }
    }
}
