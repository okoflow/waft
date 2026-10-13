import Foundation

package enum Permission: CaseIterable, Sendable {
    case microphone
    case accessibility

    package var title: String {
        switch self {
        case .microphone: String(localized: "Microphone")
        case .accessibility: String(localized: "Accessibility")
        }
    }

    package var purpose: String {
        switch self {
        case .microphone: String(localized: "Records your voice while you dictate.")
        case .accessibility: String(localized: "Notices the dictation key and pastes the text where you type.")
        }
    }
}
