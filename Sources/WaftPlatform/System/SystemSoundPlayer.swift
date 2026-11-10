package import WaftCore
import AudioToolbox
import Foundation
import os

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

        guard let url = Bundle.main.url(forResource: name, withExtension: "aiff") else {
            Logger.audio.error("The app has no sound named \(name, privacy: .public)")

            return nil
        }

        var soundID: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        guard status == kAudioServicesNoError else {
            Logger.audio.error("Couldn't load the sound \(name, privacy: .public): OSStatus \(status, privacy: .public)")

            return nil
        }

        soundIDs[name] = soundID

        return soundID
    }
}
