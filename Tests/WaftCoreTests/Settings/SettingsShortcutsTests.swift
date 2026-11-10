import Testing
import WaftCore

struct SettingsShortcutsTests {
    private static let shiftF5 = KeyCombination(keyCode: 96, modifiers: [.shift])

    @Test
    func `reports the other shortcut that uses a combination`() {
        let settings = Settings.defaults

        #expect(settings
            .conflict(with: ShortcutAction.translator.defaultCombination, recording: .modeCycle) == .shortcut(.translator))
        #expect(settings.conflict(with: ShortcutAction.translator.defaultCombination, recording: .translator) == nil)
    }

    @Test(arguments: [
        (Int64(96), Int64?.none, ShortcutConflict?.some(.key(.dictation))),
        (61, 96, .key(.edit)),
        (61, nil, nil),
    ])
    func `reports the dictation or editing key on the same function key`(
        dictationKey: Int64,
        editKey: Int64?,
        conflict: ShortcutConflict?,
    ) throws {
        var settings = Settings.defaults
        settings.pushToTalkKey = try #require(PushToTalkKey(keyCode: dictationKey))
        settings.editKey = editKey.flatMap(PushToTalkKey.init(keyCode:))

        #expect(settings.conflict(with: Self.shiftF5, recording: .translator) == conflict)
    }

    @Test
    func `reports the other key or a shortcut on the key being recorded`() throws {
        let functionKey = try #require(PushToTalkKey(keyCode: KeyEvent.f5KeyCode))
        var settings = Settings.defaults
        settings.shortcuts[.translator] = Self.shiftF5

        #expect(settings.conflict(with: settings.pushToTalkKey, recording: .dictation) == nil)
        #expect(settings.conflict(with: settings.pushToTalkKey, recording: .edit) == .key(.dictation))
        #expect(settings.conflict(with: functionKey, recording: .dictation) == .shortcut(.translator))

        settings.shortcuts[.translator] = nil
        settings.editKey = functionKey

        #expect(settings.conflict(with: functionKey, recording: .dictation) == .key(.edit))
        #expect(settings.conflict(with: functionKey, recording: .edit) == nil)
    }
}
