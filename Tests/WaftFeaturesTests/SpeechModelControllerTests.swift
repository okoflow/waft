import Foundation
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

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.isReady })

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

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.isReady })

        settings.settings.speechModel = .accurate

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls.contains(.download(.accurate)) })

        settings.settings.speechModel = .fast

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcriber.calls.suffix(4) == [.cancelDownload(.accurate), .delete(.accurate), .load(.fast), .delete(.accurate)]
        })
        #expect(controller.state.isReady)
    }

    @Test(arguments: [false, true])
    func `reloads the model that keeps transcribing while the chosen one downloads or after it fails`(failsDownload: Bool) async {
        let transcriber = FakeTranscriber(installed: [.fast], holdsDownloads: true)
        let (controller, settings) = make(transcriber)
        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.isReady })

        transcriber.failsDownloads = failsDownload
        settings.settings.speechModel = .accurate

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcriber.calls.contains(.download(.accurate)) && controller.state.canRetry == failsDownload
        })

        controller.reload()

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls.last == .load(.fast) })
        #expect(controller.state.canTranscribe)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `loads the fast model when Pro locks the accurate one`() async {
        let transcriber = FakeTranscriber()
        let (controller, settings) = make(transcriber, pro: .unlicensed(trialStarted: .distantPast))
        settings.settings.speechModel = .accurate
        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls == [.load(.fast), .delete(.accurate)] })
        #expect(controller.modelDirectory == transcriber.modelDirectory(for: .fast))
    }

    @Test
    func `retries a failed download`() async {
        let transcriber = FakeTranscriber(installed: [])
        transcriber.failsDownloads = true
        let (controller, _) = make(transcriber)
        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.canRetry })

        transcriber.failsDownloads = false
        controller.retry()

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.isReady })
        #expect(transcriber.calls == [.download(.fast), .download(.fast), .load(.fast), .delete(.accurate)])
    }

    private func make(_ transcriber: FakeTranscriber, pro: ProModel = .unlicensed()) -> (SpeechModelController, SettingsModel) {
        let settings = SettingsModel.inMemory()
        let controller = SpeechModelController(transcriber: transcriber, settings: settings, pro: pro)
        settings.onSpeechModelChange = { controller.modelDidChange() }

        return (controller, settings)
    }
}
