import AppKit
import SwiftUI
import Testing
import WaftCore
@testable import WaftFeatures

struct KeyRecorderTests {
    private nonisolated static let rightOptionPressed: UInt = 0x80040
    private static let escape: UInt16 = 53
    private nonisolated static let functionKey: UInt16 = 96
    private nonisolated static let letterA: UInt16 = 0

    private let recorder = KeyRecorder()

    @Test(arguments: [(NSEvent.EventType.flagsChanged, UInt16(61), rightOptionPressed), (.keyDown, functionKey, 0)])
    func `records a pressed modifier or function key and stops`(type: NSEvent.EventType, keyCode: UInt16, flags: UInt) throws {
        var recorded: [PushToTalkKey] = []
        recorder.start(.dictation, excluding: nil) { recorded.append($0) }

        try recorder.handle(event(type, keyCode: keyCode, flags: flags))

        #expect(recorded.map(\.keyCode) == [Int64(keyCode)])
        #expect(!recorder.isRecording)
    }

    @Test
    func `rejects a key that types text and counts the rejection for its purpose`() throws {
        recorder.start(.edit, excluding: nil) { _ in }

        try recorder.handle(event(.keyDown, keyCode: Self.letterA))
        try recorder.handle(event(.keyDown, keyCode: Self.letterA))

        #expect(recorder.rejection == .typesText)
        #expect(recorder.rejections == [.edit: 2])
        #expect(recorder.isRecording(.edit))
    }

    @Test
    func `rejects the key already used for the other purpose`() throws {
        recorder.start(.edit, excluding: PushToTalkKey(keyCode: Int64(Self.functionKey))) { _ in }

        try recorder.handle(event(.keyDown, keyCode: Self.functionKey))

        #expect(recorder.rejection == .taken)
        #expect(recorder.isRecording(.edit))
    }

    @Test
    func `cancels on Escape`() throws {
        var recorded: [PushToTalkKey] = []
        recorder.start(.dictation, excluding: nil) { recorded.append($0) }

        try recorder.handle(event(.keyDown, keyCode: Self.escape))

        #expect(!recorder.isRecording)
        #expect(recorded.isEmpty)
        #expect(recorder.rejection == nil)
    }

    @Test
    func `ignores a modifier being released`() throws {
        var recorded: [PushToTalkKey] = []
        recorder.start(.dictation, excluding: nil) { recorded.append($0) }

        try recorder.handle(event(.flagsChanged, keyCode: 61))

        #expect(recorder.isRecording(.dictation))
        #expect(recorded.isEmpty)
        #expect(recorder.rejection == nil)
    }

    @Test
    func `clears the previous rejection when it starts again`() throws {
        recorder.start(.dictation, excluding: nil) { _ in }
        try recorder.handle(event(.keyDown, keyCode: Self.letterA))

        recorder.start(.dictation, excluding: nil) { _ in }

        #expect(recorder.rejection == nil)
        #expect(recorder.rejections == [.dictation: 1])
    }

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
        recorder.start(.dictation, excluding: PushToTalkKey(keyCode: Int64(Self.functionKey))) { _ in }

        for keyCode in pressed {
            try recorder.handle(event(.keyDown, keyCode: keyCode))
        }

        #expect(recorder.note(for: purpose) == note.map { LocalizedStringKey($0) })
    }

    private func event(_ type: NSEvent.EventType, keyCode: UInt16, flags: UInt = 0) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: type,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: flags),
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
