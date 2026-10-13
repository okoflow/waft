import WaftCore
@testable import WaftFeatures

extension SpeechModelController {
    static func ready(settings: SettingsModel) async -> SpeechModelController {
        let speechModel = SpeechModelController(transcriber: FakeTranscriber(), settings: settings, pro: .unlicensed())
        speechModel.start()

        await Poll.until(timeout: .seconds(5)) { speechModel.state.isReady }

        return speechModel
    }
}
