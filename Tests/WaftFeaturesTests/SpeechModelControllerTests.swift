import Testing
import WaftCore
@testable import WaftFeatures

struct SpeechModelControllerTests {
    @Test
    func `loads the installed model and deletes the other one`() async {
        let transcriber = FakeTranscriber(installed: [.fast])
        let (controller, _) = make(transcriber)
        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls == [.load(.fast), .delete(.accurate)] })
        #expect(controller.state.isReady)
    }

    @Test
    func `downloads and loads a chosen model, then deletes the previous one`() async {
        let transcriber = FakeTranscriber(installed: [.fast])
        let (controller, settings) = make(transcriber)
        controller.start()
        await Poll.until(timeout: .seconds(5)) { controller.state.isReady }
        settings.settings.speechModel = .accurate

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcriber.calls == [.load(.fast), .delete(.accurate), .download(.accurate), .load(.accurate), .delete(.fast)]
        })
        #expect(controller.state.isReady)
    }

    @Test
    func `cancels the download of a model the user turns away from`() async {
        let transcriber = FakeTranscriber(installed: [.fast], holdsDownloads: true)
        let (controller, settings) = make(transcriber)
        controller.start()
        await Poll.until(timeout: .seconds(5)) { controller.state.isReady }
        settings.settings.speechModel = .accurate
        await Poll.until(timeout: .seconds(5)) { transcriber.calls.contains(.download(.accurate)) }
        settings.settings.speechModel = .fast

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcriber.calls.suffix(4) == [.cancelDownload(.accurate), .delete(.accurate), .load(.fast), .delete(.accurate)]
        })
        #expect(controller.state.isReady)
    }

    private func make(_ transcriber: FakeTranscriber) -> (SpeechModelController, SettingsModel) {
        let settings = SettingsModel.inMemory()
        let controller = SpeechModelController(transcriber: transcriber, settings: settings, pro: .unlicensed())
        settings.onSpeechModelChange = { controller.modelDidChange() }

        return (controller, settings)
    }
}
