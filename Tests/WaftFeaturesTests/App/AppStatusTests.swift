import Testing
import WaftCore
@testable import WaftFeatures

struct AppStatusTests {
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
}
