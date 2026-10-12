import Foundation
import Testing
@testable import WaftCore

struct PushToTalkKeyTests {
    private static let leftOptionFlag: UInt64 = 0x20
    private static let optionMask: UInt64 = 0x80000

    @Test(arguments: [Int64(54), 55, 56, 58, 59, 60, 61, 62, 63, 122, 96, 111, 90])
    func `accepts modifier and function key codes`(keyCode: Int64) throws {
        let key = try #require(PushToTalkKey(keyCode: keyCode))

        #expect(key.keyCode == keyCode)
    }

    @Test(arguments: [Int64(0), 36, 49, 53, -1, 9999])
    func `rejects ordinary key codes`(keyCode: Int64) {
        #expect(PushToTalkKey(keyCode: keyCode) == nil)
    }

    @Test
    func `names function keys by their number`() throws {
        let f13 = try #require(PushToTalkKey(keyCode: 105))

        #expect(f13.title == "F13")
        #expect(f13.shortTitle == "F13")
        #expect(PushToTalkKey.function.shortTitle == "Fn")
    }

    @Test(arguments: [
        (PushToTalkKey?.some(.rightOption), KeyEvent.rightOptionFlag | optionMask, true),
        (.rightOption, leftOptionFlag, false),
        (PushToTalkKey(keyCode: KeyEvent.f5KeyCode), .max, false),
    ])
    func `reads a modifier as held only from its own flag`(key: PushToTalkKey?, flags: UInt64, isHeld: Bool) throws {
        let key = try #require(key)

        #expect(key.isHeld(in: flags) == isHeld)
    }

    @Test(arguments: [
        (KeyEvent.Kind.modifiersChanged, Int64(61), UInt64(0x40), PushToTalk.Event?.some(.keyDown)),
        (.modifiersChanged, 61, 0, .keyUp),
        (.modifiersChanged, 58, 0x20, nil),
        (.keyDown, 0, 0x40, .otherKeyDown),
        (.keyUp, 0, 0, nil),
        (.monitorDisabled, 0, 0, .monitorDisabled),
    ])
    func `maps events for a modifier key`(kind: KeyEvent.Kind, keyCode: Int64, flags: UInt64, expected: PushToTalk.Event?) {
        #expect(PushToTalkKey.rightOption.event(for: KeyEvent(kind, keyCode: keyCode, flags: flags)) == expected)
    }

    @Test(arguments: [
        (KeyEvent.Kind.keyDown, Int64(96), PushToTalk.Event?.some(.keyDown)),
        (.keyUp, 96, .keyUp),
        (.keyDown, 97, .otherKeyDown),
        (.keyUp, 97, nil),
        (.modifiersChanged, 96, nil),
        (.monitorDisabled, 96, .monitorDisabled),
    ])
    func `maps events for a function key`(kind: KeyEvent.Kind, keyCode: Int64, expected: PushToTalk.Event?) throws {
        let key = try #require(PushToTalkKey(keyCode: KeyEvent.f5KeyCode))

        #expect(key.event(for: KeyEvent(kind, keyCode: keyCode)) == expected)
    }

    @Test(arguments: [Int64(96), 0])
    func `ignores an auto-repeated key-down`(keyCode: Int64) throws {
        let key = try #require(PushToTalkKey(keyCode: KeyEvent.f5KeyCode))

        #expect(key.event(for: KeyEvent(.keyDown, keyCode: keyCode, isRepeat: true)) == nil)
    }

    @Test(arguments: [
        (PushToTalkKey?.some(.rightOption), KeyEvent(.keyDown, keyCode: 0, flags: KeyEvent.rightOptionFlag), true),
        (.rightOption, KeyEvent(.modifiersChanged, keyCode: 61), false),
        (PushToTalkKey(keyCode: KeyEvent.f5KeyCode), KeyEvent(.keyDown, keyCode: KeyEvent.f5KeyCode), true),
        (PushToTalkKey(keyCode: KeyEvent.f5KeyCode), KeyEvent(.keyUp, keyCode: KeyEvent.f5KeyCode), false),
    ])
    func `tells whether an event presses the key`(key: PushToTalkKey?, event: KeyEvent, isPressed: Bool) throws {
        let key = try #require(key)

        #expect(key.isPressed(by: event) == isPressed)
    }

    @Test(arguments: [PushToTalkKey.rightOption, .function, PushToTalkKey(keyCode: 122)])
    func `survives an encoding round trip`(key: PushToTalkKey?) throws {
        let key = try #require(key)
        let data = try JSONEncoder().encode(key)

        #expect(String(bytes: data, encoding: .utf8) == "\(key.keyCode)")
        #expect(try JSONDecoder().decode(PushToTalkKey.self, from: data) == key)
    }

    @Test(arguments: ["9999", "0", "\"61\"", "null"])
    func `refuses to decode an unsupported key`(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PushToTalkKey.self, from: Data(json.utf8))
        }
    }
}
