import Testing
import WaftCore

struct SpeechModelStateTests {
    private static let ready: [SpeechModelState.Event] = [.started(.fast, isInstalled: true), .loaded(.fast)]

    @Test(arguments: [
        (false, SpeechModelState.Effect.download(.fast), SpeechModelState.Phase.downloading(progress: 0)),
        (true, .load(.fast), .loading),
    ])
    func `downloads or loads the model on start`(
        isInstalled: Bool,
        effect: SpeechModelState.Effect,
        phase: SpeechModelState.Phase,
    ) {
        var state = SpeechModelState()

        #expect(state.handle(.started(.fast, isInstalled: isInstalled)) == [effect])
        #expect(state.phase == phase)
    }

    @Test
    func `goes from download through loading to ready and deletes the other model`() {
        var state = SpeechModelState()
        let events: [SpeechModelState.Event] = [
            .started(.accurate, isInstalled: false),
            .downloadProgressed(.accurate, 0.5),
            .downloaded(.accurate),
            .loaded(.accurate),
        ]
        let effects = events.map { state.handle($0) }

        #expect(effects == [[.download(.accurate)], [], [.load(.accurate)], [.deleteModel(.fast)]])
        #expect(state.isReady)
    }

    @Test(arguments: [(0.3, 0.5), (0.8, 0.8), (1.7, 1)])
    func `keeps download progress monotonic and capped`(next: Double, expected: Double) {
        let state = state(after: [
            .started(.fast, isInstalled: false),
            .downloadProgressed(.fast, 0.5),
            .downloadProgressed(.fast, next),
        ])

        #expect(state.progress == expected)
    }

    @Test
    func `retries a failed download by downloading again`() {
        var state = state(after: [
            .started(.fast, isInstalled: false),
            .downloadProgressed(.fast, 0.4),
            .failed(.fast, "network lost"),
        ])

        #expect(state.phase == .failed(reason: "network lost", during: .download))
        #expect(state.canRetry)
        #expect(state.handle(.retryRequested) == [.download(.fast)])
        #expect(state.phase == .downloading(progress: 0))
    }

    @Test
    func `retries a failed load once, then deletes the model and downloads it again`() {
        var state = state(after: [
            .started(.fast, isInstalled: true),
            .loaded(.fast),
            .reloadRequested,
            .failed(.fast, "corrupt"),
        ])

        #expect(state.phase == .failed(reason: "corrupt", during: .load))
        #expect(state.handle(.retryRequested) == [.load(.fast)])
        #expect(state.phase == .loading)
        #expect(state.handle(.failed(.fast, "still corrupt")).isEmpty)
        #expect(state.canTranscribe)
        #expect(state.handle(.retryRequested) == [.deleteModel(.fast), .download(.fast)])
        #expect(state.phase == .downloading(progress: 0))
        #expect(!state.canTranscribe)
    }

    @Test
    func `gives a later load failure a fresh retry after a successful load`() {
        var state = state(after: [
            .started(.fast, isInstalled: true),
            .failed(.fast, "first"),
            .retryRequested,
            .loaded(.fast),
            .reloadRequested,
            .failed(.fast, "second"),
        ])

        #expect(state.handle(.retryRequested) == [.load(.fast)])
    }

    @Test
    func `reloads a ready model`() {
        var state = state(after: Self.ready)

        #expect(state.handle(.reloadRequested) == [.load(.fast)])
        #expect(state.phase == .loading)
        #expect(state.handle(.loaded(.fast)) == [.deleteModel(.accurate)])
        #expect(state.isReady)
    }

    @Test
    func `loads again when a reload is requested during loading`() {
        var state = state(after: [.started(.fast, isInstalled: true)])

        #expect(state.handle(.reloadRequested).isEmpty)
        #expect(state.handle(.loaded(.fast)) == [.load(.fast)])
        #expect(state.phase == .loading)
        #expect(state.handle(.loaded(.fast)) == [.deleteModel(.accurate)])
        #expect(state.phase == .ready)
    }

    @Test(arguments: [
        (false, SpeechModelState.Effect.download(.accurate), SpeechModelState.Phase.downloading(progress: 0)),
        (true, .load(.accurate), .loading),
    ])
    func `prepares a chosen model while the loaded one keeps transcribing`(
        isInstalled: Bool,
        effect: SpeechModelState.Effect,
        phase: SpeechModelState.Phase,
    ) {
        var state = state(after: Self.ready)

        #expect(state.handle(.chosen(.accurate, isInstalled: isInstalled)) == [effect])
        #expect(state.phase == phase)
        #expect(!state.isReady)
        #expect(state.canTranscribe)
        #expect(state.notReadyMessage == nil)
    }

    @Test(arguments: [(SpeechModelState.Event.loaded(.fast), true), (.failed(.fast, "corrupt"), false)])
    func `switches to a model chosen during loading once the load ends`(outcome: SpeechModelState.Event, canTranscribe: Bool) {
        var state = state(after: [.started(.fast, isInstalled: true)])

        #expect(state.handle(.chosen(.accurate, isInstalled: false)).isEmpty)
        #expect(state.handle(outcome) == [.download(.accurate)])
        #expect(state.phase == .downloading(progress: 0))
        #expect(state.canTranscribe == canTranscribe)
    }

    @Test
    func `keeps the loading model when it is chosen again`() {
        var state = state(after: [.started(.fast, isInstalled: true), .chosen(.accurate, isInstalled: true)])

        #expect(state.handle(.chosen(.fast, isInstalled: true)).isEmpty)
        #expect(state.handle(.loaded(.fast)) == [.deleteModel(.accurate)])
        #expect(state.isReady)
    }

    @Test
    func `cancels and deletes a download that another choice abandons`() {
        var state = state(after: Self.ready + [.chosen(.accurate, isInstalled: false)])

        #expect(state.handle(.chosen(.fast, isInstalled: true)) == [.cancelDownload, .deleteModel(.accurate), .load(.fast)])
        #expect(state.phase == .loading)
    }

    @Test(arguments: [
        SpeechModelState.Event.downloadProgressed(.accurate, 0.9),
        .downloaded(.accurate),
        .loaded(.accurate),
        .failed(.accurate, "cancelled"),
    ])
    func `ignores events about a model that is no longer chosen`(event: SpeechModelState.Event) {
        var state = state(after: Self.ready + [.chosen(.accurate, isInstalled: false), .chosen(.fast, isInstalled: true)])

        #expect(state.handle(event).isEmpty)
        #expect(state.phase == .loading)
    }

    @Test
    func `starts the chosen model after a failure`() {
        var state = state(after: [.started(.fast, isInstalled: false), .failed(.fast, "network lost")])

        #expect(state.handle(.chosen(.accurate, isInstalled: true)) == [.load(.accurate)])
        #expect(state.phase == .loading)
    }

    @Test(arguments: [
        SpeechModelState.Event.downloaded(.fast),
        .loaded(.fast),
        .downloadProgressed(.fast, 0.5),
        .failed(.fast, "x"),
        .retryRequested,
        .reloadRequested,
        .chosen(.accurate, isInstalled: true),
    ])
    func `ignores events that do not apply before start`(event: SpeechModelState.Event) {
        var state = SpeechModelState()

        #expect(state.handle(event).isEmpty)
        #expect(state.phase == .notInstalled)
    }

    @Test(arguments: [
        SpeechModelState.Event.started(.fast, isInstalled: false),
        .retryRequested,
        .downloaded(.fast),
        .failed(.fast, "late"),
        .chosen(.fast, isInstalled: true),
    ])
    func `ignores events that do not apply once ready`(event: SpeechModelState.Event) {
        var state = state(after: Self.ready)

        #expect(state.handle(event).isEmpty)
        #expect(state.isReady)
    }

    @Test(arguments: [
        ([SpeechModelState.Event](), "Preparing the speech model…", String?.some("The speech model isn't ready yet")),
        (
            [.started(.fast, isInstalled: true)],
            "Preparing the speech model…",
            "Preparing the speech model, about a minute the first time…",
        ),
        ([.started(.fast, isInstalled: true), .loaded(.fast)], "Ready", nil),
        (
            [.started(.fast, isInstalled: false), .failed(.fast, "network lost")],
            "Speech model failed: network lost",
            "The speech model failed to load. Retry from the menu.",
        ),
    ])
    func `reports the status and why a press must wait`(events: [SpeechModelState.Event], status: String, message: String?) {
        let state = state(after: events)

        #expect(state.statusText == status)
        #expect(state.notReadyMessage == message)
    }

    private func state(after events: [SpeechModelState.Event]) -> SpeechModelState {
        var state = SpeechModelState()

        for event in events {
            _ = state.handle(event)
        }

        return state
    }
}
