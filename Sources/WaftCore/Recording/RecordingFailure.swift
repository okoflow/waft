import Foundation

package enum RecordingFailure: String, Error, Sendable {
    case noInputChannels
    case unsupportedFormat
    case deviceUnavailable
    case engineDidNotStart
    case stoppedWhileStarting
    case stoppedAfterDeviceChange
    case formatChanged

    package var message: String {
        switch self {
        case .noInputChannels: String(localized: "The microphone has no input channels.")
        case .unsupportedFormat: String(localized: "The microphone's audio format isn't supported.")
        case .deviceUnavailable: String(localized: "The chosen microphone can't be used.")
        case .engineDidNotStart: String(localized: "The microphone didn't start.")
        case .stoppedWhileStarting: String(localized: "The microphone stopped while starting.")
        case .stoppedAfterDeviceChange: String(localized: "The microphone stopped after an audio device changed.")
        case .formatChanged: String(localized: "The microphone's audio format changed during the recording.")
        }
    }
}
