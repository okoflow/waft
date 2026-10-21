package import WaftCore
import AudioToolbox
import Foundation

@MainActor
package final class SystemSoundPlayer: FeedbackSoundPlayer {
    private var soundIDs: [String: SystemSoundID] = [:]

    package init() {}

    package func play(_ sound: FeedbackSound) {
        let name =
            switch sound {
            case .recordingStarted: "RecordingStarted"
            case .recordingFinished: "RecordingFinished"
            }

        if let soundID = soundID(named: name) {
            AudioServicesPlaySystemSound(soundID)
        }
    }

    private func soundID(named name: String) -> SystemSoundID? {
        if let soundID = soundIDs[name] {
            return soundID
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "aiff") else { return nil }

        var soundID: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(url as CFURL, &soundID) == kAudioServicesNoError else { return nil }

        soundIDs[name] = soundID

        return soundID
    }
}
