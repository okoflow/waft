import Foundation
import Testing
import WaftCore

struct RecordingTriggersTests {
    @Test
    func `starts a dictation with the push-to-talk key`() {
        var triggers = RecordingTriggers()
        let settings = Settings(languages: .preferred(by: []))

        let fired = triggers.handle(.modifiersChanged(61, flags: KeyEvent.rightOptionFlag), settings: settings)

        #expect(fired.map(\.purpose) == [.dictation])
        #expect(fired.map(\.key) == [settings.pushToTalkKey])
        #expect(fired.map(\.action) == [.startRecording])
    }

    @Test
    func `starts an edit with the edit key`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.editKey = PushToTalkKey(keyCode: KeyEvent.f5KeyCode)

        let fired = triggers.handle(.keyDown(KeyEvent.f5KeyCode), settings: settings)

        #expect(fired.map(\.purpose) == [.edit])
        #expect(fired.map(\.action) == [.startRecording])
    }

    @Test
    func `discards a dictation when the edit key is pressed during it`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.editKey = PushToTalkKey(keyCode: KeyEvent.f5KeyCode)

        _ = triggers.handle(.modifiersChanged(61, flags: KeyEvent.rightOptionFlag), settings: settings)
        let fired = triggers.handle(.keyDown(KeyEvent.f5KeyCode), settings: settings)

        #expect(fired.map(\.purpose) == [.dictation, .edit])
        #expect(fired.map(\.action) == [.discardRecording(.otherKeyPressed), .startRecording])
    }

    @Test
    func `remembers the Escape that cancels a recording`() {
        var triggers = RecordingTriggers()
        let settings = Settings(languages: .preferred(by: []))

        _ = triggers.handle(.modifiersChanged(61, flags: KeyEvent.rightOptionFlag), settings: settings)
        let fired = triggers.handle(.keyDown(KeyEvent.escapeKeyCode, flags: KeyEvent.rightOptionFlag, at: 5), settings: settings)

        #expect(fired.map(\.action) == [.discardRecording(.cancelled)])
        #expect(triggers.cancelledRecording(byEscapeAt: 5))
        #expect(!triggers.cancelledRecording(byEscapeAt: 6))
    }

    @Test
    func `discards both recordings when the key monitor stops`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.editKey = PushToTalkKey(keyCode: KeyEvent.f5KeyCode)

        _ = triggers.handle(.keyDown(KeyEvent.f5KeyCode), settings: settings)
        _ = triggers.handle(.modifiersChanged(61, flags: KeyEvent.rightOptionFlag), settings: settings)
        let fired = triggers.handle(.monitorDisabled, settings: settings)

        #expect(fired.map(\.purpose) == [.dictation, .edit])
        #expect(fired.map(\.action) == [.discardRecording(.interrupted), .discardRecording(.interrupted)])
    }

    @Test
    func `ignores an edit key that is also the dictation key`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.editKey = settings.pushToTalkKey

        let fired = triggers.handle(.modifiersChanged(61, flags: KeyEvent.rightOptionFlag), settings: settings)

        #expect(fired.map(\.purpose) == [.dictation])
    }

    @Test(arguments: [
        (
            RecordingPurpose.dictation,
            DictationStart.holdOrDoubleTap,
            [PushToTalk.Action?.some(.startRecording), .discardRecording(.tooShort), .startRecording, .lockHandsFree],
        ),
        (.dictation, .hold, [.startRecording, .discardRecording(.tooShort), .startRecording, .discardRecording(.tooShort)]),
        (.dictation, .tap, [.startRecording, .lockHandsFree, .finishRecording, nil]),
        (.edit, .tap, [.startRecording, .discardRecording(.tooShort), .startRecording, .discardRecording(.tooShort)]),
    ])
    func `starts a dictation the way the settings say and always holds the edit key`(
        purpose: RecordingPurpose,
        start: DictationStart,
        expected: [PushToTalk.Action?],
    ) {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.dictationStart = start
        let steps: [(PushToTalk.Event, TimeInterval)] = [(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.3), (.keyUp, 0.4)]

        let actions = steps.map { event, time in triggers.handle(event, for: purpose, at: time, settings: settings) }

        #expect(actions == expected)
    }

    @Test
    func `returns a purpose to idle on reset`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.dictationStart = .tap

        _ = triggers.handle(.keyDown, for: .dictation, at: 0, settings: settings)
        _ = triggers.handle(.keyUp, for: .dictation, at: 0.1, settings: settings)

        triggers.reset(.dictation)

        #expect(triggers.handle(.keyDown, for: .dictation, at: 0.3, settings: settings) == .startRecording)
    }
}
