import AppKit
import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct ShortcutRecorderNoteTests {
    private nonisolated static let letterK: UInt16 = 40

    private let settings = SettingsModel.inMemory()

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
        let recorder = ShortcutRecorder(settings: settings, shortcuts: .fake(settings: settings))
        recorder.start(.modeCycle)

        for keyCode in pressed {
            try recorder.handle(.key(keyCode: keyCode, flags: []))
        }

        #expect(recorder.note(for: action) == note.map { LocalizedStringKey($0) })
    }
}
