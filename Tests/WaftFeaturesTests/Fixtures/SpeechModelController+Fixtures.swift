import WaftCore
@testable import WaftFeatures

extension SpeechModelController {
    static func make(isReady: Bool, settings: SettingsModel, pro: ProModel = .unlicensed()) async -> SpeechModelController {
        let speechModelController = SpeechModelController(
            transcriber: FakeTranscriber(),
            settings: settings,
            pro: pro,
            urlOpener: FakeURLOpener(),
        )

        guard isReady else { return speechModelController }

        speechModelController.start()

        await Poll.until(timeout: .seconds(5)) { speechModelController.state.isReady }

        return speechModelController
    }
}
