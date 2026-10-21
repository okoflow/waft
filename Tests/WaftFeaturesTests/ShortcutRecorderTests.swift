import AppKit
import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct ShortcutRecorderTests {
    private nonisolated static let controlOption: NSEvent.ModifierFlags = [.control, .option]
    private nonisolated static let letterK: UInt16 = 40
    private nonisolated static let letterT: UInt16 = 17
    private nonisolated static let functionKey: UInt16 = 96
    private static let escape: UInt16 = 53

    private let shortcut = FakeGlobalShortcut()
    private let settings = SettingsModel.inMemory()

    @Test(arguments: [
        (letterK, controlOption, KeyCombination(keyCode: 40, modifiers: [.control, .option])),
        (letterK, NSEvent.ModifierFlags([.command, .shift]), KeyCombination(keyCode: 40, modifiers: [.shift, .command])),
        (functionKey, NSEvent.ModifierFlags(), KeyCombination(keyCode: 96, modifiers: [])),
        (functionKey, .shift, KeyCombination(keyCode: 96, modifiers: .shift)),
    ])
    func `records a combination with a required modifier or a function key and stops`(
        keyCode: UInt16,
        flags: NSEvent.ModifierFlags,
        combination: KeyCombination,
    ) throws {
        let recorder = recorder()
        recorder.start(.translator)

        try recorder.handle(event(keyCode: keyCode, flags: flags))

        #expect(settings.settings.shortcuts[.translator] == combination)
        #expect(!recorder.isRecording)
    }

    @Test(arguments: [[], NSEvent.ModifierFlags.shift])
    func `rejects a key without Command, Control, or Option`(flags: NSEvent.ModifierFlags) throws {
        let recorder = recorder()
        recorder.start(.fixSelection)

        try recorder.handle(event(keyCode: Self.letterK, flags: flags))

        #expect(recorder.rejection == .needsModifier)
        #expect(recorder.rejections == [.fixSelection: 1])
        #expect(recorder.isRecording(.fixSelection))
        #expect(settings.settings.shortcuts[.fixSelection] == ShortcutAction.fixSelection.defaultCombination)
    }

    @Test
    func `rejects the combination of another shortcut and names it`() throws {
        let recorder = recorder()
        recorder.start(.modeCycle)

        try recorder.handle(event(keyCode: Self.letterT, flags: Self.controlOption))

        #expect(recorder.rejection == .taken(.shortcut(.translator)))
        #expect(ShortcutConflict.shortcut(.translator).title == "Open the translator")
    }

    @Test
    func `accepts the combination it already has`() throws {
        let recorder = recorder()
        recorder.start(.translator)

        try recorder.handle(event(keyCode: Self.letterT, flags: Self.controlOption))

        #expect(recorder.rejection == nil)
        #expect(!recorder.isRecording)
    }

    @Test
    func `cancels on Escape and keeps the shortcut`() throws {
        let recorder = recorder()
        recorder.start(.translator)

        try recorder.handle(event(keyCode: Self.escape, flags: Self.controlOption))

        #expect(!recorder.isRecording)
        #expect(settings.settings.shortcuts[.translator] == ShortcutAction.translator.defaultCombination)
    }

    @Test
    func `suspends the global shortcuts while it records`() {
        let recorder = recorder()

        recorder.start(.translator)

        #expect(shortcut.registered == nil)

        recorder.stop()

        #expect(shortcut.registered == ShortcutAction.translator.defaultCombination)
    }

    @Test
    func `clears a shortcut and restores its default`() {
        let recorder = recorder()

        recorder.clear(.translator)

        #expect(settings.settings.shortcuts[.translator] == nil)
        #expect(shortcut.registered == nil)

        recorder.reset(.translator)

        #expect(settings.settings.shortcuts[.translator] == ShortcutAction.translator.defaultCombination)
        #expect(shortcut.registered == ShortcutAction.translator.defaultCombination)
    }

    @Test(arguments: [
        ([UInt16](), ShortcutAction.translator, String?.none),
        ([], .modeCycle, "Press a key with Command, Control, or Option, or a function key. Esc cancels."),
        ([letterK], .modeCycle, "Add Command, Control, or Option, or press a function key."),
    ])
    func `notes what to press for the shortcut being recorded`(
        pressed: [UInt16],
        action: ShortcutAction,
        note: String?,
    ) throws {
        let recorder = recorder()
        recorder.start(.modeCycle)

        for keyCode in pressed {
            try recorder.handle(event(keyCode: keyCode, flags: []))
        }

        #expect(recorder.note(for: action) == note.map { LocalizedStringKey($0) })
    }

    private func recorder() -> ShortcutRecorder {
        let shortcuts = GlobalShortcutController.fake([.translator: shortcut], settings: settings)
        shortcuts.handle(.translator) {}

        return ShortcutRecorder(settings: settings, shortcuts: shortcuts)
    }

    private func event(keyCode: UInt16, flags: NSEvent.ModifierFlags) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: flags,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: keyCode,
        ))
    }
}
