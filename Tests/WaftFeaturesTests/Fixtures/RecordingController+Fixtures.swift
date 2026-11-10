import Foundation
import WaftCore
@testable import WaftFeatures

extension RecordingController {
    static func started(
        recorder: FakeAudioRecorder,
        focusTracker: FakeFocusTracker,
        hud: HUDController,
        keyboardState: FakeKeyboardState = FakeKeyboardState(holdsKeys: true),
        sounds: FakeFeedbackSoundPlayer = FakeFeedbackSoundPlayer(),
        outputVolume: FakeOutputVolume = FakeOutputVolume(),
        settings: SettingsModel = .inMemory(),
        hudDelay: Duration = .zero,
        watchdogInterval: TimeInterval = 60,
    ) -> RecordingController {
        let recordings = RecordingController(
            recorder: recorder,
            focusTracker: focusTracker,
            keyboardState: keyboardState,
            sounds: sounds,
            otherSounds: OtherSoundsLowering(outputVolume: outputVolume, delay: .zero),
            settings: settings,
            hud: hud,
            hudDelay: hudDelay,
            watchdogInterval: watchdogInterval,
        )

        recordings.start()

        return recordings
    }
}
