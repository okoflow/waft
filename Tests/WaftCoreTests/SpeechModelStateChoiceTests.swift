import Testing
import WaftCore

struct SpeechModelStateChoiceTests {
    @Test(arguments: [
        (false, SpeechModelState.Effect.download(.accurate), SpeechModelState.Phase.downloading(progress: 0)),
        (true, .load(.accurate), .loading),
    ])
    func `prepares a chosen model while the loaded one keeps transcribing`(
        isInstalled: Bool,
        effect: SpeechModelState.Effect,
        phase: SpeechModelState.Phase,
    ) {
        var state = SpeechModelState(after: SpeechModelState.readyEvents)

        #expect(state.handle(.chosen(.accurate, isInstalled: isInstalled)) == [effect])
        #expect(state.phase == phase)
        #expect(!state.isReady)
        #expect(state.canTranscribe)
        #expect(state.notReadyMessage == nil)
    }

    @Test(arguments: [(SpeechModelState.Event.loaded(.fast), true), (.failed(.fast, "corrupt"), false)])
    func `switches to a model chosen during loading once the load ends`(outcome: SpeechModelState.Event, canTranscribe: Bool) {
        var state = SpeechModelState(after: [.started(.fast, isInstalled: true)])

        #expect(state.handle(.chosen(.accurate, isInstalled: false)).isEmpty)
        #expect(state.handle(outcome) == [.download(.accurate)])
        #expect(state.phase == .downloading(progress: 0))
        #expect(state.canTranscribe == canTranscribe)
    }

    @Test
    func `keeps the loading model when it is chosen again`() {
        var state = SpeechModelState(after: [.started(.fast, isInstalled: true), .chosen(.accurate, isInstalled: true)])

        #expect(state.handle(.chosen(.fast, isInstalled: true)).isEmpty)
        #expect(state.handle(.loaded(.fast)) == [.deleteModel(.accurate)])
        #expect(state.isReady)
    }

    @Test
    func `cancels and deletes a download that another choice abandons`() {
        var state = SpeechModelState(after: SpeechModelState.readyEvents + [.chosen(.accurate, isInstalled: false)])

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
        var state = SpeechModelState(after: SpeechModelState.readyEvents + [
            .chosen(.accurate, isInstalled: false),
            .chosen(.fast, isInstalled: true),
        ])

        #expect(state.handle(event).isEmpty)
        #expect(state.phase == .loading)
    }

    @Test
    func `starts the chosen model after a failure`() {
        var state = SpeechModelState(after: [.started(.fast, isInstalled: false), .failed(.fast, "network lost")])

        #expect(state.handle(.chosen(.accurate, isInstalled: true)) == [.load(.accurate)])
        #expect(state.phase == .loading)
    }
}
