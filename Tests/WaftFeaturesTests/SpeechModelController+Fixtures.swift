import WaftCore
@testable import WaftFeatures

extension SpeechModelController {
    static func ready(settings: SettingsModel) async -> SpeechModelController {
        let speechModelController = SpeechModelController(transcriber: FakeTranscriber(), settings: settings, pro: .unlicensed())
        speechModelController.start()

        await Poll.until(timeout: .seconds(5)) { speechModelController.state.isReady }

        return speechModelController
    }
}
