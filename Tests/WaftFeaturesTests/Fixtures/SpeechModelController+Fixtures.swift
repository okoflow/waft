import WaftCore
@testable import WaftFeatures

extension SpeechModelController {
    static func unstarted(settings: SettingsModel) -> SpeechModelController {
        SpeechModelController(transcriber: FakeTranscriber(), settings: settings, pro: .unlicensed(), urlOpener: FakeURLOpener())
    }

    static func ready(settings: SettingsModel) async -> SpeechModelController {
        let speechModelController = unstarted(settings: settings)

        speechModelController.start()

        await Poll.until(timeout: .seconds(5)) { speechModelController.state.isReady }

        return speechModelController
    }

    static func make(isReady: Bool, settings: SettingsModel) async -> SpeechModelController {
        guard isReady else { return unstarted(settings: settings) }

        return await ready(settings: settings)
    }
}
