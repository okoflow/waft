import AppKit
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
        recorder.start(.dictation, excluding: { _ in false }, { recorded.append($0) })

        try recorder.handle(.key(keyCode: keyCode, type: type, flags: NSEvent.ModifierFlags(rawValue: flags)))

        #expect(recorded.map(\.keyCode) == [Int64(keyCode)])
        #expect(!recorder.isRecording)
    }

    @Test
    func `rejects a key that types text and counts the rejection for its purpose`() throws {
        recorder.start(.edit, excluding: { _ in false }, { _ in })

        try recorder.handle(.key(keyCode: Self.letterA))
        try recorder.handle(.key(keyCode: Self.letterA))

        #expect(recorder.rejection == .typesText)
        #expect(recorder.rejections == [.edit: 2])
        #expect(recorder.isRecording(.edit))
    }

    @Test
    func `rejects the key already used for the other purpose`() throws {
        recorder.start(.edit, excluding: { $0.keyCode == Int64(Self.functionKey) }, { _ in })

        try recorder.handle(.key(keyCode: Self.functionKey))

        #expect(recorder.rejection == .taken)
        #expect(recorder.isRecording(.edit))
    }

    @Test
    func `cancels on Escape`() throws {
        var recorded: [PushToTalkKey] = []
        recorder.start(.dictation, excluding: { _ in false }, { recorded.append($0) })

        try recorder.handle(.key(keyCode: Self.escape))

        #expect(!recorder.isRecording)
        #expect(recorded.isEmpty)
        #expect(recorder.rejection == nil)
    }

    @Test
    func `ignores a modifier being released`() throws {
        var recorded: [PushToTalkKey] = []
        recorder.start(.dictation, excluding: { _ in false }, { recorded.append($0) })

        try recorder.handle(.key(keyCode: 61, type: .flagsChanged))

        #expect(recorder.isRecording(.dictation))
        #expect(recorded.isEmpty)
        #expect(recorder.rejection == nil)
    }

    @Test
    func `clears the previous rejection when it starts again`() throws {
        recorder.start(.dictation, excluding: { _ in false }, { _ in })
        try recorder.handle(.key(keyCode: Self.letterA))

        recorder.start(.dictation, excluding: { _ in false }, { _ in })

        #expect(recorder.rejection == nil)
        #expect(recorder.rejections == [.dictation: 1])
    }

    @Test
    func `stops recording when Waft stops being the active app`() async {
        recorder.start(.dictation, excluding: { _ in false }, { _ in })

        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)

        #expect(await Poll.until(timeout: .seconds(5)) { !recorder.isRecording })
    }
}
