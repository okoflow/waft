import Foundation
import WaftCore

extension RecordingPurpose {
    var title: String {
        switch self {
        case .dictation: String(localized: "Dictation key")
        case .edit: String(localized: "Editing key")
        }
    }
}
