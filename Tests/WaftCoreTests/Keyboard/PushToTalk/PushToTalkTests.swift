import Foundation
import Testing
@testable import WaftCore

struct PushToTalkTests {
    @Test(arguments: [
        (10.0, 10.05, PushToTalk.Action.discardRecording(.tooShort)),
        (10, 10.2, .discardRecording(.tooShort)),
        (10, 10.29, .discardRecording(.tooShort)),
        (0, PushToTalk.minimumHold, .finishRecording),
        (10, 11.5, .finishRecording),
    ])
    func `finishes a hold of at least the minimum duration and discards a shorter one`(
        pressedAt: TimeInterval,
        releasedAt: TimeInterval,
        expected: PushToTalk.Action,
    ) {
        #expect(handle([(.keyDown, pressedAt), (.keyUp, releasedAt)]) == [.startRecording, expected])
    }

    @Test
    func `locks hands-free on a double tap and stops on the next press`() {
        let actions = handle([(.keyDown, 0), (.keyUp, 0.125), (.keyDown, 0.25), (.keyUp, 0.375), (.keyDown, 5.25), (.keyUp, 5.5)])

        #expect(actions == [
            .startRecording,
            .discardRecording(.tooShort),
            .startRecording,
            .lockHandsFree,
            .finishRecording,
            nil,
        ])
    }

    @Test(arguments: [
        (
            [
                (PushToTalk.Event.keyDown, 0.0),
                (.keyUp, 0.1),
                (.keyDown, 0.3),
                (.keyUp, 0.4),
                (.keyDown, 2),
                (.keyUp, 2.1),
                (.keyDown, 9),
            ],
            [
                PushToTalk.Action.startRecording,
                .discardRecording(.tooShort),
                .startRecording,
                .lockHandsFree,
                .finishRecording,
                nil,
                .startRecording,
            ],
        ),
        (
            [(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.3), (.keyUp, 0.4), (.keyDown, 2), (.keyDown, 9)],
            [.startRecording, .discardRecording(.tooShort), .startRecording, .lockHandsFree, .finishRecording, .startRecording],
        ),
    ])
    func `starts a recording on the next press after hands-free stops, with or without its key-up`(
        steps: [(PushToTalk.Event, TimeInterval)],
        expected: [PushToTalk.Action?],
    ) {
        #expect(handle(steps) == expected)
    }

    @Test
    func `ignores a second tap outside the double-tap window`() {
        let actions = handle([(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.6), (.keyUp, 0.7)])

        #expect(actions.last == .discardRecording(.tooShort))
    }

    @Test
    func `treats a double tap as two short taps when only holding starts dictation`() {
        let actions = handle([(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.3), (.keyUp, 0.4)], start: .hold)

        #expect(actions == [.startRecording, .discardRecording(.tooShort), .startRecording, .discardRecording(.tooShort)])
    }

    @Test(arguments: [0.1, 2])
    func `locks hands-free when the key is released in tap mode`(holdDuration: TimeInterval) {
        let actions = handle([(.keyDown, 0), (.keyUp, holdDuration), (.keyDown, 5), (.keyUp, 5.1)], start: .tap)

        #expect(actions == [.startRecording, .lockHandsFree, .finishRecording, nil])
    }

    @Test
    func `forgets an earlier tap after a full recording`() {
        let actions = handle([
            (.keyDown, 0),
            (.keyUp, 0.0625),
            (.keyDown, 0.0625),
            (.keyUp, 0.375),
            (.keyDown, 0.4375),
            (.keyUp, 0.5),
        ])

        #expect(actions.last == .discardRecording(.tooShort))
    }

    @Test
    func `cancels when another key is pressed during the hold`() {
        let actions = handle([(.keyDown, 0), (.otherKeyDown, 1), (.keyUp, 2), (.keyDown, 3)])

        #expect(actions == [.startRecording, .discardRecording(.otherKeyPressed), nil, .startRecording])
    }

    @Test(arguments: [
        [(PushToTalk.Event.keyDown, 0.0), (.escapeDown, 1)],
        [(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.3), (.keyUp, 0.4), (.escapeDown, 3)],
    ])
    func `cancels the recording on Escape, also hands-free`(steps: [(PushToTalk.Event, TimeInterval)]) {
        #expect(handle(steps).last == .discardRecording(.cancelled))
    }

    @Test
    func `restarts on a new press right after another key canceled the hold`() {
        let actions = handle([(.keyDown, 0), (.otherKeyDown, 1), (.keyDown, 2)])

        #expect(actions.last == .startRecording)
    }

    @Test(arguments: [
        [(PushToTalk.Event.keyDown, 0.0), (.monitorDisabled, 1)],
        [(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.3), (.keyUp, 0.4), (.monitorDisabled, 3)],
    ])
    func `discards the recording when the key monitor stops`(steps: [(PushToTalk.Event, TimeInterval)]) {
        #expect(handle(steps).last == .discardRecording(.interrupted))
    }

    @Test(arguments: [PushToTalk.Event.keyUp, .otherKeyDown, .escapeDown, .monitorDisabled, .tick])
    func `ignores events while idle`(event: PushToTalk.Event) {
        #expect(handle([(event, 1)]) == [nil])
    }

    @Test
    func `ignores a repeated key-down during the hold`() {
        #expect(handle([(.keyDown, 0), (.keyDown, 0.5)]) == [.startRecording, nil])
    }

    @Test
    func `keeps a hands-free recording going while other keys are typed`() {
        let actions = handle([
            (.keyDown, 0),
            (.keyUp, 0.125),
            (.keyDown, 0.25),
            (.keyUp, 0.375),
            (.otherKeyDown, 2),
            (.keyDown, 4.25),
        ])

        #expect(actions.suffix(2) == [nil, .finishRecording])
    }

    @Test
    func `keeps recording on ticks before the maximum hold`() {
        let actions = handle([(.keyDown, 0), (.tick, PushToTalk.maximumHold - 1)])

        #expect(actions.last == .some(nil))
    }

    @Test
    func `finishes a hold that reaches the maximum duration`() {
        let actions = handle([(.keyDown, 0), (.tick, PushToTalk.maximumHold), (.keyUp, 301), (.keyDown, 302)])

        #expect(actions == [.startRecording, .finishRecording, nil, .startRecording])
    }

    @Test
    func `starts a new recording after hands-free reaches the maximum duration`() {
        let actions = handle([
            (.keyDown, 0),
            (.keyUp, 0.125),
            (.keyDown, 0.25),
            (.keyUp, 0.375),
            (.tick, 300.25),
            (.keyDown, 301),
        ])

        #expect(actions.suffix(2) == [.finishRecording, .startRecording])
    }

    private func handle(
        _ steps: [(PushToTalk.Event, TimeInterval)],
        start: DictationStart = .holdOrDoubleTap,
    ) -> [PushToTalk.Action?] {
        var pushToTalk = PushToTalk()
        pushToTalk.dictationStart = start

        return steps.map { event, time in pushToTalk.handle(event, at: time) }
    }
}
