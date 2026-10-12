import Foundation

enum MediaAudioError: LocalizedError {
    case noAudio
    case unreadable

    var errorDescription: String? {
        switch self {
        case .noAudio: String(localized: "The file has no sound to transcribe.")
        case .unreadable: String(localized: "Waft can't read this file.")
        }
    }
}
