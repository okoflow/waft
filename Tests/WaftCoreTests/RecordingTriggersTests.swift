import Foundation
import Testing
import WaftCore

struct RecordingTriggersTests {
    @Test
    func `starts a dictation with the push-to-talk key`() {
        var triggers = RecordingTriggers()
        let settings = Settings(languages: .preferred(by: []))
        let fired = triggers.handle(KeyEvent(.modifiersChanged, keyCode: 61, flags: KeyEvent.rightOptionFlag), settings: settings)

        #expect(fired.map(\.purpose) == [.dictation])
        #expect(fired.map(\.key) == [settings.pushToTalkKey])
        #expect(fired.map(\.action) == [.startRecording])
    }

    @Test
    func `starts an edit with the edit key`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.editKey = PushToTalkKey(keyCode: KeyEvent.f5KeyCode)
        let fired = triggers.handle(KeyEvent(.keyDown, keyCode: KeyEvent.f5KeyCode), settings: settings)

        #expect(fired.map(\.purpose) == [.edit])
        #expect(fired.map(\.action) == [.startRecording])
    }

    @Test
    func `ignores an edit key that is also the dictation key`() {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.editKey = settings.pushToTalkKey
        let fired = triggers.handle(KeyEvent(.modifiersChanged, keyCode: 61, flags: KeyEvent.rightOptionFlag), settings: settings)

        #expect(fired.map(\.purpose) == [.dictation])
    }

    @Test(arguments: [
        (RecordingPurpose.dictation, true, PushToTalk.Action?.some(.lockHandsFree)),
        (.dictation, false, .discardRecording(.tooShort)),
        (.edit, true, .discardRecording(.tooShort)),
    ])
    func `locks hands-free only for a dictation that allows it`(
        purpose: RecordingPurpose,
        allowsHandsFree: Bool,
        secondRelease: PushToTalk.Action?,
    ) {
        var triggers = RecordingTriggers()
        var settings = Settings(languages: .preferred(by: []))
        settings.allowsHandsFree = allowsHandsFree
        let steps: [(PushToTalk.Event, TimeInterval)] = [(.keyDown, 0), (.keyUp, 0.1), (.keyDown, 0.3), (.keyUp, 0.4)]
        let actions = steps.map { event, time in triggers.handle(event, for: purpose, at: time, settings: settings) }

        #expect(actions.last == secondRelease)
    }
}
