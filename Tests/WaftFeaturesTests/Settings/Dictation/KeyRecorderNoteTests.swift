import AppKit
import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct KeyRecorderNoteTests {
    private nonisolated static let functionKey: UInt16 = 96
    private nonisolated static let letterA: UInt16 = 0

    private let recorder = KeyRecorder()

    @Test(arguments: [
        ([UInt16](), RecordingPurpose.edit, String?.none),
        ([], .dictation, "Press Option, Command, Shift, or Control on either side, Fn, or a function key. Esc cancels."),
        ([functionKey], .dictation, "That key is already in use. Choose another one."),
        ([letterA], .dictation, "That key types text. Press Option, Command, Shift, Control, Fn, or a function key."),
    ])
    func `notes what to press for the purpose being recorded`(
        pressed: [UInt16],
        purpose: RecordingPurpose,
        note: String?,
    ) throws {
        recorder.start(.dictation, excluding: { $0.keyCode == Int64(Self.functionKey) }, { _ in })

        for keyCode in pressed {
            try recorder.handle(.key(keyCode: keyCode))
        }

        #expect(recorder.note(for: purpose) == note.map { LocalizedStringKey($0) })
    }
}
