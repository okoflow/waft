import Testing
import WaftCore
@testable import WaftFeatures

struct AppStatusTests {
    private static var readySpeechModel: SpeechModelState {
        var state = SpeechModelState()

        _ = state.handle(.started(.fast, isInstalled: true))
        _ = state.handle(.loaded(.fast))

        return state
    }

    @Test(arguments: [
        (DictationStart.hold, "Hold right ⌥ to dictate", "Ready: hold right ⌥ and speak"),
        (.holdOrDoubleTap, "Hold right ⌥ to dictate", "Ready: hold right ⌥ and speak"),
        (.tap, "Tap right ⌥ to dictate", "Ready: tap right ⌥ and speak"),
    ])
    func `names how to start dictation when ready`(start: DictationStart, title: String, message: String) {
        var settings = Settings(languages: .preferred(by: []))
        settings.dictationStart = start

        #expect(AppStatus.ready.title(in: settings) == title)
        #expect(AppStatus.readyMessage(in: settings) == message)
    }

    @Test
    func `reports a failed speech model`() {
        var state = SpeechModelState()

        _ = state.handle(.started(.fast, isInstalled: false))
        _ = state.handle(.failed(.fast, "network lost"))

        #expect(AppStatus.speechModel(state).title(in: Settings(languages: .preferred(by: []))) == "Speech model failed")
    }

    @Test(arguments: [
        (true, false, KeyMonitorController.Status.unavailable, AppStatus.recording),
        (false, false, .ready, .needsPermission),
        (false, true, .unavailable, .needsPermission),
        (false, true, .starting, .ready),
        (false, true, .ready, .ready),
    ])
    func `puts recording first and missing permissions before the speech model`(
        isRecording: Bool,
        permissionsGranted: Bool,
        keyMonitor: KeyMonitorController.Status,
        expected: AppStatus,
    ) {
        let status = AppStatus.current(
            isRecording: isRecording,
            permissionsGranted: permissionsGranted,
            keyMonitor: keyMonitor,
            speechModel: Self.readySpeechModel,
        )

        #expect(status == expected)
    }

    @Test
    func `reports the speech model until it can transcribe`() {
        let state = SpeechModelState()
        let status = AppStatus.current(isRecording: false, permissionsGranted: true, keyMonitor: .ready, speechModel: state)

        #expect(status == .speechModel(state))
    }

    @Test(arguments: [(false, true, true), (true, false, true), (true, true, false)])
    func `needs setup until it is complete and every permission is granted`(
        hasCompletedSetup: Bool,
        permissionsGranted: Bool,
        needsSetup: Bool,
    ) {
        #expect(AppStatus.needsSetup(hasCompletedSetup: hasCompletedSetup, permissionsGranted: permissionsGranted) == needsSetup)
    }
}
