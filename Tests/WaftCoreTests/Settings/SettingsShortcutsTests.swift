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
}
