import Testing
import WaftCore

struct SpeechModelStateTests {
    @Test
    func `starts out not installed`() {
        let state = SpeechModelState()

        #expect(state.phase == .notInstalled)
        #expect(!state.isReady)
        #expect(!state.canRetry)
        #expect(state.progress == nil)
    }

    @Test(arguments: [
        (false, SpeechModelState.Effect.download, SpeechModelState.Phase.downloading(progress: 0)),
        (true, .load, .loading),
    ])
    func `downloads or loads the model on start`(
        isInstalled: Bool,
        effect: SpeechModelState.Effect,
        phase: SpeechModelState.Phase,
    ) {
        var state = SpeechModelState()

        #expect(state.handle(.started(isInstalled: isInstalled)) == [effect])
        #expect(state.phase == phase)
    }

    @Test
    func `goes from download through loading to ready`() {
        var state = SpeechModelState()
        let events: [SpeechModelState.Event] = [.started(isInstalled: false), .downloadProgressed(0.5), .downloaded, .loaded]
        let effects = events.map { state.handle($0) }

        #expect(effects == [[.download], [], [.load], []])
        #expect(state.isReady)
        #expect(state.phase == .ready)
    }

    @Test(arguments: [(0.3, 0.5), (0.8, 0.8), (1.7, 1)])
    func `keeps download progress monotonic and capped`(next: Double, expected: Double) {
        let state = state(after: [.started(isInstalled: false), .downloadProgressed(0.5), .downloadProgressed(next)])

        #expect(state.progress == expected)
    }

    @Test
    func `retries a failed download by downloading again`() {
        var state = state(after: [.started(isInstalled: false), .downloadProgressed(0.4), .failed("network lost")])

        #expect(state.phase == .failed(reason: "network lost", during: .download))
        #expect(state.canRetry)
        #expect(state.handle(.retryRequested) == [.download])
        #expect(state.phase == .downloading(progress: 0))
    }

    @Test
    func `retries a failed load once and then downloads the model again`() {
        var state = state(after: [.started(isInstalled: true), .failed("corrupt")])

        #expect(state.phase == .failed(reason: "corrupt", during: .load))
        #expect(state.handle(.retryRequested) == [.load])
        #expect(state.phase == .loading)
        #expect(state.handle(.failed("still corrupt")).isEmpty)
        #expect(state.handle(.retryRequested) == [.deleteModel, .download])
        #expect(state.phase == .downloading(progress: 0))
    }

    @Test
    func `gives a later load failure a fresh retry after a successful load`() {
        var state = state(after: [
            .started(isInstalled: true),
            .failed("first"),
            .retryRequested,
            .loaded,
            .reloadRequested,
            .failed("second"),
        ])

        #expect(state.handle(.retryRequested) == [.load])
    }

    @Test
    func `reloads a ready model`() {
        var state = state(after: [.started(isInstalled: true), .loaded])

        #expect(state.handle(.reloadRequested) == [.load])
        #expect(state.phase == .loading)
        #expect(state.handle(.loaded).isEmpty)
        #expect(state.isReady)
    }

    @Test
    func `loads again when a reload is requested during loading`() {
        var state = state(after: [.started(isInstalled: true)])

        #expect(state.handle(.reloadRequested).isEmpty)
        #expect(state.handle(.loaded) == [.load])
        #expect(state.phase == .loading)
        #expect(state.handle(.loaded).isEmpty)
        #expect(state.phase == .ready)
    }

    @Test(arguments: [
        SpeechModelState.Event.downloaded,
        .loaded,
        .downloadProgressed(0.5),
        .failed("x"),
        .retryRequested,
        .reloadRequested,
    ])
    func `ignores events that do not apply before start`(event: SpeechModelState.Event) {
        var state = SpeechModelState()

        #expect(state.handle(event).isEmpty)
        #expect(state.phase == .notInstalled)
    }

    @Test(arguments: [SpeechModelState.Event.started(isInstalled: false), .retryRequested, .downloaded, .failed("late")])
    func `ignores events that do not apply once ready`(event: SpeechModelState.Event) {
        var state = state(after: [.started(isInstalled: true), .loaded])

        #expect(state.handle(event).isEmpty)
        #expect(state.isReady)
    }

    @Test(arguments: [[SpeechModelState.Event](), [.started(isInstalled: true)]])
    func `reports the model as being prepared before it starts and while it loads`(events: [SpeechModelState.Event]) {
        let state = state(after: events)

        #expect(state.statusText == "Preparing speech model…")
        #expect(state.notReadyMessage != nil)
    }

    @Test
    func `reports ready without a not-ready message`() {
        let state = state(after: [.started(isInstalled: true), .loaded])

        #expect(state.statusText == "Ready")
        #expect(state.notReadyMessage == nil)
    }

    private func state(after events: [SpeechModelState.Event]) -> SpeechModelState {
        var state = SpeechModelState()

        for event in events {
            _ = state.handle(event)
        }

        return state
    }
}
