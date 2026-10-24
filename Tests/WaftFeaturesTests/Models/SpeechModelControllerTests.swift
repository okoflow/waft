import Foundation
import Testing
import WaftCore
@testable import WaftFeatures

struct SpeechModelControllerTests {
    @Test(arguments: [true, false])
    func `starts the current model when the choice changes during the installation check`(isChosenInstalled: Bool) async {
        let (queries, queryContinuation) = AsyncStream.makeStream(of: SpeechModel.self)
        let (releases, releaseContinuation) = AsyncStream.makeStream(of: Void.self)
        defer {
            queryContinuation.finish()
            releaseContinuation.finish()
        }

        let installed: Set<SpeechModel> = isChosenInstalled ? [.fast, .accurate] : [.fast]
        let transcriber = FakeTranscriber(installed: installed, beforeInstallationCheck: { model in
            guard model == .fast else { return }

            queryContinuation.yield(model)

            var iterator = releases.makeAsyncIterator()
            _ = await iterator.next()
        })

        let settings = SettingsModel.inMemory()
        let controller = SpeechModelController(
            transcriber: transcriber,
            settings: settings,
            pro: .unlicensed(),
            urlOpener: FakeURLOpener(),
        )

        controller.start()

        var iterator = queries.makeAsyncIterator()

        #expect(await iterator.next() == .fast)

        settings.settings.speechModel = .accurate
        releaseContinuation.yield(())

        let expected: [FakeTranscriber.Call] =
            if isChosenInstalled {
                [.load(.accurate), .delete(.fast)]
            } else {
                [.download(.accurate), .load(.accurate), .delete(.fast)]
            }

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls == expected })
        #expect(controller.state.isReady)
    }

    @Test
    func `downloads and loads a chosen model, then deletes the previous one`() async {
        let transcriber = FakeTranscriber(installed: [.fast])
        let (controller, settings) = make(transcriber)

        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.isReady })
        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls == [.load(.fast), .delete(.accurate)] })

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
            guard transcriber.calls.contains(.download(.accurate)) else { return false }

            return controller.state.canRetry == failsDownload
        })

        controller.reload()

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls.last == .load(.fast) })
        #expect(controller.state.canTranscribe)
    }

    @Test
    func `finishes a reload of the serving model before it loads the chosen one`() async {
        let (releases, releaseContinuation) = AsyncStream.makeStream(of: Void.self)
        defer { releaseContinuation.finish() }

        let transcriber = FakeTranscriber(installed: [.fast], beforeLoad: { model in
            guard model == .fast else { return }

            var iterator = releases.makeAsyncIterator()
            _ = await iterator.next()
        })
        let (controller, settings) = make(transcriber)
        releaseContinuation.yield(())

        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.isReady })

        transcriber.failsDownloads = true
        settings.settings.speechModel = .accurate

        #expect(await Poll.until(timeout: .seconds(5)) { controller.state.canRetry })

        controller.reload()
        transcriber.failsDownloads = false
        controller.retry()

        #expect(await !Poll.until(timeout: .milliseconds(300)) { controller.state.isReady })

        releaseContinuation.yield(())

        #expect(await Poll.until(timeout: .seconds(5)) {
            transcriber.calls.suffix(4) == [.load(.fast), .download(.accurate), .load(.accurate), .delete(.fast)]
        })
        #expect(controller.state.isReady)
    }

    @Test(.enabled(if: !ProAccess.isFreeDuringBeta))
    func `loads the fast model when Waft+ locks the accurate one`() async {
        let transcriber = FakeTranscriber()
        let (controller, settings) = make(transcriber, pro: .unlicensed(trialStarted: .distantPast))
        settings.settings.speechModel = .accurate

        controller.start()

        #expect(await Poll.until(timeout: .seconds(5)) { transcriber.calls == [.load(.fast), .delete(.accurate)] })
        #expect(controller.modelDirectory == transcriber.modelDirectory(for: .fast))
    }

    @Test
    func `reveals the folder of the model it uses`() {
        let transcriber = FakeTranscriber()
        let urlOpener = FakeURLOpener()
        let (controller, _) = make(transcriber, urlOpener: urlOpener)

        controller.revealInFinder()

        #expect(urlOpener.revealed == [transcriber.modelDirectory(for: controller.chosenModel)])
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

    private func make(
        _ transcriber: FakeTranscriber,
        pro: ProModel = .unlicensed(),
        urlOpener: FakeURLOpener = FakeURLOpener(),
    ) -> (SpeechModelController, SettingsModel) {
        let settings = SettingsModel.inMemory()
        let controller = SpeechModelController(transcriber: transcriber, settings: settings, pro: pro, urlOpener: urlOpener)
        settings.onSpeechModelChange = { controller.modelDidChange() }

        return (controller, settings)
    }
}
